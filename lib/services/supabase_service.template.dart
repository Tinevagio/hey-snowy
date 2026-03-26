import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/observation.dart';

class SupabaseService {
  static const String _url = 'https://ergfihxckvzilpkupdef.supabase.co';
  static const String _anonKey = 'CLE SUPABASE';

  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Upload une observation vers la base communautaire
  Future<bool> uploadObservation(Observation obs) async {
    try {
      await client.from('observations').upsert({
        'id': obs.id,
        'lat': obs.lat,
        'lon': obs.lon,
        'altitude_m': obs.altitudeM,
        'timestamp': obs.timestamp.toIso8601String(),
        'snow_type': obs.snowType,
        'depth_cm': obs.depthCm,
        'stability_score': obs.stabilityScore,
        'aspect': obs.aspect,
        'raw_notes': obs.rawNotes,
      });
      return true;
    } catch (e) {
      print('Erreur upload: $e');
      return false;
    }
  }

  //SUPPRESSION
  Future<void> deleteObservation(String id) async {
    try {
      await client.from('observations').delete().eq('id', id);
    } catch (e) {
      print('Erreur suppression Supabase: $e');
    }
  }

  // Récupère les observations communautaires récentes
  Future<List<Observation>> fetchCommunityObs({int hoursBack = 48}) async {
    try {
      final since = DateTime.now()
          .subtract(Duration(hours: hoursBack))
          .toIso8601String();

      final data = await client
          .from('observations')
          .select()
          .gte('timestamp', since)
          .order('timestamp', ascending: false);

      return (data as List).map((row) {
        final obs = Observation(
          id: row['id'],
          lat: row['lat'],
          lon: row['lon'],
          altitudeM: row['altitude_m'] ?? 0.0,
          timestamp: DateTime.parse(row['timestamp']),
          audioPath: '',
        );
        obs.snowType = row['snow_type'];
        obs.depthCm = row['depth_cm'];
        obs.stabilityScore = row['stability_score'];
        obs.aspect = row['aspect'];
        obs.rawNotes = row['raw_notes'];
        return obs;
      }).toList();
    } catch (e) {
      print('Erreur fetch community: $e');
      return [];
    }
  }
}