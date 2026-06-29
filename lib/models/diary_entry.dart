/// Запись дневника самоконтроля.
class DiaryEntry {
  const DiaryEntry({
    this.id,
    required this.userId,
    required this.createdAtMillis,
    this.sugarMmolL,
    this.foodXe,
    this.foodPhotoPath,
    this.shortInsulinUnits,
    this.longInsulinUnits,
    this.comment,
    required this.isAfterMeal,
  });

  final int? id;
  final int userId;
  final int createdAtMillis;
  final double? sugarMmolL;
  final double? foodXe;
  final String? foodPhotoPath;
  final double? shortInsulinUnits;
  final double? longInsulinUnits;
  final String? comment;
  final bool isAfterMeal;

  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtMillis);

  Map<String, Object?> toRow() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'created_at': createdAtMillis,
      'sugar_mmol_l': sugarMmolL,
      'food_xe': foodXe,
      'food_photo_path': foodPhotoPath,
      'short_insulin_units': shortInsulinUnits,
      'long_insulin_units': longInsulinUnits,
      'comment': comment?.trim(),
      'is_after_meal': isAfterMeal ? 1 : 0,
    };
  }

  factory DiaryEntry.fromRow(Map<String, Object?> map) {
    return DiaryEntry(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      createdAtMillis: map['created_at'] as int,
      sugarMmolL: (map['sugar_mmol_l'] as num?)?.toDouble(),
      foodXe: (map['food_xe'] as num?)?.toDouble(),
      foodPhotoPath: map['food_photo_path'] as String?,
      shortInsulinUnits: (map['short_insulin_units'] as num?)?.toDouble(),
      longInsulinUnits: (map['long_insulin_units'] as num?)?.toDouble(),
      comment: map['comment'] as String?,
      isAfterMeal: (map['is_after_meal'] as int? ?? 0) == 1,
    );
  }
}
