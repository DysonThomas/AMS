
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
      appBar: AppBar(

        title: const Text(
          'Telsim',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 6,
      ),
      body: SafeArea(
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LiveClock(),
            Facedetect(),
          ],
        )
      ),
    );
  }
}
