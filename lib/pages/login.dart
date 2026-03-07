import 'package:flutter/material.dart';

class login extends StatelessWidget {
  const login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFDFF5EA),
              Color(0xFFF5F5F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon( 
                Icons.fitness_center,
                size: 100,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}