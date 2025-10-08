
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telsim_attendance/Screen/Facereco.dart';
import 'package:telsim_attendance/components/myDrawer.dart';

import '../components/myClock.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  @override
  void initState() {
    super.initState();
    // Disable system navigation (Android only)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [SystemUiOverlay.top], // Keep only status bar
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     drawer: Mydrawer(currentRoute: 'home',),
      appBar:AppBar(
        toolbarHeight: 80.0,
        iconTheme: IconThemeData(
          color: Colors.white70,
        ),
        backgroundColor: const Color(0xFF2C3E50),
        title: const Text(
          'Attendo',
          style: TextStyle(fontWeight: FontWeight.bold,
              color: Colors.white70

          ),
        ),
        centerTitle: true,
        elevation: 6,
      ),
      body: SafeArea(
        child:Padding(
          padding: const EdgeInsets.all(15.0),
          child: Card(
            elevation: 5, // Shadow depth
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Color(0xFF2C3E50),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LiveClock(),
                  Facedetect(),
                ],
              ),
            ),
          ),
        )
      ),
    );
  }
}
