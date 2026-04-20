import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart'; //I used the flutter camera library for handling the image taking process
import 'package:term_project/global_vars.dart' as globals;

class EventsJoinedScreen extends StatefulWidget {
  const EventsJoinedScreen({super.key});

  @override
  State<EventsJoinedScreen> createState() => EventsJoinedScreenState();
}

class EventsJoinedScreenState extends State<EventsJoinedScreen> {
  List<dynamic> joinedEvents = [];
  Timer? _refreshTimer;
  Timer? _locationTimer;

  //the following are coordinates to the university
  double currentLat = 39.728115;
  double currentLon = -121.845452;

  @override
  void initState() {
    super.initState();
    _fetchJoinedEvents();

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _fetchJoinedEvents();
      }
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _updateUserLocation();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  //The following is my api request and response handler for finding the list
  //of events that the user had joined.
  Future<void> _fetchJoinedEvents() async {
    try {
      var url = Uri.http('localhost:3001', '/userEventInstanceQuery');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": globals.username}),
      );

      if (response.statusCode == 200) {
        List<dynamic> fetchedData = jsonDecode(response.body);
        if (jsonEncode(fetchedData) != jsonEncode(joinedEvents)) {
          setState(() {
            joinedEvents = fetchedData;
          });
        }
      }
    } catch (e) {
      debugPrint("Network error fetching events: $e");
    }
  }

  //  The following funciotn makes use of the geolocator library in order to
  //  retrieve the user location.
  //  Then, the function sends an api request to the server to update the user
  //  location.
  Future<void> _updateUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      //used example from the geolocator package page as a base reference
      //for the location settings and the getCurrentPosition function
      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      currentLat = position.latitude;
      currentLon = position.longitude;

      var url = Uri.http('localhost:3001', '/userLocationUpdate');
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": globals.username,
          "latitude": currentLat.toString(),
          "longitude": currentLon.toString(),
        }),
      );
    } catch (e) {
      debugPrint("error updating location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events Joined')),
      body: RefreshIndicator(
        onRefresh: _fetchJoinedEvents,
        child: joinedEvents.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "no events joined yet.\n waiting for updates",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: joinedEvents.length,
                itemBuilder: (context, index) {
                  var event = joinedEvents[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.event_available,
                      color: Colors.green,
                    ),
                    title: Text(event['category'] ?? 'unnamed event'),
                    subtitle: Text(event['eventLocation'] ?? 'no location'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventDetailScreen(event: event),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class EventDetailScreen extends StatefulWidget {
  final dynamic event;
  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  bool isMapView = false;
  String selectedChannel = "Main";
  List<String> channels = ["Main", "Questions", "Memes"];
  List<dynamic> chatComments = [];
  List<dynamic> userLocations = [];

  List<dynamic> eventPosts = [];
  Timer? _postsTimer;

  final TextEditingController _commentController = TextEditingController();
  Timer? _detailRefreshTimer;

  @override
  void initState() {
    //camera initialization
    super.initState();
    _fetchData();
    _initCamera();

  //timer and page state initialization
    _detailRefreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _fetchData();
      }
    });

    _fetchPosts();
    _postsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _fetchPosts();
      }
    });
  }

  // When using the standard camera library, the function has to wait for
  // the camera to load
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return;
    }

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  //Camera has to be disposed of, else duplicate instances of the camera can be found running (not good)
  @override
  void dispose() {
    _detailRefreshTimer?.cancel();
    _postsTimer?.cancel();
    _commentController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  //after data is fetched, we either request more data(if on map view)
  //or fetch the chats (in chat view)
  void _fetchData() {
    if (isMapView) {
      _fetchLocations();
    } else {
      _fetchChats();
    }
  }

  //  The following is my api handler for retrieving posts
  //  The api request is sent for a specific event, and if
  //  found, a list of all posts by user and sorted by recency will be loaded
  Future<void> _fetchPosts() async {
    try {
      var url = Uri.http('localhost:3001', '/getEventPosts');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"eventId": widget.event['eventId']}),
      );
      if (response.statusCode == 200) {
        List<dynamic> newPosts = jsonDecode(response.body);
        if (jsonEncode(newPosts) != jsonEncode(eventPosts)) {
          setState(() {
            eventPosts = newPosts;
          });
        }
      }
    } catch (e) {
      debugPrint("error when fetching posts: $e");
    }
  }

  //  Yet another api handler, this time for chats
  //  Request made for the event chats, and return values are the comments in order of recency
  Future<void> _fetchChats() async {
    try {
      var url = Uri.http('localhost:3001', '/eventChatQuery');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "eventId": widget.event['eventId'],
          "channelId": selectedChannel,
        }),
      );
      if (response.statusCode == 200) {
        setState(() => chatComments = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Chat fetch error: $e");
    }
  }

  //  api handler for locations.
  //  a request is made for all user locatoins, and the return value is the locations of all
  //  users given that they attended the event.
  Future<void> _fetchLocations() async {
    try {
      var url = Uri.http('localhost:3001', '/eventUserLocations');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"eventId": widget.event['eventId']}),
      );
      if (response.statusCode == 200) {
        setState(() => userLocations = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Location fetch error: $e");
    }
  }

  // Api handler for message sending
  // User input is cleaned and then sent to server, with text, user, and chat as
  // reference.
  Future<void> _sendMessage() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }
    try {
      var url = Uri.http('localhost:3001', '/addCommentToChat');
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": globals.username,
          "eventId": widget.event['eventId'],
          "channelId": selectedChannel,
          "comment": _commentController.text.trim(),
        }),
      );
      _commentController.clear();
      _fetchChats();
    } catch (e) {
      debugPrint("error when retrieving comments: $e");
    }
  }

  //  Following is handler of the user making a post and sending api request to server
  //  First, the user takes a picture with the camera library. Then, the api request is sent to the
  //  server. If successful, the post will appear under the second app bar
  Future<void> _takePictureAndPost() async {
    if (_controller == null || !_isCameraInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Camera not initialized")));
      return;
    }

    try {

      // I am using XFile to handle the image retieval and submission to the
      // server. (XFile is cross-platform)
      final XFile image = await _controller!.takePicture();
      bool isDesktop =
          !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.macOS);

      if (isDesktop) {
        debugPrint("Captured image on Desktop at: ${image.path}");
      }

      await _postImage(image);
    } catch (e) {
      debugPrint("Error capturing image: $e");
    }
  }

  //The following logic handles the posting of the image. The image has to be
  //converted to a byte string, and sent to the backend. If successufl, the
  //backend will successufly read and interpret the image.
  Future<void> _postImage(XFile image) async {
    try {
      final Uint8List imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      var url = Uri.http('localhost:3001', '/createPost');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "eventId": widget.event['eventId'],
          "username": globals.username,
          "image": base64Image,
          "description": "Posted from event",
        }),
      );

      if (response.statusCode == 201) {
        _fetchPosts();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Post shared!")));
      }
    } catch (e) {
      debugPrint("Upload error: $e");
    }
  }

  void _openPostViewer(String targetUsername) {
    List<dynamic> userSpecificPosts = eventPosts
        .where((p) => p['username'] == targetUsername)
        .toList();

    if (userSpecificPosts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$targetUsername has no posts.")));
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return PostViewerDialog(
          posts: userSpecificPosts,
          currentUsername: globals.username,
          refreshCallback: _fetchPosts,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event['category'] ?? 'Event Details'),
        actions: [
          IconButton(
            icon: Icon(isMapView ? Icons.chat : Icons.map),
            onPressed: () => setState(() {
              isMapView = !isMapView;
              _fetchData();
            }),
          ),
        ],
      ),
      body: Column(
        //second app bar is added to the map view if the user is in the map view
        children: [
          if (isMapView) _buildPostsBar(),
          Expanded(child: isMapView ? _buildMap() : _buildChat()),
        ],
      ),
    );
  }

  Widget _buildPostsBar() {
    Set<String> usersWithPosts = eventPosts
        .map((p) => p['username'].toString())
        .toSet();
    List<String> userList = usersWithPosts.toList();

    return Container(
      height: 80,
      color: Colors.grey[200],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: userList.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: _takePictureAndPost,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.add_a_photo, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text("New Post", style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            );
          }

          String postUser = userList[index - 1];
          return GestureDetector(
            onTap: () => _openPostViewer(postUser),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Text(postUser[0].toUpperCase()),
                  ),
                  const SizedBox(height: 4),
                  Text(postUser, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: channels.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(channels[index]),
                  selected: selectedChannel == channels[index],
                  onSelected: (selected) {
                    setState(() {
                      selectedChannel = channels[index];
                      _fetchChats();
                    });
                  },
                ),
              );
            },
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: chatComments.length,
            itemBuilder: (context, index) {
              var chat = chatComments[index];
              return ListTile(
                title: Text(
                  chat['userId'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(chat['comment'] ?? ''),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          double.tryParse(widget.event['latitude']?.toString() ?? '39.728') ??
              39.728,
          double.tryParse(
                widget.event['longitude']?.toString() ?? '-121.845',
              ) ??
              -121.845,
        ),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.WeMeet.testingmapapp',
        ),
        MarkerLayer(
          markers: userLocations.map((loc) {
            String uname = loc['username'] ?? '';
            return Marker(
              point: LatLng(
                double.tryParse(loc['latitude']?.toString() ?? '0') ?? 0,
                double.tryParse(loc['longitude']?.toString() ?? '0') ?? 0,
              ),
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () => _openPostViewer(uname),
                child: Column(
                  children: [
                    Text(
                      uname,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Colors.white70,
                      ),
                    ),
                    const Icon(
                      Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class PostViewerDialog extends StatefulWidget {
  final List<dynamic> posts;
  final String currentUsername;
  final VoidCallback refreshCallback;

  const PostViewerDialog({
    super.key,
    required this.posts,
    required this.currentUsername,
    required this.refreshCallback,
  });

  @override
  State<PostViewerDialog> createState() => _PostViewerDialogState();
}

class _PostViewerDialogState extends State<PostViewerDialog> {
  int currentIndex = 0;
  final TextEditingController _postCommentController = TextEditingController();
  Timer? _dialogRefreshTimer;

  late List<dynamic> localPosts;

  @override
  void initState() {
    super.initState();
    localPosts = List.from(widget.posts);

    _dialogRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        widget.refreshCallback();
        _syncLatestPostData();
      }
    });
  }

  @override
  void dispose() {
    _dialogRefreshTimer?.cancel();
    _postCommentController.dispose();
    super.dispose();
  }

  Future<void> _syncLatestPostData() async {
    try {
      var url = Uri.http('localhost:3001', '/getEventPosts');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"eventId": localPosts[currentIndex]['eventId']}),
      );
      if (response.statusCode == 200) {
        List<dynamic> allPosts = jsonDecode(response.body);
        var targetId = localPosts[currentIndex]['_id'];
        var updatedPost = allPosts.firstWhere(
          (p) => p['_id'] == targetId,
          orElse: () => null,
        );
        if (updatedPost != null && mounted) {
          setState(() {
            localPosts[currentIndex] = updatedPost;
          });
        }
      }
    } catch (e) {
      debugPrint("Sync error: $e");
    }
  }

  //  like toggler:
  //  when the user toggles the like, another api request is sent to the server handling the
  //  requst.
  Future<void> _toggleLike() async {
    try {
      var url = Uri.http('localhost:3001', '/toggleLikePost');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "postId": localPosts[currentIndex]['_id'],
          "username": widget.currentUsername,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          localPosts[currentIndex]['likes'] = jsonDecode(
            response.body,
          )['likes'];
        });
      }
    } catch (e) {
      debugPrint("error toggling the like button: $e");
    }
  }

  //  Following logic was altered from the initial comment section.
  Future<void> _addComment() async {
    if (_postCommentController.text.trim().isEmpty) {
      return;
    }
    try {
      var url = Uri.http('localhost:3001', '/addPostComment');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "postId": localPosts[currentIndex]['_id'],
          "username": widget.currentUsername,
          "comment": _postCommentController.text.trim(),
        }),
      );
      if (response.statusCode == 201) {
        setState(() {
          localPosts[currentIndex]['comments'] = jsonDecode(
            response.body,
          )['comments'];
        });
        _postCommentController.clear();
      }
    } catch (e) {
      debugPrint("Comment error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var currentPost = localPosts[currentIndex];
    List<dynamic> likes = currentPost['likes'] ?? [];
    List<dynamic> comments = currentPost['comments'] ?? [];
    bool hasLiked = likes.contains(widget.currentUsername);

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        image: DecorationImage(
                          image: MemoryImage(
                            base64Decode(currentPost['image']),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black54,
                        child: Text(
                          currentPost['description'] ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    if (currentIndex > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 2)],
                          ),
                          onPressed: () => setState(() => currentIndex--),
                        ),
                      ),
                    if (currentIndex < localPosts.length - 1)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 2)],
                          ),
                          onPressed: () => setState(() => currentIndex++),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        hasLiked ? Icons.favorite : Icons.favorite_border,
                        color: hasLiked ? Colors.red : Colors.black,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text("${likes.length} Likes"),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    var c = comments[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        c['username'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(c['comment'] ?? ''),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _postCommentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
