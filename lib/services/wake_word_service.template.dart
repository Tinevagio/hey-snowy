import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'dart:io';

class WakeWordService {
  static const String _accessKey = 'CLE PORCUPINE';

  PorcupineManager? _manager;
  Function()? onWakeWord;
  Function()? onStopWord;

  Future<String> _extractAsset(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${assetPath.split('/').last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  }

  Future<bool> init() async {
    try {
      print('Init Porcupine...');
      final path1 = await _extractAsset('assets/hey_snowy_android.ppn');
      final path2 = await _extractAsset('assets/bye_bye_snow_android.ppn');
      final modelPath = await _extractAsset('assets/porcupine_params.pv');
      print('Assets extraits: $path1, $path2');

      _manager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        [path1, path2],
        _onWakeWordDetected,
        modelPath: modelPath,
        errorCallback: _onError,
      );
      print('Porcupine initialisé OK');
      return true;
    } catch (e) {
      print('Erreur init wake word type: ${e.runtimeType}');
      print('Erreur init wake word message: $e');
      if (e is PorcupineInvalidArgumentException) {
        print('Message détaillé: ${e.message}');
      }
      return false;
    }
  }

  void _onWakeWordDetected(int keywordIndex) {
    print('Wake word détecté ! index: $keywordIndex');
    if (keywordIndex == 0) {
      onWakeWord?.call();
    } else if (keywordIndex == 1) {
      onStopWord?.call();
    }
  }

  void _onError(PorcupineException e) {
    print('Erreur Porcupine détail: ${e.message}');
  }

  Future<void> startListening() async {
    print('Démarrage écoute wake word...');
    await _manager?.start();
    print('Écoute active');
  }

  Future<void> stopListening() async {
    await _manager?.stop();
  }

  Future<void> dispose() async {
    await _manager?.delete();
    _manager = null;
  }
}