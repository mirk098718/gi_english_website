import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineNativeTeacher.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 수강생이 메인 원어민 강사를 고르거나, 코티처로 본 선생님을 메인으로 고정한다.
class MainTeacherChange {
  static Future<bool> pick(
    BuildContext context, {
    String currentUid = '',
  }) async {
    final teachers = await AuthService.selectableNativeTeachers(
      kind: TeacherPickKind.checkout,
    );
    final assigned = currentUid.trim();
    final choices = teachers.where((teacher) {
      if (teacher.accountUid.trim().isEmpty) return false;
      if (teacher.id.trim().isEmpty || teacher.name.trim().isEmpty) return false;
      if (assigned.isNotEmpty && teacher.accountUid == assigned) return false;
      return true;
    }).toList();
    if (!context.mounted) return false;
    if (choices.isEmpty) {
      _snack(
        context,
        '지금은 메인 강사로 고를 수 있는 선생님이 없습니다.',
        Palette.grey700,
      );
      return false;
    }
    final selected = await showDialog<OnlineNativeTeacher>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, '메인 강사 변경'),
            style: TextStyle(fontFamily: 'Jalnan', fontSize: 16)),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: choices.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, index) {
              final teacher = choices[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                leading: ClipOval(child: teacher.photo(width: 44, height: 44)),
                title: Text(teacher.name,
                    style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontWeight: FontWeight.w700)),
                subtitle: Text(
                  teacher.nationality.trim().isEmpty
                      ? tr(context, '앞으로 새 예약은 이 선생님 일정으로 열립니다.')
                      : teacher.nationality,
                  style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 12,
                      color: Palette.grey600),
                ),
                onTap: () => Navigator.pop(dialogContext, teacher),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr(context, '취소'),
                style: TextStyle(fontFamily: 'NotoSansKR')),
          ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return false;
    return pin(context, selected);
  }

  static Future<bool> pin(
    BuildContext context,
    OnlineNativeTeacher teacher,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(teacher.name,
            style: TextStyle(fontFamily: 'Jalnan', fontSize: 16)),
        content: Text(
          tr(context,
              '이 선생님을 메인 강사로 고정할까요?\n앞으로 새 예약은 이 선생님 일정으로 열립니다. 이미 예약된 수업은 예약한 선생님 그대로 진행됩니다.'),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, '취소'),
                style: TextStyle(fontFamily: 'NotoSansKR')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.secondaryDark,
              foregroundColor: Palette.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(context, '메인 강사로 고정'),
                style: TextStyle(fontFamily: 'NotoSansKR')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;
    final error = await AuthService.setMyMainTeacher(teacher);
    if (!context.mounted) return false;
    if (error != null) {
      _snack(context, error, Palette.accent);
      return false;
    }
    _snack(context, '메인 강사를 바꿨습니다.', Palette.secondaryDark);
    return true;
  }

  static void _snack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, message),
            style: TextStyle(fontFamily: 'NotoSansKR')),
        backgroundColor: color,
      ),
    );
  }
}
