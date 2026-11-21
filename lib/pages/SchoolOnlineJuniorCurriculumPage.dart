import 'package:flutter/material.dart';
import 'package:gi_english_website/class/JuniorCurriculum.dart';
import 'package:gi_english_website/class/OnlinePlan.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/MyWidget.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/SiteLayout.dart';
import 'package:gi_english_website/widget/MobileSchoolLayout.dart';
import 'package:gi_english_website/widget/OnlineProgramSideMenu.dart';
import 'package:gi_english_website/widget/WebSchoolLayout.dart';

/// 과정 왼쪽 메뉴의 주니어 커리큘럼.
/// 원서 사진과 다른 수업 카드의 원어민 강사 사진을 카드로 보여주고,
/// 주 2회·주 3회 금액과 3개월 5% 할인을 고를 수 있다.
class SchoolOnlineJuniorCurriculumPage extends StatelessWidget {
  const SchoolOnlineJuniorCurriculumPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!useMobileSchoolLayout(context)) {
      return WebSchoolLayout(
        content: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                color: Palette.white,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 232,
                      child: OnlineProgramSideMenu(
                        selectedIndex: OnlineProgramSideMenu.juniorIndex,
                      ),
                    ),
                    Expanded(child: JuniorCurriculumContent()),
                  ],
                ),
              ),
              MyWidget.footer(),
            ],
          ),
        ),
      );
    }
    return MobileSchoolLayout(
      content: SingleChildScrollView(
        child: Container(
          color: Palette.white,
          child: Column(
            children: [
              OnlineProgramSideMenu(
                selectedIndex: OnlineProgramSideMenu.juniorIndex,
                isMobile: true,
              ),
              JuniorCurriculumContent(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class JuniorCurriculumContent extends StatefulWidget {
  static const description =
      'Trophy9 영어 원서를 읽고, 문제를 풀고, 원어민 선생님과 1대1 화상으로 이야기를 나눕니다.';

  final bool compact;
  final String title;

  const JuniorCurriculumContent({
    Key? key,
    this.compact = false,
    this.title = '주니어 커리큘럼',
  }) : super(key: key);

  @override
  State<JuniorCurriculumContent> createState() =>
      _JuniorCurriculumContentState();
}

class _JuniorCurriculumContentState extends State<JuniorCurriculumContent> {
  static const _orange = Color(0xFFEA7A1A);
  static const _cream = Color(0xFFFFF6EE);

  final GlobalKey _programsKey = GlobalKey();
  JuniorOffer _offer = JuniorOffer.twiceAWeek;
  bool _quarter = false;

  void _openPrograms() {
    final target = _programsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 320),
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _offer.priceLabel(quarter: _quarter);
    return Container(
      width: double.maxFinite,
      color: Palette.white,
      padding: EdgeInsets.all(widget.compact ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, widget.title),
            style: TextStyle(fontFamily: 'Jalnan', fontSize: 20),
          ),
          SizedBox(height: 8),
          Text(
            tr(context, '초·중등 학생을 위한 원서 읽기와 1:1 화상 영어 수업입니다.'),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 14,
              height: 1.5,
              color: Palette.grey700,
            ),
          ),
          SizedBox(height: 20),
          _heroCard(),
          SizedBox(height: 28),
          KeyedSubtree(
            key: _programsKey,
            child: _programs(),
          ),
          SizedBox(height: 16),
          Text(
            tf(context, '선택한 금액 {p0}', {'p0': selected}),
            style: TextStyle(
              fontFamily: 'Jalnan',
              fontSize: 16,
              color: _orange,
            ),
          ),
          SizedBox(height: 8),
          Text(
            tr(context, '3개월을 한 번에 신청하면 5% 할인됩니다.'),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              height: 1.5,
              color: Palette.grey600,
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SizedBox(
              height: widget.compact ? 180 : 230,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _shot(
                      asset: 'assets/junior-reader-spread.jpg',
                      label: '원서',
                      badge: _orange,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, color: _orange, size: 22),
                  ),
                  Expanded(
                    flex: 3,
                    child: _shot(
                      asset: 'assets/plan-card-speaking.jpg',
                      label: '화상',
                      badge: Palette.secondaryDark,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _orange,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '4',
                  style: TextStyle(
                    fontFamily: 'Jalnan',
                    fontSize: 16,
                    color: Palette.white,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Text(
                tr(context, '초·중등'),
                style: TextStyle(
                  fontFamily: 'Jalnan',
                  fontSize: 18,
                  color: _orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            tr(context, '초중등 1:1 화상 영어 수업'),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontWeight: FontWeight.w800,
              fontSize: widget.compact ? 22 : 28,
              height: 1.3,
              color: Palette.grey900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            tr(context, JuniorCurriculumContent.description),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 15,
              height: 1.55,
              color: Palette.grey700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '${tr(context, '주 2회')} ${JuniorOffer.twiceAWeek.priceLabel(quarter: false)} · ${tr(context, '주 3회')} ${JuniorOffer.threeTimesAWeek.priceLabel(quarter: false)}',
            style: TextStyle(
              fontFamily: 'Jalnan',
              fontSize: widget.compact ? 16 : 20,
              color: _orange,
              height: 1.4,
            ),
          ),
          SizedBox(height: 4),
          Text(
            tr(context, '교재 포함'),
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 13,
              color: Palette.grey500,
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: _openPrograms,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              tr(context, '내용 보기'),
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Palette.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shot({
    required String asset,
    required String label,
    required Color badge,
    required BoxFit fit,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Palette.white,
            child: Image.asset(asset, fit: fit),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badge,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tr(context, label),
                  style: TextStyle(
                    fontFamily: 'Jalnan',
                    fontSize: 13,
                    color: Palette.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _programs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, '세부 프로그램'),
          style: TextStyle(
            fontFamily: 'Jalnan',
            fontSize: 15,
            color: Palette.secondaryDark,
          ),
        ),
        SizedBox(height: 8),
        Text(
          tr(context, JuniorCurriculumContent.description),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 14,
            height: 1.55,
            color: Palette.black,
          ),
        ),
        SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _termChip(label: '1개월', quarter: false),
            _termChip(label: '3개월', quarter: true),
          ],
        ),
        SizedBox(height: 14),
        widget.compact
            ? Column(
                children: [
                  for (final offer in JuniorOffer.all) ...[
                    _offerCard(offer),
                    SizedBox(height: 12),
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < JuniorOffer.all.length; i++) ...[
                    if (i > 0) SizedBox(width: 12),
                    Expanded(child: _offerCard(JuniorOffer.all[i])),
                  ],
                ],
              ),
      ],
    );
  }

  Widget _termChip({required String label, required bool quarter}) {
    final selected = _quarter == quarter;
    return ChoiceChip(
      label: Text(
        tr(context, label),
        style: TextStyle(
          fontFamily: 'NotoSansKR',
          fontWeight: FontWeight.w700,
          color: selected ? Palette.white : Palette.grey800,
        ),
      ),
      selected: selected,
      selectedColor: _orange,
      backgroundColor: Palette.white,
      side: BorderSide(color: selected ? _orange : Palette.grey300),
      onSelected: (_) => setState(() => _quarter = quarter),
    );
  }

  Widget _offerCard(JuniorOffer offer) {
    final selected = _offer.id == offer.id;
    final sessions = offer.sessions(quarter: _quarter);
    final price = offer.priceLabel(quarter: _quarter);
    return Material(
      color: selected ? _orange.withValues(alpha: 0.06) : Palette.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _offer = offer),
        child: Ink(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _orange : Palette.grey200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, offer.frequencyLabel),
                style: TextStyle(
                  fontFamily: 'Jalnan',
                  fontSize: 16,
                  color: Palette.grey900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                _quarter
                    ? tf(context, '3개월 동안 {p0}회 수업입니다.', {'p0': sessions})
                    : tf(context, '한 달에 {p0}회 수업입니다.', {'p0': sessions}),
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  height: 1.4,
                  color: Palette.grey600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                price,
                style: TextStyle(
                  fontFamily: 'Jalnan',
                  fontSize: 22,
                  color: _orange,
                ),
              ),
              if (_quarter) ...[
                SizedBox(height: 4),
                Text(
                  tf(context, '정가 {p0}에서 5% 할인', {
                    'p0': OnlinePlan.money(offer.quarterListPrice),
                  }),
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 12,
                    color: Palette.grey500,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Palette.grey500,
                  ),
                ),
              ],
              SizedBox(height: 8),
              Text(
                tr(context, '교재 포함'),
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 12,
                  color: Palette.grey500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
