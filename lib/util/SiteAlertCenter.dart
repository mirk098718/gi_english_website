import 'dart:async';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonFeedbackService.dart';
import 'package:gi_english_website/util/NotificationService.dart';
import 'package:gi_english_website/util/alert_chime_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 사이트 오른쪽 위 종: 예약·수업 시간·강사 피드백 알림을 실시간으로 모은다.
class SiteAlertCenter extends ChangeNotifier {
  SiteAlertCenter._();
  static final SiteAlertCenter instance = SiteAlertCenter._();

  StreamSubscription? _authSub;
  StreamSubscription? _noteSub;
  Timer? _poll;
  bool _started = false;
  bool _hydrated = false;
  bool _isStaff = false;
  final Set<String> _knownIds = {};
  final Set<String> _dismissedLocal = {};
  List<AppNotification> _server = [];
  List<AppNotification> _local = [];

  List<AppNotification> get unread {
    final seen = <String>{};
    final items = <AppNotification>[];
    for (final item in [..._local, ..._server]) {
      if (item.read || seen.contains(item.id)) continue;
      seen.add(item.id);
      items.add(item);
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  int get unreadCount => unread.length;
  bool get hasUnread => unread.isNotEmpty;

  void start() {
    if (_started) return;
    _started = true;
    _loadDismissed();
    _authSub = AuthService.authStateChanges.listen((_) => _bindUser());
    _bindUser();
  }

  Future<void> _loadDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dismissedLocal.addAll(prefs.getStringList('site_alert_dismissed') ?? []);
    } catch (_) {}
  }

  Future<void> _bindUser() async {
    await _noteSub?.cancel();
    _poll?.cancel();
    _server = [];
    _local = [];
    _knownIds.clear();
    _hydrated = false;
    _isStaff = false;
    notifyListeners();
    final viewerUid = await _viewerUid();
    if (viewerUid.isEmpty) return;
    _isStaff = await AuthService.isStaff();
    _noteSub = NotificationService.watchMine(userId: viewerUid)
        .listen(_onServer, onError: (_) {});
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refreshLocal());
    await _refreshLocal();
  }

  Future<String> _viewerUid() async {
    final member = AuthService.currentUser?.uid ?? '';
    if (member.isNotEmpty) return member;
    return AuthService.currentStaffUid();
  }

  void _onServer(List<AppNotification> items) {
    _server = items;
    _emit(playIfNew: true);
  }

  Future<void> _refreshLocal() async {
    final viewerUid = await _viewerUid();
    if (viewerUid.isEmpty) return;
    final bookings = _isStaff
        ? await EnrollmentService.staffWeekBookings(mineOnly: true)
        : await EnrollmentService.myAllWeekBookings();
    final due = EnrollmentService.dueLessonAlerts(bookings);
    final reminderKeys = _server
        .where((item) =>
            item.type == 'lesson_reminder' && item.bookingId.isNotEmpty)
        .map((item) => item.bookingId)
        .toSet();
    final next = <AppNotification>[];
    for (final booking in due) {
      final id = 'local_lesson_${booking.id}';
      if (_dismissedLocal.contains(id)) continue;
      if (reminderKeys.contains(booking.id)) continue;
      final when =
          '${EnrollmentService.formatBookingDate(booking.date)} ${EnrollmentService.formatBookingTime(booking.time)}';
      final student = booking.memberName.trim().isEmpty
          ? '수강생'
          : booking.memberName.trim();
      next.add(AppNotification(
        id: id,
        userId: viewerUid,
        title: '수업 시간 알림',
        body: _isStaff
            ? '곧 $student님 화상수업입니다. $when 호스트로 입장해 주세요.'
            : '곧 화상수업이 시작됩니다. $when 내 강의실에서 입장해 주세요.',
        type: 'lesson_reminder',
        bookingId: booking.id,
        createdAt: DateTime.now(),
      ));
    }
    next.addAll(await _localFeedbackAlerts(viewerUid));
    _local = next;
    _emit(playIfNew: true);
  }

  Future<List<AppNotification>> _localFeedbackAlerts(String viewerUid) async {
    if (_isStaff) return const [];
    final feedbacks = await LessonFeedbackService.listMineForAlerts(
      userId: viewerUid,
    );
    if (feedbacks == null) return const [];
    await _baselineExistingFeedback(viewerUid, feedbacks);
    final serverBookings = _server
        .where((item) =>
            item.type == 'lesson_feedback' && item.bookingId.isNotEmpty)
        .map((item) => item.bookingId)
        .toSet();
    final next = <AppNotification>[];
    for (final feedback in feedbacks) {
      if (!feedback.hasContent) continue;
      if (feedback.bookingId.isNotEmpty &&
          serverBookings.contains(feedback.bookingId)) {
        continue;
      }
      final id = _feedbackAlertId(feedback);
      if (_dismissedLocal.contains(id)) continue;
      final teacher = feedback.teacherName.trim().isEmpty
          ? '강사'
          : feedback.teacherName.trim();
      final week =
          feedback.weekNumber > 0 ? '${feedback.weekNumber}회차' : '화상수업';
      next.add(AppNotification(
        id: id,
        userId: viewerUid,
        title: '강사 피드백',
        body: '$teacher 선생님이 $week 피드백을 남겼습니다. 내 강의실에서 확인해 주세요.',
        type: 'lesson_feedback',
        bookingId: feedback.bookingId,
        createdAt: feedback.updatedAt ?? feedback.createdAt,
      ));
    }
    return next;
  }

  String _feedbackAlertId(LessonFeedback feedback) {
    final stamp =
        (feedback.updatedAt ?? feedback.createdAt).millisecondsSinceEpoch;
    return 'local_feedback_${feedback.id}_$stamp';
  }

  Future<void> _baselineExistingFeedback(
    String viewerUid,
    List<LessonFeedback> feedbacks,
  ) async {
    if (viewerUid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'site_alert_feedback_baselined_$viewerUid';
      if (prefs.getBool(key) == true) return;
      for (final feedback in feedbacks) {
        _dismissedLocal.add(_feedbackAlertId(feedback));
      }
      await prefs.setStringList(
          'site_alert_dismissed', _dismissedLocal.toList());
      await prefs.setBool(key, true);
    } catch (_) {}
  }

  void _emit({required bool playIfNew}) {
    final ids = unread.map((item) => item.id).toSet();
    final fresh = ids.difference(_knownIds);
    _knownIds.addAll(ids);
    if (_hydrated && playIfNew && fresh.isNotEmpty) {
      playAlertTone();
    }
    _hydrated = true;
    notifyListeners();
  }

  Future<void> dismiss(AppNotification item) async {
    if (item.id.startsWith('local_')) {
      _dismissedLocal.add(item.id);
      _local = _local.where((n) => n.id != item.id).toList();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
            'site_alert_dismissed', _dismissedLocal.toList());
      } catch (_) {}
    } else {
      await NotificationService.markRead(item.id);
      _server = _server
          .map((n) => n.id == item.id ? n.copyWith(read: true) : n)
          .toList();
    }
    _knownIds.remove(item.id);
    notifyListeners();
  }

  void unlockAudio() {
    if (!kIsWeb) return;
    try {
      final audio = html.AudioElement(kAlertChimeDataUri)..volume = 0.0;
      audio.play().then((_) {
        audio.pause();
        audio.currentTime = 0;
      }).catchError((_) {});
    } catch (_) {}
  }

  void playAlertTone() {
    if (!kIsWeb) return;
    try {
      html.AudioElement(kAlertChimeDataUri)
        ..volume = 0.45
        ..play().catchError((_) {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _noteSub?.cancel();
    _poll?.cancel();
    super.dispose();
  }
}
