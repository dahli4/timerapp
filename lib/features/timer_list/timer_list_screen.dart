import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/study_timer_model.dart';
import '../../data/timer_group_model.dart';
import '../../widgets/daily_goal_dialog.dart';
import '../../widgets/group_management_dialog.dart';
import '../../utils/daily_goal_service.dart';
import 'timer_list_dialogs.dart';
import 'group_timers_screen.dart';
import '../timer_run/timer_run_screen.dart';
import '../timer_run/infinite_timer_run_screen.dart';

class TimerListScreen extends StatefulWidget {
  const TimerListScreen({super.key});

  @override
  State<TimerListScreen> createState() => _TimerListScreenState();
}

class _TimerListScreenState extends State<TimerListScreen> {
  late Box<StudyTimerModel> _timerBox;
  late Box<TimerGroupModel> _groupBox;

  @override
  void initState() {
    super.initState();
    _timerBox = Hive.box<StudyTimerModel>('timers');
    _groupBox = Hive.box<TimerGroupModel>('groups');
  }

  void _showAddTimerDialog() {
    final titleController = TextEditingController();
    final durationController = TextEditingController();
    final colorNotifier = ValueNotifier<Color>(Colors.blue.shade600);
    final isInfiniteNotifier = ValueNotifier<bool>(false);

    showTimerDialog(
      context: context,
      titleController: titleController,
      durationController: durationController,
      colorNotifier: colorNotifier,
      isInfiniteNotifier: isInfiniteNotifier,
      onConfirm: () async {
        final title = titleController.text.trim();
        if (title.isEmpty) return;

        final isInfinite = isInfiniteNotifier.value;
        final duration =
            isInfinite ? 0 : (int.tryParse(durationController.text) ?? 0);

        if (!isInfinite && duration <= 0) return;

        final colorHex = colorNotifier.value.toARGB32();

        final timer = StudyTimerModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          durationMinutes: duration,
          createdAt: DateTime.now(),
          colorHex: colorHex,
          groupId: null,
          isInfinite: isInfinite,
          isFavorite: false,
        );
        await _timerBox.add(timer);
        setState(() {});
        if (mounted) {
          Navigator.pop(context);
        }
      },
      title: '새 타이머 추가',
      confirmText: '추가',
    );
  }

  Future<void> _showGoalDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const DailyGoalDialog(),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _showAddGroupDialog() async {
    final result = await showGroupManagementDialog(context);
    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupBox.values.toList();
    final ungroupedTimers =
        _timerBox.values.where((timer) => timer.groupId == null).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DailyGoalCard(onTap: _showGoalDialog),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: [
                    const SizedBox(height: 8),

                    // 빠른 시작 섹션
                    _buildQuickStartSection(),

                    const SizedBox(height: 16),

                    // 그룹 없는 타이머들 (기본 폴더)
                    if (ungroupedTimers.isNotEmpty)
                      _buildGroupCard(
                        title: '개인 타이머',
                        icon: Icons.timer_outlined,
                        color: Colors.grey.shade600,
                        timerCount: ungroupedTimers.length,
                        groupId: null,
                      ),

                    // 그룹 폴더들
                    ...groups.map((group) {
                      final groupTimers =
                          _timerBox.values
                              .where((timer) => timer.groupId == group.id)
                              .toList();
                      return _buildGroupCard(
                        title: group.name,
                        icon: Icons.folder,
                        color:
                            group.colorHex != null
                                ? Color(group.colorHex!)
                                : Colors.blue,
                        timerCount: groupTimers.length,
                        groupId: group.id,
                        group: group,
                      );
                    }),

                    // 새 그룹 추가 카드
                    _buildAddGroupCard(),

                    // 그룹이 없는 경우 안내
                    if (groups.isEmpty && ungroupedTimers.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.folder_outlined,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '타이머가 없습니다',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '+ 버튼을 눌러 새 타이머를 추가해보세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimerDialog,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }

  Widget _buildGroupCard({
    required String title,
    required IconData icon,
    required Color color,
    required int timerCount,
    required String? groupId,
    TimerGroupModel? group,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => GroupTimersScreen(
                      groupId: groupId,
                      groupName: title,
                      groupColor: color,
                    ),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$timerCount개의 타이머',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (group != null)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showEditGroupDialog(group);
                      } else if (value == 'delete') {
                        _showDeleteGroupDialog(group);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    color: const Color(0xFFF8F8F8), // 연한 회색 (거의 흰색)
                    surfaceTintColor: Colors.transparent,
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, size: 20),
                                SizedBox(width: 12),
                                Text('편집'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_rounded,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 12),
                                Text('삭제', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                    child: Icon(
                      Icons.more_vert,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddGroupCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        child: InkWell(
          onTap: _showAddGroupDialog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '새 그룹 추가',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '타이머를 분류해보세요',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStartSection() {
    // 모든 타이머 가져오기
    final allTimers = _timerBox.values.toList();
    if (allTimers.isEmpty) return const SizedBox.shrink();

    // 즐겨찾기된 타이머들만 표시
    final favoriteTimers =
        allTimers.where((timer) => timer.isFavorite).toList();

    // 즐겨찾기 타이머가 없으면 섹션을 숨김
    if (favoriteTimers.isEmpty) return const SizedBox.shrink();

    favoriteTimers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 즐겨찾기 타이머들만 표시
    final quickStartTimers = favoriteTimers;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '즐겨찾기',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              clipBehavior: Clip.none,
              itemCount: quickStartTimers.length,
              itemBuilder: (context, index) {
                final timer = quickStartTimers[index];
                return _buildQuickStartCard(timer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartCard(StudyTimerModel timer) {
    final color = Color(timer.colorHex ?? Colors.blue.shade600.toARGB32());

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () => _startTimer(timer),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        timer.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (timer.isFavorite)
                      Icon(Icons.star, size: 16, color: Colors.amber),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        timer.isInfinite == true
                            ? '무제한'
                            : '${timer.durationMinutes}분',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.play_arrow, size: 18, color: color),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startTimer(StudyTimerModel timer) async {
    if (timer.isInfinite == true) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InfiniteTimerRunScreen(timer: timer),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TimerRunScreen(timer: timer)),
      );
    }
    // 타이머 화면에서 돌아올 때 상태 새로고침 (즐겨찾기 변경사항 반영)
    setState(() {});
  }

  Future<void> _showEditGroupDialog(TimerGroupModel group) async {
    final nameController = TextEditingController(text: group.name);
    final colorNotifier = ValueNotifier<Color>(
      group.colorHex != null ? Color(group.colorHex!) : Colors.blue.shade500,
    );

    final colors = [
      Colors.red.shade500,
      Colors.orange.shade500,
      Colors.amber.shade500,
      Colors.green.shade500,
      Colors.blue.shade500,
      Colors.indigo.shade500,
      Colors.purple.shade500,
      Colors.pink.shade500,
      Colors.teal.shade500,
      Colors.cyan.shade500,
    ];

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '그룹 편집',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '그룹 이름',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '색상',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<Color>(
                    valueListenable: colorNotifier,
                    builder:
                        (context, selectedColor, _) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: selectedColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: selectedColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '선택된 색상',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 5,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1,
                                children:
                                    colors.map((color) {
                                      final isSelected = selectedColor == color;
                                      return ColorButtonWidget(
                                        color: color,
                                        isSelected: isSelected,
                                        onTap:
                                            () => colorNotifier.value = color,
                                      );
                                    }).toList(),
                              ),
                            ],
                          ),
                        ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.trim().isNotEmpty) {
                              Navigator.pop(context, true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('저장'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final updatedGroup = TimerGroupModel(
        id: group.id,
        name: nameController.text.trim(),
        colorHex: colorNotifier.value.toARGB32(),
        createdAt: group.createdAt,
        modifiedAt: DateTime.now(),
      );

      final index = _groupBox.values.toList().indexWhere(
        (g) => g.id == group.id,
      );
      if (index >= 0) {
        await _groupBox.putAt(index, updatedGroup);
        setState(() {});
      }
    }
  }

  Future<void> _showDeleteGroupDialog(TimerGroupModel group) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('그룹 삭제'),
            content: Text(
              '정말로 "${group.name}" 그룹을 삭제하시겠습니까?\n그룹에 속한 타이머들은 그룹 없음으로 이동됩니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
    );

    if (result == true) {
      // 그룹에 속한 타이머들의 groupId를 null로 변경
      final timersToUpdate =
          _timerBox.values.where((timer) => timer.groupId == group.id).toList();

      for (final timer in timersToUpdate) {
        final index = _timerBox.values.toList().indexOf(timer);
        final updatedTimer = StudyTimerModel(
          id: timer.id,
          title: timer.title,
          durationMinutes: timer.durationMinutes,
          createdAt: timer.createdAt,
          colorHex: timer.colorHex,
          groupId: null,
          isInfinite: timer.isInfinite,
          isFavorite: timer.isFavorite,
        );
        await _timerBox.putAt(index, updatedTimer);
      }

      // 그룹 삭제
      final index = _groupBox.values.toList().indexWhere(
        (g) => g.id == group.id,
      );
      if (index >= 0) {
        await _groupBox.deleteAt(index);
        setState(() {});
      }
    }
  }
}

// DailyGoalCard 위젯을 직접 정의
class DailyGoalCard extends StatefulWidget {
  final VoidCallback? onTap;

  const DailyGoalCard({super.key, this.onTap});

  @override
  State<DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends State<DailyGoalCard> {
  final DailyGoalService _goalService = DailyGoalService();

  @override
  Widget build(BuildContext context) {
    final progressInfo = _goalService.getTodayProgressInfo();

    if (!progressInfo.isGoalSet) {
      return _buildNoGoalCard();
    }

    return _buildProgressCard(progressInfo);
  }

  Widget _buildNoGoalCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? Theme.of(context).colorScheme.surface : Colors.blue.shade50;
    final iconColor = isDark ? Colors.blue.shade300 : const Color(0xFF87CEEB);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      color: backgroundColor,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient:
                isDark
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade700.withValues(alpha: 0.08),
                        Colors.blue.shade600.withValues(alpha: 0.04),
                      ],
                    )
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 32, color: iconColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 목표를 설정해보세요',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '목표 시간을 설정하고 성취감을 느껴보세요',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle_outline, color: iconColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(DailyProgressInfo info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lightBlue = isDark ? Colors.blue.shade300 : const Color(0xFF87CEEB);
    final isAchieved = info.isAchieved;
    final progressColor = isAchieved ? Colors.green : lightBlue;
    final backgroundColor =
        isDark ? Theme.of(context).colorScheme.surface : Colors.blue.shade50;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      color: backgroundColor,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient:
                isDark
                    ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade700.withValues(alpha: 0.08),
                        Colors.blue.shade600.withValues(alpha: 0.04),
                      ],
                    )
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAchieved ? Icons.emoji_events : Icons.flag,
                          color: progressColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '오늘의 목표',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (isAchieved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '달성!',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // 진행률 바
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: info.progress,
                        backgroundColor:
                            isDark ? Colors.grey[700] : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(info.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 시간 정보
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '완료: ${info.completedTimeString}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '목표: ${info.goalTimeString}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (!isAchieved && info.remainingMinutes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lightBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: lightBlue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${info.remainingTimeString} 남음',
                          style: TextStyle(
                            color:
                                isDark
                                    ? Colors.blue.shade200
                                    : Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
