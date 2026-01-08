import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Be Healthy"),
      ),
      body: Center(
        child: Container(
          height: 100,
          width: 100,
          child: Text("Be Healthy",style: TextStyle(fontSize: 20,fontWeight:FontWeight.bold),),
        ),
      ),
    );
  }
}
