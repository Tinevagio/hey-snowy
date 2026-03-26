import 'dart:convert';

class Observation {
  final String id;
  final double lat;
  final double lon;
  final double altitudeM;
  final DateTime timestamp;
  final String audioPath;
  String? transcript;
  String? snowType;
  int? depthCm;
  int? stabilityScore;
  String? aspect;
  String? rawNotes;
  bool uploaded = false;

  Observation({
    required this.id,
    required this.lat,
    required this.lon,
    required this.altitudeM,
    required this.timestamp,
    required this.audioPath,
  });

  // Convertir en Map pour stocker en base SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lat': lat,
      'lon': lon,
      'altitude_m': altitudeM,
      'timestamp': timestamp.toIso8601String(),
      'audio_path': audioPath,
      'transcript': transcript,
      'snow_type': snowType,
      'depth_cm': depthCm,
      'stability_score': stabilityScore,
      'aspect': aspect,
      'raw_notes': rawNotes,
      'uploaded': uploaded ? 1 : 0,
    };
  }

  // Reconstruire depuis la base SQLite
  factory Observation.fromMap(Map<String, dynamic> map) {
    return Observation(
      id: map['id'],
      lat: map['lat'],
      lon: map['lon'],
      altitudeM: map['altitude_m'],
      timestamp: DateTime.parse(map['timestamp']),
      audioPath: map['audio_path'],
    )
      ..transcript = map['transcript']
      ..snowType = map['snow_type']
      ..depthCm = map['depth_cm']
      ..stabilityScore = map['stability_score']
      ..aspect = map['aspect']
      ..rawNotes = map['raw_notes']
      ..uploaded = (map['uploaded'] ?? 0) == 1;
  }

  // Export GeoJSON pour la carte
  Map<String, dynamic> toGeoJson() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [lon, lat, altitudeM],
      },
      'properties': {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'snow_type': snowType,
        'depth_cm': depthCm,
        'stability_score': stabilityScore,
        'aspect': aspect,
        'transcript': transcript,
      },
    };
  }

  @override
  String toString() {
    return 'Observation($id, $lat/$lon, ${altitudeM}m, $snowType)';
  }
}