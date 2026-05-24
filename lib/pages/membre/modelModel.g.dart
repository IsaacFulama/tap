// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modelModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MembreModelAdapter extends TypeAdapter<MembreModel> {
  @override
  final int typeId = 2;

  @override
  MembreModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MembreModel(
      nom: fields[0] as String,
      prenom: fields[1] as String,
      adresse: fields[2] as String,
      numTel: fields[3] as String,
      travail: fields[4] as String?,
      grade: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MembreModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.nom)
      ..writeByte(1)
      ..write(obj.prenom)
      ..writeByte(2)
      ..write(obj.adresse)
      ..writeByte(3)
      ..write(obj.numTel)
      ..writeByte(4)
      ..write(obj.travail)
      ..writeByte(5)
      ..write(obj.grade);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MembreModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
