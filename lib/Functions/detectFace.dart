import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'dart:io';


class DetectFace{
  bool validateInputImage(InputImage? inputImage, CameraImage originalCameraImage) {
    if (inputImage == null) {
      print('❌ InputImage conversion failed - null result');
      return false;
    }

    final metadata = inputImage.metadata;
    if (metadata == null) {
      print('❌ InputImage metadata is null');
      return false;
    }

    print('✅ InputImage created successfully:');
    print('  📐 Size: ${metadata.size.width} x ${metadata.size.height}');
    print('  🔄 Rotation: ${metadata.rotation}');
    print('  📱 Format: ${metadata.format}');
    print('  📊 Bytes per row: ${metadata.bytesPerRow}');

    // Compare with original CameraImage dimensions
    print('  📷 Original CameraImage: ${originalCameraImage.width} x ${originalCameraImage.height}');
    print('  📷 Original Format: ${originalCameraImage.format.group}');

    // Validate dimensions match (accounting for rotation)
    bool dimensionsMatch = (metadata.size.width == originalCameraImage.width.toDouble() &&
        metadata.size.height == originalCameraImage.height.toDouble()) ||
        (metadata.size.width == originalCameraImage.height.toDouble() &&
            metadata.size.height == originalCameraImage.width.toDouble());

    if (!dimensionsMatch) {
      print('⚠️  Dimension mismatch detected');
    }

    return true;
  }

  Future<img.Image?> detectFace(XFile image,FaceDetector faceDetector) async{
    try{
      final InputImage inputImage = InputImage.fromFilePath(image!.path);
      final faces = await faceDetector.processImage(inputImage);
      final imageBytes = await image.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage != null && faces.isNotEmpty && faces.length <= 1) {
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
        final inputSize = 160;
        final resizedFace = img.copyResize(cropped, width: inputSize, height: inputSize);
        return resizedFace;
      }
      else{
        return null;

      }
    }
    catch(e){
      print(e);
      return null;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Please try again or Contact your manager")),
      // );
    }

  }

  Future<img.Image?> detectLiveFace(CameraImage cameraImage, FaceDetector faceDetector, CameraController controller) async {
    try {
      // Convert CameraImage to InputImage for ML Kit
      final InputImage? inputImage = _convertCameraImageToInputImage(cameraImage, controller);
      if (inputImage != null) {
        validateInputImage(inputImage, cameraImage); // Logs detailed info
      }
      // Detect faces using ML Kit
      final faces = await faceDetector.processImage(inputImage!);
      print("Number of faces: ${faces.length}");
      // Convert CameraImage to img.Image for cropping
      final img.Image? originalImage = _convertCameraImageToImage(cameraImage);
      if (originalImage != null && faces.isNotEmpty && faces.length <= 1) {
        final face = faces.first;
        final boundingBox = face.boundingBox;
        // Clamp coordinates to image bounds
        final x = boundingBox.left.toInt().clamp(0, originalImage.width - 1);
        final y = boundingBox.top.toInt().clamp(0, originalImage.height - 1);
        final w = boundingBox.width.toInt().clamp(1, originalImage.width - x);
        final h = boundingBox.height.toInt().clamp(1, originalImage.height - y);

        // Crop the face from the original image
        final cropped = img.copyCrop(
          originalImage,
          x: x,
          y: y,
          width: w,
          height: h,
        );

        // Resize to standard input size (160x160)
        const inputSize = 160;
        final resizedFace = img.copyResize(cropped, width: inputSize, height: inputSize);

        return resizedFace;
      } else {
        return null;
      }
    } catch (e) {
      print('Error in detectLiveFace: $e');
      return null;
    }
  }

  // FIXED: Proper YUV420 to NV21 conversion for ML Kit
  InputImage? _createInputImageFromYUV420(CameraImage image, InputImageRotation rotation) {
    try {
      print("Converting YUV420 to NV21 for ML Kit...");

      final int width = image.width;
      final int height = image.height;

      // Get Y, U, V planes
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final yBytes = yPlane.bytes;
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;

      // NV21 format: Y plane followed by interleaved V and U
      final int ySize = yBytes.length;
      final int uvLength = width * height ~/ 4;

      final nv21Bytes = Uint8List(ySize + uvLength * 2);

      // Copy Y plane
      nv21Bytes.setRange(0, ySize, yBytes);

      // Interleave V and U for NV21 format (V first, then U)
      int nv21Index = ySize;
      int uvPixelStride = uPlane.bytesPerPixel ?? 1;
      int uvRowStride = uPlane.bytesPerRow;

      for (int row = 0; row < height ~/ 2; row++) {
        for (int col = 0; col < width ~/ 2; col++) {
          int uvIndex = row * uvRowStride + col * uvPixelStride;

          // NV21 format: VUVUVU...
          if (uvIndex < vBytes.length && uvIndex < uBytes.length) {
            nv21Bytes[nv21Index++] = vBytes[uvIndex]; // V first
            nv21Bytes[nv21Index++] = uBytes[uvIndex]; // U second
          }
        }
      }

      return InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: width, // For NV21, this should be the width
        ),
      );

    } catch (e) {
      print("YUV420 to NV21 conversion error: $e");
      return null;
    }
  }

//   For Cameras Image(home page)
  InputImage? _convertCameraImageToInputImage(
      CameraImage image, CameraController controller) {
    try {
      final camera = controller.description;
      final rotation = _rotationIntToImageRotation(camera.sensorOrientation);
      print("Camera format: ${image.format.group}");
      if (image.format.group == ImageFormatGroup.yuv420) {
        print("akathu");
        return _createInputImageFromYUV420(image, rotation);
      }
      else if (image.format.group == ImageFormatGroup.bgra8888) {
        // For BGRA8888, direct conversion usually works
        final bytes = image.planes[0].bytes;
        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }
      else {
        print("Unsupported format, trying generic conversion...");
        // For any other format, convert via RGB
        final img.Image? rgbImage = _convertCameraImageToImage(image);
        if (rgbImage != null) {
          final pngBytes = img.encodePng(rgbImage);
          return InputImage.fromBytes(
            bytes: pngBytes,
            metadata: InputImageMetadata(
              size: Size(image.width.toDouble(), image.height.toDouble()),
              rotation: rotation,
              format: InputImageFormat.nv21,
              bytesPerRow: image.width * 4,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      print("Conversion error: $e");
      return null;
    }
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        throw Exception("Invalid rotation value: $rotation");
    }
  }




  img.Image? _convertCameraImageToImage(CameraImage cameraImage) {
    try {
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToImage(cameraImage);
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888ToImage(cameraImage);
      } else {
        print('Unsupported image format: ${cameraImage.format.group}');
        return null;
      }
    } catch (e) {
      print('Error converting CameraImage to img.Image: $e');
      return null;
    }
  }
  img.Image _convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final img.Image image = img.Image(width: width, height: height);

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final yp = cameraImage.planes[0].bytes[index];
        final up = cameraImage.planes[1].bytes[uvIndex];
        final vp = cameraImage.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  img.Image _convertBGRA8888ToImage(CameraImage cameraImage) {
    final bytes = cameraImage.planes[0].bytes;
    return img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: bytes.buffer,
      format: img.Format.uint8,
      numChannels: 4,
    );
  }
  InputImageRotation _getRotationFromSensorOrientation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
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
}