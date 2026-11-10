import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/DailyWord.dart';
import 'package:gi_english_website/util/DailyWordLookup.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';

enum DailyWordTone { home, talk }

/// 오늘의 단어. 홈은 남색 띠, 렛츠 토크는 코랄 띠, 내 강의실은 왼쪽 메뉴 아래 카드.
class HomeDailyWordBlock extends StatefulWidget {
  final bool compact;
  final bool sidebar;
  final DailyWordTone tone;
  final DateTime? date;
  final DailyWord? word;

  const HomeDailyWordBlock({
    Key? key,
    this.compact = false,
    this.sidebar = false,
    this.tone = DailyWordTone.home,
    this.date,
    this.word,
  }) : super(key: key);

  @override
  State<HomeDailyWordBlock> createState() => _HomeDailyWordBlockState();
}

class _HomeDailyWordBlockState extends State<HomeDailyWordBlock> {
  DailyWord? _word;

  @override
  void initState() {
    super.initState();
    final given = widget.word;
    if (given != null) {
      _word = given;
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final loaded = await DailyWordLookup.forDate(widget.date ?? DateTime.now());
    if (!mounted) return;
    setState(() => _word = loaded);
  }

  _WordLook get _look => widget.tone == DailyWordTone.talk
      ? const _WordLook.talk()
      : const _WordLook.home();

  @override
  Widget build(BuildContext context) {
    final today = widget.date ?? DateTime.now();
    final word = _word;
    final compact = widget.compact || widget.sidebar;
    final look = _look;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.sidebar ? 16 : 0),
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: look.gradient,
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: compact ? -30 : -10,
            top: compact ? -40 : -50,
            child: Container(
              width: compact ? 160 : 240,
              height: compact ? 160 : 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: look.blob,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              widget.sidebar ? 14 : (compact ? 20 : 48),
              widget.sidebar ? 14 : (compact ? 22 : 28),
              widget.sidebar ? 14 : (compact ? 20 : 48),
              widget.sidebar ? 14 : (compact ? 22 : 28),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: widget.sidebar ? 36 : 72,
                      height: 4,
                      decoration: BoxDecoration(
                        color: look.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: compact ? 14 : 16),
                    word == null
                        ? Text(
                            tr(context, "오늘의 단어를 준비하고 있습니다."),
                            style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: look.word,
                            ),
                          )
                        : _body(today, word),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _body(DateTime today, DailyWord word) {
    final compact = widget.compact || widget.sidebar;
    final wordSide = _wordSide(today, word);
    final expressionSide = _expressionCard(word);
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide =
            !widget.sidebar && !compact && constraints.maxWidth >= 860;
        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wordSide,
              SizedBox(height: 16),
              expressionSide,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 5, child: wordSide),
            SizedBox(width: 28),
            Expanded(flex: 6, child: expressionSide),
          ],
        );
      },
    );
  }

  Widget _wordSide(DateTime today, DailyWord word) {
    final look = _look;
    final sidebar = widget.sidebar;
    final compact = widget.compact || sidebar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.instance.isEnglish
              ? '${_enMonth(today.month)} ${today.day} · ${tr(context, '오늘의 단어')}'
              : '${today.month}월 ${today.day}일 · ${tr(context, '오늘의 단어')}',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: sidebar ? 11 : (compact ? 13 : 14),
            fontWeight: FontWeight.w700,
            color: look.accent,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: sidebar ? 6 : 8),
        Text(
          word.word,
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: sidebar ? 28 : (compact ? 40 : 56),
            fontWeight: FontWeight.w800,
            color: look.word,
            height: 1.05,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: sidebar ? 8 : 12),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: sidebar ? 10 : 12,
            vertical: sidebar ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: look.meaningFill,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            word.meaning,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: sidebar ? 12 : (compact ? 14 : 16),
              fontWeight: FontWeight.w800,
              color: look.meaningText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _expressionCard(DailyWord word) {
    final look = _look;
    final sidebar = widget.sidebar;
    final compact = widget.compact || sidebar;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        sidebar ? 12 : (compact ? 16 : 22),
        sidebar ? 12 : (compact ? 16 : 20),
        sidebar ? 12 : (compact ? 16 : 22),
        sidebar ? 12 : (compact ? 16 : 18),
      ),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '“',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: sidebar ? 22 : 28,
                  height: 0.8,
                  fontWeight: FontWeight.w800,
                  color: look.quote,
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                tr(context, "오늘의 표현"),
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: sidebar ? 12 : (compact ? 13 : 14),
                  fontWeight: FontWeight.w800,
                  color: look.quote,
                ),
              ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            word.expression,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: sidebar ? 13 : (compact ? 16 : 20),
              fontWeight: FontWeight.w800,
              height: 1.45,
              color: look.expression,
            ),
          ),
          if (word.expressionMeaning.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              word.expressionMeaning,
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: sidebar ? 12 : (compact ? 14 : 15),
                height: 1.5,
                color: Palette.grey600,
              ),
            ),
          ],
          if (word.sourceUrl.isNotEmpty) ...[
            SizedBox(height: 12),
            InkWell(
              onTap: () => UrlUtil.open(word.sourceUrl),
              child: Text(
                tr(context, "출처: 영어 위키낱말사전"),
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 12,
                  color: Palette.grey500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WordLook {
  final List<Color> gradient;
  final Color accent;
  final Color blob;
  final Color word;
  final Color meaningFill;
  final Color meaningText;
  final Color quote;
  final Color expression;

  const _WordLook({
    required this.gradient,
    required this.accent,
    required this.blob,
    required this.word,
    required this.meaningFill,
    required this.meaningText,
    required this.quote,
    required this.expression,
  });

  const _WordLook.home()
      : gradient = const [
          Color(0xFF071526),
          Color(0xFF0B3A4A),
          Color(0xFF0F766E),
        ],
        accent = Palette.talkMango,
        blob = const Color(0x29FFB020),
        word = Palette.white,
        meaningFill = Palette.white,
        meaningText = Palette.navy,
        quote = Palette.darkTeal,
        expression = Palette.navy;

  const _WordLook.talk()
      : gradient = const [
          Color(0xFFE23B55),
          Color(0xFFFF5B6B),
          Color(0xFFFF7A45),
        ],
        accent = Palette.talkCream,
        blob = const Color(0x33FFFFFF),
        word = Palette.white,
        meaningFill = Palette.talkCream,
        meaningText = Palette.talkCoralDark,
        quote = Palette.talkCoralDark,
        expression = Palette.talkInk;
}

const _enMonths = [
  '',
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _enMonth(int month) => _enMonths[month];
