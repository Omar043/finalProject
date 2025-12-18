import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final db = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;
String uid = '';

/*
    signIn:
  The following function makes an api call to the google firebase authentication 
  server to ensure that the user credentials were correct and existed. On 
  success, the user id is returned. On failiure, an error message is returned, 
  depending on the issue.
*/
Future<String?> signIn(String email, String password) async {
  try {
    final userCredential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user?.uid;
  } on FirebaseAuthException catch (e) {
    if ((e.code == 'user-not-found') || (e.code == 'wrong-password')) {
      return "Authentication failed";
    }
  } catch (e) {
    return 'An unknown error occured';
  }
  return "An unknown error occured";
}
