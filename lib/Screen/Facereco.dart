import 'package:flutter/material.dart';
import '../Camera/myHomeCamera.dart';
import '../components/myDrawer.dart';

class Facedetect extends StatefulWidget {
  const Facedetect({super.key});

  @override
  State<Facedetect> createState() => _FacedetectState();
}

class _FacedetectState extends State<Facedetect> {
  final GlobalKey<MycameraState> cameraKey = GlobalKey<MycameraState>();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Mycamera(key: cameraKey),
          ],
        ));
  }
}
