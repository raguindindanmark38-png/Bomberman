import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF545050),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // Logged in
        if (snapshot.hasData) {
          return const HomePage();
        }

        // Not logged in
        return const LoginPage();
      },
    );
  }
}
