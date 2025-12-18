/*
    camera_screen.dart:
  The following file stores classes and functions that are in charge of both 
  loading the camera screen page and handling various user inputs such as taking
  a picture and exiting from the page.
*/
import 'package:final_project/models/patient_data.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

/*
    _getCameraController:
  Wrapper function for availableCameras, returns list of available cameras.
*/
Future<List<CameraDescription>> _getCameraController(
  BuildContext context,
) async {
  List<CameraDescription> cameras = await availableCameras();
  return cameras;
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
  const CameraScreenPage({super.key});

  @override
  State<CameraScreenPage> createState() => CameraPageState();
}

class CameraPageState extends State<CameraScreenPage> {
  //The following are vars needed to manage the state of the camera.
  List<CameraDescription> cameras = [];
  late CameraController controller;
  late Future<void>? initController;

  @override
  void initState() {
    super.initState();
    initalizeCamera();
  }

  /*
      initalizeCamera():
    The following function handles the connection to the mobile phone camera.
    First, a list of available cameras is retrieved, and if possible, the 
    controller is connected to the camera with certain presets set.
  */
  Future<void> initalizeCamera() async {
    try {
      cameras = await _getCameraController(context);  //origional call, can fail
      if (cameras.isEmpty) {
        return;
      }
      controller = CameraController(  //controller initalized if camera found
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      setState(
        () {
          initController = controller
              .initialize(); //the camera is connected to the initalizer
        },
      );
    } catch (e) {
      print("error initalizing camera");
    }
  }

  @override
  void dispose() {
    if (initController != null) {
      controller.dispose();
    }
    super.dispose();
  }

  /*
      getImageFilePath:
    Helper function for retrieving the location of an image enerated by the user
  */
  Future<String> getImageFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  /*
      takePicture:
    The following function makes a call to the camera controller to take a 
    picture, and if successful, the image is added to the patient information
  */
  Future<void> takePicture() async {
    if (!controller.value.isInitialized || controller.value.isTakingPicture) {
      return;
    }
    try {
      await initController;
      final XFile image = await controller.takePicture();
      final path = await getImageFilePath();
      await File(image.path).copy(path);

      newPatient.imagePaths.add(path);
    } catch (e) {
      print("issue taking picture");
    }
  }

  @override
  Widget build(BuildContext context) {
    void onReturn() {
      //the following function returns the user to the input page
      if (context.mounted) {
        context.go('/inputPage');
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text("Take Photo")),
      //check for controller being initalized. If yes, camera gets loaded. 
      //If not, loading screen gets loaded
      body: initController ==
              null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
            //FutureBuilder has to be placed in lieu of other widgets because
            //of possibility of camera controller being retrieved late
              future:
                  initController,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      //Positioned.fill forces the camers to take up majority of
                      //screen space
                      Positioned.fill(
                        child: CameraPreview(controller),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  //dummy code for camera not being loaded
                  return const Center(
                      child: Text(
                          'Camera error: Check permissions or if another app is using the camera.'));
                }
                //if no error but snapshot still loading, it means that page 
                //is still loading.
                else {
                  return const Center(
                      child:
                          CircularProgressIndicator());
                }
              },
            ),
      //button for taking photo
      floatingActionButton: FloatingActionButton(
        onPressed: takePicture,
        child: const Icon(Icons.camera_alt),
      ),
      persistentFooterButtons: [
        //return button used for returning to home page
        ElevatedButton(
          onPressed: onReturn,
          child: const Text("Return to input page"),
        ),
      ],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
