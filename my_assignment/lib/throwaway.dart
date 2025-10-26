/*
/*
    main.dart
*/
import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/firebasestorage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainPage());
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  //Appbar Color
  final Color _appBarColor = Colors.redAccent;

  //Controller for text input
  final TextEditingController _textController = TextEditingController();
  int id = 0;
  String userName = "";

  final CFStorage _storage = CFStorage();

  void addInputToDatabase(String? userInput, int id) {
    String testUsername = _textController.text;

    //check if values have been changed
    if (testUsername.isNotEmpty && id != 0) {
      _storage.writeValues(userName, id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      //if yes, set variables in database to new values
      //provide popup confirmation message to user
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fields(s) Empty. Enter info in both fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
    //clear fields.
    _textController.clear();
    id = 0;
  }

  @override
  void initState() {
    super.initState();
    _storage.readValues().then((data) {
      setState(() {
        id = data.id;
        userName = data.userName;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [
      //id

      //username
      const Text(
        'Display Widgets:',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text('UserName: $userName', style: const TextStyle(fontSize: 16)),
      Text('Id: $id', style: const TextStyle(fontSize: 16)),

      /*
          When button is pressed, addInputToDatabase is set
      */
      ElevatedButton(
        onPressed: () {
          addInputToDatabase(userName, id);
        },
        child: Text('Add data to database'),
      ),

      /*
          TextField stores values user enters for username
      */
      TextField(
        controller: _textController,
        decoration: InputDecoration(labelText: "Username input"),
      ),

      /*
          Spinbox stores values user enters for id
      */
      SpinBox(
        min: 1,
        max: 5000,
        value: id.toDouble(),
        step: 1,
        decimals: 0,
        decoration: const InputDecoration(labelText: 'Id input'),
        onChanged: (val) {
          setState(() => id = val.toInt());
        },
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
*/
