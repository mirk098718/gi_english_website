import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PaymentService.dart';
import 'package:gi_english_website/util/PhoneUtil.dart';
import 'package:gi_english_website/widget/AdminContentWidth.dart';
import 'package:gi_english_website/widget/NotificationBellButton.dart';
import 'package:gi_english_website/widget/StudentLearningProgressPanel.dart';

/// 수강생 한 명의 가입·담당·수강·결제 정보를 모두 보여 준다.
class StudentDetailPage extends StatefulWidget {
  final Map<String, dynamic> member;
  final String teacherName;

  const StudentDetailPage({
    Key? key,
    required this.member,
    this.teacherName = '',
  }) : super(key: key);

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  late Map<String, dynamic> _member;
  List<EnrollmentRecord> _enrollments = [];
  Map<String, List<StudentWeekProgress>> _learning = {};
  List<PaymentOrder> _payments = [];
  String _teacherName = '';
  bool _loading = true;

  String get _uid => _member['uid']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _member = Map<String, dynamic>.from(widget.member);
    _teacherName = widget.teacherName;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = _uid;
    final fresh = uid.isEmpty ? null : await AuthService.getMember(uid);
    final teachers = await AuthService.listTeachers();
    final teacherNames = <String, String>{
      for (final teacher in teachers)
        if ((teacher['uid']?.toString() ?? '').isNotEmpty)
          teacher['uid'].toString(): teacher['name']?.toString() ?? '',
    };
    final enrollments = uid.isEmpty
        ? <EnrollmentRecord>[]
        : await EnrollmentService.listEnrollments(memberIds: [uid]);
    final learning = await EnrollmentService.learningByEnrollment(enrollments);
    final payments =
        uid.isEmpty ? <PaymentOrder>[] : await PaymentService.paymentsForUser(uid);
    if (!mounted) return;
    final member = fresh ?? _member;
    setState(() {
      _member = member;
      _teacherName = AuthService.memberTeacherName(member,
              teacherNames: teacherNames)
          .ifEmpty(_teacherName);
      _enrollments = enrollments;
      _learning = learning;
      _payments = payments;
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

  @override
  Widget build(BuildContext context) {
    final name = _member['name']?.toString().trim() ?? '';
    return Theme(
      data: Palette.adminTheme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: Palette.white,
        appBar: AppBar(
          title: Text(name.isEmpty ? '수강생 정보' : name,
              style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.navy,
          foregroundColor: Palette.white,
          actions: const [
            NotificationBellButton(light: true),
            SizedBox(width: 8),
          ],
        ),
        body: AdminContentWidth(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _profileCard(),
                    const SizedBox(height: 28),
                    _sectionTitle('수강 배정'),
                    const SizedBox(height: 8),
                    Text(
                      '배정된 과정, 남은 회차, 결제 여부를 한곳에서 보고 수정할 수 있습니다.',
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 13,
                          color: Palette.grey600),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: _showAssignDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text('수업 배정',
                            style: TextStyle(fontFamily: "NotoSansKR")),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Palette.darkTeal,
                          foregroundColor: Palette.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_enrollments.isEmpty)
                      Text('배정된 수업이 없습니다.',
                          style: TextStyle(
                              fontFamily: "NotoSansKR", color: Palette.grey500))
                    else
                      ..._enrollments.map(_enrollmentCard),
                    const SizedBox(height: 28),
                    _sectionTitle('결제 내역'),
                    const SizedBox(height: 8),
                    Text(
                      '토스페이먼츠로 결제한 주문과, 수강 카드에 직접 기록한 결제 정보를 함께 보여 줍니다.',
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 13,
                          color: Palette.grey600),
                    ),
                    const SizedBox(height: 12),
                    _paymentSummary(),
                    const SizedBox(height: 12),
                    if (_payments.isEmpty)
                      Text('토스 결제 주문이 없습니다.',
                          style: TextStyle(
                              fontFamily: "NotoSansKR", color: Palette.grey500))
                    else
                      ..._payments.map(_paymentTile),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: TextStyle(fontFamily: "Jalnan", fontSize: 16));
  }

  Widget _profileCard() {
    final name = _member['name']?.toString().trim() ?? '';
    final email = _member['email']?.toString().trim() ?? '';
    final phone = _member['phone']?.toString() ?? '';
    final joined = AuthService.memberCreatedAt(_member);
    final active = _member['isActive'] != false;
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name.isEmpty ? '이름 미등록 회원' : name,
              style: TextStyle(fontFamily: "Jalnan", fontSize: 18)),
          const SizedBox(height: 10),
          _infoRow('이메일', email.isEmpty ? '-' : email),
          _infoRow(
              '연락처',
              PhoneUtil.isValid(phone) ? PhoneUtil.display(phone) : (phone.isEmpty ? '-' : phone)),
          _infoRow('담당 강사', _teacherName.isEmpty ? '미배정' : _teacherName),
          _infoRow('가입일', _formatDateTime(joined, dateOnly: true)),
          _infoRow('상태', active ? '이용 중' : '비활성'),
          _infoRow(
              '수강',
              '배정 ${_enrollments.length}건 · 결제완료 ${_enrollments.where((e) => e.isPaid).length}건'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label,
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _paymentSummary() {
    final paid = _payments.where((p) => p.status == 'paid').toList();
    final recorded = _enrollments.where((e) => e.isPaid && e.paidAmount > 0);
    final tossSum = paid.fold<int>(0, (sum, p) => sum + p.amount);
    final recordedSum = recorded.fold<int>(0, (sum, e) => sum + e.paidAmount);
    return Text(
      '토스 결제완료 ${paid.length}건 ${_formatWon(tossSum)} · 수강 카드 기록 ${_formatWon(recordedSum)}',
      style: TextStyle(
          fontFamily: "NotoSansKR",
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Palette.secondaryDark),
    );
  }

  Widget _enrollmentCard(EnrollmentRecord record) {
    final course = record.course;
    final title =
        course == null ? record.courseId : '${course.order}. ${course.title}';
    final sessionsConfigured = record.totalSessions > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: record.isActive ? Palette.white : Palette.grey100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontFamily: "NotoSansKR", fontWeight: FontWeight.bold)),
              ),
              if (!record.isActive)
                Text('배정 취소됨',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.danger)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sessionsConfigured
                ? '진행 ${record.completedSessions}회 / 전체 ${record.totalSessions}회 · 남은 ${record.remainingSessions}회'
                : '수업 횟수 미설정',
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                color:
                    sessionsConfigured ? Palette.secondaryDark : Palette.danger,
                fontWeight: FontWeight.bold),
          ),
          if (record.nativeTeacherLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('수업 강사 ${record.nativeTeacherLabel}',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey600)),
          ],
          if (record.lastSessionAt != null) ...[
            const SizedBox(height: 4),
            Text('최근 수업 처리: ${_formatDateTime(record.lastSessionAt)}',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey500)),
          ],
          const SizedBox(height: 4),
          Text(
            record.isPaid
                ? '결제 완료${record.paidAmount > 0 ? ' · ${_formatWon(record.paidAmount)}' : ''}'
                    '${record.paymentNote.isNotEmpty ? ' · ${record.paymentNote}' : ''}'
                : '미결제',
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: record.isPaid ? Palette.success : Palette.danger),
          ),
          if (record.paidAt != null) ...[
            const SizedBox(height: 2),
            Text('결제일 ${_formatDateTime(record.paidAt)}',
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey500)),
          ],
          const SizedBox(height: 12),
          StudentLearningProgressPanel(
            enrollments: [record],
            progressByEnrollment: _learning,
            dense: true,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showPaymentDialog(record),
                icon: const Icon(Icons.payments_outlined, size: 16),
                label: Text('결제 정보',
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
              ),
              OutlinedButton(
                onPressed: () => _showEditDialog(record),
                child: Text('배정 변경',
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12)),
              ),
              TextButton(
                onPressed: () => _cancelEnrollment(record),
                child: Text(record.isActive ? '배정 취소' : '배정 복구',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: record.isActive
                            ? Palette.danger
                            : Palette.secondaryDark)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentTile(PaymentOrder payment) {
    final color = payment.status == 'paid'
        ? Palette.success
        : (payment.status == 'failed' ? Palette.danger : Palette.grey600);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          payment.courseTitle.isEmpty ? payment.orderId : payment.courseTitle,
          style: TextStyle(
              fontFamily: "NotoSansKR",
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
        subtitle: Text(
          '${payment.amountLabel} · 화상 ${payment.totalSessions}회 · ${payment.statusLabel}\n'
          '주문 ${payment.orderId}\n'
          '생성 ${_formatDateTime(payment.createdAt)}'
          '${payment.paidAt != null ? ' · 결제 ${_formatDateTime(payment.paidAt)}' : ''}'
          '${payment.nativeTeacherName.isNotEmpty ? '\n강사 ${payment.nativeTeacherName}' : ''}'
          '${payment.method != null && payment.method!.isNotEmpty ? '\n수단 ${payment.method}' : ''}',
          style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              height: 1.45,
              color: Palette.grey600),
        ),
        isThreeLine: true,
        trailing: Text(payment.statusLabel,
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
      ),
    );
  }

  Future<void> _showAssignDialog() async {
    final email = _member['email']?.toString().trim() ?? '';
    if (email.isEmpty) {
      _toast('이메일 없는 회원은 수동 배정할 수 없습니다.', error: true);
      return;
    }
    OnlineCourse selectedCourse = OnlineCourse.all.first;
    final sessionsController = TextEditingController(text: '8');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('수업 배정', style: TextStyle(fontFamily: "Jalnan")),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<OnlineCourse>(
                  initialValue: selectedCourse,
                  decoration: const InputDecoration(
                      labelText: '과정', border: OutlineInputBorder()),
                  items: OnlineCourse.all
                      .map((course) => DropdownMenuItem(
                            value: course,
                            child: Text(course.title,
                                style: TextStyle(fontFamily: "NotoSansKR")),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCourse = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: sessionsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '전체 화상수업 횟수',
                    suffixText: '회',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('닫기')),
            ElevatedButton(
              onPressed: () async {
                final total = int.tryParse(sessionsController.text.trim()) ?? 0;
                final error = await EnrollmentService.assignCourseByEmail(
                  email: email,
                  courseId: selectedCourse.id,
                  totalSessions: total,
                );
                if (!mounted) return;
                if (error != null) {
                  _toast(error, error: true);
                  return;
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text('배정하기'),
            ),
          ],
        ),
      ),
    );
    sessionsController.dispose();
    if (saved == true) {
      _toast('수업이 배정되었습니다.');
      await _load();
    }
  }

  Future<void> _showEditDialog(EnrollmentRecord record) async {
    OnlineCourse selectedCourse = record.course ?? OnlineCourse.all.first;
    final sessionsController = TextEditingController(
        text: record.totalSessions > 0 ? '${record.totalSessions}' : '8');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('배정 변경', style: TextStyle(fontFamily: "Jalnan")),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<OnlineCourse>(
                  initialValue: selectedCourse,
                  decoration: const InputDecoration(
                      labelText: '과정', border: OutlineInputBorder()),
                  items: OnlineCourse.all
                      .map((course) => DropdownMenuItem(
                            value: course,
                            child: Text(course.title,
                                style: TextStyle(fontFamily: "NotoSansKR")),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCourse = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: sessionsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '전체 화상수업 횟수',
                    suffixText: '회',
                    helperText: selectedCourse.id == record.courseId
                        ? '같은 과정이면 현재 진행 횟수를 유지합니다.'
                        : '과정을 변경하면 진행 횟수가 0회로 초기화됩니다.',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('닫기')),
            ElevatedButton(
              onPressed: () async {
                final total = int.tryParse(sessionsController.text.trim()) ?? 0;
                final error = await EnrollmentService.updateEnrollment(
                  enrollmentId: record.id,
                  userId: record.userId,
                  currentCourseId: record.courseId,
                  courseId: selectedCourse.id,
                  totalSessions: total,
                );
                if (!mounted) return;
                if (error != null) {
                  _toast(error, error: true);
                  return;
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text('변경 저장'),
            ),
          ],
        ),
      ),
    );
    sessionsController.dispose();
    if (saved == true) {
      _toast('배정 정보가 변경되었습니다.');
      await _load();
    }
  }

  Future<void> _showPaymentDialog(EnrollmentRecord record) async {
    var isPaid = record.isPaid;
    final amountController = TextEditingController(
        text: record.paidAmount > 0 ? '${record.paidAmount}' : '');
    final noteController = TextEditingController(text: record.paymentNote);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('결제 정보', style: TextStyle(fontFamily: "Jalnan")),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title:
                      Text('결제 완료', style: TextStyle(fontFamily: "NotoSansKR")),
                  value: isPaid,
                  onChanged: (value) => setDialogState(() => isPaid = value),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '결제 금액',
                    suffixText: '원',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '메모 (예: 계좌이체 / 카드)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('닫기')),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text.trim()) ?? 0;
                final error = await EnrollmentService.updatePaymentInfo(
                  enrollmentId: record.id,
                  isPaid: isPaid,
                  paidAmount: amount,
                  paymentNote: noteController.text.trim(),
                );
                if (!mounted) return;
                if (error != null) {
                  _toast(error, error: true);
                  return;
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
    noteController.dispose();
    if (saved == true) {
      _toast('결제 정보가 저장되었습니다.');
      await _load();
    }
  }

  Future<void> _cancelEnrollment(EnrollmentRecord record) async {
    if (record.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('배정 취소'),
          content: Text('이 수업을 회원의 내 강의실에서 숨길까요? 진행 횟수 기록은 보존됩니다.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('아니요')),
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text('배정 취소', style: TextStyle(color: Palette.danger))),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final error = await EnrollmentService.setEnrollmentActive(
        record.id, !record.isActive);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast(record.isActive ? '배정이 취소되었습니다.' : '배정이 복구되었습니다.');
    await _load();
  }

  String _formatDateTime(DateTime? dt, {bool dateOnly = false}) {
    if (dt == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${dt.year}.${two(dt.month)}.${two(dt.day)}';
    if (dateOnly) return date;
    return '$date ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatWon(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}원';
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
