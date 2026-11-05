import 'package:flutter/material.dart';
import 'package:gi_english_website/util/DailyWord.dart';
import 'package:gi_english_website/util/DailyWordLookup.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';

/// 학원 홈과 온라인 홈의 히어로 바로 아래에 두는 오늘의 단어.
class HomeDailyWordBlock extends StatefulWidget {
  final bool compact;
  final DateTime? date;
  final DailyWord? word;

  const HomeDailyWordBlock({
    Key? key,
    this.compact = false,
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

  @override
  Widget build(BuildContext context) {
    final today = widget.date ?? DateTime.now();
    final word = _word;
    final compact = widget.compact;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071526),
            Color(0xFF0B3A4A),
            Color(0xFF0F766E),
          ],
          stops: [0.0, 0.55, 1.0],
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
                color: Palette.talkMango.withValues(alpha: 0.16),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 20 : 48,
              compact ? 22 : 28,
              compact ? 20 : 48,
              compact ? 22 : 28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Palette.talkMango,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: compact ? 14 : 16),
                    word == null
                        ? Text(
                            '오늘의 단어를 준비하고 있습니다.',
                            style: TextStyle(
                              fontFamily: 'NotoSansKR',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Palette.white,
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
    );
  }

  Widget _body(DateTime today, DailyWord word) {
    final compact = widget.compact;
    final wordSide = _wordSide(today, word);
    final expressionSide = _expressionCard(word);
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = !compact && constraints.maxWidth >= 860;
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
    final compact = widget.compact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${today.month}월 ${today.day}일 · 오늘의 단어',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
            color: Palette.talkMango,
            letterSpacing: 0.4,
          ),
        ),
        SizedBox(height: 8),
        Text(
          word.word,
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: compact ? 40 : 56,
            fontWeight: FontWeight.w800,
            color: Palette.white,
            height: 1.05,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            word.meaning,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w800,
              color: Palette.navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _expressionCard(DailyWord word) {
    final compact = widget.compact;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 22,
        compact ? 16 : 20,
        compact ? 16 : 22,
        compact ? 16 : 18,
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
                  fontSize: 28,
                  height: 0.8,
                  fontWeight: FontWeight.w800,
                  color: Palette.darkTeal,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '오늘의 표현',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w800,
                  color: Palette.darkTeal,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            word.expression,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.w800,
              height: 1.45,
              color: Palette.navy,
            ),
          ),
          if (word.expressionMeaning.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              word.expressionMeaning,
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: compact ? 14 : 15,
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
                '출처: 영어 위키낱말사전',
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
