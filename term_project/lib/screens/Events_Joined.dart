import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:term_project/global_vars.dart' as globals;

class EventsJoinedScreen extends StatefulWidget {
  const EventsJoinedScreen({super.key});

  @override
  State<EventsJoinedScreen> createState() => EventsJoinedScreenState();
}

class EventsJoinedScreenState extends State<EventsJoinedScreen> {

  /*
    following are some variables needed to maintain the eventsjoinedscreen page
    timers are used for checks for if any element has to be updated
  */
  List<dynamic> joinedEvents = [];
  Timer? _refreshTimer;
  Timer? _locationTimer;

  //default coordinates is set to chico
  double currentLat = 39.728115;
  double currentLon = -121.845452;

  @override
  void initState() {
    super.initState();
    _fetchJoinedEvents();

    //page is refreshed every second (migration to websockes will occur later)
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) 
      {
        _fetchJoinedEvents();
      }
    });

    // user location is updated every five seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted)
      {
        _updateUserLocation();
      }
    });
  }

  @override
  void dispose() {
    //timers are canceled when not on the page (to save memory)
    _refreshTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  /*
      The following function sends a query to the backend for all the events
      that the user has joined. if any changes occur, the page has to be
      reloaded
  */
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

        // json strings from fetched data are compared to ones we have to check for a change
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

  /*
      The following function sends a query to the backend that contains the user
      followed by the coordinates in lat-long format
  */
  Future<void> _updateUserLocation() async {
    try {
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
      debugPrint("Error updating location: $e");
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
                    title: Text(event['category'] ?? 'unnamed Event'),
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
  bool isMapView = false;
  String selectedChannel = "Main";
  List<String> channels = ["Main", "Questions", "Memes"];
  List<dynamic> chatComments = [];
  List<dynamic> userLocations = [];
  final TextEditingController _commentController = TextEditingController();
  Timer? _detailRefreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    //chat is refreshed every two seconds when in details
    _detailRefreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) _fetchData();
    });
  }

  @override
  void dispose() {
    //we cancel the refresh timers when not on the page to save memory
    _detailRefreshTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  /*
      if the user is not in the map view, we do not need to retrieve their
      location
  */
  void _fetchData() {
    if (isMapView) {
      _fetchLocations();
    } else {
      _fetchChats();
    }
  }

  /*
      A query is sent to the backend involving the chats that the user is a
      participant of.

      If there is any difference between the ones fetched and current ones
      loaded, the page has to be updated
  */
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

  /*
      The following function updates the locaiton of the user in the backend
  */
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

  /*
      A write request is made to the server, in which a new comment instance is 
      created
  */
  Future<void> _sendMessage() async {
    if (_commentController.text.trim().isEmpty) return;
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
      debugPrint("Send error: $e");
    }
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
      body: isMapView ? _buildMap() : _buildChat(),
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

  /*
    The following function constructs an instance of a map using the
    openStreetMap tiles. The the location is first defaulted to the values in
    latitude and longitude, else they are set to chico. Then, the tile layer is
    specified to the ones provided from openStreetMap, and the marker layer is
    fed all of the user locations, and they are displayed on the map
  */
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
            return Marker(
              point: LatLng(
                double.tryParse(loc['latitude']?.toString() ?? '0') ?? 0,
                double.tryParse(loc['longitude']?.toString() ?? '0') ?? 0,
              ),
              width: 60,
              height: 60,
              child: Column(
                children: [
                  Text(
                    loc['username'] ?? '',
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
            );
          }).toList(),
        ),
      ],
    );
  }
}
