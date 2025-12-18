/*
    input_method.dart:
  The following page allows the user to either select for an input method
  (camera or video) or submit the current media that they have recorded.
  Attempts to submit a patient without media will produce an error.
*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:final_project/models/patient_data.dart';

/*
    InputMethodPage:
  User should have the ability to select between audio and camera output.

    Functions:
      onAudioPress
      onCameraPress
      onSubmission
*/
class InputMethodPage extends StatelessWidget {
  const InputMethodPage({super.key});
  _onVideo(BuildContext context) {
    context.go('/videoPage');
  }

  _onCamera(BuildContext context) {
    context.go('/cameraPage');
  }

  /*
      _onSubmission:
    The following function either enters all information related to the current 
    paitent to the database and reroutes the user to the new page, or sends a 
    working to the user if they have not submitted any media in relation to the 
    patient. 
  */
  _onSubmission(BuildContext context) async {
    if (newPatient.videoPaths.isEmpty && newPatient.imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Need at least 1 image/video'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      await submitPatient(newPatient);
      await cleanupPatientData(newPatient);
      context.go('/submissionMadePage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Please enter input through the following methods:')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _onVideo(context);
              },
              child: Text('Video Entry'),
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
