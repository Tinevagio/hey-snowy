import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isInitialized = false;
  String? _currentFilePath;

  // Initialise le recorder + demande permission micro
  Future<bool> init() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return false;

    await _recorder.openRecorder();
    _isInitialized = true;
    return true;
  }

  // Démarre l'enregistrement d'un clip
  Future<String?> startRecording() async {
    if (!_isInitialized) {
      final ok = await init();
      if (!ok) return null;
    }

    // Si déjà en train d'enregistrer, on arrête d'abord
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    _currentFilePath = '${dir.path}/obs_$timestamp.wav';

    await _recorder.startRecorder(
      toFile: _currentFilePath,
      codec: Codec.pcm16WAV,
    );

    return _currentFilePath;
  }

  // Arrête l'enregistrement et retourne le chemin du fichier
  Future<String?> stopRecording() async {
    if (!_recorder.isRecording) return null;
    await _recorder.stopRecorder();
    return _currentFilePath;
  }

  bool get isRecording => _recorder.isRecording;

  // Libère les ressources
  Future<void> dispose() async {
    await _recorder.closeRecorder();
    _isInitialized = false;
  }
}