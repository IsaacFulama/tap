// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evenModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 2;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      type: fields[0] as String,
      categorie: fields[1] as String,
      montant: fields[2] as double,
      date: fields[3] as DateTime,
      description: fields[4] as String,
      evenement: fields[5] as String,
      fondAssocie: fields[6] as String,
      donateur: fields[7] as String,
      devises: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.categorie)
      ..writeByte(2)
      ..write(obj.montant)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.evenement)
      ..writeByte(6)
      ..write(obj.fondAssocie)
      ..writeByte(7)
      ..write(obj.donateur)
      ..writeByte(8)
      ..write(obj.devises);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
