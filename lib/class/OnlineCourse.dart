import 'package:flutter/material.dart';
import 'package:gi_english_website/class/OnlinePlan.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 성인 온라인 프로그램(인강) 과정 정보.
/// id는 Firestore의 수강 정보(enrollments.courseId)와 매칭된다.
class OnlineCourse {
  final String id;
  final int order;
  final String title;
  final String subtitle;
  final String description;
  final String imageAsset;
  final List<String> highlights;
  final Color accentColor;

  /// 인강+퀴즈+화상 [defaultSessions]회 묶음 금액 (원). 지금 판매 중인 가격.
  final int price;

  /// 인강+퀴즈만 판매할 때의 안내 금액 (원). 레벨당 [OnlinePlan.lessonsPerLevel]편.
  /// 화상 [defaultSessions]회를 따로 더하면 묶음보다 비싸다.
  final int lecturePrice;

  /// 기본 포함 화상수업 횟수. 묶음 상품 기준.
  final int defaultSessions;

  const OnlineCourse({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageAsset,
    required this.highlights,
    required this.accentColor,
    required this.price,
    required this.lecturePrice,
    this.defaultSessions = 8,
  });

  static const List<OnlineCourse> all = [
    OnlineCourse(
      id: 'beginner_phonics',
      order: 1,
      title: '글림 왕초보 영어',
      subtitle: '파닉스 + 기초회화',
      description:
          '알파벳과 발음부터 차근차근 시작하는 왕초보 과정입니다. 짧은 표현으로 말문을 열고, 영어에 대한 부담을 덜어 드립니다.',
      imageAsset: 'assets/audience-beginner.png',
      highlights: [
        '영어 발음의 기본 파닉스부터 시작',
        '기초 어휘와 짧은 표현으로 말하기 연습',
        '영어에 자신감을 갖고 싶은 분들께 추천',
      ],
      accentColor: Palette.warning,
      price: 180000,
      lecturePrice: 99000,
      defaultSessions: 8,
    ),
    OnlineCourse(
      id: 'basic_grammar_speaking',
      order: 2,
      title: '글림 기초영어',
      subtitle: '영문법 + 원어민 회화',
      description:
          '꼭 필요한 기초 문법과 일상 회화를 함께 익히는 과정입니다. 바로 쓰는 표현으로 말하기 자신감을 키웁니다.',
      imageAsset: 'assets/audience-basic.png',
      highlights: [
        '꼭 필요한 기초 영문법을 쉽게 이해',
        '일상생활에서 바로 쓰는 회화 표현 연습',
        '말문이 트이는 기초 실력 완성',
      ],
      accentColor: Palette.secondary,
      price: 200000,
      lecturePrice: 129000,
      defaultSessions: 8,
    ),
    OnlineCourse(
      id: 'intermediate_grammar_speaking',
      order: 3,
      title: '글림 중급영어',
      subtitle: '영문법 + 원어민 회화',
      description:
          '중급 문법을 체계적으로 정리하고, 자연스러운 표현으로 회화의 폭을 넓히는 과정입니다.',
      imageAsset: 'assets/audience-intermediate.png',
      highlights: [
        '중급 영문법을 체계적으로 정리',
        '자연스럽고 다양한 표현으로 회화 능력 향상',
        '한 단계 더 업그레이드된 영어 실력',
      ],
      accentColor: Palette.primary,
      price: 200000,
      lecturePrice: 129000,
      defaultSessions: 8,
    ),
    OnlineCourse(
      id: 'business_english',
      order: 4,
      title: '글림 실전 비즈니스 영어',
      subtitle: '실무 중심 비즈니스 커뮤니케이션',
      description:
          '회의, 이메일, 프레젠테이션처럼 업무에서 바로 마주치는 상황에서 쓰는 실전 영어를 익힙니다.',
      imageAsset: 'assets/audience-business.png',
      highlights: [
        '비즈니스 상황에 맞는 실전 회화 학습',
        '회의, 프레젠테이션, 이메일 등 실무 중심',
        '글로벌 비즈니스 자신감 향상',
      ],
      accentColor: Palette.accent,
      price: 200000,
      lecturePrice: 129000,
      defaultSessions: 8,
    ),
    OnlineCourse(
      id: 'advanced_premium_speaking',
      order: 5,
      title: '글림 고급영어',
      subtitle: '프리미엄 스피킹',
      description:
          '고급 표현과 뉘앙스까지 다루며, 토론·시사 주제로 유창하고 세련된 말하기를 완성하는 과정입니다.',
      imageAsset: 'assets/audience-advanced.png',
      highlights: [
        '고급 표현과 뉘앙스까지 완벽 마스터',
        '토론, 시사, 문화 등 다양한 주제로 심화 학습',
        '유창하고 세련된 영어 구사 능력 완성',
      ],
      accentColor: Palette.danger,
      price: 250000,
      lecturePrice: 169000,
      defaultSessions: 8,
    ),
  ];

  /// 원어민 1:1 회화만 파는 상품. 레벨 과정 [all]에는 넣지 않는다.
  static const speaking = OnlineCourse(
    id: OnlinePlan.speakingCourseId,
    order: 0,
    title: '원어민 1:1 회화',
    subtitle: '실전 1:1 스피킹',
    description:
        '인강 없이 원어민과 1:1로만 말하는 회화 수업입니다. 필요한 횟수만큼 신청합니다.',
    imageAsset: 'assets/native-speaking-class-full.jpg',
    highlights: [
      '나에게만 집중하는 1:1 원어민 회화',
      '4회, 8회, 12회 중에서 횟수를 고릅니다',
      '인강과 퀴즈는 포함되지 않습니다',
    ],
    accentColor: Palette.accent,
    price: OnlinePlan.speakingSessionPrice * 8,
    lecturePrice: 0,
    defaultSessions: 8,
  );

  /// 레벨 과정과 화상만 상품. 관리자 배정 목록용.
  static List<OnlineCourse> get catalog => [...all, speaking];

  bool get isSpeakingProduct => id == speaking.id;

  String get priceLabel => OnlinePlan.won(price);

  String get lecturePriceLabel => OnlinePlan.won(lecturePrice);

  int amountFor(String plan, {int? sessions}) {
    final kind = OnlinePlan.normalize(plan);
    if (kind == OnlinePlan.lecture) return lecturePrice;
    if (kind == OnlinePlan.speaking) {
      return OnlinePlan.speakingSessionPrice *
          sessionsFor(kind, sessions: sessions);
    }
    return price;
  }

  int sessionsFor(String plan, {int? sessions}) {
    final kind = OnlinePlan.normalize(plan);
    if (kind == OnlinePlan.lecture) return 0;
    if (kind == OnlinePlan.speaking) {
      final count = sessions ?? defaultSessions;
      return count > 0 ? count : defaultSessions;
    }
    return sessions ?? defaultSessions;
  }

  static OnlineCourse? findById(String id) {
    if (id == speaking.id) return speaking;
    for (final course in all) {
      if (course.id == id) return course;
    }
    return null;
  }
}
