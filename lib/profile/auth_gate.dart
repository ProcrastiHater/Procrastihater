///**************************************************************************
/// Name: auth_gate.dart
///
/// Description: Creates widget that handles user sign in, account creation,
/// and tracking if user is currently signed in.
///**************************************************************************
library;

//Firebase Imports
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

// Dart Imports
import 'package:flutter/material.dart';
import '../main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Creates event listner for if a user signs in
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot){
        // If a user is not signed in display login page
        if (!snapshot.hasData){
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
            ],
           headerBuilder: (context, constraints, shrinkOffset) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset('assets/logo.jpg')
              )
            );
           }
          );
        }
        // If user is signed in run App
        return const ProcrastiHater();
      },      
    );
  }
}
