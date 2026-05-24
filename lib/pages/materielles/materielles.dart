import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:untitled11/pages/materielles/model_bien.dart';

// Imports requis pour le traitement documentaire PDF & Impression d'infrastructure
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// =========================================================================
// 🧠 MOTEUR ANALYTIQUE DE PATRIMOINE : ASSET INTELLIGENCE ENGINE UNIFIÉ
// =========================================================================
class AssetEngine {
  final List<AssetModel> assets;
  final double tauxChange; // 1 USD = X CDF

  AssetEngine({required this.assets, this.tauxChange = 2850.0});

  double _getAcquisitionEnUSD(AssetModel asset) {
    return asset.devise == "CDF" ? asset.valeurAcquisition / tauxChange : asset.valeurAcquisition;
  }

  double _getVncEnUSD(AssetModel asset) {
    if (asset.statut == "Déclassé") return 0.0;
    return asset.devise == "CDF"
        ? asset.valeurNetteComptable / tauxChange
        : asset.valeurNetteComptable;
  }

  double get valeurGlobaleAcquisition =>
      assets.fold(0.0, (sum, asset) => sum + _getAcquisitionEnUSD(asset));

  double get valeurActuelleNet => assets.fold(0.0, (sum, asset) => sum + _getVncEnUSD(asset));

  int obtenirNombreParStatut(String statut) => assets.where((a) => a.statut == statut).length;

  double obtenirTauxSantePatrimoine() {
    if (assets.isEmpty) return 1.0;
    int fonctionnels = assets.where((a) => a.statut == "Opérationnel").length;
    return fonctionnels / assets.length;
  }
}

// =========================================================================
// 🎨 INTERFACE DE GESTION AUDIOVISUELLE ET IMMOBILIÈRE
// =========================================================================
class ChurchAssetPage extends StatefulWidget {
  const ChurchAssetPage({super.key});

  @override
  State<ChurchAssetPage> createState() => _ChurchAssetPageState();
}

class _ChurchAssetPageState extends State<ChurchAssetPage> {
  late final Box<AssetModel> assetBox;
  bool _isBoxInitialized = false;

  final formatUSD = NumberFormat.currency(symbol: "\$ ", decimalDigits: 2);
  final formatCDF = NumberFormat.currency(symbol: "FC ", decimalDigits: 0, locale: "fr_FR");

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tauxController = TextEditingController()..text = "2850";

  String _queryRecherche = "";
  String _filtreCategorie = "Toutes";
  String _filtreStatut = "Tous";

  @override
  void initState() {
    super.initState();
    try {
      assetBox = Hive.box<AssetModel>("biens_eglise");
      _isBoxInitialized = true;
    } catch (e) {
      _isBoxInitialized = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tauxController.dispose();
    super.dispose();
  }

  double get _tauxActuel => double.tryParse(_tauxController.text) ?? 2850.0;

  List<AssetModel> _filtrerFicheAssets() {
    if (!_isBoxInitialized) return [];
    final listeTotale = assetBox.values.toList();
    return listeTotale.where((asset) {
      final matchQuery =
          asset.nom.toLowerCase().contains(_queryRecherche.toLowerCase()) ||
          asset.codeImmatriculation.toLowerCase().contains(_queryRecherche.toLowerCase()) ||
          asset.responsable.toLowerCase().contains(_queryRecherche.toLowerCase()) ||
          asset.emplacement.toLowerCase().contains(_queryRecherche.toLowerCase());
      final matchCategorie = _filtreCategorie == "Toutes" || asset.categorie == _filtreCategorie;
      final matchStatut = _filtreStatut == "Tous" || asset.statut == _filtreStatut;

      return matchQuery && matchCategorie && matchStatut;
    }).toList();
  }

  /// 📄 ENGINE D'EXPORTATION PDF AVEC RESPECT STRICT DES FILTRES ET DES KPI
  Future<void> _exporterInventairePDF(List<AssetModel> assetsFiltres) async {
    final pdf = pw.Document();
    final engineCalcul = AssetEngine(assets: assetsFiltres, tauxChange: _tauxActuel);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // En-tête de l'organisation
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "AMOUR PARFAIT TABERNACLE",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Département Logistique, Maintenance & Patrimoine",
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Divider(thickness: 0.8, color: PdfColors.grey400),
            pw.SizedBox(height: 14),

            // Métadonnées et filtres appliqués sur le rapport
            pw.Text(
              "INVENTAIRE ET VALORISATION DES ACTIFS",
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              "Filtres actifs : Catégorie [$_filtreCategorie] • État [$_filtreStatut] ${_queryRecherche.isNotEmpty ? '• Requête [$_queryRecherche]' : ''}",
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey700),
            ),
            pw.SizedBox(height: 16),

            // Bloc KPI consolidé inclus dans le document PDF
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "VALEUR GLOBALE ACQUISITION",
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        formatUSD.format(engineCalcul.valeurGlobaleAcquisition),
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "VALEUR NETTE COMPTABLE (VNC)",
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        formatUSD.format(engineCalcul.valeurActuelleNet),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "SANTÉ DU PARC",
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "${(engineCalcul.obtenirTauxSantePatrimoine() * 100).toStringAsFixed(0)}%",
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tableau d'inventaire
            pw.TableHelper.fromTextArray(
              headers: [
                'Code / Matricule',
                'Désignation',
                'Zone / Emplacement',
                'État',
                'Coût Acquisition',
                'VNC Actuelle',
              ],
              data: assetsFiltres.map((asset) {
                final prixAffiche = asset.devise == "USD"
                    ? formatUSD.format(asset.valeurAcquisition)
                    : formatCDF.format(asset.valeurAcquisition);
                final vncAffichee = asset.devise == "USD"
                    ? formatUSD.format(asset.valeurNetteComptable)
                    : formatCDF.format(asset.valeurNetteComptable);
                return [
                  asset.codeImmatriculation,
                  asset.nom,
                  asset.emplacement,
                  asset.statut,
                  prixAffiche,
                  vncAffichee,
                ];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Nombre d'éléments listés : ${assetsFiltres.length}",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'patrimoine_filtre_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  Color _obtenirCouleurStatut(String statut) {
    switch (statut) {
      case "Opérationnel":
        return Colors.green;
      case "En Maintenance":
        return Colors.orange;
      case "En Panne":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _ouvrirFormulaireBien() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FormulaireBienDialog(
        onSaved: (nouveauBien) {
          if (_isBoxInitialized) {
            setState(() {
              assetBox.add(nouveauBien);
            });
          }
        },
      ),
    );
  }

  void _modifierStatutDialog(AssetModel asset) {
    showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Mettre à jour l'état",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Opérationnel", "En Maintenance", "En Panne", "Déclassé"].map((etat) {
              return ListTile(
                title: Text(etat, style: const TextStyle(fontSize: 13)),
                trailing: asset.statut == etat
                    ? const Icon(Icons.check_circle, color: Colors.black)
                    : null,
                onTap: () async {
                  if (!_isBoxInitialized) return;
                  final index = assetBox.keys.firstWhere((k) => assetBox.get(k) == asset);
                  final updated = AssetModel(
                    codeImmatriculation: asset.codeImmatriculation,
                    nom: asset.nom,
                    categorie: asset.categorie,
                    valeurAcquisition: asset.valeurAcquisition,
                    dateAcquisition: asset.dateAcquisition,
                    dureeVieAnnees: asset.dureeVieAnnees,
                    emplacement: asset.emplacement,
                    statut: etat,
                    responsable: asset.responsable,
                    devise: asset.devise,
                  );
                  await assetBox.put(index, updated);
                  navigator.pop();
                  setState(() {});
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final fichesFiltrees = _filtrerFicheAssets();
    final engineTotal = AssetEngine(assets: assetBox.values.toList(), tauxChange: _tauxActuel);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Logistique & Patrimoine",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton d'exportation PDF filtrée réactif
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
            tooltip: "Exporter cette vue en PDF",
            onPressed: () => _exporterInventairePDF(fichesFiltrees),
          ),
          IconButton(
            icon: const Icon(Icons.currency_exchange, size: 20),
            tooltip: "Ajuster le taux",
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Taux de Change Patrimoine"),
                content: TextField(
                  controller: _tauxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "1 USD = X CDF",
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text("Appliquer"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirFormulaireBien,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.playlist_add_sharp),
        label: const Text("Ajouter Actif"),
      ),
      body: Column(
        children: [
          // ================= KPI DASHBOARD UNIFIÉ EN USD =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "VALEUR DU REGISTRE (CONSOLIDÉ USD)",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatUSD.format(engineTotal.valeurGlobaleAcquisition),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "VALEUR NETTE COMPTABLE (RÉELLE)",
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formatUSD.format(engineTotal.valeurActuelleNet),
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Santé physique du parc : ${(engineTotal.obtenirTauxSantePatrimoine() * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    Text(
                      "${engineTotal.obtenirNombreParStatut("En Panne")} Alerte(s) de panne",
                      style: TextStyle(
                        color: engineTotal.obtenirNombreParStatut("En Panne") > 0
                            ? Colors.redAccent
                            : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ================= FILTRES DE TRIS =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _filtreCategorie,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  underline: const SizedBox(),
                  items: [
                    "Toutes",
                    "Électronique",
                    "Mobilier",
                    "Immobilier",
                    "Véhicule",
                  ].map((c) => DropdownMenuItem(value: c, child: Text("Catégorie: $c"))).toList(),
                  onChanged: (v) => setState(() => _filtreCategorie = v!),
                ),
                DropdownButton<String>(
                  value: _filtreStatut,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  underline: const SizedBox(),
                  items: [
                    "Tous",
                    "Opérationnel",
                    "En Maintenance",
                    "En Panne",
                    "Déclassé",
                  ].map((s) => DropdownMenuItem(value: s, child: Text("État: $s"))).toList(),
                  onChanged: (v) => setState(() => _filtreStatut = v!),
                ),
              ],
            ),
          ),

          // ================= MODULE RECHERCHE =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Recherche par équipement, matricule, lieu...",
                prefixIcon: const Icon(Icons.search, size: 16, color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _queryRecherche = v),
            ),
          ),

          // ================= LE LIVRE d'INVENTAIRE =================
          Expanded(
            child: fichesFiltrees.isEmpty
                ? Center(
                    child: Text(
                      "Aucun équipement repertorié",
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  )
                : ListView.builder(
                    itemCount: fichesFiltrees.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final asset = fichesFiltrees[index];
                      final diagnosticCouleur = _obtenirCouleurStatut(asset.statut);

                      final prixAffiche = asset.devise == "USD"
                          ? formatUSD.format(asset.valeurAcquisition)
                          : formatCDF.format(asset.valeurAcquisition);
                      final vncAffichee = asset.devise == "USD"
                          ? formatUSD.format(asset.valeurNetteComptable)
                          : formatCDF.format(asset.valeurNetteComptable);

                      return Card(
                        elevation: 0,
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey[100]!),
                        ),
                        child: ListTile(
                          onTap: () => _modifierStatutDialog(asset),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  asset.nom,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: diagnosticCouleur,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  asset.statut,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Matricule : ${asset.codeImmatriculation}  •  Zone : ${asset.emplacement}",
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                Text(
                                  "Curateur : ${asset.responsable}",
                                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                                ),
                                const SizedBox(height: 2),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: asset.tauxUsure,
                                    backgroundColor: Colors.grey[100],
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.blueGrey,
                                    ),
                                    minHeight: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                prixAffiche,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                "VNC : $vncAffichee",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.teal[700],
                                  fontWeight: FontWeight.w600,
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

// =========================================================================
// 🔒 DIALOGUE FORMULAIRE D'INVENTAIRE SÉCURISÉ CONTRE LES LEAKS DE CONTEXTE
// =========================================================================
class _FormulaireBienDialog extends StatefulWidget {
  final Function(AssetModel) onSaved;
  const _FormulaireBienDialog({required this.onSaved});

  @override
  State<_FormulaireBienDialog> createState() => _FormulaireBienDialogState();
}

class _FormulaireBienDialogState extends State<_FormulaireBienDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _valeurController = TextEditingController();
  final _amortissementController = TextEditingController();
  final _emplacementController = TextEditingController();
  final _responsableController = TextEditingController();

  String _categorieChoisie = "Électronique";
  String _deviseChoisie = "USD";

  @override
  void dispose() {
    _nomController.dispose();
    _valeurController.dispose();
    _amortissementController.dispose();
    _emplacementController.dispose();
    _responsableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Ficher un nouvel Actif",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue:
                    _categorieChoisie, // 🛠️ FIX : Remplacement de initialValue pour éviter les crashs de rebuilds
                decoration: const InputDecoration(labelText: "Type de Structure Patrimoniale"),
                items: [
                  "Électronique",
                  "Mobilier",
                  "Immobilier",
                  "Véhicule",
                ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _categorieChoisie = v!),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: "Désignation de l'équipement *"),
                validator: (v) => v!.trim().isEmpty ? "Nom requis" : null,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 85,
                    child: DropdownButtonFormField<String>(
                      initialValue: _deviseChoisie, // 🛠️ FIX : Remplacement de initialValue
                      decoration: const InputDecoration(labelText: "Devise"),
                      items: [
                        "USD",
                        "CDF",
                      ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setState(() => _deviseChoisie = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _valeurController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: "Coût Acquisition *"),
                      validator: (v) => double.tryParse(v ?? "") == null ? "Invalide" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amortissementController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Durée d'Amortissement Prévue (Années) *",
                ),
                validator: (v) => int.tryParse(v ?? "") == null ? "Invalide" : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emplacementController,
                decoration: const InputDecoration(labelText: "Emplacement / Zone Église"),
                validator: (v) => v!.trim().isEmpty ? "Spécifiez le lieu" : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _responsableController,
                decoration: const InputDecoration(labelText: "Diacre / Agent Responsable"),
                validator: (v) => v!.trim().isEmpty ? "Affectation obligatoire" : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final stamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
              final item = AssetModel(
                codeImmatriculation:
                    "INV-${_categorieChoisie.substring(0, 3).toUpperCase()}-$stamp",
                nom: _nomController.text.trim(),
                categorie: _categorieChoisie,
                valeurAcquisition: double.parse(_valeurController.text),
                dateAcquisition: DateTime.now(),
                dureeVieAnnees: int.parse(_amortissementController.text),
                emplacement: _emplacementController.text.trim(),
                statut: "Opérationnel",
                responsable: _responsableController.text.trim(),
                devise: _deviseChoisie,
              );
              widget.onSaved(item);
              Navigator.pop(context);
            }
          },
          child: const Text("Ficher"),
        ),
      ],
    );
  }
}
