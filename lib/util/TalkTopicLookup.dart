import 'package:cloud_functions/cloud_functions.dart';
import 'package:gi_english_website/util/TalkTopics.dart';

class TalkTopicLookup {
  static Future<List<TalkTopic>> load({DateTime? now}) async {
    final callable = FirebaseFunctions.instanceFor(
      region: 'asia-northeast3',
    ).httpsCallable('talkConversationTopics');
    final result = await callable.call();
    final data = Map<String, dynamic>.from(result.data as Map);
    final rawItems = data['items'];
    if (rawItems is! List) return const [];
    final topics = <TalkTopic>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final published = TalkTopics.parseRssDate('${item['pubDate'] ?? ''}');
      if (published == null) continue;
      topics.add(
        TalkTopic(
          category: '${item['category'] ?? ''}',
          title: '${item['title'] ?? ''}',
          summary: TalkTopics.lead('${item['description'] ?? ''}'),
          url: '${item['url'] ?? ''}',
          source: '${item['source'] ?? ''}',
          published: published,
          imageUrl: '${item['imageUrl'] ?? ''}',
        ),
      );
    }
    return TalkTopics.select(topics, now ?? DateTime.now());
  }
}
