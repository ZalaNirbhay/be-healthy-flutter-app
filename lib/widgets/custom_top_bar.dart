import 'package:flutter/material.dart';
import 'package:be_healthy/services/auth_service.dart';
import 'package:be_healthy/services/theme_service.dart';
import 'package:be_healthy/services/notification_service.dart';
import 'dart:io';
import '../pages/dashboard.dart';
import '../pages/profile_setting.dart';

// ðŸ”¹ REUSABLE PROFILE ICON â€” Dynamic with theme support
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ThemeService.isDark
                    ? Colors.black54
                    : Colors.black26,
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: ThemeService.isDark
                ? const Color(0xFF2D4A6E)
                : Colors.white,
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

// ðŸ”¹ NOTIFICATION BELL
Widget buildNotificationBell(BuildContext context) {
  return FutureBuilder<int>(
    future: NotificationService.getUnreadCount(),
    builder: (context, snapshot) {
      final count = snapshot.data ?? 0;
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileSetting()),
          );
        },
        child: Stack(
          children: [
            Icon(Icons.notifications_outlined,
                size: 26, color: ThemeService.textPrimary),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text('$count',
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                      textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      );
    },
  );
}

// ðŸ”¹ REUSABLE TOP BAR â€” Theme-aware
Widget buildTopBar(BuildContext context, String title, {bool isDashboard = false}) {
  // ThemeService accessed directly
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      
      // Left navigation
      if (isDashboard)
        Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu, size: 28, color: ThemeService.textPrimary),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        )
      else
        GestureDetector(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Dashboard()),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Icon(Icons.arrow_back, size: 28, color: ThemeService.textPrimary),
          ),
        ),

      // Title
      Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: ThemeService.textPrimary,
        ),
      ),

      // Right side: notification bell (dashboard) or profile icon
      if (isDashboard)
        Row(
          children: [
            buildNotificationBell(context),
            const SizedBox(width: 10),
            buildProfileIcon(context),
          ],
        )
      else
        buildProfileIcon(context),
    ],
  );
}
