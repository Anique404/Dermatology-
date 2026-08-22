import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/constants.dart';

class ModelService {
  Interpreter? _interpreter;
  List<String>? _classNames;
  Map<String, dynamic>? _recommendations;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initializeModel() async {
    if (_isInitialized) return;

    try {
      print('📦 Loading model...');

      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        ModelConfig.modelPath,
        options: options,
      );

      print('✅ Model loaded!');

      final classNamesJson = await rootBundle.loadString(
        ModelConfig.classNamesPath,
      );
      _classNames = List<String>.from(jsonDecode(classNamesJson));
      print('✅ Class names loaded: ${_classNames?.length}');

      final recommendationsJson = await rootBundle.loadString(
        ModelConfig.recommendationsPath,
      );
      _recommendations = jsonDecode(recommendationsJson);
      print('✅ Recommendations loaded');

      _isInitialized = true;
    } catch (e) {
      print('❌ Init error: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  // CHANGE: Return type is now Map<String, dynamic>
  Future<Map<String, dynamic>> predictDisease(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      await initializeModel();
    }

    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Invalid image');

      final inputShape = _interpreter!.getInputTensor(0).shape;
      if (inputShape.length != 4 || inputShape[0] != 1) {
        throw Exception('Unsupported model input shape: $inputShape');
      }
      final height = inputShape[1];
      final width = inputShape[2];
      final channels = inputShape[3];
      if (channels != 3) {
        throw Exception('Unsupported model channel count: $channels');
      }

      final resized = img.copyResize(image, width: width, height: height);
      final input = _imageToTensor(resized, width, height);

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      if (outputShape.length != 2 || outputShape[0] != 1) {
        throw Exception('Unsupported model output shape: $outputShape');
      }
      final output = [List<double>.filled(outputShape[1], 0.0)];

      print('🔄 Running inference...');
      _interpreter!.run(input, output);
      print('✅ Inference complete!');

      final predictions = output[0];
      int maxIdx = 0;
      double maxConf = 0.0;
      for (int i = 0; i < predictions.length; i++) {
        if (predictions[i] > maxConf) {
          maxConf = predictions[i];
          maxIdx = i;
        }
      }

      final disease = _classNames?[maxIdx] ?? 'Unknown';
      final recommendation =
          _recommendations?[disease] ?? 'Consult a dermatologist.';

      print('✅ Prediction: $disease (${(maxConf * 100).toStringAsFixed(2)}%)');

      // Return Map instead of PredictionModel
      return {
        'diseaseName': disease,
        'confidence': maxConf,
        'recommendation': recommendation.toString(),
      };
    } catch (e) {
      print('❌ Prediction error: $e');
      throw Exception('Failed to predict disease: $e');
    }
  }

  List<List<List<List<double>>>> _imageToTensor(
    img.Image image,
    int width,
    int height,
  ) {
    return [
      List.generate(
        height,
        (y) => List.generate(width, (x) {
          final pixel = image.getPixelSafe(x, y);
          return [
            (pixel.r / 127.5) - 1.0,
            (pixel.g / 127.5) - 1.0,
            (pixel.b / 127.5) - 1.0,
          ];
        }),
      ),
    ];
  }

  Map<String, dynamic>? getDiseaseInfo(String diseaseName) {
    if (_recommendations != null &&
        _recommendations!.containsKey(diseaseName)) {
      return {'recommendation': _recommendations![diseaseName]};
    }
    return null;
  }

  void dispose() {
    _interpreter?.close();
  }
}
