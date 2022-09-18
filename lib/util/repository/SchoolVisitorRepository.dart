import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gi_english_website/class/SchoolVisitor.dart';

class SchoolVisitorRepository {
  static const collectionName = "SchoolVisitor";

  static FirebaseFirestore _db() => FirebaseFirestore.instance;

  static CollectionReference<SchoolVisitor> _cRef() =>
      _db().collection(collectionName).withConverter(
            fromFirestore: SchoolVisitor.fromFirestore,
            toFirestore: (SchoolVisitor schoolVisitor, options) =>
                schoolVisitor.toFirestore(),
          );

  static DocumentReference<SchoolVisitor> _dRef([String? documentId]) =>
      _cRef().doc(documentId);

  static Future<void> save(SchoolVisitor schoolVisitor,
      {String? documentId, SetOptions? options}) async {
    await _dRef(documentId).set(schoolVisitor,options);
  }

  static Future<void> delete(SchoolVisitor schoolVisitor, {required String documentId}) async {
    await _dRef(documentId).delete();
  }

  static Future<SchoolVisitor?> get({String? documentId}) async {
    DocumentSnapshot<SchoolVisitor> schoolVisitorSnapshot = await _dRef(documentId).get();
    SchoolVisitor? schoolVisitor = schoolVisitorSnapshot.data();
    return schoolVisitor;
  }


  static Future<List<SchoolVisitor>> getList(
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
    Query<SchoolVisitor> query = _cRef().where(
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
    QuerySnapshot<SchoolVisitor> querySnapshot = await query.get();

    //queryDocumentSnapshotList는 Query를 통해 얻은 QueryDocumentSnapshot의 List이다.
    List<QueryDocumentSnapshot<SchoolVisitor>> queryDocumentSnapshotList =
        querySnapshot.docs;
    //queryDocumentSnapshotList -> schoolVisitorList로 변환 필요
    List<SchoolVisitor> schoolVisitorList =
    queryDocumentSnapshotList.map((e) => e.data()).toList();

    return schoolVisitorList;
  }

}
