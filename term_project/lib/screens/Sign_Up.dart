//The account creation page should be viewed after the user selects create an account in the sign in page
//user can choose to sign in or create an account
//creating an account requires a username and password
//after creating an account, should be redirected to the sign in page

import 'package:flutter/material.dart';
import 'package:http/http.dart'
    as http; //for sending requests and recieving responses from the server
import 'dart:convert'; //for json code
import 'package:go_router/go_router.dart'; //for setting up the router

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /*
      The following function processes the username and password, and checks if
      they are valid for a new account. If they are, true is returned, else
      false.
  */
  Future<bool> createNewUser() async {
    //check if both fields contain a value
    //if yes, send to server
    //else if no, send to
    var username = _usernameController.text;
    var password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      //badmsg
      return false;
    }

    final dataToSend = {'username': username, 'password': password};
    var url = Uri.http('localhost:3001', '/signupRequest');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(dataToSend),
    );

    //if user already exists error message
    if (response.statusCode == 409) {
      print("username already exists");
      return false;
    }

    //if creation attempt successful, reroute to sign in screen
    if (response.statusCode == 201) {
      print("account creation success");
      return true;
    } else if (response.statusCode == 500) {
      print("server error");
      return false;
    } else {
      print("unknown error");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: ListView(
        children: [
          const Divider(),
          Text("Username:"),

          //referenced from flutter example
          //text input field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
              ),
              controller: _usernameController,
            ),
          ),

          Text("Password:"),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              obscureText: true,
              controller: _passwordController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
              ),
            ),
          ),

          TextButton(
            onPressed: () async {
              bool accountCreationStatus = await createNewUser();
              if (accountCreationStatus == false) {
                //create green success popup that lets user know that account has been created
                //used following reference: https://api.flutter.dev/flutter/material/AlertDialog-class.html
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('New user was not able to be created'),
                    content: const Text('<CONTEXT HERE>'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Cancel'),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'OK'),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('New user has been created.'),
                    //content: const Text('<CONTEXT HERE>'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'OK'),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text('Create Account'),
          ),

          TextButton(
            onPressed: () {
              if (context.mounted) {
                context.go("/sign-in");
              }
            },
            child: Text('Go back to sign in'),
          ),
        ],
      ),
    );
  }
}
