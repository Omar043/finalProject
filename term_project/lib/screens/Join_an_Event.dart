import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:osm_nominatim/osm_nominatim.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:term_project/global_vars.dart' as globals;

class JoinAnEventScreen extends StatefulWidget {
  const JoinAnEventScreen({super.key});

  @override
  State<JoinAnEventScreen> createState() => _JoinAnEventScreenState();
}

class _JoinAnEventScreenState extends State<JoinAnEventScreen> {
  //The following variables are important for event discovery
  Place? currentPlace;
  final List<int> radiuses = [5, 10, 25, 50];
  int radius = 5;
  var currentRadiusSelected = 0;

  //The caching is for best policy regarding openstreetmap (is NOT free to use, access can be limited if too many requests)
  late final Future<String?> _cachePath;
  var listOfCurrentEvents = [];

  //Following are controllers for the map and city name
  final TextEditingController _cityController = TextEditingController(
    text: 'Chico',
  );
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _cachePath = _prepareCachePath();
  }

  //cache for map directory has to be set up
  Future<String?> _prepareCachePath() async {
    //The map has to be stored with a temporary directory for web users
    if (kIsWeb) {
      return null;
    }
    final cacheDir = await getTemporaryDirectory();
    return cacheDir.path;
  }

  /*
      Map is refreshed when the user enters a location (later every so often)
  */
  void _refreshMap(Place areaToSearch, int selectedRadius) async {
    setState(() {
      currentPlace = areaToSearch;
    });

    //latitude and longitude are of the areas tha the user have selected
    double? latitude = currentPlace?.lat;
    double? longitude = currentPlace?.lon;

    //if no location selected, we have no base of reference to refresh the map
    if (latitude == null || longitude == null) {
      return;
    }

    _mapController.move(LatLng(latitude, longitude), 9.2);

    //event query is made after we have selected a new location
    var url = Uri.http('localhost:3001', '/eventQuery');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      print("Request unsuccessful: ${response.statusCode}");
      return;
    }

    //respose from server is parsed and processed
    List jsonResponse = json.decode(response.body);
    List finalArray = [];
    const distanceCalculator = Distance();

    for (int i = 0; i < jsonResponse.length; i++) {
      // string is parsed as a double to ensure the requirement
      double eventLat =
          double.tryParse(jsonResponse[i]['latitude']?.toString() ?? '0') ??
          0.0;
      double eventLon =
          double.tryParse(jsonResponse[i]['longitude']?.toString() ?? '0') ??
          0.0;

      //we use the nominatim library as the distance formula is inacurate for latitude and longitude
      double distance = distanceCalculator.as(
        LengthUnit.Mile,
        LatLng(latitude, longitude),
        LatLng(eventLat, eventLon),
      );

      //if the distance is less than the max distance selected by the user, it is loaded
      if (distance < selectedRadius) {
        finalArray.add(jsonResponse[i]);
      }
    }

    setState(() {
      listOfCurrentEvents = finalArray;
    });
  }

  /*
      The following screen displays the event as a popup from the bottom sheet
  */
  void _showEventDetails(dynamic event) {
    //bottom sheet is rendered as a popup from the bottom screen
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['category'] ?? 'New Event',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Location: ${event['eventLocation'] ?? 'TBD'}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    final dataToSend = {
                      "username": globals.username,
                      "eventId": event["eventId"],
                    };
                    var url = Uri.http('localhost:3001', '/eventJoinRequest');
                    var response = await http.post(
                      url,
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode(dataToSend),
                    );

                    if (response.statusCode == 201) {
                      print("Join success");
                    } else {
                      print("Error joining event: ${response.statusCode}");
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Join Event',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /*
      The following is a query made to the nominatim database for the top five
      results of areas closest name to our location
  */
  Future<List<Place>?> _returnLocationsGivenText() async {
    final nominatim = Nominatim(userAgent: 'MyCoolFlutterApp/1.0');
    final List<Place> results = await nominatim.searchByName(
      query: _cityController.text,
      limit: 5,
    );
    return results.isEmpty ? null : results;
  }

  /*
      The following function sends a query to the nominatim server
      If the return value is null, the address is not valid, and nothing is
      presented. 
      Else we present to the user the top five most similar addressed to the one
      that they selected
  */
  void _handleLocationQuery() async {
    List<Place>? locations = await _returnLocationsGivenText();
    if (locations == null) return;

    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Select an address'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: locations.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(locations[index].displayName),
                onTap: () {
                  _refreshMap(locations[index], radius);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find an event')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                Expanded(
                  child: DropdownButton<int>(
                    value: radius,
                    icon: const Icon(Icons.arrow_downward),
                    onChanged: (int? newValue) {
                      setState(() => radius = newValue!);
                    },
                    items: radiuses.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text("$value miles"),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _handleLocationQuery,
                  child: const Text('Verify'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<String?>(
              future: _cachePath,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(39.728115, -121.845452),
                    initialZoom: 9.2,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.WeMeet.testingmapapp',
                      tileProvider: CachedTileProvider(
                        store: snapshot.data == null
                            ? MemCacheStore()
                            : FileCacheStore(snapshot.data!),
                      ),
                    ),
                    MarkerLayer(
                      markers: listOfCurrentEvents.map((event) {
                        double lat =
                            double.tryParse(
                              event['latitude']?.toString() ?? '0',
                            ) ??
                            0.0;
                        double lon =
                            double.tryParse(
                              event['longitude']?.toString() ?? '0',
                            ) ??
                            0.0;

                        return Marker(
                          point: LatLng(lat, lon),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showEventDetails(event),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => launchUrl(
                            Uri.parse('https://openstreetmap.org/copyright'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    //if the user selects another page, we stop rendering the map to ensure that
    //no memory is wasted.
    _cityController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
