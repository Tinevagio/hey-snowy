import 'package:flutter/material.dart';
import '../models/observation.dart';
import 'edit_observation_screen.dart';

class ReviewScreen extends StatefulWidget {
  final List<Observation> observations;
  const ReviewScreen({super.key, required this.observations});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late List<Observation> _obs;

  @override
  void initState() {
    super.initState();
    _obs = widget.observations.reversed.toList();
  }

  // Groupe les observations par date
  Map<String, List<Observation>> _groupByDate() {
    final Map<String, List<Observation>> grouped = {};
    for (final obs in _obs) {
      final key = _dateLabel(obs.timestamp);
      grouped.putIfAbsent(key, () => []).add(obs);
    }
    return grouped;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final obsDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(obsDay).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    final dates = grouped.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F1A),
        title: const Text(
          'Observations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _obs.isEmpty
          ? const Center(
              child: Text(
                'Aucune observation',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dates.fold<int>(0, (sum, d) => sum + 1 + grouped[d]!.length),
              itemBuilder: (context, index) {
                // Calcule quel item afficher
                int cursor = 0;
                for (final date in dates) {
                  if (index == cursor) {
                    return _DateHeader(label: date, count: grouped[date]!.length);
                  }
                  cursor++;
                  final obsForDate = grouped[date]!;
                  if (index < cursor + obsForDate.length) {
                    final obs = obsForDate[index - cursor];
                    final globalIndex = _obs.indexOf(obs);
                    return _ObsCard(
                      obs: obs,
                      onUpdated: (updated) {
                        setState(() => _obs[globalIndex] = updated);
                      },
                      onDeleted: (id) {
                        setState(() => _obs.removeWhere((o) => o.id == id));
                      },
                    );
                  }
                  cursor += obsForDate.length;
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  final int count;
  const _DateHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1D9E75),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count obs.',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 0.5,
              color: const Color(0xFF1D9E75).withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObsCard extends StatelessWidget {
  final Observation obs;
  final Function(Observation) onUpdated;
  final Function(String) onDeleted;
  const _ObsCard({required this.obs, required this.onUpdated, required this.onDeleted});

  Color _stabilityColor(int? score) {
    if (score == null) return Colors.grey;
    if (score <= 2) return const Color(0xFF1D9E75);
    if (score == 3) return const Color(0xFFF5A623);
    return const Color(0xFFFF6B6B);
  }

  IconData _snowIcon(String? type) {
    switch (type) {
      case 'poudre': return Icons.ac_unit;
      case 'moquette':
      case 'transfo': return Icons.grass;
      case 'béton':
      case 'croûte': return Icons.layers;
      case 'ventée': return Icons.air;
      case 'humide': return Icons.opacity;
      case 'purge': return Icons.landslide;
      case 'lourde': return Icons.water_drop;
      default: return Icons.terrain;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<Observation>(
          context,
          MaterialPageRoute(
            builder: (_) => EditObservationScreen(observation: obs),
          ),
        );
        if (updated != null) {
          onUpdated(updated);
        } else {
          onDeleted(obs.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_snowIcon(obs.snowType), color: const Color(0xFF1D9E75), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      obs.snowType ?? 'Type inconnu',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${obs.timestamp.hour}h${obs.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (obs.altitudeM > 0)
                  _Badge('${obs.altitudeM.toInt()}m', Icons.height, Colors.white54),
                if (obs.aspect != null)
                  _Badge(obs.aspect!, Icons.explore, Colors.white54),
                if (obs.depthCm != null)
                  _Badge('${obs.depthCm}cm', Icons.straighten, Colors.white54),
                if (obs.stabilityScore != null)
                  _Badge(
                    'Risque ${obs.stabilityScore}',
                    Icons.warning_amber,
                    _stabilityColor(obs.stabilityScore),
                  ),
              ],
            ),
            if (obs.rawNotes != null) ...[
              const SizedBox(height: 10),
              Text(obs.rawNotes!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
            if (obs.transcript != null) ...[
              const SizedBox(height: 8),
              Text(
                '"${obs.transcript}"',
                style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${obs.lat.toStringAsFixed(5)}, ${obs.lon.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Badge(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}