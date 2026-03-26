import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/observation.dart';

class StorageService {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('observations');
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hey_snow.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE observations (
            id TEXT PRIMARY KEY,
            lat REAL,
            lon REAL,
            altitude_m REAL,
            timestamp TEXT,
            audio_path TEXT,
            transcript TEXT,
            snow_type TEXT,
            depth_cm INTEGER,
            stability_score INTEGER,
            aspect TEXT,
            raw_notes TEXT,
            uploaded INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE observations ADD COLUMN uploaded INTEGER DEFAULT 0'
          );
        }
      },
    );
  }

  // Sauvegarde une observation
  Future<void> saveObservation(Observation obs) async {
    final db = await database;
    await db.insert(
      'observations',
      obs.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //forcer l'upload
  Future<void> markAllAsUploaded() async {
    final db = await database;
    await db.update('observations', {'uploaded': 1});
  }

  // Charge toutes les observations
  Future<List<Observation>> loadAll() async {
    final db = await database;
    final maps = await db.query('observations', orderBy: 'timestamp DESC');
    return maps.map((m) => Observation.fromMap(m)).toList();
  }

  // Charge les observations d'une session (dernières 24h)
  Future<List<Observation>> loadSession() async {
    final db = await database;
    final since = DateTime.now()
        .subtract(const Duration(hours: 24))
        .toIso8601String();
    final maps = await db.query(
      'observations',
      where: 'timestamp > ?',
      whereArgs: [since],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => Observation.fromMap(m)).toList();
  }

  // Met à jour une observation après transcription/IA
  Future<void> updateObservation(Observation obs) async {
    final db = await database;
    await db.update(
      'observations',
      obs.toMap(),
      where: 'id = ?',
      whereArgs: [obs.id],
    );
  }

  // on ne charge que les non uploadés
  Future<List<Observation>> loadPending() async {
    final db = await database;
    final maps = await db.query(
      'observations',
      where: 'uploaded = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => Observation.fromMap(m)).toList();
  }

  //SUPPRESSION
  Future<void> deleteObservation(String id) async {
    final db = await database;
    await db.delete('observations', where: 'id = ?', whereArgs: [id]);
  }

  // Exporte toutes les obs en GeoJSON
  Future<Map<String, dynamic>> exportGeoJson() async {
    final obs = await loadAll();
    return {
      'type': 'FeatureCollection',
      'features': obs.map((o) => o.toGeoJson()).toList(),
    };
  }
}