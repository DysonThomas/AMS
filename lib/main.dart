import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telsim_attendance/Screen/homeScreen.dart';
import 'package:telsim_attendance/Screen/manageEmp.dart';

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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:Homescreen()
    );
  }
}
