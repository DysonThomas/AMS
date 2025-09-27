import 'package:flutter/material.dart';
import '../Camera/MyHomeCamera.dart';

class Facedetect extends StatefulWidget {
  const Facedetect({super.key});

  @override
  State<Facedetect> createState() => _FacedetectState();
}

class _FacedetectState extends State<Facedetect> {
  final GlobalKey<MyHomeCameraState> cameraKey = GlobalKey<MyHomeCameraState>();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyHomecamera(key: cameraKey),
          ],
        ));
  }
}
