import 'package:flutter/material.dart';

Widget topicPhoto(String url, {required double width, required double height}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    ),
  );
}
