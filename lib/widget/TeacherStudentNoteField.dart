import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AppLanguage.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/TeacherStudentNoteService.dart';

/// 강사가 학생마다 남기는 간단 정보.
class TeacherStudentNoteField extends StatefulWidget {
  final String teacherId;
  final String studentId;
  final String initialNote;
  final bool enabled;
  final ValueChanged<String>? onSaved;

  const TeacherStudentNoteField({
    Key? key,
    required this.teacherId,
    required this.studentId,
    this.initialNote = '',
    this.enabled = true,
    this.onSaved,
  }) : super(key: key);

  @override
  State<TeacherStudentNoteField> createState() => _TeacherStudentNoteFieldState();
}

class _TeacherStudentNoteFieldState extends State<TeacherStudentNoteField> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void didUpdateWidget(covariant TeacherStudentNoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialNote != widget.initialNote &&
        _controller.text != widget.initialNote) {
      _controller.text = widget.initialNote;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!widget.enabled || _saving) return;
    setState(() => _saving = true);
    final error = await TeacherStudentNoteService.save(
      teacherId: widget.teacherId,
      studentId: widget.studentId,
      note: _controller.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, error), style: TextStyle(fontFamily: 'NotoSansKR')),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    widget.onSaved?.call(_controller.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(context, '학생 정보를 저장했습니다.'),
          style: TextStyle(fontFamily: 'NotoSansKR'),
        ),
        backgroundColor: Palette.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      final text = widget.initialNote.trim();
      if (text.isEmpty) return SizedBox.shrink();
      return Text(
        text,
        style: TextStyle(
          fontFamily: 'NotoSansKR',
          fontSize: 12,
          height: 1.45,
          color: Palette.grey700,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(context, '학생 정보'),
          style: TextStyle(
            fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Palette.grey800,
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: _controller,
          maxLines: 3,
          style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 13),
          decoration: InputDecoration(
            hintText: tr(context, '레벨·성향·주의할 점 등 간단히 적어 두세요.'),
            hintStyle: TextStyle(fontFamily: 'NotoSansKR', fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: Palette.darkTeal,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              tr(context, '학생 정보 저장'),
              style: TextStyle(fontFamily: 'NotoSansKR', fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}