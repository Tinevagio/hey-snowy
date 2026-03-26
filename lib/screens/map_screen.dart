import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/observation.dart';
import '../services/supabase_service.dart';

class MapScreen extends StatefulWidget {
  final List<Observation> observations;
  const MapScreen({super.key, required this.observations});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Observation> _communityObs = [];
  bool _loadingCommunity = true;
  bool _showCommunity = true;
  int _hoursFilter = 48;

  @override
  void initState() {
    super.initState();
    _loadCommunityObs();
  }

  Future<void> _loadCommunityObs() async {
    setState(() => _loadingCommunity = true);
    final supabase = SupabaseService();
    final obs = await supabase.fetchCommunityObs(hoursBack: _hoursFilter);
    setState(() {
      _communityObs = obs;
      _loadingCommunity = false;
    });
  }

  Color _markerColor(String? snowType) {
    switch (snowType) {
      case 'poudre': return const Color(0xFF1D9E75);
      case 'moquette':
      case 'transfo': return const Color(0xFF4CAF50);
      case 'béton':
      case 'croûte': return const Color(0xFFF5A623);
      case 'ventée':
      case 'lourde': return const Color(0xFFFF6B6B);
      case 'humide': return const Color(0xFF378ADD);
      case 'purge': return Colors.grey;
      default: return Colors.white54;
    }
  }

  LatLng _computeCenter(List<Observation> obs) {
    if (obs.isEmpty) return LatLng(45.0, 6.5);
    return LatLng(
      obs.map((o) => o.lat).reduce((a, b) => a + b) / obs.length,
      obs.map((o) => o.lon).reduce((a, b) => a + b) / obs.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final myObs = widget.observations.where((o) => o.lat != 0).toList();
    final allObs = [...myObs, if (_showCommunity) ..._communityObs];
    final center = _computeCenter(allObs.isNotEmpty ? allObs : myObs);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F1A),
        title: const Text(
          'Carte',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Filtre temporel
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            color: const Color(0xFF1A3A2A),
            onSelected: (hours) {
              setState(() => _hoursFilter = hours);
              _loadCommunityObs();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 24, child: Text('24h', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 48, child: Text('48h', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 168, child: Text('7 jours', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: myObs.length == 1 ? 14 : 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.hey_snow',
              ),
              MarkerLayer(
                markers: [
                  // Mes observations (bord blanc épais)
                  ...myObs.map((obs) => Marker(
                    point: LatLng(obs.lat, obs.lon),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _showObsDetail(context, obs, isMine: true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _markerColor(obs.snowType),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.ac_unit, color: Colors.white, size: 20),
                      ),
                    ),
                  )),
                  // Observations communautaires (bord fin)
                  if (_showCommunity)
                    ..._communityObs.map((obs) => Marker(
                      point: LatLng(obs.lat, obs.lon),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _showObsDetail(context, obs, isMine: false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _markerColor(obs.snowType).withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white54, width: 1.5),
                          ),
                          child: const Icon(Icons.ac_unit, color: Colors.white70, size: 16),
                        ),
                      ),
                    )),
                ],
              ),
            ],
          ),

          // Toggle communauté + compteur
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F1A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loadingCommunity)
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D9E75)),
                    )
                  else
                    Text(
                      '${_communityObs.length} obs communautaires · $_hoursFilter h',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showCommunity = !_showCommunity),
                    child: Icon(
                      _showCommunity ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF1D9E75),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Légende
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F1A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(color: const Color(0xFF1D9E75), label: 'poudre'),
                  _LegendItem(color: const Color(0xFF4CAF50), label: 'moquette / transfo'),
                  _LegendItem(color: const Color(0xFFF5A623), label: 'béton / croûte'),
                  _LegendItem(color: const Color(0xFFFF6B6B), label: 'ventée / lourde'),
                  _LegendItem(color: const Color(0xFF378ADD), label: 'humide'),
                  _LegendItem(color: Colors.grey, label: 'purge'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showObsDetail(BuildContext context, Observation obs, {required bool isMine}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A3A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      obs.snowType ?? 'Type inconnu',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D9E75).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('moi', style: TextStyle(color: Color(0xFF1D9E75), fontSize: 11)),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${obs.timestamp.day}/${obs.timestamp.month} ${obs.timestamp.hour}h${obs.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (obs.rawNotes != null)
              Text(obs.rawNotes!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              '${obs.altitudeM.toInt()}m · ${obs.aspect ?? '?'} · stabilité ${obs.stabilityScore ?? '?'}/5',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}