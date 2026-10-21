/// IMM-ACCUEIL-FRONT : « Importer les inscriptions », cote administration.
///
/// Decision du directeur du 12/10/2026 (`DECISION-IMMATRICULATION-2026-10-12.md`,
/// section 5) : les inscrits actuels sont importes depuis les deux CSV du
/// classeur des formulaires Google, accueillis sans tout ressaisir, avec un mot
/// d'accueil. Trois temps sur le meme ecran :
///
/// 1. **Deposer** : coller le contenu ou choisir le fichier (eleves,
///    enseignants) ;
/// 2. **Apercu** : ligne par ligne, ce qui sera refuse (champ manquant, adresse
///    mal ecrite, date, ligne d'essai) et ce qui merite un coup d'oeil
///    (doublon, age hors tranche, foyer de mineurs sans adulte), les foyers qui
///    seront crees, l'essai a blanc du serveur, puis les mots d'accueil (un mot
///    commun, la case « a patiente », un mot par foyer) et la confirmation ;
/// 3. **Resultat** : personnes creees, deja presentes, lignes refusees avec leur
///    motif, invitations a envoyer.
///
/// L'ecran lit une capacite (`capacites_import_inscriptions`), jamais un role.
/// Aucune regle metier n'est decidee ici : le serveur relit tout a la
/// confirmation, refuse ce qu'il refuse et ne cree jamais deux fois la meme
/// personne. Les bornes d'age viennent du serveur.
///
/// Etats : chargement (`Skeleton`), contenu, vide (aucune ligne importable),
/// erreur (`EtatSysteme`, « Reessayer »), hors ligne (l'apercu local reste
/// lisible, la confirmation n'est pas offerte et une phrase le dit), port
/// absent, double verification requise, acces refuse.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/import_inscriptions/analyse_inscriptions.dart';
import '../../core/import_inscriptions/analyseur_csv.dart';
import '../../core/import_inscriptions/port_import_inscriptions.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';
import '../salle_seance/information_controle.dart' show coupuresAdresse;
import 'selecteur_csv.dart';

/// Combien de lignes d'une liste l'ecran montre avant « autres lignes ».
const int _lignesMontrees = 50;

/// Combien de foyers l'ecran detaille avant « foyers non affiches ».
const int _foyersMontres = 100;

/// En-tetes d'un fichier absent : le serveur veut un en-tete dans les deux.
const String _enteteElevesVide = 'Email\r\n';
const String _enteteEnseignantsVide = 'Prénom,Nom,Email\r\n';

enum _Etape { saisie, apercu, resultat }

/// Les reglages d'un foyer retouches a la main.
class _Reglage {
  bool? patiente;
  bool ouvert = false;
  final TextEditingController accueil = TextEditingController();
  final TextEditingController patience = TextEditingController();

  void liberer() {
    accueil.dispose();
    patience.dispose();
  }
}

/// L'ecran « Importer les inscriptions ».
class ImportInscriptionsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const ImportInscriptionsPage({super.key});

  @override
  ConsumerState<ImportInscriptionsPage> createState() =>
      _ImportInscriptionsPageState();
}

class _ImportInscriptionsPageState
    extends ConsumerState<ImportInscriptionsPage> {
  final TextEditingController _eleves = TextEditingController();
  final TextEditingController _enseignants = TextEditingController();
  final TextEditingController _motLot = TextEditingController();
  final Map<String, _Reglage> _reglages = <String, _Reglage>{};

  _Etape _etape = _Etape.saisie;
  String? _nomEleves;
  String? _nomEnseignants;
  String? _messageSaisie;
  bool _fichierIllisible = false;

  bool _calcul = false;
  bool _envoi = false;
  ApercuLocal _local = ApercuLocal.vide;
  List<ProblemeLigne> _problemes = <ProblemeLigne>[];
  ApercuServeur? _serveur;
  bool _patienteLot = false;
  String? _echec;
  ResultatImport? _resultat;
  TableCsv _tableEleves = TableCsv.vide;
  TableCsv _tableEnseignants = TableCsv.vide;

  @override
  void dispose() {
    _eleves.dispose();
    _enseignants.dispose();
    _motLot.dispose();
    for (final _Reglage r in _reglages.values) {
      r.liberer();
    }
    super.dispose();
  }

  _Reglage _reglage(String email) => _reglages.putIfAbsent(email, _Reglage.new);

  Future<void> _choisir(bool eleves) async {
    setState(() {
      _fichierIllisible = false;
      _messageSaisie = null;
    });
    CsvChoisi? choisi;
    try {
      choisi = await ref.read(selecteurCsvProvider).choisir();
    } on Object {
      if (mounted) setState(() => _fichierIllisible = true);
      return;
    }
    if (choisi == null || !mounted) return;
    setState(() {
      if (eleves) {
        _eleves.text = choisi!.texte;
        _nomEleves = choisi.nom;
      } else {
        _enseignants.text = choisi!.texte;
        _nomEnseignants = choisi.nom;
      }
    });
  }

  String _csvEleves() =>
      _tableEleves.estVide ? _enteteElevesVide : _tableEleves.versCsv();

  String _csvEnseignants() => _tableEnseignants.estVide
      ? _enteteEnseignantsVide
      : _tableEnseignants.versCsv();

  Future<void> _voirApercu(CapacitesImport caps) async {
    if (_calcul) return;
    if (_eleves.text.trim().isEmpty && _enseignants.text.trim().isEmpty) {
      setState(() => _messageSaisie = t.admin.importInscriptions.manqueFichier);
      return;
    }
    final PortImportInscriptions? port = ref.read(
      portImportInscriptionsProvider,
    );
    _tableEleves = AnalyseurCsv.lire(_eleves.text);
    _tableEnseignants = AnalyseurCsv.lire(_enseignants.text);
    final ApercuLocal local = AnalyseInscriptions.analyser(
      eleves: _tableEleves,
      enseignants: _tableEnseignants,
      jour: ref.read(horlogeImportProvider)(),
      bornes: caps.bornes,
    );
    for (final _Reglage r in _reglages.values) {
      r.liberer();
    }
    _reglages.clear();
    setState(() {
      _messageSaisie = null;
      _echec = null;
      _local = local;
      _problemes = local.problemes;
      _serveur = null;
      _etape = _Etape.apercu;
    });
    // Rien d'importable, ou un fichier inutilisable : le serveur n'a rien a
    // essayer.
    if (port == null || local.rienAImporter || local.fichierBloque) return;
    if (ref.read(horsLigneProvider).value ?? false) {
      return;
    }
    setState(() => _calcul = true);
    try {
      final ApercuServeur serveur = await port.apercu(
        elevesCsv: _csvEleves(),
        enseignantsCsv: _csvEnseignants(),
      );
      if (!mounted) return;
      setState(() {
        _serveur = serveur;
        _problemes = _fusionner(local, serveur);
        _calcul = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _calcul = false;
        _echec = e is ImportInvalide
            ? t.admin.importInscriptions.echec.invalide
            : e is ImportRefuse
            ? t.admin.importInscriptions.echec.refuse
            : null;
      });
    }
  }

  /// Ajoute aux problemes locaux les refus que le serveur rend et que
  /// l'analyse locale n'a pas vus : le serveur est l'arbitre.
  List<ProblemeLigne> _fusionner(ApercuLocal local, ApercuServeur serveur) {
    final List<ProblemeLigne> tous = <ProblemeLigne>[...local.problemes];
    for (final MotifRejetServeur m in serveur.motifs) {
      final bool dejaVu = tous.any(
        (ProblemeLigne p) =>
            p.source == m.source &&
            p.ligne == m.ligne &&
            p.gravite == GraviteProbleme.refus,
      );
      if (dejaVu) continue;
      tous.add(
        ProblemeLigne(
          source: m.source,
          ligne: m.ligne,
          code: m.code ?? CodeProbleme.refusServeur,
        ),
      );
    }
    tous.sort((ProblemeLigne a, ProblemeLigne b) {
      final int s = a.source.index.compareTo(b.source.index);
      if (s != 0) return s;
      final int l = a.ligne.compareTo(b.ligne);
      return l != 0 ? l : a.code.index.compareTo(b.code.index);
    });
    return tous;
  }

  List<OptionFoyer> _options() {
    final String lot = _motLot.text.trim();
    return <OptionFoyer>[
      for (final FoyerApercu f in _local.foyers)
        () {
          final _Reglage? r = _reglages[f.email];
          final String propre = r?.accueil.text.trim() ?? '';
          final String patience = r?.patience.text.trim() ?? '';
          return OptionFoyer(
            email: f.email,
            aPatiente: r?.patiente ?? _patienteLot,
            motAccueil: propre.isNotEmpty
                ? propre
                : lot.isNotEmpty
                ? lot
                : null,
            motPatience: patience.isNotEmpty ? patience : null,
          );
        }(),
    ];
  }

  Future<void> _confirmer() async {
    final PortImportInscriptions? port = ref.read(
      portImportInscriptionsProvider,
    );
    if (port == null || _envoi) return;
    final a = t.admin.importInscriptions;
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: a.confirmation.question,
      consequence: a.confirmation.consequence,
      libelleConfirmer: a.confirmer,
    );
    if (!oui || !mounted) return;
    if (ref.read(horsLigneProvider).value ?? false) return;
    setState(() {
      _envoi = true;
      _echec = null;
    });
    try {
      final ResultatImport resultat = await port.confirmer(
        elevesCsv: _csvEleves(),
        enseignantsCsv: _csvEnseignants(),
        options: _options(),
      );
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _resultat = resultat;
        _etape = _Etape.resultat;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _echec = switch (e) {
          ImportHorsLigne() => a.echec.horsLigne,
          ImportRefuse() => a.echec.refuse,
          ImportInvalide() => a.echec.invalide,
          _ => a.echec.serveur,
        };
      });
    }
  }

  void _recommencer() {
    for (final _Reglage r in _reglages.values) {
      r.liberer();
    }
    _reglages.clear();
    setState(() {
      _eleves.clear();
      _enseignants.clear();
      _motLot.clear();
      _nomEleves = null;
      _nomEnseignants = null;
      _patienteLot = false;
      _resultat = null;
      _serveur = null;
      _problemes = <ProblemeLigne>[];
      _local = ApercuLocal.vide;
      _echec = null;
      _etape = _Etape.saisie;
    });
  }

  void _retourSaisie() => setState(() {
    _echec = null;
    _etape = _Etape.saisie;
  });

  @override
  Widget build(BuildContext context) {
    final a = t.admin.importInscriptions;
    final AsyncValue<CapacitesImport> caps = ref.watch(capacitesImportProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    return PageShell(
      titre: a.titre,
      sousTitre: a.sousTitre,
      entete: SousNavigationDomaine(onglets: ongletsPersonnes(), indexActif: 4),
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: BlocAsynchrone<CapacitesImport>(
            key: const ValueKey<String>('import-bloc'),
            valeur: caps,
            squelette: const Skeleton.liste(lignes: 3),
            onReessayer: () => ref.invalidate(capacitesImportProvider),
            erreurVersEtat: (Object e, VoidCallback? reessayer) {
              if (e is CapaciteIndisponible) {
                return EtatSysteme(
                  key: const ValueKey<String>('import-indisponible'),
                  nature: NatureEtat.indisponible,
                  titre: a.indisponibleTitre,
                  phrase: a.indisponiblePhrase,
                  dependance: dependanceImportInscriptions,
                );
              }
              return horsLigne
                  ? EtatSansDonnees(
                      key: const ValueKey<String>('import-sans-donnees'),
                      quoi: a.sansDonnees,
                      onAction: reessayer,
                    )
                  : EtatSysteme(
                      key: const ValueKey<String>('import-erreur'),
                      nature: NatureEtat.echecServeur,
                      phrase: a.erreur,
                      onAction: reessayer,
                    );
            },
            construire: (CapacitesImport c) {
              if (!c.peutImporter) {
                return c.doubleVerificationRequise
                    ? EtatSysteme(
                        key: const ValueKey<String>('import-double'),
                        nature: NatureEtat.accesRefuse,
                        titre: a.acces.doubleTitre,
                        phrase: a.acces.doublePhrase,
                      )
                    : const EtatSysteme(
                        key: ValueKey<String>('import-refuse'),
                        nature: NatureEtat.accesRefuse,
                      );
              }
              return switch (_etape) {
                _Etape.saisie => _saisie(c),
                _Etape.apercu => _apercu(c, horsLigne),
                _Etape.resultat => _resultatVue(),
              };
            },
          ),
        ),
      ),
    );
  }

  /// L'unique bouton plein de l'ecran (K-56) : « Voir l'apercu » au premier
  /// temps, « Confirmer l'import » au deuxieme. Jamais deux a la fois.
  Widget _boutonPlein({
    required String cle,
    required String libelle,
    required VoidCallback? onPress,
    bool enCours = false,
  }) => ActionPrincipale(
    key: ValueKey<String>(cle),
    libelle: libelle,
    enCours: enCours,
    onPress: onPress,
  );

  // --- 1. deposer ---

  Widget _saisie(CapacitesImport caps) {
    final a = t.admin.importInscriptions;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      key: const ValueKey<String>('import-saisie'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(a.intro, style: textes.bodyMedium),
        Ecart.vLg,
        _champFichier(
          titre: a.eleves.titre,
          aide: a.eleves.aide,
          champ: a.eleves.champ,
          controleur: _eleves,
          nom: _nomEleves,
          cle: 'eleves',
          onChoisir: () => unawaited(_choisir(true)),
        ),
        Ecart.vSection,
        _champFichier(
          titre: a.enseignants.titre,
          aide: a.enseignants.aide,
          champ: a.enseignants.champ,
          controleur: _enseignants,
          nom: _nomEnseignants,
          cle: 'enseignants',
          onChoisir: () => unawaited(_choisir(false)),
        ),
        Ecart.vLg,
        if (_fichierIllisible || _messageSaisie != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _fichierIllisible ? a.fichierIllisible : _messageSaisie!,
                key: const ValueKey<String>('import-message-saisie'),
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ),
        _boutonPlein(
          cle: 'import-voir-apercu',
          libelle: a.voirApercu,
          onPress: () => unawaited(_voirApercu(caps)),
        ),
      ],
    );
  }

  Widget _champFichier({
    required String titre,
    required String aide,
    required String champ,
    required TextEditingController controleur,
    required String? nom,
    required String cle,
    required VoidCallback onChoisir,
  }) {
    final a = t.admin.importInscriptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(titre: titre),
        Ecart.vSm,
        ZoneSaisie(
          controleur: controleur,
          cleChamp: ValueKey<String>('import-champ-$cle'),
          libelle: champ,
          aide: aide,
          minLignes: 4,
          maxLignes: 8,
          majuscules: TextCapitalization.none,
        ),
        Ecart.vSm,
        LienFleche(
          key: ValueKey<String>('import-choisir-$cle'),
          libelle: a.choisir,
          icone: AppIcons.telecharger,
          fleche: false,
          alignerEnDebut: true,
          onPress: onChoisir,
        ),
        if (nom != null)
          Text(
            a.fichierCharge(nom: nom),
            key: ValueKey<String>('import-nom-$cle'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  // --- 2. apercu ---

  String _fichierNom(SourceImport s) => switch (s) {
    SourceImport.eleves => t.admin.importInscriptions.fichier.eleves,
    SourceImport.enseignants => t.admin.importInscriptions.fichier.enseignants,
  };

  String _motifTexte(ProblemeLigne p) {
    final m = t.admin.importInscriptions.motif;
    return switch (p.code) {
      CodeProbleme.ligneVide => m.ligneVide,
      CodeProbleme.colonnesDifferentes => m.colonnesDifferentes,
      CodeProbleme.ligneTest => m.ligneTest,
      CodeProbleme.personneSansNom => m.personneSansNom,
      CodeProbleme.emailManquant => m.emailManquant,
      CodeProbleme.emailInvalide => m.emailInvalide,
      CodeProbleme.dateInvalide => m.dateInvalide,
      CodeProbleme.refusServeur => m.serveur,
      CodeProbleme.enteteEmailAbsent => m.enteteEmailAbsent,
      CodeProbleme.guillemetNonFerme => m.guillemetNonFerme,
      CodeProbleme.doublonAdresse => m.doublonAdresse(
        autre: p.autreLigne ?? p.ligne,
      ),
      CodeProbleme.doublonPersonne => m.doublonPersonne(
        autre: p.autreLigne ?? p.ligne,
      ),
      CodeProbleme.dateFuture => m.dateFuture,
      CodeProbleme.ageTropJeune => m.ageTropJeune,
      CodeProbleme.adulteTropJeune => m.adulteTropJeune,
      CodeProbleme.foyerSansAdulte => m.foyerSansAdulte,
    };
  }

  String _ligneTexte(ProblemeLigne p) => t.admin.importInscriptions.ligne(
    fichier: _fichierNom(p.source),
    ligne: p.ligne,
    motif: _motifTexte(p),
  );

  Widget _listeProblemes({
    required String cle,
    required String titre,
    required String aide,
    required List<ProblemeLigne> lignes,
    required TonEtat ton,
  }) {
    final a = t.admin.importInscriptions;
    final TextTheme textes = Theme.of(context).textTheme;
    final List<ProblemeLigne> montrees = lignes
        .take(_lignesMontrees)
        .toList(growable: false);
    return AppCard(
      key: ValueKey<String>('import-$cle'),
      entete: OverflowBar(
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.start,
        spacing: AppSpacing.sm,
        overflowSpacing: AppSpacing.sm,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(titre, style: textes.titleMedium),
          ),
          StatusPill(libelle: '${lignes.length}', ton: ton),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(aide, style: textes.bodyMedium),
          Ecart.vMd,
          for (final ProblemeLigne p in montrees) ...<Widget>[
            Text(
              _ligneTexte(p),
              key: ValueKey<String>(
                'import-$cle-${p.source.name}-${p.ligne}-${p.code.name}',
              ),
              style: textes.bodyMedium,
            ),
            Ecart.vSm,
          ],
          if (lignes.length > montrees.length)
            Text(
              a.autresLignes(n: lignes.length - montrees.length),
              style: textes.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _apercu(CapacitesImport caps, bool horsLigne) {
    final a = t.admin.importInscriptions;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final List<ProblemeLigne> refus = <ProblemeLigne>[
      for (final ProblemeLigne p in _problemes)
        if (p.gravite == GraviteProbleme.refus) p,
    ];
    final List<ProblemeLigne> alertes = <ProblemeLigne>[
      for (final ProblemeLigne p in _problemes)
        if (p.gravite == GraviteProbleme.alerte) p,
    ];
    final int lignesRefusees = <(SourceImport, int)>{
      for (final ProblemeLigne p in refus) (p.source, p.ligne),
    }.length;

    final Widget tete = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(a.apercu.titre, style: textes.titleLarge),
        ),
        Ecart.vSm,
        Text(a.apercu.intro, style: textes.bodyMedium),
      ],
    );

    if (_local.rienAImporter) {
      return Column(
        key: const ValueKey<String>('import-apercu'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          tete,
          Ecart.vLg,
          if (refus.isNotEmpty) ...<Widget>[
            _listeProblemes(
              cle: 'refus',
              titre: a.apercu.refusees,
              aide: a.apercu.refusAide,
              lignes: refus,
              ton: TonEtat.avertissement,
            ),
            Ecart.vLg,
          ],
          EmptyState(
            key: const ValueKey<String>('import-vide'),
            message: a.apercu.vide,
            icone: AppIcons.foyer,
            libelleAction: a.apercu.modifier,
            onAction: _retourSaisie,
          ),
        ],
      );
    }

    final bool serveurPret = _serveur != null && !_calcul;
    final bool peutConfirmer =
        serveurPret && !horsLigne && !_local.fichierBloque;

    return Column(
      key: const ValueKey<String>('import-apercu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        tete,
        Ecart.vLg,
        PileCartes(
          children: <Widget>[
            AppCard(
              key: const ValueKey<String>('import-resume'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  LigneCleValeur(
                    cle: a.apercu.lignesEleves,
                    valeur: '${_local.lignesEleves}',
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: a.apercu.lignesEnseignants,
                    valeur: '${_local.lignesEnseignants}',
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: a.apercu.foyers,
                    valeur: '${_local.foyers.length}',
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: a.apercu.personnes,
                    valeur: '${_local.personnes}',
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: a.apercu.refusees,
                    valeur: '$lignesRefusees',
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: a.apercu.alertes,
                    valeur:
                        '${<(SourceImport, int)>{for (final ProblemeLigne p in alertes) (p.source, p.ligne)}.length}',
                    chiffres: true,
                  ),
                ],
              ),
            ),
            _carteServeur(),
            if (refus.isNotEmpty)
              _listeProblemes(
                cle: 'refus',
                titre: a.apercu.refusees,
                aide: a.apercu.refusAide,
                lignes: refus,
                ton: TonEtat.avertissement,
              ),
            if (alertes.isNotEmpty)
              _listeProblemes(
                cle: 'alertes',
                titre: a.apercu.alertes,
                aide: a.apercu.alertesAide,
                lignes: alertes,
                ton: TonEtat.neutre,
              ),
            _carteMots(),
          ],
        ),
        Ecart.vLg,
        if (_echec != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _echec!,
                key: const ValueKey<String>('import-echec'),
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
          ),
        if (horsLigne)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              a.horsLigne,
              key: const ValueKey<String>('import-hors-ligne'),
              style: textes.bodyMedium,
            ),
          ),
        // Le bouton qui ne peut pas aboutir n'est pas rendu (hors ligne,
        // serveur muet) : une phrase le dit au-dessus.
        if (peutConfirmer || _envoi)
          _boutonPlein(
            cle: 'import-confirmer',
            libelle: a.confirmer,
            enCours: _envoi,
            onPress: _envoi ? null : () => unawaited(_confirmer()),
          ),
        Ecart.vMd,
        LienFleche(
          key: const ValueKey<String>('import-modifier'),
          libelle: a.apercu.modifier,
          fleche: false,
          alignerEnDebut: true,
          onPress: _retourSaisie,
        ),
      ],
    );
  }

  Widget _carteServeur() {
    final a = t.admin.importInscriptions;
    final TextTheme textes = Theme.of(context).textTheme;
    final ApercuServeur? s = _serveur;
    return AppCard(
      key: const ValueKey<String>('import-serveur'),
      entete: Semantics(
        header: true,
        child: Text(a.serveur.titre, style: textes.titleMedium),
      ),
      child: _calcul
          ? const Skeleton.liste(lignes: 3)
          : s == null
          ? Text(
              _echec ?? a.serveur.indisponible,
              key: const ValueKey<String>('import-serveur-indisponible'),
              style: textes.bodyMedium,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LigneCleValeur(
                  cle: a.serveur.foyers,
                  valeur: '${s.foyers}',
                  chiffres: true,
                ),
                LigneCleValeur(
                  cle: a.serveur.personnes,
                  valeur: '${s.personnes}',
                  chiffres: true,
                ),
                LigneCleValeur(
                  cle: a.serveur.refusees,
                  valeur: '${s.lignesRejetees}',
                  chiffres: true,
                ),
              ],
            ),
    );
  }

  // --- les mots d'accueil ---

  Widget _carteMots() {
    final a = t.admin.importInscriptions;
    final TextTheme textes = Theme.of(context).textTheme;
    final List<FoyerApercu> montres = _local.foyers
        .take(_foyersMontres)
        .toList(growable: false);
    return AppCard(
      key: const ValueKey<String>('import-mots'),
      entete: Semantics(
        header: true,
        child: Text(a.mots.titre, style: textes.titleMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(a.mots.intro, style: textes.bodyMedium),
          Ecart.vLg,
          ZoneSaisie(
            controleur: _motLot,
            cleChamp: const ValueKey<String>('import-mot-lot'),
            libelle: a.mots.lotChamp,
            aide: a.mots.lotAide,
            minLignes: 3,
            maxLignes: 6,
          ),
          Ecart.vMd,
          _bascule(
            cle: 'import-patiente-lot',
            titre: a.mots.lotPatience,
            legende: a.mots.lotPatienceAide,
            valeur: _patienteLot,
            onChange: (bool v) => setState(() => _patienteLot = v),
          ),
          Ecart.vLg,
          for (final FoyerApercu f in montres) ...<Widget>[
            _carteFoyer(f),
            Ecart.vLg,
          ],
          if (_local.foyers.length > montres.length)
            Text(
              a.foyer.nonAffiches(n: _local.foyers.length - montres.length),
              style: textes.bodyMedium,
            ),
        ],
      ),
    );
  }

  Widget _bascule({
    required String cle,
    required String titre,
    required bool valeur,
    required ValueChanged<bool> onChange,
    String? legende,
  }) {
    final TextTheme textes = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(titre, style: textes.titleSmall),
                if (legende != null) Text(legende, style: textes.bodyMedium),
              ],
            ),
          ),
          Ecart.hSm,
          Switch.adaptive(
            key: ValueKey<String>(cle),
            value: valeur,
            onChanged: onChange,
          ),
        ],
      ),
    );
  }

  Widget _carteFoyer(FoyerApercu f) {
    final a = t.admin.importInscriptions;
    final TextTheme textes = Theme.of(context).textTheme;
    final _Reglage r = _reglage(f.email);
    final bool patiente = r.patiente ?? _patienteLot;
    final String prenom = f.destinataire;
    final List<String> eleves = f.prenomsEleves;
    return Column(
      key: ValueKey<String>('import-foyer-${f.email}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(header: true, child: Text(prenom, style: textes.titleSmall)),
        Text(
          a.foyer.adresse(adresse: coupuresAdresse(f.email)),
          style: textes.bodyMedium,
        ),
        if (eleves.isNotEmpty)
          Text(
            a.foyer.eleves(eleves: eleves.join(', ')),
            style: textes.bodyMedium,
          ),
        Ecart.vSm,
        _bascule(
          cle: 'import-patiente-${f.email}',
          titre: a.foyer.patiente,
          valeur: patiente,
          onChange: (bool v) => setState(() => r.patiente = v),
        ),
        LienFleche(
          key: ValueKey<String>('import-retoucher-${f.email}'),
          libelle: r.ouvert
              ? a.foyer.fermer
              : a.foyer.retoucher(
                  dePrenom: deDevant(
                    prenom,
                    cle: 'admin.importInscriptions.foyer.retoucher',
                  ),
                ),
          libelleSemantique: r.ouvert
              ? a.foyer.fermer
              : a.foyer.retoucher(
                  dePrenom: deDevant(
                    prenom,
                    cle: 'admin.importInscriptions.foyer.retoucher',
                  ),
                ),
          fleche: false,
          alignerEnDebut: true,
          onPress: () => setState(() => r.ouvert = !r.ouvert),
        ),
        if (r.ouvert) ...<Widget>[
          Ecart.vSm,
          ZoneSaisie(
            controleur: r.accueil,
            cleChamp: ValueKey<String>('import-mot-${f.email}'),
            libelle: a.foyer.champAccueil(
              dePrenom: deDevant(
                prenom,
                cle: 'admin.importInscriptions.foyer.champAccueil',
              ),
            ),
            aide: a.foyer.motAide,
            minLignes: 3,
            maxLignes: 6,
          ),
          if (patiente) ...<Widget>[
            Ecart.vMd,
            ZoneSaisie(
              controleur: r.patience,
              cleChamp: ValueKey<String>('import-patience-${f.email}'),
              libelle: a.foyer.champPatience(
                dePrenom: deDevant(
                  prenom,
                  cle: 'admin.importInscriptions.foyer.champPatience',
                ),
              ),
              aide: a.foyer.motAide,
              minLignes: 3,
              maxLignes: 6,
            ),
          ],
        ],
      ],
    );
  }

  // --- 3. resultat ---

  Widget _resultatVue() {
    final a = t.admin.importInscriptions;
    final TextTheme textes = Theme.of(context).textTheme;
    final ResultatImport r = _resultat!;
    final List<ProblemeLigne> refus = <ProblemeLigne>[
      for (final ProblemeLigne p in _problemes)
        if (p.gravite == GraviteProbleme.refus) p,
    ];
    final int lignesRefusees = <(SourceImport, int)>{
      for (final ProblemeLigne p in refus) (p.source, p.ligne),
    }.length;
    final bool rienDeNouveau = r.personnesCreees == 0 && r.foyersCrees == 0;
    return Column(
      key: const ValueKey<String>('import-resultat'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(a.resultat.titre, style: textes.titleLarge),
        ),
        Ecart.vLg,
        PileCartes(
          children: <Widget>[
            AppCard(
              key: const ValueKey<String>('import-resultat-chiffres'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  LigneCleValeur(
                    cle: a.resultat.personnesCreees,
                    valeur: '${r.personnesCreees}',
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: a.resultat.personnesPresentes,
                    valeur: '${r.personnesDejaImportees}',
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: a.resultat.foyersCrees,
                    valeur: '${r.foyersCrees}',
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: a.resultat.foyersVus,
                    valeur: '${r.foyersTraites}',
                    chiffres: true,
                  ),
                  LigneCleValeur(
                    cle: a.resultat.refusees,
                    valeur: '$lignesRefusees',
                    chiffres: true,
                  ),
                  if (rienDeNouveau) ...<Widget>[
                    Ecart.vSm,
                    Text(
                      a.resultat.rienDeNouveau,
                      key: const ValueKey<String>('import-rien-de-nouveau'),
                      style: textes.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            AppCard(
              key: const ValueKey<String>('import-invitations'),
              entete: OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.start,
                spacing: AppSpacing.sm,
                overflowSpacing: AppSpacing.sm,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      a.resultat.invitations,
                      style: textes.titleMedium,
                    ),
                  ),
                  StatusPill(
                    libelle: '${r.foyersCrees}',
                    ton: r.foyersCrees > 0 ? TonEtat.accent : TonEtat.neutre,
                  ),
                ],
              ),
              child: Text(a.resultat.invitationsAide, style: textes.bodyMedium),
            ),
            if (refus.isNotEmpty)
              _listeProblemes(
                cle: 'refus',
                titre: a.resultat.refusees,
                aide: a.resultat.refusAide,
                lignes: refus,
                ton: TonEtat.avertissement,
              ),
          ],
        ),
        Ecart.vLg,
        LienFleche(
          key: const ValueKey<String>('import-recommencer'),
          libelle: a.resultat.recommencer,
          fleche: false,
          alignerEnDebut: true,
          onPress: _recommencer,
        ),
      ],
    );
  }
}
