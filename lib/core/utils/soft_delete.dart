import 'package:cloud_firestore/cloud_firestore.dart';

mixin SoftDeleteMapper {
  static Map<String, dynamic> withTimestamps({
    required Map<String, dynamic> data,
    required bool isCreate,
  }) {
    final now = FieldValue.serverTimestamp();
    return {
      ...data,
      if (isCreate) 'createdAt': now,
      'updatedAt': now,
    };
  }

  static Query<Map<String, dynamic>> activeOnly(
    CollectionReference<Map<String, dynamic>> ref,
  ) {
    return ref.where('deletedAt', isNull: true);
  }
}
