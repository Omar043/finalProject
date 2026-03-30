//The account creation page should be viewed after the user selects create an account in the sign in page
//user can choose to sign in or create an account
//creating an account requires a username and password
//after creating an account, popup will let user know

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';                                    //for json code
import 'package:term_project/global_vars.dart' as globals; //has username var
import 'package:go_router/go_router.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscured = true;

  /*
      The following function handles the user sign in request. First, it is 
      ensured that all fields are entered. Then, the username and password are
      sent to the express server for processing. If the username and password
      are valid, we get a return type of 200, else the attempt was unsuccessful
  */
  Future<bool> verifyUser() async {
    var username = _usernameController.text;
    var password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      print("missing data fields");
      return false;
    }

    final dataToSend = {'username': username, 'password': password};
    var url = Uri.http('localhost:3001', '/loginRequest');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(dataToSend),
    );

    //if we recieve anything but 400, means that there is problem with login.
    if (response.statusCode != 200) {
      print("login attempt unsuccessful ${response.statusCode}");
      return false;
    }
    //transition user to main page
    else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: ListView(
        children: [
          const Divider(),
          Text("Username:"), //Username input
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
          Text("Password:"), //Password Input
          //text input field (should be hidden)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              obscureText: _isObscured,
              controller: _passwordController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(35)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              bool result = await verifyUser();
              if (result == true) {
                if (context.mounted) {
                  globals.username = _usernameController.text;
                  context.go("/home");
                }
              } else {
                //print failed sign in message here
              }
            },
            child: Text('Sign In'),
          ),
          /*
              NEED TO CREATE SIGN UP BUTTON THAT REDIRECTS USER TO THE SIGN UP OPTION
          */
          TextButton(
            onPressed: () {
              context.go("/sign-up");
            },
            child: Text('Or create an account'),
          ),
        ],
      ),
    );
  }
}
