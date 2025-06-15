// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DraftModelAdapter extends TypeAdapter<DraftModel> {
  @override
  final int typeId = 0;

  @override
  DraftModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DraftModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      topics: (fields[3] as List).cast<String>(),
      imagePaths: (fields[4] as List).cast<String>(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DraftModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.topics)
      ..writeByte(4)
      ..write(obj.imagePaths)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
