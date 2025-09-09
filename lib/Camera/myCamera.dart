
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class Mycamera extends StatefulWidget {
  const Mycamera({super.key});

  @override
  State<Mycamera> createState() => MycameraState();
}

class MycameraState extends State<Mycamera> {
  CameraController? _controller;
  bool _initializing = true;
  String? _error;
  img.Image? croppedFace;

  @override
  void initState() {
    super.initState();
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
  Future<XFile?> capture() async {
    if (_controller != null && _controller!.value.isInitialized) {
      final image = await _controller!.takePicture();
      return image;
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
    super.dispose();
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
              ],
            )),
          ),
        ],
      );
  }
}