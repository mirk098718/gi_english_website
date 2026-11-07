import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

final _viewTypes = <String, String>{};

Widget topicPhoto(String url) {
  final viewType = _viewTypes.putIfAbsent(url, () {
    final type = 'talk-photo-${_viewTypes.length}';
    ui_web.platformViewRegistry.registerViewFactory(type, (int viewId) {
      return html.ImageElement()
        ..src = url
        ..alt = ''
        ..setAttribute('aria-hidden', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.display = 'block';
    });
    return type;
  });
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      height: 210,
      width: double.infinity,
      child: HtmlElementView(viewType: viewType),
    ),
  );
}
