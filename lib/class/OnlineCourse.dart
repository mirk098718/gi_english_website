import 'package:flutter/material.dart';
import 'package:gi_english_website/util/Palette.dart';

/// 성인 온라인 프로그램(인강) 과정 정보.
/// id는 Firestore의 수강 정보(enrollments.courseId)와 매칭된다.
class OnlineCourse {
  final String id;
  final int order;
  final String title;
  final String subtitle;
  final List<String> highlights;
  final Color accentColor;

  /// 과정 결제 금액 (원). 화상수업 [defaultSessions]회 포함.
  final int price;

  /// 기본 포함 화상수업 횟수.
  final int defaultSessions;

  const OnlineCourse({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.highlights,
    required this.accentColor,
    required this.price,
    this.defaultSessions = 8,
  });

  static const List<OnlineCourse> all = [
    OnlineCourse(
      id: 'beginner_phonics',
      order: 1,
      title: '성인 왕초보 영어',
      subtitle: '파닉스 + 기초회화',
      highlights: [
        '영어 발음의 기본 파닉스부터 시작',
        '기초 어휘와 짧은 표현으로 말하기 연습',
        '영어에 자신감을 갖고 싶은 분들께 추천',
      ],
      accentColor: Palette.warning,
      price: 200000,
      defaultSessions: 8,
    ),
    OnlineCourse(
      id: 'basic_grammar_speaking',
      order: 2,
      title: '성인 기초영어',
      subtitle: '영문법 + 원어민 회화',
      highlights: [
        '꼭 필요한 기초 영문법을 쉽게 이해',
        '일상생활에서 바로 쓰는 회화 표현 연습',
        '말문이 트이는 기초 실력 완성',
      ],
      accentColor: Palette.secondary,
      price: 250000,
      defaultSessions: 8,
    ),
    OnlineCourse(
      id: 'intermediate_grammar_speaking',
      order: 3,
      title: '성인 중급영어',
      subtitle: '영문법 + 원어민 회화',
      highlights: [
        '중급 영문법을 체계적으로 정리',
        '자연스럽고 다양한 표현으로 회화 능력 향상',
        '한 단계 더 업그레이드된 영어 실력',
      ],
      accentColor: Palette.primary,
      price: 280000,
      defaultSessions: 8,
    ),
    OnlineCourse(
      id: 'business_english',
      order: 4,
      title: '실전 비즈니스 영어회화',
      subtitle: '실무 중심 비즈니스 커뮤니케이션',
      highlights: [
        '비즈니스 상황에 맞는 실전 회화 학습',
        '회의, 프레젠테이션, 이메일 등 실무 중심',
        '글로벌 비즈니스 자신감 향상',
      ],
      accentColor: Palette.accent,
      price: 300000,
      defaultSessions: 8,
    ),
    OnlineCourse(
      id: 'advanced_premium_speaking',
      order: 5,
      title: '성인 고급 영어회화',
      subtitle: '프리미엄 스피킹',
      highlights: [
        '고급 표현과 뉘앙스까지 완벽 마스터',
        '토론, 시사, 문화 등 다양한 주제로 심화 학습',
        '유창하고 세련된 영어 구사 능력 완성',
      ],
      accentColor: Palette.danger,
      price: 350000,
      defaultSessions: 8,
    ),
  ];

  String get priceLabel {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}원';
  }

  static OnlineCourse? findById(String id) {
    for (final course in all) {
      if (course.id == id) return course;
    }
    return null;
  }
}
