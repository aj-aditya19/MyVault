/// A single logged study session - the core record for the Study Tracker.
class StudySession {
  final String id;
  final String subject;
  final String topic;
  final int durationMinutes;
  final String notes;
  final DateTime date;

  const StudySession({
    required this.id,
    required this.subject,
    required this.topic,
    required this.durationMinutes,
    this.notes = '',
    required this.date,
  });

  StudySession copyWith({
    String? subject,
    String? topic,
    int? durationMinutes,
    String? notes,
    DateTime? date,
  }) {
    return StudySession(
      id: id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'topic': topic,
    'durationMinutes': durationMinutes,
    'notes': notes,
    'date': date.toIso8601String(),
  };

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      subject: json['subject']?.toString() ?? 'General',
      topic: json['topic']?.toString() ?? '',
      durationMinutes: (json['durationMinutes'] is int)
          ? json['durationMinutes'] as int
          : int.tryParse(json['durationMinutes']?.toString() ?? '') ?? 0,
      notes: json['notes']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
