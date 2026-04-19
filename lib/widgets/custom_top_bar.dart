import 'package:flutter/material.dart';
import '../pages/dashboard.dart';
import '../pages/profile_setting.dart';

// 🔹 REUSABLE PROFILE ICON
Widget buildProfileIcon(BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetting()),
      );
    },
    child: Container(
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
      child: const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        child: Icon(Icons.person, color: Colors.green),
      ),
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

      // ✅ Reusable Profile Icon
      buildProfileIcon(context),
    ],
  );
}
