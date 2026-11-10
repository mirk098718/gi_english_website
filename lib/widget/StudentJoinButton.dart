import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 수강생 화상수업 입장 버튼.
/// 강사가 시작하기 전에는 회색으로 두고, 시작 후에만 초록으로 누를 수 있다.
class StudentJoinButton extends StatelessWidget {
  final bool enabled;
  final String label;
  final VoidCallback? onPressed;

  const StudentJoinButton({
    Key? key,
    required this.enabled,
    required this.label,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? Palette.white : Palette.grey600;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Palette.success,
        foregroundColor: Palette.white,
        disabledBackgroundColor: Palette.grey300,
        disabledForegroundColor: Palette.grey600,
        elevation: enabled ? 1 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: enabled ? onPressed : null,
      icon: Icon(Icons.login, size: 16, color: foreground),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: "Jalnan",
          color: foreground,
          fontSize: 13,
        ),
      ),
    );
  }
}
