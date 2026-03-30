const express = require('express');
const bcrypt = require('bcrypt');
const mongoose = require('mongoose');
const cors = require('cors'); // added for Flutter Web compatibility

const app = express();
const port = 3001;

app.use(cors()); // allows the flutter app to talk to the server
app.use(express.json());

const mongoURI = 'mongodb://mongo:27017';

mongoose.connect(mongoURI)
  .then(() => console.log("Connected to MongoDB"))
  .catch(err => console.error("Connection error", err));


/*
    The following are schemas that are used to store the data neccessary for the app
*/
const userSchema = new mongoose.Schema({
  username: String,
  hashedPassword: String,
  profileImage: String
});

const eventSchema = new mongoose.Schema({
  creator: String,
  category: String,
  startingTime: String,
  isActive: Boolean,
  isPrivate: Boolean,
  eventId: String,
  eventLocation: String,
  latitude: String,
  longitude: String
});

const eventChatSchema = new mongoose.Schema({
  eventId: String,
  channelId: String,
});

const eventUserCommentSchema = new mongoose.Schema({
  eventId: String,
  channelId: String,
  userId: String,
  comment: String
})

const userEventInstanceSchema = new mongoose.Schema({
  username: String,
  eventId: String,
  isadmin: Boolean,
  isbanned: Boolean,
  ismuted: Boolean
});

const userTrackingSchema = new mongoose.Schema({
  username: String,
  latitude: String,
  longitude: String
})

const User = mongoose.model('User', userSchema);
const Event = mongoose.model('Event', eventSchema);
const UserEventInstance = mongoose.model('UserEventInstance', userEventInstanceSchema);
const UserTracking = mongoose.model('UserTrackingInstance', userTrackingSchema);
const EventChat = mongoose.model("EventChat", eventChatSchema);
const EventUserComment = mongoose.model("EventUserComment", eventUserCommentSchema);

//standard port is for debugging purpouses.
app.get('/', (req, res) => {
  res.send('HTTP Server is running!');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`HTTP server up at http://localhost:${port}`);
});

// Login Request
// Bcrypt library used to ensure that the username and password are encrypted
app.post('/loginRequest', async (req, res) => {
  try {
    const { username, password } = req.body;
    const user = await User.findOne({ username });

    if (!user) {
      return res.status(404).send("User not found");
    }

    const isMatch = await bcrypt.compare(password, user.hashedPassword);
    
    if (isMatch) {
      res.status(200).send("Login successful!");
    } else {
      res.status(401).send("Invalid credentials");
    }
  } catch (error) {
    res.status(500).send("Server error");
  }
});

// Signup Request
// Afer verification that the the username is unique, the account can be created
app.post('/signupRequest', async (req, res) => {
  try {
    const { username, password } = req.body;

    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.status(409).send("Username already taken"); 
    }

    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    const newUser = new User({
      username: username,
      hashedPassword: hashedPassword,
      profileImage: "" 
    });

    await newUser.save();
    res.status(201).send("User created successfully!");
  } catch (error) {
    console.error(error);
    res.status(500).send("Server error during signup");
  }
});

// Event creation request
// The event is created and given a unique eventId
// Afterwards, the user who created the event is automatically assignmed admin priveledges
app.post('/eventCreationRequest', async (req, res) => {
  try {
    const { username, publicOrPrivate, category, startingTime, location, Lat, Long } = req.body;
    const generatedEventId = new mongoose.Types.ObjectId().toString();
    const newEvent = new Event({
      creator: username,
      category: category,
      startingTime: startingTime,
      isActive: true,
      isPrivate: publicOrPrivate,
      eventId: generatedEventId,
      eventLocation: location,
      latitude: String(Lat),
      longitude: String(Long)
    });
    await newEvent.save();

    const adminInstance = new UserEventInstance({
      username: username,
      eventId: generatedEventId,
      isadmin: true, 
      isbanned: false,
      ismuted: false
    });
    await adminInstance.save();

    res.status(201).send("Event created and joined successfully");
  } catch (error) {
    res.status(500).send("Server error");
  }
});

// Event Query
// as of current, all events are returned to the user
app.post('/eventQuery', async (req, res) => {
  try {
    const events = await Event.find({}).lean();
    if (!events){
      return res.status(404).send("Events not found");
    }
    res.status(200).json(events);
  } catch (error) {
    res.status(500).send("Server error");
  }
});

// Event attendees query:
// all users of a specifice event are returned to the user
app.post('/userEventInstanceQuery', async (req, res) => {
  try{
    const { username } = req.body;
    const instances = await UserEventInstance.find({ username }).lean();
    const eventIds = instances.map(inst => inst.eventId);
    const events = await Event.find({ eventId: { $in: eventIds } }).lean();
    res.status(200).json(events);
  } catch (error) {
    res.status(500).send("Server error");
  }
});

// Query for all comments in event chat under specific channel
// Required for rendering
app.post('/eventChatQuery', async (req, res) =>{
  try{
    const { eventId, channelId } = req.body;
    const comments = await EventUserComment.find({ eventId, channelId }).lean();
    res.status(200).json(comments);
  } catch(error) {
    res.status(500).send("Server error");
  }
});

// query for all locations of users of an event
// first, all userEventInstances are queried
// then, all instances of userTracking are queried
// the result is sent to the user
app.post('/eventUserLocations', async (req, res) =>{
  try{
    const { eventId } = req.body;
    const instances = await UserEventInstance.find({ eventId }).lean();
    const usernames = instances.map(inst => inst.username);
    const locations = await UserTracking.find({ username: { $in: usernames } }).lean();
    res.status(200).json(locations);
  } catch(error) {
    res.status(500).send("Server error");
  }
});

// User location update
// When the user sends the new coordinates, they overwrite the current ones
app.post('/userLocationUpdate', async(req, res) => {
  try{
    const { userId, latitude, longitude } = req.body;
    await UserTracking.findOneAndUpdate(
      { username: userId },
      { latitude: String(latitude), longitude: String(longitude) },
      { upsert: true } //User location instance is created if it does not exist
    );
    res.status(200).send("Location updated");
  } catch(error) {
    res.status(500).send("Server error");
  }
});

// Comment is added to chat
// The comment is saved as an EventUserComment
app.post('/addCommentToChat', async(req, res) => {
  try{
    const { userId, eventId, channelId, comment } = req.body;
    const newComment = new EventUserComment({
      eventId,
      channelId,
      userId,
      comment
    });
    await newComment.save();
    res.status(201).send("Comment added");
  } catch(error) {
    res.status(500).send("Server error");
  }
});

// User event join and handle request
// The user data is verified, and the user event instance is subsequently created
app.post('/eventJoinRequest', async (req, res) => {
  try {
    const { username, eventId } = req.body;
    
    const user = await User.findOne({ username });
    if (!user) return res.status(404).send("User not found");

    const event = await Event.findOne({ eventId });
    if (!event) return res.status(404).send("Event not found");

    const userExistsInEvent = await UserEventInstance.findOne({ username, eventId });

    if (userExistsInEvent) {
      return res.status(409).send("User already in event");
    }

    const newUserInEvent = new UserEventInstance({
      username,
      eventId,
      isadmin: false,
      isbanned: false,
      ismuted: false
    });
    await newUserInEvent.save();

    const userTrackingInstance = new UserTracking({
      username,
      latitude: "",
      longitude: ""
    });
    await userTrackingInstance.save();

    res.status(201).send("Joined event successfully");
    
  } catch (error) {
    console.error(error);
    res.status(500).send("Server error");
  }
});