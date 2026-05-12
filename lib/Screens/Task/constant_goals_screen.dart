import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ConstantGoalsScreen extends StatefulWidget {
  const ConstantGoalsScreen({super.key});

  @override
  State<ConstantGoalsScreen> createState() => _ConstantGoalsScreenState();
}

class _ConstantGoalsScreenState extends State<ConstantGoalsScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _goals = [];

  late File _goalsFile;
  late encrypt.Key _key;
  late encrypt.Encrypter _encrypter;

  @override
  void initState() {
    super.initState();
    _key = encrypt.Key.fromUtf8('my 32 length key................');
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
    _initFile();
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

  Future<void> _initFile() async {
    final dir = await getApplicationDocumentsDirectory();
    _goalsFile = File('${dir.path}/constant_goals.txt');

    if (!await _goalsFile.exists()) {
      await _goalsFile.create();
      await _goalsFile.writeAsString(_encryptData(jsonEncode(<String>[])));
    }

    await _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final content = await _goalsFile.readAsString();
      if (content.isEmpty) return;

      final decrypted = _decryptData(content);
      final decoded = jsonDecode(decrypted);
      if (decoded is List) {
        setState(() {
          _goals
            ..clear()
            ..addAll(decoded.map((e) => e.toString()));
        });
      }
    } catch (_) {
      try {
        final fallback = await _goalsFile.readAsString();
        final decoded = jsonDecode(fallback);
        if (decoded is List) {
          setState(() {
            _goals
              ..clear()
              ..addAll(decoded.map((e) => e.toString()));
          });
          await _saveGoals();
        }
      } catch (_) {}
    }
  }

  Future<void> _saveGoals() async {
    await _goalsFile.writeAsString(_encryptData(jsonEncode(_goals)));
  }

  Future<void> _addGoal() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _goals.add(text);
      _controller.clear();
    });
    await _saveGoals();
  }

  Future<void> _removeGoal(int index) async {
    setState(() {
      _goals.removeAt(index);
    });
    await _saveGoals();
  }

  Future<void> _editGoal(int index) async {
    final editController = TextEditingController(text: _goals[index]);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Goal'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: 'Goal text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = editController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _goals[index] = text;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    await _saveGoals();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Constant Goals')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.64),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Add a daily constant goal',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addGoal,
                    icon: const Icon(Icons.add_circle_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'These goals appear in your Daily Check-in.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _goals.isEmpty
                  ? Center(
                      child: Text(
                        'No constant goals yet',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.70),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.24,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: Text(goal),
                            trailing: Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  onPressed: () => _editGoal(index),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () => _removeGoal(index),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: scheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
