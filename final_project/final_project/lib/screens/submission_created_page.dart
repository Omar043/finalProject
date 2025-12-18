import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubmissionMadePage extends StatefulWidget {
  const SubmissionMadePage({super.key});
  @override
  State<SubmissionMadePage> createState() => _SubmissionMadePageState();
}

/*
    _SubmissionMadePageState
  The following is a page that allows users to be redirected to the patient entry page
*/
class _SubmissionMadePageState extends State<SubmissionMadePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("SubmissionMadePage")),
        body: Center(
            child: ElevatedButton(
                onPressed: () {
                  context.go('/');
                },
                child: const Text("Add new patient"))));
  }
}
