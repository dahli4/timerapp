import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timerapp/main.dart';

void main() {
  group('Timer App Tests', () {
    testWidgets('App loads without crashing', (WidgetTester tester) async {
      // 앱이 정상적으로 로드되는지 테스트
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      // MaterialApp이 로드되는지 확인
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App has proper theme configuration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      // MaterialApp의 테마가 설정되어 있는지 확인
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
    });
  });
}
