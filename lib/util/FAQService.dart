import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/class/FAQ.dart';

class FAQService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'faqs';

  // FAQ 추가
  static Future<void> addFAQ(FAQ faq) async {
    try {
      await _firestore.collection(_collection).add(faq.toFirestore());
    } catch (e) {
      print('FAQ 추가 오류: $e');
      throw e;
    }
  }

  // FAQ 목록 실시간 스트림 (중요한 것 우선, 최신순)
  static Stream<List<FAQ>> getFAQsStreamSorted() {
    print('🔄 FAQService: 스트림 시작');

    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true) // 단일 필드로만 정렬
        .snapshots(includeMetadataChanges: false)
        .timeout(Duration(seconds: 15))
        .handleError((error) {
      print('❌ FAQ 스트림 오류: $error');
      return <QuerySnapshot>[];
    }).map((snapshot) {
      print('📊 FAQService: 데이터 수신 - ${snapshot.docs.length}개 문서');

      List<FAQ> faqs = snapshot.docs
          .map((doc) {
            try {
              return FAQ.fromFirestore(doc);
            } catch (e) {
              print('❌ 문서 파싱 오류 (${doc.id}): $e');
              return null;
            }
          })
          .where((faq) => faq != null)
          .cast<FAQ>()
          .toList();

      print('✅ FAQService: 파싱된 FAQ ${faqs.length}개');

      // 클라이언트 사이드에서 중요도 먼저, 그 다음 최신순으로 정렬
      faqs.sort((a, b) {
        // 먼저 중요도로 정렬 (중요한 것이 먼저)
        if (a.isImportant != b.isImportant) {
          return b.isImportant ? 1 : -1;
        }
        // 그 다음 생성일로 정렬 (최신이 먼저)
        return b.createdAt.compareTo(a.createdAt);
      });

      // 과거 앱 시작 시마다 더미 데이터가 반복 추가되어 같은 질문이 여러 문서로 남은 경우, 표시는 질문당 하나만
      List<FAQ> deduped = [];
      Set<String> seenQuestions = {};
      for (FAQ f in faqs) {
        if (!seenQuestions.contains(f.question)) {
          seenQuestions.add(f.question);
          deduped.add(f);
        }
      }

      print('🎯 FAQService: 정렬 완료 - ${deduped.length}개 (중복 제거 후)');
      return deduped;
    });
  }

  // 특정 FAQ 조회
  static Future<FAQ?> getFAQById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return FAQ.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('FAQ 조회 오류: $e');
      return null;
    }
  }

  // FAQ 수정
  static Future<void> updateFAQ(FAQ faq) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(faq.id)
          .update(faq.toFirestore());
    } catch (e) {
      print('FAQ 수정 오류: $e');
      throw e;
    }
  }

  // FAQ 삭제
  static Future<void> deleteFAQ(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('FAQ 삭제 오류: $e');
      throw e;
    }
  }

  // 중요 FAQ만 가져오기 (메인 페이지용)
  static Stream<List<FAQ>> getImportantFAQsStream() {
    return _firestore
        .collection(_collection)
        .where('isImportant', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => FAQ.fromFirestore(doc)).toList();
    });
  }

  // 카테고리별 FAQ 가져오기
  static Stream<List<FAQ>> getFAQsByCategoryStream(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true) // 단일 필드로만 정렬
        .snapshots()
        .handleError((error) {
      print('❌ 카테고리별 FAQ 스트림 오류: $error');
      return <QuerySnapshot>[];
    }).map((snapshot) {
      List<FAQ> faqs =
          snapshot.docs.map((doc) => FAQ.fromFirestore(doc)).toList();

      // 클라이언트 사이드에서 중요도 먼저, 그 다음 최신순으로 정렬
      faqs.sort((a, b) {
        if (a.isImportant != b.isImportant) {
          return b.isImportant ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      return faqs;
    });
  }

  // 임시: 중복 FAQ 정리 (한번만 사용)
  static Future<int> cleanupTestData() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(_collection).get();

      Map<String, List<QueryDocumentSnapshot>> groups = {};

      // 질문별로 그룹화
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String question = data['question'] ?? '';

        if (!groups.containsKey(question)) {
          groups[question] = [];
        }
        groups[question]!.add(doc);
      }

      int deletedCount = 0;

      // 중복된 질문들 처리
      for (String question in groups.keys) {
        List<QueryDocumentSnapshot> docs = groups[question]!;
        if (docs.length > 1) {
          // 최신 하나만 남기고 나머지 삭제
          docs.sort((a, b) {
            Timestamp aTime =
                (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp? ??
                    Timestamp.now();
            Timestamp bTime =
                (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp? ??
                    Timestamp.now();
            return bTime.compareTo(aTime);
          });

          // 첫 번째(최신)를 제외한 나머지 삭제
          for (int i = 1; i < docs.length; i++) {
            await docs[i].reference.delete();
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      print('정리 오류: $e');
      return 0;
    }
  }

  // 테스트용 더미 FAQ 데이터 추가 (개발용)
  static Future<void> addDummyFAQs() async {
    try {
      List<FAQ> dummyFAQs = [
        FAQ(
          id: '',
          question: '수업료는 어떻게 납부하나요?',
          answer: '수업료는 매월 1일까지 계좌이체로 납부하시면 됩니다. 자세한 계좌 정보는 상담 시 안내드립니다.',
          category: '일반',
          createdAt: DateTime.now().subtract(Duration(days: 7)),
          updatedAt: DateTime.now().subtract(Duration(days: 7)),
          isImportant: true,
        ),
        FAQ(
          id: '',
          question: '레벨테스트는 언제 받을 수 있나요?',
          answer: '레벨테스트는 매주 월요일과 수요일에 받으실 수 있습니다. 사전 예약이 필요합니다.',
          category: '수업',
          createdAt: DateTime.now().subtract(Duration(days: 5)),
          updatedAt: DateTime.now().subtract(Duration(days: 5)),
          isImportant: false,
        ),
        FAQ(
          id: '',
          question: '교재는 별도로 구매해야 하나요?',
          answer: '기본 교재는 수업료에 포함되어 있습니다. 추가 교재가 필요한 경우 별도 안내드립니다.',
          category: '교재',
          createdAt: DateTime.now().subtract(Duration(days: 3)),
          updatedAt: DateTime.now().subtract(Duration(days: 3)),
          isImportant: false,
        ),
      ];

      for (FAQ faq in dummyFAQs) {
        await addFAQ(faq);
      }

      print('✅ 더미 FAQ 데이터가 추가되었습니다.');
    } catch (e) {
      print('더미 FAQ 추가 오류: $e');
    }
  }
}
