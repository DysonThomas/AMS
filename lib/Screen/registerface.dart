
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:telsim_attendance/Functions/detectFace.dart';
import 'package:telsim_attendance/Functions/embedface.dart';
import 'package:telsim_attendance/components/MyButton.dart';
import 'package:telsim_attendance/components/textBox.dart';
import '../Camera/myCamera.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:telsim_attendance/constants.dart';
import 'dart:typed_data';
import '../components/myDrawer.dart';

class RegisterFace extends StatefulWidget {
  const RegisterFace({super.key});

  @override
  State<RegisterFace> createState() => _RegisterFaceState();
}

class _RegisterFaceState extends State<RegisterFace> {
  final GlobalKey<MycameraState> cameraKey = GlobalKey<MycameraState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  XFile? capturedImage;
  late FaceDetector faceDetector;
  img.Image? croppedFace;
  Uint8List? displayFace;
  bool showErrorScaffold = false;
  List<double>? faceEmbedding;
  final FaceEmbedding _faceEmbeddingService = FaceEmbedding();
  bool isProcessing = false;
  bool isModelLoaded = false;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.top]);
    super.initState();
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
    _initializeFaceEmbedding();
  }
  Future<void> _initializeFaceEmbedding() async {
    setState(() {
      isProcessing = true;
    });

    try {
      await _faceEmbeddingService.loadModel();
      setState(() {
        isModelLoaded = true;
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isModelLoaded = false;
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to load model: $e Contact you Manager"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
//   fINDING fACE AND cROPPING IT and  embedding
void ONDetectFace(XFile file) async{
    try{
      final detector = DetectFace();
      final faceImage = await detector.detectFace(file, faceDetector);


      if (faceImage == null) {
        setState(() {
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ No face or multiple faces detected"),
          ),
        );
        return;
      }
      final croppedBytes = Uint8List.fromList(img.encodeJpg(faceImage));
      // Generate face embedding
      print('Generating face embedding...');
     await _faceEmbeddingService.loadModel();
      final embedding = await _faceEmbeddingService.generateEmbedding(faceImage);

      if (embedding != null) {
        setState(() {
          croppedFace = faceImage;
          faceEmbedding = embedding;
          isProcessing = false;
          displayFace=croppedBytes;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Face processed! Embedding: ${embedding.length} features"),
            backgroundColor: Colors.green,
          ),
        );

        // Debug print
        print('Embedding generated successfully!');
        print('Embedding length: ${embedding.length}');
        print('Sample values: ${embedding.take(5).toList()}');
      } else {
        setState(() {
          isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Failed to generate embedding"),
            backgroundColor: Colors.red,
          ),
        );
    }}

    catch(e){
      setState(() {
        isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      print('Face processing error: $e');

    }
}
Future<void> onRegisterButPressed() async {
  if (faceEmbedding == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No face embedding. Capture and detect face first!"))
    );
    return;
  }
    try{

      var url = Uri.parse("$apiBaseUrl/users");
      var response = await http.post(url,headers: {
        "Content-Type": "application/json",
      },
          body: jsonEncode({
            "userID": _idController.text,
            "userName": _nameController.text,
            "faceembed":faceEmbedding
          })
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Employee Registered")),
        );
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ssue: ${response.body}")),
        );
      }
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    }

  setState(() {
    _idController.clear();
    _nameController.clear();
    capturedImage = null;
    croppedFace = null;
  });
}
void onRetakeButPressed(){
  setState(() {
    capturedImage = null;
    croppedFace = null;
  });
}  @override
  void dispose() {
    faceDetector.close();
    _faceEmbeddingService.dispose();
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey,
        drawer: Mydrawer(currentRoute: 'register',),
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white70, // 👈 your custom color
          ),
          backgroundColor: Colors.grey[700],
          title: const Text(
            'Telsim',
            style: TextStyle(fontWeight: FontWeight.w600,
                color: Colors.white70

            ),
          ),
          centerTitle: true,
          elevation: 6,
        ),
      // uncomment/replace your AppBar if you wan
      body: SafeArea(
          child:Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Camera Section
                if (croppedFace == null) ...[
                  Mycamera(key: cameraKey),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final image = await cameraKey.currentState?.capture();
                      setState(() {
                        capturedImage = image;
                      });
                      ONDetectFace(image!);
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
                if (croppedFace != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3), // Black shadow with transparency
                          blurRadius: 8,
                          offset: Offset(0, 4), // Shadow position (x, y)
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40), // Same radius as container
                      child: Image.memory(
                        displayFace!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Employee ID
                  MyTextBox(controller: _idController, label: "Employee ID"),
                  const SizedBox(height: 16),
                  MyTextBox(controller: _nameController, label: "Employee Name"),
                  const SizedBox(height: 24),
                  // Register Button
                  MyButton(text: "Register", onPressed:onRegisterButPressed),
                  const SizedBox(height: 12),
                  MyButton(text: "Retake Image", onPressed: onRetakeButPressed),
                  const SizedBox(height: 12),


                ],
              ],
            ),
          )
      )
    );
  }
}
