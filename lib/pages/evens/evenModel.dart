import 'package:hive/hive.dart';

part 'evenModel.g.dart';

@HiveType(
  typeId: 2,
) // ⚠️ Utilise un typeId différent (ex: 2) pour éviter tout conflit avec l'autre modèle dans Hive
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String type; // "entree" ou "sortie"

  @HiveField(1)
  final String categorie; // "Offrande Spéciale", "Action de Grâce", "Logistique"

  @HiveField(2)
  final double montant;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String evenement; // Le nom de l'événement (ex: "Convention Annuelle 2026", "Fête des Mamans")

  @HiveField(6)
  final String fondAssocie; // "Général", "Construction", "Social", etc.

  @HiveField(7)
  final String donateur; // Nom du fidèle, de la cellule de réveil ou "Anonyme"

  @HiveField(8)
  final String devises; // "USD" ou "CDF"

  TransactionModel({
    required this.type,
    required this.categorie,
    required this.montant,
    required this.date,
    required this.description,
    required this.evenement,
    required this.fondAssocie,
    required this.donateur,
    required this.devises,
  });

  // ☁️ MATION CLOUD : Convertit l'événement en format Map/JSON pour l'envoyer vers Firebase Firestore
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'categorie': categorie,
      'montant': montant,
      'date': date.toIso8601String(), // Conversion du DateTime en String ISO pour le Cloud
      'description': description,
      'evenement': evenement,
      'fondAssocie': fondAssocie,
      'donateur': donateur,
      'devises': devises,
    };
  }

  // 📥 MATION CLOUD : Reconstruit l'objet à partir des données récupérées depuis le Cloud (Firebase)
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      type: json['type'] as String,
      categorie: json['categorie'] as String,
      montant: (json['montant'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String), // Parse la chaîne ISO en DateTime local
      description: json['description'] as String,
      evenement: json['evenement'] as String,
      fondAssocie: (json['fondAssocie'] ?? 'Général') as String,
      donateur: (json['donateur'] ?? 'Anonyme') as String,
      devises: (json['devises'] ?? 'USD') as String,
    );
  }
}
