import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:untitled11/pages/finance/modelfinance.dart';
import 'package:untitled11/GlobalSyncService/global_sync_service.dart';

// =========================================================================
// 🧠 MOTEUR LOGIQUE ENRICHI : CHURCH FINTECH ENGINE
// =========================================================================
class ChurchFinanceEngine {
  final List<TransactionModel> transactions;
  final double budgetMensuel;
  final double tauxChange; // 1 USD = X CDF (ex: 2850)

  ChurchFinanceEngine({
    required this.transactions,
    required this.budgetMensuel,
    this.tauxChange = 2850.0,
  });

  double _getMontantEnUSD(TransactionModel tx) {
    return tx.devise == "CDF" ? tx.montant / tauxChange : tx.montant;
  }

  double get totalEntreesUSD {
    return transactions
        .where((tx) => tx.type == "entree")
        .fold(0.0, (sum, tx) => sum + _getMontantEnUSD(tx));
  }

  double get totalSortiesUSD {
    return transactions
        .where((tx) => tx.type == "sortie")
        .fold(0.0, (sum, tx) => sum + _getMontantEnUSD(tx));
  }

  double get soldeGlobalUSD => totalEntreesUSD - totalSortiesUSD;

  double get totalVolumeUSD {
    return transactions
        .where((tx) => tx.devise == "USD")
        .fold(0.0, (sum, tx) => sum + tx.montant);
  }

  double get totalVolumeCDF {
    return transactions
        .where((tx) => tx.devise == "CDF")
        .fold(0.0, (sum, tx) => sum + tx.montant);
  }

  double totalParFond(String fond) {
    return transactions
        .where((tx) => tx.fondAssocie == fond)
        .fold(
          0.0,
          (sum, tx) =>
              sum +
              (tx.type == "entree"
                  ? _getMontantEnUSD(tx)
                  : -_getMontantEnUSD(tx)),
        );
  }

  double get ratioSolidarite {
    double social = transactions
        .where((tx) => tx.fondAssocie == "Social" && tx.type == "sortie")
        .fold(0.0, (sum, tx) => sum + _getMontantEnUSD(tx));
    if (totalSortiesUSD == 0) return 0.0;
    return social / totalSortiesUSD;
  }

  String get categorieLaPlusDepensiere {
    final Map<String, double> mapCategories = {};
    final sorties = transactions.where((tx) => tx.type == "sortie");
    if (sorties.isEmpty) return "Aucune";

    for (var tx in sorties) {
      mapCategories[tx.categorie] =
          (mapCategories[tx.categorie] ?? 0.0) + _getMontantEnUSD(tx);
    }
    if (mapCategories.isEmpty) return "Aucune";

    var tri = mapCategories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return tri.first.key;
  }

  double get tauxConsommationBudget =>
      (totalSortiesUSD / budgetMensuel).clamp(0.0, 1.0);

  Color get couleurRisque {
    double taux = tauxConsommationBudget;
    if (taux >= 0.9) return Colors.redAccent;
    if (taux >= 0.7) return Colors.orangeAccent;
    return Colors.green;
  }
}

// =========================================================================
// 🎨 INTERFACE UTILISATEUR COMPLÈTE (UI)
// =========================================================================
class Finances extends StatefulWidget {
  const Finances({super.key});

  @override
  State<Finances> createState() => _FinancesState();
}

class _FinancesState extends State<Finances> {
  late final Box<TransactionModel> box;
  bool _isBoxInitialized = false;
  final GlobalSyncService _syncService = GlobalSyncService();

  List<TransactionModel> toutesLesTransactions = [];
  List<TransactionModel> transactionsFiltrees = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _evenementController = TextEditingController();
  final TextEditingController _donateurController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController()
    ..text = "2500";
  final TextEditingController _tauxController = TextEditingController()
    ..text = "2850";

  String _typeSelectionne = "entree";
  String _categorieSelectionnee = "Dîme";
  String _fondSelectionne = "Général";
  String _deviseSelectionnee = "USD";

  String _filtreTemporel = "Tout";
  String _filtreFlux = "Tout Flux";
  String _filtreFond = "Tous Fonds";
  bool _isSaving = false;

  final formatUSD = NumberFormat.currency(symbol: "\$ ", decimalDigits: 2);
  final formatCDF = NumberFormat.currency(
    symbol: "FC ",
    decimalDigits: 0,
    locale: "fr_FR",
  );

  @override
  void initState() {
    super.initState();
    try {
      box = Hive.box<TransactionModel>("finances");
      _isBoxInitialized = true;
      _synchroniserDonnees();
    } catch (e) {
      _isBoxInitialized = false;
    }
  }

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    _evenementController.dispose();
    _donateurController.dispose();
    _searchController.dispose();
    _budgetController.dispose();
    _tauxController.dispose();
    super.dispose();
  }

  double get _tauxActuel => double.tryParse(_tauxController.text) ?? 2850.0;

  void _synchroniserDonnees() {
    if (!_isBoxInitialized || !mounted) return;
    final list = box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      toutesLesTransactions = list;
    });
    _appliquerFiltresCombines();
  }

  void _appliquerFiltresCombines() {
    final maintenant = DateTime.now();
    List<TransactionModel> resultat = List.from(toutesLesTransactions);

    if (_filtreTemporel == "Mois") {
      resultat = resultat
          .where(
            (tx) =>
                tx.date.month == maintenant.month &&
                tx.date.year == maintenant.year,
          )
          .toList();
    } else if (_filtreTemporel == "Année") {
      resultat = resultat
          .where((tx) => tx.date.year == maintenant.year)
          .toList();
    }

    if (_filtreFlux == "Entrées") {
      resultat = resultat.where((tx) => tx.type == "entree").toList();
    } else if (_filtreFlux == "Sorties") {
      resultat = resultat.where((tx) => tx.type == "sortie").toList();
    }

    if (_filtreFond != "Tous Fonds") {
      resultat = resultat.where((tx) => tx.fondAssocie == _filtreFond).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      resultat = resultat.where((tx) {
        return tx.description.toLowerCase().contains(query) ||
            tx.categorie.toLowerCase().contains(query) ||
            tx.donateur.toLowerCase().contains(query) ||
            tx.evenement.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      transactionsFiltrees = resultat;
    });
  }

  ChurchFinanceEngine _buildEngine(List<TransactionModel> targetList) {
    double budget = double.tryParse(_budgetController.text) ?? 2500.0;
    return ChurchFinanceEngine(
      transactions: targetList,
      budgetMensuel: budget,
      tauxChange: _tauxActuel,
    );
  }

  Future<void> _exporterRapportPDF() async {
    if (transactionsFiltrees.isEmpty) return;

    final pdf = pw.Document();
    final dateDuJour = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final fontStyle = pw.TextStyle(font: pw.Font.helvetica());
    final fontBold = pw.TextStyle(
      font: pw.Font.helveticaBold(),
      fontWeight: pw.FontWeight.bold,
    );

    final filteredEngine = _buildEngine(transactionsFiltrees);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "RAPPORT COMPTABLE ECCLÉSIASTIQUE",
                    style: fontBold.copyWith(fontSize: 16),
                  ),
                  pw.Text(
                    "Fonds : $_filtreFond | Flux : $_filtreFlux | Période : $_filtreTemporel",
                    style: fontStyle.copyWith(fontSize: 10),
                  ),
                  pw.Text(
                    "Généré le : $dateDuJour",
                    style: fontStyle.copyWith(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Text(
                "Trésorerie Centrale",
                style: fontBold.copyWith(
                  fontSize: 12,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 10),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPdfCard(
                "SOLDE SÉLECTION (USD)",
                formatUSD.format(filteredEngine.soldeGlobalUSD),
                PdfColors.green800,
                fontStyle,
                fontBold,
              ),
              _buildPdfCard(
                "TOTAL ENTRÉES",
                formatUSD.format(filteredEngine.totalEntreesUSD),
                PdfColors.blue800,
                fontStyle,
                fontBold,
              ),
              _buildPdfCard(
                "TOTAL SORTIES",
                formatUSD.format(filteredEngine.totalSortiesUSD),
                PdfColors.red800,
                fontStyle,
                fontBold,
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      "Date",
                      style: fontBold.copyWith(fontSize: 9),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      "Donateur / Source",
                      style: fontBold.copyWith(fontSize: 9),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      "Catégorie (Fond)",
                      style: fontBold.copyWith(fontSize: 9),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      "Montant Saisi",
                      style: fontBold.copyWith(fontSize: 9),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
              ...transactionsFiltrees.map((tx) {
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        DateFormat('dd/MM/yyyy').format(tx.date),
                        style: fontStyle.copyWith(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "${tx.donateur} (${tx.evenement})",
                        style: fontStyle.copyWith(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "${tx.categorie} [${tx.fondAssocie}]",
                        style: fontStyle.copyWith(fontSize: 8),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        "${tx.type == 'entree' ? '+' : '-'} ${tx.devise == 'USD' ? formatUSD.format(tx.montant) : formatCDF.format(tx.montant)}",
                        style: fontBold.copyWith(
                          fontSize: 8,
                          color: tx.type == 'entree'
                              ? PdfColors.green700
                              : PdfColors.red700,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Rapport_Eglise_${_filtreFond}.pdf',
    );
  }

  static pw.Widget _buildPdfCard(
    String title,
    String val,
    PdfColor color,
    pw.TextStyle s,
    pw.TextStyle b,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: s.copyWith(fontSize: 7)),
          pw.Text(val, style: b.copyWith(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  void _ouvrirFormulaireAjout() {
    _montantController.clear();
    _descriptionController.clear();
    _evenementController.text = "Culte Dimanche";
    _donateurController.text = "Anonyme";
    _typeSelectionne = "entree";
    _categorieSelectionnee = "Dîme";
    _fondSelectionne = "Général";
    _deviseSelectionnee = "USD";
    _isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          List<String> categories = _typeSelectionne == "entree"
              ? [
                  "Dîme",
                  "Offrande Ordinaire",
                  "Action de Grâce",
                  "Don Spécial",
                  "Sponsoring",
                ]
              : [
                  "Soutien Social / Veuves",
                  "Achat Équipements",
                  "Logistique & Transports",
                  "Factures Eau/Électricité",
                  "Ministère Étranger",
                ];

          List<String> fonds = [
            "Général",
            "Construction",
            "Social",
            "Évangélisation",
          ];

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ), // 🛠️ FIX ECOULEMENT ÉCRAN
            title: const Text(
              "Nouvelle Écriture Comptable",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                // 🛠️ FIX CLAVIER : Évite le crash d'overlap quand le clavier s'affiche
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text(
                            "Recette",
                            style: TextStyle(fontSize: 12),
                          ),
                          selected: _typeSelectionne == "entree",
                          selectedColor: Colors.green[100],
                          onSelected: (s) => setDialogState(() {
                            if (s) _typeSelectionne = "entree";
                            _categorieSelectionnee = "Dîme";
                          }),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text(
                            "Dépense",
                            style: TextStyle(fontSize: 12),
                          ),
                          selected: _typeSelectionne == "sortie",
                          selectedColor: Colors.red[100],
                          onSelected: (s) => setDialogState(() {
                            if (s) _typeSelectionne = "sortie";
                            _categorieSelectionnee = "Soutien Social / Veuves";
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 85,
                          child: DropdownButtonFormField<String>(
                            initialValue: _deviseSelectionnee,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              labelText: "Devise",
                            ),
                            items: ["USD", "CDF"]
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => _deviseSelectionnee = v!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _montantController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: "Montant",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _categorieSelectionnee,
                      decoration: const InputDecoration(
                        labelText: "Type de Mouvement",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      items: categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => _categorieSelectionnee = value!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _fondSelectionne,
                      decoration: const InputDecoration(
                        labelText: "Affectation au Fond / Caisse",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      items: fonds
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                "Fond $f",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => _fondSelectionne = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _donateurController,
                      decoration: const InputDecoration(
                        labelText: "Donateur / Bénéficiaire",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _evenementController,
                      decoration: const InputDecoration(
                        labelText: "Provenance / Événement",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Notes complémentaires",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving
                    ? null
                    : () async {
                        final txtMontant = _montantController.text.trim();
                        if (txtMontant.isEmpty) return;
                        final montant = double.tryParse(
                          txtMontant.replaceAll(',', '.'),
                        );
                        if (montant == null || montant <= 0) return;

                        setDialogState(() => _isSaving = true);

                        TransactionModel tx = TransactionModel(
                          type: _typeSelectionne,
                          categorie: _categorieSelectionnee,
                          montant: montant,
                          date: DateTime.now(),
                          description: _descriptionController.text.trim(),
                          evenement: _evenementController.text.trim(),
                          fondAssocie: _fondSelectionne,
                          donateur: _donateurController.text.trim(),
                          devise: _deviseSelectionnee,
                        );

                        await box.add(tx);
                        _synchroniserDonnees();
                        Navigator.pop(context);

                        try {
                          String txId = DateTime.now().millisecondsSinceEpoch
                              .toString();
                          await _syncService.saveTransaction(tx, txId);
                        } catch (e) {
                          debugPrint("⚠️ Échec Synchro Cloud: $e");
                        }
                      },
                child: const Text("Enregistrer"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    final globalEngine = _buildEngine(toutesLesTransactions);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "AMOUR PARFAIT Analyse",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_applications, size: 20),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Configurations"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Budget Sorties Max (USD)",
                      ),
                    ),
                    TextField(
                      controller: _tauxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Taux de Change (1 USD = X CDF)",
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      _synchroniserDonnees();
                      Navigator.pop(context);
                    },
                    child: const Text("Appliquer"),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            onPressed: transactionsFiltrees.isEmpty
                ? null
                : _exporterRapportPDF,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: _ouvrirFormulaireAjout,
        icon: const Icon(Icons.add),
        label: const Text("Nouveau Mouvement", style: TextStyle(fontSize: 12)),
      ),
      body: Column(
        children: [
          // 📊 EN-TÊTE COMPTABLE ADAPTATIF
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "TRÉSORERIE GLOBALE NETTE UNIFIÉE",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatUSD.format(globalEngine.soldeGlobalUSD),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      color: globalEngine.couleurRisque,
                      child: Text(
                        "SANTÉ : ${globalEngine.tauxConsommationBudget >= 0.9 ? 'ALERTE' : 'STABLE'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text(
                  "CONSOMMATION DU BUDGET MENSUEL",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: globalEngine.tauxConsommationBudget,
                    minHeight: 5,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      globalEngine.couleurRisque,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Dépenses : ${formatUSD.format(globalEngine.totalSortiesUSD)}",
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      "${(globalEngine.tauxConsommationBudget * 100).toStringAsFixed(0)}% du plafond",
                      style: TextStyle(
                        color: globalEngine.couleurRisque,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Text(
                  "RÉPARTITION DU VOLUME PAR DEVISE (SAISIE BRUTE)",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final usdVol = globalEngine.totalVolumeUSD;
                    final cdfVol = globalEngine.totalVolumeCDF;
                    final totalVol = usdVol + (cdfVol / _tauxActuel);
                    final double pctUSD = totalVol > 0
                        ? (usdVol / totalVol).clamp(0.0, 1.0)
                        : 0.5;

                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: (pctUSD * 100).round().clamp(1, 99),
                                child: Container(
                                  height: 5,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              Expanded(
                                flex: ((1 - pctUSD) * 100).round().clamp(1, 99),
                                child: Container(
                                  height: 5,
                                  color: Colors.amberAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "USD: ${formatUSD.format(usdVol)}",
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "CDF: ${formatCDF.format(cdfVol)}",
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Évitement de débordements sur les lignes de fonds
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Général: ${formatUSD.format(globalEngine.totalParFond('Général'))}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "Construc.: ${formatUSD.format(globalEngine.totalParFond('Construction'))}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        textAlign: appRight,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "Social: ${formatUSD.format(globalEngine.totalParFond('Social'))}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "Ratio Social: ${(globalEngine.ratioSolidarite * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🎛️ FILTRES TRIPLE ZONE CONFIGURÉS POUR L'AFFICHAGE MOBILE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          initialValue: _filtreTemporel,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            border: OutlineInputBorder(),
                            labelText: "Temps",
                            labelStyle: TextStyle(fontSize: 11),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                          items: ["Tout", "Mois", "Année"]
                              .map(
                                (f) =>
                                    DropdownMenuItem(value: f, child: Text(f)),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => _filtreTemporel = v!);
                            _appliquerFiltresCombines();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          initialValue: _filtreFond,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            border: OutlineInputBorder(),
                            labelText: "Caisse/Fond",
                            labelStyle: TextStyle(fontSize: 11),
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black,
                          ),
                          items:
                              [
                                    "Tous Fonds",
                                    "Général",
                                    "Construction",
                                    "Social",
                                    "Évangélisation",
                                  ]
                                  .map(
                                    (f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(f),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            setState(() => _filtreFond = v!);
                            _appliquerFiltresCombines();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: ["Tout Flux", "Entrées", "Sorties"].map((flux) {
                    final isSel = _filtreFlux == flux;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          label: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Text(
                              flux,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSel ? Colors.white : Colors.black54,
                              ),
                            ),
                          ),
                          selected: isSel,
                          selectedColor: Colors.blueGrey[800],
                          showCheckmark: false,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onSelected: (v) {
                            if (v) {
                              setState(() => _filtreFlux = flux);
                              _appliquerFiltresCombines();
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 🔍 RECHERCHE TEXTUELLE MALIGNE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _appliquerFiltresCombines(),
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: "Rechercher un fidèle, un culte, un tag...",
                  hintStyle: TextStyle(fontSize: 12),
                  prefixIcon: Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 📜 GRAND LIVRE DES COMPTES RESILIENT
          Expanded(
            child: transactionsFiltrees.isEmpty
                ? const Center(
                    child: Text(
                      "Aucun enregistrement trouvé.",
                      style: TextStyle(fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: transactionsFiltrees.length,
                    itemBuilder: (context, index) {
                      final tx = transactionsFiltrees[index];
                      final bool isEntree = tx.type == "entree";

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isEntree
                                ? Colors.green[50]
                                : Colors.red[50],
                            child: Icon(
                              isEntree
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isEntree ? Colors.green : Colors.red,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            "${tx.donateur} • ${tx.evenement}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              "${tx.categorie} [Fond ${tx.fondAssocie}]\n${DateFormat('dd/MM/yyyy à HH:mm').format(tx.date)}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${isEntree ? '+' : '-'} ${tx.devise == 'USD' ? formatUSD.format(tx.montant) : formatCDF.format(tx.montant)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isEntree
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Alignement Helper pour éviter les constantes globales
const TextAlign appRight = TextAlign.right;
