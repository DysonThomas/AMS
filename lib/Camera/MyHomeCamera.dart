
import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:telsim_attendance/Functions/match_face.dart';
import '../Functions/detectFace.dart';
import '../Functions/embedface.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../constants.dart';

class MyHomecamera extends StatefulWidget {
  const MyHomecamera({super.key});

  @override
  State<MyHomecamera> createState() => MyHomeCameraState();
}

class MyHomeCameraState extends State<MyHomecamera> {
  CameraController? _controller;
  bool _initializing = true;
  String? _error;
  img.Image? croppedFace;
  bool _isDetecting = false;
  int? _lastProcessed;
  late FaceDetector faceDetector;
  final FaceEmbedding _faceEmbeddingService = FaceEmbedding();
  bool isProcessing = false;
  bool isModelLoaded = false;
  Uint8List? displayFace;
  final FlutterTts flutterTts = FlutterTts();
  @override
  void initState() {
    super.initState();
    _initCamera();
    faceDetector = FaceDetector(

      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableContours: true,
        enableClassification: true,
      ),
    );
  }
  Future<void> speak(String text) async {
    await flutterTts.setLanguage("en-AU");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  Future<void> _initCamera() async {
    try {
      // 1) Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _initializing = false;
          _error = 'Camera permission denied';
        });
        return;
      }

      // 2) Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'No camera found on this device / emulator';
        });
        return;
      }

      // 3) Prefer front camera if available
      final camera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      // 4) Create and initialize controller
      final controller = CameraController(
        camera,
        ResolutionPreset.high, // Changed from max to medium for better performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,  // Better for ML Kit
      );

      await controller.initialize();

      controller.startImageStream((CameraImage image) async {
        if (_isDetecting) return; // avoid overlapping frames
        _isDetecting = true;
        try {

          final now = DateTime.now().millisecondsSinceEpoch;
          if (_lastProcessed == null || (now - _lastProcessed! ) > 5000) {
            final timestamp = DateTime.now().toIso8601String(); ;
            _lastProcessed = now;
            final XFile picture = await controller.takePicture();
            final detector = DetectFace();
            final faceImage = await detector.detectFace(picture,faceDetector);
            // final faceImage = await detector.detectLiveFace(image, faceDetector,controller);
            if (faceImage != null) {
               final croppedBytes = Uint8List.fromList(img.encodeJpg(faceImage!));
              print('Generating face embedding...');
              await _faceEmbeddingService.loadModel();
              final embedding = await _faceEmbeddingService.generateEmbedding(faceImage);
              if (embedding != null) {
                setState(() async {
                  croppedFace = faceImage;
                  isProcessing = false;
                  displayFace=croppedBytes;
                  MatchFace match = MatchFace();
                  final res = await match.setEmbedding(embedding);
                  if(res!=null){

                    try{
                      var url = Uri.parse("$apiBaseUrl/log");
                      var response = await http.post(url,headers: {
                        "Content-Type": "application/json",
                      },
                          body: jsonEncode({
                            "userID": res['userID'],
                            "detected_time":timestamp
                          })
                      );
                      if (response.statusCode == 200) {
                        speak("Hey, ${res['userName']}, Action Recorded Successfully");

                        setState(() {
                          ScaffoldMessenger.of(context).showSnackBar(

                            SnackBar(
                              content: Text("Hey ${res['userName']}! Action Recorded Successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        });
                      }
                      else{
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("issue: ${response.body}")),
                        );
                      }
                    }
                    catch(e){
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Network error: $e")),
                      );
                    }


                  }
                  else{
                    speak("Please Try Again");
                    setState(() {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please try Again"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  }
                });


                // Debug print
                print('Embedding generated successfully!');
                print('Embedding length: ${embedding.length}');
                print('Sample values: ${embedding.take(5).toList()}');
              }

              return;
            }

          }
        }
        catch (e) {
          print("Error in face detection: $e");
        }
        finally{
          _isDetecting = false;
        }
        // Always reset the flag

      });

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _initializing = false;
        _error = 'Failed to initialize camera: $e';
      });
    }

  }
  Widget _buildOvalPreview() {
    final screenWidth = MediaQuery.of(context).size.width;
    final ovalWidth = screenWidth * 0.7;
    final ovalHeight = ovalWidth * 1.15;

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipOval(
          child: Container(
            width: ovalWidth,
            height: ovalHeight,
            color: Colors.black12,
            child: _controller == null || !_controller!.value.isInitialized
                ? const Center(
              child: Text(
                'Contact Your Supervisor',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : CameraPreview(_controller!),
          ),
        ),
        // Border ring
        IgnorePointer(
          child: Container(
            width: ovalWidth,
            height: ovalHeight,
            decoration: ShapeDecoration(
              shape: StadiumBorder(
                side: BorderSide(
                  width: 4,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
    faceDetector.close();
  }


  @override
  Widget build(BuildContext context) {
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: _initializing
              ? const CircularProgressIndicator()
              : (_error != null
              ? Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initCamera,
                  child: const Text('Retry'),
                ),

              ],
            ),
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              _buildOvalPreview(),
              const SizedBox(height: 16),
              const Text(
                'Allign your face inside the camera',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),

              ),
             //  if (displayFace != null) ...[
             //  Image.memory(
             //    displayFace!,
             //    width: 150,
             //    height: 150,
             //    fit: BoxFit.cover,
             //  )
             // ]
            ],
          )),
        ),
      ],
    );
  }


}