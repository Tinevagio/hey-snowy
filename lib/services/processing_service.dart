import '../models/observation.dart';
import 'transcription_service.dart';
import 'ai_service.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class ProcessingService {
  final TranscriptionService _transcription = TranscriptionService();
  final AiService _ai = AiService();
  final StorageService _storage = StorageService();
  final SupabaseService _supabase = SupabaseService();

  Future<List<Observation>> processSession(
    List<Observation> observations,
    Function(int current, int total) onProgress, {
    bool shareWithCommunity = true,
  }) async {
    final results = <Observation>[];

    for (int i = 0; i < observations.length; i++) {
      final obs = observations[i];
      onProgress(i + 1, observations.length);

      //print('--- Traitement obs ${i+1}/${observations.length}');
      //print('Audio path: ${obs.audioPath}');

      final transcript = await _transcription.transcribe(obs.audioPath);
      //print('Transcript: $transcript');

      if (transcript == null || transcript.isEmpty) {
        obs.rawNotes = 'Transcription échouée';
        results.add(obs);
        await _storage.updateObservation(obs);
        continue;
      }

      final enriched = await _ai.extractSnowData(obs, transcript);
      //print('Snow type: ${enriched.snowType}');
      //print('Notes: ${enriched.rawNotes}');

      await _storage.updateObservation(enriched);

      // Upload communautaire si autorisé et obs enrichie
      if (shareWithCommunity && enriched.snowType != null) {
        final uploaded = await _supabase.uploadObservation(enriched);
        if (uploaded) {
          enriched.uploaded = true;
          await _storage.updateObservation(enriched);
        }
      }

      results.add(enriched);
    }

    return results;
  }
}