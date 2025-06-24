import 'package:hive/hive.dart';

part 'study_timer_model.g.dart';

@HiveType(typeId: 0)
class StudyTimerModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final int durationMinutes;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final int? colorHex;
  @HiveField(5)
  final String? groupId; // 그룹 ID
  @HiveField(6)
  final bool? _isInfinite; // nullable로 변경하여 기존 데이터 호환성 확보
  @HiveField(7)
  final bool? _isFavorite; // 즐겨찾기

  // isInfinite getter로 backward compatibility 제공
  bool get isInfinite => _isInfinite ?? false;
  // isFavorite getter로 backward compatibility 제공
  bool get isFavorite => _isFavorite ?? false;

  StudyTimerModel({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.createdAt,
    this.colorHex,
    this.groupId,
    bool isInfinite = false,
    bool isFavorite = false,
  }) : _isInfinite = isInfinite,
       _isFavorite = isFavorite;

  // 기존 데이터를 새로운 형식으로 마이그레이션하는 헬퍼 메서드
  StudyTimerModel copyWith({
    String? id,
    String? title,
    int? durationMinutes,
    DateTime? createdAt,
    int? colorHex,
    String? groupId,
    bool? isInfinite,
    bool? isFavorite,
  }) {
    return StudyTimerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdAt: createdAt ?? this.createdAt,
      colorHex: colorHex ?? this.colorHex,
      groupId: groupId ?? this.groupId,
      isInfinite: isInfinite ?? this.isInfinite,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
