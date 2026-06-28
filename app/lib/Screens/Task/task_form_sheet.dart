import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/models/task_model.dart';

/// Shows the add/edit task form as a modal bottom sheet. Returns the new
/// or updated [TaskItem], or null if the person cancelled.
Future<TaskItem?> showTaskFormSheet(
  BuildContext context, {
  TaskItem? existing,
  required String dayKey,
}) {
  return showModalBottomSheet<TaskItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TaskFormSheet(existing: existing, dayKey: dayKey),
  );
}

class _TaskFormSheet extends StatefulWidget {
  final TaskItem? existing;
  final String dayKey;

  const _TaskFormSheet({required this.existing, required this.dayKey});

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  static final _uuid = Uuid();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagController;

  late TaskPriority _priority;
  DateTime? _dueDate;
  bool _reminderEnabled = false;
  DateTime? _reminderAt;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _tagController = TextEditingController();
    _priority = existing?.priority ?? TaskPriority.medium;
    _dueDate = existing?.dueDate;
    _reminderAt = existing?.reminderAt;
    _reminderEnabled = existing?.reminderAt != null;
    _tags = List.of(existing?.tags ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickReminderTime() async {
    final base = _reminderAt ?? _dueDate ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (time == null) return;

    setState(() {
      _reminderAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _addTag(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty || _tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the task a title first.')),
      );
      return;
    }

    final reminderAt = _reminderEnabled ? _reminderAt : null;

    final result = widget.existing == null
        ? TaskItem(
            id: _uuid.v4(),
            title: title,
            description: _descriptionController.text.trim(),
            priority: _priority,
            dueDate: _dueDate,
            reminderAt: reminderAt,
            tags: _tags,
            createdAt: DateTime.now(),
            dayKey: widget.dayKey,
          )
        : widget.existing!.copyWith(
            title: title,
            description: _descriptionController.text.trim(),
            priority: _priority,
            dueDate: _dueDate,
            clearDueDate: _dueDate == null,
            reminderAt: reminderAt,
            clearReminder: reminderAt == null,
            tags: _tags,
          );

    Navigator.of(context).pop(result);
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(date)}, $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  isEditing ? 'Edit Task' : 'New Task',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  autofocus: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Priority', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 8),
                SegmentedButton<TaskPriority>(
                  segments: TaskPriority.values
                      .map(
                        (p) => ButtonSegment(
                          value: p,
                          label: Text(p.label),
                          icon: Icon(Icons.flag_rounded, color: p.color, size: 16),
                        ),
                      )
                      .toList(),
                  selected: {_priority},
                  onSelectionChanged: (selection) {
                    setState(() => _priority = selection.first);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDueDate,
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text(
                          _dueDate == null ? 'Set due date' : _formatDate(_dueDate!),
                        ),
                      ),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Remind me'),
                  subtitle: Text(
                    _reminderEnabled && _reminderAt != null
                        ? _formatDateTime(_reminderAt!)
                        : 'Get a notification before this task is due',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _reminderEnabled,
                  onChanged: (value) {
                    setState(() {
                      _reminderEnabled = value;
                      if (value && _reminderAt == null) {
                        _reminderAt = _dueDate ?? DateTime.now().add(const Duration(hours: 1));
                      }
                    });
                  },
                ),
                if (_reminderEnabled)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _pickReminderTime,
                      icon: const Icon(Icons.alarm_rounded, size: 18),
                      label: const Text('Choose reminder time'),
                    ),
                  ),
                const SizedBox(height: 12),
                Text('Tags', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: 'Type a tag and press enter',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => _addTag(_tagController.text),
                    ),
                  ),
                  onSubmitted: _addTag,
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            onDeleted: () => setState(() => _tags.remove(tag)),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Save Changes' : 'Add Task'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
