import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/study_timer_model.dart';
import '../../../data/timer_group_model.dart';

class GroupViewModel {
  final Box<TimerGroupModel> groupBox;
  final Box<StudyTimerModel> timerBox;

  GroupViewModel(this.groupBox, this.timerBox);

  List<TimerGroupModel> get groupsSorted {
    final groups = groupBox.values.toList();
    groups.sort((a, b) => a.safeOrder.compareTo(b.safeOrder));
    return groups;
  }

  Future<void> moveGroupUp(int index) async {
    if (index <= 0) return;
    final groups = groupsSorted;
    final current = groups[index];
    final above = groups[index - 1];
    final tempOrder = current.safeOrder;
    final updatedCurrent = TimerGroupModel(
      id: current.id,
      name: current.name,
      colorHex: current.colorHex,
      createdAt: current.createdAt,
      modifiedAt: DateTime.now(),
      order: above.safeOrder,
    );
    final updatedAbove = TimerGroupModel(
      id: above.id,
      name: above.name,
      colorHex: above.colorHex,
      createdAt: above.createdAt,
      modifiedAt: DateTime.now(),
      order: tempOrder,
    );
    await current.delete();
    await above.delete();
    await groupBox.add(updatedCurrent);
    await groupBox.add(updatedAbove);
  }

  Future<void> moveGroupDown(int index) async {
    final groups = groupsSorted;
    if (index >= groups.length - 1) return;
    final current = groups[index];
    final below = groups[index + 1];
    final tempOrder = current.safeOrder;
    final updatedCurrent = TimerGroupModel(
      id: current.id,
      name: current.name,
      colorHex: current.colorHex,
      createdAt: current.createdAt,
      modifiedAt: DateTime.now(),
      order: below.safeOrder,
    );
    final updatedBelow = TimerGroupModel(
      id: below.id,
      name: below.name,
      colorHex: below.colorHex,
      createdAt: below.createdAt,
      modifiedAt: DateTime.now(),
      order: tempOrder,
    );
    await current.delete();
    await below.delete();
    await groupBox.add(updatedCurrent);
    await groupBox.add(updatedBelow);
  }

  Future<void> updateGroup(TimerGroupModel group) async {
    final index = groupBox.values.toList().indexWhere((g) => g.id == group.id);
    if (index >= 0) {
      await groupBox.putAt(index, group);
    }
  }

  Future<void> deleteGroup(TimerGroupModel group) async {
    final timers = timerBox.values.where((t) => t.groupId == group.id).toList();
    for (final timer in timers) {
      final idx = timerBox.values.toList().indexOf(timer);
      await timerBox.putAt(idx, timer.copyWith(groupId: null));
    }
    final index = groupBox.values.toList().indexWhere((g) => g.id == group.id);
    if (index >= 0) {
      await groupBox.deleteAt(index);
    }
  }
}
