import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/ProfilePhotoPicker.dart';
import 'package:gi_english_website/widget/ProfileAvatar.dart';

/// 수강생·강사가 닉네임과 프로필 사진을 직접 고르는 창.
class ProfileEditDialog extends StatefulWidget {
  final String title;
  final String email;
  final String nickname;
  final String photoUrl;
  final String helperText;
  final Future<String?> Function({
    required String nickname,
    Uint8List? photoBytes,
  }) onSave;

  const ProfileEditDialog({
    Key? key,
    this.title = '프로필 수정',
    required this.email,
    this.nickname = '',
    this.photoUrl = '',
    this.helperText =
        '로그인은 이메일 그대로 두고, 수업과 목록에는 닉네임과 사진이 보입니다.',
    required this.onSave,
  }) : super(key: key);

  static Future<bool> show(
    BuildContext context, {
    String title = '프로필 수정',
    required String email,
    String nickname = '',
    String photoUrl = '',
    String helperText =
        '로그인은 이메일 그대로 두고, 수업과 목록에는 닉네임과 사진이 보입니다.',
    required Future<String?> Function({
      required String nickname,
      Uint8List? photoBytes,
    }) onSave,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProfileEditDialog(
        title: title,
        email: email,
        nickname: nickname,
        photoUrl: photoUrl,
        helperText: helperText,
        onSave: onSave,
      ),
    );
    return saved == true;
  }

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late final TextEditingController _nicknameCtrl;
  Uint8List? _newPhoto;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.nickname);
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  void _toast(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: "NotoSansKR")),
        backgroundColor: error ? Palette.danger : Palette.success,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final cropped = await ProfilePhotoPicker.pickAndCrop(
      context,
      onError: (message) => _toast(message),
    );
    if (!mounted || cropped == null || cropped.isEmpty) return;
    setState(() => _newPhoto = cropped);
  }

  Future<void> _save() async {
    if (_saving) return;
    final nicknameError = AuthService.validateNickname(_nicknameCtrl.text);
    if (nicknameError != null) {
      _toast(nicknameError);
      return;
    }
    setState(() => _saving = true);
    final error = await widget.onSave(
      nickname: _nicknameCtrl.text.trim(),
      photoBytes: _newPhoto,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      _toast(error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.white,
      surfaceTintColor: Palette.white,
      title: Text(widget.title, style: TextStyle(fontFamily: "Jalnan")),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.email.isNotEmpty)
                Text(
                  widget.email,
                  style: TextStyle(
                    fontFamily: "NotoSansKR",
                    fontSize: 13,
                    color: Palette.grey600,
                  ),
                ),
              SizedBox(height: 8),
              Text(
                widget.helperText,
                style: TextStyle(
                  fontFamily: "NotoSansKR",
                  fontSize: 13,
                  color: Palette.grey600,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  ProfileAvatar(
                    photoUrl: widget.photoUrl,
                    bytes: _newPhoto,
                    label: _nicknameCtrl.text.trim().isNotEmpty
                        ? _nicknameCtrl.text
                        : widget.email,
                    size: 72,
                  ),
                  SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickPhoto,
                    icon: Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(
                      widget.photoUrl.isEmpty && _newPhoto == null
                          ? '사진 넣기'
                          : '사진 변경',
                      style: TextStyle(fontFamily: "NotoSansKR"),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nicknameCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: '닉네임',
                  hintText: '수업에서 불릴 이름',
                  helperText: '2–16자. 비워 두면 가입 이름이 보입니다.',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text('닫기'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('저장'),
        ),
      ],
    );
  }
}
