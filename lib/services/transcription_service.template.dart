import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranscriptionService {
  static const String _apiKey = 'CLE GROQ';
  static const String _apiUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';

  Future<String?> transcribe(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        print('ERREUR: fichier audio introuvable: $audioPath');
        return null;
      }

      print('Fichier audio trouvé: ${await file.length()} bytes');

      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['Authorization'] = 'Bearer $_apiKey';
      request.fields['model'] = 'whisper-large-v3';
      request.fields['language'] = 'fr';
      request.fields['response_format'] = 'text';
      request.files.add(await http.MultipartFile.fromPath('file', audioPath));

      //print('Envoi à Groq...');
      final response = await request.send();
      final body = await response.stream.bytesToString();

      //print('Groq status: ${response.statusCode}');
      //print('Groq réponse: $body');

      if (response.statusCode == 200) {
        return body.trim();
      } else {
        return null;
      }
    } catch (e) {
      print('ERREUR transcription: $e');
      return null;
    }
  }
}