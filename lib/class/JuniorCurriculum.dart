import 'package:gi_english_website/class/OnlinePlan.dart';

/// 초·중등 원서 + 1:1 화상 수업 금액.
///
/// 1개월은 주 2회 8회 26만 원, 주 3회 12회 33만 원이다.
/// 3개월을 한 번에 내면 그 3개월 정가에서 5%를 뺀다.
class JuniorOffer {
  static const discountPercent = 5;
  static const quarterMonths = 3;

  final String id;
  final String frequencyLabel;
  final int sessionsPerMonth;
  final int monthlyPrice;

  const JuniorOffer({
    required this.id,
    required this.frequencyLabel,
    required this.sessionsPerMonth,
    required this.monthlyPrice,
  });

  static const twiceAWeek = JuniorOffer(
    id: 'twice',
    frequencyLabel: '주 2회',
    sessionsPerMonth: 8,
    monthlyPrice: 260000,
  );

  static const threeTimesAWeek = JuniorOffer(
    id: 'thrice',
    frequencyLabel: '주 3회',
    sessionsPerMonth: 12,
    monthlyPrice: 330000,
  );

  static const all = [twiceAWeek, threeTimesAWeek];

  int get quarterSessions => sessionsPerMonth * quarterMonths;

  int get quarterListPrice => monthlyPrice * quarterMonths;

  int get quarterPrice =>
      quarterListPrice * (100 - discountPercent) ~/ 100;

  int price({required bool quarter}) =>
      quarter ? quarterPrice : monthlyPrice;

  int sessions({required bool quarter}) =>
      quarter ? quarterSessions : sessionsPerMonth;

  String priceLabel({required bool quarter}) =>
      OnlinePlan.money(price(quarter: quarter));
}

/// 재원생만 듣는 원어민 화상 프리토킹. 원서와 문제 없이 이야기만 한다.
/// 주 1회, 20분, 4회에 7만 원.
class EnrolledFreeTalk {
  static const sessions = 4;
  static const minutes = 20;
  static const price = 70000;

  static String priceLabel() => OnlinePlan.money(price);
}
