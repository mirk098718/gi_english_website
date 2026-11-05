import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/Palette.dart';

class ProfileAvatar extends StatelessWidget {
  final String photoUrl;
  final Uint8List? bytes;
  final String label;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  const ProfileAvatar({
    Key? key,
    this.photoUrl = '',
    this.bytes,
    this.label = '',
    this.size = 48,
    this.backgroundColor = Palette.navy,
    this.foregroundColor = Palette.white,
  }) : super(key: key);

  factory ProfileAvatar.fromData(
    Map<String, dynamic>? data, {
    Key? key,
    double size = 48,
    Color backgroundColor = Palette.navy,
    Color foregroundColor = Palette.white,
    String fallback = '',
  }) {
    return ProfileAvatar(
      key: key,
      photoUrl: AuthService.profilePhotoUrl(data),
      label: AuthService.profileDisplayName(data, fallback: fallback),
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = OnlineNativeTeacher.imageProviderOf(photoUrl, bytes);
    final initial = AuthService.profileInitial(label);
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        alignment: Alignment.center,
        child: provider == null
            ? _initial(initial)
            : Image(
                image: provider,
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _initial(initial),
              ),
      ),
    );
  }

  Widget _initial(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: "NotoSansKR",
        fontWeight: FontWeight.w700,
        fontSize: size * 0.38,
        color: foregroundColor,
      ),
    );
  }
}
