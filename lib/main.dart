import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart'; // Généré via la CLI FlutterFire

// Importations des modèles de données
import 'package:untitled11/pages/connexion/inscription.dart';
import 'package:untitled11/pages/membre/modelModel.dart'; // Contient MembreModel
import 'package:untitled11/pages/finance/modelfinance.dart';
import 'package:untitled11/pages/materielles/model_bien.dart';

// Importation du service de synchronisation
import 'package:untitled11/GlobalSyncService/global_sync_service.dart';

void main() async {
  // 1. Assure la liaison avec le moteur Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialise Firebase (Essentiel pour l'authentification et Firestore)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Initialise Hive pour la mise en cache locale
  await Hive.initFlutter();

  // 4. Enregistre les adaptateurs Hive en vérifiant l'absence de doublons
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TransactionModelAdapter()); // ID 1 : Finances
  }

  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(MembreModelAdapter()); // ID 2 : Membres
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(AssetModelAdapter()); // ID 3 : Matériels & Biens
  }

  // Ne jamais supprimer automatiquement les boîtes Hive au démarrage :
  // elles contiennent les données locales des membres, finances et biens.
  // Une réparation de données doit être explicite et précédée d'une sauvegarde.

  // 5. Ouvre à nouveau les boîtes de stockage sur des bases saines et propres
  await Hive.openBox<MembreModel>("membres_eglise");
  await Hive.openBox<TransactionModel>("finances");
  await Hive.openBox<AssetModel>("biens_eglise");

  // 6. Initialisation de la synchronisation Cloud Firestore
  final syncService = GlobalSyncService();

  // Étape A : Télécharge les données depuis Firestore vers Hive si l'appareil est neuf
  await syncService.recupererDonneesDistantes();

  // Étape B : Active l'écouteur réactif (Hive -> Firebase)
  syncService.initialiserLaSynchronisation();

  // 7. Démarre l'interface graphique
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Amour Parfait Tab',
      debugShowCheckedModeBanner: false,
      home: Inscription(), // Redirige directement sur ton écran d'inscription sécurisé
    );
  }
}
