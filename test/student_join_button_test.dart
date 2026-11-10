import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/widget/StudentJoinButton.dart';

OnlineSession _session({
  bool isLive = false,
  String meetingUrl = 'https://meet.jit.si/room',
  DateTime? startedAt,
  DateTime? endedAt,
}) {
  return OnlineSession(
    id: 's1',
    courseId: 'c1',
    title: '1회차 화상수업',
    order: 1,
    meetingUrl: meetingUrl,
    isLive: isLive,
    bookingId: 'b1',
    startedAt: startedAt,
    endedAt: endedAt,
  );
}

void main() {
  group('OnlineSession student join', () {
    test('confirmed session stays closed until the teacher starts', () {
      final waiting = _session();
      expect(waiting.canStudentJoin, isFalse);
      expect(waiting.isWaitingForStart, isTrue);
    });

    test('opens only while the class is live', () {
      final live = _session(isLive: true, startedAt: DateTime.now());
      expect(live.canStudentJoin, isTrue);
      expect(live.isWaitingForStart, isFalse);
    });

    test('closes again after three hours', () {
      final stale = _session(
        isLive: true,
        startedAt: DateTime.now().subtract(
          const Duration(hours: 3, minutes: 1),
        ),
      );
      expect(stale.isStale, isTrue);
      expect(stale.canStudentJoin, isFalse);
      expect(stale.isWaitingForStart, isFalse);
    });

    test('stays closed after the teacher ends the class', () {
      final ended = _session(endedAt: DateTime.now());
      expect(ended.isFinished, isTrue);
      expect(ended.canStudentJoin, isFalse);
      expect(ended.isWaitingForStart, isFalse);
    });

    test('stays closed without a meeting url', () {
      final missing = _session(meetingUrl: '  ');
      expect(missing.canStudentJoin, isFalse);
      expect(missing.isWaitingForStart, isFalse);
    });
  });

  testWidgets('join button is gray and cannot be pressed before start',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StudentJoinButton(
          enabled: false,
          label: '입장하기',
          onPressed: () => taps++,
        ),
      ),
    ));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(
      button.style?.backgroundColor?.resolve({WidgetState.disabled}),
      Palette.grey300,
    );
    expect(
      button.style?.foregroundColor?.resolve({WidgetState.disabled}),
      Palette.grey600,
    );
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
    expect(find.text('입장하기'), findsOneWidget);
  });

  testWidgets('join button turns green after the teacher starts',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StudentJoinButton(
          enabled: true,
          label: '입장하기',
          onPressed: () => taps++,
        ),
      ),
    ));

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
    expect(button.style?.backgroundColor?.resolve({}), Palette.success);
    expect(button.style?.foregroundColor?.resolve({}), Palette.white);
    await tester.tap(find.text('입장하기'));
    await tester.pump();
    expect(taps, 1);
  });
}
