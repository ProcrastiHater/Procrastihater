///**************************************************************************
/// Name: login_screen.dart
///
/// Description: Creates a page to render the auth_gate on which will manage
/// user sign-in state and allow for account creation/sign-in 
///**************************************************************************
library;

// Dart imports
import 'package:flutter/material.dart';
import 'auth_gate.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthGate(),
    );
  }
}