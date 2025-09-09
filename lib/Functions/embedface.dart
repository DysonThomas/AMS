import 'dart:typed_data';
import 'package:image/image.dart' as img;

class Embedface{

  Float32List imageToByteListFloat32(img.Image image, int inputSize) {
    final Float32List convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    int bufferIndex = 0;

    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);

        // normalize to -1..1
        convertedBytes[bufferIndex++] = ((pixel.r / 255.0) - 0.5) * 2;
        convertedBytes[bufferIndex++] = ((pixel.g / 255.0) - 0.5) * 2;
        convertedBytes[bufferIndex++] = ((pixel.b / 255.0) - 0.5) * 2;
      }
    }

    return convertedBytes;
  }
}



