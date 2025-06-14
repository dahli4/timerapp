import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../utils/permission_helper.dart';
import '../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '집중 타이머로\n생산성을 높여보세요',
      description: '공부, 업무, 운동 등\n다양한 활동의 시간을 측정하고\n체계적으로 관리할 수 있어요',
      icon: Icons.timer_outlined,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: '다양한 색상으로\n타이머를 구분하세요',
      description: '과목별, 활동별로 색상을 지정해\n쉽게 구분하고 관리할 수 있어요',
      icon: Icons.palette_outlined,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: '통계로 확인하는\n나의 성장',
      description: '일별, 주별 활동 기록을 확인하고\n달력에서 나의 성취를 확인해보세요',
      icon: Icons.analytics_outlined,
      color: Colors.green,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    // 알림 권한 요청
    final hasPermission =
        await PermissionHelper.requestNotificationPermission();

    if (!hasPermission) {
      // 권한이 거부되었을 때 다이얼로그 표시
      _showPermissionDialog();
      return;
    }

    // 온보딩 완료 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // 메인 앱으로 이동
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const StudyTimerApp()),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('알림 권한 필요'),
            content: const Text(
              '타이머 완료 시 알림을 받으려면 알림 권한이 필요합니다.\n설정에서 알림을 허용해주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _proceedWithoutPermission();
                },
                child: const Text('나중에'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  PermissionHelper.openAppSettings();
                  _proceedWithoutPermission();
                },
                child: const Text('설정으로 이동'),
              ),
            ],
          ),
    );
  }

  void _proceedWithoutPermission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const StudyTimerApp()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip 버튼
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    '건너뛰기',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // 페이지 컨텐츠
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 아이콘
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 60, color: page.color),
                        ),
                        const SizedBox(height: 48),

                        // 제목
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 설명
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 하단 영역
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // 페이지 인디케이터
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Theme.of(context).colorScheme.primary,
                      dotColor: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 다음/시작 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
