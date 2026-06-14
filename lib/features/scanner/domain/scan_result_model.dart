import 'package:hive_flutter/hive_flutter.dart';

part 'scan_result_model.g.dart';

/// Enum representing the detected type of a scanned code.
@HiveType(typeId: 1)
enum ScanType {
  @HiveField(0)
  url,

  @HiveField(1)
  phone,

  @HiveField(2)
  email,

  @HiveField(3)
  sms,

  @HiveField(4)
  wifi,

  @HiveField(5)
  vcard,

  @HiveField(6)
  geo,

  @HiveField(7)
  text,
}

/// Represents a single scan result stored in Hive.
@HiveType(typeId: 0)
class ScanResultModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String rawContent;

  @HiveField(2)
  final ScanType type;

  @HiveField(3)
  final DateTime scannedAt;

  @HiveField(4)
  bool isFavorite;

  ScanResultModel({
    required this.id,
    required this.rawContent,
    required this.type,
    required this.scannedAt,
    this.isFavorite = false,
  });

  /// Returns a truncated preview of the raw content.
  String get preview {
    if (rawContent.length <= 60) return rawContent;
    return '${rawContent.substring(0, 57)}...';
  }

  ScanResultModel copyWith({
    String? id,
    String? rawContent,
    ScanType? type,
    DateTime? scannedAt,
    bool? isFavorite,
  }) {
    return ScanResultModel(
      id: id ?? this.id,
      rawContent: rawContent ?? this.rawContent,
      type: type ?? this.type,
      scannedAt: scannedAt ?? this.scannedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
