/*
    sign_in_page.dart:
  The following page is in charge of handling the user authentication.
  The user has the ability to enter their username and password, and the 
  page will handle the request to the firebase server.
*/
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import "package:final_project/user_auth.dart";

class SigninPage extends StatefulWidget {
  const SigninPage({super.key, required this.failedLoginFlag});

  final bool failedLoginFlag;

  @override
  State<SigninPage> createState() => _SigninPageState();
}

/*
    _SigninPageState:
  The following is the implimentation for the sign in page.
  The user must enter their name and password in correctly, or else they will 
  not be permitted to enter the application.
*/
class _SigninPageState extends State<SigninPage> {
  bool isAuthenticating =
      false; //had to add signal to stop user from trying to authenticate twice
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  /*
      _handleAuthAttempt:
    Function responsible for determining if a user's authentication request is 
    valid.
    First checks that the user has not entered a request yet to ensure two 
    identical requests.
    Then passes in values stored in textfields to the firebase api. 
    If string returned from firebase api returns as positive, the user can 
    proceed to the user severity page, else they are rediredted to the sign in 
    page.
  */
  Future<void> _handleAuthAttempt() async {
    if (isAuthenticating) {
      return;
    }

    setState(() {
      isAuthenticating = true;
    });

    String? authAttempt = await signIn(_username.text, _password.text);

    if (!mounted) {
      return;
    }

    setState(() {
      isAuthenticating = false;
    });

    if ((authAttempt != "Authentication failed") &&
        (authAttempt != "An unknown error occured") &&
        authAttempt != null) {
      uid = authAttempt;
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed. $authAttempt'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Ourobre Sign In',
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //title: username
            Text(
              'Username:',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                letterSpacing: 2.0,
              ),
            ),
            //entry box for username
            TextField(
              controller: _username,
            ),

            //title: password
            Text(
              'Password:',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                letterSpacing: 2.0,
              ),
            ),
            //entry box for password
            TextField(
              controller: _password,
              obscureText: true,
            ),

            ElevatedButton(
              //the following func checks if the user is currently being authed
              onPressed: isAuthenticating ? null : _handleAuthAttempt,
              child: () {
                if (isAuthenticating == true) {
                  return const CircularProgressIndicator();
                } else {
                  return const Text('Sign In');
                }
              }(),
            ),
          ],
        ),
      ),
    );
  }
}
