import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 홈: 주간 루프 아래, 수업 화면과 예약 알림 안내.
class HomeClassAlertBand extends StatelessWidget {
  final bool compact;

  const HomeClassAlertBand({Key? key, this.compact = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Palette.white,
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 48,
        compact ? 36 : 56,
        compact ? 20 : 48,
        compact ? 36 : 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '예약 · 알림',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: Palette.darkTeal,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '내 시간에 맞춰 고르면,\n수업 전에 알려 드립니다',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w800,
              height: 1.28,
              color: Palette.black,
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720),
            child: Text(
              '30분 단위로 화상수업을 예약하면, 수업 전에 카카오톡과 이메일로 일정을 보내 드립니다.',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: compact ? 14 : 16,
                height: 1.6,
                color: Palette.grey600,
              ),
            ),
          ),
          SizedBox(height: compact ? 24 : 32),
          _image(
            asset: 'assets/curriculum-service-overview.jpg',
            label: '인강 · 디지털 교재 · 실시간 화상수업 · 피드백 체크리스트가 한 화면에서 이어집니다.',
          ),
          SizedBox(height: compact ? 28 : 40),
          Text(
            '예약하면 수업 전에 이렇게 알려 드립니다.',
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: Palette.navy,
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          _image(
            asset: 'assets/online-class-alert.png',
            label: '열린 시간은 30분 칸으로 보이고, 예약이 확정되면 글림 에듀케이션 알림이 갑니다.',
          ),
        ],
      ),
    );
  }

  Widget _image({required String asset, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            asset,
            width: double.infinity,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.high,
          ),
        ),
        SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 12 : 13,
            height: 1.5,
            color: Palette.grey600,
          ),
        ),
      ],
    );
  }
}
