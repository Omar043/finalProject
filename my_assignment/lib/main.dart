import 'package:flutter/material.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/firebasestorage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(home: MainPage()));
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final Color _appBarColor = Colors.redAccent;
  final TextEditingController _textController = TextEditingController();

  /*
      Variables:
        id = keeps track of the updated id
        tempId = keeps track of the raw user input id
        userName = keeps track of the username
        CFStorage = interface to the firebase databae
  */
  int id = 0;
  int tempId = 0;
  String userName = "";
  final CFStorage _storage = CFStorage();

  /*
      addInputToDatabase():
        The following function verifies that the input the user entered is updated,
        and subsequently adds the input to the user database.
        
        The program subsequently notifies the user if their input has been accepted
        through a pop up message in the botton of the screen, with green indicating
        success and red failiure
  */
  void addInputToDatabase() {
    String testUsername = _textController.text.trim();

    if (testUsername.isNotEmpty && tempId != 0) {
      //check for non-modified fields
      _storage.writeValues(testUsername, tempId).then((_) async {
        //data is written to the database, and then retrieved and interpreted
        var data = await _storage.readValues();
        setState(() {
          //values are updated to the display
          userName = data.userName;
          id = data.id;
        });

        //success popup message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        _textController.clear();
      });
    } else {
      //failiure popup message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Field(s) Empty. Enter info in both fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _appBarColor,
        title: const Text('CSCI567 Hello World'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Display Widgets:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('UserName: $userName', style: const TextStyle(fontSize: 16)),
            Text('Id: $id', style: const TextStyle(fontSize: 16)),
            ElevatedButton(
              onPressed: () => addInputToDatabase(),
              child: const Text('Add data to database'),
            ),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(labelText: "Username input"),
            ),
            SpinBox(
              min: 1,
              max: 5000,
              value: id.toDouble(),
              step: 1,
              decimals: 0,
              decoration: const InputDecoration(labelText: 'Id input'),
              onChanged: (val) {
                tempId = val.toInt();
              },
            ),
          ],
        ),
      ),
    );
  }
}
