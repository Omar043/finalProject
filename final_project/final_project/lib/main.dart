import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'dart:io';
//credit advanced introduction to goroute, as shown by the following persons: "https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/main.dart"
//url = "https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/main.dart"

// GoRouter configuration
final _router = GoRouter(
  routes: [
    //  Home screen
    GoRoute(
      path: '/',
      builder: (context, state) {
        return HomeScreen();
      },
    ),

    //  Sign in page
    GoRoute(
      path: 'signInPage',
      builder: (context, state) {
        return SigninPage();
      },
    ),

    //  input method page
    GoRoute(
      path: 'inputPage',
      builder: (context, state) {
        final patientType = state.extra as String;
        return InputMethodPage(patientType: patientType);
      },
    ),

    //  camera screen
    GoRoute(
      path: 'cameraPage',
      builder: (context, state) {
        return CameraScreenPage();
      },
    ),
    GoRoute(
      path: 'audioPage',
      builder: (context, state) {
        return AudioScreenPage();
      },
    ),

    GoRoute(
      path: 'submissionMadePage',
      builder: (context, state) {
        return AudioScreenPage();
      },
    ),
  ],
);
void main() {
  runApp(const MyApp());
}

//class that stores paths to audio recordings and images
class PatientDataToSend {
  List<String> imagePaths = [];
  List<String> audioPaths = [];
}

PatientDataToSend newPatient = PatientDataToSend();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/*
    Create the following functions:
      onEmergencyButton
      onUrgentButton
*/
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /*
      Both buttons should send the user to the inputMethodPage
      Problem is telling the inputMethodPage what button was selected, preferably
      through an input parameter

      Solution:
        use 
  */
  void _handleEmergencyButton(BuildContext context) {
    context.go('inputPage', extra: "emergency");
  }

  void _handleUrgentButton(BuildContext context) {
    context.go('inputPage', extra: "urgent");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _handleEmergencyButton(context);
              },
              child: Text('Emergency'),
            ),
            ElevatedButton(
              onPressed: () {
                _handleUrgentButton(context);
              },
              child: Text('Urgent'),
            ),
          ],
        ),
      ),
    );
  }
}

/*
  TODO:
    ENSURE THAT NO SQL INJECTIONS ARE ALLOWED WHEN USER SIGNS IN
    send generic warning message to the user when both credentials tab filled in but incorrect (count as attempt)
    send warning message when missing field present in user credential submission(don't count as attempt)
    send warning message to user after three incorrect credential submissions(send warning to user)
    lock user screen for 1 min, 3 min, then indefinately after sufficient number of incorrect submissions. 

    Functions:
      incorrectWarning
      repeatedErrorWarning
      lockUserScreen

    CHECK IF AUTHENTICATION SOFTWARE EXISTS
*/
class SigninPage extends StatelessWidget {
  const SigninPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ),
    );
  }
}

/*
    InputMethodPage:
  User should have the ability to select between audio and camera output.

    Functions:
      onAudioPress
      onCameraPress
      onSubmission
*/
class InputMethodPage extends StatelessWidget {
  const InputMethodPage({super.key, required this.patientType});
  final String patientType;

  //route user to the audio page
  _onAudio(BuildContext context) {
    context.go('audioPage');
  }

  //route user to the camera page
  _onCamera(BuildContext context) {
    context.go('cameraPage');
  }

  //route user to a "finished" page
  _onSubmission(BuildContext context) {
    //check if any audio or visual entries submitted
    //if yes, submit
    //else if no, do not submit and send warning to user

    /*
      PatientDataToSend newPatient = PatientDataToSend();
    */
    if (newPatient.audioPaths.isEmpty && newPatient.imagePaths.isEmpty) {
      //popup warning message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum of 1 recording/image required'),
          duration: Duration(seconds: 3),
          /*
            action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              print('Undo clicked!');
            },
            ),
          */
        ),
      );
    } else {
      /*
          code that submits data to the database
      */
      context.go('submissionMadePage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('InputMethodPage')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _onAudio(context);
              },
              child: Text('Audio Entry'),
            ),
            ElevatedButton(
              onPressed: () {
                _onCamera(context);
              },
              child: Text('Photo Entry'),
            ),
            ElevatedButton(
              onPressed: () {
                _onSubmission(context);
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

/*
    CameraScreenPage:
  Need to create camera with a "take photo" button and a "return" button

  take_photo:
    take a picture with the mobile camera. 
    store the image locally with the method of choice
    store link to image within newPatient

  return:
    return to the inputMethod page
*/
class CameraScreenPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraScreenPage> {
  late CameraController _controller;
  late List<CameraDescription> cameras;
  late CameraDescription firstCamera;

  @override
  void initState() {
    super.initState();
    // Initialize the camera.
    _initializeCamera();
  }
}

class AudioScreenPage extends StatelessWidget {
  const AudioScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ),
    );
  }
}

class SubmissionMadePage extends StatelessWidget {
  const SubmissionMadePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Submission Created')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ),
    );
  }
}
