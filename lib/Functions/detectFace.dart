import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class DetectFace {
  Future<img.Image?> detectFace(XFile image, FaceDetector faceDetector) async {
    try {
      final InputImage inputImage = InputImage.fromFilePath(image.path);
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
        const inputSize = 160;
        final resizedFace = img.copyResize(cropped, width: inputSize, height: inputSize);
        return resizedFace;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }
}
