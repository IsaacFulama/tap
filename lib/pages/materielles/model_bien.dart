import 'package:hive/hive.dart';

part 'model_bien.g.dart';

@HiveType(
  typeId: 3,
) // ⚠️ Utilise le typeId 3 pour éviter d'entrer en collision avec le Core Finance (1) et les Événements (2)
class AssetModel extends HiveObject {
  @HiveField(0)
  final String codeImmatriculation; // Code unique ex: INV-2026-001

  @HiveField(1)
  final String nom; // ex: "Console de mixage Behringer X32"

  @HiveField(2)
  final String categorie; // Électronique/Sono, Mobilier, Immobilier, Véhicule

  @HiveField(3)
  final double valeurAcquisition;

  @HiveField(4)
  final DateTime dateAcquisition;

  @HiveField(5)
  final int dureeVieAnnees; // Pour le calcul automatique de l'amortissement

  @HiveField(6)
  final String emplacement; // Bureau Pasteur, Sanctuaire, Annexe, Cellule...

  @HiveField(7)
  final String statut; // "Opérationnel", "En Maintenance", "En Panne", "Déclassé"

  @HiveField(8)
  final String responsable; // Diacre ou technicien en charge du matériel

  @HiveField(9)
  final String devise; // "USD" ou "CDF" pour l'ancrage monétaire du patrimoine

  AssetModel({
    required this.codeImmatriculation,
    required this.nom,
    required this.categorie,
    required this.valeurAcquisition,
    required this.dateAcquisition,
    required this.dureeVieAnnees,
    required this.emplacement,
    required this.statut,
    required this.responsable,
    required this.devise,
  });

  // =========================================================================
  // ⚙️ MOTEUR COMPTABLE : AMORTISSEMENT ET VALEUR COMPTABLE NETTE (VNC)
  // =========================================================================

  /// Calcule la Valeur Nette Comptable (VNC) actuelle de l'équipement
  double get valeurNetteComptable {
    if (dureeVieAnnees <= 0) return 0.0;

    final maintenant = DateTime.now();
    // Calcule la différence en jours pour une précision maximale
    final joursPossedes = maintenant.difference(dateAcquisition).inDays;
    final joursVieTotale = dureeVieAnnees * 365;

    if (joursPossedes <= 0) return valeurAcquisition;
    if (joursPossedes >= joursVieTotale) return 0.0; // Totalement amorti

    // Amortissement linéaire au prorata des jours consommés
    double amortissementCumule = (valeurAcquisition / joursVieTotale) * joursPossedes;
    return valeurAcquisition - amortissementCumule;
  }

  /// Indique le pourcentage d'usure financière du bien (0.0 = Neuf, 1.0 = Amorti)
  double get tauxUsure {
    if (valeurAcquisition == 0) return 1.0;
    return ((valeurAcquisition - valeurNetteComptable) / valeurAcquisition).clamp(0.0, 1.0);
  }

  // =========================================================================
  // ☁️ SYNCHRONISATION CLOUD : SERIALIZATION JSON FOR FIRESTORE
  // =========================================================================

  /// Convertit l'actif matériel en format JSON pour l'envoyer sur Firebase Firestore
  Map<String, dynamic> toJson() {
    return {
      'codeImmatriculation': codeImmatriculation,
      'nom': nom,
      'categorie': categorie,
      'valeurAcquisition': valeurAcquisition,
      'dateAcquisition': dateAcquisition.toIso8601String(),
      'dureeVieAnnees': dureeVieAnnees,
      'emplacement': emplacement,
      'statut': statut,
      'responsable': responsable,
      'devise': devise,
    };
  }

  /// Reconstruit l'objet AssetModel à partir des données téléchargées du Cloud
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      codeImmatriculation: json['codeImmatriculation'] as String,
      nom: json['nom'] as String,
      categorie: json['categorie'] as String,
      valeurAcquisition: (json['valeurAcquisition'] as num).toDouble(),
      dateAcquisition: DateTime.parse(json['dateAcquisition'] as String),
      dureeVieAnnees: json['dureeVieAnnees'] as int,
      emplacement: json['emplacement'] as String,
      statut: json['statut'] as String,
      responsable: json['responsable'] as String,
      devise: (json['devise'] ?? 'USD') as String, // Rétrocompatibilité Cloud assurée
    );
  }
}
