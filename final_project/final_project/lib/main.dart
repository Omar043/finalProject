/*
    main.dart:
  The following page acts as the entry point for the router.
  It is also where the connection to the firebase is initialized.
  I also use it to add my citations as presented belowL
*/
//credit: flutter.dev
//url: "https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/main.dart"
//reason cited: used example as a skeleton for my own router

//credit: flutter.dev
//url: "https://github.com/flutter/packages/blob/main/packages/camera/camera/example/lib/readme_full_example.dart"
//reason cited: used the pub.dev page and the full example.dart page as a reference for my camera app

//credit: google
//url: "https://firebase.google.com/docs/storage/flutter/start"
//reason cited: used documentation for setting up google cloud storage.

//credit: flutter.dev
//url: https://api.flutter.dev/flutter/material/Icons-class.html
//reason cited: used to find the icons for the camera and video page

import 'package:flutter/material.dart';
import 'package:final_project/routes/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

//The main function handles the initalization of the firebase connection.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

//the router is used to handle the state of the user page.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
