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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase, Hive et les adaptateurs avant de démarrer l'application.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TransactionModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(MembreModelAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(AssetModelAdapter());
  }

  // IMPORTANT : ne jamais supprimer les boîtes Hive au démarrage.
  // Les données locales contiennent les finances, les membres et le patrimoine.
  // Une migration ou une réparation doit être explicite et préserver une sauvegarde.
  await Hive.openBox<MembreModel>("membres_eglise");
  await Hive.openBox<TransactionModel>("finances");
  await Hive.openBox<AssetModel>("biens_eglise");

  final syncService = GlobalSyncService();
  await syncService.recupererDonneesDistantes();
  syncService.initialiserLaSynchronisation();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Amour Parfait Tab',
      debugShowCheckedModeBanner: false,
      home: Inscription(),
    );
  }
}
