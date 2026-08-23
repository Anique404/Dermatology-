import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
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
        final parts = remote?['parts'];
        final partUrls = parts is List
            ? parts.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
            : <String>[];
        final modelFile = await _ensureLocalModelFile(
          url: remoteUrl,
          version: targetVersion,
          partUrls: partUrls,
          bytes: remote?['bytes'],
        );
        _interpreter = Interpreter.fromFile(modelFile, options: options);
      } else {
        _interpreter = await Interpreter.fromAsset(
          ModelConfig.modelPath,
          options: options,
        );
      }

      print('✅ Model loaded!');
      await _loadMetadata();
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
          await _loadMetadata();
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

  Future<void> _loadMetadata() async {
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
  }

  Future<File> _ensureLocalModelFile({
    required String url,
    required String version,
    List<String> partUrls = const [],
    dynamic bytes,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final modelFile = File('${directory.path}/$_cacheFileName');
    final prefs = await SharedPreferences.getInstance();
    final cacheToken =
        '$version:${bytes ?? ''}:${partUrls.length}:${partUrls.isEmpty ? url : partUrls.last}';
    final cachedVersion = prefs.getString(_cacheVersionKey);
    if (cachedVersion == cacheToken && await modelFile.exists()) {
      return modelFile;
    }

    print('⬇️ Downloading model $version...');
    final urls = partUrls.isNotEmpty ? partUrls : [url];
    final builder = BytesBuilder(copy: false);
    for (final partUrl in urls) {
      final response = await http.get(Uri.parse(partUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception('Failed to download model (${response.statusCode})');
      }
      builder.add(response.bodyBytes);
    }
    final data = builder.takeBytes();
    if (data.isEmpty) {
      throw Exception('Downloaded model file is empty');
    }
    await modelFile.writeAsBytes(data, flush: true);
    await prefs.setString(_cacheVersionKey, cacheToken);
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

      var scores = List<double>.from(output[0]);
      if (scores.any((value) => value < 0 || value > 1.01)) {
        scores = _softmax(scores);
      }

      final labelCount = _classNames?.length ?? 0;
      final usable = labelCount == 0
          ? scores.length
          : (scores.length < labelCount ? scores.length : labelCount);
      int maxIdx = 0;
      double maxConf = -1;
      for (int i = 0; i < usable; i++) {
        if (scores[i] > maxConf) {
          maxConf = scores[i];
          maxIdx = i;
        }
      }

      final rawName = (labelCount > 0 && maxIdx < labelCount)
          ? _classNames![maxIdx]
          : 'Unknown';
      final disease = _displayDiseaseName(rawName);
      final recommendation = _recommendationFor(disease);

      print(
        '✅ Prediction: $disease (${(maxConf * 100).toStringAsFixed(2)}%) index=$maxIdx/$usable of ${scores.length}',
      );

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

  String _displayDiseaseName(String raw) {
    return raw.replaceAll('_', ' ').trim();
  }

  String _recommendationFor(String disease) {
    final recs = _recommendations;
    if (recs == null) return 'Consult a dermatologist.';
    final spaced = _displayDiseaseName(disease);
    final underscored = spaced.replaceAll(' ', '_');
    final value = recs[spaced] ?? recs[disease] ?? recs[underscored];
    if (value == null || value.toString().trim().isEmpty) {
      return 'Consult a dermatologist.';
    }
    return value.toString();
  }

  List<double> _softmax(List<double> logits) {
    var maxLogit = logits.first;
    for (final value in logits) {
      if (value > maxLogit) maxLogit = value;
    }
    final exps = logits.map((value) => math.exp(value - maxLogit)).toList();
    final sum = exps.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) return List<double>.filled(logits.length, 0);
    return exps.map((value) => value / sum).toList();
  }

  Map<String, dynamic>? getDiseaseInfo(String diseaseName) {
    final text = _recommendationFor(diseaseName);
    if (text == 'Consult a dermatologist.') return null;
    return {'recommendation': text};
  }

  void dispose() {
    _interpreter?.close();
  }
}
