import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/util/SiteLayout.dart';

void main() {
  testWidgets('좁은 화면과 가로로 누운 폰은 모바일 헤더를 쓴다', (tester) async {
    Future<bool> at(Size size) async {
      late bool mobile;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              mobile = useMobileSchoolLayout(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return mobile;
    }

    expect(await at(const Size(390, 844)), isTrue);
    expect(await at(const Size(844, 390)), isTrue);
    expect(await at(const Size(1280, 800)), isFalse);
  });
}
