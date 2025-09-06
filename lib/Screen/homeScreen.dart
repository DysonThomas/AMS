import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:telsim_attendance/Camera/myCamera.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // uncomment/replace your AppBar if you want
      appBar: AppBar(
        title: const Text(
          'Telsim',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 6,
      ),
      body: SafeArea(
        child:Mycamera()
      ),
    );
  }
}
