import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DailyCheckinScreen extends StatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final TextEditingController _studyHoursController = TextEditingController();
  final TextEditingController _exerciseController = TextEditingController();
  final TextEditingController _achievementController = TextEditingController();
  final TextEditingController _lossController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late File _checkinFile;
  late File _goalsFile;
  late encrypt.Key _key;
  late encrypt.Encrypter _encrypter;

  Map<String, dynamic> _allCheckins = {};
  List<String> _constantGoals = [];
  Map<String, bool> _goalStatus = {};

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  void initState() {
    super.initState();
    _key = encrypt.Key.fromUtf8('my 32 length key................');
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
    _initFiles();
  }

  String _encryptData(String data) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(data, iv: iv);
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  String _decryptData(String base64Data) {
    final combined = base64Decode(base64Data);
    final iv = encrypt.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);
    final encrypted = encrypt.Encrypted(encryptedBytes);
    return _encrypter.decrypt(encrypted, iv: iv);
  }

  Future<void> _initFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    _checkinFile = File('${dir.path}/daily_checkin.txt');
    _goalsFile = File('${dir.path}/constant_goals.txt');

    if (!await _checkinFile.exists()) {
      await _checkinFile.create();
      await _checkinFile.writeAsString(_encryptData(jsonEncode({})));
    }

    if (!await _goalsFile.exists()) {
      await _goalsFile.create();
      await _goalsFile.writeAsString(_encryptData(jsonEncode(<String>[])));
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    await _loadConstantGoals();
    await _loadCheckin();
  }

  Future<void> _loadConstantGoals() async {
    try {
      final content = await _goalsFile.readAsString();
      if (content.isEmpty) return;

      final decrypted = _decryptData(content);
      final decoded = jsonDecode(decrypted);
      if (decoded is List) {
        _constantGoals = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      _constantGoals = [];
    }
  }

  Future<void> _loadCheckin() async {
    try {
      final content = await _checkinFile.readAsString();
      if (content.isEmpty) return;

      final decrypted = _decryptData(content);
      final decoded = jsonDecode(decrypted);
      if (decoded is Map<String, dynamic>) {
        _allCheckins = decoded;
      }

      final todayData = _allCheckins[_today] as Map<String, dynamic>?;
      if (todayData != null) {
        _studyHoursController.text = (todayData['study_hours'] ?? '')
            .toString();
        _exerciseController.text = (todayData['exercise_minutes'] ?? '')
            .toString();
        _achievementController.text = (todayData['achievement'] ?? '')
            .toString();
        _lossController.text = (todayData['loss'] ?? '').toString();
        _notesController.text = (todayData['notes'] ?? '').toString();

        final storedGoals = todayData['goals'] as Map<String, dynamic>? ?? {};
        _goalStatus = {
          for (final goal in _constantGoals) goal: (storedGoals[goal] == true),
        };
      } else {
        _goalStatus = {for (final goal in _constantGoals) goal: false};
      }

      setState(() {});
    } catch (_) {}
  }

  Future<void> _saveCheckin() async {
    _allCheckins[_today] = {
      'study_hours': double.tryParse(_studyHoursController.text.trim()) ?? 0,
      'exercise_minutes': int.tryParse(_exerciseController.text.trim()) ?? 0,
      'achievement': _achievementController.text.trim(),
      'loss': _lossController.text.trim(),
      'notes': _notesController.text.trim(),
      'goals': _goalStatus,
      'saved_at': DateTime.now().toIso8601String(),
    };

    await _checkinFile.writeAsString(_encryptData(jsonEncode(_allCheckins)));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Daily check-in saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-in')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveCheckin,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Today Metrics',
            child: Column(
              children: [
                _LabeledInput(
                  label: 'Study Hours',
                  hint: 'e.g. 5.5',
                  controller: _studyHoursController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 10),
                _LabeledInput(
                  label: 'Exercise Minutes',
                  hint: 'e.g. 45',
                  controller: _exerciseController,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Reflection',
            child: Column(
              children: [
                _LabeledInput(
                  label: 'Today Achievement',
                  hint: 'What did you do well today?',
                  controller: _achievementController,
                ),
                const SizedBox(height: 10),
                _LabeledInput(
                  label: 'Today Loss / Mistake',
                  hint: 'What did not go well?',
                  controller: _lossController,
                ),
                const SizedBox(height: 10),
                _LabeledInput(
                  label: 'Extra Notes',
                  hint: 'Anything else about today',
                  controller: _notesController,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Constant Goals Completion',
            child: _constantGoals.isEmpty
                ? Text(
                    'No constant goals found. Add goals in Constant Goals screen.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  )
                : Column(
                    children: _constantGoals
                        .map(
                          (goal) => CheckboxListTile(
                            value: _goalStatus[goal] ?? false,
                            contentPadding: EdgeInsets.zero,
                            title: Text(goal),
                            onChanged: (value) {
                              setState(() {
                                _goalStatus[goal] = value ?? false;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 88),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _LabeledInput({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
