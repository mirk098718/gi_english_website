import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/TalkTopics.dart';
import 'package:gi_english_website/widget/TalkTopicBoard.dart';

void main() {
  final now = DateTime.utc(2026, 11, 7, 13);

  TalkTopic topic({
    required String category,
    required String title,
    String summary =
        'A long enough English summary for a cafe conversation about this story.',
    String url = 'https://www.nytimes.com/story',
    DateTime? published,
    String source = 'The New York Times',
  }) {
    return TalkTopic(
      category: category,
      title: title,
      summary: summary,
      url: url,
      source: source,
      published: published ?? DateTime.utc(2026, 11, 6, 12),
    );
  }

  test('names cooking, beauty, and science in Korean', () {
    expect(TalkTopics.categoryKo['Cooking'], '요리');
    expect(TalkTopics.categoryKo['Beauty'], '미용');
    expect(TalkTopics.categoryKo['Science'], '과학');
    expect(
      TalkTopics.categories.indexOf('Cooking'),
      lessThan(TalkTopics.categories.indexOf('Sports')),
    );
  });

  test('drops politics, religion, and death', () {
    expect(
      TalkTopics.isSensitive(
        'Religious guesthouses welcome travelers of any faith',
      ),
      isTrue,
    );
    expect(
      TalkTopics.isSensitive(
        'Scientists elected to Congress push back on Trump',
      ),
      isTrue,
    );
    expect(
      TalkTopics.isSensitive('The cruise died anyway after soaring costs'),
      isTrue,
    );
    expect(
      TalkTopics.isSensitive(
        'Federal officials plan to ground floppy disks in air traffic towers',
      ),
      isTrue,
    );
    expect(
      TalkTopics.isSensitive("Wandering Budapest's haunted streets at night"),
      isTrue,
    );
    expect(
      TalkTopics.isSensitive(
        'Experts see how El Nino might change ski country',
      ),
      isFalse,
    );
  });

  test('keeps only the opening paragraph and the feed photo', () {
    const xml = '''
      <item>
        <title>A guesthouse carved into an Albanian tower</title>
        <link>https://www.theguardian.com/travel/kulla</link>
        <description><![CDATA[<p>In the mountains of northern Albania, a family opens a stone tower to guests who want a quiet week.</p><p>The rest of the article continues with prices, trains and a long itinerary that stays on the newspaper page.</p>]]></description>
        <pubDate>Sat, 07 Nov 2026 08:00:00 GMT</pubDate>
        <media:content width="140" url="https://i.guim.co.uk/img/media/example.jpg?width=140&amp;s=aaa"/>
        <media:content width="700" url="https://i.guim.co.uk/img/media/example.jpg?width=700&amp;s=bbb"/>
      </item>
    ''';
    final parsed = TalkTopics.parseRss(
      xml,
      category: 'Travel',
      source: 'The Guardian',
    );
    expect(parsed, hasLength(1));
    expect(parsed.single.summary, contains('northern Albania'));
    expect(parsed.single.summary, isNot(contains('itinerary')));

    final escaped = TalkTopics.lead(
      '&lt;p&gt;A family opens a stone tower to weekend guests.&lt;/p&gt;&lt;p&gt;The later itinerary stays on the newspaper page.&lt;/p&gt;',
    );
    expect(escaped, 'A family opens a stone tower to weekend guests.');
    expect(
      TalkTopics.isEligible(
        topic(
          category: 'Sports',
          title: 'Leeds United v Tottenham Hotspur: Premier League – live',
        ),
        DateTime.utc(2026, 11, 7, 12),
      ),
      isFalse,
    );
    expect(
      parsed.single.imageUrl,
      'https://i.guim.co.uk/img/media/example.jpg?width=700&s=bbb',
    );
  });

  test('parses an RSS item and keeps the newest safe story in each field', () {
    const xml = '''
      <rss><channel>
        <item>
          <title>What Does the Super El Ni&#241;o Mean for Ski Season?</title>
          <link>https://www.nytimes.com/ski</link>
          <description><![CDATA[The climate event is predicted to alter snowfall patterns across ski country.]]></description>
          <pubDate>Fri, 06 Nov 2026 10:00:32 +0000</pubDate>
        </item>
        <item>
          <title>NYC Religious Guesthouses</title>
          <link>https://www.nytimes.com/faith</link>
          <description>These five properties welcome budget travelers of any faith this week.</description>
          <pubDate>Thu, 05 Nov 2026 10:00:35 +0000</pubDate>
        </item>
      </channel></rss>
    ''';
    final parsed = TalkTopics.parseRss(
      xml,
      category: 'Travel',
      source: 'The New York Times',
    );
    expect(parsed, hasLength(2));
    expect(parsed.first.title, contains('Niño'));
    expect(parsed.first.published, DateTime.utc(2026, 11, 6, 10, 0, 32));

    final picked = TalkTopics.select([
      ...parsed,
      topic(
        category: 'Society',
        title: 'Someone From Your Past Wants to Reconnect. What Now?',
        url: 'https://www.nytimes.com/reconnect',
      ),
      topic(
        category: 'Society',
        title: 'These Newly Elected Lawmakers Know Science',
        summary:
            'Democratic lawmakers are preparing to push back on research cuts.',
        url: 'https://www.nytimes.com/election',
        published: DateTime.utc(2026, 11, 6, 21),
      ),
      topic(
        category: 'Entertainment',
        title: '11 Songs We Are Talking About',
        url: 'https://www.nytimes.com/songs',
        published: DateTime.utc(2026, 11, 7, 10),
      ),
      topic(
        category: 'Entertainment',
        title: 'The Nutcracker, Now in Virtual Reality',
        url: 'https://www.nytimes.com/nutcracker',
        published: DateTime.utc(2026, 11, 6, 18),
      ),
      topic(
        category: 'Sports',
        title: 'Doncic scores 53 as the Lakers roll',
        url: 'https://www.espn.com/doncic',
        source: 'ESPN',
        published: DateTime.utc(2026, 11, 7, 12, 38, 7),
      ),
      topic(
        category: 'Sports',
        title: 'Sources: Colts engaged in trade talks',
        url: 'https://www.espn.com/trade',
        source: 'ESPN',
        published: DateTime.utc(2026, 11, 7, 12, 38, 7),
      ),
      topic(
        category: 'Sports',
        title: 'Premier League live updates from Leeds',
        summary:
            'Another weekend of European soccer is underway with several matches.',
        url: 'https://www.espn.com/live',
        source: 'ESPN',
        published: DateTime.utc(2026, 11, 7, 12, 50),
      ),
      topic(
        category: 'Travel',
        title: 'An old hotel story',
        url: 'https://www.nytimes.com/old',
        published: DateTime.utc(2026, 10, 20),
      ),
    ], now);

    expect(picked.map((item) => item.category).toList(), [
      'Travel',
      'Society',
      'Entertainment',
      'Sports',
    ]);
    expect(picked[0].url, 'https://www.nytimes.com/ski');
    expect(picked[1].url, 'https://www.nytimes.com/reconnect');
    expect(picked[2].title, contains('Songs'));
    expect(picked[3].url, 'https://www.espn.com/doncic');
  });

  test('reads an Eastern Time stamp as UTC', () {
    expect(
      TalkTopics.parseRssDate('Sat, 7 Nov 2026 07:38:07 EST'),
      DateTime.utc(2026, 11, 7, 12, 38, 7),
    );
  });

  testWidgets('분야를 누르면 그 영어 기사를 보여 준다', (tester) async {
    final topics = [
      topic(
        category: 'Travel',
        title: 'Ski season is changing',
        url: 'https://www.nytimes.com/ski',
      ),
      topic(
        category: 'Sports',
        title: 'Doncic scores 53',
        summary:
            'Luka Doncic poured in a season-high 53 points for the Lakers.',
        url: 'https://www.espn.com/doncic',
        source: 'ESPN',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TalkTopicBoard(compact: false, topics: topics)),
      ),
    );

    expect(find.text('오늘의 추천 Conversation 주제들!'), findsOneWidget);
    expect(find.text('Ski season is changing'), findsOneWidget);
    expect(find.text('Doncic scores 53'), findsNothing);

    await tester.tap(find.text('Sports'));
    await tester.pump();

    expect(find.text('Doncic scores 53'), findsOneWidget);
    expect(
      find.text(
        'Luka Doncic poured in a season-high 53 points for the Lakers.',
      ),
      findsOneWidget,
    );
    expect(find.text('전체 기사 읽기'), findsOneWidget);
    expect(find.text('Ski season is changing'), findsNothing);

    await tester.tap(find.byTooltip('이전 분야'));
    await tester.pump();
    expect(find.text('Ski season is changing'), findsOneWidget);
  });
}
