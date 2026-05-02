import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:be_healthy/pages/login.dart';
import 'package:be_healthy/pages/profile_setup.dart';
import 'package:be_healthy/pages/dashboard.dart';

/// AuthWrapper — Runs on app start, decides navigation automatically.
///
/// IF user == null → Login Page
/// ELSE → Fetch Firestore document
///   IF profile_completed == false → Profile Setup Page
///   ELSE → Dashboard (Home Page)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFDFF5EA),
            body: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        // No user logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const Login();
        }

        // User is logged in — check profile status
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, docSnapshot) {
            // Loading Firestore data
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFDFF5EA),
                body: Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
              );
            }

            // No Firestore document — send to profile setup
            if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
              return const ProfileSetup();
            }

            // Check profile_completed flag
            final data = docSnapshot.data!.data() as Map<String, dynamic>;
            final bool profileCompleted = data['profile_completed'] ?? false;

            if (profileCompleted) {
              return const Dashboard();
            } else {
              return const ProfileSetup();
            }
          },
        );
      },
    );
  }
}
