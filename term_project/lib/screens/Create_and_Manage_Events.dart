import 'package:term_project/global_vars.dart' as globals;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:osm_nominatim/osm_nominatim.dart';

class CreateAndManageEventsScreen extends StatefulWidget {
  const CreateAndManageEventsScreen({super.key});

  @override
  State<CreateAndManageEventsScreen> createState() =>
      _CreateAndManageEventsScreenState();
}

class _CreateAndManageEventsScreenState
    extends State<CreateAndManageEventsScreen> {
  //Controllers for input
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  //vars required to keep track of event creation
  bool isPrivate = true;
  Place? eventLocation;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        //date is in YYYY-MM-DD format
        _dateController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // time picking logic
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    //if the user has selected a time, we have to select a state
    if (pickedTime != null && context.mounted) {
      setState(() {
        _timeController.text = pickedTime.format(context);
      });
    }
  }

  /*  
      event creation first involves retrieving the user inputs.
      after verifying inputs, request has to be sent to the server. 
      After request is processed, if the event has been created (and user who created event is set to admin)
  */
  Future<bool> createNewEvent() async {
    // variables required for event creation are retrieved from controllers
    var username = globals.username;
    var category = _categoryController.text;
    var startingTime = _timeController.text;

    if (username.isEmpty ||
        category.isEmpty ||
        startingTime.isEmpty ||
        eventLocation?.displayName == null) {
      return false;
    }

    final dataToSend = {
      'username': username,
      'publicOrPrivate': isPrivate,
      'category': category,
      'startingTime': startingTime,
      "location": eventLocation?.displayName,
      "Lat": eventLocation?.lat,
      "Long": eventLocation?.lon,
    };

    //data is sent to server and processed
    var url = Uri.http('localhost:3001', '/eventCreationRequest');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(dataToSend),
    );

    //if creation attempt successful, reroute to sign in screen
    if (response.statusCode == 201) {
      print("account creation success");
      return true;
    }
    //if we get any other status code (other than 201), we have to send an error to the server
    else if (response.statusCode == 500) {
      print("server error");
      return false;
    } else {
      print("unknown error");
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          //header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'Event Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          //name for event
          const Text(
            "Event Name:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            maxLength: 50,
            controller: _eventNameController,
            decoration: const InputDecoration(
              hintText: "Enter event name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),

          const SizedBox(height: 10),

          //privacy toggle
          SwitchListTile(
            title: const Text('Private Mode'),
            subtitle: const Text('Hide from public search'),
            value: isPrivate,
            onChanged: (bool value) {
              setState(() => isPrivate = value);
            },
          ),

          const SizedBox(height: 10),

          //category field
          const Text(
            "Category:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              hintText: "i.e: Workshop, Party",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          //date field
          const Text("Date:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: () => _selectDate(context),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          //time field
          const Text(
            "Starting Time:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _timeController,
            readOnly: true,
            onTap: () => _selectTime(context),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.access_time),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Enter a location and then confirm:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'City'),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () {
              _handleLocationQuery();
            },
            child: const Text('Search for location'),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () async {
              bool success = await createNewEvent();
              _showResultDialog(success);
            },
            child: const Text('Create Event'),
          ),
        ],
      ),
    );
  }

  //showDialouge instance lets the user know if the user can create the event or if there is an error
  void _showResultDialog(bool success) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Success' : 'Error'),
        content: Text(
          success
              ? 'Event created successfully'
              : 'Event creation failed. Check the data fields',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /*
      when handling the location query, we first send the text to the nominatim
      server

      we then display the results of the query if there are return values

      NOTE: one request per second only (as per nominatim policy)
  */

  void _handleLocationQuery() async {
    List<Place>? locations = await _returnLocationsGivenText();
    if (locations == null) {
      eventLocation = null;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text("Location entered was not valid"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    /*
        new dialogue for the return of the nominatim results.
        when the user selects one result, it becomes the location of the event
    */
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: locations.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(locations[index].displayName),
                onTap: () {
                  setState(() {
                    eventLocation = locations[index];
                    _locationController.text = locations[index].displayName;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  //logic for location query to nominatim
  Future<List<Place>?> _returnLocationsGivenText() async {
    final nominatim = Nominatim(userAgent: 'MyCoolFlutterApp/1.0');

    final List<Place> results = await nominatim.searchByName(
      query: _locationController.text,
      limit: 5,
    );

    if (results.isEmpty) {
      return null;
    }
    return results;
  }
}
