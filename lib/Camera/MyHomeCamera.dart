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
  bool _isDisposed = false;
  bool _isStreamActive = false;

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
    _initTTS();
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-AU");
    await flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (!_isDisposed) {
      await flutterTts.speak(text);
    }
  }

  Future<void> _initCamera() async {
    try {
      // 1) Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _initializing = false;
            _error = 'Camera permission denied';
          });
        }
        return;
      }

      // 2) Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _initializing = false;
            _error = 'No camera found on this device';
          });
        }
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
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      if (!mounted || _isDisposed) {
        controller.dispose();
        return;
      }

      // Start image stream
      await controller.startImageStream(_processImageStream);
      _isStreamActive = true;

      if (mounted) {
        setState(() {
          _controller = controller;
          _initializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  void _processImageStream(CameraImage image) async {
    if (_isDetecting || _isDisposed || !_isStreamActive) return;

    _isDetecting = true;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Process every 10 seconds
      if (_lastProcessed == null || (now - _lastProcessed!) > 10000) {
        _lastProcessed = now;

        if (_controller == null || !_controller!.value.isInitialized) {
          return;
        }

        final timestamp = DateTime.now().toIso8601String();

        // Stop image stream before taking picture
        if (_isStreamActive) {
          await _controller!.stopImageStream();
          _isStreamActive = false;
        }

        // Small delay to ensure stream is fully stopped
        await Future.delayed(const Duration(milliseconds: 100));

        // Take picture
        final XFile picture = await _controller!.takePicture();

        // Detect face
        final detector = DetectFace();
        final faceImage = await detector.detectFace(picture, faceDetector);

        if (faceImage != null && mounted && !_isDisposed) {
          final croppedBytes = Uint8List.fromList(img.encodeJpg(faceImage));

          print('Generating face embedding...');
          await _faceEmbeddingService.loadModel();
          final embedding = await _faceEmbeddingService.generateEmbedding(faceImage);

          if (embedding != null && mounted && !_isDisposed) {
            setState(() {
              croppedFace = faceImage;
              isProcessing = false;
              displayFace = croppedBytes;
            });

            // Match face and handle login/logout
            await _handleFaceMatch(embedding, timestamp);
          }
        }

        // Restart image stream
        if (_controller != null &&
            _controller!.value.isInitialized &&
            !_isDisposed &&
            mounted &&
            !_isStreamActive) {
          try {
            await _controller!.startImageStream(_processImageStream);
            _isStreamActive = true;
          } catch (e) {
            print("Error restarting image stream: $e");
          }
        }
      }
    } catch (e) {
      print("Error in face detection: $e");

      // Try to restart image stream on error
      if (_controller != null &&
          _controller!.value.isInitialized &&
          !_isDisposed &&
          mounted &&
          !_isStreamActive) {
        try {
          await _controller!.startImageStream(_processImageStream);
          _isStreamActive = true;
        } catch (restartError) {
          print("Error restarting image stream after error: $restartError");
        }
      }
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _handleFaceMatch(List<double> embedding, String timestamp) async {
    try {
      MatchFace match = MatchFace();
      final res = await match.setEmbedding(embedding);

      if (res == null) {
        await speak("Please try again");
        if (mounted) {
          _showSnackBar("Please try again", Colors.red);
        }
        return;
      }

      print("Match result: ${res["isLoggedIn"]}");

      final isLoggedIn = res["isLoggedIn"];
      // Handle userID as either int or String
      final userID = res['userID'].toString();
      final userName = res['userName']?.toString() ?? 'User';

      if (isLoggedIn == null || isLoggedIn == 0 || isLoggedIn == false) {
        // User is logging in
        await _performLogin(userID, userName, timestamp);
      } else if (isLoggedIn == true || isLoggedIn == 1) {
        // User is logging out
        await _performLogout(userID, userName, timestamp);
      }
    } catch (e) {
      print("Error in face matching: $e");
      if (mounted) {
        _showSnackBar("Error processing: $e", Colors.red);
      }
    }
  }

  Future<void> _performLogin(String userID, String userName, String timestamp) async {
    try {
      print("Attempting login for userID: $userID");
      var url = Uri.parse("$apiBaseUrl/login");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userID": userID,
          "log_in_time": timestamp,
        }),
      );

      print("Login response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        // Update login status
        await _updateLoginStatus(userID, true);

        if (mounted) {
          await speak("Hey $userName! Login recorded successfully");
          _showSnackBar("Hey $userName! Login recorded successfully", Colors.green);
        }
      } else {
        if (mounted) {
          await speak("Login Failed");
          _showSnackBar("Login failed: ${response.body}", Colors.red);
        }
      }
    } catch (e) {
      print("Login error: $e");
      if (mounted) {
        _showSnackBar("Network error: $e", Colors.red);
      }
    }
  }

  Future<void> _performLogout(String userID, String userName, String timestamp) async {
    try {
      print("Attempting logout for userID: $userID");
      var url = Uri.parse("$apiBaseUrl/logout");
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userID": userID,
          "log_in_time": timestamp,
        }),
      );

      print("Logout response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        // Update login status
        await _updateLoginStatus(userID, false);

        if (mounted) {
          await speak("Hey $userName! Logout recorded successfully");
          _showSnackBar("Hey $userName! Logout recorded successfully", Colors.green);
        }
      } else {
        if (mounted) {
          await speak("Logout Failed");
          _showSnackBar("Logout failed: ${response.body}", Colors.red);
        }
      }
    } catch (e) {
      print("Logout error: $e");
      if (mounted) {
        _showSnackBar("Network error: $e", Colors.red);
      }
    }
  }

  Future<void> _updateLoginStatus(String userID, bool isLoggedIn) async {
    try {
      print("Updating login status - userID: $userID, isLoggedIn: $isLoggedIn");
      var url = Uri.parse("$apiBaseUrl/updateLog");
      var response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userID": userID,
          "isLoggedIn": isLoggedIn,
        }),
      );
      print("Update login status response: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        print("Failed to update login status: ${response.body}");
      }
    } catch (e) {
      print("Error updating login status: $e");
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
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
    _isDisposed = true;
    _isStreamActive = false;
    _controller?.stopImageStream().then((_) {
      _controller?.dispose();
    }).catchError((e) {
      print("Error disposing camera: $e");
      _controller?.dispose();
    });
    faceDetector.close();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                'Align your face inside the camera',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              // Optional: Display the detected face
              // if (displayFace != null) ...[
              //   const SizedBox(height: 16),
              //   Image.memory(
              //     displayFace!,
              //     width: 150,
              //     height: 150,
              //     fit: BoxFit.cover,
              //   )
              // ]
            ],
          )),
        ),
      ],
    );
  }
}