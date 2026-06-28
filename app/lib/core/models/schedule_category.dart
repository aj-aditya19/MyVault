import 'package:flutter/material.dart';

/// Category options for Weekly Schedule Planner time blocks.
enum ScheduleCategory { study, project, personal, fitness, other }

extension ScheduleCategoryX on ScheduleCategory {
  String get label {
    switch (this) {
      case ScheduleCategory.study:
        return 'Study';
      case ScheduleCategory.project:
        return 'Project';
      case ScheduleCategory.personal:
        return 'Personal';
      case ScheduleCategory.fitness:
        return 'Fitness';
      case ScheduleCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case ScheduleCategory.study:
        return const Color(0xFF1E88E5);
      case ScheduleCategory.project:
        return const Color(0xFF8E24AA);
      case ScheduleCategory.personal:
        return const Color(0xFF00897B);
      case ScheduleCategory.fitness:
        return const Color(0xFFEF6C00);
      case ScheduleCategory.other:
        return const Color(0xFF607D8B);
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleCategory.study:
        return Icons.menu_book_rounded;
      case ScheduleCategory.project:
        return Icons.code_rounded;
      case ScheduleCategory.personal:
        return Icons.person_rounded;
      case ScheduleCategory.fitness:
        return Icons.fitness_center_rounded;
      case ScheduleCategory.other:
        return Icons.category_rounded;
    }
  }

  static ScheduleCategory fromString(String? value) {
    return ScheduleCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ScheduleCategory.other,
    );
  }
}
