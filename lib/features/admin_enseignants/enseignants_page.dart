/// LP-2 (SPEC-LISTE-PERSONNES §2 et §3) : la liste des enseignants de la
/// direction, sous Personnes.
///
/// Une personne n'y apparait qu'une fois, pour toute sa vie : la ligne est son
/// dossier de candidature, et montre sa **phase** (candidat, accueil,
/// disponible, en poste, absent, en pause, suspendu, parti) et ce qui compte
/// dans cette phase. La phase, ce qui manque, qui attend quoi, les gestes
/// permis par ligne et par selection sont **decides par le serveur**
/// (`lister_enseignants`, LP-1) : l'ecran n'en deduit rien.
///
/// Meme grammaire que la liste des candidatures : le titre est le selecteur de
/// section, une loupe ouvre la recherche, un menu « Phase » remplace « File »,
/// le badge « Nouveau » marque les arrivees, un menu « ... » par ligne, la
/// selection avec les gestes que le serveur groupe.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/admin_domaine.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_lot_candidatures.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/enseignants/modeles_enseignants.dart';
import '../../core/enseignants/port_enseignants.dart';
import '../../core/i18n/isolat_bidi.dart' show enchainer;
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badge_nouveau.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/barre_selection.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_candidature/feuille_geste.dart';
import '../admin_candidature/gestes_proposes.dart';
import '../admin_candidature/libelles_candidature.dart';
import '../admin_candidatures/libelles_candidatures.dart';
import '../admin_candidatures/lot_candidatures.dart';
import '../admin_candidatures/menu_ligne_candidature.dart' show iconeDuGeste;

/// Le geste du moteur (nom du serveur) que l'ecran sait faire, ou `null`.
/// « Choisir le responsable » n'y est pas : comme dans la liste des
/// candidatures, la liste des responsables n'est pas servie, et un geste qui ne
/// peut pas aboutir n'est pas offert.
GesteCandidature? gesteDuServeur(String nom) => switch (nom) {
  'demander_complement' => GesteCandidature.demanderComplement,
  'admettre_verifications' => GesteCandidature.admettreVerifications,
  'confirmer_moyen_paiement' => GesteCandidature.confirmerMoyenPaiement,
  'infirmer_moyen_paiement' => GesteCandidature.infirmerMoyenPaiement,
  'mettre_en_pause' => GesteCandidature.mettreEnPause,
  'lever_pause' => GesteCandidature.leverPause,
  'refuser' => GesteCandidature.refuser,
  'retirer' => GesteCandidature.consignerRetrait,
  'rouvrir' => GesteCandidature.rouvrir,
  'valider_piece' => GesteCandidature.validerPiece,
  _ => null,
};

/// Les gestes du menu « ... » d'une ligne, dans l'ordre : les gestes ordinaires,
/// puis les gestes destructifs. Seulement ceux que le serveur permet.
List<GesteCandidature> gestesDuMenuEnseignant(LigneEnseignant ligne) {
  final List<GesteCandidature> tous = <GesteCandidature>[
    for (final String nom in ligne.gestes) ?gesteDuServeur(nom),
  ];
  return <GesteCandidature>[
    ...tous.where((GesteCandidature g) => !g.destructif),
    ...tous.where((GesteCandidature g) => g.destructif),
  ];
}

/// Les gestes de lot que **toutes** les lignes retenues permettent : la barre
/// de la selection ne propose que ce que le serveur annonce groupable pour
/// chacune d'elles.
List<GesteLot> gestesDeLot(Iterable<LigneEnseignant> retenues) {
  if (retenues.isEmpty) return const <GesteLot>[];
  return <GesteLot>[
    for (final GesteLot g in GesteLot.values)
      if (retenues.every(
        (LigneEnseignant l) => l.gestesGroupables.any(
          (String nom) => GesteLot.depuisSql(nom) == g,
        ),
      ))
        g,
  ];
}

/// Le mot de la phase.
String libellePhase(PhaseEnseignant phase) {
  final p = t.admin.listeEnseignants.phases;
  return switch (phase) {
    PhaseEnseignant.candidat => p.candidat,
    PhaseEnseignant.accueil => p.accueil,
    PhaseEnseignant.disponible => p.disponible,
    PhaseEnseignant.enPoste => p.enPoste,
    PhaseEnseignant.absent => p.absent,
    PhaseEnseignant.pause => p.pause,
    PhaseEnseignant.suspendu => p.suspendu,
    PhaseEnseignant.parti => p.parti,
  };
}

/// La famille de la pastille de phase : jamais la couleur seule, le mot la
/// double.
TonEtat tonDePhase(PhaseEnseignant phase) => switch (phase) {
  PhaseEnseignant.accueil => TonEtat.avertissement,
  PhaseEnseignant.disponible => TonEtat.accent,
  PhaseEnseignant.enPoste => TonEtat.succes,
  PhaseEnseignant.absent || PhaseEnseignant.suspendu => TonEtat.alerte,
  PhaseEnseignant.candidat ||
  PhaseEnseignant.pause ||
  PhaseEnseignant.parti => TonEtat.neutre,
};

/// Le mot d'une chose qui manque a un enseignant en accueil, ou `null` : une
/// cle inconnue n'est pas devinee.
String? libelleManque(String cle) {
  final m = t.admin.listeEnseignants.manque;
  return switch (cle) {
    'compte_inactif' => m.compteInactif,
    'piece_non_validee' => m.pieceNonValidee,
    'langues_absentes' => m.languesAbsentes,
    'genre_inconnu' => m.genreInconnu,
    'indisponible' => m.indisponible,
    'photo_absente' => m.photoAbsente,
    'disponibilites_absentes' => m.disponibilitesAbsentes,
    _ => null,
  };
}

/// La phrase « Il manque : ... », ou `null` quand rien ne manque.
String? phraseManque(LigneEnseignant ligne) {
  final List<String> mots = <String>[
    for (final String c in ligne.manque) ?libelleManque(c),
  ];
  if (mots.isEmpty) return null;
  // En arabe, la virgule est la virgule arabe.
  final String virgule = LocaleSettings.currentLocale == AppLocale.ar
      ? '، '
      : ', ';
  return t.admin.listeEnseignants.manque.intro(liste: enchainer(mots, virgule));
}

/// Le mot de « qui attend », ou `null`.
String? phraseAttend(LigneEnseignant ligne) {
  final a = t.admin.listeEnseignants.attend;
  return switch (ligne.quiAttend) {
    'candidat' => a.candidat,
    'direction' => a.direction,
    'enseignant' => a.enseignant,
    _ => null,
  };
}

/// Le mot court de « qui attend » (une colonne), ou `null`.
String? motAttend(LigneEnseignant ligne) {
  final a = t.admin.listeEnseignants.attendCourt;
  return switch (ligne.quiAttend) {
    'candidat' => a.candidat,
    'direction' => a.direction,
    'enseignant' => a.enseignant,
    _ => null,
  };
}

/// Le resume d'une ligne propre a sa phase : jamais tout, le detail est dans le
/// dossier. Une ou deux phrases courtes. [tableau] : au bureau, « qui attend »,
/// les classes et la prochaine seance ont leur colonne et ne se repetent pas.
List<String> resumeDeLigne(LigneEnseignant ligne, {bool tableau = false}) {
  final l = t.admin.listeEnseignants;
  final List<String> morceaux = <String>[];
  switch (ligne.phase) {
    case PhaseEnseignant.candidat:
      final EtatAffiche? etat = etatAffiche(ligne.dossier);
      if (etat != null) morceaux.add(etat.libelle);
    case PhaseEnseignant.accueil:
      if (phraseManque(ligne) case final String m) morceaux.add(m);
    case PhaseEnseignant.disponible:
    case PhaseEnseignant.pause:
    case PhaseEnseignant.suspendu:
    case PhaseEnseignant.parti:
      break;
    case PhaseEnseignant.enPoste:
    case PhaseEnseignant.absent:
      if (!tableau) {
        morceaux.add(
          '${l.classes(n: ligne.classes.nombre)} · '
          '${LibellesGroupe.insecable(l.heures(h: _heures(ligne.classes.heuresSemaine)))}',
        );
        if (ligne.prochaineSeance case final DateTime s) {
          morceaux.add(
            l.prochaineSeance(date: dateCourteCandidature(s.toLocal())),
          );
        }
      }
      if (ligne.remplacements.donnes + ligne.remplacements.recus > 0) {
        morceaux.add(
          l.remplacements(
            donnes: '${ligne.remplacements.donnes}',
            recus: '${ligne.remplacements.recus}',
          ),
        );
      }
  }
  if (!tableau) {
    if (phraseAttend(ligne) case final String a) morceaux.add(a);
  }
  return morceaux;
}

String _heures(double h) =>
    h == h.roundToDouble() ? '${h.round()}' : h.toStringAsFixed(1);

/// La cle de la ligne ou de la carte d'un enseignant, pour les tests.
Key cleEnseignant(String id) => ValueKey<String>('enseignant-$id');

/// L'ecran « Enseignants ».
class EnseignantsPage extends ConsumerStatefulWidget {
  /// Cree l'ecran. [ouvrirCandidature] mene au dossier de la personne (le meme
  /// dossier pour toute sa vie) ; sans lui, la ligne n'est pas pressable hors
  /// selection.
  const EnseignantsPage({super.key, this.ouvrirCandidature});

  /// Ouvre le dossier d'une personne, ou `null` : la ligne ne s'ouvre pas.
  final void Function(LigneCandidature ligne)? ouvrirCandidature;

  /// La cle de la page.
  static const Key clePage = ValueKey<String>('enseignants-page');

  /// La loupe qui ouvre la recherche.
  static const Key cleLoupe = ValueKey<String>('enseignants-loupe');

  /// Le champ de recherche.
  static const Key cleRecherche = ValueKey<String>('enseignants-recherche');

  /// Le menu « Phase ».
  static const Key clePhase = ValueKey<String>('enseignants-phase');

  /// Le menu du tri.
  static const Key cleTri = ValueKey<String>('enseignants-tri');

  /// Le nombre d'enseignants.
  static const Key cleTotal = ValueKey<String>('enseignants-total');

  /// La barre du traitement groupe.
  static const Key cleBarreLot = ValueKey<String>('enseignants-barre-lot');

  /// Le lien « Selectionner ».
  static const Key cleSelectionner = ValueKey<String>(
    'enseignants-selectionner',
  );

  /// La note des comptes sans dossier.
  static const Key cleSansDossier = ValueKey<String>(
    'enseignants-sans-dossier',
  );

  /// Le menu « ... » d'une ligne.
  static Key cleMenu(String id) => ValueKey<String>('enseignant-menu-$id');

  /// L'operation de lot [g].
  static Key cleOperationLot(GesteLot g) =>
      ValueKey<String>('enseignants-lot-${g.valeurSql}');

  @override
  ConsumerState<EnseignantsPage> createState() => _EtatEnseignantsPage();
}

class _EtatEnseignantsPage extends ConsumerState<EnseignantsPage> {
  late final TextEditingController _recherche;
  Timer? _attenteSaisie;
  FiltreEnseignants _filtre = const FiltreEnseignants();
  TriEnseignants _tri = TriEnseignants.activite;
  int _page = 1;
  bool _rechercheOuverte = false;
  bool _enSelection = false;
  final Map<String, LigneEnseignant> _retenues = <String, LigneEnseignant>{};
  CompteursEnseignants _compteurs = const CompteursEnseignants();
  String? _retour;
  String? _echecLigne;
  String? _ouverture;

  /// Le delai de la recherche saisie, comme la liste des candidatures.
  /// Une duree metier de saisie (300 ms), pas un jeton d'`AppMouvement`.
  static const Duration _delaiSaisie = Duration(
    microseconds: 300 * Duration.microsecondsPerMillisecond,
  );

  RequeteEnseignants get _requete =>
      RequeteEnseignants(filtre: _filtre, tri: _tri, page: _page);

  bool get _rechercheVisible => _rechercheOuverte || _recherche.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _recherche = TextEditingController();
  }

  @override
  void dispose() {
    _attenteSaisie?.cancel();
    _recherche.dispose();
    super.dispose();
  }

  void _relire() => ref.invalidate(pageEnseignantsProvider(_requete));

  void _filtrer(FiltreEnseignants filtre) {
    setState(() {
      if (_retenues.isNotEmpty) {
        _retenues.clear();
        _retour = t.admin.candidatures.lot.selectionRetiree;
      }
      _filtre = filtre;
      _page = 1;
    });
  }

  void _chercher(String texte) {
    _attenteSaisie?.cancel();
    _attenteSaisie = Timer(_delaiSaisie, () {
      if (!mounted) return;
      _filtrer(_filtre.avec(recherche: texte));
    });
  }

  void _chercherTout(String texte) {
    _attenteSaisie?.cancel();
    _filtrer(_filtre.avec(recherche: texte));
  }

  void _effacer() {
    _attenteSaisie?.cancel();
    _recherche.clear();
    _filtrer(const FiltreEnseignants());
  }

  void _allerAPage(int page) => setState(() => _page = page);

  void _basculerSelection() => setState(() {
    _enSelection = !_enSelection;
    if (!_enSelection) _retenues.clear();
  });

  void _basculerLigne(LigneEnseignant ligne) => setState(() {
    if (_retenues.remove(ligne.id) == null) _retenues[ligne.id] = ligne;
  });

  // --- Un geste depuis le menu d'une ligne --------------------------------

  /// Le geste d'une ligne : lire le dossier (la ligne n'en porte ni la version
  /// ni les reponses), rappeler la table des gestes sur ce qu'on vient de lire,
  /// puis ouvrir **la meme feuille** que la fiche. Rien n'est fait si le geste
  /// n'est plus permis.
  Future<void> _gesteDeLigne(
    LigneEnseignant ligne,
    GesteCandidature geste,
    CapacitesCandidatures capacites,
  ) async {
    if (_ouverture != null) return;
    final LigneCandidature dossier = ligne.dossier;
    final DemandeDossier demande = DemandeDossier(
      dossier.reference,
      id: dossier.id,
    );
    setState(() {
      _ouverture = nomAffiche(dossier);
      _echecLigne = null;
      _retour = null;
    });
    ref.invalidate(detailCandidatureProvider(demande));
    final ProviderSubscription<AsyncValue<DetailCandidature>> garde = ref
        .listenManual(
          detailCandidatureProvider(demande),
          (
            AsyncValue<DetailCandidature>? _,
            AsyncValue<DetailCandidature> _,
          ) {},
        );
    DetailCandidature? detail;
    try {
      detail = await ref.read(detailCandidatureProvider(demande).future);
    } on Object {
      detail = null;
    } finally {
      garde.close();
    }
    if (!mounted) return;
    final r = t.admin.candidatures.liste;
    if (detail == null) {
      setState(() {
        _ouverture = null;
        _echecLigne = r.dossierIllisible;
      });
      return;
    }
    setState(() => _ouverture = null);
    if (!gestePermis(geste, detail)) {
      final LigneCandidature lu = detail.ligne;
      setState(
        () => _echecLigne = r.gestePlusPossible(
          etat: libelleEtatCourant(
            issue: lu.issue,
            enPause: lu.enPause,
            etape: lu.etape,
            etat: lu.etat,
          ),
        ),
      );
      _relire();
      return;
    }
    final SortieFeuille? sortie = await ouvrirFeuilleGeste(
      context,
      geste: geste,
      detail: detail,
      capacites: capacites,
    );
    if (!mounted || sortie == null) return;
    _relire();
    setState(
      () => _retour = sortie.issue == IssueFeuille.fait
          ? r.retourLigne(
              nom: nomAffiche(dossier),
              retour: sortie.rejoue
                  ? t.admin.candidatures.retours.rejoue
                  : libelleRetour(geste),
            )
          : null,
    );
  }

  // --- Le traitement groupe -----------------------------------------------

  Future<void> _lancerLot(GesteLot geste, CapacitesCandidatures caps) async {
    await ouvrirFeuilleLot(
      context,
      geste: geste,
      ids: _retenues.keys.toList(),
      capacites: caps,
      onRapport: _apresLot,
    );
  }

  void _apresLot(RapportLot rapport) {
    if (!mounted) return;
    _relire();
    setState(() {
      _retenues.clear();
      _enSelection = false;
      _retour = rapport.rejoue
          ? t.admin.candidatures.lot.feuille.rapport.rejoue
          : t.admin.candidatures.lot.feuille.rapport.reussies(
              n: rapport.reussies,
            );
    });
  }

  Widget _barreLot(CapacitesCandidatures caps, bool horsLigne) {
    final l = t.admin.candidatures.lot;
    final int n = _retenues.length;
    final bool tropNombreuses = n > plafondLotCandidatures;
    final List<GesteLot> gestes = gestesDeLot(_retenues.values);
    return BarreSelection.compacte(
      key: EnseignantsPage.cleBarreLot,
      titre: l.selectionnees(n: n),
      phrase: horsLigne
          ? t.admin.candidatures.selection.horsLigne
          : tropNombreuses
          ? l.plafond(n: plafondLotCandidatures)
          : gestes.isEmpty
          ? l.autresGestes
          : l.autresGestes,
      onRelacher: () => setState(_retenues.clear),
      operations: <Widget>[
        if (!horsLigne && !tropNombreuses)
          for (final GesteLot g in gestes)
            if (caps.geste(g.geste.capacite))
              ActionPrincipale(
                key: EnseignantsPage.cleOperationLot(g),
                libelle: libelleGesteLot(g),
                niveau: g == GesteLot.refuser
                    ? NiveauAction.destructive
                    : NiveauAction.secondaire,
                compacte: true,
                pleineLargeur: false,
                onPress: () => unawaited(_lancerLot(g, caps)),
              ),
      ],
    );
  }

  // --- Commandes ------------------------------------------------------------

  /// La cle choisie du menu « Phase » : `toutes`, `nouveaux`, ou la phase.
  String get _cleChoisie {
    if (_filtre.nouveau == true) return 'nouveaux';
    return _filtre.phase?.valeurSql ?? 'toutes';
  }

  FiltreEnseignants _filtreDeCle(String cle) {
    final FiltreEnseignants base = _filtre.avec(
      phase: () => null,
      nouveau: () => null,
      partis: false,
    );
    if (cle == 'toutes') return base;
    if (cle == 'nouveaux') return base.avec(nouveau: () => true);
    return base.avec(phase: () => PhaseEnseignant.depuisSql(cle));
  }

  Widget _menuPhase() {
    final l = t.admin.listeEnseignants;
    final CompteursEnseignants c = _compteurs;
    final int total = <PhaseEnseignant>[
      for (final PhaseEnseignant p in PhaseEnseignant.values)
        if (p != PhaseEnseignant.parti) p,
    ].fold<int>(0, (int s, PhaseEnseignant p) => s + c.de(p));
    final List<({String cle, String texteChoix})> choix =
        <({String cle, String texteChoix})>[
          (cle: 'toutes', texteChoix: '${l.toutesPhases} · $total'),
          if (c.nouveaux > 0)
            (cle: 'nouveaux', texteChoix: '${l.nouveaux} · ${c.nouveaux}'),
          for (final PhaseEnseignant p in PhaseEnseignant.values)
            if (c.de(p) > 0)
              (cle: p.valeurSql, texteChoix: '${libellePhase(p)} · ${c.de(p)}'),
        ];
    final String cle = _cleChoisie;
    final String texte = choix
        .firstWhere(
          (({String cle, String texteChoix}) x) => x.cle == cle,
          orElse: () => (cle: cle, texteChoix: l.phase),
        )
        .texteChoix;
    return MenuFiltre<String>(
      key: EnseignantsPage.clePhase,
      libelle: texte,
      valeur: cle,
      entrees: <EntreeFiltre<String>>[
        for (final ({String cle, String texteChoix}) x in choix)
          EntreeFiltre<String>(valeur: x.cle, libelle: x.texteChoix),
      ],
      onChoix: (String? v) {
        if (v == null) return;
        _filtrer(_filtreDeCle(v));
      },
    );
  }

  Widget _menuTri() {
    final r = t.admin.candidatures.tri;
    return MenuActions(
      key: EnseignantsPage.cleTri,
      libelle: r.titre,
      icone: AppIcons.triNeutre,
      actions: <EntreeAction>[
        EntreeAction(
          libelle: r.activite,
          onChoix: () => setState(() {
            _tri = TriEnseignants.activite;
            _page = 1;
          }),
        ),
        EntreeAction(
          libelle: r.reception,
          onChoix: () => setState(() {
            _tri = TriEnseignants.recente;
            _page = 1;
          }),
        ),
      ],
    );
  }

  Widget _boutonRecherche() => BoutonIcone(
    key: EnseignantsPage.cleLoupe,
    icone: AppIcons.recherche,
    libelle: t.recrutement.file.rechercher,
    selectionne: _rechercheVisible,
    onPress: () => setState(() {
      _rechercheOuverte = _recherche.text.isNotEmpty || !_rechercheOuverte;
    }),
  );

  Widget _ligneNombre(PageEnseignants page, {required bool selectionPossible}) {
    final l = t.admin.listeEnseignants;
    final r = t.admin.candidatures;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        Semantics(
          header: true,
          liveRegion: true,
          child: TexteSansCoupure(
            l.total(n: page.total),
            key: EnseignantsPage.cleTotal,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
        if (selectionPossible)
          LienFleche(
            key: EnseignantsPage.cleSelectionner,
            libelle: _enSelection
                ? r.selection.quitter
                : r.selection.selectionner,
            fleche: false,
            legende: true,
            alignerEnFin: true,
            onPress: _basculerSelection,
          ),
      ],
    );
  }

  // --- Liste ----------------------------------------------------------------

  Widget _liste(
    PageEnseignants page,
    CapacitesCandidatures caps,
    bool horsLigne,
  ) {
    final bool bureau =
        DataCollection.enTableau(context) &&
        MediaQuery.textScalerOf(context).scale(1) <= 1;
    final void Function(LigneCandidature)? ouvrir = widget.ouvrirCandidature;
    Widget? menu(LigneEnseignant l) => _menuLigne(l, caps, horsLigne, ouvrir);
    final void Function(LigneEnseignant)? toucher = _enSelection
        ? _basculerLigne
        : ouvrir == null
        ? null
        : (LigneEnseignant l) => ouvrir(l.dossier);
    if (bureau) {
      return DataCollection<LigneEnseignant>(
        colonnes: _colonnes(),
        lignes: page.lignes,
        defileAvecLaPage: true,
        cle: (LigneEnseignant l) => cleEnseignant(l.id),
        onSelectionner: toucher,
        estSelectionnee: _enSelection
            ? (LigneEnseignant l) => _retenues.containsKey(l.id)
            : null,
        actionsLigne: _enSelection
            ? null
            : (BuildContext _, LigneEnseignant l) =>
                  menu(l) ?? const SizedBox.shrink(),
      );
    }
    return PileCartes(
      children: <Widget>[
        for (final LigneEnseignant l in page.lignes)
          _CarteEnseignant(
            ligne: l,
            retenue: _retenues.containsKey(l.id),
            enSelection: _enSelection,
            onToucher: toucher == null ? null : () => toucher(l),
            menu: _enSelection ? null : menu(l),
          ),
      ],
    );
  }

  Widget? _menuLigne(
    LigneEnseignant l,
    CapacitesCandidatures caps,
    bool horsLigne,
    void Function(LigneCandidature)? ouvrir,
  ) {
    final List<EntreeAction> actions = <EntreeAction>[
      if (ouvrir != null)
        EntreeAction(
          libelle: t.admin.candidatures.liste.ouvrirDossier,
          icone: AppIcons.dossiers,
          onChoix: () => ouvrir(l.dossier),
        ),
      // Hors ligne : seul le dossier s'ouvre, aucun geste n'est propose.
      if (!horsLigne)
        for (final GesteCandidature g in gestesDuMenuEnseignant(l))
          EntreeAction(
            libelle: libelleGeste(g),
            icone: iconeDuGeste(g),
            destructif: g.destructif,
            onChoix: () => unawaited(_gesteDeLigne(l, g, caps)),
          ),
    ];
    if (actions.isEmpty) return null;
    return MenuActions(
      key: EnseignantsPage.cleMenu(l.id),
      points: true,
      objet: nomAffiche(l.dossier),
      actions: actions,
    );
  }

  List<ColonneDonnees<LigneEnseignant>> _colonnes() {
    final c = t.admin.listeEnseignants.colonnes;
    return <ColonneDonnees<LigneEnseignant>>[
      if (_enSelection)
        ColonneDonnees<LigneEnseignant>(
          titre: '',
          texte: (LigneEnseignant l) => '',
          flex: 1,
          rendu: (BuildContext _, LigneEnseignant l) =>
              _CaseEnseignant(retenue: _retenues.containsKey(l.id)),
        ),
      ColonneDonnees<LigneEnseignant>(
        titre: c.nom,
        texte: (LigneEnseignant l) => nomAffiche(l.dossier),
        role: RoleColonne.identifiante,
        flex: 5,
        rendu: (BuildContext _, LigneEnseignant l) => _CelluleNom(ligne: l),
      ),
      ColonneDonnees<LigneEnseignant>(
        titre: c.phase,
        texte: (LigneEnseignant l) => libellePhase(l.phase),
        flex: 3,
        rendu: (BuildContext _, LigneEnseignant l) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusPill(
            libelle: libellePhase(l.phase),
            ton: tonDePhase(l.phase),
          ),
        ),
      ),
      ColonneDonnees<LigneEnseignant>(
        titre: c.attend,
        texte: (LigneEnseignant l) => motAttend(l) ?? '',
        flex: 3,
      ),
      ColonneDonnees<LigneEnseignant>(
        titre: c.classes,
        texte: (LigneEnseignant l) => l.classes.nombre == 0
            ? ''
            : t.admin.listeEnseignants.classes(n: l.classes.nombre),
        flex: 2,
      ),
      ColonneDonnees<LigneEnseignant>(
        titre: c.seance,
        texte: (LigneEnseignant l) => l.prochaineSeance == null
            ? ''
            : dateCourteCandidature(l.prochaineSeance!.toLocal()),
        flex: 2,
        tabulaire: true,
      ),
      ColonneDonnees<LigneEnseignant>(
        titre: c.activite,
        texte: (LigneEnseignant l) => activiteAffichee(l.dossier),
        flex: 2,
        tabulaire: true,
      ),
    ];
  }

  Widget _contenu(
    PageEnseignants page,
    CapacitesCandidatures caps,
    bool horsLigne,
  ) {
    final l = t.admin.listeEnseignants;
    final r = t.admin.candidatures;
    if (page.lignes.isEmpty) {
      return EmptyState(
        key: const ValueKey<String>('enseignants-aucun-resultat'),
        message: l.aucunResultat,
        icone: AppIcons.rienAAfficher,
        libelleAction: t.admin.journal.effacerFiltres,
        onAction: _effacer,
      );
    }
    return Column(
      key: const ValueKey<String>('enseignants-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _liste(page, caps, horsLigne),
        Ecart.vLg,
        TexteSansCoupure(
          l.resume(
            debut: '${(page.page - 1) * page.taillePage + 1}',
            fin: '${(page.page - 1) * page.taillePage + page.lignes.length}',
            total: '${page.total}',
          ),
          key: const ValueKey<String>('enseignants-resume'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (page.pages > 1) ...<Widget>[
          Ecart.vSm,
          BarrePrecedentSuivant(
            key: const ValueKey<String>('enseignants-pagination'),
            position: t.commun.formats.pageSur(
              page: '${page.page}',
              total: '${page.pages}',
            ),
            positionSemantique: r.pagination.positionSemantique(
              page: '${page.page}',
              total: '${page.pages}',
            ),
            libellePrecedent: r.pagination.precedente,
            libelleSuivant: r.pagination.suivante,
            onPrecedent: page.page > 1
                ? () => _allerAPage(page.page - 1)
                : null,
            onSuivant: page.page < page.pages
                ? () => _allerAPage(page.page + 1)
                : null,
          ),
        ],
      ],
    );
  }

  Widget? _etatErreur(Object erreur, VoidCallback? reessayer, bool horsLigne) {
    final l = t.admin.listeEnseignants;
    if (erreur is CapaciteIndisponible) {
      return EtatSysteme(
        key: const ValueKey<String>('enseignants-indisponible'),
        nature: NatureEtat.indisponible,
        titre: t.commun.etats.branchementServeur,
        phrase: '',
        dependance: erreur.dependance,
      );
    }
    if (erreur is GenreLecteurInconnu) {
      return EtatSysteme(
        key: const ValueKey<String>('enseignants-genre-inconnu'),
        nature: NatureEtat.accesRefuse,
        titre: l.genreInconnuTitre,
        phrase: l.genreInconnu,
      );
    }
    if (erreur is PermissionInsuffisante) {
      return EtatSysteme(
        key: const ValueKey<String>('enseignants-acces-refuse'),
        nature: NatureEtat.accesRefuse,
        titre: l.accesRefuse,
        phrase: '',
      );
    }
    if (horsLigne) {
      return EtatSansDonnees(
        key: const ValueKey<String>('enseignants-sans-donnees'),
        quoi: l.sansDonnees,
        onAction: reessayer,
      );
    }
    return EtatSysteme(
      key: const ValueKey<String>('enseignants-erreur'),
      nature: NatureEtat.echecServeur,
      titre: l.lectureEchec,
      phrase: reessayer == null ? t.commun.etats.reessaisEpuises : '',
      onAction: reessayer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = t.admin.listeEnseignants;
    final AsyncValue<PageEnseignants> valeur = ref.watch(
      pageEnseignantsProvider(_requete),
    );
    final PageEnseignants? reference = valeur.asData?.value;
    if (reference != null) _compteurs = reference.compteurs;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final CapacitesCandidatures caps =
        ref.watch(capacitesCandidaturesProvider).asData?.value ??
        CapacitesCandidatures.aucune;
    final bool selectionPossible =
        caps.peutAgirEnLot &&
        (reference?.lignes.any(
              (LigneEnseignant x) => x.gestesGroupables.isNotEmpty,
            ) ??
            false);
    final int indexActif = ongletsPersonnes().indexWhere(
      (({String libelle, String chemin}) o) =>
          o.chemin == Routes.adminPersonnesEnseignants,
    );
    final bool commandes = reference != null || !_filtre.estVide;

    return PageShell(
      key: EnseignantsPage.clePage,
      actions: _enSelection && _retenues.isNotEmpty
          ? _barreLot(caps, horsLigne)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  label: l.titre,
                  child: SousNavigationDomaine(
                    onglets: ongletsPersonnes(),
                    indexActif: indexActif < 0 ? 0 : indexActif,
                  ),
                ),
              ),
              if (commandes) _boutonRecherche(),
              if (commandes) _menuTri(),
            ],
          ),
          Ecart.vSm,
          if (commandes && _rechercheVisible) ...<Widget>[
            Semantics(
              label: t.admin.candidatures.recherche,
              child: ChampRecherche(
                cleChamp: EnseignantsPage.cleRecherche,
                controleur: _recherche,
                autofocus: true,
                libelle: t.recrutement.file.rechercher,
                compact: true,
                aide: t.admin.candidatures.rechercheAide,
                onChange: _chercher,
                onValider: _chercherTout,
              ),
            ),
            Ecart.vSm,
          ],
          if (_ouverture != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: TexteSansCoupure(
                t.admin.candidatures.liste.ouverture(nom: _ouverture!),
                style: AppPalette.of(context).inkMuted.applyTo(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
          ],
          if (_echecLigne != null) ...<Widget>[
            LocalFeedback(message: _echecLigne!),
            Ecart.vSm,
          ],
          if (_retour != null) ...<Widget>[
            LocalFeedback(message: _retour),
            Ecart.vSm,
          ],
          if (commandes) ...<Widget>[
            _menuPhase(),
            Ecart.vMd,
            if (reference != null) ...<Widget>[
              _ligneNombre(reference, selectionPossible: selectionPossible),
              if (reference.compteurs.sansDossier > 0) ...<Widget>[
                Ecart.vSm,
                TexteSansCoupure(
                  l.sansDossier(n: reference.compteurs.sansDossier),
                  key: EnseignantsPage.cleSansDossier,
                  style: AppPalette.of(context).inkMuted.applyTo(
                    Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                  ),
                ),
              ],
              Ecart.vMd,
            ],
          ],
          BlocAsynchrone<PageEnseignants>(
            key: const ValueKey<String>('enseignants-bloc'),
            valeur: valeur,
            squelette: const Skeleton.liste(lignes: 4),
            onReessayer: _relire,
            estVide: (PageEnseignants p) => p.total == 0 && _filtre.estVide,
            vide: EmptyState(
              key: const ValueKey<String>('enseignants-vide'),
              message: l.vide,
              invitation: l.videDetail,
              registre: RegistreVide.subi,
              icone: AppIcons.dossiers,
            ),
            erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
                _etatErreur(erreur, reessayer, horsLigne),
            construire: (PageEnseignants page) =>
                _contenu(page, caps, horsLigne),
          ),
        ],
      ),
    );
  }
}

/// L'indicateur de case d'une ligne en selection : montre l'etat, ne se touche
/// pas (la ligne entiere est la cible).
class _CaseEnseignant extends StatelessWidget {
  const _CaseEnseignant({required this.retenue});

  final bool retenue;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ExcludeFocus(
      child: IgnorePointer(
        child: Checkbox(value: retenue, onChanged: (bool? _) {}),
      ),
    ),
  );
}

/// La cellule du nom : le nom, la reference, le badge « Nouveau », puis le
/// resume propre a la phase.
class _CelluleNom extends StatelessWidget {
  const _CelluleNom({required this.ligne});

  final LigneEnseignant ligne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final List<String> resume = resumeDeLigne(ligne, tableau: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TexteSansCoupure(
          nomAffiche(ligne.dossier),
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        TexteSansCoupure(
          referenceAffichee(ligne.dossier),
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        if (ligne.dossier.nouveau) ...<Widget>[
          Ecart.vSm,
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: BadgeNouveau(),
          ),
        ],
        for (final String m in resume)
          TexteSansCoupure(
            m,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
      ],
    );
  }
}

/// La carte d'un enseignant, sur telephone et tablette : le nom et la
/// reference, la phase, le badge « Nouveau », le resume propre a la phase.
class _CarteEnseignant extends StatelessWidget {
  const _CarteEnseignant({
    required this.ligne,
    required this.retenue,
    required this.enSelection,
    required this.onToucher,
    required this.menu,
  });

  final LigneEnseignant ligne;
  final bool retenue;
  final bool enSelection;
  final VoidCallback? onToucher;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final LigneCandidature d = ligne.dossier;
    final List<String> resume = resumeDeLigne(ligne);
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    final String semantique = enchainer(<String>[
      nomAffiche(d),
      referenceAffichee(d),
      libellePhase(ligne.phase),
      if (d.nouveau) t.commun.nouveau,
    ], ', ');
    final Widget carte = AppCard(
      key: cleEnseignant(ligne.id),
      onPress: onToucher,
      libelleSemantique: semantique,
      selectionnee: enSelection && retenue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (enSelection) ...<Widget>[
            _CaseEnseignant(retenue: retenue),
            Ecart.hSm,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TexteSansCoupure(
                  nomAffiche(d),
                  style: palette.inkStrong.applyTo(
                    textes.titleMedium ?? const TextStyle(),
                  ),
                ),
                Ecart.vXs,
                TexteSansCoupure(referenceAffichee(d), style: attenue),
                Ecart.vSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    StatusPill(
                      libelle: libellePhase(ligne.phase),
                      ton: tonDePhase(ligne.phase),
                    ),
                    if (d.nouveau) const BadgeNouveau(),
                  ],
                ),
                for (final String m in resume) ...<Widget>[
                  Ecart.vXs,
                  TexteSansCoupure(m, style: attenue),
                ],
              ],
            ),
          ),
          if (menu != null)
            const SizedBox(width: AppSpacing.xxl + AppSpacing.sm),
        ],
      ),
    );
    if (menu == null) return carte;
    // Superpose a la carte, hors de sa cible : le menu est un arret de
    // tabulation a part, jamais un bouton dans un bouton.
    return Stack(
      children: <Widget>[
        carte,
        PositionedDirectional(
          end: AppSpacing.sm,
          top: AppSpacing.sm,
          child: menu!,
        ),
      ],
    );
  }
}
