/*
    app_router.dart:
  The following file stores the GoRouter configuration of the project.
  And for the sign in page, it defines the login flag neeed to check whehter
  or not the user had failed a login attempt. 
*/

import 'package:go_router/go_router.dart';
import 'package:final_project/screens/camera_screen.dart';
import 'package:final_project/screens/input_method.dart';
import 'package:final_project/screens/sign_in_page.dart';
import 'package:final_project/screens/video_screen.dart';
import 'package:final_project/screens/submission_created_page.dart';
import 'package:final_project/screens/input_severity.dart';

// The following is my gorouter configuration, where I store the locations of
// the pages relevant to the project.
final router = GoRouter(
  initialLocation: '/signInPage',
  routes: [
    // emergency input screen
    GoRoute(
      path: '/',
      builder: (context, state) {
        return HomeScreen();
      },
    ),

    // sign in page
    GoRoute(
      path: '/signInPage',
      builder: (context, state) {
        final failedLoginFlag = (state.extra as bool?) ?? false;
        return SigninPage(failedLoginFlag: failedLoginFlag);
      },
    ),

    //  input method page
    GoRoute(
      path: '/inputPage',
      builder: (context, state) {
        return InputMethodPage();
      },
    ),

    //  camera screen
    GoRoute(
      path: '/cameraPage',
      builder: (context, state) {
        return CameraScreenPage();
      },
    ),

    //  video input method page
    GoRoute(
      path: '/videoPage',
      builder: (context, state) {
        return VideoScreenPage();
      },
    ),

    //  redirection page
    GoRoute(
      path: '/submissionMadePage',
      builder: (context, state) {
        return SubmissionMadePage();
      },
    ),
  ],
);
