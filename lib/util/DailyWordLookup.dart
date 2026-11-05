import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:gi_english_website/util/DailyWord.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 자주 쓰이는 영어 9,421개 안에서 날짜마다 다음 단어를 고르고,
/// 영어 위키낱말사전(CC BY-SA 4.0)에서 뜻과 예문을 가져온다.
class DailyWordLookup {
  static const String _bankAsset = 'assets/daily_word_bank.txt';
  static List<String>? _bank;
  static final Map<String, DailyWord> _memory = {};

  static Future<DailyWord> forDate(DateTime date) async {
    final key = _cacheKey(date);
    final remembered = _memory[key];
    if (remembered != null) return remembered;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = _decode(prefs.getString(key));
      if (cached != null) {
        _memory[key] = cached;
        return cached;
      }

      final bank = await _loadBank();
      final start = DailyWord.indexFor(date, bank.length);
      for (var offset = 0; offset < 4; offset++) {
        final candidate = bank[(start + offset) % bank.length];
        final found = await _fetch(candidate);
        if (found == null) continue;
        _memory[key] = found;
        await prefs.setString(key, jsonEncode(_encode(found)));
        return found;
      }
    } catch (_) {}

    final fallback = DailyWord.forDate(date);
    _memory[key] = fallback;
    return fallback;
  }

  static String _cacheKey(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final month = day.month.toString().padLeft(2, '0');
    final dayText = day.day.toString().padLeft(2, '0');
    return 'gleam-daily-word-v2-${day.year}-$month-$dayText';
  }

  static Future<List<String>> _loadBank() async {
    final cached = _bank;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_bankAsset);
    final words = raw
        .split('\n')
        .map((line) => line.trim().toLowerCase())
        .where((line) => line.isNotEmpty)
        .toList();
    _bank = words;
    return words;
  }

  static Future<DailyWord?> _fetch(String word) async {
    final uri = Uri.https(
      'freedictionaryapi.com',
      '/api/v1/entries/en/$word',
      {'translations': 'true'},
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return null;
    return parseWiktionaryEntry(body);
  }

  static DailyWord? parseWiktionaryEntry(Map<String, dynamic> json) {
    final word = json['word']?.toString().trim() ?? '';
    if (word.isEmpty) return null;
    final entries = json['entries'];
    if (entries is! List) return null;

    DailyWord? englishOnly;
    final source = json['source'];
    final sourceUrl = source is Map ? source['url']?.toString() ?? '' : '';
    for (final entry in entries) {
      if (entry is! Map) continue;
      final senses = entry['senses'];
      if (senses is! List) continue;
      for (final sense in senses) {
        if (sense is! Map) continue;
        final example = _exampleContaining(word, sense['examples']);
        if (example == null || example.isEmpty) continue;
        final korean = _korean(sense['translations']);
        if (korean != null && korean.isNotEmpty) {
          return DailyWord(
            word: word,
            meaning: korean,
            expression: example,
            expressionMeaning: '',
            sourceUrl: sourceUrl,
          );
        }
        englishOnly ??= DailyWord(
          word: word,
          meaning: _firstString(sense['definition']) ?? word,
          expression: example,
          expressionMeaning: '',
          sourceUrl: sourceUrl,
        );
      }
    }
    return englishOnly;
  }

  static String? _exampleContaining(String word, Object? raw) {
    if (raw is! List) return null;
    final needle = word.toLowerCase();
    String? first;
    for (final item in raw) {
      final text = item?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      first ??= text;
      if (text.toLowerCase().contains(needle)) return text;
    }
    return first;
  }

  static String? _korean(Object? raw) {
    if (raw is! List) return null;
    for (final item in raw) {
      if (item is! Map) continue;
      final language = item['language'];
      final code = language is Map ? language['code']?.toString() : '';
      if (code != 'ko') continue;
      final text = item['word']?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static String? _firstString(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static Map<String, String> _encode(DailyWord word) {
    return {
      'word': word.word,
      'meaning': word.meaning,
      'expression': word.expression,
      'expressionMeaning': word.expressionMeaning,
      'sourceUrl': word.sourceUrl,
    };
  }

  static DailyWord? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is! Map) return null;
    final word = json['word']?.toString() ?? '';
    final expression = json['expression']?.toString() ?? '';
    if (word.isEmpty || expression.isEmpty) return null;
    return DailyWord(
      word: word,
      meaning: json['meaning']?.toString() ?? '',
      expression: expression,
      expressionMeaning: json['expressionMeaning']?.toString() ?? '',
      sourceUrl: json['sourceUrl']?.toString() ?? '',
    );
  }
}
