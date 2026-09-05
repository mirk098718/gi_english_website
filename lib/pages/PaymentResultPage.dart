import 'package:flutter/material.dart';
import 'package:gi_english_website/pages/OnlineCheckoutPage.dart';
import 'package:gi_english_website/pages/SchoolOnlineClassroomPage.dart';
import 'package:gi_english_website/util/MenuUtil.dart';
import 'package:gi_english_website/util/Palette.dart';
import 'package:gi_english_website/util/PaymentService.dart';

/// 토스 결제 인증 후 리다이렉트되는 결과 페이지.
/// successUrl / failUrl 쿼리 파라미터를 읽어 승인(Cloud Function)을 호출한다.
class PaymentResultPage extends StatefulWidget {
  final bool success;
  final String? paymentKey;
  final String? orderId;
  final int? amount;
  final String? code;
  final String? message;

  const PaymentResultPage({
    Key? key,
    required this.success,
    this.paymentKey,
    this.orderId,
    this.amount,
    this.code,
    this.message,
  }) : super(key: key);

  factory PaymentResultPage.fromUri(Uri uri, {required bool success}) {
    return PaymentResultPage(
      success: success,
      paymentKey: uri.queryParameters['paymentKey'],
      orderId: uri.queryParameters['orderId'],
      amount: int.tryParse(uri.queryParameters['amount'] ?? ''),
      code: uri.queryParameters['code'],
      message: uri.queryParameters['message'],
    );
  }

  @override
  _PaymentResultPageState createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  bool _loading = true;
  String? _error;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    if (widget.success) {
      _confirm();
    } else {
      _loading = false;
      _error = widget.message ?? '결제가 취소되었거나 실패했습니다.';
    }
  }

  Future<void> _confirm() async {
    final paymentKey = widget.paymentKey;
    final orderId = widget.orderId;
    final amount = widget.amount;

    if (paymentKey == null ||
        orderId == null ||
        amount == null ||
        paymentKey.isEmpty ||
        orderId.isEmpty) {
      setState(() {
        _loading = false;
        _error = '결제 정보가 올바르지 않습니다. 다시 시도해주세요.';
      });
      return;
    }

    final error = await PaymentService.confirmPayment(
      paymentKey: paymentKey,
      orderId: orderId,
      amount: amount,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (error == null) {
        _confirmed = true;
      } else if (error.startsWith('CLOUD_FUNCTIONS_UNAVAILABLE:')) {
        // 토스 인증은 됐고, Blaze Functions 전이라 관리자 확정 대기
        _confirmed = true;
        _error =
            '결제창 인증은 완료됐습니다.\n자동 수강 배정(Cloud Functions)이 아직 배포되지 않아, 관리자가 결제내역에서 ‘수강 배정’을 눌러야 내 강의실에 반영됩니다.';
      } else {
        _error = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.white,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: EdgeInsets.all(28),
            child: _loading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('결제를 확인하고 수강을 배정하는 중입니다...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: "NotoSansKR", fontSize: 14)),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _confirmed ? Icons.check_circle : Icons.error_outline,
                        size: 56,
                        color: _confirmed ? Palette.success : Palette.danger,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _confirmed
                            ? (_error == null ? '결제가 완료되었습니다' : '결제 인증 완료')
                            : '결제 처리 실패',
                        style: TextStyle(fontFamily: "Jalnan", fontSize: 20),
                      ),
                      SizedBox(height: 12),
                      Text(
                        _confirmed
                            ? (_error ??
                                '선택한 프로그램이 내 강의실에 배정되었습니다.\n지금 바로 수강을 시작하실 수 있습니다.')
                            : (_error ?? '알 수 없는 오류가 발생했습니다.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: "NotoSansKR",
                            fontSize: 14,
                            height: 1.6,
                            color: Palette.grey600),
                      ),
                      if (widget.orderId != null) ...[
                        SizedBox(height: 10),
                        Text('주문번호: ${widget.orderId}',
                            style: TextStyle(
                                fontFamily: "NotoSansKR",
                                fontSize: 12,
                                color: Palette.grey500)),
                      ],
                      SizedBox(height: 28),
                      if (_confirmed)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.secondaryDark,
                            foregroundColor: Palette.white,
                            minimumSize: Size(double.infinity, 48),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => SchoolOnlineClassroomPage()),
                              (route) => false,
                            );
                          },
                          child: Text('내 강의실로 이동',
                              style: TextStyle(fontFamily: "Jalnan")),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.secondaryDark,
                            foregroundColor: Palette.white,
                            minimumSize: Size(double.infinity, 48),
                          ),
                          onPressed: () {
                            MenuUtil.push(context, OnlineCheckoutPage());
                          },
                          child: Text('다시 결제하기',
                              style: TextStyle(fontFamily: "Jalnan")),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
