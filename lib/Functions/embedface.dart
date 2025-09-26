import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';


class FaceEmbedding {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  static const int INPUT_SIZE = 112; // Common size for face recognition models
  static const int EMBEDDING_SIZE = 128;
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite');
      print(_interpreter);
      _isModelLoaded = true;
      print('Face recognition model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      _isModelLoaded = false;
    }
  }

  Float32List _preprocessImage(img.Image image) {
    // Resize image to model input size
    img.Image resizedImage = img.copyResize(
      image,
      width: INPUT_SIZE,
      height: INPUT_SIZE,
      interpolation: img.Interpolation.linear,
    );
    Float32List inputBuffer = Float32List(INPUT_SIZE * INPUT_SIZE * 3);
    int bufferIndex = 0;

    for (int y = 0; y < INPUT_SIZE; y++) {
      for (int x = 0; x < INPUT_SIZE; x++) {
        img.Pixel pixel = resizedImage.getPixel(x, y);

        // Normalize pixel values to [-1, 1] or [0, 1] based on your model
        // For most face recognition models, use [-1, 1] normalization
        inputBuffer[bufferIndex++] = (pixel.r / 255.0 - 0.5) * 2.0;
        inputBuffer[bufferIndex++] = (pixel.g / 255.0 - 0.5) * 2.0;
        inputBuffer[bufferIndex++] = (pixel.b / 255.0 - 0.5) * 2.0;
      }
    }

    return inputBuffer;
  }
  Future<List<double>?> generateEmbedding(img.Image croppedFace) async {

    if (!_isModelLoaded || _interpreter == null) {
      print('Model not loaded. Call loadModel() first.');
      return null;
    }

    try {
      // Preprocess the image
      Float32List inputBuffer = _preprocessImage(croppedFace);

      // Reshape input for the model [1, height, width, channels]
      var input = inputBuffer.reshape([1, INPUT_SIZE, INPUT_SIZE, 3]);

      // Prepare output buffer
      var output = List.filled(1 * EMBEDDING_SIZE, 0.0).reshape([1, EMBEDDING_SIZE]);

      // Run inference
      _interpreter!.run(input, output);

      // Extract embedding vector
      List<double> embedding = List<double>.from(output[0]);

      // Optional: Normalize the embedding vector
      embedding = _normalizeEmbedding(embedding);

      print('Generated embedding of size: ${embedding.length}');
      return embedding;

    } catch (e) {
      print('Error generating embedding: $e');
      return null;
    }
  }
  List<double> _normalizeEmbedding(List<double> embedding) {
    double norm = 0.0;
    for (double value in embedding) {
      norm += value * value;
    }
    norm = sqrt(norm);

    if (norm > 0) {
      return embedding.map((value) => value / norm).toList();
    }
    return embedding;
  }
  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same length');
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) {
      return 0.0;
    }

    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }
  void dispose() {
    _interpreter?.close();
    _isModelLoaded = false;
  }
}
extension ListReshape<T> on List<T> {
  /// Reshape a flat list into a multi-dimensional list
  dynamic reshape(List<int> shape) {
    if (shape.isEmpty) {
      throw ArgumentError('Shape cannot be empty');
    }

    int totalElements = shape.reduce((a, b) => a * b);
    if (length != totalElements) {
      throw ArgumentError(
          'Shape $shape requires $totalElements elements, but list has $length elements'
      );
    }

    switch (shape.length) {
      case 1:
        return this;
      case 2:
        return _reshape2D(shape);
      case 3:
        return _reshape3D(shape);
      case 4:
        return _reshape4D(shape);
      default:
        throw ArgumentError('Reshape only supports up to 4 dimensions');
    }
  }

  /// Reshape to 2D: [rows, cols]
  List<List<T>> _reshape2D(List<int> shape) {
    int rows = shape[0];
    int cols = shape[1];

    List<List<T>> result = [];
    for (int i = 0; i < rows; i++) {
      List<T> row = [];
      for (int j = 0; j < cols; j++) {
        row.add(this[i * cols + j]);
      }
      result.add(row);
    }
    return result;
  }

  /// Reshape to 3D: [depth, rows, cols]
  List<List<List<T>>> _reshape3D(List<int> shape) {
    int depth = shape[0];
    int rows = shape[1];
    int cols = shape[2];

    List<List<List<T>>> result = [];
    for (int d = 0; d < depth; d++) {
      List<List<T>> plane = [];
      for (int i = 0; i < rows; i++) {
        List<T> row = [];
        for (int j = 0; j < cols; j++) {
          int index = d * rows * cols + i * cols + j;
          row.add(this[index]);
        }
        plane.add(row);
      }
      result.add(plane);
    }
    return result;
  }

  /// Reshape to 4D: [batch, depth, rows, cols]
  List<List<List<List<T>>>> _reshape4D(List<int> shape) {
    int batch = shape[0];
    int depth = shape[1];
    int rows = shape[2];
    int cols = shape[3];

    List<List<List<List<T>>>> result = [];
    for (int b = 0; b < batch; b++) {
      List<List<List<T>>> batchData = [];
      for (int d = 0; d < depth; d++) {
        List<List<T>> plane = [];
        for (int i = 0; i < rows; i++) {
          List<T> row = [];
          for (int j = 0; j < cols; j++) {
            int index = b * depth * rows * cols + d * rows * cols + i * cols + j;
            row.add(this[index]);
          }
          plane.add(row);
        }
        batchData.add(plane);
      }
      result.add(batchData);
    }
    return result;
  }
}