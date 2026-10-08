import 'package:flutter/material.dart';
import 'package:gi_english_website/util/AuthService.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 아이디(이메일) 안내 + Firebase 비밀번호 재설정 메일.
class AccountRecoveryDialog extends StatefulWidget {
  final String? prefillEmail;

  const AccountRecoveryDialog({Key? key, this.prefillEmail}) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    String? prefillEmail,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AccountRecoveryDialog(prefillEmail: prefillEmail),
    );
  }

  @override
  State<AccountRecoveryDialog> createState() => _AccountRecoveryDialogState();
}

class _AccountRecoveryDialogState extends State<AccountRecoveryDialog> {
  late final TextEditingController _emailController;
  bool _sending = false;
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.prefillEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _feedback = null;
    });

    final error =
        await AuthService.sendPasswordResetEmail(_emailController.text);
    if (!mounted) return;

    setState(() {
      _sending = false;
      _feedbackIsError = error != null;
      _feedback = error ??
          '요청을 보냈습니다. 가입된 이메일이면 재설정 링크가 도착합니다. '
              '스팸함도 확인해 주세요. 메일이 없으면 가입에 사용한 주소가 맞는지 확인해 주세요.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('아이디 · 비밀번호 찾기',
          style: TextStyle(fontFamily: 'Jalnan', fontSize: 18)),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '아이디는 가입하신 이메일입니다.',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '이메일이 기억나지 않으면 학원으로 문의해 주세요.\n'
                '전화 ${AuthService.academyPhone}\n'
                '이메일 ${AuthService.academyEmail}',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  color: Palette.grey600,
                  height: 1.55,
                ),
              ),
              SizedBox(height: 20),
              Text(
                '비밀번호 재설정',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '가입한 이메일로 재설정 링크를 보내 드립니다.',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 13,
                  color: Palette.grey600,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _emailController,
                enabled: !_sending,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_sending) _sendReset();
                },
                decoration: InputDecoration(
                  labelText: '이메일',
                  hintText: '가입한 이메일',
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontFamily: 'NotoSansKR'),
              ),
              if (_feedback != null) ...[
                SizedBox(height: 12),
                Text(
                  _feedback!,
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 13,
                    color: _feedbackIsError ? Palette.danger : Palette.success,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: Text('닫기', style: TextStyle(fontFamily: 'NotoSansKR')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.darkTeal,
            foregroundColor: Palette.white,
          ),
          onPressed: _sending ? null : _sendReset,
          child: _sending
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Palette.white,
                  ),
                )
              : Text('재설정 메일 보내기', style: TextStyle(fontFamily: 'Jalnan')),
        ),
      ],
    );
  }
}
