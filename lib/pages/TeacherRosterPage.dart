import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonFeedbackService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PhoneUtil.dart';

/// 강사 프로필 · 담당 회원 · 화상수업 이력 · 피드백.
class TeacherRosterPage extends StatelessWidget {
  final Map<String, dynamic>? teacher;
  final bool embedded;

  const TeacherRosterPage({
    Key? key,
    this.teacher,
    this.embedded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final body = TeacherRosterView(teacher: teacher);
    if (embedded) return body;
    return Scaffold(
      backgroundColor: Palette.white,
      appBar: AppBar(
        title: Text('강사 프로필 · 담당 회원',
            style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: Palette.secondaryDark,
        foregroundColor: Palette.white,
      ),
      body: body,
    );
  }
}

class TeacherRosterView extends StatefulWidget {
  final Map<String, dynamic>? teacher;

  const TeacherRosterView({Key? key, this.teacher}) : super(key: key);

  @override
  State<TeacherRosterView> createState() => _TeacherRosterViewState();
}

class _TeacherRosterViewState extends State<TeacherRosterView> {
  Map<String, dynamic>? _teacher;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _guestMembers = [];
  List<WeekBooking> _bookings = [];
  List<LessonFeedback> _feedbacks = [];
  bool _loading = true;
  String _staffUid = '';
  bool _isOwner = false;
  String _writerName = '';

  String get _teacherUid => _teacher?['uid']?.toString() ?? '';

  bool get _canWrite =>
      _isOwner || (_staffUid.isNotEmpty && _staffUid == _teacherUid);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isOwner = await AuthService.isAdmin();
    final staffUid = await AuthService.currentStaffUid();
    final writerName = await AuthService.getAdminName();
    Map<String, dynamic>? teacher = widget.teacher;
    if (teacher == null || (teacher['uid']?.toString() ?? '').isEmpty) {
      teacher = await AuthService.currentStaffProfile();
    }
    final teacherUid = teacher?['uid']?.toString() ?? '';
    final members = teacherUid.isEmpty
        ? <Map<String, dynamic>>[]
        : await AuthService.listMembers(teacherId: teacherUid);
    final bookings = await EnrollmentService.weekBookingsForTeacher(teacherUid);
    final byId = <String, Map<String, dynamic>>{};
    for (final member in members) {
      final id = member['uid']?.toString() ?? '';
      if (id.isNotEmpty) byId[id] = member;
    }
    final myIds = byId.keys.toSet();
    final guestById = <String, Map<String, dynamic>>{};
    for (final booking in bookings) {
      if (booking.userId.isEmpty || myIds.contains(booking.userId)) continue;
      guestById.putIfAbsent(booking.userId, () {
        return {
          'uid': booking.userId,
          'name': booking.memberName,
          'email': booking.email,
          'assignedTeacherName': booking.assignedTeacherName,
        };
      });
    }
    final mergedMembers = byId.values.toList();
    mergedMembers.sort((a, b) {
      final aName = a['name']?.toString() ?? '';
      final bName = b['name']?.toString() ?? '';
      return aName.compareTo(bName);
    });
    final guestMembers = guestById.values.toList();
    guestMembers.sort((a, b) {
      final aName = a['name']?.toString() ?? '';
      final bName = b['name']?.toString() ?? '';
      return aName.compareTo(bName);
    });
    final feedbacks = await LessonFeedbackService.listForTeacher(teacherUid);
    if (!mounted) return;
    setState(() {
      _teacher = teacher;
      _members = mergedMembers;
      _guestMembers = guestMembers;
      _bookings = bookings;
      _feedbacks = feedbacks;
      _staffUid = staffUid;
      _isOwner = isOwner;
      _writerName = writerName;
      _loading = false;
    });
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  List<WeekBooking> _bookingsFor(String memberId) {
    return _bookings.where((b) => b.userId == memberId).toList();
  }

  Future<void> _openFeedback(WeekBooking booking) async {
    final existing =
        LessonFeedbackService.forBooking(_feedbacks, booking.id);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FeedbackDialog(
        booking: booking,
        existing: existing,
        canWrite: _canWrite,
        onSave: (content) async {
          return LessonFeedbackService.save(
            booking: booking,
            content: content,
            teacherId: _teacherUid,
            teacherName: (_teacher?['name']?.toString() ?? '').trim().isNotEmpty
                ? _teacher!['name'].toString()
                : _writerName,
          );
        },
      ),
    );
    if (saved == true) {
      _toast('피드백을 저장했습니다.');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_teacherUid.isEmpty) {
      return Center(
        child: Text('강사 정보를 찾을 수 없습니다.',
            style: TextStyle(fontFamily: "NotoSansKR")),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _profileCard(),
          SizedBox(height: 24),
          Text('내 수강생', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          SizedBox(height: 8),
          Text(
            '담당으로 배정된 회원의 화상수업 이력과 주차별 피드백을 확인하고, ${_canWrite ? '피드백을 작성할 수 있습니다.' : '피드백을 확인할 수 있습니다.'}',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          SizedBox(height: 16),
          if (_members.isEmpty)
            Text('아직 배정된 회원이 없습니다.',
                style: TextStyle(
                    fontFamily: "NotoSansKR", color: Palette.grey500))
          else
            ..._members.map(_memberCard),
          SizedBox(height: 28),
          Text('타 수강생', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          SizedBox(height: 8),
          Text(
            '다른 강사 담당이지만 내 스케줄로 예약한 수강생입니다. 컨펌하면 수업 횟수에 포함됩니다.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          SizedBox(height: 16),
          if (_guestMembers.isEmpty)
            Text('아직 타 수강생 수업이 없습니다.',
                style: TextStyle(
                    fontFamily: "NotoSansKR", color: Palette.grey500))
          else
            ..._guestMembers.map((member) => _memberCard(member, guest: true)),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _profileCard() {
    final teacher = _teacher ?? {};
    final name = teacher['name']?.toString() ?? '';
    final email = teacher['email']?.toString() ?? '';
    final nationality = teacher['nationality']?.toString() ?? '';
    final intro = teacher['intro']?.toString() ?? '';
    final photoUrl = teacher['photoUrl']?.toString() ?? '';
    final phone = teacher['phone']?.toString() ?? '';
    final isOwnerTeacher = teacher['role']?.toString() != 'teacher';
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _photo(photoUrl, 88),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwnerTeacher ? '$name (메인 관리자 · 강사)' : name,
                      style: TextStyle(fontFamily: "Jalnan", fontSize: 18),
                    ),
                    if (email.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Text(email,
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 13,
                              color: Palette.grey600)),
                    ],
                    if (PhoneUtil.isValid(phone)) ...[
                      SizedBox(height: 6),
                      Text(PhoneUtil.display(phone),
                          style: TextStyle(
                              fontFamily: "NotoSansKR",
                              fontSize: 13,
                              color: Palette.grey600)),
                    ],
                    if (nationality.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Palette.grey200),
                        ),
                        child: Text(nationality,
                            style: TextStyle(
                                fontFamily: "NotoSansKR",
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            intro.trim().isEmpty ? '소개가 아직 없습니다.' : intro,
            style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 14,
              height: 1.5,
              color: Palette.grey700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '내 수강생 ${_members.length}명 · 타 수강생 ${_guestMembers.length}명 · 화상수업 ${_bookings.length}건',
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 12,
                color: Palette.grey500),
          ),
        ],
      ),
    );
  }

  Widget _photo(String url, double size) {
    final provider = OnlineNativeTeacher.imageProviderOf(url);
    if (provider == null) {
      return Container(
        width: size,
        height: size,
        color: Palette.grey200,
        child: Icon(Icons.person, color: Palette.grey400),
      );
    }
    return Image(
      image: provider,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  Widget _memberCard(Map<String, dynamic> member, {bool guest = false}) {
    final memberId = member['uid']?.toString() ?? '';
    final name = member['name']?.toString() ?? '';
    final email = member['email']?.toString() ?? '';
    final assignedTeacherName = member['assignedTeacherName']?.toString() ?? '';
    final lessons = _bookingsFor(memberId);
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: guest
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Palette.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '타',
                    style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Palette.accent,
                    ),
                  ),
                )
              : null,
          title: Text(
            name.isEmpty ? email : name,
            style: TextStyle(fontFamily: "NotoSansKR", fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              if (email.isNotEmpty) email,
              if (guest && assignedTeacherName.isNotEmpty)
                '담당 $assignedTeacherName',
              '화상수업 ${lessons.length}건',
            ].join(' · '),
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 12, color: Palette.grey600),
          ),
          children: [
            if (lessons.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '아직 화상수업 이력이 없습니다.',
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 13,
                      color: Palette.grey500),
                ),
              )
            else
              ...lessons.map((booking) => _lessonRow(booking)),
          ],
        ),
      ),
    );
  }

  Widget _lessonRow(WeekBooking booking) {
    final feedback = LessonFeedbackService.forBooking(_feedbacks, booking.id);
    final written = feedback != null && feedback.hasContent;
    final course = OnlineCourse.findById(booking.courseId);
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              if (booking.weekNumber > 0) '${booking.weekNumber}주차',
              if (course != null) course.title,
            ].join(' · '),
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            '${EnrollmentService.formatBookingDate(booking.date)} ${EnrollmentService.formatBookingTime(booking.time)} · ${booking.statusLabel}',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 12, color: Palette.grey600),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: written
                      ? Palette.secondary.withValues(alpha: 0.12)
                      : Palette.grey200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  written ? '피드백 작성됨' : '피드백 미작성',
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 11,
                    color: written ? Palette.secondaryDark : Palette.grey600,
                  ),
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () => _openFeedback(booking),
                child: Text(
                  written
                      ? (_canWrite ? '피드백 확인 · 수정' : '피드백 확인')
                      : (_canWrite ? '피드백 작성' : '확인'),
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.secondaryDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  final WeekBooking booking;
  final LessonFeedback? existing;
  final bool canWrite;
  final Future<String?> Function(String content) onSave;

  const _FeedbackDialog({
    required this.booking,
    required this.existing,
    required this.canWrite,
    required this.onSave,
  });

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.content ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final error = await widget.onSave(_controller.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final course = OnlineCourse.findById(booking.courseId);
    return AlertDialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      title: Text('주차별 피드백', style: TextStyle(fontFamily: "Jalnan")),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (booking.memberName.isNotEmpty) booking.memberName,
                  if (course != null) course.title,
                  if (booking.weekNumber > 0) '${booking.weekNumber}주차',
                ].join(' · '),
                style: TextStyle(
                    fontFamily: "NotoSansKR", fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                '${EnrollmentService.formatBookingDate(booking.date)} ${EnrollmentService.formatBookingTime(booking.time)}',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey600),
              ),
              SizedBox(height: 16),
              if (widget.canWrite)
                TextField(
                  controller: _controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: '수업 피드백',
                    alignLabelWithHint: true,
                    hintText: '오늘 수업에서 잘한 점, 고칠 점, 다음 주 과제를 적어 주세요.',
                    border: OutlineInputBorder(),
                  ),
                )
              else
                Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Palette.grey50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Palette.grey200),
                  ),
                  child: Text(
                    (widget.existing?.content ?? '').trim().isEmpty
                        ? '아직 작성된 피드백이 없습니다.'
                        : widget.existing!.content,
                    style: TextStyle(
                        fontFamily: "NotoSansKR", fontSize: 14, height: 1.55),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text('닫기'),
        ),
        if (widget.canWrite)
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('저장'),
          ),
      ],
    );
  }
}
