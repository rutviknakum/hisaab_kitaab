import 'package:uuid/uuid.dart';
import '../database/db_constants.dart';

class LedgerPersonModel {
  final String id;
  final String userId;
  final String name;
  final String? phone;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  LedgerPersonModel({
    String? id,
    required this.userId,
    required this.name,
    this.phone,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  LedgerPersonModel copyWith({
    String? userId,
    String? name,
    String? phone,
    String? note,
  }) =>
      LedgerPersonModel(
        id: id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        note: note ?? this.note,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        DbConstants.cId: id,
        DbConstants.cUserId: userId,
        DbConstants.cPerName: name,
        DbConstants.cPerPhone: phone,
        DbConstants.cPerNote: note,
        DbConstants.cCreatedAt: createdAt.toIso8601String(),
        DbConstants.cUpdatedAt: updatedAt.toIso8601String(),
      };

  factory LedgerPersonModel.fromMap(Map<String, dynamic> map) =>
      LedgerPersonModel(
        id: map[DbConstants.cId],
        userId: map[DbConstants.cUserId] ?? '',
        name: map[DbConstants.cPerName],
        phone: map[DbConstants.cPerPhone],
        note: map[DbConstants.cPerNote],
        createdAt: DateTime.parse(map[DbConstants.cCreatedAt]),
        updatedAt: DateTime.parse(map[DbConstants.cUpdatedAt]),
      );
}
