import 'package:flutter/material.dart';

class profile_setup extends StatefulWidget {
  const profile_setup({super.key});

  @override
  State<profile_setup> createState() => _profile_setupState();
}

class _profile_setupState extends State<profile_setup> {
  String activityLevel = "Moderate Exercise";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFFDFF5EA),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Profile Setup",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // colors: [Color(0xFFDFF5EA), Color(0xFFF5F5F5)],
            colors: [Color(0xFFDFF5EA), Color(0xFFF5F5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 10),
                Text(
                  "Be Healthy",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Tell Us About Yourself To Personalize",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            " Your Health Journey ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),
                Container(
                  width: 320,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [


                          SizedBox(height: 8),

                          TextField(
                            decoration: InputDecoration(
                              hintText: "Enter Your Age",
                              prefixIcon: Icon(Icons.cake_rounded),

                              filled: true,
                              fillColor: Color(0xFFF5F5F5),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          SizedBox(height: 30),

                          // ignore: sized_box_for_whitespace
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 2,
                                bottom: 2,
                                left: 5,
                                right: 5,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      child: Text("Male"),
                                    ),
                                  ),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      child: Text("Female"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 2,
                                bottom: 2,
                                left: 5,
                                right: 5,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.height,
                                          color: Colors.black,
                                        ),
                                        hintText: "Height",
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 15,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.line_weight,
                                          color: Colors.black,
                                        ),

                                        hintText: "Weight",
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 15,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          Text(
                            "Activity Level",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(height: 8),

                          DropdownButtonFormField<String>(
                            value: activityLevel,

                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.directions_run),
                              filled: true,
                              fillColor: Color(0xFFF5F5F5),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),

                            items:
                                [
                                  "Sedentary",
                                  "Light Exercise",
                                  "Moderate Exercise",
                                  "Heavy Exercise",
                                  "Athlete",
                                ].map((level) {
                                  return DropdownMenuItem(
                                    value: level,
                                    child: Text(level),
                                  );
                                }).toList(),

                            onChanged: (value) {
                              setState(() {
                                activityLevel = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
