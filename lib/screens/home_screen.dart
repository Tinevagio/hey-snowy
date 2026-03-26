import 'package:flutter/material.dart';
import '../services/gps_service.dart';
import '../services/audio_service.dart';
import '../models/observation.dart';
import '../services/storage_service.dart';
import '../services/processing_service.dart';
import 'review_screen.dart';
import 'map_screen.dart';
import '../services/wake_word_service.dart';
import '../services/sound_service.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GpsService _gpsService = GpsService();
  final AudioService _audioService = AudioService();
  final StorageService _storageService = StorageService();
  final WakeWordService _wakeWordService = WakeWordService();
  final SoundService _soundService = SoundService();

  Timer? _recordingTimer;

  bool _isSessionActive = false;

  bool _shareWithCommunity = true;
  
  bool _isRecording = false;
  bool _isProcessing = false;
  int _initialCountBeforeSession = 0;

  final List<Observation> _observations = [];
  String _statusText = 'Lance une session pour commencer';

  @override
  void initState() {
    super.initState();
    //_storageService.clearAll(); //ATTENTION A SUPPRIMER ENSUITE
    _storageService.markAllAsUploaded(); // egalement à supprimer 
    _soundService.init();
    _loadExistingObservations();
    _initWakeWord();
  }

  Future<void> _initWakeWord() async {
    final ok = await _wakeWordService.init();
    if (ok) {
      _wakeWordService.onWakeWord = () {
        if (_isSessionActive && !_isRecording) {
          _startObservation();
        }
      };
      _wakeWordService.onStopWord = () {
        if (_isRecording) {
          _stopObservation();
        }
      };
      await _wakeWordService.startListening();
    }
  }

  Future<void> _loadExistingObservations() async {
    final existing = await _storageService.loadSession();
    setState(() {
      _observations.addAll(existing);
    });
  }



  Future<void> _startSession() async {
    setState(() {
      _initialCountBeforeSession = _observations.length; // On mémorise le nbr d'observations stockées
      _isSessionActive = true;
      _statusText = 'Session active — appuie pour démarrer/arrêter';
    });
  }

  Future<void> _startObservation() async {
    if (_isRecording || _isProcessing) return;
    _isProcessing = true;
    await _soundService.bipStart();

    setState(() {
      _isRecording = true;
      _statusText = 'Enregistrement en cours...';
    });

    final position = await _gpsService.snapPosition();
    final audioPath = await _audioService.startRecording();

    if (position == null || audioPath == null) {
      setState(() {
        _isRecording = false;
        _statusText = 'Erreur GPS ou micro — réessaie';
      });
      _isProcessing = false;
      return;
    }

    final obs = Observation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      lat: position['lat']!,
      lon: position['lon']!,
      altitudeM: position['altitude']!,
      timestamp: DateTime.now(),
      audioPath: audioPath,
    );
    _observations.add(obs);
    await _storageService.saveObservation(obs);

    setState(() {
      _statusText = 'Parle... (relâche pour arrêter)';
    });

    // Timeout automatique 15 secondes
    _recordingTimer = Timer(const Duration(seconds: 15), () {
      if (_isRecording) {
        _stopObservation();
      }
    });

    _isProcessing = false;
  }

  Future<void> _stopObservation() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    
    if (!_isRecording) return;
    await _audioService.stopRecording();
    await _soundService.bipStop();
    setState(() {
      _isRecording = false;
      _statusText = '${_observations.length} observation(s) — appuie pour en ajouter';
    });
  }

  void _stopSession() async {
    setState(() {
      _isSessionActive = false;
      _statusText = 'Traitement en cours...';
    });

    try {
      final processor = ProcessingService();
      
      // On ne traite que les observations de cette session (non uploadées)
      final toProcess = _observations
          .skip(_initialCountBeforeSession)
          .where((o) => !o.uploaded)
          .toList();

      await processor.processSession(
        toProcess,
        (current, total) {
          if (mounted) {
            setState(() {
              _statusText = 'Traitement $current / $total...';
            });
          }
        },
        shareWithCommunity: _shareWithCommunity,
      );

      // Recharge les observations enrichies depuis SQLite
      final totalCount = _observations.length;
      
      final sessionCount = totalCount - _initialCountBeforeSession;

      final enriched = await _storageService.loadSession();
      // final newlyProcessed = enriched.where((o) => o.uploaded).length;

      if (mounted) {
        setState(() {
          _observations.clear();
          _observations.addAll(enriched);
          _statusText = 'Terminé — $sessionCount nouvelle(s) observation(s) traitée(s) !';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Erreur traitement: $e';
        });
      }
    }
  }


  @override
  void dispose() {
    _recordingTimer?.cancel();
    _wakeWordService.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F1A),
        title: const Text(
          'Hey Snowy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_observations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.list, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewScreen(observations: _observations),
                ),
              ),
            ),  

          if (_observations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapScreen(observations: _observations),
                ),
              ),
            ),

          if (_isSessionActive)
            TextButton(
              onPressed: _stopSession,
              child: const Text(
                'Terminer',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSessionActive)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatCard(label: 'Observations', value: '${_observations.length}'),
                  StatCard(label: 'Statut', value: _isRecording ? 'REC' : 'Prêt'),
                ],
              ),
            ),
          if (!_isSessionActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Partager avec la communauté',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Switch(
                    value: _shareWithCommunity,
                    onChanged: (v) => setState(() => _shareWithCommunity = v),
                    activeThumbColor: const Color(0xFF1D9E75),
                  ),
                ],
              ),
            ),  
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo_full.png',
                    height: 160,
                  ),
                  const SizedBox(height: 40),

                  GestureDetector(
                    onTap: () {
                      if (!_isSessionActive) return;
                      if (_isRecording) {
                        _stopObservation();
                      } else {
                        _startObservation();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isRecording ? 140 : 120,
                      height: _isRecording ? 140 : 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? const Color(0xFFFF6B6B).withOpacity(0.2)
                            : const Color(0xFF1D9E75).withOpacity(0.15),
                        border: Border.all(
                          color: _isRecording
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF1D9E75),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : Icons.mic_none,
                        size: 56,
                        color: _isRecording
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF1D9E75),
                      ),
                    ),
                  ),


                  const SizedBox(height: 32),
                  Text(
                    _statusText,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !_isSessionActive
          ? FloatingActionButton.extended(
              onPressed: _startSession,
              backgroundColor: const Color(0xFF1D9E75),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer sortie'),
            )
          : null,
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1D9E75),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}