import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gi_english_website/util/TalkTopics.dart';
import 'package:http/http.dart' as http;

class TalkTopicLookup {
  static const _feeds = [
    _Feed(
      'https://rss.nytimes.com/services/xml/rss/nyt/Travel.xml',
      'Travel',
      'The New York Times',
    ),
    _Feed(
      'https://rss.nytimes.com/services/xml/rss/nyt/Well.xml',
      'Society',
      'The New York Times',
    ),
    _Feed(
      'https://rss.nytimes.com/services/xml/rss/nyt/DiningandWine.xml',
      'Society',
      'The New York Times',
    ),
    _Feed(
      'https://rss.nytimes.com/services/xml/rss/nyt/Arts.xml',
      'Entertainment',
      'The New York Times',
    ),
    _Feed(
      'https://rss.nytimes.com/services/xml/rss/nyt/Movies.xml',
      'Entertainment',
      'The New York Times',
    ),
    _Feed(
      'https://rss.nytimes.com/services/xml/rss/nyt/Music.xml',
      'Entertainment',
      'The New York Times',
    ),
    _Feed('https://www.espn.com/espn/rss/news', 'Sports', 'ESPN'),
  ];

  static Future<List<TalkTopic>> load({
    DateTime? now,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final ownsClient = client == null;
    try {
      final batches = await Future.wait(
        _feeds.map((feed) => _read(httpClient, feed)),
      );
      return TalkTopics.select([
        for (final batch in batches) ...batch,
      ], now ?? DateTime.now());
    } finally {
      if (ownsClient) httpClient.close();
    }
  }

  static Future<List<TalkTopic>> _read(http.Client client, _Feed feed) async {
    try {
      final response = await client
          .get(
            Uri.parse(feed.url),
            headers: kIsWeb
                ? const {
                    'Accept': 'application/rss+xml, application/xml, text/xml',
                  }
                : const {
                    'Accept': 'application/rss+xml, application/xml, text/xml',
                    'User-Agent': 'GleamIslandTalk/1.0',
                  },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      return TalkTopics.parseRss(
        utf8.decode(response.bodyBytes),
        category: feed.category,
        source: feed.source,
      );
    } catch (_) {
      return const [];
    }
  }
}

class _Feed {
  final String url;
  final String category;
  final String source;

  const _Feed(this.url, this.category, this.source);
}
