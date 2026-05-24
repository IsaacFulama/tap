// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_bien.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetModelAdapter extends TypeAdapter<AssetModel> {
  @override
  final int typeId = 3;

  @override
  AssetModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetModel(
      codeImmatriculation: fields[0] as String,
      nom: fields[1] as String,
      categorie: fields[2] as String,
      valeurAcquisition: fields[3] as double,
      dateAcquisition: fields[4] as DateTime,
      dureeVieAnnees: fields[5] as int,
      emplacement: fields[6] as String,
      statut: fields[7] as String,
      responsable: fields[8] as String,
      devise: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AssetModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.codeImmatriculation)
      ..writeByte(1)
      ..write(obj.nom)
      ..writeByte(2)
      ..write(obj.categorie)
      ..writeByte(3)
      ..write(obj.valeurAcquisition)
      ..writeByte(4)
      ..write(obj.dateAcquisition)
      ..writeByte(5)
      ..write(obj.dureeVieAnnees)
      ..writeByte(6)
      ..write(obj.emplacement)
      ..writeByte(7)
      ..write(obj.statut)
      ..writeByte(8)
      ..write(obj.responsable)
      ..writeByte(9)
      ..write(obj.devise);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
