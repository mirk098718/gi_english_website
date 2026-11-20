import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gi_english_website/class/Notice.dart';
import 'package:gi_english_website/util/NoticeImages.dart';
import 'package:gi_english_website/widget/NoticeBodyField.dart';

void main() {
  test('keeps image urls on old and new notices', () {
    final created = DateTime.utc(2026, 3, 4, 9);

    final legacy = Notice.fromMap('old', {
      'title': '개강 안내',
      'content': '본문',
      'author': '관리자',
      'createdAt': created,
    });
    expect(legacy.imageUrls, isEmpty);

    final notice = Notice.fromMap('new', {
      'title': '사진 공지',
      'content': '현장 사진입니다.',
      'author': '관리자',
      'createdAt': created,
      'imageUrls': [
        ' https://cdn.example/a.jpg ',
        '',
        'https://cdn.example/b.png',
      ],
    });
    expect(notice.imageUrls, [
      'https://cdn.example/a.jpg',
      'https://cdn.example/b.png',
    ]);
    expect(notice.toFirestore()['imageUrls'], notice.imageUrls);
    expect(notice.copyWith(title: '수정').imageUrls, notice.imageUrls);
  });

  test('rejects files that are not images or are too large', () {
    expect(
      NoticeImages.rejectionReason(fileName: 'note.pdf', byteLength: 20),
      'jpg, png, gif, webp 이미지만 첨부할 수 있습니다.',
    );
    expect(
      NoticeImages.rejectionReason(fileName: 'photo.PNG', byteLength: 20),
      isNull,
    );
    expect(
      NoticeImages.rejectionReason(
        fileName: 'photo.jpg',
        byteLength: NoticeImages.maxBytes + 1,
      ),
      '이미지가 너무 큽니다. 8MB 이하 파일로 올려 주세요.',
    );
    expect(NoticeImages.contentTypeOf('photo.webp'), 'image/webp');
    expect(
      NoticeImages.storagePath('사진.GIF', '123_0'),
      'notices/images/123_0.gif',
    );
    expect(
      NoticeImages.isStorageUrl(
        'https://firebasestorage.googleapis.com/v0/b/app/o/notices%2Fimages%2Fa.jpg?alt=media',
      ),
      isTrue,
    );
  });

  testWidgets(
    'long pasted notice text stays intact and scrolls inside the field',
    (tester) async {
      final text = List<String>.generate(
        80,
        (index) => '공지 $index 줄입니다.',
      ).join('\n');
      final controller = TextEditingController(text: text);
      final pageScroll = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(pageScroll.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              controller: pageScroll,
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  NoticeBodyField(controller: controller),
                  const SizedBox(height: 900),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enableInteractiveSelection, isTrue);
      expect(field.expands, isTrue);
      expect(field.maxLines, isNull);
      expect(controller.text, text);

      final bodyScroll = field.scrollController!;
      expect(bodyScroll.position.maxScrollExtent, greaterThan(200));

      final textStart =
          tester.getTopLeft(find.byType(EditableText)) + const Offset(28, 20);
      final drag = await tester.startGesture(
        textStart,
        kind: PointerDeviceKind.mouse,
      );
      await drag.moveBy(const Offset(140, 36));
      await drag.up();
      await tester.pump();
      expect(controller.selection.isValid, isTrue);
      expect(controller.selection.isCollapsed, isFalse);

      final center = tester.getCenter(find.byType(NoticeBodyField));
      await tester.sendEventToBinding(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 160)),
      );
      await tester.pump();

    expect(bodyScroll.offset, inInclusiveRange(1, 200));
    expect(pageScroll.offset, 0);
    },
  );
}
