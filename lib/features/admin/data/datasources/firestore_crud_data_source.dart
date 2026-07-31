import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fingerprint_app/core/constants/firestore_paths.dart';
import 'package:fingerprint_app/core/utils/soft_delete.dart';

typedef FromMap<T> = T Function(String id, Map<String, dynamic> data);
typedef ToMap<T> = Map<String, dynamic> Function(T entity);

/// Generic Firestore CRUD for soft-deleted, branch-scoped documents.
class FirestoreCrudDataSource<T> {
  FirestoreCrudDataSource({
    required this.collectionPath,
    required this.fromMap,
    required this.toMap,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String collectionPath;
  final FromMap<T> fromMap;
  final ToMap<T> toMap;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(collectionPath);

  Stream<List<T>> watchAll({String branchId = AppDefaults.branchId}) {
    return _col.where('branchId', isEqualTo: branchId).snapshots().map((snap) {
      return snap.docs
          .where((d) {
            final data = d.data();
            return data['deletedAt'] == null && data['placeholder'] != true;
          })
          .map((d) => fromMap(d.id, d.data()))
          .toList(growable: false);
    });
  }

  Future<List<T>> fetchAll({String branchId = AppDefaults.branchId}) async {
    final snap = await _col.where('branchId', isEqualTo: branchId).get();
    return snap.docs
        .where((d) {
          final data = d.data();
          return data['deletedAt'] == null && data['placeholder'] != true;
        })
        .map((d) => fromMap(d.id, d.data()))
        .toList();
  }

  Future<String> create(T entity) async {
    final data = SoftDeleteMapper.withTimestamps(
      data: toMap(entity),
      isCreate: true,
    );
    final doc = await _col.add(data);
    return doc.id;
  }

  Future<void> createWithId(String id, T entity) async {
    final data = SoftDeleteMapper.withTimestamps(
      data: toMap(entity),
      isCreate: true,
    );
    await _col.doc(id).set(data);
  }

  Future<void> update(String id, T entity) async {
    final data = SoftDeleteMapper.withTimestamps(
      data: toMap(entity),
      isCreate: false,
    );
    await _col.doc(id).update(data);
  }

  Future<void> softDelete(String id) async {
    await _col.doc(id).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
