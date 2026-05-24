import 'package:hive/hive.dart';

part 'modelModel.g.dart';

@HiveType(typeId: 2) // Utilise un typeId unique (ex: 2 pour éviter les conflits avec tes actifs)
class MembreModel extends HiveObject {
  @HiveField(0)
  final String nom;

  @HiveField(1)
  final String prenom;

  @HiveField(2)
  final String adresse;

  @HiveField(3)
  final String numTel;

  @HiveField(4)
  final String? travail; // 🟢 Optionnel (Nullable)

  @HiveField(5)
  final String grade;

  MembreModel({
    required this.nom,
    required this.prenom,
    required this.adresse,
    required this.numTel,
    this.travail,
    required this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'adresse': adresse,
      'numTel': numTel,
      'travail': travail,
      'grade': grade,
    };
  }

  // 2. Recrée l'objet à partir des données Firebase
  factory MembreModel.fromJson(Map<String, dynamic> json) {
    return MembreModel(
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      adresse: json['adresse'] as String,
      numTel: json['numTel'] as String,
      travail: json['travail'] as String?,
      grade: json['grade'] as String,
    );
  }
}
