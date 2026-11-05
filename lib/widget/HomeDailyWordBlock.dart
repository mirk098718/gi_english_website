import 'package:flutter/material.dart';
import 'package:gi_english_website/util/DailyWord.dart';
import 'package:gi_english_website/util/DailyWordLookup.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';

/// 학원 홈과 온라인 홈 아래에 두는 오늘의 단어.
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
    return Container(
      width: double.infinity,
      color: Palette.white,
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 20 : 48,
        widget.compact ? 28 : 40,
        widget.compact ? 20 : 48,
        widget.compact ? 36 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 860),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              widget.compact ? 18 : 28,
              widget.compact ? 18 : 24,
              widget.compact ? 18 : 28,
              widget.compact ? 18 : 24,
            ),
            decoration: BoxDecoration(
              color: Palette.grey50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.grey200),
            ),
            child: word == null
                ? Text(
                    '오늘의 단어를 준비하고 있습니다.',
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 14,
                      color: Palette.grey600,
                    ),
                  )
                : _card(today, word),
          ),
        ),
      ),
    );
  }

  Widget _card(DateTime today, DailyWord word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${today.month}월 ${today.day}일 · 오늘의 단어',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: widget.compact ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Palette.darkTeal,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 8),
        Text(
          word.word,
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: widget.compact ? 28 : 36,
            fontWeight: FontWeight.w800,
            color: Palette.navy,
            height: 1.15,
          ),
        ),
        SizedBox(height: 4),
        Text(
          word.meaning,
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: widget.compact ? 15 : 16,
            fontWeight: FontWeight.w600,
            color: Palette.grey700,
          ),
        ),
        SizedBox(height: widget.compact ? 16 : 20),
        Text(
          '오늘의 표현',
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: widget.compact ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Palette.darkTeal,
          ),
        ),
        SizedBox(height: 6),
        Text(
          word.expression,
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: widget.compact ? 16 : 18,
            fontWeight: FontWeight.w700,
            height: 1.45,
            color: Palette.black,
          ),
        ),
        if (word.expressionMeaning.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            word.expressionMeaning,
            style: TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: widget.compact ? 14 : 15,
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
    );
  }
}
