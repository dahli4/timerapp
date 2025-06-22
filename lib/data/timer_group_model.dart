import 'package:hive/hive.dart';

part 'timer_group_model.g.dart';

@HiveType(typeId: 3)
class TimerGroupModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int? colorHex;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime? modifiedAt;

  TimerGroupModel({
    required this.id,
    required this.name,
    this.colorHex,
    required this.createdAt,
    this.modifiedAt,
  });
}
