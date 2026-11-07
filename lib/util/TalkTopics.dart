class TalkTopic {
  final String category;
  final String title;
  final String summary;
  final String url;
  final String source;
  final DateTime published;

  const TalkTopic({
    required this.category,
    required this.title,
    required this.summary,
    required this.url,
    required this.source,
    required this.published,
  });
}

class TalkTopics {
  static const categories = ['Travel', 'Society', 'Entertainment', 'Sports'];
  static const maxAge = Duration(hours: 72);

  static const categoryKo = {
    'Travel': '여행',
    'Society': '사회',
    'Entertainment': '연예',
    'Sports': '스포츠',
  };

  /// 정치, 종교, 전쟁, 죽음, 범죄처럼 카페에서 다루기 민감한 단어를 거른다.
  static bool isSensitive(String text) {
    final words = RegExp(
      r"[a-z0-9']+",
    ).allMatches(text.toLowerCase()).map((match) => match.group(0)!).toSet();
    const blocked = {
      'politics',
      'political',
      'election',
      'elections',
      'congress',
      'senate',
      'parliament',
      'president',
      'presidential',
      'trump',
      'biden',
      'democrat',
      'democratic',
      'republican',
      'republicans',
      'minister',
      'government',
      'federal',
      'officials',
      'campaign',
      'lawmaker',
      'lawmakers',
      'voter',
      'voters',
      'gop',
      'religion',
      'religious',
      'church',
      'mosque',
      'temple',
      'islam',
      'muslim',
      'christian',
      'jewish',
      'catholic',
      'pope',
      'faith',
      'war',
      'military',
      'missile',
      'missiles',
      'gaza',
      'ukraine',
      'israel',
      'iran',
      'hamas',
      'killed',
      'killing',
      'death',
      'died',
      'dead',
      'murder',
      'murdered',
      'shooting',
      'suicide',
      'terror',
      'terrorist',
      'bomb',
      'bombing',
      'sexual',
      'sex',
      'porn',
      'nude',
      'abuse',
      'abused',
      'rape',
      'crime',
      'criminal',
      'police',
      'prison',
      'abortion',
      'racism',
      'racist',
      'cancer',
      'pandemic',
      'haunted',
      'ghost',
      'ghosts',
      'horror',
      'holocaust',
      'genocide',
      'massacre',
    };
    if (words.any(blocked.contains)) return true;
    final lower = text.toLowerCase();
    return lower.contains('white house') || lower.contains('live updates');
  }

  static bool isEligible(TalkTopic topic, DateTime now) {
    if (topic.title.trim().isEmpty || topic.url.trim().isEmpty) return false;
    if (topic.summary.trim().length < 40) return false;
    if (!topic.url.startsWith('http')) return false;
    final age = now.toUtc().difference(topic.published.toUtc());
    if (age.isNegative && age.abs() > const Duration(hours: 6)) return false;
    if (age > maxAge) return false;
    if (RegExp(r'^sources\s*:', caseSensitive: false).hasMatch(topic.title)) {
      return false;
    }
    return !isSensitive('${topic.title} ${topic.summary}');
  }

  static List<TalkTopic> select(List<TalkTopic> candidates, DateTime now) {
    final chosen = <TalkTopic>[];
    for (final category in categories) {
      TalkTopic? best;
      for (final topic in candidates) {
        if (topic.category != category || !isEligible(topic, now)) continue;
        if (chosen.any((picked) => picked.url == topic.url)) continue;
        if (best == null || topic.published.isAfter(best.published)) {
          best = topic;
        }
      }
      if (best != null) chosen.add(best);
    }
    return chosen;
  }

  static List<TalkTopic> parseRss(
    String xml, {
    required String category,
    required String source,
  }) {
    final topics = <TalkTopic>[];
    final items = RegExp(
      r'<item\b[^>]*>([\s\S]*?)</item>',
      caseSensitive: false,
    ).allMatches(xml);
    for (final item in items) {
      final body = item.group(1) ?? '';
      final title = _clean(_tag(body, 'title'));
      final summary = _clean(_tag(body, 'description'));
      final url = _clean(_tag(body, 'link'));
      final published = parseRssDate(_tag(body, 'pubDate'));
      if (title.isEmpty || url.isEmpty || published == null) continue;
      topics.add(
        TalkTopic(
          category: category,
          title: title,
          summary: summary,
          url: url,
          source: source,
          published: published,
        ),
      );
    }
    return topics;
  }

  static DateTime? parseRssDate(String raw) {
    final match = RegExp(
      r'[A-Za-z]{3},?\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})\s+(?:([A-Z]{2,4})|([+-]\d{4}))',
    ).firstMatch(raw.trim());
    if (match == null) return null;
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final month = months[match.group(2)];
    if (month == null) return null;
    final clock = DateTime.utc(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
    final named = match.group(7);
    final numeric = match.group(8);
    final Duration offset;
    if (numeric != null) {
      final sign = numeric.startsWith('-') ? -1 : 1;
      offset =
          Duration(
            hours: int.parse(numeric.substring(1, 3)),
            minutes: int.parse(numeric.substring(3)),
          ) *
          sign;
    } else {
      const zones = {
        'EST': Duration(hours: -5),
        'EDT': Duration(hours: -4),
        'CST': Duration(hours: -6),
        'CDT': Duration(hours: -5),
        'PST': Duration(hours: -8),
        'PDT': Duration(hours: -7),
        'GMT': Duration.zero,
        'UTC': Duration.zero,
      };
      final zone = zones[named];
      if (zone == null) return null;
      offset = zone;
    }
    return clock.subtract(offset);
  }

  static String _tag(String item, String name) {
    final cdata = RegExp(
      '<$name[^>]*>\\s*<!\\[CDATA\\[([\\s\\S]*?)\\]\\]>\\s*</$name>',
      caseSensitive: false,
    ).firstMatch(item);
    if (cdata != null) return cdata.group(1) ?? '';
    final plain = RegExp(
      '<$name[^>]*>([\\s\\S]*?)</$name>',
      caseSensitive: false,
    ).firstMatch(item);
    return plain?.group(1) ?? '';
  }

  static String _clean(String raw) {
    final withoutTags = raw.replaceAll(RegExp(r'<[^>]+>'), ' ');
    final decoded = withoutTags.replaceAllMapped(
      RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z]+);'),
      (match) {
        final token = match.group(1)!;
        if (token.startsWith('#x') || token.startsWith('#X')) {
          final code = int.tryParse(token.substring(2), radix: 16);
          return code == null ? match.group(0)! : String.fromCharCode(code);
        }
        if (token.startsWith('#')) {
          final code = int.tryParse(token.substring(1));
          return code == null ? match.group(0)! : String.fromCharCode(code);
        }
        const named = {
          'amp': '&',
          'lt': '<',
          'gt': '>',
          'quot': '"',
          'apos': "'",
        };
        return named[token] ?? match.group(0)!;
      },
    );
    return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
