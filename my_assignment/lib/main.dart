/*
    main.dart
*/
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MainPage());

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  //Appbar Color
  final Color _appBarColor = Colors.redAccent;

  //Controllers for retrieving input
  final TextEditingController _textController = TextEditingController();
  double tempFavNumber = 0;
  int tempId = 1;

  //Variables for input storage:
  String name = "";
  double favNumber = 0;
  int id = 0;

  //Functions assosiated with the shared_preferences function:
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs(); // Call the async function here
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    setState(() {
      name = prefs.getString('name') ?? '';
      favNumber = prefs.getDouble('favNumber') ?? 0.0;
      id = prefs.getInt('id') ?? 1;
    });
  }

  //Functions for input handling
  Future<void> saveInputValues() async {
    final testName = _textController.text;
    final testFavNumber = tempFavNumber;
    final testId = tempId;

    final savedName = prefs.getString('name') ?? '';
    final savedFavNumber = prefs.getDouble('favNumber') ?? 0.0;
    final savedId = prefs.getInt('id') ?? 1;

    bool hasChanged = false;

    //name is only updated when it has a value and is a different value
    if (testName.isNotEmpty && testName != savedName) {
      await prefs.setString('name', testName);
      hasChanged = true;
    }

    if (testFavNumber != savedFavNumber) {
      await prefs.setDouble('favNumber', testFavNumber);
      hasChanged = true;
    }

    if (testId != savedId) {
      await prefs.setInt('id', testId);
      hasChanged = true;
    }

    if (hasChanged) {
      setState(() {
        if (testName.isNotEmpty) {
          name = testName;
        }
        favNumber = testFavNumber;
        id = testId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [
      /*
        method of displaying name, favorite number, and id
    */
      //name: text
      Text('Current name: $name'),
      Text('Current favorite number: $favNumber'),
      Text('Current id: $id'),

      /*
      form with four elements:
        textfield for name,
        scroll for favorite number,
        number text field? for id
        submit button
    */
      TextField(
        controller: _textController,
        decoration: InputDecoration(labelText: "Name input"),
      ),

      SpinBox(
        min: -100.0,
        max: 100.0,
        value: tempFavNumber,
        step: 0.1,
        decimals: 2,
        decoration: const InputDecoration(labelText: 'Favorite Number'),
        onChanged: (val) {
          setState(() => tempFavNumber = val);
        },
      ),

      SpinBox(
        min: 1,
        max: 5000,
        value: tempId.toDouble(),
        step: 1,
        decimals: 0,
        decoration: const InputDecoration(labelText: 'Id'),
        onChanged: (val) {
          setState(() => tempId = val.toInt());
        },
      ),

      //button that when pressed, saves all of the information to a persistent state
      ElevatedButton(
        onPressed: () async {
          // Action when the button is pressed
          await saveInputValues();
          await _loadPrefs();
        },
        child: Text('Press to store current values'),
      ),
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: _appBarColor,
          title: const Text('CSCI567 Hello World'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: widgetList),
        ),
      ),
    );
  }
}
