// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_result_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanResultModelAdapter extends TypeAdapter<ScanResultModel> {
  @override
  final int typeId = 0;

  @override
  ScanResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanResultModel(
      id: fields[0] as String,
      rawContent: fields[1] as String,
      type: fields[2] as ScanType,
      scannedAt: fields[3] as DateTime,
      isFavorite: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ScanResultModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.rawContent)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.scannedAt)
      ..writeByte(4)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScanTypeAdapter extends TypeAdapter<ScanType> {
  @override
  final int typeId = 1;

  @override
  ScanType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScanType.url;
      case 1:
        return ScanType.phone;
      case 2:
        return ScanType.email;
      case 3:
        return ScanType.sms;
      case 4:
        return ScanType.wifi;
      case 5:
        return ScanType.vcard;
      case 6:
        return ScanType.geo;
      case 7:
        return ScanType.text;
      default:
        return ScanType.text;
    }
  }

  @override
  void write(BinaryWriter writer, ScanType obj) {
    switch (obj) {
      case ScanType.url:
        writer.writeByte(0);
      case ScanType.phone:
        writer.writeByte(1);
      case ScanType.email:
        writer.writeByte(2);
      case ScanType.sms:
        writer.writeByte(3);
      case ScanType.wifi:
        writer.writeByte(4);
      case ScanType.vcard:
        writer.writeByte(5);
      case ScanType.geo:
        writer.writeByte(6);
      case ScanType.text:
        writer.writeByte(7);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
