class AppCategoryModel {
  final String id;
  final String? userId;
  final String name;
  final String emoji;
  final String type;
  final bool isDefault;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppCategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    required this.type,
    required this.isDefault,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppCategoryModel.fromMap(Map<String, dynamic> map) {
    return AppCategoryModel(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      name: map['name'] as String,
      emoji: map['emoji'] as String? ?? '📁',
      type: map['type'] as String,
      isDefault: map['is_default'] as bool? ?? false,
      isDeleted: map['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'emoji': emoji,
      'type': type,
      'is_default': isDefault,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AppCategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? emoji,
    String? type,
    bool? isDefault,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppCategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
