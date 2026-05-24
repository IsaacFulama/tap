import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:untitled11/pages/materielles/model_bien.dart';
import 'package:untitled11/pages/membre/modelModel.dart';
import 'package:untitled11/pages/finance/modelfinance.dart'; // 🛠️ Import de ton modèle Finance

class GlobalSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Box<AssetModel> _assetBox = Hive.box<AssetModel>("biens_eglise");
  final Box<MembreModel> _membreBox = Hive.box<MembreModel>("membres_eglise");

  /// Écoute les modifications du patrimoine local pour Cloud Firestore
  void initialiserLaSynchronisation() {
    _assetBox.listenable().addListener(() async {
      for (var key in _assetBox.keys) {
        final asset = _assetBox.get(key);
        if (asset != null) {
          await _firestore
              .collection('patrimoine')
              .doc(asset.codeImmatriculation)
              .set(asset.toJson());
        }
      }
    });
  }

  /// Sauvegarde un membre sur Firebase Firestore
  Future<void> saveMembre(MembreModel membre, String documentId) async {
    await _firestore.collection('membres').doc(documentId).set({
      'nom': membre.nom,
      'prenom': membre.prenom,
      'adresse': membre.adresse,
      'numTel': membre.numTel,
      'travail': membre.travail,
      'grade': membre.grade,
    });
  }

  /// 🟢 AJOUT : Sauvegarde une transaction financière sur Firebase Firestore
  Future<void> saveTransaction(TransactionModel tx, String documentId) async {
    await _firestore.collection('finances').doc(documentId).set({
      'type': tx.type, // 'entree' ou 'sortie'
      'categorie': tx.categorie, // 'Dîme', 'Offrande', etc.
      'montant': tx.montant,
      'date': tx.date.toIso8601String(), // Conversion de la date pour Firestore
      'description': tx.description,
      'evenement': tx.evenement,
      'fondAssocie': tx.fondAssocie, // 'Général', 'Construction', etc.
      'donateur': tx.donateur,
      'devise': tx.devise, // 'USD' ou 'CDF'
    });
  }

  /// Récupère le patrimoine depuis Firebase au démarrage si le cache local est vide
  Future<void> recupererDonneesDistantes() async {
    try {
      if (_assetBox.isEmpty) {
        final snapshot = await _firestore.collection('patrimoine').get();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final asset = AssetModel.fromJson(data);
          await _assetBox.put(doc.id, asset);
        }
      }
    } catch (e) {
      print("Mode Offline ou erreur Firebase : $e");
    }
  }
}
