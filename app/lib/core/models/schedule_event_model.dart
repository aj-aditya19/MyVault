import 'package:flutter/material.dart';

enum ScheduleCategory {
  workout,
  study,
  college,
  project,
  meal,
  freeTime,
  meeting,
  outing,
  reading,
  other,
}

extension ScheduleCategoryX on ScheduleCategory {
  String get label {
    switch (this) {
      case ScheduleCategory.workout:
        return 'Workout';
      case ScheduleCategory.study:
        return 'Study';
      case ScheduleCategory.college:
        return 'College';
      case ScheduleCategory.project:
        return 'Project';
      case ScheduleCategory.meal:
        return 'Lunch / Rest';
      case ScheduleCategory.freeTime:
        return 'Free Time';
      case ScheduleCategory.meeting:
        return 'Meeting';
      case ScheduleCategory.outing:
        return 'Outing / Movie';
      case ScheduleCategory.reading:
        return 'Read / Learn';
      case ScheduleCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleCategory.workout:
        return Icons.fitness_center_rounded;
      case ScheduleCategory.study:
        return Icons.menu_book_rounded;
      case ScheduleCategory.college:
        return Icons.school_rounded;
      case ScheduleCategory.project:
        return Icons.code_rounded;
      case ScheduleCategory.meal:
        return Icons.restaurant_rounded;
      case ScheduleCategory.freeTime:
        return Icons.sports_esports_rounded;
      case ScheduleCategory.meeting:
        return Icons.groups_rounded;
      case ScheduleCategory.outing:
        return Icons.local_movies_rounded;
      case ScheduleCategory.reading:
        return Icons.import_contacts_rounded;
      case ScheduleCategory.other:
        return Icons.event_note_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ScheduleCategory.workout:
        return const Color(0xFF14B8A6);
      case ScheduleCategory.study:
        return const Color(0xFF3B82F6);
      case ScheduleCategory.college:
        return const Color(0xFF8B5CF6);
      case ScheduleCategory.project:
        return const Color(0xFFD4A017);
      case ScheduleCategory.meal:
        return const Color(0xFF10B981);
      case ScheduleCategory.freeTime:
        return const Color(0xFFEF4444);
      case ScheduleCategory.meeting:
        return const Color(0xFF8B5CF6);
      case ScheduleCategory.outing:
        return const Color(0xFF8B5CF6);
      case ScheduleCategory.reading:
        return const Color(0xFF22C55E);
      case ScheduleCategory.other:
        return const Color(0xFF64748B);
    }
  }
}

ScheduleCategory categoryFromString(String? value) {
  return ScheduleCategory.values.firstWhere(
    (c) => c.name == value,
    orElse: () => ScheduleCategory.other,
  );
}

class ScheduleEvent {
  final String id;
  String title;
  String subtitle;
  DateTime date;
  TimeOfDay start;
  TimeOfDay end;
  ScheduleCategory category;
  bool isDone;

  ScheduleEvent({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.date,
    required this.start,
    required this.end,
    this.category = ScheduleCategory.other,
    this.isDone = false,
  });

  DateTime get dayOnly => DateTime(date.year, date.month, date.day);

  DateTime get startDateTime =>
      DateTime(date.year, date.month, date.day, start.hour, start.minute);

  DateTime get endDateTime =>
      DateTime(date.year, date.month, date.day, end.hour, end.minute);

  int get startMinutes => start.hour * 60 + start.minute;
  int get endMinutes => end.hour * 60 + end.minute;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'date': _fmtDate(date),
    'start': _fmtTime(start),
    'end': _fmtTime(end),
    'category': category.name,
    'isDone': isDone,
  };

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    final dateParts = (json['date']?.toString() ?? '').split('-');
    final date = dateParts.length == 3
        ? DateTime(
            int.tryParse(dateParts[0]) ?? DateTime.now().year,
            int.tryParse(dateParts[1]) ?? 1,
            int.tryParse(dateParts[2]) ?? 1,
          )
        : DateTime.now();

    TimeOfDay parseTime(String? raw, TimeOfDay fallback) {
      final parts = (raw ?? '').split(':');
      if (parts.length != 2) return fallback;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return fallback;
      return TimeOfDay(hour: h, minute: m);
    }

    return ScheduleEvent(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      date: date,
      start: parseTime(
        json['start']?.toString(),
        const TimeOfDay(hour: 9, minute: 0),
      ),
      end: parseTime(
        json['end']?.toString(),
        const TimeOfDay(hour: 10, minute: 0),
      ),
      category: categoryFromString(json['category']?.toString()),
      isDone: json['isDone'] == true,
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String scheduleDateKey(DateTime d) => _fmtDate(d);
