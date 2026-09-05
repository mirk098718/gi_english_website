import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';

class AdminBookingTab extends StatefulWidget {
  @override
  _AdminBookingTabState createState() => _AdminBookingTabState();
}

class _AdminBookingTabState extends State<AdminBookingTab> {
  List<WeekBooking> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
    });
    final bookings = await EnrollmentService.staffWeekBookings();
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
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

  Future<void> _confirm(WeekBooking booking) async {
    final error = await EnrollmentService.confirmWeekBooking(booking.id);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('예약을 확인했습니다.');
    await _refresh();
  }

  Future<void> _reject(WeekBooking booking) async {
    final error = await EnrollmentService.rejectWeekBooking(booking.id);
    if (error != null) {
      _toast(error, error: true);
      return;
    }
    _toast('예약을 거절했습니다.');
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text('수업 예약', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        SizedBox(height: 8),
        Text(
          '회원이 문제풀이까지 체크한 뒤 신청한 주차 수업입니다. 날짜·시간을 확인하고 컨펌하세요.',
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
        ),
        SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _refresh,
            icon: Icon(Icons.refresh, size: 18),
            label: Text('새로고침', style: TextStyle(fontFamily: "NotoSansKR")),
          ),
        ),
        SizedBox(height: 16),
        if (_loading)
          Center(child: CircularProgressIndicator())
        else if (_bookings.isEmpty)
          Text('아직 들어온 예약이 없습니다.',
              style:
                  TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
        else
          ..._bookings.map(_bookingCard),
      ],
    );
  }

  Widget _bookingCard(WeekBooking booking) {
    final course = OnlineCourse.findById(booking.courseId);
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.memberName.isEmpty
                        ? booking.email
                        : '${booking.memberName} · ${booking.email}',
                    style: TextStyle(
                        fontFamily: "NotoSansKR", fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  booking.statusLabel,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 12,
                    color: booking.isConfirmed
                        ? Palette.success
                        : booking.status == 'rejected'
                            ? Palette.danger
                            : Palette.warning,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              '${course?.title ?? booking.courseId} · ${booking.weekNumber}주차'
              '${booking.weekTitle.isEmpty ? '' : ' · ${booking.weekTitle}'}',
              style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  color: Palette.grey600),
            ),
            SizedBox(height: 4),
            Text(
              '${EnrollmentService.formatBookingDate(booking.date)} ${booking.time}',
              style: TextStyle(fontFamily: "Jalnan", fontSize: 15),
            ),
            if (booking.isPending) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.secondaryDark,
                      foregroundColor: Palette.white,
                    ),
                    onPressed: () => _confirm(booking),
                    child:
                        Text('컨펌', style: TextStyle(fontFamily: "Jalnan")),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _reject(booking),
                    child: Text('거절',
                        style: TextStyle(fontFamily: "NotoSansKR")),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
