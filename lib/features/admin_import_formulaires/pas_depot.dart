// Pas 1 de l'import des formulaires (`ADM-23`) : deposer le fichier.
//
// Une seule question : quel fichier ? La reponse est une carte qu'on touche (le
// selecteur du systeme) : aucune frappe, aucun collage. Le classeur et l'onglet
// se deduisent du nom du fichier (« classeur - onglet.csv », ce qu'exporte
// Google Sheets) ; on ne les tape que pour les corriger. Rien n'est envoye avant
// « Analyser le fichier ».
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/fichier_formulaires.dart';
import '../../core/candidature/port_import_candidatures.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/chargement_avec_delais.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_import_inscriptions/selecteur_csv.dart';
import 'composants_import.dart';
import 'controleur_import.dart';
import 'libelles_import.dart';

/// Le pas « Deposer le fichier ».
class PasDepot extends ConsumerStatefulWidget {
  /// Cree le pas.
  const PasDepot({
    required this.controleur,
    required this.empile,
    required this.horsLigne,
    super.key,
  });

  /// Le controleur de l'import.
  final ControleurImportCandidatures controleur;

  /// Vrai sur telephone.
  final bool empile;

  /// Vrai quand l'appareil est hors ligne.
  final bool horsLigne;

  /// La cle de la carte « Choisir un fichier CSV ».
  static const Key carteFichierKey = ValueKey<String>('import-carte-fichier');

  /// La cle du lien « Corriger ces noms ».
  static const Key corrigerNomsKey = ValueKey<String>('import-corriger-noms');

  /// La cle du champ du classeur.
  static const Key champClasseurKey = ValueKey<String>('import-champ-classeur');

  /// La cle du champ de l'onglet.
  static const Key champOngletKey = ValueKey<String>('import-champ-onglet');

  @override
  ConsumerState<PasDepot> createState() => _PasDepotEtat();
}

class _PasDepotEtat extends ConsumerState<PasDepot> {
  final TextEditingController _classeur = TextEditingController();
  final TextEditingController _onglet = TextEditingController();
  bool _nomsOuverts = false;
  bool _selectionEchouee = false;

  ControleurImportCandidatures get _c => widget.controleur;

  @override
  void initState() {
    super.initState();
    _classeur.text = _c.noms.classeur;
    _onglet.text = _c.noms.onglet;
    // Un fichier sans onglet deduit : la direction doit le dire, le champ
    // s'ouvre de lui-meme.
    _nomsOuverts = _c.fichier != null && _c.noms.onglet.trim().isEmpty;
  }

  @override
  void dispose() {
    _classeur.dispose();
    _onglet.dispose();
    super.dispose();
  }

  Future<void> _choisir() async {
    setState(() => _selectionEchouee = false);
    CsvChoisi? choisi;
    try {
      choisi = await ref.read(selecteurCsvProvider).choisir();
    } on Object {
      if (mounted) setState(() => _selectionEchouee = true);
      return;
    }
    if (choisi == null || !mounted) return;
    _c.deposer(nom: choisi.nom, texte: choisi.texte);
    setState(() {
      _classeur.text = _c.noms.classeur;
      _onglet.text = _c.noms.onglet;
      _nomsOuverts = _c.noms.onglet.trim().isEmpty;
    });
  }

  void _surNoms() =>
      _c.corrigerNoms(classeur: _classeur.text, onglet: _onglet.text);

  /// Pourquoi le bouton « Analyser le fichier » n'est pas rendu.
  String? _raison() {
    final a = t.admin.importFormulaires.depot;
    if (_c.fichier == null) return a.manqueFichier;
    if (_c.noms.onglet.trim().isEmpty) return a.noms.ongletManquant;
    if (!_c.noms.valides) return a.noms.invalide;
    if (_c.peutAnalyser && widget.horsLigne) return a.horsLigne;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importFormulaires;
    if (_c.phase == PhaseImport.analyse) {
      return Column(
        key: const ValueKey<String>('import-analyse'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          QuestionDuPas(
            question: a.depot.question,
            explication: a.depot.analyseEnCours,
          ),
          Ecart.vXl,
          ChargementAvecDelais(
            squelette: const Skeleton.liste(lignes: 4),
            onReessayer: () => unawaited(_c.analyser()),
          ),
        ],
      );
    }
    final String? raison = _raison();
    final bool peutLancer =
        _c.peutAnalyser && !widget.horsLigne && raison == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        QuestionDuPas(
          question: a.depot.question,
          explication: a.depot.explication,
        ),
        Ecart.vXl,
        _carteFichier(),
        if (_c.fichier != null) ...<Widget>[Ecart.vLg, _carteNoms()],
        // Sur telephone, l'en-tete de la page ne porte pas la phrase qui dit ce
        // que l'import ne fait pas : elle suit ici, au premier pas.
        if (widget.empile) ...<Widget>[
          Ecart.vLg,
          InfoPas(
            key: const ValueKey<String>('import-intro'),
            message: a.intro,
          ),
        ],
        ..._constats(),
        Ecart.vLg,
        ActionsDuPas(
          empile: widget.empile,
          libelleAction: peutLancer ? a.depot.analyser : null,
          onAction: () => unawaited(_c.analyser()),
          souscription: raison == null
              ? null
              : IndicationPas(message: raison, discret: true),
        ),
      ],
    );
  }

  Widget _carteFichier() {
    final a = t.admin.importFormulaires.depot;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final FichierFormulaires? f = _c.fichier;
    return AppCard(
      key: PasDepot.carteFichierKey,
      selectionnee: f != null,
      onPress: () => unawaited(_choisir()),
      libelleSemantique: f == null ? a.carteTitre : a.autreFichier,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DecoratedBox(
            decoration: palette.washAccent.decoration(
              borderRadius: AppRadius.arrondiFull,
            ),
            child: SizedBox(
              width: AppTouchTarget.standard,
              height: AppTouchTarget.standard,
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    color: palette.washAccent.onBackground,
                    size: AppSpacing.xxl,
                  ),
                  child: Icon(
                    f == null
                        ? AppIcons.telecharger.repos
                        // Un fichier illisible n'est pas « choisi avec succes ».
                        : _c.problemeFichier != null
                        ? AppIcons.avertissement.actif
                        : AppIcons.succes.actif,
                  ),
                ),
              ),
            ),
          ),
          Ecart.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TexteSansCoupure(
                  f == null ? a.carteTitre : a.carteChoisi(nom: f.nom),
                  style: textes.titleMedium,
                ),
                // Un fichier illisible n'a pas de nombre de lignes a dire : la
                // phrase en rouge, dessous, dit pourquoi.
                if (_c.problemeFichier == null) ...<Widget>[
                  Ecart.vXs,
                  TexteSansCoupure(
                    f == null
                        ? a.carteDescription
                        : a.lignesLues(n: f.nombreLignes),
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ],
                if (f != null) ...<Widget>[
                  Ecart.vSm,
                  TexteSansCoupure(
                    a.autreFichier,
                    style: palette.inkAccent.applyTo(
                      textes.labelLarge ?? const TextStyle(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteNoms() {
    final a = t.admin.importFormulaires.depot.noms;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return AppCard(
      key: const ValueKey<String>('import-carte-noms'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(a.titre, style: textes.titleMedium),
          ),
          Ecart.vSm,
          TexteSansCoupure(
            _c.noms.onglet.trim().isEmpty
                ? _c.noms.classeur
                : a.ligne(
                    classeur: _c.noms.classeur.trim(),
                    onglet: _c.noms.onglet.trim(),
                  ),
            key: const ValueKey<String>('import-noms-ligne'),
            style: textes.bodyLarge,
          ),
          Ecart.vSm,
          TexteSansCoupure(
            a.aide,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vSm,
          LienDebut(
            key: PasDepot.corrigerNomsKey,
            libelle: _nomsOuverts ? a.garder : a.corriger,
            onPress: () => setState(() => _nomsOuverts = !_nomsOuverts),
          ),
          if (_nomsOuverts) ...<Widget>[
            Ecart.vMd,
            ChampEtiquete(
              libelle: a.classeur,
              controller: _classeur,
              onChanged: (String _) => setState(_surNoms),
            ),
            Ecart.vMd,
            ChampEtiquete(
              libelle: a.onglet,
              controller: _onglet,
              onChanged: (String _) => setState(_surNoms),
            ),
          ],
        ],
      ),
    );
  }

  /// Ce qui est arrive au fichier ou a l'analyse, avec quoi faire.
  List<Widget> _constats() {
    final a = t.admin.importFormulaires;
    final ProblemeFichier? probleme = _c.problemeFichier;
    final Object? echec = _c.erreurAnalyse;
    return <Widget>[
      if (_selectionEchouee) ...<Widget>[
        Ecart.vLg,
        BandeauAttention(
          key: const ValueKey<String>('import-selection-echec'),
          titre: a.fichier.titre,
          message: texteFichierIllisible(
            const ProblemeFichier(CauseFichier.inconnue),
          ),
          ton: TonEtat.alerte,
        ),
      ],
      if (probleme != null) ...<Widget>[
        Ecart.vLg,
        BandeauAttention(
          key: const ValueKey<String>('import-fichier-illisible'),
          titre: a.fichier.titre,
          message: texteFichierIllisible(probleme),
          ton: TonEtat.alerte,
        ),
      ] else if (_c.fichierSansLigne) ...<Widget>[
        Ecart.vLg,
        EmptyState(
          key: const ValueKey<String>('import-vide'),
          message: a.depot.vide,
          invitation: a.depot.videAide,
          icone: AppIcons.rienAAfficher,
          registre: RegistreVide.subi,
        ),
      ],
      if (echec != null &&
          probleme == null &&
          !_c.fichierSansLigne) ...<Widget>[
        Ecart.vLg,
        EtatSysteme(
          key: const ValueKey<String>('import-analyse-echec'),
          nature: NatureEtat.echecServeur,
          titre: a.analyse.echec,
          phrase: switch (echec) {
            ImportInvalide() || ImportRefuseInconnu() => a.analyse.refus,
            _ => a.analyse.echecPhrase,
          },
          libelleAction: a.analyse.reessayer,
          onAction: () => unawaited(_c.analyser()),
        ),
      ],
    ];
  }
}
