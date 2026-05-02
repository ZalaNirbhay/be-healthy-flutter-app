import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:be_healthy/pages/login.dart';
import 'package:be_healthy/pages/register.dart';
import 'package:be_healthy/pages/profile_setup.dart';
import 'package:be_healthy/pages/dashboard.dart';
import 'package:be_healthy/pages/profile_setting.dart';
import 'package:be_healthy/pages/food_tracker.dart';
import 'package:be_healthy/pages/maintain_calories.dart';
import 'package:be_healthy/widgets/auth_wrapper.dart';
import 'firebase_options.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const Login(),
        '/register': (context) => const register(),
        '/profile-setup': (context) => const ProfileSetup(),
        '/main': (context) => const Dashboard(),
        '/profile-setting': (context) => const ProfileSetting(),
        '/food-tracker': (context) => const FoodTracker(),
        '/maintain-calories': (context) => const MaintainCalories(),
      },
    );
  }
}
