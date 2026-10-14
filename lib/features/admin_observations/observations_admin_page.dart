import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/admin_domaine.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_observation/guardian_session_visit.dart';
import '../../core/tc_observation/port_historique_observations.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';
import '../suivi_foyer/composants_historique.dart';
import '../suivi_foyer/filtres_historique.dart';
import 'annuaire_observations.dart';

/// L'historique des observations, cote administration
/// (`/admin/securite-audit/observations`, lot E sous-paquet 3, maquette V8 D3).
///
/// Onglet pair du Journal sous Securite et audit (`ongletsSecurite()`) : la
/// barre laterale admin reste celle des huit domaines (manifeste : la barre
/// « Vue d'ensemble / Personnes / Classes / Historique » de la maquette n'est
/// pas une spec). Composition de D3 : titre et sous-titre, recherche d'un
/// tuteur ou d'un eleve puis trois filtres (Classe, Periode, Statut), UN
/// tableau a filets, note de fuseau en pied.
///
/// **Lecture seule** : aucune action d'ecriture ni de suppression (observation
/// section 8). **Ce que la table ne dit pas, l'ecran ne le dit pas** : la
/// colonne « Fin » de la maquette (« Limite atteinte », « Depart volontaire »)
/// devient « Statut » (Terminee / Sortie non enregistree), le motif ecrit par
/// le serveur etant toujours « sortie volontaire » (DB-OBS-04). Une duree
/// n'est jamais recalculee : celle du serveur, ou « Non confirmee ».
///
/// Source : `guardian_session_visit` sous RLS admin (port K4). Tant que le
/// coordinateur n'a pas branche l'adaptateur du lot (demande E-9), le port de
/// production rend « indisponible » : l'ecran le dit et n'interroge rien
/// d'autre (ni l'annuaire des noms, ni les classes).
class ObservationsAdminPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const ObservationsAdminPage({super.key, this.horloge = DateTime.now});

  /// D'ou vient l'instant courant (injectable pour les tests).
  final DateTime Function() horloge;

  @override
  ConsumerState<ObservationsAdminPage> createState() =>
      _ObservationsAdminPageEtat();
}

/// Une visite prete a s'afficher : la visite du serveur et ses noms.
@immutable
class VisiteAdmin {
  /// Cree une ligne.
  const VisiteAdmin({
    required this.visite,
    required this.tuteur,
    required this.eleve,
    required this.classe,
  });

  /// La visite, telle que la table la rend.
  final GuardianSessionVisit visite;

  /// Le tuteur qui a observe.
  final String tuteur;

  /// L'eleve concerne.
  final String eleve;

  /// La classe de la seance.
  final String classe;

  /// Vrai tant que le serveur n'a pas ecrit de sortie.
  bool get ouverte => visite.enCours;

  /// L'entree, en heure de l'appareil.
  DateTime get entree => visite.enteredAtUtc.toLocal();
}

class _ObservationsAdminPageEtat extends ConsumerState<ObservationsAdminPage> {
  final List<GuardianSessionVisit> _visites = <GuardianSessionVisit>[];
  final Map<String, String> _noms = <String, String>{};
  final Map<String, String> _classes = <String, String>{};

  PersonneAnnuaire? _tuteur;
  PersonneAnnuaire? _eleve;
  String? _classeId;
  PeriodeHistorique _periode = PeriodeHistorique.toute;
  bool _ouvertes = false;

  String? _curseur;
  bool _chargement = true;
  bool _fin = false;
  Object? _erreur;

  /// Vrai des qu'une lecture a abouti : la recherche et les filtres n'ont de
  /// sens qu'apres (et l'annuaire n'est pas interroge avant).
  bool _disponible = false;

  /// La lecture en cours : une reponse d'un filtre abandonne est ignoree.
  int _generation = 0;

  bool get _indisponible => _erreur is CapaciteIndisponible;

  bool get _filtre =>
      _tuteur != null ||
      _eleve != null ||
      _classeId != null ||
      _periode != PeriodeHistorique.toute ||
      _ouvertes;

  FiltreObservationsAdmin _filtreCourant() {
    final DateTime maintenant = widget.horloge();
    final DateTime? debut = _periode.debut(maintenant);
    return FiltreObservationsAdmin(
      tuteurId: _tuteur?.id,
      eleveId: _eleve?.id,
      groupeId: _classeId,
      periode: debut == null
          ? null
          : DateTimeRange(
              start: debut,
              end: maintenant.add(const Duration(days: 1)),
            ),
      seulementOuvertes: _ouvertes,
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_recharger());
  }

  /// Relit depuis le debut : un changement de filtre ne melange jamais deux
  /// lectures dans la meme liste.
  Future<void> _recharger() async {
    setState(() {
      _visites.clear();
      _curseur = null;
      _fin = false;
      _erreur = null;
      _chargement = true;
    });
    await _lire(null);
  }

  Future<void> _suite() async {
    if (_chargement || _fin || _visites.isEmpty) {
      return;
    }
    setState(() => _chargement = true);
    await _lire(_curseur);
  }

  Future<void> _lire(String? curseur) async {
    final int generation = ++_generation;
    try {
      final ({List<ObservationsSeance> lignes, String? curseur}) page =
          await ref
              .read(portHistoriqueObservationsAdminProvider)
              .rechercher(_filtreCourant(), curseur: curseur);
      final List<GuardianSessionVisit> visites = <GuardianSessionVisit>[
        for (final ObservationsSeance groupe in page.lignes) ...groupe.visites,
      ];
      await _resoudreNoms(visites);
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _visites.addAll(visites);
        _curseur = page.curseur;
        _fin = page.curseur == null;
        _chargement = false;
        _disponible = true;
      });
    } on Object catch (erreur) {
      if (mounted && generation == _generation) {
        setState(() {
          _erreur = erreur;
          _chargement = false;
        });
      }
    }
  }

  /// Complete les noms manquants. Un annuaire illisible laisse « Nom non
  /// disponible » : les visites restent lisibles, rien n'est invente.
  Future<void> _resoudreNoms(List<GuardianSessionVisit> visites) async {
    final AnnuaireObservations annuaire = ref.read(
      annuaireObservationsProvider,
    );
    final Set<String> personnes = <String>{
      for (final GuardianSessionVisit v in visites) ...<String>[
        v.observateurProfilId,
        ?v.enfantConcerneId,
      ],
    }.difference(_noms.keys.toSet());
    final Set<String> classes = <String>{
      for (final GuardianSessionVisit v in visites) v.groupeId,
    }.difference(_classes.keys.toSet());
    try {
      _noms.addAll(await annuaire.noms(personnes));
    } on Object {
      // Nom non disponible.
    }
    try {
      _classes.addAll(await annuaire.classes(classes));
    } on Object {
      // Classe non disponible.
    }
  }

  void _poser(VoidCallback changement) {
    setState(changement);
    unawaited(_recharger());
  }

  void _toutEffacer() => _poser(() {
    _tuteur = null;
    _eleve = null;
    _classeId = null;
    _periode = PeriodeHistorique.toute;
    _ouvertes = false;
  });

  void _choisirPersonne(PersonneAnnuaire p) => _poser(() {
    _noms[p.id] = p.nom;
    if (p.estTuteur) {
      _tuteur = p;
    } else {
      _eleve = p;
    }
  });

  VisiteAdmin _ligne(GuardianSessionVisit v) => VisiteAdmin(
    visite: v,
    tuteur: _noms[v.observateurProfilId] ?? t.admin.observations.nomInconnu,
    eleve: _noms[v.enfantConcerneId] ?? t.admin.observations.nomInconnu,
    classe: _classes[v.groupeId] ?? t.admin.observations.classeInconnue,
  );

  @override
  Widget build(BuildContext context) {
    final List<({String libelle, String chemin})> onglets = ongletsSecurite();
    return PageShell(
      titre: t.admin.observations.titrePage,
      sousTitre: t.admin.observations.sousTitre,
      // Le tableau defile lui-meme : l'en-tete de colonnes et les filtres
      // restent en place pendant que les visites defilent.
      defilante: false,
      entete: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SousNavigationDomaine(onglets: onglets, indexActif: 1),
          if (_disponible) ...<Widget>[
            Ecart.vLg,
            _BarreRecherche(
              tuteur: _tuteur,
              eleve: _eleve,
              classeId: _classeId,
              periode: _periode,
              ouvertes: _ouvertes,
              onPersonne: _choisirPersonne,
              onRetirerTuteur: () => _poser(() => _tuteur = null),
              onRetirerEleve: () => _poser(() => _eleve = null),
              onClasse: (String? c) => _poser(() => _classeId = c),
              onPeriode: (PeriodeHistorique p) => _poser(() => _periode = p),
              onOuvertes: (bool o) => _poser(() => _ouvertes = o),
            ),
          ],
        ],
      ),
      child: _corps(context),
    );
  }

  Widget _corps(BuildContext context) {
    if (_indisponible) {
      return _Defilant(
        child: EtatSysteme(
          nature: NatureEtat.indisponible,
          titre: t.admin.observations.indisponibleTitre,
          phrase: t.admin.observations.indisponiblePhrase,
          dependance: (_erreur! as CapaciteIndisponible).dependance,
        ),
      );
    }
    if (_erreur != null && _visites.isEmpty) {
      return _Defilant(
        child: EtatSysteme(
          nature: NatureEtat.echecServeur,
          onAction: () => unawaited(_recharger()),
        ),
      );
    }
    if (_visites.isEmpty && _chargement) {
      return const _Defilant(child: Skeleton.liste(lignes: 5));
    }
    if (_visites.isEmpty) {
      return _Defilant(
        child: _filtre
            ? EtatSysteme(
                nature: NatureEtat.aucunResultat,
                titre: t.admin.observations.videFiltreTitre,
                phrase: t.admin.observations.videFiltrePhrase,
                libelleAction: t.admin.observations.effacerFiltres,
                onAction: _toutEffacer,
              )
            : EtatSysteme(
                nature: NatureEtat.aucunResultat,
                titre: t.admin.observations.videTitre,
                phrase: t.admin.observations.videPhrase,
              ),
      );
    }

    final List<VisiteAdmin> lignes = <VisiteAdmin>[
      for (final GuardianSessionVisit v in _visites) _ligne(v),
    ];
    final Widget pied = _PiedDePage(
      chargement: _chargement,
      fin: _fin,
      erreur: _erreur,
      onSuite: _suite,
      decalage: decalageUtc(widget.horloge()),
    );
    // Tableau dense au bureau ; ailleurs UNE carte a filets (decision du
    // directeur : jamais un rectangle par ligne).
    if (AppGabarit.de(context) == Gabarit.desktop) {
      return DataCollection<VisiteAdmin>(
        lignes: lignes,
        cle: (VisiteAdmin l) => ValueKey<String>('visite-${l.visite.id}'),
        colonnes: colonnesObservationsAdmin(),
        piedDePage: pied,
      );
    }
    return ListView(
      children: <Widget>[
        CarteLignes(
          lignes: <Widget>[
            for (final VisiteAdmin l in lignes)
              _LigneVisite(key: ValueKey<String>('visite-${l.visite.id}'), l),
          ],
        ),
        Ecart.vXl,
        pied,
        Ecart.vSection,
      ],
    );
  }
}

/// Un etat qui defile si la hauteur manque (page non defilante).
class _Defilant extends StatelessWidget {
  const _Defilant({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(child: child);
}

/// La recherche d'un tuteur ou d'un eleve, puis Classe, Periode, Statut
/// (maquette D3 : recherche a gauche, trois filtres a droite ; sous 600 de
/// large, les filtres passent sous la recherche). Les personnes retenues
/// rejoignent les filtres sur la meme rangee (FILTRES-1b).
class _BarreRecherche extends ConsumerWidget {
  const _BarreRecherche({
    required this.tuteur,
    required this.eleve,
    required this.classeId,
    required this.periode,
    required this.ouvertes,
    required this.onPersonne,
    required this.onRetirerTuteur,
    required this.onRetirerEleve,
    required this.onClasse,
    required this.onPeriode,
    required this.onOuvertes,
  });

  final PersonneAnnuaire? tuteur;
  final PersonneAnnuaire? eleve;
  final String? classeId;
  final PeriodeHistorique periode;
  final bool ouvertes;
  final ValueChanged<PersonneAnnuaire> onPersonne;
  final VoidCallback onRetirerTuteur;
  final VoidCallback onRetirerEleve;
  final ValueChanged<String?> onClasse;
  final ValueChanged<PeriodeHistorique> onPeriode;
  final ValueChanged<bool> onOuvertes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ClasseAnnuaire>> classes = ref.watch(
      classesEnCoursAdminProvider,
    );
    final List<ClasseAnnuaire> liste = classes.hasValue && !classes.hasError
        ? classes.requireValue
        : const <ClasseAnnuaire>[];

    final Widget recherche = RechercheObservations(onChoix: onPersonne);
    final List<Widget> filtres = <Widget>[
      if (liste.isNotEmpty || classeId != null)
        MenuFiltre<String>(
          libelle: t.admin.observations.classe,
          valeur: classeId,
          entrees: <EntreeFiltre<String>>[
            EntreeFiltre<String>(
              valeur: null,
              libelle: t.admin.observations.toutesClasses,
            ),
            for (final ClasseAnnuaire c in liste)
              EntreeFiltre<String>(valeur: c.id, libelle: c.libelle),
          ],
          onChoix: onClasse,
        ),
      MenuFiltre<PeriodeHistorique>(
        libelle: t.admin.observations.periode,
        valeur: periode == PeriodeHistorique.toute ? null : periode,
        entrees: <EntreeFiltre<PeriodeHistorique>>[
          for (final PeriodeHistorique p in PeriodeHistorique.values)
            EntreeFiltre<PeriodeHistorique>(
              valeur: p == PeriodeHistorique.toute ? null : p,
              libelle: p.libelle,
            ),
        ],
        onChoix: (PeriodeHistorique? p) =>
            onPeriode(p ?? PeriodeHistorique.toute),
      ),
      MenuFiltre<bool>(
        libelle: t.admin.observations.statut,
        valeur: ouvertes ? true : null,
        entrees: <EntreeFiltre<bool>>[
          EntreeFiltre<bool>(
            valeur: null,
            libelle: t.admin.observations.tousStatuts,
          ),
          EntreeFiltre<bool>(
            valeur: true,
            libelle: t.admin.observations.ouverte,
          ),
        ],
        onChoix: (bool? o) => onOuvertes(o ?? false),
      ),
    ];
    final List<Widget> personnes = <Widget>[
      if (tuteur case final PersonneAnnuaire p)
        _PastillePersonne(
          libelle: t.admin.observations.filtreTuteur(nom: p.nom),
          onRetirer: onRetirerTuteur,
        ),
      if (eleve case final PersonneAnnuaire p)
        _PastillePersonne(
          libelle: t.admin.observations.filtreEleve(nom: p.nom),
          onRetirer: onRetirerEleve,
        ),
    ];

    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints contraintes) {
        final bool enLigne = contraintes.maxWidth >= AppPage.largeurDialogue;
        // FILTRES-1 et 1b : les menus et les personnes retenues sur UNE
        // rangee qui defile, jamais une seconde rangee de puces.
        final Widget rangee = RangeeFiltres(
          filtres: <Widget>[...filtres, ...personnes],
        );
        if (!enLigne) {
          // Sous 600, la rangee sous la recherche.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[recherche, Ecart.vMd, rangee],
          );
        }
        // Au-dela, la rangee a cote de la recherche (maquette D3) : elle
        // prend la largeur de ses puces, dans la limite de ce que la
        // recherche laisse ([_partRecherche] de la largeur au moins), et
        // defile au-dela.
        return Row(
          children: <Widget>[
            Expanded(child: recherche),
            Ecart.hMd,
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    contraintes.maxWidth * (1 - _partRecherche) - AppSpacing.md,
              ),
              child: rangee,
            ),
          ],
        );
      },
    );
  }
}

/// La part de la largeur que la recherche garde au moins, a cote de la
/// rangee de filtres (a partir de 600) : un champ plus etroit ne laisse plus
/// lire ce qu'on tape.
const double _partRecherche = 1 / 3;

/// Une personne retenue par la recherche : la toucher la retire.
///
/// Elle se declare [PuceFiltre] retenue : la rangee l'amene dans la vue des
/// qu'elle apparait au bout des menus, sinon la seule facon de retirer ce
/// filtre resterait cachee hors de la rangee (FILTRES-1b, reprise).
class _PastillePersonne extends StatelessWidget implements PuceFiltre {
  const _PastillePersonne({required this.libelle, required this.onRetirer});

  final String libelle;
  final VoidCallback onRetirer;

  @override
  bool get retenue => true;

  @override
  Widget build(BuildContext context) => Semantics(
    label: t.admin.observations.retirerFiltre(filtre: libelle),
    excludeSemantics: true,
    child: FilterPill(libelle: libelle, retenue: true, onPress: onRetirer),
  );
}

/// Le champ « Rechercher un tuteur ou un eleve » : deux lettres au moins,
/// puis les personnes proposees par l'annuaire ; en choisir une pose le
/// filtre Tuteur ou Eleve.
class RechercheObservations extends ConsumerWidget {
  /// Cree le champ.
  const RechercheObservations({required this.onChoix, super.key});

  /// La personne choisie.
  final ValueChanged<PersonneAnnuaire> onChoix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Autocomplete<PersonneAnnuaire>(
      displayStringForOption: (PersonneAnnuaire p) => p.nom,
      optionsBuilder: (TextEditingValue saisie) async {
        if (motifRecherche(saisie.text).length < 2) {
          return const <PersonneAnnuaire>[];
        }
        try {
          return await ref
              .read(annuaireObservationsProvider)
              .chercher(saisie.text);
        } on Object {
          return const <PersonneAnnuaire>[];
        }
      },
      onSelected: onChoix,
      fieldViewBuilder:
          (
            BuildContext contexte,
            TextEditingController controleur,
            FocusNode focus,
            VoidCallback _,
          ) => TextField(
            controller: controleur,
            focusNode: focus,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              // COUPE-MOTS-FOND-1 : l'aide passe a la ligne entre ses mots, et
              // un mot trop large se reduit, borne : jamais tronquee ni
              // coupee (320 px texte x2, Interface guidee).
              hint: texteAideSansCoupure(
                contexte,
                t.admin.observations.recherche,
              ),
              prefixIcon: Icon(AppIcons.recherche.repos),
            ),
          ),
      optionsViewBuilder:
          (
            BuildContext _,
            AutocompleteOnSelected<PersonneAnnuaire> choisir,
            Iterable<PersonneAnnuaire> options,
          ) => Align(
            alignment: AlignmentDirectional.topStart,
            child: DecoratedBox(
              decoration: palette.surfaceRaised
                  .decoration(
                    borderRadius: AppRadius.arrondiSm,
                    side: palette.borderHairline.asBorderSide(),
                  )
                  .copyWith(boxShadow: AppElevation.niveau2(palette.ombre)),
              child: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: AppPage.largeurDialogue / 2,
                    maxWidth: AppPage.largeurDialogue,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      for (final PersonneAnnuaire p in options)
                        Pressable(
                          key: ValueKey<String>('personne-${p.id}'),
                          onPress: () => choisir(p),
                          libelleSemantique: '${p.nom}, ${_role(p)}',
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(p.nom, style: textes.bodyMedium),
                                Text(
                                  _role(p),
                                  style: palette.inkMuted.applyTo(
                                    textes.bodySmall ?? const TextStyle(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

String _role(PersonneAnnuaire p) => p.estTuteur
    ? t.admin.observations.roleTuteur
    : t.admin.observations.roleEleve;

/// Les classes en cours, pour le filtre « Classe » (lu apres une premiere
/// page de visites seulement).
final FutureProvider<List<ClasseAnnuaire>> classesEnCoursAdminProvider =
    FutureProvider<List<ClasseAnnuaire>>(
      (Ref ref) => ref.watch(annuaireObservationsProvider).classesEnCours(),
    );

/// « 23/09/2026 ».
String dateNumerique(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

/// « 18:12:00 » : les secondes des deux cotes (la maquette D4 les melangeait).
String heureSecondes(DateTime d) =>
    '${heureMinute(d)}:${d.second.toString().padLeft(2, '0')}';

/// La sortie d'une visite, ou « Non enregistree ».
String sortieDe(VisiteAdmin l) => switch (l.visite.leftAtUtc) {
  final DateTime s => heureSecondes(s.toLocal()),
  null => t.admin.observations.sortieAbsente,
};

/// La duree ecrite par le serveur, ou « Non confirmee ».
String dureeDe(VisiteAdmin l) =>
    switch ((l.visite.leftAtUtc, l.visite.durationSeconds)) {
      (DateTime _, final Duration d) => dureeLisible(d),
      _ => t.admin.observations.dureeNonConfirmee,
    };

/// Le libelle de statut d'une visite.
String statutVisite(VisiteAdmin l) =>
    l.ouverte ? t.admin.observations.ouverte : t.admin.observations.terminee;

/// Ce que le lecteur d'ecran dit d'une visite.
String semantiqueDe(VisiteAdmin l) => t.admin.observations.ligne(
  rang: l.visite.visitNumber,
  date: dateNumerique(l.entree),
  tuteur: l.tuteur,
  eleve: l.eleve,
  classe: l.classe,
  entree: heureSecondes(l.entree),
  sortie: sortieDe(l),
  duree: dureeDe(l),
  statut: statutVisite(l),
);

/// Les huit colonnes de la maquette D3, « Fin » devenue « Statut ».
List<ColonneDonnees<VisiteAdmin>> colonnesObservationsAdmin() =>
    <ColonneDonnees<VisiteAdmin>>[
      ColonneDonnees<VisiteAdmin>(
        titre: t.admin.observations.colonneDate,
        texte: (VisiteAdmin l) => dateNumerique(l.entree),
        tabulaire: true,
        flex: 3,
      ),
      ColonneDonnees<VisiteAdmin>(
        titre: t.admin.observations.colonneTuteur,
        texte: (VisiteAdmin l) => l.tuteur,
        role: RoleColonne.identifiante,
        flex: 4,
      ),
      ColonneDonnees<VisiteAdmin>(
        titre: t.admin.observations.colonneEleve,
        texte: (VisiteAdmin l) => l.eleve,
        flex: 3,
      ),
      ColonneDonnees<VisiteAdmin>(
        titre: t.admin.observations.colonneClasse,
        texte: (VisiteAdmin l) => l.classe,
        flex: 3,
      ),
      ColonneDonnees<VisiteAdmin>(
        titre: t.admin.observations.colonneEntree,
        texte: (VisiteAdmin l) => heureSecondes(l.entree),
        tabulaire: true,
        flex: 2,
      ),
      ColonneDonnees<VisiteAdmin>(
        titre: t.admin.observations.colonneSortie,
        texte: sortieDe,
        tabulaire: true,
        flex: 3,
      ),
      ColonneDonnees<VisiteAdmin>(
        titre: t.admin.observations.colonneDuree,
        texte: dureeDe,
        tabulaire: true,
        flex: 3,
      ),
      ColonneDonnees<VisiteAdmin>(
        titre: t.admin.observations.colonneStatut,
        texte: statutVisite,
        flex: 4,
        rendu: (BuildContext _, VisiteAdmin l) => Semantics(
          label: '${t.admin.observations.colonneStatut} : ${statutVisite(l)}',
          excludeSemantics: true,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatusPill(
              libelle: statutVisite(l),
              ton: l.ouverte ? TonEtat.neutre : TonEtat.succes,
            ),
          ),
        ),
      ),
    ];

/// Une visite sur telephone et tablette : date et plage a gauche, filet,
/// tuteur puis eleve et classe, pastille. Aucune cible : il n'existe pas de
/// detail admin d'une visite (aucun chevron qui ne menerait nulle part).
class _LigneVisite extends StatelessWidget {
  const _LigneVisite(this.ligne, {super.key});

  final VisiteAdmin ligne;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle fort = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final TextStyle doux = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    // Sans sortie, l'heure d'entree seule : la pastille dit deja « Sortie non
    // enregistree », la ligne ne le repete pas.
    final String plage = switch (ligne.visite.leftAtUtc) {
      final DateTime s => t.admin.observations.plage(
        entree: heureMinute(ligne.entree),
        sortie: heureMinute(s.toLocal()),
      ),
      null => heureMinute(ligne.entree),
    };
    return Semantics(
      label: semantiqueDe(ligne),
      excludeSemantics: true,
      child: ColoredBox(
        color: palette.surfaceRaised.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: LayoutBuilder(
            builder: (BuildContext _, BoxConstraints contraintes) {
              // Un nom compose (« An-Nour ») ne passe pas a la ligne apres
              // son trait d'union : trait d'union insecable (U+2011), comme
              // les cartes de classe (BENTO-3).
              final String tuteur = ligne.tuteur.replaceAll('-', '\u2011');
              final String eleveClasse = '${ligne.eleve} · ${ligne.classe}'
                  .replaceAll('-', '\u2011');
              final String duree = ligne.ouverte
                  ? t.historique.observations.dureeNonConfirmee
                  : dureeDe(ligne);
              final Widget quand = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    dateNumerique(ligne.entree),
                    style: AppTypography.tabulaire(fort),
                  ),
                  Ecart.vXs,
                  Text(plage, style: AppTypography.tabulaire(doux)),
                  Ecart.vXs,
                  Text(duree, style: doux),
                ],
              );
              final Widget qui = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(tuteur, style: fort),
                  Ecart.vXs,
                  Text(eleveClasse, style: doux),
                  Ecart.vSm,
                  StatusPill(
                    libelle: statutVisite(ligne),
                    ton: ligne.ouverte ? TonEtat.neutre : TonEtat.succes,
                  ),
                ],
              );
              final double gauche = contraintes.maxWidth * _partQuand;
              final double droite =
                  contraintes.maxWidth - gauche - AppSpacing.xxl;
              final TextScaler echelle = MediaQuery.textScalerOf(context);
              // FILTRES-1b : un mot qui ne tient pas dans sa colonne (la
              // date a 320 px texte x2, « Fatoumata ») serait coupe au
              // milieu. La ligne empile alors la date au-dessus des noms, sur
              // toute la largeur.
              final bool cote =
                  _motLePlusLarge(<(String, TextStyle)>[
                        (
                          dateNumerique(ligne.entree),
                          AppTypography.tabulaire(fort),
                        ),
                        (plage, AppTypography.tabulaire(doux)),
                        (duree, doux),
                      ], echelle) <=
                      gauche &&
                  _motLePlusLarge(<(String, TextStyle)>[
                        (tuteur, fort),
                        (eleveClasse, doux),
                      ], echelle) <=
                      droite;
              if (!cote) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    quand,
                    Divider(
                      height: AppSpacing.lg,
                      thickness: palette.contourCarte.asBorderSide().width,
                      color: palette.contourCarte.asBorderSide().color,
                    ),
                    qui,
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  SizedBox(width: gauche, child: quand),
                  SizedBox(
                    height: AppSpacing.section,
                    child: VerticalDivider(
                      width: AppSpacing.xxl,
                      thickness: palette.contourCarte.asBorderSide().width,
                      color: palette.contourCarte.asBorderSide().color,
                    ),
                  ),
                  Expanded(child: qui),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// La part de la ligne que prend la colonne date, plage et duree.
const double _partQuand = 0.34;

/// La largeur du plus long mot des textes donnes, a l'echelle du texte : ce
/// qu'une colonne doit offrir pour qu'aucun mot n'y soit coupe.
double _motLePlusLarge(List<(String, TextStyle)> textes, TextScaler echelle) {
  double largeur = 0;
  for (final (String texte, TextStyle style) in textes) {
    for (final String mot in texte.split(RegExp('[ \t\n]+'))) {
      if (mot.isEmpty) continue;
      final TextPainter mesure = TextPainter(
        text: TextSpan(text: mot, style: style),
        textDirection: TextDirection.ltr,
        textScaler: echelle,
        maxLines: 1,
      )..layout();
      if (mesure.width > largeur) largeur = mesure.width;
      mesure.dispose();
    }
  }
  return largeur;
}

/// Ce qui suit la derniere visite : la suite, ou la fin ; puis le fuseau.
class _PiedDePage extends StatelessWidget {
  const _PiedDePage({
    required this.chargement,
    required this.fin,
    required this.erreur,
    required this.onSuite,
    required this.decalage,
  });

  final bool chargement;
  final bool fin;
  final Object? erreur;
  final Future<void> Function() onSuite;
  final String decalage;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle doux = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (fin)
            Text(t.admin.observations.fin, style: doux)
          else ...<Widget>[
            if (erreur != null) ...<Widget>[
              Text(t.admin.observations.erreurSuite, style: doux),
              Ecart.vSm,
            ],
            ActionPrincipale(
              libelle: t.admin.observations.chargerSuite,
              niveau: NiveauAction.secondaire,
              enCours: chargement,
              pleineLargeur: false,
              onPress: chargement ? null : () => unawaited(onSuite()),
            ),
          ],
          Ecart.vMd,
          Text(t.admin.observations.fuseau(decalage: decalage), style: doux),
          Ecart.vLg,
        ],
      ),
    );
  }
}
