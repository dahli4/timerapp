import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/study_timer_model.dart';
import '../../../data/timer_group_model.dart';

class TimerListViewModel {
  final Box<StudyTimerModel> timerBox;
  final Box<TimerGroupModel> groupBox;

  TimerListViewModel(this.timerBox, this.groupBox);

  List<StudyTimerModel> getUngroupedTimers() {
    return timerBox.values.where((timer) => timer.groupId == null).toList();
  }

  List<StudyTimerModel> getTimersForGroup(String? groupId) {
    return timerBox.values.where((t) => t.groupId == groupId).toList();
  }

  List<StudyTimerModel> getFavoriteTimers() {
    return timerBox.values.where((t) => t.isFavorite).toList();
  }

  List<TimerGroupModel> getGroupsSorted() {
    final groups = groupBox.values.toList();
    groups.sort((a, b) => a.safeOrder.compareTo(b.safeOrder));
    return groups;
  }

  Future<void> addTimer(StudyTimerModel timer) async {
    await timerBox.add(timer);
  }

  Future<void> updateTimer(int index, StudyTimerModel timer) async {
    await timerBox.putAt(index, timer);
  }

  Future<void> ungroupTimers(String groupId) async {
    final timers = getTimersForGroup(groupId);
    for (final timer in timers) {
      final idx = timerBox.values.toList().indexOf(timer);
      await updateTimer(idx, timer.copyWith(groupId: null));
    }
  }
}
