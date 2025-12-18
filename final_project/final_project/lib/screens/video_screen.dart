/*
    video_screen.dart:
  The following file is in charge of creating the video page and managing the 
  state of the resources(camera) being used. The user may click on the record
  button to start recording, and must click on it again to end recording.
  If the user exits the page while the recording is still in progress,
  the input is forcibly saved.
*/
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:final_project/models/patient_data.dart';

/*
    _getCameraController:
  the following funcion is a simple wrapper for the availableCameras function
  that returns its output. 
*/
Future<List<CameraDescription>> _getCameraController(
  BuildContext context,
) async {
  List<CameraDescription> cameras = await availableCameras();
  return cameras;
}

class VideoScreenPage extends StatefulWidget {
  const VideoScreenPage({super.key});

  @override
  State<VideoScreenPage> createState() => VideoPageState();
}

/*
    VideoPageState:
  The following class is a page that presents a preview of the recorded input of
  the user's device. At the bottom of the screen are navigaiton options.
*/
class VideoPageState extends State<VideoScreenPage> {
  //The following vars are used in the handling of the camera.
  List<CameraDescription> cameras = [];
  late CameraController controller;
  late Future<void> initController;
  late CameraDescription firstCamera;

  bool isRecording =  //var in charge of handling the controller state
      false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /*
      _initializeCamera:
    The following function is responsible for the camera setup
    It first handles retrieving the list of available cameras thru 
    _getCameraController, and the subsequently sets up the controller. 
    The page is then reloaded to account for this change.
  */
  Future<void> _initializeCamera() async {
    cameras = await _getCameraController(context);
    controller =
        CameraController(cameras[0], ResolutionPreset.high, enableAudio: true);
    initController = controller.initialize();

    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  //simple wrapper for getApplicationDocumentsDirectory, simply formats the 
  //path to the file that has been recorded
  Future<String> getVideoFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
  }

  /*
      recordVideo:
    The following is a wrapper for the startVideoRecording function, also sets
    the isRecording value as true for stability purpouses
  */
  void recordVideo() async {
    if (!controller.value.isInitialized) {
      return;
    }
    await controller.startVideoRecording();
    setState(() => isRecording = true);
  }

  /*
      stopRecording
    A wrapper forthe stopVideoRecording function.
    Sets the isRecording value to be false, and adds the reference of the 
    newly created video to the patient struct.
  */
  Future<void> stopRecording() async {
    if (!controller.value.isInitialized) {
      return;
    }
    final XFile videoFile = await controller.stopVideoRecording();
    setState(() => isRecording = false);

    newPatient.videoPaths.add(videoFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Record Video")),

        //page "chooses" to either return the camera preview or a progress
        //circle, depending on if the camera has been connected
        body: FutureBuilder<void>(
            future: initController,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return CameraPreview(controller);
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (isRecording) {
                stopRecording();
              } else {
                recordVideo();
              }
            },
            // the isRecording var is in charge of the icon state
            // if recording, we show the user the stop option, else they get 
            // the video option
            child: Icon(isRecording
                ? Icons.stop
                : Icons
                    .videocam)),
        persistentFooterButtons: [
          ElevatedButton(
              onPressed: () async {
                if (isRecording) {
                  await stopRecording();
                }
                if (context.mounted) {
                  context.go('/inputPage');
                }
              },
              child: Text("return to input page")),
        ]);
  }
}
