/*
    patient_data.dart:
  The following file stores methods and classes that manage both the state of
  the current patient and the input of the new patient into the system.
*/

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//class that stores paths to audio recordings and images
class PatientDataToSend {
  List<String> imagePaths = [];
  List<String> videoPaths = [];
  String patientType =
      "emergency"; //patientType identifies the severity of the patient status. can be "emergency" or "urgent"

  void clear() {
    //reference deletion function
    imagePaths.clear();
    videoPaths.clear();
  }
}

PatientDataToSend newPatient = PatientDataToSend();

/*
    uploadFile:
  In the following function, the file stored in folder "folder" and of name "localpath"
  is uploaded to the firebase storage database. 
*/
Future<String> uploadFile(String localPath, String folder) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseStorage.instance.ref(
    'uploads/$uid/$folder/${DateTime.now().millisecondsSinceEpoch}', //url creation
  );
  await ref.putFile(File(localPath));
  return await ref
      .getDownloadURL(); //getDownloadUrl returns the status of the uploaded file
}

/*
    uploadPatientMedia:
  uploadPatientMedia accepts the entirety of the data related to the paitent and
  attempts to upload all of these urls to the firebase server
*/
Future<Map<String, List<String>>> uploadPatientMedia(
    PatientDataToSend patient) async {
  List<String> imageUrls = [];
  List<String> videoUrls = [];

  for (final path in patient.imagePaths) {
    //all images related to patient added
    imageUrls.add(await uploadFile(path, 'images'));
  }

  for (final path in patient.videoPaths) {
    //all videos related to patient added
    videoUrls.add(await uploadFile(path, 'videos'));
  }

  return {
    //all of the return url's are returned
    'images': imageUrls,
    'videos': videoUrls,
  };
}

/*
    savePatientRecord
  savePatientRecord creates the record of the new patient in the database, including
  information such as the patient type and media created in relation to the patient
*/
Future<void> savePatientRecord(
  PatientDataToSend patient,
  Map<String, List<String>> mediaUrls,
) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance.collection('patients').add({
    'userId': uid,
    'patient_type': patient.patientType,
    'images': mediaUrls['images'],
    'videos': mediaUrls['videos'],
    'createdAt': FieldValue.serverTimestamp(),
  });
}

/*
    submitPatient:
  submitPatient is a wrapper for patient-data related operations.
  The media related to a patient are first uploaded, and the patient record is 
  subsequently added.
*/
Future<void> submitPatient(PatientDataToSend patient) async {
  final mediaUrls = await uploadPatientMedia(patient);
  await savePatientRecord(patient, mediaUrls);
}

/*
    deleteLocalFiles:
  deleteLocalFiles removes all of the information related to the patient stored
  on the local device. The images and videos are removed in that order.
*/
Future<void> deleteLocalFiles(PatientDataToSend patient) async {
  for (final path in patient.imagePaths) {
    final file = File(path);
    if (await file.exists()) {
      //need to first check if the file exists before it is deleted
      await file.delete();
    }
  }

  for (final path in patient.videoPaths) {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/*
    cleanupPatientData:
  The following function is a wrapper for all of the functions related to the removal
  of patient information. All files related to the patient are deleted, followed up by the 
  references to the patient information stored in the PatientDataToSend class
*/
Future<void> cleanupPatientData(PatientDataToSend patient) async {
  deleteLocalFiles;
  patient.clear();
}
