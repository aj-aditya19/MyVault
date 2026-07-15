import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFE53935);
      case TaskPriority.medium:
        return const Color(0xFFFB8C00);
      case TaskPriority.low:
        return const Color(0xFF43A047);
    }
  }

  static TaskPriority fromString(String? value) {
    switch (value) {
      case 'high':
        return TaskPriority.high;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }

  String get storageValue => name;
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final List<String> tags;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String dayKey;

  const TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.reminderAt,
    this.tags = const [],
    this.isDone = false,
    required this.createdAt,
    this.completedAt,
    required this.dayKey,
  });

  /// Stable, small int derived from the task id - used as the local
  /// notification id so reminders can be scheduled/cancelled per task.
  int get notificationId => id.hashCode & 0x7FFFFFFF;

  TaskItem copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? reminderAt,
    bool clearReminder = false,
    List<String>? tags,
    bool? isDone,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      tags: tags ?? this.tags,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      dayKey: dayKey,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority.storageValue,
    'dueDate': dueDate?.toIso8601String(),
    'reminderAt': reminderAt?.toIso8601String(),
    'tags': tags,
    'isDone': isDone,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'dayKey': dayKey,
  };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return TaskItem(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: TaskPriorityX.fromString(json['priority']?.toString()),
      dueDate: parseDate(json['dueDate']),
      reminderAt: parseDate(json['reminderAt']),
      tags:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      isDone: json['isDone'] == true,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      completedAt: parseDate(json['completedAt']),
      dayKey: json['dayKey']?.toString() ?? '',
    );
  }

  /// Builds a [TaskItem] from the legacy `{"title": ..., "isDone": ...}`
  /// shape used by the original app so old saved data keeps working.
  factory TaskItem.fromLegacy(
    Map<String, dynamic> json,
    String dayKey,
    String id,
  ) {
    return TaskItem(
      id: id,
      title: json['title']?.toString() ?? '',
      isDone: json['isDone'] == true,
      createdAt: DateTime.now(),
      dayKey: dayKey,
    );
  }
}

String dayKeyFor(DateTime date) => '${date.year}-${date.month}-${date.day}';
