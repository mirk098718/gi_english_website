import 'package:cloud_firestore/cloud_firestore.dart';

import '../../class/CafeVisitor.dart';

class CafeVisitorRepository {
  static const collectionName = "CafeVisitor";

  static FirebaseFirestore _db() => FirebaseFirestore.instance;

  static CollectionReference<CafeVisitor> _cRef() =>
      _db().collection(collectionName).withConverter(
        fromFirestore: CafeVisitor.fromFirestore,
        toFirestore: (CafeVisitor schoolVisitor, options) =>
            schoolVisitor.toFirestore(),
      );

  static DocumentReference<CafeVisitor> _dRef([String? documentId]) =>
      _cRef().doc(documentId);

  static Future<CafeVisitor?> get({String? documentId}) async {
    DocumentSnapshot<CafeVisitor> cafeVisitorSnapshot = await _dRef(documentId).get();
    CafeVisitor? cafeVisitor = cafeVisitorSnapshot.data();
    return cafeVisitor;
  }

  static Future<List<CafeVisitor>> getList(
      Object field, {
        Object? isEqualTo,
        Object? isNotEqualTo,
        Object? isLessThan,
        Object? isLessThanOrEqualTo,
        Object? isGreaterThan,
        Object? isGreaterThanOrEqualTo,
        Object? arrayContains,
        List<Object?>? arrayContainsAny,
        List<Object?>? whereIn,
        List<Object?>? whereNotIn,
        bool? isNull,
      }) async {
    Query<CafeVisitor> query = _cRef().where(
      field,
      isEqualTo: isEqualTo,
      isNotEqualTo: isNotEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      arrayContains: arrayContains,
      arrayContainsAny: arrayContainsAny,
      whereIn: whereIn,
      whereNotIn: whereNotIn,
      isNull: isNull,
    );
    QuerySnapshot<CafeVisitor> querySnapshot = await query.get();

    //queryDocumentSnapshotList는 Query를 통해 얻은 QueryDocumentSnapshot의 List이다.
    List<QueryDocumentSnapshot<CafeVisitor>> queryDocumentSnapshotList =
        querySnapshot.docs;
    //queryDocumentSnapshotList -> schoolVisitorList로 변환 필요
    List<CafeVisitor> cafeVisitorList =
    queryDocumentSnapshotList.map((e) => e.data()).toList();

    return cafeVisitorList;
  }
}