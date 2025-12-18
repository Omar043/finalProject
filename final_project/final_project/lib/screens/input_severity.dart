import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:final_project/models/patient_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/*
    _HomeScreenState:
  The following is the first page that appears when entering in a new patient 
  into the system. The user can specify of which severity the patient condition 
  is in by selecting one of two options. 
*/
class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter severity of situation',
            style: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            )),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                newPatient.patientType = "emergency";
                context.go('/inputPage');
              },
              child: Text('Emergency'),
            ),
            ElevatedButton(
              onPressed: () {
                newPatient.patientType = "urgent";
                context.go('/inputPage');
              },
              child: Text('Urgent'),
            ),
          ],
        ),
      ),
    );
  }
}
