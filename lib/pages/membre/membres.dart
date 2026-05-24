import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:untitled11/pages/membre/modelModel.dart';
import 'package:untitled11/GlobalSyncService/global_sync_service.dart';

// Imports requis pour la génération et l'impression du PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MembresPage extends StatefulWidget {
  const MembresPage({super.key});

  @override
  State<MembresPage> createState() => _MembresPageState();
}

class _MembresPageState extends State<MembresPage> {
  late final Box<MembreModel> membreBox;
  bool _isBoxInitialized = false;
  final TextEditingController _searchController = TextEditingController();

  String _queryRecherche = "";
  String _filtreGrade = "Tous";
  String _filtreMinistere = "Tous";

  final List<String> _gradesList = [
    "Tous",
    "Pasteur",
    "Administrateur",
    "Diacre",
    "Nouveau Converti",
    "Fidèle",
    "Chantre",
    "Technicien",
  ];

  final List<String> _ministeresList = [
    "Tous",
    "Chorale",
    "Éco-dim",
    "Jeunesse",
    "Intercession",
    "Social & Veuves",
  ];

  @override
  void initState() {
    super.initState();
    try {
      membreBox = Hive.box<MembreModel>("membres_eglise");
      _isBoxInitialized = true;
    } catch (e) {
      _isBoxInitialized = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MembreModel> _filtrerMembres() {
    if (!_isBoxInitialized) return [];
    final listeTotale = membreBox.values.toList();
    return listeTotale.where((membre) {
      final matchQuery =
          membre.nom.toLowerCase().contains(_queryRecherche.toLowerCase()) ||
          membre.prenom.toLowerCase().contains(_queryRecherche.toLowerCase()) ||
          membre.numTel.contains(_queryRecherche) ||
          membre.adresse.toLowerCase().contains(_queryRecherche.toLowerCase());

      final matchGrade = _filtreGrade == "Tous" || membre.grade == _filtreGrade;

      final matchMinistere =
          _filtreMinistere == "Tous" ||
          (membre.travail != null && membre.travail!.contains(_filtreMinistere));

      return matchQuery && matchGrade && matchMinistere;
    }).toList();
  }

  /// 📄 MOTEUR DE GÉNÉRATION PDF HAUTE QUALITÉ
  Future<void> _exporterPDF(List<MembreModel> membres) async {
    final pdf = pw.Document();

    // Construction du document structuré
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // En-tête Corporate Documentaire
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
                        fontSize: 14,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Registre Officiel des Membres",
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Text(
                  "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Titre du Document Récapitulatif
            pw.Text(
              "RAPPORT D'EFFECTIF FILTRÉ",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              "Filtres appliqués : Rôle [$_filtreGrade] • Département [$_filtreMinistere]",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 16),

            // Tableau des Données
            pw.TableHelper.fromTextArray(
              headers: ['Nom & Prénom', 'Téléphone', 'Rôle / Grade', 'Département / Notes'],
              data: membres.map((m) {
                return ["${m.nom.toUpperCase()} ${m.prenom}", m.numTel, m.grade, m.travail ?? '-'];
              }).toList(),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
            ),

            pw.SizedBox(height: 24),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Total : ${membres.length} profil(s) enregistré(s)",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              ),
            ),
          ];
        },
      ),
    );

    // Affichage direct de la feuille de partage, téléchargement et impression native
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'registre_membres_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  void _ouvrirFormulaireMembre() {
    if (!_isBoxInitialized) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FormulaireMembreDialog(
        grades: _gradesList.where((g) => g != "Tous").toList(),
        ministeres: _ministeresList.where((m) => m != "Tous").toList(),
        onSaved: (nouveauMembre) {
          setState(() {
            membreBox.add(nouveauMembre);
          });
        },
      ),
    );
  }

  void _ouvrirSuiviSpirituel(MembreModel membre) {
    showDialog(
      context: context,
      builder: (context) => _SuiviSpirituelDialog(
        membre: membre,
        accompagnateursPossibles: membreBox.values
            .where(
              (m) => m.grade == "Diacre" || m.grade == "Pasteur" || m.grade == "Administrateur",
            )
            .toList(),
        onSuiviMisAJour: (membreMisAJour) async {
          final cibleKey = membreBox.keys.firstWhere(
            (k) => membreBox.get(k)?.numTel == membre.numTel,
            orElse: () => null,
          );

          if (cibleKey != null) {
            setState(() {
              membreBox.put(cibleKey, membreMisAJour);
            });

            try {
              final GlobalSyncService syncService = GlobalSyncService();
              await syncService.saveMembre(membreMisAJour, membreMisAJour.numTel);
            } catch (e) {
              debugPrint("⚠️ Erreur de synchronisation cloud: $e");
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF000000),
        body: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5)),
      );
    }

    final membresFiltres = _filtrerMembres();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0E12), Color(0xFF000000), Color(0xFF050508)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // APP BAR REDESSINÉE AVEC BOUTON EXPORT PDF DISCRET
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Membres",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                        letterSpacing: -0.8,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        // Bouton d'exportation PDF
                        IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 20,
                            color: Colors.white70,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1C1C1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _exporterPDF(membresFiltres),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add, size: 22, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1C1C1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _ouvrirFormulaireMembre,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "${membresFiltres.length} profils affichés",
                  style: const TextStyle(color: Color(0xFF636366), fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),

              // BARRE DE RECHERCHE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: "Rechercher un fidèle, contact, adresse...",
                    hintStyle: const TextStyle(color: Color(0xFF48484A), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF636366)),
                    filled: true,
                    fillColor: const Color(0xFF1C1C1E),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white38),
                    ),
                  ),
                  onChanged: (v) => setState(() => _queryRecherche = v),
                ),
              ),
              const SizedBox(height: 16),

              // FILTRE 1 : GRADES
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                child: Text(
                  "RÔLE ECCLÉSIASTIQUE",
                  style: TextStyle(
                    color: Color(0xFF48484A),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _gradesList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemBuilder: (context, index) {
                    final grade = _gradesList[index];
                    final isSelected = _filtreGrade == grade;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          grade,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.black : Colors.white70,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.white,
                        backgroundColor: const Color(0xFF141416),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (v) => setState(() => _filtreGrade = grade),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // FILTRE 2 : MINISTÈRES
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                child: Text(
                  "MINISTÈRE / DÉPARTEMENT",
                  style: TextStyle(
                    color: Color(0xFF48484A),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _ministeresList.length,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemBuilder: (context, index) {
                    final mini = _ministeresList[index];
                    final isSelected = _filtreMinistere == mini;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          mini,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.black : Colors.white60,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.lightBlueAccent,
                        backgroundColor: const Color(0xFF141416),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        onSelected: (v) => setState(() => _filtreMinistere = mini),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // LISTE DES MEMBRES
              Expanded(
                child: membresFiltres.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucun membre trouvé",
                          style: TextStyle(color: Color(0xFF48484A), fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        itemCount: membresFiltres.length,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        separatorBuilder: (context, index) =>
                            const Divider(color: Color(0xFF1C1C1E), height: 1),
                        itemBuilder: (context, index) {
                          final membre = membresFiltres[index];
                          final bool isNouveauConverti = membre.grade == "Nouveau Converti";

                          return InkWell(
                            onTap: isNouveauConverti ? () => _ouvrirSuiviSpirituel(membre) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isNouveauConverti
                                          ? const Color(0xFF1A120B)
                                          : const Color(0xFF1C1C1E),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isNouveauConverti
                                            ? Colors.orangeAccent
                                            : const Color(0xFF2C2C2E),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      membre.nom.isNotEmpty
                                          ? membre.nom.substring(0, 1).toUpperCase()
                                          : "?",
                                      style: TextStyle(
                                        color: isNouveauConverti
                                            ? Colors.orangeAccent
                                            : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                "${membre.prenom} ${membre.nom.toUpperCase()}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isNouveauConverti) ...[
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.eco_rounded,
                                                size: 14,
                                                color: Colors.greenAccent,
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          membre.numTel,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF8E8E93),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "📍 ${membre.adresse}${membre.travail != null ? '  •  💼 ' + membre.travail! : ''}",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF48484A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A0A0C),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF2C2C2E)),
                                    ),
                                    child: Text(
                                      membre.grade,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isNouveauConverti
                                            ? Colors.orangeAccent
                                            : const Color(0xFFAEAEB2),
                                      ),
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
        ),
      ),
    );
  }
}

// Dialogues de suivi et de création inchangés...
class _SuiviSpirituelDialog extends StatefulWidget {
  final MembreModel membre;
  final List<MembreModel> accompagnateursPossibles;
  final Function(MembreModel) onSuiviMisAJour;

  const _SuiviSpirituelDialog({
    required this.membre,
    required this.accompagnateursPossibles,
    required this.onSuiviMisAJour,
  });

  @override
  State<_SuiviSpirituelDialog> createState() => _SuiviSpirituelDialogState();
}

class _SuiviSpirituelDialogState extends State<_SuiviSpirituelDialog> {
  String _responsableSuivi = "Non assigné";
  bool _appeleCetteSemaine = false;
  bool _visiteCetteSemaine = false;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.membre.travail ?? "";
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141416),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2C2C2E)),
      ),
      title: Row(
        children: [
          const Icon(Icons.spa_rounded, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Suivi de ${widget.membre.prenom}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Theme(
                data: Theme.of(context).copyWith(canvasColor: const Color(0xFF141416)),
                child: DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF141416),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: "Assigner à un Berger/Diacre",
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  initialValue: _responsableSuivi,
                  items: [
                    const DropdownMenuItem(value: "Non assigné", child: Text("Non assigné")),
                    ...widget.accompagnateursPossibles.map(
                      (m) => DropdownMenuItem(
                        value: "${m.prenom} ${m.nom}",
                        child: Text("${m.prenom} ${m.nom}"),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _responsableSuivi = v!),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Appelé au téléphone",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                value: _appeleCetteSemaine,
                activeColor: Colors.green,
                onChanged: (v) => setState(() => _appeleCetteSemaine = v!),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Visité à domicile",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                value: _visiteCetteSemaine,
                activeColor: Colors.green,
                onChanged: (v) => setState(() => _visiteCetteSemaine = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Rapport de visite / Notes",
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white38),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            final updatedInstance = MembreModel(
              nom: widget.membre.nom,
              prenom: widget.membre.prenom,
              adresse: widget.membre.adresse,
              numTel: widget.membre.numTel,
              grade: widget.membre.grade,
              travail:
                  "Berger: $_responsableSuivi | Appelé: ${_appeleCetteSemaine ? 'Oui' : 'Non'} | Visité: ${_visiteCetteSemaine ? 'Oui' : 'Non'} | Notes: ${_noteController.text.trim()}",
            );

            widget.onSuiviMisAJour(updatedInstance);
            Navigator.pop(context);
          },
          child: const Text("Sauvegarder"),
        ),
      ],
    );
  }
}

class _FormulaireMembreDialog extends StatefulWidget {
  final List<String> grades;
  final List<String> ministeres;
  final Function(MembreModel) onSaved;

  const _FormulaireMembreDialog({
    required this.grades,
    required this.ministeres,
    required this.onSaved,
  });

  @override
  State<_FormulaireMembreDialog> createState() => _FormulaireMembreDialogState();
}

class _FormulaireMembreDialogState extends State<_FormulaireMembreDialog> {
  final _formKey = GlobalKey<FormState>();
  final GlobalSyncService _syncService = GlobalSyncService();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telController = TextEditingController();

  late String _gradeChoisi;
  late String _ministereChoisi;

  @override
  void initState() {
    super.initState();
    _gradeChoisi = widget.grades.first;
    _ministereChoisi = widget.ministeres.first;
  }

  InputDecoration _dialogInputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF636366), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: const Color(0xFF0A0A0C),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white38),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _adresseController.dispose();
    _telController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141416),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF2C2C2E)),
      ),
      title: const Text(
        "Ajouter à l'effectif",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _prenomController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogInputDeco("Prénom *"),
                  validator: (v) => v!.isEmpty ? "Obligatoire" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nomController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogInputDeco("Nom *"),
                  validator: (v) => v!.isEmpty ? "Obligatoire" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _telController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogInputDeco("Téléphone *"),
                  validator: (v) => v!.isEmpty ? "Obligatoire" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _adresseController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dialogInputDeco("Adresse résidentielle *"),
                  validator: (v) => v!.isEmpty ? "Obligatoire" : null,
                ),
                const SizedBox(height: 10),

                Theme(
                  data: Theme.of(context).copyWith(canvasColor: const Color(0xFF141416)),
                  child: DropdownButtonFormField<String>(
                    initialValue: _gradeChoisi,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInputDeco("Rôle / Grade"),
                    items: widget.grades
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _gradeChoisi = v!),
                  ),
                ),
                const SizedBox(height: 10),

                Theme(
                  data: Theme.of(context).copyWith(canvasColor: const Color(0xFF141416)),
                  child: DropdownButtonFormField<String>(
                    initialValue: _ministereChoisi,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInputDeco("Département d'action"),
                    items: widget.ministeres
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _ministereChoisi = v!),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final item = MembreModel(
                nom: _nomController.text.trim(),
                prenom: _prenomController.text.trim(),
                adresse: _adresseController.text.trim(),
                numTel: _telController.text.trim(),
                travail: _ministereChoisi,
                grade: _gradeChoisi,
              );

              widget.onSaved(item);
              Navigator.pop(context);

              try {
                await _syncService.saveMembre(item, item.numTel);
              } catch (e) {
                debugPrint("❌ Erreur Cloud Synchro: $e");
              }
            }
          },
          child: const Text("Confirmer", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
