import 'package:objectbox/objectbox.dart';
import 'package:earnjoy/data/models/category.dart';

/// A user-defined activity template for quick-logging.
/// Stored in ObjectBox so users can add/edit/delete their own presets.
@Entity()
class ActivityPreset {
  @Id()
  int id = 0;

  String title;
  int durationMinutes;

  /// Whether this was seeded as a default (prevents accidental deletion of all defaults).
  bool isDefault;

  /// Link to the Category entity.
  final category = ToOne<Category>();

  ActivityPreset({
    this.id = 0,
    required this.title,
    required this.durationMinutes,
    this.isDefault = false,
  });

  ActivityPreset copyWith({int? id, String? title, int? durationMinutes, bool? isDefault}) {
    return ActivityPreset(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
