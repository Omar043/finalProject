import 'package:cloud_firestore/cloud_firestore.dart';

/*
    CFStorage:
  class used to interact with the firebase storage database
  
  The following has been a modified version of the starter code from the example
  as shown in class.
*/
class UserData {
  final int id;
  final String userName;

  UserData({required this.id, required this.userName});

  factory UserData.fromFirestore(Map<String, dynamic> data) {
    return UserData(id: data['id'] ?? 0, userName: data['name'] ?? '');
  }
}

class CFStorage {
  bool kDebugMode = true;

  Future<void> writeValues(String newUser, int id) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    firestore
        .collection('counterCollection')
        .doc('xZBYhlV8IHQjEEJWq99M')
        .set({'name': newUser, 'id': id})
        .then((value) {
          if (kDebugMode) {
            print('count updated successfully');
          }
        })
        .catchError((error) {
          if (kDebugMode) {
            print('writeCounter error: $error');
          }
        });
  }

  Future<UserData> readValues() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot ds = await firestore
        .collection('counterCollection')
        .doc('xZBYhlV8IHQjEEJWq99M')
        .get();

    if (ds.data() != null) {
      final data = ds.data() as Map<String, dynamic>;
      return UserData.fromFirestore(data);
    } else {
      if (kDebugMode) {
        print('readCounter error for csci567 doc');
      }
      final data = ds.data() as Map<String, dynamic>;
      return UserData.fromFirestore(data);
    }
  }
}
