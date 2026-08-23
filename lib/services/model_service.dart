import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/constants.dart';
import 'firestore_service.dart';

class ModelService {
  static const _cacheVersionKey = 'active_model_version';
  static const _cacheFileName = 'current_model.tflite';

  Interpreter? _interpreter;
  List<String>? _classNames;
  Map<String, dynamic>? _recommendations;
  bool _isInitialized = false;
  String? _loadedVersion;

  bool get isInitialized => _isInitialized;
  String? get loadedVersion => _loadedVersion;

  Future<void> initializeModel({bool forceReload = false}) async {
    Map<String, dynamic>? remote;
    try {
      remote = await FirestoreService().getCurrentModel();
    } catch (e) {
      print('⚠️ Could not fetch remote model info: $e');
    }

    final remoteUrl = remote?['url']?.toString() ?? '';
    final remoteVersion = remote?['version']?.toString() ?? '';
    final hasRemote = remoteUrl.isNotEmpty;
    final targetVersion = hasRemote
        ? (remoteVersion.isNotEmpty ? remoteVersion : remoteUrl)
        : 'bundled';

    if (!forceReload && _isInitialized && _loadedVersion == targetVersion) {
      return;
    }

    try {
      print('📦 Loading model ($targetVersion)...');
      _interpreter?.close();
      _interpreter = null;
      _isInitialized = false;

      final options = InterpreterOptions()..threads = 2;

      if (hasRemote) {
        final modelFile = await _ensureLocalModelFile(
          url: remoteUrl,
          version: targetVersion,
        );
        _interpreter = Interpreter.fromFile(modelFile, options: options);
      } else {
        _interpreter = await Interpreter.fromAsset(
          ModelConfig.modelPath,
          options: options,
        );
      }

      print('✅ Model loaded!');

      if (_classNames == null) {
        final classNamesJson = await rootBundle.loadString(
          ModelConfig.classNamesPath,
        );
        _classNames = List<String>.from(jsonDecode(classNamesJson));
        print('✅ Class names loaded: ${_classNames?.length}');
      }

      if (_recommendations == null) {
        final recommendationsJson = await rootBundle.loadString(
          ModelConfig.recommendationsPath,
        );
        _recommendations = jsonDecode(recommendationsJson);
        print('✅ Recommendations loaded');
      }

      _loadedVersion = targetVersion;
      _isInitialized = true;
    } catch (e) {
      print('❌ Init error: $e');
      if (hasRemote) {
        print('⚠️ Falling back to bundled model');
        try {
          final options = InterpreterOptions()..threads = 2;
          _interpreter = await Interpreter.fromAsset(
            ModelConfig.modelPath,
            options: options,
          );
          _loadedVersion = 'bundled';
          _isInitialized = true;
          return;
        } catch (fallbackError) {
          print('❌ Bundled model fallback failed: $fallbackError');
        }
      }
      _isInitialized = false;
      rethrow;
    }
  }

  Future<File> _ensureLocalModelFile({
    required String url,
    required String version,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final modelFile = File('${directory.path}/$_cacheFileName');
    final prefs = await SharedPreferences.getInstance();
    final cachedVersion = prefs.getString(_cacheVersionKey);
    if (cachedVersion == version && await modelFile.exists()) {
      return modelFile;
    }

    print('⬇️ Downloading model $version...');
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception('Failed to download model (${response.statusCode})');
    }
    await modelFile.writeAsBytes(response.bodyBytes, flush: true);
    await prefs.setString(_cacheVersionKey, version);
    return modelFile;
  }

  Future<Map<String, dynamic>> predictDisease(Uint8List imageBytes) async {
    await initializeModel();

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
