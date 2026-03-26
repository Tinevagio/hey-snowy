import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/observation.dart';

class AiService {
  static const String _apiKey = 'CLE GROQ';
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<Observation> extractSnowData(Observation obs, String transcript) async {
    final prompt = '''

Tu es un expert en ski de randonnée et conditions de neige alpines. Analyse cette observation vocale de skieur et extrais les données en JSON uniquement, sans texte autour.

Catégories de neige disponibles (choisis la plus précise) :
- "poudre" : neige fraîche légère, floconneuse, non tassée
- "moquette" : neige de printemps transformée, agréable, veloutée (souvent après regel/décaillage)
- "béton" : neige regelée dure le matin, croûte portante
- "transfo" : neige qui vient de décailler, surface ramollie après regel
- "croûte" : croûte de regel non portante, désagréable
- "ventée" : neige soufflée, tassée par le vent, plaque potentielle
- "humide" : neige mouillée, lourde, printanière avancée
- "purge" : neige ayant déjà purgé naturellement
- "lourde": poudreuse ayant pris l'humidité, qui a perdu de sa légèreté
- "autre" : si aucune catégorie ne correspond

JSON à retourner :
{
  "snow_type": "catégorie parmi celles ci-dessus",
  "depth_cm": nombre entier ou null,
  "stability_score": entier 1-5 (1=très stable/sûr, 5=très instable/dangereux) ou null,
  "aspect": "N/NE/E/SE/S/SO/O/NO" ou null,
  "raw_notes": "résumé concis et fidèle en français"
}

Observation: "$transcript"''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        }),
      );

      print('Groq LLM status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String;
        print('Groq LLM réponse: $text');
        final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final extracted = jsonDecode(clean);

        obs.transcript = transcript;
        obs.snowType = extracted['snow_type'];
        obs.depthCm = extracted['depth_cm'];
        obs.stabilityScore = extracted['stability_score'];
        obs.aspect = extracted['aspect'];
        obs.rawNotes = extracted['raw_notes'];
      }
    } catch (e) {
      print('ERREUR Groq LLM: $e');
      obs.transcript = transcript;
      obs.rawNotes = 'Extraction échouée: $e';
    }

    return obs;
  }
}