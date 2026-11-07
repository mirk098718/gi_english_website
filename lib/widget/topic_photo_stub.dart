import 'package:flutter/material.dart';

Widget topicPhoto(String url) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.network(
      url,
      height: 210,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    ),
  );
}
