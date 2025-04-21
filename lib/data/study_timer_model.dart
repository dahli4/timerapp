// lib/data/models/study_timer_model.dart
class StudyTimerModel {
  final String id;
  final String title;
  final int durationMinutes;
  final DateTime createdAt;
  final int? colorHex; // optional

  StudyTimerModel({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.createdAt,
    this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'durationMinutes': durationMinutes,
      'createdAt': createdAt.toIso8601String(),
      'colorHex': colorHex,
    };
  }

  factory StudyTimerModel.fromMap(Map<String, dynamic> map) {
    return StudyTimerModel(
      id: map['id'],
      title: map['title'],
      durationMinutes: map['durationMinutes'],
      createdAt: DateTime.parse(map['createdAt']),
      colorHex: map['colorHex'],
    );
  }
}
