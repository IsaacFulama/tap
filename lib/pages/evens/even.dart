import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:untitled11/pages/finance/modelfinance.dart';

// =========================================================================
// 🧠 MOTEUR BI INTELLIGENT : CHURCH FINTECH ENGINE UNIFIÉ
// =========================================================================
class FinanceEngine {
  final List<TransactionModel> transactions;
  final double budgetMensuel;
  final String evenementCible;
  final double tauxChange; // 1 USD = X CDF

  FinanceEngine({
    required this.transactions,
    required this.budgetMensuel,
    required this.evenementCible,
    this.tauxChange = 2850.0,
  });

  double _getMontantEnUSD(TransactionModel tx) {
    return tx.devise == "CDF" ? tx.montant / tauxChange : tx.montant;
  }

  double get totalEntrees => transactions
      .where((tx) => tx.type == "entree")
      .fold(0.0, (sum, tx) => sum + _getMontantEnUSD(tx));
  double get totalSorties => transactions
      .where((tx) => tx.type == "sortie")
      .fold(0.0, (sum, tx) => sum + _getMontantEnUSD(tx));
  double get soldeGlobal => totalEntrees - totalSorties;

  double get panierMoyen {
    if (transactions.isEmpty) return 0.0;
    return transactions.fold(0.0, (sum, tx) => sum + _getMontantEnUSD(tx)) / transactions.length;
  }

  double totalParFond(String fond) {
    return transactions.where((tx) => tx.fondAssocie == fond).fold(0.0, (sum, tx) {
      double val = _getMontantEnUSD(tx);
      return sum + (tx.type == "entree" ? val : -val);
    });
  }

  double get ratioSolidarite {
    double social = transactions
        .where((tx) => tx.fondAssocie == "Social" && tx.type == "sortie")
        .fold(0.0, (sum, tx) => sum + _getMontantEnUSD(tx));
    if (totalSorties == 0) return 0.0;
    return social / totalSorties;
  }

  double get balanceEvenementCible {
    if (evenementCible == "Aucun") return 0.0;
    final txEv = transactions.where((tx) => tx.evenement == evenementCible);
    double entrees = txEv
        .where((tx) => tx.type == "entree")
        .fold(0.0, (sum, tx) => sum + _getMontantEnUSD(tx));
    double sorties = txEv
        .where((tx) => tx.type == "sortie")
        .fold(0.0, (sum, tx) => sum + _getMontantEnUSD(tx));
    return entrees - sorties;
  }

  double get tauxConsommationBudget {
    if (budgetMensuel <= 0) return 0.0;
    return (totalSorties / budgetMensuel).clamp(0.0, 1.0);
  }

  String get niveauRisqueBudget {
    double taux = tauxConsommationBudget;
    if (taux >= 0.9) return "CRITIQUE";
    if (taux >= 0.7) return "MODÉRÉ";
    return "FAIBLE";
  }

  Color get couleurRisque {
    double taux = tauxConsommationBudget;
    if (taux >= 0.9) return Colors.red;
    if (taux >= 0.7) return Colors.orange;
    return Colors.green;
  }

  double get projectionFinMois {
    final maintenant = DateTime.now();
    final transactions30Jours = transactions.where(
      (tx) => maintenant.difference(tx.date).inDays <= 30 && tx.type == "sortie",
    );
    if (transactions30Jours.isEmpty) return soldeGlobal;

    double depenses30Jours = transactions30Jours.fold(0.0, (sum, tx) => sum + _getMontantEnUSD(tx));
    int joursRestants = DateTime(maintenant.year, maintenant.month + 1, 0).day - maintenant.day;
    return soldeGlobal - ((depenses30Jours / 30) * joursRestants);
  }
}

// =========================================================================
// 🎨 INTERFACE DE PRODUCTION : NOVA PAY ECOSYSTEM (CHURCH EDITION)
// =========================================================================
class NovaPayFinancePage extends StatefulWidget {
  const NovaPayFinancePage({super.key});

  @override
  State<NovaPayFinancePage> createState() => _NovaPayFinancePageState();
}

class _NovaPayFinancePageState extends State<NovaPayFinancePage> {
  final Box<TransactionModel> box = Hive.box<TransactionModel>("finances");

  List<TransactionModel> toutesLesTransactions = [];
  List<TransactionModel> transactionsFiltrees = [];

  final List<String> _listeEvenementsDisponibles = [
    "Aucun",
    "Culte Dimanche",
    "Conférence Annuelle",
    "Campagne d'Évangélisation",
    "Séminaire d'Enseignement",
    "Mariage / Fête",
  ];

  final List<String> _listeFonds = [
    "Tous Fonds",
    "Général",
    "Construction",
    "Social",
    "Évangélisation",
  ];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _donateurController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController()..text = "2000";
  final TextEditingController _tauxController = TextEditingController()..text = "2850";

  String _typeSelectionne = "entree";
  String _categorieSelectionnee = "Dîme";
  String _evenementSelectionneFormulaire = "Aucun";
  String _fondSelectionneFormulaire = "Général";
  String _deviseSelectionnee = "USD";

  String _filtreTemporel = "Tout";
  String _filtreFlux = "Tout Flux";
  String _filtreEvenement = "Aucun";
  String _filtreFond = "Tous Fonds";

  final formatUSD = NumberFormat.currency(symbol: "\$ ", decimalDigits: 2);
  final formatCDF = NumberFormat.currency(symbol: "FC ", decimalDigits: 0, locale: "fr_FR");
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _synchroniserDonnees();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    _donateurController.dispose();
    _searchController.dispose();
    _budgetController.dispose();
    _tauxController.dispose();
    super.dispose();
  }

  double get _tauxActuel => double.tryParse(_tauxController.text) ?? 2850.0;

  void _synchroniserDonnees() {
    if (!box.isOpen) return;
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
          .where((tx) => tx.date.month == maintenant.month && tx.date.year == maintenant.year)
          .toList();
    } else if (_filtreTemporel == "Mois Dernier") {
      int moisPrecedent = maintenant.month == 1 ? 12 : maintenant.month - 1;
      int anneeAssociee = maintenant.month == 1 ? maintenant.year - 1 : maintenant.year;
      resultat = resultat
          .where((tx) => tx.date.month == moisPrecedent && tx.date.year == anneeAssociee)
          .toList();
    } else if (_filtreTemporel == "Année") {
      resultat = resultat.where((tx) => tx.date.year == maintenant.year).toList();
    }

    if (_filtreFlux == "Entrées") {
      resultat = resultat.where((tx) => tx.type == "entree").toList();
    } else if (_filtreFlux == "Sorties") {
      resultat = resultat.where((tx) => tx.type == "sortie").toList();
    }

    if (_filtreEvenement != "Aucun") {
      resultat = resultat.where((tx) => tx.evenement == _filtreEvenement).toList();
    }

    if (_filtreFond != "Tous Fonds") {
      resultat = resultat.where((tx) => tx.fondAssocie == _filtreFond).toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      final dateFormat = DateFormat('dd/MM/yyyy');
      resultat = resultat.where((tx) {
        return tx.description.toLowerCase().contains(query) ||
            tx.categorie.toLowerCase().contains(query) ||
            tx.evenement.toLowerCase().contains(query) ||
            tx.donateur.toLowerCase().contains(query) ||
            tx.fondAssocie.toLowerCase().contains(query) ||
            dateFormat.format(tx.date).contains(query);
      }).toList();
    }

    setState(() {
      transactionsFiltrees = resultat;
    });
  }

  FinanceEngine _buildEngine(List<TransactionModel> targetList) {
    double budget = double.tryParse(_budgetController.text) ?? 2000.0;
    return FinanceEngine(
      transactions: targetList,
      budgetMensuel: budget,
      evenementCible: _filtreEvenement,
      tauxChange: _tauxActuel,
    );
  }

  Future<void> _exporterRapportPDF() async {
    if (transactionsFiltrees.isEmpty) return;

    final pdf = pw.Document();
    final dateDuJour = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final fontStyle = pw.TextStyle(font: pw.Font.helvetica());
    final fontBold = pw.TextStyle(font: pw.Font.helveticaBold(), fontWeight: pw.FontWeight.bold);

    final filteredEngine = _buildEngine(transactionsFiltrees);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 15),
          child: pw.Text(
            'Page ${context.pageNumber} sur ${context.pagesCount}',
            style: fontStyle.copyWith(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "RAPPORT COMPTABLE ECCLÉSIASTIQUE",
                    style: fontBold.copyWith(fontSize: 14, color: PdfColors.blueGrey900),
                  ),
                  pw.Text(
                    "Filtres : Période: $_filtreTemporel | Caisse: $_filtreFond | Événement: $_filtreEvenement",
                    style: fontStyle.copyWith(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    "Généré Par les Administrateurs le : $dateDuJour",
                    style: fontStyle.copyWith(fontSize: 8, color: PdfColors.grey500),
                  ),
                ],
              ),
              pw.Text(
                "Trésorerie NovaPay",
                style: fontBold.copyWith(fontSize: 11, color: PdfColors.indigo900),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 15),

          pw.Text(
            "Synthèse de l'Échantillon Sélectionné",
            style: fontBold.copyWith(fontSize: 11, color: PdfColors.blueGrey800),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPdfSummaryCard(
                "SOLDE FILTRÉ (USD)",
                formatUSD.format(filteredEngine.soldeGlobal),
                PdfColors.black,
                fontStyle,
                fontBold,
              ),
              _buildPdfSummaryCard(
                "PANIER COMPTABLE MOYEN",
                formatUSD.format(filteredEngine.panierMoyen),
                PdfColors.teal700,
                fontStyle,
                fontBold,
              ),
              _buildPdfSummaryCard(
                "CAISSE ANALYSÉE",
                _filtreFond,
                PdfColors.purple700,
                fontStyle,
                fontBold,
              ),
            ],
          ),
          pw.SizedBox(height: 15),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.5),
              1: pw.FlexColumnWidth(2.5),
              2: pw.FlexColumnWidth(2.5),
              3: pw.FlexColumnWidth(2.5),
              4: pw.FlexColumnWidth(2.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _buildTableCell("Date", fontBold, isHeader: true),
                  _buildTableCell("Fidèle / Source", fontBold, isHeader: true),
                  _buildTableCell("Catégorie (Fond)", fontBold, isHeader: true),
                  _buildTableCell("Événement", fontBold, isHeader: true),
                  _buildTableCell("Montant original", fontBold, isHeader: true, alignRight: true),
                ],
              ),
              ...transactionsFiltrees.map((tx) {
                final estEntree = tx.type == "entree";
                final affichagePrix = tx.devise == "USD"
                    ? formatUSD.format(tx.montant)
                    : formatCDF.format(tx.montant);
                return pw.TableRow(
                  children: [
                    _buildTableCell(DateFormat('dd/MM/yy').format(tx.date), fontStyle),
                    _buildTableCell(tx.donateur, fontStyle),
                    _buildTableCell("${tx.categorie} [${tx.fondAssocie}]", fontStyle),
                    _buildTableCell(tx.evenement, fontStyle),
                    _buildTableCell(
                      "${estEntree ? '+' : '-'} $affichagePrix",
                      fontBold.copyWith(color: estEntree ? PdfColors.green700 : PdfColors.red700),
                      alignRight: true,
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
      name: 'Rapport_Comptable_Eglise.pdf',
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.TextStyle style, {
    bool isHeader = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: style.copyWith(fontSize: isHeader ? 8 : 7),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildPdfSummaryCard(
    String title,
    String val,
    PdfColor color,
    pw.TextStyle style,
    pw.TextStyle bold,
  ) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: style.copyWith(fontSize: 6, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(val, style: bold.copyWith(fontSize: 9, color: color), maxLines: 1),
        ],
      ),
    );
  }

  void _ouvrirFormulaireAjout() {
    _montantController.clear();
    _descriptionController.clear();
    _donateurController.text = "Anonyme";
    setState(() {
      _typeSelectionne = "entree";
      _categorieSelectionnee = "Dîme";
      _evenementSelectionneFormulaire = "Aucun";
      _fondSelectionneFormulaire = "Général";
      _deviseSelectionnee = "USD";
      _isSaving = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          List<String> categories = _typeSelectionne == "entree"
              ? ["Dîme", "Offrande Ordinaire", "Action de Grâce", "Don Projets", "Sponsoring"]
              : [
                  "Soutien Social / Veuves",
                  "Achat Équipements",
                  "Logistique & Fêtes",
                  "Factures Construction",
                  "Eau & Électricité",
                ];

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              "Nouvelle Écriture",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9, // Sécurité de contrainte sur mobile
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ChoiceChip(
                          label: const Text("Entrée"),
                          selected: _typeSelectionne == "entree",
                          selectedColor: Colors.green[100],
                          onSelected: (selected) {
                            if (selected && !_isSaving) {
                              setDialogState(() {
                                _typeSelectionne = "entree";
                                _categorieSelectionnee = "Dîme";
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text("Sortie"),
                          selected: _typeSelectionne == "sortie",
                          selectedColor: Colors.red[100],
                          onSelected: (selected) {
                            if (selected && !_isSaving) {
                              setDialogState(() {
                                _typeSelectionne = "sortie";
                                _categorieSelectionnee = "Soutien Social / Veuves";
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 🛠️ FIX #1 : Contraintes strictes sur la boîte de Devise
                        SizedBox(
                          width: 90,
                          child: DropdownButtonFormField<String>(
                            initialValue: _deviseSelectionnee, // Changement initialValue -> value
                            isExpanded: true, // Évite les débordements de flèche
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Devise",
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            ),
                            items: ["USD", "CDF"]
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d, style: const TextStyle(fontSize: 13)),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (v) => setDialogState(() => _deviseSelectionnee = v!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _montantController,
                            enabled: !_isSaving,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "Montant",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // 🛠️ FIX #2 : Ajout de isExpanded: true sur tous les autres champs du formulaire
                    DropdownButtonFormField<String>(
                      initialValue: _categorieSelectionnee,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Type de Mouvement",
                        border: OutlineInputBorder(),
                      ),
                      items: categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) => setDialogState(() => _categorieSelectionnee = value!),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: _fondSelectionneFormulaire,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Affectation Caisse / Fond",
                        border: OutlineInputBorder(),
                      ),
                      items: _listeFonds
                          .where((f) => f != "Tous Fonds")
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text("Fond $f", style: const TextStyle(fontSize: 13)),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) => setDialogState(() => _fondSelectionneFormulaire = value!),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: _evenementSelectionneFormulaire,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Contexte Réunion",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_note, size: 18),
                      ),
                      items: _listeEvenementsDisponibles
                          .map(
                            (ev) => DropdownMenuItem(
                              value: ev,
                              child: Text(
                                ev,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) =>
                                setDialogState(() => _evenementSelectionneFormulaire = value!),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _donateurController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: "Fidèle / Donateur / Bénéficiaire",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _descriptionController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: "Notes / Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _typeSelectionne == "entree" ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSaving
                    ? null
                    : () async {
                        final chaineMontant = _montantController.text.trim();
                        if (chaineMontant.isEmpty) return;

                        final montant = double.tryParse(chaineMontant.replaceAll(',', '.'));
                        if (montant == null || montant <= 0) return;

                        setDialogState(() {
                          _isSaving = true;
                        });

                        TransactionModel transaction = TransactionModel(
                          type: _typeSelectionne,
                          categorie: _categorieSelectionnee,
                          montant: montant,
                          date: DateTime.now(),
                          description: _descriptionController.text.trim(),
                          evenement: _evenementSelectionneFormulaire,
                          fondAssocie: _fondSelectionneFormulaire,
                          donateur: _donateurController.text.trim().isEmpty
                              ? "Anonyme"
                              : _donateurController.text.trim(),
                          devise: _deviseSelectionnee,
                        );

                        await box.add(transaction);
                        _synchroniserDonnees();
                        Navigator.pop(context);
                      },
                child: const Text("Enregistrer"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniAnalyticsCard(
    String title,
    String value,
    IconData icon, {
    bool isAlert = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isAlert ? Colors.orange : Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalEngine = _buildEngine(toutesLesTransactions);
    final filteredEngine = _buildEngine(transactionsFiltrees);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "AMOUR PARFAIT",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Seuils & Taux change",
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
                      decoration: const InputDecoration(labelText: "Budget Max Sorties (USD)"),
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
            icon: const Icon(Icons.print_outlined),
            tooltip: "Export Ledger PDF",
            onPressed: transactionsFiltrees.isEmpty ? null : _exporterRapportPDF,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: _ouvrirFormulaireAjout,
        icon: const Icon(Icons.add_card_sharp),
        label: const Text("Écriture"),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TRÉSORERIE TAP NETTE UNIFIÉE",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatUSD.format(globalEngine.soldeGlobal),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: globalEngine.couleurRisque,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "RISQUE BUDGET : ${globalEngine.niveauRisqueBudget}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Général: ${formatUSD.format(globalEngine.totalParFond('Général'))}",
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                    Text(
                      "Parcelle: ${formatUSD.format(globalEngine.totalParFond('Construction'))}",
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                    Text(
                      "Social: ${formatUSD.format(globalEngine.totalParFond('Social'))}",
                      style: const TextStyle(color: Colors.white60, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: globalEngine.tauxConsommationBudget,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(globalEngine.couleurRisque),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _filtreTemporel,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    underline: const SizedBox(),
                    items: [
                      "Tout",
                      "Mois",
                      "Mois Dernier",
                      "Année",
                    ].map((f) => DropdownMenuItem(value: f, child: Text("Temps: $f"))).toList(),
                    onChanged: (v) {
                      setState(() => _filtreTemporel = v!);
                      _appliquerFiltresCombines();
                    },
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _filtreFlux,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    underline: const SizedBox(),
                    items: [
                      "Tout Flux",
                      "Entrées",
                      "Sorties",
                    ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (v) {
                      setState(() => _filtreFlux = v!);
                      _appliquerFiltresCombines();
                    },
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _filtreFond,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    underline: const SizedBox(),
                    items: _listeFonds
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f == "Tous Fonds" ? "Toutes Caisses" : "Caisse $f"),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => _filtreFond = v!);
                      _appliquerFiltresCombines();
                    },
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _filtreEvenement,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    underline: const SizedBox(),
                    items: _listeEvenementsDisponibles
                        .map(
                          (ev) => DropdownMenuItem(
                            value: ev,
                            child: Text(ev == "Aucun" ? "Tous Événements" : ev),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setState(() => _filtreEvenement = v!);
                      _appliquerFiltresCombines();
                    },
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _appliquerFiltresCombines(),
              decoration: InputDecoration(
                hintText: "Fidèle, catégorie, note ou date...",
                prefixIcon: const Icon(Icons.search, size: 16, color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            child: Row(
              children: [
                _buildMiniAnalyticsCard(
                  "PANIER MOYEN",
                  formatUSD.format(filteredEngine.panierMoyen),
                  Icons.pie_chart,
                ),
                const SizedBox(width: 8),
                _buildMiniAnalyticsCard(
                  "ACTION SOCIALE",
                  "${(globalEngine.ratioSolidarite * 100).toStringAsFixed(1)} %",
                  Icons.volunteer_activism,
                  isAlert: globalEngine.ratioSolidarite < 0.1,
                ),
              ],
            ),
          ),
          Expanded(
            child: transactionsFiltrees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_outlined, color: Colors.grey[400]),
                        const Text(
                          "Aucune transaction enregistrée.",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: transactionsFiltrees.length,
                    itemBuilder: (context, index) {
                      final tx = transactionsFiltrees[index];
                      final bool isEntree = tx.type == "entree";

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isEntree ? Colors.green[50] : Colors.red[50],
                            child: Icon(
                              isEntree ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isEntree ? Colors.green : Colors.red,
                              size: 16,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tx.categorie,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                tx.devise == "USD"
                                    ? formatUSD.format(tx.montant)
                                    : formatCDF.format(tx.montant),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isEntree ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            "${tx.donateur} • Fond ${tx.fondAssocie} • ${DateFormat('dd/MM/yyyy').format(tx.date)}",
                            style: const TextStyle(fontSize: 10),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Supprimer l'écriture ?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Non"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      box.delete(tx.key);
                                      _synchroniserDonnees();
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text("Oui, supprimer"),
                                  ),
                                ],
                              ),
                            ),
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
