import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/widget/StudentLearningProgressPanel.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguage.instance.code = 'ko';
  });

  tearDown(() {
    AppLanguage.instance.code = 'ko';
  });

  test('수강완료는 영어로 Completed', () {
    AppLanguage.instance.code = 'en';
    expect(AppLanguage.instance.translate('수강완료'), 'Completed');
  });

  testWidgets('끝난 회차는 수강완료로 한 줄이고, 누르면 내용이 열린다', (tester) async {
    final enrollment = EnrollmentRecord(
      id: 'enr-1',
      userId: 'student-1',
      email: 'student@example.com',
      memberName: '수강생',
      courseId: 'not-a-catalog-course',
      isActive: true,
      totalSessions: 8,
      completedSessions: 1,
      remainingSessions: 7,
    );
    final weeks = [
      StudentWeekProgress(
        weekId: 'w1',
        weekNumber: 1,
        weekTitle: '1강',
        videoUrl: 'https://example.com/lesson-1',
        problemLinks: const [
          WeekProblemLink(title: '1강 연습문제', url: ''),
        ],
        videoChecked: true,
        problemsChecked: true,
        readyToBook: false,
      ),
      StudentWeekProgress(
        weekId: 'w2',
        weekNumber: 2,
        weekTitle: '2강',
        videoUrl: 'https://example.com/lesson-2',
        problemLinks: const [
          WeekProblemLink(title: '2강 연습문제', url: ''),
        ],
        videoChecked: true,
        problemsChecked: true,
        readyToBook: true,
      ),
      StudentWeekProgress(
        weekId: 'w3',
        weekNumber: 3,
        weekTitle: '3강',
        videoUrl: 'https://example.com/lesson-3',
        problemLinks: const [
          WeekProblemLink(title: '3강 연습문제', url: ''),
        ],
        videoChecked: false,
        problemsChecked: false,
        readyToBook: false,
      ),
    ];

    await tester.pumpWidget(
      LangScope(
        child: MaterialApp(
          home: Scaffold(
            body: StudentLearningProgressPanel(
              enrollments: [enrollment],
              progressByEnrollment: {'enr-1': weeks},
              dense: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1회차 · 1강 · 수강완료'), findsOneWidget);
    expect(find.text('2회차 · 2강 · 수강완료'), findsOneWidget);
    expect(find.text('3회차 · 3강'), findsOneWidget);
    expect(find.text('예약 가능'), findsNothing);
    expect(find.text('인강 · 1강'), findsNothing);
    expect(find.text('인강 · 3강'), findsNothing);

    await tester.tap(find.text('3회차 · 3강'));
    await tester.pumpAndSettle();

    expect(find.text('인강 · 3강'), findsOneWidget);
    expect(find.text('인강 · 1강'), findsNothing);
    expect(find.text('1회차 · 1강 · 수강완료'), findsOneWidget);
  });
}
