import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSetup extends StatefulWidget {
  const ProfileSetup({super.key});

  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {
  String selectedGender = "male";
  String selectedGoal = "weight_loss";
  String activityLevel = "Moderate Exercise";

  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  bool isLoading = false;

  Future<void> saveProfile() async {
    try {
      setState(() => isLoading = true);

      String uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'age': int.tryParse(ageController.text) ?? 0,
        'gender': selectedGender,
        'height_cm': int.tryParse(heightController.text) ?? 0,
        'weight_kg': int.tryParse(weightController.text) ?? 0,
        'activity_level': activityLevel,
        'goal': selectedGoal,
        'profile_completed': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error saving data")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget pillInput({required Widget child}) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Color(0xFFF2F5F3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: child,
    );
  }

  Widget toggleButton(String text, String value, String group) {
    bool selected = value == group;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (group == selectedGender) {
              selectedGender = value;
            } else {
              selectedGoal = value;
            }
          });
        },
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: selected ? Colors.green.shade50 : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: selected ? Colors.green : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDFF5EA),
      body: SafeArea(
        child: Stack(
          children: [
            // BACKGROUND GRADIENT
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB6F0D2),
                    Color(0xFFDFF5EA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // MAIN CONTENT
            SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 10),

                  // TOP BAR
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Profile Setup",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      SizedBox(width: 48),
                    ],
                  ),

                  SizedBox(height: 10),

                  Text(
                    "BeHealth",
                    style:
                    TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Tell us about yourself to personalize\nyour health plan",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),

                  SizedBox(height: 30),

                  // CARD
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Age"),
                        SizedBox(height: 8),
                        pillInput(
                          child: TextField(
                            controller: ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "Enter your age",
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.cake),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        Text("Gender"),
                        SizedBox(height: 8),
                        pillInput(
                          child: Row(
                            children: [
                              toggleButton("Male", "male", selectedGender),
                              toggleButton("Female", "female", selectedGender),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text("Height (cm)"),
                                  SizedBox(height: 8),
                                  pillInput(
                                    child: TextField(
                                      controller: heightController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        prefixIcon: Icon(Icons.height),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                children: [
                                  Text("Weight (kg)"),
                                  SizedBox(height: 8),
                                  pillInput(
                                    child: TextField(
                                      controller: weightController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        prefixIcon:
                                        Icon(Icons.fitness_center),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20),

                        Text("Activity Level"),
                        SizedBox(height: 8),
                        pillInput(
                          child: DropdownButtonFormField<String>(
                            value: activityLevel,
                            decoration:
                            InputDecoration(border: InputBorder.none),
                            items: [
                              "Sedentary",
                              "Light Exercise",
                              "Moderate Exercise",
                              "Heavy Exercise",
                              "Athlete",
                            ].map((e) {
                              return DropdownMenuItem(
                                  value: e, child: Text(e));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => activityLevel = val!),
                          ),
                        ),

                        SizedBox(height: 20),

                        Text("Fitness Goal"),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            toggleButton(
                                "Lose", "weight_loss", selectedGoal),
                            toggleButton("Maintain", "maintain",
                                selectedGoal),
                            toggleButton(
                                "Gain", "weight_gain", selectedGoal),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // BUTTON
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Save & Continue →",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  Text(
                    "You can update these details anytime from your profile settings.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}