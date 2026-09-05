import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlineCourse.dart';
import 'package:gi_english_website/util/EnrollmentService.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 과정별 주간 학습(인강 · 문제 링크 · 체크리스트) 등록.
class AdminWeekCurriculumTab extends StatefulWidget {
  @override
  _AdminWeekCurriculumTabState createState() => _AdminWeekCurriculumTabState();
}

class _AdminWeekCurriculumTabState extends State<AdminWeekCurriculumTab> {
  OnlineCourse _selectedCourse = OnlineCourse.all.first;
  List<OnlineWeek> _weeks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
    });
    final weeks = await EnrollmentService.weeks(_selectedCourse.id);
    if (!mounted) return;
    setState(() {
      _weeks = weeks;
      _loading = false;
    });
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  Future<void> _openEditor({OnlineWeek? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WeekEditorDialog(
        course: _selectedCourse,
        existing: existing,
      ),
    );
    if (saved == true) {
      _toast(existing == null ? '주차가 등록되었습니다.' : '주차가 수정되었습니다.');
      await _refresh();
    }
  }

  Future<void> _delete(OnlineWeek week) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${week.weekNumber}주차 삭제',
            style: TextStyle(fontFamily: "Jalnan")),
        content: Text(
          '이 주차의 인강·문제 링크·체크리스트가 삭제됩니다.\n학생들의 체크 기록은 남아 있을 수 있습니다.',
          style: TextStyle(fontFamily: "NotoSansKR"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제', style: TextStyle(color: Palette.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await EnrollmentService.deleteWeek(week.id);
    if (error != null) {
      _toast(error, error: true);
    } else {
      _toast('삭제되었습니다.');
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        Text('과정 선택', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        SizedBox(height: 8),
        DropdownButtonFormField<OnlineCourse>(
          initialValue: _selectedCourse,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Palette.white,
          ),
          items: OnlineCourse.all
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.order}. ${c.title}',
                        style: TextStyle(fontFamily: "NotoSansKR")),
                  ))
              .toList(),
          onChanged: (value) async {
            if (value == null) return;
            setState(() {
              _selectedCourse = value;
            });
            await _refresh();
          },
        ),
        SizedBox(height: 12),
        Text(
          '각 주차에 인강 URL, 문제풀이 링크, 학생이 스스로 체크할 학습 항목을 넣습니다.\n'
          '회원은 수강 시작일 기준으로 “이번 주”가 강조되고, 이전 주차도 복습할 수 있습니다.',
          style: TextStyle(
              fontFamily: "NotoSansKR", fontSize: 13, color: Palette.grey600),
        ),
        SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.secondaryDark,
              foregroundColor: Palette.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onPressed: () => _openEditor(),
            icon: Icon(Icons.add),
            label: Text('주차 추가', style: TextStyle(fontFamily: "Jalnan")),
          ),
        ),
        Divider(height: 36),
        Text('등록된 주차', style: TextStyle(fontFamily: "Jalnan", fontSize: 16)),
        SizedBox(height: 12),
        if (_loading)
          Center(child: CircularProgressIndicator())
        else if (_weeks.isEmpty)
          Text('등록된 주차가 없습니다. 1주차부터 추가해주세요.',
              style:
                  TextStyle(fontFamily: "NotoSansKR", color: Palette.grey500))
        else
          ..._weeks.map((week) => Card(
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Palette.secondaryDark,
                    child: Text('${week.weekNumber}',
                        style: TextStyle(
                            fontFamily: "Jalnan",
                            color: Palette.white,
                            fontSize: 13)),
                  ),
                  title: Text(
                    week.title.isEmpty ? '${week.weekNumber}주차' : week.title,
                    style: TextStyle(
                        fontFamily: "NotoSansKR", fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '인강 ${week.videoUrl.isEmpty ? "없음" : "있음"} · '
                    '문제 ${week.problemLinks.length}개 · '
                    '체크 ${week.checklistItems.length}개',
                    style: TextStyle(fontFamily: "NotoSansKR", fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '수정',
                        icon: Icon(Icons.edit_outlined),
                        onPressed: () => _openEditor(existing: week),
                      ),
                      IconButton(
                        tooltip: '삭제',
                        icon: Icon(Icons.delete_outline, color: Palette.danger),
                        onPressed: () => _delete(week),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _LinkDraft {
  final TextEditingController title;
  final TextEditingController url;

  _LinkDraft({String title = '', String url = ''})
      : title = TextEditingController(text: title),
        url = TextEditingController(text: url);

  void dispose() {
    title.dispose();
    url.dispose();
  }
}

class _CheckDraft {
  final String id;
  final TextEditingController label;

  _CheckDraft({required this.id, String label = ''})
      : label = TextEditingController(text: label);

  void dispose() {
    label.dispose();
  }
}

class _WeekEditorDialog extends StatefulWidget {
  final OnlineCourse course;
  final OnlineWeek? existing;

  const _WeekEditorDialog({required this.course, this.existing});

  @override
  State<_WeekEditorDialog> createState() => _WeekEditorDialogState();
}

class _WeekEditorDialogState extends State<_WeekEditorDialog> {
  late final TextEditingController weekNumberController;
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController videoUrlController;
  final List<_LinkDraft> _links = [];
  final List<_CheckDraft> _checks = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    weekNumberController = TextEditingController(
        text: existing == null ? '1' : '${existing.weekNumber}');
    titleController = TextEditingController(text: existing?.title ?? '');
    descriptionController =
        TextEditingController(text: existing?.description ?? '');
    videoUrlController = TextEditingController(text: existing?.videoUrl ?? '');

    if (existing != null) {
      for (final link in existing.problemLinks) {
        _links.add(_LinkDraft(title: link.title, url: link.url));
      }
      for (final item in existing.checklistItems) {
        _checks.add(_CheckDraft(id: item.id, label: item.label));
      }
    }
    if (_links.isEmpty) _links.add(_LinkDraft());
    if (_checks.isEmpty) {
      _checks.add(_CheckDraft(id: _newCheckId()));
    }
  }

  @override
  void dispose() {
    weekNumberController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    videoUrlController.dispose();
    for (final link in _links) {
      link.dispose();
    }
    for (final check in _checks) {
      check.dispose();
    }
    super.dispose();
  }

  String _newCheckId() =>
      'item_${DateTime.now().microsecondsSinceEpoch}_${_checks.length}';

  Future<void> _save() async {
    final weekNumber = int.tryParse(weekNumberController.text.trim()) ?? 0;
    setState(() {
      _saving = true;
    });

    final links = _links
        .map((e) => WeekProblemLink(
              title: e.title.text.trim(),
              url: e.url.text.trim(),
            ))
        .where((e) => e.url.isNotEmpty)
        .toList();
    final checks = _checks
        .where((e) => e.label.text.trim().isNotEmpty)
        .map((e) => WeekChecklistItem(id: e.id, label: e.label.text.trim()))
        .toList();

    final existing = widget.existing;
    final error = existing == null
        ? await EnrollmentService.addWeek(
            courseId: widget.course.id,
            weekNumber: weekNumber,
            title: titleController.text,
            description: descriptionController.text,
            videoUrl: videoUrlController.text,
            problemLinks: links,
            checklistItems: checks,
          )
        : await EnrollmentService.updateWeek(
            weekId: existing.id,
            courseId: widget.course.id,
            weekNumber: weekNumber,
            title: titleController.text,
            description: descriptionController.text,
            videoUrl: videoUrlController.text,
            problemLinks: links,
            checklistItems: checks,
          );

    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(fontFamily: "NotoSansKR")),
          backgroundColor: Palette.danger,
        ),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(
        isEdit ? '${widget.existing!.weekNumber}주차 수정' : '주차 추가',
        style: TextStyle(fontFamily: "Jalnan"),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: weekNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '주차 번호',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '주차 제목 (예: 1주차 자기소개)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: '이번 주 안내 (선택)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: videoUrlController,
                decoration: InputDecoration(
                  labelText: '인강 URL (YouTube 등)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 18),
              Text('문제풀이 링크',
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 14)),
              SizedBox(height: 8),
              ...List.generate(_links.length, (index) {
                final draft = _links[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: draft.title,
                          decoration: InputDecoration(
                            labelText: '이름',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: draft.url,
                          decoration: InputDecoration(
                            labelText: 'URL',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _links.removeAt(index);
                            if (_links.isEmpty) _links.add(_LinkDraft());
                          });
                        },
                        icon: Icon(Icons.remove_circle_outline,
                            color: Palette.grey500),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _links.add(_LinkDraft());
                  });
                },
                icon: Icon(Icons.add),
                label: Text('문제 링크 추가',
                    style: TextStyle(fontFamily: "NotoSansKR")),
              ),
              SizedBox(height: 12),
              Text('이번 주 체크리스트',
                  style: TextStyle(fontFamily: "Jalnan", fontSize: 14)),
              SizedBox(height: 8),
              ...List.generate(_checks.length, (index) {
                final draft = _checks[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: draft.label,
                          decoration: InputDecoration(
                            labelText: '학생이 체크할 항목',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _checks.removeAt(index);
                            if (_checks.isEmpty) {
                              _checks.add(_CheckDraft(id: _newCheckId()));
                            }
                          });
                        },
                        icon: Icon(Icons.remove_circle_outline,
                            color: Palette.grey500),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _checks.add(_CheckDraft(id: _newCheckId()));
                  });
                },
                icon: Icon(Icons.add),
                label: Text('체크 항목 추가',
                    style: TextStyle(fontFamily: "NotoSansKR")),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text('취소'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.secondaryDark,
            foregroundColor: Palette.white,
          ),
          onPressed: _saving ? null : _save,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Palette.white),
                )
              : Text(isEdit ? '수정 저장' : '등록',
                  style: TextStyle(fontFamily: "Jalnan")),
        ),
      ],
    );
  }
}
