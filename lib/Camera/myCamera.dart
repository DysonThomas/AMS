import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class Mycamera extends StatefulWidget {
  const Mycamera({super.key});

  @override
  State<Mycamera> createState() => _MycameraState();
}

class _MycameraState extends State<Mycamera> {
  CameraController? _controller;
  bool _initializing = true;
  bool _isBusy = false;
  String? _error;
  late FaceDetector _faceDetector;
  img.Image? croppedFace;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );
    _initCamera();
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
        ResolutionPreset.medium, // Changed from max to medium for better performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,  // Better for ML Kit
      );

      await controller.initialize();

      // Start image stream for face detection
      controller.startImageStream((CameraImage image) async {
        if (_isBusy) return;
        _isBusy = true;

        try {
          final XFile file = await _controller!.takePicture();
          final InputImage inputImage = InputImage.fromFilePath(file.path);
          final faces = await _faceDetector.processImage(inputImage);
          final imageBytes = await file.readAsBytes();
          final img.Image? originalImage = img.decodeImage(imageBytes);


          if (originalImage != null && faces.isNotEmpty) {
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
            setState(() {
              croppedFace=cropped;
            });


            // croppedFace = img.copyCrop(
            //   originalImage,
            //   x: boundingBox.left.toInt(),
            //   y: boundingBox.top.toInt(),
            //   width: boundingBox.width.toInt(),
            //   height: boundingBox.height.toInt(),
            //
            // );
          }
        } catch (e) {
          print("Error in face detection: $e");
        } finally {
          // _isBusy = false;
        }
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
                'Camera Preview',
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
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
            // croppedFace != null
            //     ? Image.memory(
            //   Uint8List.fromList(img.encodePng(croppedFace!)),
            //   width: 200,
            //   height: 250,
            //   fit: BoxFit.cover,
            // )
            //     : Container(),
          ],
        )),
      ),
    );
  }

  InputImage _convertToInputImage(CameraImage image, int rotation) {
    // Get image rotation
    final InputImageRotation imageRotation =
    _getImageRotation(rotation);

    // Get image format
    final InputImageFormat inputImageFormat =
    _getImageFormat(image.format);

    // Create InputImage directly from CameraImage
    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  // Helper method to concatenate plane bytes
  Uint8List _concatenatePlanes(List<Plane> planes) {
    final List<int> allBytes = [];
    for (final Plane plane in planes) {
      allBytes.addAll(plane.bytes);
    }
    return Uint8List.fromList(allBytes);
  }

  // Helper method to get image rotation
  InputImageRotation _getImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  // Helper method to get image format
  InputImageFormat _getImageFormat(ImageFormat format) {
    switch (format.group) {
      case ImageFormatGroup.yuv420:
        return InputImageFormat.yuv420;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      default:
        return InputImageFormat.nv21;
    }
  }

}