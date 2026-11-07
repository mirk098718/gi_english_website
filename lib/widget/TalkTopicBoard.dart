import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/TalkTopicLookup.dart';
import 'package:gi_english_website/util/TalkTopics.dart';
import 'package:gi_english_website/util/UrlIUtil.dart';
import 'package:gi_english_website/widget/topic_photo.dart';

class TalkTopicBoard extends StatefulWidget {
  final bool compact;
  final List<TalkTopic>? topics;

  const TalkTopicBoard({Key? key, required this.compact, this.topics})
    : super(key: key);

  @override
  State<TalkTopicBoard> createState() => _TalkTopicBoardState();
}

class _TalkTopicBoardState extends State<TalkTopicBoard> {
  List<TalkTopic>? _topics;
  var _loading = false;
  var _failed = false;
  var _selected = 0;

  @override
  void initState() {
    super.initState();
    if (widget.topics != null) {
      _topics = widget.topics;
      return;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final topics = await TalkTopicLookup.load();
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _selected = 0;
        _loading = false;
        _failed = topics.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _move(int delta) {
    final topics = _topics;
    if (topics == null || topics.isEmpty) return;
    setState(() {
      _selected = (_selected + delta) % topics.length;
      if (_selected < 0) _selected += topics.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topics = _topics;
    return Container(
      width: double.infinity,
      color: Palette.talkCream,
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 20 : 56,
        widget.compact ? 8 : 4,
        widget.compact ? 20 : 56,
        widget.compact ? 22 : 28,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 추천 Conversation 주제들!',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w800,
                  fontSize: widget.compact ? 18 : 22,
                  height: 1.35,
                  color: Palette.talkInk,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '정치·종교처럼 민감한 뉴스는 빼 두었어요. 카드에는 신문의 영어 첫 문단과 사진을 보여 주고, 전문은 로그인 없이 열리는 기사로 연결해요.',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  height: 1.4,
                  color: Palette.grey600,
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const _StatusLine('오늘의 주제를 불러오는 중이에요.')
              else if (_failed || topics == null || topics.isEmpty)
                _StatusLine(
                  '지금 기사를 불러오지 못했어요.',
                  onRetry: widget.topics == null ? _load : null,
                )
              else ...[
                SizedBox(
                  height: widget.compact ? 62 : 68,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: topics.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return _CategoryTab(
                        label: topic.category,
                        korean: TalkTopics.categoryKo[topic.category] ?? '',
                        selected: index == _selected,
                        onTap: () => setState(() => _selected = index),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _ArticlePanel(
                  topic: topics[_selected.clamp(0, topics.length - 1).toInt()],
                  compact: widget.compact,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: '이전 분야',
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.chevron_left),
                      color: Palette.talkCoralDark,
                    ),
                    IconButton(
                      tooltip: '다음 분야',
                      onPressed: () => _move(1),
                      icon: const Icon(Icons.chevron_right),
                      color: Palette.talkCoralDark,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final String korean;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.korean,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Palette.white : Palette.talkInk;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label $korean',
      child: Material(
        color: selected ? Palette.talkCoral : Palette.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minWidth: 132),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Palette.talkCoral
                    : Palette.talkCoral.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  korean,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 11,
                    color: selected
                        ? Palette.white.withValues(alpha: 0.9)
                        : Palette.grey600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArticlePanel extends StatelessWidget {
  final TalkTopic topic;
  final bool compact;

  const _ArticlePanel({required this.topic, required this.compact});

  @override
  Widget build(BuildContext context) {
    final kst = topic.published.toUtc().add(const Duration(hours: 9));
    final photoWidth = compact ? 96.0 : 168.0;
    final photoHeight = compact ? 72.0 : 96.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.talkCoral.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (topic.imageUrl.isNotEmpty) ...[
            topicPhoto(topic.imageUrl, width: photoWidth, height: photoHeight),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${topic.source}  ·  ${kst.month}월 ${kst.day}일',
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Palette.talkCoralDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1.3,
                    color: Palette.talkInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 13,
                    height: 1.35,
                    color: Palette.talkInk,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => UrlUtil.open(topic.url),
                    style: TextButton.styleFrom(
                      foregroundColor: Palette.talkCoralDark,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text(
                      '전체 기사 읽기',
                      style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _StatusLine(this.message, {this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'NotoSansKR',
              fontSize: 14,
              color: Palette.grey700,
            ),
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(width: 8),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ],
    );
  }
}
