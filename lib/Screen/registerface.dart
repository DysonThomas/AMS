
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:telsim_attendance/Functions/embedface.dart';
import '../Camera/myCamera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';


class RegisterFace extends StatefulWidget {
  const RegisterFace({super.key});

  @override
  State<RegisterFace> createState() => _RegisterFaceState();
}

class _RegisterFaceState extends State<RegisterFace> {
  final GlobalKey<MycameraState> cameraKey = GlobalKey<MycameraState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final embface = Embedface();
  XFile? capturedImage;
  late FaceDetector _faceDetector;
  img.Image? croppedFace;
  Uint8List? croppedFaceBytes;
  late Interpreter interpreter;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
loadModel();
  }
  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }
  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('mobile_face_net.tflite');
  }
  Future<void> detectFace(XFile image) async{
    try{
      final InputImage inputImage = InputImage.fromFilePath(image!.path);
      final faces = await _faceDetector.processImage(inputImage);
      print(faces.length);
      final imageBytes = await image.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage != null && faces.isNotEmpty && faces.length <= 1) {
        print("inside");
        final face = faces.first;
        final boundingBox = face.boundingBox;
        final x = boundingBox.left.toInt().clamp(0, originalImage.width - 1);
        final y = boundingBox.top.toInt().clamp(0, originalImage.height - 1);
        final w = boundingBox.width.toInt().clamp(1, originalImage.width - x);
        final h = boundingBox.height.toInt().clamp(1, originalImage.height - y);

        final cropped = img.copyCrop(
          originalImage,
          x: x,
          y: y,
          width: w,
          height: h,
        );
        final inputSize = 112;
        final resizedFace = img.copyResize(cropped, width: inputSize, height: inputSize);
        final croppedBytes = Uint8List.fromList(img.encodeJpg(resizedFace));

        setState(() async {

          croppedFace = resizedFace;
          print('Cropped image width: ${croppedFace!.width}');
          print('Cropped image height: ${croppedFace!.height}');// keeps the img.Image if you want to process further
          croppedFaceBytes = croppedBytes; // you can display this with Image.memory
          final embedding = await getEmbedding(croppedFace!);
        });
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please try Again")),
        );
      }
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please try Again")),
      );
    }

  }
  Future<List<double>> getEmbedding(img.Image face) async {
    final inputSize = 112;
    final input = embface.imageToByteListFloat32(face, inputSize);

    var output = List.filled(1 * 192, 0.0).reshape([1, 192]); // output for MobileFaceNet
    interpreter.run(input, output);

    return List<double>.from(output[0]);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // uncomment/replace your AppBar if you wan
      body: SafeArea(
          child:Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Camera Section
                if (croppedFaceBytes == null) ...[
                  Mycamera(key: cameraKey),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final image = await cameraKey.currentState?.capture();
                      setState(() {
                        capturedImage = image;
                      });
                      detectFace(image!);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Capture Image", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      elevation: 6,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],

                // Registration Section
                if (croppedFaceBytes != null) ...[
                  const SizedBox(height: 24),

                  // Employee ID
                  TextField(
                    controller: _idController,
                    decoration: InputDecoration(
                      labelText: "Employee ID",
                      labelStyle: const TextStyle(fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Employee Name
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Employee Name",
                      labelStyle: const TextStyle(fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Registration logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Employee Registered")),
                        );
                        setState(() {
                          _idController.clear();
                          _nameController.clear();
                          croppedFaceBytes = null;
                          capturedImage = null;
                          croppedFace = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text("Register", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Retake Image Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          croppedFaceBytes = null;
                          capturedImage = null;
                          croppedFace = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.grey, width: 2),
                      ),
                      child: const Text("Retake Image", style: TextStyle(fontSize: 16, color: Colors.blue)),
                    ),
                  ),
                  // if (croppedFaceBytes != null)
                  //   Image.memory(
                  //     croppedFaceBytes!,
                  //     width: 150,
                  //     height: 150,
                  //     fit: BoxFit.cover,
                  //   ),
                ],
              ],
            ),
          )
      )
    );
  }
}
