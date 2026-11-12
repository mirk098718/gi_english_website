import 'package:flutter/material.dart';
import 'package:gi_english_website/class/TeacherClassBands.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 강사 카드에 붙는 대략적인 수업 시간.
class TeacherClassTimeLine extends StatelessWidget {
  final TeacherClassBands bands;

  const TeacherClassTimeLine({Key? key, required this.bands}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final words = bands.keywords;
    if (words.isEmpty) return const SizedBox.shrink();
    final line = words.map((word) => tr(context, word)).join(', ');
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Class Time : $line',
        style: TextStyle(
          fontFamily: 'NotoSansKR',
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w700,
          color: Palette.darkTeal,
        ),
      ),
    );
  }
}
