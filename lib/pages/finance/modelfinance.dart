import 'package:hive/hive.dart';

part 'modelfinance.g.dart';

@HiveType(typeId: 1)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String type; // "entree" ou "sortie"

  @HiveField(1)
  String categorie; // "Dîme", "Offrande", "Action de Grâce", "Social", etc.

  @HiveField(2)
  double montant;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String description;

  @HiveField(5)
  String evenement; // "Culte Dimanche", "Conférence", etc.

  @HiveField(6)
  String fondAssocie; // "Général", "Construction", "Social", "Évangélisation"

  @HiveField(7)
  String donateur; // Nom du fidèle ou "Anonyme"

  @HiveField(8)
  String devise; // "USD" ou "CDF"

  TransactionModel({
    required this.type,
    required this.categorie,
    required this.montant,
    required this.date,
    required this.description,
    required this.evenement,
    required this.fondAssocie,
    required this.donateur,
    required this.devise,
  });

  // ☁️ Convertit la transaction en format JSON pour l'envoyer sur Firebase Firestore
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'categorie': categorie,
      'montant': montant,
      'date': date.toIso8601String(), // Conversion du DateTime en texte pour le Cloud
      'description': description,
      'evenement': evenement,
      'fondAssocie': fondAssocie,
      'donateur': donateur,
      'devise': devise,
    };
  }

  // 📥 Reconstruit l'objet TransactionModel à partir des données téléchargées du Cloud
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      type: json['type'] as String,
      categorie: json['categorie'] as String,
      montant: (json['montant'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String), // Reconvertit le texte en DateTime
      description: json['description'] as String,
      evenement: json['evenement'] as String,
      fondAssocie:
          (json['fondAssocie'] ?? 'Général')
              as String, // Valeur par défaut pour éviter les crashs sur les anciennes lignes
      donateur: (json['donateur'] ?? 'Anonyme') as String,
      devise: (json['devise'] ?? 'USD') as String,
    );
  }
}
