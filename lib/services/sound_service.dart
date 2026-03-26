import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class SoundService {
  final AudioPlayer _player = AudioPlayer();
  String? _bipStartPath;
  String? _bipStopPath;

  Future<void> init() async {
    _bipStartPath = await _writeBeep(frequency: 880, durationMs: 120);
    _bipStopPath = await _writeBeep(frequency: 660, durationMs: 100);
  }

  Future<String> _writeBeep({
    required double frequency,
    required double durationMs,
    double sampleRate = 44100,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/bip_${frequency.round()}.wav';
    final file = File(path);
    if (await file.exists()) return path;

    final numSamples = (sampleRate * durationMs / 1000).round();
    final buffer = ByteData(44 + numSamples * 2);
    int o = 0;
    for (final b in 'RIFF'.codeUnits) buffer.setUint8(o++, b);
    buffer.setUint32(o, 36 + numSamples * 2, Endian.little); o += 4;
    for (final b in 'WAVEfmt '.codeUnits) buffer.setUint8(o++, b);
    buffer.setUint32(o, 16, Endian.little); o += 4;
    buffer.setUint16(o, 1, Endian.little); o += 2;
    buffer.setUint16(o, 1, Endian.little); o += 2;
    buffer.setUint32(o, sampleRate.round(), Endian.little); o += 4;
    buffer.setUint32(o, sampleRate.round() * 2, Endian.little); o += 4;
    buffer.setUint16(o, 2, Endian.little); o += 2;
    buffer.setUint16(o, 16, Endian.little); o += 2;
    for (final b in 'data'.codeUnits) buffer.setUint8(o++, b);
    buffer.setUint32(o, numSamples * 2, Endian.little); o += 4;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final env = i < numSamples * 0.1
          ? i / (numSamples * 0.1)
          : i > numSamples * 0.8
              ? (numSamples - i) / (numSamples * 0.2)
              : 1.0;
      final s = (sin(2 * pi * frequency * t) * 32767 * 0.7 * env).round();
      buffer.setInt16(o, s.clamp(-32768, 32767), Endian.little);
      o += 2;
    }
    await file.writeAsBytes(buffer.buffer.asUint8List());
    return path;
  }

  Future<void> bipStart() async {
    if (_bipStartPath == null) return;
    print('bipStart appelé, path: $_bipStartPath');
    try {
      await _player.setFilePath(_bipStartPath!);
      await _player.play();
    } catch (e) {
      print('Erreur bip start: $e');
    }
  }

  Future<void> bipStop() async {
    if (_bipStopPath == null) return;
    try {
      await _player.setFilePath(_bipStopPath!);
      await _player.play();
      await Future.delayed(const Duration(milliseconds: 250));
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (e) {
      print('Erreur bip stop: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}