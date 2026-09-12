import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/StudentDetailPage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PaymentService.dart';

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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final payments = await PaymentService.listPayments(limit: 2000);
    final enrollments = await EnrollmentService.listEnrollments();
    final teachers = await AuthService.listTeachers();
    final bookings = await EnrollmentService.staffWeekBookings(mineOnly: false);
    if (!mounted) return;
    setState(() {
      _payments = payments;
      _enrollments = enrollments;
      _teachers = teachers;
      _bookings = bookings;
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
              tabs: const [
                Tab(text: '수강생 정산'),
                Tab(text: '강사 월급'),
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
        source: '토스',
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
        source: record.paymentNote.isEmpty ? '수강카드' : record.paymentNote,
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
            title: '수강생 정산',
            onShift: (delta) => setState(() {
              _month = DateTime(_month.year, _month.month + delta);
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '한 달 입금과 토스 주문, 아직 안 끝난 건을 한곳에서 봅니다. 같은 수강생·과정은 한 줄로만 나옵니다.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          const SizedBox(height: 14),
          _summaryRow([
            _summaryCell('입금', '${items.length}건', Palette.secondaryDark),
            _summaryCell('수강생', '${groups.length}명', Palette.navy),
            _summaryCell('합계', _formatWon(total), Palette.success),
          ]),
          const SizedBox(height: 8),
          Text(
            '토스 결제완료 ${monthPaid.length}건 ${_formatWon(monthPaidSum)} · 미완료 $openCount건',
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
              Text('미완료', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                '토스에서 아직 안 끝난 주문은 수강 배정으로, 배정만 되고 입금 표시가 없는 수강은 회원 상세에서 처리합니다.',
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
            Text('이 달 입금',
                style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text('이 달 입금 기록이 없습니다.',
                  style: TextStyle(
                      fontFamily: "NotoSansKR", color: Palette.grey500))
            else
              ...groups.entries.map((entry) => _studentGroup(entry.value)),
            const SizedBox(height: 24),
            Text('토스 결제 내역',
                style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '이 달 결제 완료·실패 주문입니다. 아직 안 끝난 주문은 위 미완료에만 있습니다.',
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  color: Palette.grey600),
            ),
            const SizedBox(height: 12),
            if (monthPayments.isEmpty)
              Text('이 달 토스 주문이 없습니다.',
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
          '${p.email}\n'
          '${p.amountLabel} · 화상 ${p.totalSessions}회 · ${p.statusLabel}\n'
          '주문 ${p.orderId}\n'
          '생성 ${_formatDateTime(p.createdAt)}'
          '${p.paidAt != null ? ' · 결제 ${_formatDateTime(p.paidAt)}' : ''}',
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
                        content: Text(error ?? '수강 배정이 완료되었습니다.',
                            style: TextStyle(fontFamily: "NotoSansKR")),
                        backgroundColor:
                            error != null ? Palette.danger : Palette.success,
                      ),
                    );
                    await widget.onRefresh();
                  },
                  child: Text('수강 배정',
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
              if (first.teacherName.trim().isNotEmpty) '담당 ${first.teacherName}',
              '${rows.length}건 · ${_formatWon(sum)}',
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
                label: Text('회원 상세',
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
              '담당 ${record.nativeTeacherLabel}',
            '배정됨 · 입금 미확인',
          ].join(' · '),
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 12, color: Palette.danger),
        ),
        trailing: Text('회원 상세',
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
  final bool loading;
  final Future<void> Function() onRefresh;

  const _TeacherPayrollPane({
    required this.teachers,
    required this.bookings,
    required this.loading,
    required this.onRefresh,
  });

  @override
  State<_TeacherPayrollPane> createState() => _TeacherPayrollPaneState();
}

class _TeacherPayRow {
  final Map<String, dynamic> teacher;
  final TeacherMonthStats stats;
  final int pending;

  const _TeacherPayRow({
    required this.teacher,
    required this.stats,
    required this.pending,
  });
}

class _TeacherPayrollPaneState extends State<_TeacherPayrollPane> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool _isCompleted(WeekBooking booking) {
    final at = EnrollmentService.bookingDateTime(booking.date, booking.time);
    if (at == null) return booking.isConfirmed;
    return booking.isConfirmed &&
        DateTime.now().isAfter(
            at.add(Duration(minutes: EnrollmentService.lessonMinutes)));
  }

  TeacherMonthStats _statsFor(String uid) {
    return TeacherMonthStats.fromBookings(
      bookings: widget.bookings,
      teacherUid: uid,
      isCompleted: _isCompleted,
      now: _month,
    );
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
        stats: _statsFor(uid),
        pending: _pendingFor(uid),
      );
    }).toList();

    final completed = rows.fold<int>(0, (sum, row) => sum + row.stats.completedCount);
    final cancelled = rows.fold<int>(0, (sum, row) => sum + row.stats.cancelledCount);
    final pending = rows.fold<int>(0, (sum, row) => sum + row.pending);
    final payroll = rows.fold<int>(0, (sum, row) => sum + row.stats.incomeWon);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MonthBar(
            month: _month,
            title: '강사 월급 정산',
            onShift: (delta) => setState(() {
              _month = DateTime(_month.year, _month.month + delta);
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '확정 후 수업 시간이 지난 건을 진행으로 셉니다. '
            '수업 ${EnrollmentService.lessonMinutes}분 · 건당 ${_formatWon(EnrollmentService.lessonPayWon)}.',
            style: TextStyle(
                fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
          ),
          const SizedBox(height: 16),
          Text('모든 강사 합계',
              style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          const SizedBox(height: 10),
          _summaryRow([
            _summaryCell('진행', '$completed회', Palette.secondaryDark),
            _summaryCell('취소', '$cancelled회', Palette.danger),
          ]),
          const SizedBox(height: 8),
          _summaryRow([
            _summaryCell('대기', '$pending건', Palette.grey600),
            _summaryCell('월급', _formatWon(payroll), Palette.navy),
          ]),
          const SizedBox(height: 24),
          Text('강사별 월급', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
          const SizedBox(height: 10),
          if (widget.loading)
            const Center(child: CircularProgressIndicator())
          else if (rows.isEmpty)
            Text('등록된 강사가 없습니다.',
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
    final stats = row.stats;
    final isOwnerTeacher = teacher['role']?.toString() != 'teacher';
    final name = teacher['name']?.toString() ?? '';
    final email = teacher['email']?.toString() ?? '';
    final bank = AuthService.bankLabel(teacher);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOwnerTeacher ? '$name (메인 관리자 · 강사)' : name,
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
              _summaryCell('진행', '${stats.completedCount}회', Palette.secondaryDark),
              _summaryCell('취소', '${stats.cancelledCount}회', Palette.danger),
            ]),
            const SizedBox(height: 8),
            _summaryRow([
              _summaryCell('대기', '${row.pending}건', Palette.grey600),
              _summaryCell('월급', stats.incomeLabel, Palette.navy),
            ]),
            const SizedBox(height: 10),
            Text(
              bank.isEmpty ? '월급 계좌 미등록' : bank,
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 12,
                  color: bank.isEmpty ? Palette.grey500 : Palette.grey700),
            ),
          ],
        ),
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
          tooltip: '이전 달',
          onPressed: () => onShift(-1),
          icon: Icon(Icons.chevron_left, color: Palette.navy),
        ),
        Expanded(
          child: Column(
            children: [
              Text(title, style: TextStyle(fontFamily: "Jalnan", fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                '${month.year}년 ${month.month}월',
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
          tooltip: '다음 달',
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
  return '${buf.toString()}원';
}

String _formatDateTime(DateTime? dt, {bool dateOnly = false}) {
  if (dt == null) return '-';
  String two(int n) => n.toString().padLeft(2, '0');
  final date = '${dt.year}.${two(dt.month)}.${two(dt.day)}';
  if (dateOnly) return date;
  return '$date ${two(dt.hour)}:${two(dt.minute)}';
}
