import '../../../utils/daily_goal_service.dart';

class DailyGoalViewModel {
  final DailyGoalService _service = DailyGoalService();

  DailyProgressInfo getProgressInfo() {
    return _service.getTodayProgressInfo();
  }
}
