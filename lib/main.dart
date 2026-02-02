import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telsim_attendance/Functions/checkAuthScreen.dart';
import 'package:telsim_attendance/Screen/homeScreen.dart';
import 'package:telsim_attendance/Screen/loginPage.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // Optional: allow upside down portrait
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});


  @override

  Widget build(BuildContext context) {
    final storage = FlutterSecureStorage();
    bool isLoading = true;

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home:CheckAuthScreen()
    );
  }
}
