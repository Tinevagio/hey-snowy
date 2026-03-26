import 'package:flutter/material.dart';
import '../models/observation.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

class EditObservationScreen extends StatefulWidget {
  final Observation observation;
  const EditObservationScreen({super.key, required this.observation});

  @override
  State<EditObservationScreen> createState() => _EditObservationScreenState();
}

class _EditObservationScreenState extends State<EditObservationScreen> {
  late String? _snowType;
  late int? _stabilityScore;
  late String? _aspect;
  late TextEditingController _notesController;
  bool _saving = false;

  final List<String> _snowTypes = [
    'poudre', 'moquette', 'transfo', 'béton',
    'croûte', 'ventée', 'humide', 'purge', 'lourde', 'autre'
  ];

  final List<String?> _aspects = [
    null, 'N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'
  ];

  @override
  void initState() {
    super.initState();
    _snowType = widget.observation.snowType;
    _stabilityScore = widget.observation.stabilityScore;
    _aspect = widget.observation.aspect;
    _notesController = TextEditingController(
      text: widget.observation.rawNotes ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }



  Future<void> _save() async {
    setState(() => _saving = true);

    widget.observation.snowType = _snowType;
    widget.observation.stabilityScore = _stabilityScore;
    widget.observation.aspect = _aspect;
    widget.observation.rawNotes = _notesController.text;

    // Sauvegarde SQLite
    await StorageService().updateObservation(widget.observation);

    // Mise à jour Supabase si déjà uploadée
    if (widget.observation.uploaded) {
      await SupabaseService().uploadObservation(widget.observation);
    }

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context, widget.observation);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A3A2A),
        title: const Text(
          'Supprimer cette observation ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Cette action est irréversible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService().deleteObservation(widget.observation.id);
      if (widget.observation.uploaded) {
        await SupabaseService().deleteObservation(widget.observation.id);
      }
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F1A),
        title: const Text(
          'Modifier',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
            onPressed: () => _confirmDelete(context),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF1D9E75),
                    ),
                  )
                : const Text(
                    'Sauvegarder',
                    style: TextStyle(color: Color(0xFF1D9E75)),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transcript (lecture seule)
            if (widget.observation.transcript != null) ...[
              const Text('Transcription', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A2A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '"${widget.observation.transcript}"',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Type de neige
            const Text('Type de neige', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _snowTypes.map((type) {
                final selected = _snowType == type;
                return GestureDetector(
                  onTap: () => setState(() => _snowType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFF1A3A2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1D9E75)
                            : Colors.white24,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Orientation
            const Text('Orientation', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _aspects.map((aspect) {
                final selected = _aspect == aspect;
                return GestureDetector(
                  onTap: () => setState(() => _aspect = aspect),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFF1A3A2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF1D9E75)
                            : Colors.white24,
                      ),
                    ),
                    child: Text(
                      aspect ?? '—',
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Stabilité
            const Text('Stabilité (1 = stable, 5 = instable)', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('1', style: TextStyle(color: Colors.white54)),
                Expanded(
                  child: Slider(
                    value: (_stabilityScore ?? 1).toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: const Color(0xFF1D9E75),
                    label: '${_stabilityScore ?? 1}',
                    onChanged: (v) => setState(() => _stabilityScore = v.toInt()),
                  ),
                ),
                const Text('5', style: TextStyle(color: Colors.white54)),
              ],
            ),
            const SizedBox(height: 20),

            // Notes
            const Text('Notes', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1A3A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Notes sur les conditions...',
                hintStyle: const TextStyle(color: Colors.white24),
              ),
            ),

            // Infos GPS (lecture seule)
            const SizedBox(height: 20),
            Text(
              '${widget.observation.altitudeM.toInt()}m · ${widget.observation.lat.toStringAsFixed(5)}, ${widget.observation.lon.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}