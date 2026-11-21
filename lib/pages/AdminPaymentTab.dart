import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/pages/StudentDetailPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/LessonRatingService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PaymentService.dart';
import 'package:gi_english_website/util/TeacherPayroll.dart';

/// 메인 관리자용 결제 내역 + 월별 수강생·강사 정산.
class AdminPaymentTab extends StatefulWidget {
  @override
  _AdminPaymentTabState createState() => _AdminPaymentTabState();
}

class _AdminPaymentTabState extends State<AdminPaymentTab> {
  List<PaymentOrder> _payments = [];
  List<EnrollmentRecord> _enrollments = [];
  List<Map<String, dynamic>> _teachers = [];
  List<WeekBooking> _bookings = [];
  List<LessonRating> _ratings = [];
  Map<String, TeacherSettlement> _settlements = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await AuthService.backfillPaidTeacherIds();
    final payments = await PaymentService.listPayments(limit: 2000);
    final enrollments = await EnrollmentService.listEnrollments();
    final teachers = await AuthService.listTeachers();
    final bookings = await EnrollmentService.staffWeekBookings(mineOnly: false);
    final ratings = await LessonRatingService.listAll();
    final settlements = await AuthService.listLessonSettlements();
    if (!mounted) return;
    setState(() {
      _payments = payments;
      _enrollments = enrollments;
      _teachers = teachers;
      _bookings = bookings;
      _ratings = ratings;
      _settlements = settlements;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Palette.white,
            child: TabBar(
              isScrollable: true,
              indicatorColor: Palette.navy,
              labelColor: Palette.navy,
              unselectedLabelColor: Palette.grey500,
              labelStyle: TextStyle(
                  fontFamily: "NotoSansKR", fontWeight: FontWeight.bold),
              tabs:  [
                Tab(text: tr(context, '수강생 정산')),
                Tab(text: tr(context, '이번 달 수업 수당')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _StudentSettlementPane(
                  payments: _payments,
                  enrollments: _enrollments,
                  loading: _loading,
                  onRefresh: _refresh,
                ),
                _TeacherPayrollPane(
                  teachers: _teachers,
                  bookings: _bookings,
                  ratings: _ratings,
                  settlements: _settlements,
                  loading: _loading,
                  onRefresh: _refresh,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentPaymentItem {
  final String userId;
  final String name;
  final String email;
  final String courseTitle;
  final int amount;
  final String source;
  final String teacherName;
  final DateTime? at;
  final Map<String, dynamic> member;

  const _StudentPaymentItem({
    required this.userId,
    required this.name,
    required this.email,
    required this.courseTitle,
    required this.amount,
    required this.source,
    required this.teacherName,
    required this.at,
    required this.member,
  });
}

class _StudentSettlementPane extends StatefulWidget {
  final List<PaymentOrder> payments;
  final List<EnrollmentRecord> enrollments;
  final bool loading;
  final Future<void> Function() onRefresh;

  const _StudentSettlementPane({
    required this.payments,
    required this.enrollments,
    required this.loading,
    required this.onRefresh,
  });

  @override
  State<_StudentSettlementPane> createState() => _StudentSettlementPaneState();
}

class _StudentSettlementPaneState extends State<_StudentSettlementPane> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool _inMonth(DateTime? dt) {
    return dt != null && dt.year == _month.year && dt.month == _month.month;
  }

  List<_StudentPaymentItem> get _monthItems {
    final items = <_StudentPaymentItem>[];
    final seen = <String>{};

    for (final payment in widget.payments) {
      if (payment.status != 'paid') continue;
      final at = payment.paidAt ?? payment.createdAt;
      if (!_inMonth(at)) continue;
      final key =
          '${payment.userId}|${payment.courseId}|${payment.amount}|${at?.year}-${at?.month}';
      seen.add(key);
      items.add(_StudentPaymentItem(
        userId: payment.userId,
        name: payment.memberName,
        email: payment.email,
        courseTitle: payment.courseTitle,
        amount: payment.amount,
        source: tr(context, '토스'),
        teacherName: payment.nativeTeacherName,
        at: at,
        member: {
          'uid': payment.userId,
          'name': payment.memberName,
          'email': payment.email,
          'nativeTeacherName': payment.nativeTeacherName,
        },
      ));
    }

    for (final record in widget.enrollments) {
      if (!record.isPaid || record.paidAmount <= 0) continue;
      final at = record.paidAt ?? record.createdAt;
      if (!_inMonth(at)) continue;
      final key =
          '${record.userId}|${record.courseId}|${record.paidAmount}|${at?.year}-${at?.month}';
      if (seen.contains(key)) continue;
      items.add(_StudentPaymentItem(
        userId: record.userId,
        name: record.memberName,
        email: record.email,
        courseTitle: record.course?.title ?? record.courseId,
        amount: record.paidAmount,
        source: record.paymentNote.isEmpty ? tr(context, '수강카드'): record.paymentNote,
        teacherName: record.nativeTeacherLabel,
        at: at,
        member: {
          'uid': record.userId,
          'name': record.memberName,
          'email': record.email,
          'nativeTeacherName': record.nativeTeacherName,
        },
      ));
    }

    items.sort((a, b) {
      final at = a.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });
    return items;
  }

  Set<String> get _openTossKeys {
    return widget.payments
        .where((p) => p.status == 'pending' || p.status == 'authorized')
        .map((p) => '${p.userId}|${p.courseId}')
        .toSet();
  }

  List<EnrollmentRecord> get _unpaidOnly {
    final open = _openTossKeys;
    return widget.enrollments.where((record) {
      if (!record.isActive || record.isPaid) return false;
      return !open.contains('${record.userId}|${record.courseId}');
    }).toList();
  }

  List<PaymentOrder> get _actionPayments {
    return widget.payments
        .where((p) => p.status == 'pending' || p.status == 'authorized')
        .toList();
  }

  List<PaymentOrder> get _monthPayments {
    final items = widget.payments.where((p) {
      if (p.status == 'pending' || p.status == 'authorized') return false;
      return _inMonth(p.paidAt ?? p.createdAt);
    }).toList();
    items.sort((a, b) {
      final at = a.paidAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.paidAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _monthItems;
    final unpaidOnly = _unpaidOnly;
    final actionPayments = _actionPayments;
    final monthPayments = _monthPayments;
    final monthPaid = monthPayments.where((p) => p.status == 'paid').toList();
    final monthPaidSum = monthPaid.fold<int>(0, (sum, p) => sum + p.amount);
    final openCount = actionPayments.length + unpaidOnly.length;
    final total = items.fold<int>(0, (sum, item) => sum + item.amount);
    final groups = <String, List<_StudentPaymentItem>>{};
    for (final item in items) {
      final key = item.userId.isNotEmpty ? item.userId : item.email;
      groups.putIfAbsent(key, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MonthBar(
            month: _month,
            title: tr(context, '수강생 정산'),
            onShift: (delta) => setState(() {
              _month = DateTime(_month.year, _month.month + delta);
            }),
          ),
          const SizedBox(height: 8),
          Text(
            tr(context, '한 달 입금과 토스 주문, 아직 안 끝난 건을 한곳에서 봅니다. 같은 수강생·과정은 한 줄로만 나옵니다.'),
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          const SizedBox(height: 14),
          _summaryRow([
            _summaryCell(tr(context, '입금'), tf(context, '{p0}건', {'p0': items.length}), Palette.secondaryDark),
            _summaryCell(tr(context, '수강생'), tf(context, '{p0}명', {'p0': groups.length}), Palette.navy),
            _summaryCell(tr(context, '합계'), _formatWon(total), Palette.success),
          ]),
          const SizedBox(height: 8),
          Text(
            tf(context, '토스 결제완료 {p0}건 {p1} · 미완료 {p2}건', {'p0': monthPaid.length, 'p1': _formatWon(monthPaidSum), 'p2': openCount}),
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Palette.secondaryDark),
          ),
          if (widget.loading) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            if (openCount > 0) ...[
              const SizedBox(height: 24),
              Text(tr(context, '미완료'), style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                tr(context, '토스에서 아직 안 끝난 주문은 수강 배정으로, 배정만 되고 입금 표시가 없는 수강은 회원 상세에서 처리합니다.'),
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey600),
              ),
              const SizedBox(height: 12),
              ...actionPayments.map(_tossPaymentCard),
              ...unpaidOnly.map(_unpaidTile),
            ],
            const SizedBox(height: 24),
            Text(tr(context, '이 달 입금'),
                style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text(tr(context, '이 달 입금 기록이 없습니다.'),
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.grey500))
            else
              ...groups.entries.map((entry) => _studentGroup(entry.value)),
            const SizedBox(height: 24),
            Text(tr(context, '토스 결제 내역'),
                style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              tr(context, '이 달 결제 완료·실패 주문입니다. 아직 안 끝난 주문은 위 미완료에만 있습니다.'),
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  color: Palette.grey600),
            ),
            const SizedBox(height: 12),
            if (monthPayments.isEmpty)
              Text(tr(context, '이 달 토스 주문이 없습니다.'),
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.grey500))
            else
              ...monthPayments.map(_tossPaymentCard),
          ],
        ],
      ),
    );
  }

  Widget _tossPaymentCard(PaymentOrder p) {
    final color = p.status == 'paid'
        ? Palette.success
        : (p.status == 'failed' ? Palette.danger : Palette.grey600);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
            '${p.memberName.isEmpty ? p.email : p.memberName} · ${p.courseTitle}',
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontWeight: FontWeight.bold,
                fontSize: 13)),
        subtitle: Text(
          tf(context, '{p0}\n{p1} · 화상 {p2}회 · {p3}\n주문 {p4}\n생성 {p5}{p6}', {'p0': p.email, 'p1': p.amountLabel, 'p2': p.totalSessions, 'p3': p.statusLabel, 'p4': p.orderId, 'p5': _formatDateTime(p.createdAt), 'p6': p.paidAt != null ? tf(context, ' · 결제 {p0}', {'p0': _formatDateTime(p.paidAt)}): ''}),
          style: TextStyle(
              fontFamily: "NotoSansKR",
              fontSize: 12,
              height: 1.45,
              color: Palette.grey600),
        ),
        isThreeLine: true,
        trailing: FittedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(p.statusLabel,
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color)),
              if (p.status == 'authorized' || p.status == 'pending')
                TextButton(
                  onPressed: () async {
                    final error =
                        await PaymentService.adminFulfillPayment(p.orderId);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            tr(context, error ?? '수강 배정이 완료되었습니다.'),
                            style: TextStyle(fontFamily: "NotoSansKR")),
                        backgroundColor:
                            error != null ? Palette.danger : Palette.success,
                      ),
                    );
                    await widget.onRefresh();
                  },
                  child: Text(tr(context, '수강 배정'),
                      style: TextStyle(
                          fontFamily: "NotoSansKR",
                          fontSize: 11,
                          color: Palette.secondaryDark)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studentGroup(List<_StudentPaymentItem> rows) {
    final first = rows.first;
    final sum = rows.fold<int>(0, (total, row) => total + row.amount);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            first.name.isEmpty ? first.email : first.name,
            style: TextStyle(
                fontFamily: "NotoSansKR", fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            [
              if (first.email.isNotEmpty) first.email,
              if (first.teacherName.trim().isNotEmpty) tf(context, '담당 {p0}', {'p0': first.teacherName}),
              tf(context, '{p0}건 · {p1}', {'p0': rows.length, 'p1': _formatWon(sum)}),
            ].join(' · '),
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 12, color: Palette.grey600),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentDetailPage(
                      member: first.member,
                      teacherName: first.teacherName,
                    ),
                  ),
                ),
                icon: const Icon(Icons.person_outline, size: 18),
                label: Text(tr(context, '회원 상세'),
                    style: TextStyle(fontFamily: "NotoSansKR")),
              ),
            ),
            ...rows.map((row) => ListTile(
                  dense: true,
                  title: Text(
                    '${row.courseTitle} · ${_formatWon(row.amount)}',
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 13),
                  ),
                  subtitle: Text(
                    '${row.source} · ${_formatDateTime(row.at, dateOnly: true)}'
                    '${row.teacherName.trim().isEmpty ? '' : ' · ${row.teacherName}'}',
                    style: TextStyle(
                        fontFamily: "NotoSansKR",
                        fontSize: 12,
                        color: Palette.grey500),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _unpaidTile(EnrollmentRecord record) {
    final title = record.course?.title ?? record.courseId;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailPage(
              member: {
                'uid': record.userId,
                'name': record.memberName,
                'email': record.email,
                'nativeTeacherName': record.nativeTeacherName,
              },
              teacherName: record.nativeTeacherLabel,
            ),
          ),
        ),
        title: Text(
          '${record.memberName.isEmpty ? record.email : record.memberName} · $title',
          style: TextStyle(
              fontFamily: "NotoSansKR",
              fontWeight: FontWeight.w700,
              fontSize: 13),
        ),
        subtitle: Text(
          [
            if (record.email.isNotEmpty) record.email,
            if (record.nativeTeacherLabel.trim().isNotEmpty)
              tf(context, '담당 {p0}', {'p0': record.nativeTeacherLabel}),
            tr(context, '배정됨 · 입금 미확인'),
          ].join(' · '),
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 12, color: Palette.danger),
        ),
        trailing: Text(tr(context, '회원 상세'),
            style: TextStyle(
                fontFamily: "NotoSansKR",
                fontSize: 12,
                color: Palette.secondaryDark)),
      ),
    );
  }
}

class _TeacherPayrollPane extends StatefulWidget {
  final List<Map<String, dynamic>> teachers;
  final List<WeekBooking> bookings;
  final List<LessonRating> ratings;
  final Map<String, TeacherSettlement> settlements;
  final bool loading;
  final Future<void> Function() onRefresh;

  const _TeacherPayrollPane({
    required this.teachers,
    required this.bookings,
    required this.ratings,
    required this.settlements,
    required this.loading,
    required this.onRefresh,
  });

  @override
  State<_TeacherPayrollPane> createState() => _TeacherPayrollPaneState();
}

class _TeacherPayRow {
  final Map<String, dynamic> teacher;
  final TeacherPayroll payroll;
  final int pending;

  const _TeacherPayRow({
    required this.teacher,
    required this.payroll,
    required this.pending,
  });
}

class _TeacherPayrollPaneState extends State<_TeacherPayrollPane> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  TeacherPayroll _payrollFor(Map<String, dynamic> teacher) {
    final uid = teacher['uid']?.toString() ?? '';
    return TeacherPayroll.forTeacher(
      bookings: widget.bookings,
      ratings: widget.ratings,
      teacherUid: uid,
      year: _month.year,
      month: _month.month,
      lessonFeeWon: EnrollmentService.lessonFeeWonOf(teacher),
      settlements: widget.settlements.values
          .where((item) => item.teacherUid == uid)
          .toList(),
    );
  }

  Future<void> _markPaid(_TeacherPayRow row) async {
    final payroll = row.payroll;
    final english = AppLanguage.instance.isEnglish;
    final due = payroll.dueLabel(english: english);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tf(dialogContext, '{p0} 지급 기록', {'p0': due}),
            style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        content: Text(
          tf(
            dialogContext,
            '{p0} 1일–말일 완료 {p1}회\n지난 마감 후 {p2}회\n합계 {p3}회 · {p4}\n\n통장 이체는 없습니다. 이 횟수와 금액을 지급 기록으로 남깁니다.',
            {
              'p0': payroll.monthLabel,
              'p1': payroll.closedCount,
              'p2': payroll.carryInCount,
              'p3': payroll.shownPayoutCount,
              'p4': TeacherPayroll.won(payroll.shownAmount),
            },
          ),
          style: TextStyle(fontFamily: "NotoSansKR", height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(dialogContext, '취소'),
                style: TextStyle(fontFamily: "NotoSansKR")),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(dialogContext, '기록'),
                style: TextStyle(fontFamily: "NotoSansKR")),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final uid = row.teacher['uid']?.toString() ?? '';
    final error = await AuthService.markLessonSettlementPaid(
      teacherUid: uid,
      month: _month,
      sessionCount: payroll.shownPayoutCount,
      amount: payroll.shownAmount,
      lessonFeeWon: payroll.lessonFeeWon,
      closedCount: payroll.closedCount,
      carryInCount: payroll.carryInCount,
      bookingIds: payroll.payoutBookingIds,
      payDue: payroll.deposit,
      monthEndedAt:
          TeacherPayroll.seoulMidnightUtc(payroll.year, payroll.month + 1, 1),
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr(context, error),
                style: TextStyle(fontFamily: "NotoSansKR")),
            backgroundColor: Palette.danger),
      );
      return;
    }
    await widget.onRefresh();
  }

  int _pendingFor(String uid) {
    var count = 0;
    for (final booking in widget.bookings) {
      if (!TeacherMonthStats.taughtBy(booking, uid)) continue;
      if (booking.date.year != _month.year ||
          booking.date.month != _month.month) {
        continue;
      }
      if (booking.status == 'pending') count += 1;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.teachers.map((teacher) {
      final uid = teacher['uid']?.toString() ?? '';
      return _TeacherPayRow(
        teacher: teacher,
        payroll: _payrollFor(teacher),
        pending: _pendingFor(uid),
      );
    }).toList();

    final payoutCount =
        rows.fold<int>(0, (sum, row) => sum + row.payroll.shownPayoutCount);
    final cancelled =
        rows.fold<int>(0, (sum, row) => sum + row.payroll.cancelledCount);
    final awaiting =
        rows.fold<int>(0, (sum, row) => sum + row.payroll.awaitingCount);
    final late = rows.fold<int>(0, (sum, row) => sum + row.payroll.lateCount);
    final payroll =
        rows.fold<int>(0, (sum, row) => sum + row.payroll.shownAmount);
    final dueDate = TeacherPayroll.seoulDate(
        TeacherPayroll.seoulMidnightUtc(_month.year, _month.month + 1, 10));
    final due = '${dueDate.month}월 ${dueDate.day}일';

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MonthBar(
            month: _month,
            title: tr(context, '이번 달 수업 수당'),
            onShift: (delta) => setState(() {
              _month = DateTime(_month.year, _month.month + delta);
            }),
          ),
          const SizedBox(height: 8),
          Text(
            tf(context, '{p0}월 수업분 · 지급일 {p1}. 월마감은 말일입니다. 1일부터 말일까지 별점이 끝난 확정 수업이 이 지급분입니다. 말일 이후 별점은 마감 후로 남고, 별점이 끝난 달의 다음 10일에 지급합니다. 수업 {p2}분 · 회차 수당은 강사마다 다르고, 없으면 {p3}입니다. 지급 완료는 횟수와 금액만 남기며 통장 이체는 없습니다.', {
              'p0': _month.month,
              'p1': due,
              'p2': EnrollmentService.lessonMinutes,
              'p3': _formatWon(EnrollmentService.lessonPayWon),
            }),
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          const SizedBox(height: 16),
          Text(tr(context, '모든 강사 합계'),
              style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          const SizedBox(height: 10),
          _summaryRow([
            _summaryCell(tr(context, '이번 지급'), tf(context, '{p0}회', {'p0': payoutCount}), Palette.secondaryDark),
            _summaryCell(tr(context, '수당'), _formatWon(payroll), Palette.navy),
          ]),
          const SizedBox(height: 8),
          _summaryRow([
            _summaryCell(tr(context, '마감 후'), tf(context, '{p0}회', {'p0': late}), Palette.warning),
            _summaryCell(tr(context, '평가대기'), tf(context, '{p0}건', {'p0': awaiting}), Palette.warning),
          ]),
          const SizedBox(height: 8),
          _summaryRow([
            _summaryCell(tr(context, '취소'), tf(context, '{p0}회', {'p0': cancelled}), Palette.danger),
          ]),
          const SizedBox(height: 24),
          Text(tr(context, '강사별 수당'), style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          const SizedBox(height: 10),
          if (widget.loading)
            const Center(child: CircularProgressIndicator())
          else if (rows.isEmpty)
            Text(tr(context, '등록된 강사가 없습니다.'),
                style:
                    TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
          else
            ...rows.map(_teacherCard),
        ],
      ),
    );
  }

  Widget _teacherCard(_TeacherPayRow row) {
    final teacher = row.teacher;
    final payroll = row.payroll;
    final isOwnerTeacher = AuthService.docIsOwner(teacher);
    final name = teacher['name']?.toString() ?? '';
    final email = teacher['email']?.toString() ?? '';
    final bank = AuthService.bankLabel(teacher);
    final english = AppLanguage.instance.isEnglish;
    final payoutLabel =
        tr(context, payroll.isEstimate ? '예상 지급' : '이번 지급');
    final amountLabel = tr(context, payroll.isEstimate ? '예상 수당' : '수당');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOwnerTeacher ? tf(context, '{p0} (메인 관리자 · 강사)', {'p0': name}): name,
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(email,
                  style: TextStyle(
                      fontFamily: "NotoSansKR",
                      fontSize: 12,
                      color: Palette.grey600)),
            ],
            const SizedBox(height: 10),
            _summaryRow([
              _summaryCell(payoutLabel, tf(context, '{p0}회', {'p0': payroll.shownClosed}), Palette.secondaryDark),
              _summaryCell(tr(context, '지난 마감 후'), tf(context, '{p0}회', {'p0': payroll.shownCarry}), Palette.secondaryDark),
            ]),
            const SizedBox(height: 8),
            _summaryRow([
              _summaryCell(tr(context, '마감 후'), tf(context, '{p0}회', {'p0': payroll.lateCount}), Palette.warning),
              _summaryCell(amountLabel, TeacherPayroll.won(payroll.shownAmount), Palette.navy),
            ]),
            const SizedBox(height: 8),
            _summaryRow([
              _summaryCell(tr(context, '평가대기'), tf(context, '{p0}건', {'p0': payroll.awaitingCount}), Palette.warning),
              _summaryCell(tr(context, '평균별점'), payroll.averageStarsLabel, Palette.warning),
            ]),
            const SizedBox(height: 8),
            _summaryRow([
              _summaryCell(tr(context, '취소'), tf(context, '{p0}회', {'p0': payroll.cancelledCount}), Palette.danger),
              _summaryCell(tr(context, '예약대기'), tf(context, '{p0}건', {'p0': row.pending}), Palette.grey600),
            ]),
            const SizedBox(height: 10),
            Text(
              bank.isEmpty ? tr(context, '수당 계좌 미등록'): bank,
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  color: bank.isEmpty ? Palette.grey500 : Palette.grey700),
            ),
            const SizedBox(height: 8),
            Text(
              tf(context, '회차 수당 {p0} · 지급일 {p1}', {
                'p0': _formatWon(payroll.lessonFeeWon),
                'p1': payroll.dueLabel(english: english),
              }),
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  color: Palette.grey600),
            ),
            if (payroll.legacyNote != null) ...[
              const SizedBox(height: 8),
              Text(
                payroll.legacyNote!,
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: Palette.grey700),
              ),
            ],
            const SizedBox(height: 8),
            _payButton(row),
          ],
        ),
      ),
    );
  }

  Widget _payButton(_TeacherPayRow row) {
    final payroll = row.payroll;
    if (payroll.paid) {
      final when = payroll.paidAt == null
          ? ''
          : ' · ${TeacherPayroll.formatSeoulDay(payroll.paidAt!)}';
      return Text(
        tf(context, '지급 완료{p0} · {p1}회 · {p2}', {
          'p0': when,
          'p1': payroll.shownPayoutCount,
          'p2': TeacherPayroll.won(payroll.shownAmount),
        }),
        style: TextStyle(
            fontFamily: "NotoSansKR",
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Palette.secondaryDark),
      );
    }
    if (!payroll.canMarkPaid) {
      final due = payroll.dueLabel(english: AppLanguage.instance.isEnglish);
      final note = payroll.isEstimate
          ? tf(context, '말일까지는 예상입니다. {p0}부터 기록할 수 있습니다.', {'p0': due})
          : tf(context, '{p0}부터 기록할 수 있습니다.', {'p0': due});
      return Text(
        note,
        style: TextStyle(
            fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton(
        onPressed: widget.loading ? null : () => _markPaid(row),
        child: Text(tr(context, '지급 완료'), style: TextStyle(fontFamily: "NotoSansKR")),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  final DateTime month;
  final String title;
  final ValueChanged<int> onShift;

  const _MonthBar({
    required this.month,
    required this.title,
    required this.onShift,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: tr(context, '이전 달'),
          onPressed: () => onShift(-1),
          icon: Icon(Icons.chevron_left, color: Palette.navy),
        ),
        Expanded(
          child: Column(
            children: [
              Text(title, style: TextStyle(fontFamily: "Jalnan", fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                tf(context, '{p0}년 {p1}월', {'p0': month.year, 'p1': month.month}),
                style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.secondaryDark,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: tr(context, '다음 달'),
          onPressed: () => onShift(1),
          icon: Icon(Icons.chevron_right, color: Palette.navy),
        ),
      ],
    );
  }
}

Widget _summaryRow(List<Widget> cells) {
  return Row(
    children: [
      for (var i = 0; i < cells.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: cells[i]),
      ],
    ],
  );
}

Widget _summaryCell(String label, String value, Color valueColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(
      color: Palette.grey50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Palette.grey200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 11, color: Palette.grey600)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: "Jalnan", fontSize: 14, color: valueColor),
        ),
      ],
    ),
  );
}

String _formatWon(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return AppLanguage.instance.fill('{p0}원', {'p0': buf.toString()});
}

String _formatDateTime(DateTime? dt, {bool dateOnly = false}) {
  if (dt == null) return '-';
  String two(int n) => n.toString().padLeft(2, '0');
  final date = '${dt.year}.${two(dt.month)}.${two(dt.day)}';
  if (dateOnly) return date;
  return '$date ${two(dt.hour)}:${two(dt.minute)}';
}
