import 'package:cloud_firestore/cloud_firestore.dart';
import '../class/Notice.dart';

class NoticeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'notices';

  // Firestore 설정 초기화
  static void initializeFirestore() {
    try {
      _firestore.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print('✅ Firestore 설정이 초기화되었습니다.');
    } catch (e) {
      print('⚠️ Firestore 설정 초기화 중 오류: $e');
    }
  }

  // Firestore 연결 상태 확인
  static Future<bool> checkConnection() async {
    try {
      await _firestore
          .collection(_collectionName)
          .limit(1)
          .get(GetOptions(source: Source.server));
      return true;
    } catch (e) {
      print('Firestore 연결 확인 실패: $e');
      return false;
    }
  }

  // 모든 노티스 가져오기 (최신순)
  static Stream<List<Notice>> getNoticesStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList());
  }

  // 중요 노티스 먼저, 그 다음 최신순으로 정렬된 노티스 가져오기
  static Stream<List<Notice>> getNoticesStreamSorted() {
    print('🔄 NoticeService: 스트림 시작');

    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: false)
        .timeout(Duration(seconds: 15))
        .handleError((error) {
      print('❌ Notice 스트림 오류: $error');
      return <QuerySnapshot>[];
    }).map((snapshot) {
      print('📊 NoticeService: 데이터 수신 - ${snapshot.docs.length}개 문서');

      List<Notice> notices = snapshot.docs
          .map((doc) {
            try {
              return Notice.fromFirestore(doc);
            } catch (e) {
              print('❌ 문서 파싱 오류 (${doc.id}): $e');
              return null;
            }
          })
          .where((notice) => notice != null)
          .cast<Notice>()
          .toList();

      print('✅ NoticeService: 파싱된 공지사항 ${notices.length}개');

      // 클라이언트 사이드에서 중요도 먼저, 그 다음 최신순으로 정렬
      notices.sort((a, b) {
        // 먼저 중요도로 정렬 (중요한 것이 먼저)
        if (a.isImportant != b.isImportant) {
          return b.isImportant ? 1 : -1;
        }
        // 그 다음 생성일로 정렬 (최신이 먼저)
        return b.createdAt.compareTo(a.createdAt);
      });

      print('🎯 NoticeService: 정렬 완료 - ${notices.length}개');
      return notices;
    });
  }

  // 임시: 중복 게시글 정리 (한번만 사용)
  static Future<int> cleanupTestData() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection(_collectionName).get();

      Map<String, List<QueryDocumentSnapshot>> groups = {};

      // 제목별로 그룹화
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String title = data['title'] ?? '';

        if (!groups.containsKey(title)) {
          groups[title] = [];
        }
        groups[title]!.add(doc);
      }

      int deletedCount = 0;

      // 중복된 제목들 처리
      for (String title in groups.keys) {
        List<QueryDocumentSnapshot> docs = groups[title]!;
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

  // 단순한 Future 기반으로 노티스 목록 가져오기 (대안)
  static Future<List<Notice>> getNoticesSimple() async {
    print('🔄 NoticeService: 단순 조회 시작');
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get(GetOptions(source: Source.cache))
          .timeout(Duration(seconds: 10));

      print('📊 NoticeService: 단순 조회 - ${snapshot.docs.length}개 문서');

      List<Notice> notices = snapshot.docs
          .map((doc) {
            try {
              return Notice.fromFirestore(doc);
            } catch (e) {
              print('❌ 문서 파싱 오류 (${doc.id}): $e');
              return null;
            }
          })
          .where((notice) => notice != null)
          .cast<Notice>()
          .toList();

      // 클라이언트 사이드에서 중요도 먼저, 그 다음 최신순으로 정렬
      notices.sort((a, b) {
        if (a.isImportant != b.isImportant) {
          return b.isImportant ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      print('✅ NoticeService: 단순 조회 완료 - ${notices.length}개');
      return notices;
    } catch (e) {
      print('❌ NoticeService: 단순 조회 오류 - $e');
      rethrow;
    }
  }

  // 특정 노티스 가져오기
  static Future<Notice?> getNotice(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionName).doc(id).get();

      if (doc.exists) {
        return Notice.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('노티스 가져오기 오류: $e');
      return null;
    }
  }

  // 노티스 추가
  static Future<String?> addNotice(Notice notice) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(notice.toFirestore());

      return docRef.id;
    } catch (e) {
      print('노티스 추가 오류: $e');
      return null;
    }
  }

  // 노티스 수정
  static Future<bool> updateNotice(String id, Notice notice) async {
    try {
      Notice updatedNotice = notice.copyWith(
        id: id,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(updatedNotice.toFirestore());

      return true;
    } catch (e) {
      print('노티스 수정 오류: $e');
      return false;
    }
  }

  // 노티스 삭제
  static Future<bool> deleteNotice(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();

      return true;
    } catch (e) {
      print('노티스 삭제 오류: $e');
      return false;
    }
  }

  // 페이지네이션을 위한 노티스 가져오기
  static Future<List<Notice>> getNoticesPaginated({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();
      List<Notice> notices =
          snapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList();

      // 클라이언트 사이드에서 중요도 먼저, 그 다음 최신순으로 정렬
      notices.sort((a, b) {
        if (a.isImportant != b.isImportant) {
          return b.isImportant ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      return notices;
    } catch (e) {
      print('페이지네이션 노티스 가져오기 오류: $e');
      return [];
    }
  }

  // 검색 기능
  static Future<List<Notice>> searchNotices(String searchTerm) async {
    try {
      // Firestore에서는 전체 텍스트 검색이 제한적이므로,
      // 제목에서만 검색하거나 클라이언트 사이드에서 필터링
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      List<Notice> allNotices =
          snapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList();

      // 클라이언트 사이드에서 제목과 내용 검색
      return allNotices
          .where((notice) =>
              notice.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
              notice.content.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    } catch (e) {
      print('노티스 검색 오류: $e');
      return [];
    }
  }

  // 노티스 개수 가져오기
  static Future<int> getNoticeCount() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection(_collectionName).get();

      return snapshot.docs.length;
    } catch (e) {
      print('노티스 개수 가져오기 오류: $e');
      return 0;
    }
  }

  // 테스트용 더미 Notice 데이터 추가 (개발용)
  static Future<void> addDummyNotices() async {
    try {
      List<Notice> dummyNotices = [
        Notice(
          title: '2024년 신학기 개강 안내',
          content:
              '2024년 신학기가 3월 4일부터 시작됩니다. 자세한 내용은 공지사항을 확인해주세요.\n\n주요 일정:\n- 레벨테스트: 2월 26일~3월 1일\n- 개강일: 3월 4일\n- 첫 주는 오리엔테이션으로 진행됩니다.',
          author: '관리자',
          createdAt: DateTime.now().subtract(Duration(days: 10)),
          isImportant: true,
        ),
        Notice(
          title: '겨울방학 특별프로그램 모집',
          content:
              '겨울방학 특별프로그램에 참여하실 학생들을 모집합니다.\n\n프로그램 내용:\n- 집중 회화 클래스\n- 문법 완성반\n- 토익 준비반\n\n신청 마감: 12월 20일까지',
          author: '관리자',
          createdAt: DateTime.now().subtract(Duration(days: 7)),
          isImportant: false,
        ),
        Notice(
          title: '학부모 상담 일정 안내',
          content:
              '학부모 상담 일정을 안내드립니다.\n\n상담 기간: 매월 마지막 주 금요일\n시간: 오후 2시~6시\n예약 방법: 전화 또는 방문 예약\n\n문의사항이 있으시면 언제든 연락 주세요.',
          author: '관리자',
          createdAt: DateTime.now().subtract(Duration(days: 5)),
          isImportant: false,
        ),
        Notice(
          title: '2024년 봄학기 교재 안내',
          content:
              '새 학기에 사용할 교재에 대해 안내드립니다.\n\n주요 교재:\n- Elementary: Let\'s Go 시리즈\n- Intermediate: Four Corners\n- Advanced: Interchange\n\n교재는 개강 전까지 준비해주시기 바랍니다.',
          author: '관리자',
          createdAt: DateTime.now().subtract(Duration(days: 3)),
          isImportant: false,
        ),
      ];

      for (Notice notice in dummyNotices) {
        await addNotice(notice);
      }

      print('✅ 더미 Notice 데이터가 추가되었습니다.');
    } catch (e) {
      print('더미 Notice 추가 오류: $e');
    }
  }
}
