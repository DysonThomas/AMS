import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:telsim_attendance/Screen/Homescreen.dart';
import 'package:telsim_attendance/Screen/loginPage.dart';

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({Key? key}) : super(key: key);

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    // Small delay for splash effect (optional)
    await Future.delayed(Duration(seconds: 1));

    try {
      String? token = await storage.read(key: 'token');
      String? user = await storage.read(key: 'user');

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        // User is logged in - go to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Homescreen()),
        );
      } else {
        // User is not logged in - go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Loginpage()),
        );
      }
    } catch (e) {
      // Error reading token - go to login
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Loginpage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C3E50),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo here (optional)
            Text(
              'Attendo',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}