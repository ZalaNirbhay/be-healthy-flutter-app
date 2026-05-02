import 'package:flutter/material.dart';
import 'package:be_healthy/services/auth_service.dart';
import 'dart:io';
import '../pages/dashboard.dart';
import '../pages/profile_setting.dart';

// 🔹 REUSABLE PROFILE ICON — Now shows dynamic user photo
Widget buildProfileIcon(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetting()),
      );
    },
    child: FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.getUserDocument(),
      builder: (context, snapshot) {
        String photoUrl = "";
        if (snapshot.hasData && snapshot.data != null) {
          photoUrl = snapshot.data!['photo_url'] ?? "";
        }

        return Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            backgroundImage: photoUrl.isNotEmpty
                ? (AuthService.isLocalFile(photoUrl)
                    ? FileImage(File(photoUrl))
                    : NetworkImage(photoUrl)) as ImageProvider
                : null,
            child: photoUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.green)
                : null,
          ),
        );
      },
    ),
  );
}

// 🔹 REUSABLE TOP BAR
Widget buildTopBar(BuildContext context, String title, {bool isDashboard = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      
      // ✅ Dynamic Left Navigation Element
      if (isDashboard)
        Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, size: 28),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        )
      else
        GestureDetector(
          onTap: () {
            // ✅ Fallback to Dashboard if pushed from a stackless context 
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Dashboard()),
              );
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(5.0),
            child: Icon(Icons.arrow_back, size: 28),
          ),
        ),

      // ✅ Standardized Title
      Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ✅ Reusable Profile Icon — Now dynamic
      buildProfileIcon(context),
    ],
  );
}
