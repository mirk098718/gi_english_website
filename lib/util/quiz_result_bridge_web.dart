import 'dart:html' as html;
import 'dart:js_util' as js;

import 'package:gi_english_website/class/QuizResult.dart';
import 'package:gi_english_website/util/QuizResultService.dart';

void startQuizResultBridge(void Function() onSaved) {
  html.window.onMessage.listen((html.MessageEvent event) async {
    if (event.origin != html.window.location.origin) return;
    final data = _asMap(_normalize(event.data));
    if (data == null || data['type'] != 'gleam-quiz-result') return;
    final payload = _asMap(data['payload']);
    final source = event.source;
    if (payload == null) {
      _reply(source, event.origin, 'gleam-quiz-save-failed');
      return;
    }
    final request = QuizSaveRequest.tryParse(payload);
    if (request == null) {
      _reply(source, event.origin, 'gleam-quiz-save-failed');
      return;
    }
    try {
      await QuizResultService.saveLatest(request);
      _reply(source, event.origin, 'gleam-quiz-saved');
      onSaved();
    } catch (_) {
      _reply(source, event.origin, 'gleam-quiz-save-failed');
    }
  });
}

void _reply(html.EventTarget? source, String origin, String type) {
  if (source is! html.WindowBase) return;
  source.postMessage({'type': type}, origin);
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

Object? _normalize(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }
  if (value is List) return value.map(_normalize).toList();
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), _normalize(item)));
  }
  try {
    final keys = List<Object?>.from(js.objectKeys(value));
    final isArray = keys.isNotEmpty && keys.every((key) => int.tryParse('$key') != null);
    if (isArray) {
      final items = <Object?>[];
      for (final key in keys) {
        items.add(_normalize(js.getProperty(value, key.toString())));
      }
      return items;
    }
    final map = <String, dynamic>{};
    for (final key in keys) {
      final name = key.toString();
      map[name] = _normalize(js.getProperty(value, name));
    }
    return map;
  } catch (_) {
    return value;
  }
}
