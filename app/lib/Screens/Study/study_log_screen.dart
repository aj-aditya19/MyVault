import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/models/study_session_model.dart';
import 'package:app/core/services/storage_service.dart';

class StudyLogScreen extends StatefulWidget {
  final VoidCallback? onSaved;
  const StudyLogScreen({super.key, this.onSaved});

  @override
  State<StudyLogScreen> createState() => _StudyLogScreenState();
}

class _StudyLogScreenState extends State<StudyLogScreen> {
  static const _boxName = 'study_sessions';
  static final _uuid = Uuid();

  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _notesController = TextEditingController();

  List<StudySession> _sessions = [];
  bool _loading = true;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _topicController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final raw = await StorageService.readList(_boxName);
    final sessions = raw.map(StudySession.fromJson).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await StorageService.write(
      _boxName,
      _sessions.map((s) => s.toJson()).toList(),
    );
  }

  void _clearForm() {
    _editingId = null;
    _subjectController.clear();
    _topicController.clear();
    _durationController.text = '30';
    _notesController.clear();
  }

  Future<void> _save() async {
    final subject = _subjectController.text.trim();
    final topic = _topicController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;

    if (subject.isEmpty || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a subject and a duration greater than 0.'),
        ),
      );
      return;
    }

    setState(() {
      if (_editingId == null) {
        _sessions.insert(
          0,
          StudySession(
            id: _uuid.v4(),
            subject: subject,
            topic: topic,
            durationMinutes: duration,
            notes: _notesController.text.trim(),
            date: DateTime.now(),
          ),
        );
      } else {
        final index = _sessions.indexWhere((s) => s.id == _editingId);
        if (index != -1) {
          _sessions[index] = _sessions[index].copyWith(
            subject: subject,
            topic: topic,
            durationMinutes: duration,
            notes: _notesController.text.trim(),
          );
        }
      }
      _clearForm();
    });

    await _persist();
    widget.onSaved?.call();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Study session saved.')));
    }
  }

  void _editSession(StudySession session) {
    setState(() {
      _editingId = session.id;
      _subjectController.text = session.subject;
      _topicController.text = session.topic;
      _durationController.text = session.durationMinutes.toString();
      _notesController.text = session.notes;
    });
  }

  Future<void> _deleteSession(String id) async {
    setState(() => _sessions.removeWhere((s) => s.id == id));
    await _persist();
    widget.onSaved?.call();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) return 'Today, ${_formatTime(date)}';
    return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingId == null ? 'Log a study session' : 'Edit session',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g. Data Structures',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  hintText: 'e.g. Binary Search Trees',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_editingId != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: () => setState(_clearForm),
                        child: const Text('Cancel'),
                      ),
                    ),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: Icon(
                        _editingId == null ? Icons.add : Icons.save_outlined,
                      ),
                      label: Text(_editingId == null ? 'Add Session' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Recent sessions',
          style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        if (_sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No sessions logged yet - add your first one above.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ..._sessions.map((session) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${session.durationMinutes}m',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.subject,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (session.topic.isNotEmpty)
                          Text(
                            session.topic,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          _formatDate(session.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    onPressed: () => _editSession(session),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 19, color: scheme.error),
                    onPressed: () => _deleteSession(session.id),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 40),
      ],
    );
  }
}
