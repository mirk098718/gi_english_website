import 'package:flutter/material.dart';
import 'package:gi_english_website/class/JuniorLevel.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/SiteLayout.dart';
import 'package:gi_english_website/widget/JuniorLevelTestDialog.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

/// 주니어 레벨테스트. 초등부와 중등부를 나눠 연다.
class JuniorLevelTestPage extends StatefulWidget {
  const JuniorLevelTestPage({Key? key}) : super(key: key);

  @override
  State<JuniorLevelTestPage> createState() => _JuniorLevelTestPageState();
}

class _JuniorLevelTestPageState extends State<JuniorLevelTestPage> {
  JuniorLevel? _saved;

  Future<void> _start(String band) async {
    final result = await JuniorLevelTestDialog.open(context, band: band);
    if (result == null || !mounted) return;
    final userId = AuthService.currentUser?.uid ?? '';
    String? error;
    if (userId.isNotEmpty) {
      error = await EnrollmentService.saveJuniorLevel(
        userId: userId,
        level: result,
      );
    }
    if (!mounted) return;
    setState(() {
      if (error == null) _saved = result;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, error ?? '현재 레벨을 저장했습니다.'),
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
        backgroundColor: error == null ? Palette.success : Palette.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      child: Column(
        children: [
          _content(compact: useMobileSchoolLayout(context)),
          if (!useMobileSchoolLayout(context)) MyWidget.footer(),
        ],
      ),
    );
    if (!useMobileSchoolLayout(context)) {
      return WebSchoolLayout(content: body);
    }
    return MobileSchoolLayout(content: body);
  }

  Widget _content({required bool compact}) {
    return Container(
      width: double.maxFinite,
      color: Palette.white,
      padding: EdgeInsets.all(compact ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, '주니어 레벨테스트'),
            style: TextStyle(fontFamily: 'Jalnan', fontSize: 20),
          ),
          SizedBox(height: 8),
          Text(
            tr(context, '초등부와 중등부 테스트를 따로 봅니다. 각각 레벨 1부터 6까지 나뉩니다.'),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 14,
              height: 1.5,
              color: Palette.grey700,
            ),
          ),
          if (_saved != null) ...[
            SizedBox(height: 12),
            Text(
              tf(context, '현재 레벨 {p0}', {'p0': _saved!.label}),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w700,
                color: Palette.secondaryDark,
              ),
            ),
          ],
          SizedBox(height: 20),
          if (compact)
            Column(
              children: [
                _card(JuniorLevel.elementary),
                SizedBox(height: 12),
                _card(JuniorLevel.middle),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _card(JuniorLevel.elementary)),
                SizedBox(width: 12),
                Expanded(child: _card(JuniorLevel.middle)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _card(String band) {
    final elementary = band == JuniorLevel.elementary;
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: elementary ? const Color(0xFFFFF6EE) : Palette.grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: elementary ? const Color(0xFFEA7A1A) : Palette.grey200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, elementary ? '초등부' : '중등부'),
            style: TextStyle(fontFamily: 'Jalnan', fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            tr(
              context,
              elementary
                  ? '알파벳, 짧은 문장, 간단한 이야기로 초등 레벨 1~6을 나눕니다.'
                  : '문법과 짧은 글을 읽고 중등 레벨 1~6을 나눕니다.',
            ),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              height: 1.5,
              color: Palette.grey700,
            ),
          ),
          SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => _start(band),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  elementary ? const Color(0xFFEA7A1A) : Palette.darkTeal,
              foregroundColor: Palette.white,
            ),
            child: Text(
              tr(context, '테스트 시작'),
              style: TextStyle(fontFamily: 'NotoSansKR'),
            ),
          ),
        ],
      ),
    );
  }
}
