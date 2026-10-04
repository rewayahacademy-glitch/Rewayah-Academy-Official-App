// Les Politiques commerciales, cote direction (`/admin/finance/politiques`,
// FI-11b ; guide Finance V4 §1, §5.7, §8 LOT F8 ; maquette 10 ; K-57, K-58).
//
// Une politique est versionnee : l'en-tete dit le statut (brouillon ou
// publiee) et la date d'effet. Les sections du guide (Tarifs, Essai, Remises,
// Enseignants, Groupes, Paiement, Pilotage) LISENT les valeurs du port ; dans
// un brouillon, les valeurs reglables deviennent des champs, prerempli avec
// la valeur du brouillon (K-57 : deduit), et la valeur de la version active
// s'affiche sous un champ des qu'elle differe.
//
// Les invariants (idempotence, separation des soldes, historique en ajout
// seul, confirmation avant credit, pas de double debit, acces par periode
// financee) ne sont JAMAIS des champs (FI22) : une carte « Regles fixes » les
// dit en texte. Le paiement web seul au lancement se lit dans Paiement, sans
// champ non plus.
//
// Une saisie est refusee sur sa forme (un nombre entier) puis sur sa
// coherence (capacite d'au moins 1, tarif non nul, plafond pas sous la base,
// maximum pas sous l'objectif, minimum pas au-dessus de la plus petite
// classe, remise pas au-dessus du tarif) : une phrase par refus, sous le
// champ (LOT F8, erreur de champ). Une comparaison, jamais un calcul.
//
// « Publier » appelle le port, qui rend `CapaciteIndisponible` en production
// comme en demonstration : l'ecran le dit honnetement, rien n'est ecrit.
// Aucun calcul de prix ni de remise ici (FI6) : seule la conversion d'une
// saisie en unites entieres vers les unites mineures (`montantDepuisUnites`).
//
// FI-11c : l'historique des versions (lecture seule, la version active
// marquee) et, sous un brouillon, l'« Apercu avant publication » : un foyer
// de 1 a 5 enfants payants et le taux horaire d'une classe. Les montants de
// l'apercu sont ARRETES par le port (`apercuFamille`, `apercuEnseignant`) a
// partir du brouillon a l'ecran, relus a chaque saisie valide ; jamais
// calcules ici (garde de source dans le test).

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_politiques_commerciales.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/finance/politique_commerciale.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/ligne_finance.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'vue_globale_finance.dart' show pourMilleEnTexte;

/// La version active, le brouillon en cours s'il y en a un, et l'historique
/// des versions (le plus recent d'abord).
typedef PolitiquesLues = ({
  PolitiqueCommerciale active,
  PolitiqueCommerciale? brouillon,
  List<PolitiqueCommerciale> versions,
});

/// Lit [port] : la version active, puis le plus recent brouillon de
/// l'historique (le premier rendu, la liste etant la plus recente d'abord).
Future<PolitiquesLues> lirePolitiques(PortPolitiquesCommerciales port) async {
  final PolitiqueCommerciale active = await port.active();
  final List<PolitiqueCommerciale> versions = await port.versions();
  PolitiqueCommerciale? brouillon;
  for (final PolitiqueCommerciale v in versions) {
    if (v.statut == StatutPolitique.brouillon) {
      brouillon = v;
      break;
    }
  }
  return (active: active, brouillon: brouillon, versions: versions);
}

/// Les politiques lues sur le port. `retry` nul : pas de retentative
/// silencieuse derriere « Reessayer » (meme reglage que la Vue globale).
final FutureProvider<PolitiquesLues> politiquesCommercialesProvider =
    FutureProvider<PolitiquesLues>(
      (Ref ref) =>
          lirePolitiques(ref.watch(portPolitiquesCommercialesProvider)),
      retry: (int retryCount, Object error) => null,
    );

/// L'onglet Politiques commerciales : chargement, contenu, sans brouillon
/// (vide), erreur, hors ligne, et « Pas encore disponible » tant que le port
/// rend `CapaciteIndisponible` (production, FI-BR-01).
class PolitiquesCommercialesBloc extends ConsumerWidget {
  /// Cree le bloc.
  const PolitiquesCommercialesBloc({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PolitiquesLues> lues = ref.watch(
      politiquesCommercialesProvider,
    );
    void relire() => ref.invalidate(politiquesCommercialesProvider);
    final Object? erreur = lues.hasError ? lues.error : null;
    final bool echecHorsLigne =
        erreur != null &&
        erreur is! CapaciteIndisponible &&
        (ref.watch(horsLigneProvider).value ?? false);
    if (echecHorsLigne) {
      return EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire);
    }
    return BlocAsynchrone<PolitiquesLues>(
      valeur: lues,
      squelette: const _Squelette(),
      onReessayer: relire,
      construire: (PolitiquesLues l) => PolitiquesCommercialesContenu(
        // Un nouveau brouillon lu repart de ses propres valeurs.
        key: ValueKey<String>(l.brouillon?.version ?? l.active.version),
        active: l.active,
        brouillon: l.brouillon,
        versions: l.versions,
      ),
    );
  }
}

/// La nature d'une valeur de politique, qui dit comment la lire et la saisir.
enum _Nature {
  montant,
  montantHoraire,
  remise,
  eleves,
  seances,
  groupes,
  jours,
}

/// Un parametre de la politique : son libelle, sa consequence (K-58), sa
/// valeur dans le brouillon (ou la version lue) et dans la version active.
class _Champ {
  const _Champ({
    required this.id,
    required this.libelle,
    required this.consequence,
    required this.nature,
    required this.lue,
    required this.active,
    this.devise,
    this.facultatif = false,
  });

  final String id;
  final String libelle;
  final String consequence;
  final _Nature nature;

  /// La valeur rendue par le port pour la version affichee : `Montant` ou
  /// `int`, `null` quand la version ne la fixe pas.
  final Object? lue;

  /// La valeur de la version active, pour la comparaison.
  final Object? active;

  /// La devise d'un montant que la version ne fixe pas encore (aide
  /// Internet) : celle des tarifs.
  final String? devise;

  /// Vrai quand le champ peut rester vide : la valeur n'est alors pas fixee
  /// (aide Internet, montant configurable, guide §1.4).
  final bool facultatif;

  bool get estMontant =>
      nature == _Nature.montant ||
      nature == _Nature.montantHoraire ||
      nature == _Nature.remise;

  /// Le texte prerempli dans le champ, en unites entieres (une remise en
  /// valeur absolue), vide pour un champ facultatif pas encore fixe, ou
  /// `null` quand une saisie entiere ne represente pas la valeur : le champ
  /// reste alors en lecture.
  String? get saisieInitiale {
    final Object? v = lue;
    if (v is int) return '$v';
    if (v is Montant) {
      final int? unites = unitesEntieresDe(v);
      if (unites == null) return null;
      return '${nature == _Nature.remise ? -unites : unites}';
    }
    if (v == null && facultatif && devise != null) return '';
    return null;
  }

  /// La devise du champ quand c'est un montant.
  String? get deviseMontant => switch (lue) {
    final Montant m => m.devise,
    _ => devise,
  };

  /// La valeur d'une saisie [unites] (deja validee), dans la forme du port.
  Object depuisSaisie(int unites) {
    final String? d = deviseMontant;
    if (estMontant && d != null) {
      return montantDepuisUnites(
        nature == _Nature.remise ? -unites : unites,
        d,
      );
    }
    return unites;
  }
}

/// Le contenu de l'onglet, sans lecture : en-tete de version, sections,
/// regles fixes, puis la publication quand un brouillon est ouvert.
class PolitiquesCommercialesContenu extends ConsumerStatefulWidget {
  /// Cree le contenu.
  const PolitiquesCommercialesContenu({
    required this.active,
    required this.brouillon,
    super.key,
    this.versions = const <PolitiqueCommerciale>[],
  });

  /// L'historique des versions rendu par le port, le plus recent d'abord.
  final List<PolitiqueCommerciale> versions;

  /// La version active (publiee).
  final PolitiqueCommerciale active;

  /// Le brouillon en cours, ou `null` (lecture seule de la version active).
  final PolitiqueCommerciale? brouillon;

  /// La cle de l'en-tete de version.
  static const Key enteteKey = ValueKey<String>('fi-pol-entete');

  /// La cle de la carte des regles fixes.
  static const Key invariantsKey = ValueKey<String>('fi-pol-invariants');

  /// La cle du bandeau de publication.
  static const Key publicationKey = ValueKey<String>('fi-pol-publication');

  /// La cle du champ [id] (par exemple `tarifEnfant`, `remise-3`).
  static Key champKey(String id) => ValueKey<String>('fi-pol-champ-$id');

  /// La cle de la valeur active rappelee sous le champ [id].
  static Key comparaisonKey(String id) => ValueKey<String>('fi-pol-cmp-$id');

  /// La cle de la carte d'historique des versions.
  static const Key historiqueKey = ValueKey<String>('fi-pol-historique');

  /// La cle de la ligne d'historique de la version [version].
  static Key historiqueLigneKey(String version) =>
      ValueKey<String>('fi-pol-histo-$version');

  /// La cle de la carte d'apercu du foyer.
  static const Key apercuFamilleKey = ValueKey<String>('fi-pol-apercu-famille');

  /// La cle de la carte d'apercu de l'enseignant.
  static const Key apercuEnseignantKey = ValueKey<String>(
    'fi-pol-apercu-enseignant',
  );

  /// La cle de la ligne de l'enfant de rang [rang] dans l'apercu.
  static Key apercuEnfantKey(int rang) =>
      ValueKey<String>('fi-pol-apercu-enfant-$rang');

  /// La cle du total du foyer dans l'apercu.
  static const Key apercuTotalKey = ValueKey<String>('fi-pol-apercu-total');

  /// La cle du taux horaire effectif dans l'apercu.
  static const Key apercuTauxKey = ValueKey<String>('fi-pol-apercu-taux');

  @override
  ConsumerState<PolitiquesCommercialesContenu> createState() =>
      _PolitiquesCommercialesContenuState();
}

/// Le resultat d'une tentative de publication.
enum _Publication { aucune, champsACorriger, indisponible, nonConfirmee }

class _PolitiquesCommercialesContenuState
    extends ConsumerState<PolitiquesCommercialesContenu> {
  final Map<String, TextEditingController> _saisies =
      <String, TextEditingController>{};
  _Publication _publication = _Publication.aucune;
  bool _enCours = false;

  PolitiqueCommerciale get _lue => widget.brouillon ?? widget.active;
  bool get _estBrouillon => widget.brouillon != null;

  @override
  void initState() {
    super.initState();
    if (!_estBrouillon) return;
    for (final _Champ c in _tousLesChamps()) {
      final String? initiale = c.saisieInitiale;
      if (initiale == null) continue;
      _saisies[c.id] = TextEditingController(text: initiale)
        ..addListener(_rafraichir);
    }
  }

  void _rafraichir() => setState(() {
    if (_publication == _Publication.champsACorriger) {
      _publication = _Publication.aucune;
    }
  });

  @override
  void dispose() {
    for (final TextEditingController c in _saisies.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// La saisie du champ [id] en unites entieres, ou `null` si elle est vide
  /// ou mal formee. La borne (douze chiffres) tient un franc guineen a
  /// plusieurs millions et reste loin du depassement d'un entier sur 64 bits
  /// une fois converti en unites mineures.
  int? _saisie(String id) {
    final String texte = _saisies[id]?.text.trim() ?? '';
    if (!RegExp(r'^\d{1,12}$').hasMatch(texte)) return null;
    return int.parse(texte);
  }

  /// Vrai quand le champ facultatif [c] est laisse vide : pas encore fixe.
  bool _videPermis(_Champ c) =>
      c.facultatif && (_saisies[c.id]?.text.trim() ?? '').isEmpty;

  /// La phrase d'erreur du champ [c], ou `null` : la forme d'abord, puis la
  /// coherence avec les autres valeurs a l'ecran.
  String? _erreurDe(_Champ c) {
    if (!_saisies.containsKey(c.id) || _videPermis(c)) return null;
    final pol = t.admin.finance.pol;
    final int? s = _saisie(c.id);
    if (s == null) return pol.erreurChamp;
    final Object v = c.depuisSaisie(s);
    Object? autre(String id) => _courante(_champ(id));
    switch (c.id) {
      case 'capaciteEnfant' || 'capaciteAdulte' || 'capaciteDebutant':
        if (s < 1) return pol.erreurCapacite;
      case 'tarifEnfant' || 'tarifAdulte':
        if (s < 1) return pol.erreurTarif;
      case 'plafondHoraire':
        if (autre('baseHoraire') case final Montant base
            when v is Montant && v.mineur < base.mineur) {
          return pol.erreurPlafond(base: _texteValeur(base, c.nature));
        }
      case 'groupesMax':
        if (autre('groupesObjectif') case final int objectif
            when s < objectif) {
          return pol.erreurGroupesMax(objectif: pol.groupes(n: objectif));
        }
      case 'minimum':
        final List<int> capacites = <int>[
          for (final String id in <String>[
            'capaciteEnfant',
            'capaciteAdulte',
            'capaciteDebutant',
          ])
            if (autre(id) case final int n) n,
        ];
        final int plusPetite = capacites.reduce(
          (int a, int b) => a < b ? a : b,
        );
        // Une capacite nulle porte deja sa propre erreur.
        if (plusPetite >= 1 && s > plusPetite) {
          return pol.erreurMinimum(capacite: pol.eleves(n: plusPetite));
        }
      default:
        if (c.nature == _Nature.remise && v is Montant) {
          // La remise ne depasse aucun tarif auquel elle s'applique.
          for (final String id in <String>['tarifEnfant', 'tarifAdulte']) {
            if (autre(id) case final Montant tarif
                when v.mineur.abs() > tarif.mineur) {
              return pol.erreurRemise(tarif: _texteValeur(tarif, c.nature));
            }
          }
        }
    }
    return null;
  }

  bool _enErreur(String id) => _erreurDe(_champ(id)) != null;

  /// Le champ [id] de la version affichee.
  _Champ _champ(String id) =>
      _tousLesChamps().firstWhere((_Champ c) => c.id == id);

  /// La valeur courante du champ : la saisie quand elle est bien formee
  /// (`null` pour un champ facultatif laisse vide), sinon la valeur lue.
  Object? _courante(_Champ c) {
    if (!_saisies.containsKey(c.id)) return c.lue;
    if (_videPermis(c)) return null;
    final int? s = _saisie(c.id);
    return s == null ? c.lue : c.depuisSaisie(s);
  }

  bool _differe(_Champ c) => _courante(c) != c.active;

  /// Vrai quand chaque champ du brouillon porte une saisie valide.
  bool get _saisiesValides => !_saisies.keys.any(_enErreur);

  /// L'empreinte des saisies : l'apercu se relit quand elle change.
  String get _empreinteSaisies => <String>[
    for (final MapEntry<String, TextEditingController> e in _saisies.entries)
      '${e.key}=${e.value.text}',
  ].join(';');

  // Les champs, section par section, dans l'ordre du guide §5.7.

  List<_Champ> _tarifs() {
    final pol = t.admin.finance.pol;
    final PolitiqueCommerciale a = widget.active;
    return <_Champ>[
      _Champ(
        id: 'tarifEnfant',
        libelle: pol.tarifEnfant,
        consequence: pol.tarifEnfantDetail,
        nature: _Nature.montant,
        lue: _lue.tarifEnfant,
        active: a.tarifEnfant,
      ),
      _Champ(
        id: 'tarifAdulte',
        libelle: pol.tarifAdulte,
        consequence: pol.tarifAdulteDetail,
        nature: _Nature.montant,
        lue: _lue.tarifAdulte,
        active: a.tarifAdulte,
      ),
    ];
  }

  List<_Champ> _essai() {
    final pol = t.admin.finance.pol;
    return <_Champ>[
      _Champ(
        id: 'essais',
        libelle: pol.essais,
        consequence: pol.essaisDetail,
        nature: _Nature.seances,
        lue: _lue.essaisMax,
        active: widget.active.essaisMax,
      ),
    ];
  }

  List<_Champ> _remises() {
    final pol = t.admin.finance.pol;
    final List<RemiseRang> rangs = _lue.remisesParRang;
    return <_Champ>[
      for (int i = 0; i < rangs.length; i++)
        _Champ(
          id: 'remise-${rangs[i].aPartirDuRang}',
          libelle: i == rangs.length - 1
              ? pol.remiseRangSuivants(rang: '${rangs[i].aPartirDuRang}')
              : pol.remiseRang(rang: '${rangs[i].aPartirDuRang}'),
          consequence: i == rangs.length - 1
              ? pol.remiseRangSuivantsDetail
              : pol.remiseRangDetail,
          nature: _Nature.remise,
          lue: rangs[i].remise,
          active: widget.active.remisePourRang(rangs[i].aPartirDuRang),
        ),
    ];
  }

  List<_Champ> _enseignants() {
    final pol = t.admin.finance.pol;
    final PolitiqueCommerciale a = widget.active;
    return <_Champ>[
      _Champ(
        id: 'baseHoraire',
        libelle: pol.baseHoraire,
        consequence: pol.baseHoraireDetail,
        nature: _Nature.montantHoraire,
        lue: _lue.baseHoraire,
        active: a.baseHoraire,
      ),
      _Champ(
        id: 'plafondHoraire',
        libelle: pol.plafondHoraire,
        consequence: pol.plafondHoraireDetail,
        nature: _Nature.montantHoraire,
        lue: _lue.plafondHoraire,
        active: a.plafondHoraire,
      ),
      _Champ(
        id: 'groupesObjectif',
        libelle: pol.groupesObjectif,
        consequence: pol.groupesObjectifDetail,
        nature: _Nature.groupes,
        lue: _lue.groupesObjectif,
        active: a.groupesObjectif,
      ),
      _Champ(
        id: 'groupesMax',
        libelle: pol.groupesMax,
        consequence: pol.groupesMaxDetail,
        nature: _Nature.groupes,
        lue: _lue.groupesMax,
        active: a.groupesMax,
      ),
      _Champ(
        id: 'internet',
        libelle: pol.internet,
        consequence: pol.internetDetail,
        nature: _Nature.montant,
        lue: _lue.allocationInternet,
        active: a.allocationInternet,
        devise: _lue.tarifEnfant.devise,
        facultatif: true,
      ),
    ];
  }

  List<_Champ> _groupes() {
    final pol = t.admin.finance.pol;
    final PolitiqueCommerciale a = widget.active;
    return <_Champ>[
      _Champ(
        id: 'capaciteEnfant',
        libelle: pol.capaciteEnfant,
        consequence: pol.capaciteEnfantDetail,
        nature: _Nature.eleves,
        lue: _lue.capaciteEnfant,
        active: a.capaciteEnfant,
      ),
      _Champ(
        id: 'capaciteAdulte',
        libelle: pol.capaciteAdulte,
        consequence: pol.capaciteAdulteDetail,
        nature: _Nature.eleves,
        lue: _lue.capaciteAdulte,
        active: a.capaciteAdulte,
      ),
      _Champ(
        id: 'capaciteDebutant',
        libelle: pol.capaciteDebutant,
        consequence: pol.capaciteDebutantDetail,
        nature: _Nature.eleves,
        lue: _lue.capaciteDebutant,
        active: a.capaciteDebutant,
      ),
      _Champ(
        id: 'minimum',
        libelle: pol.minimum,
        consequence: pol.minimumDetail,
        nature: _Nature.eleves,
        lue: _lue.minimumOuverture,
        active: a.minimumOuverture,
      ),
    ];
  }

  List<_Champ> _paiement() {
    final pol = t.admin.finance.pol;
    return <_Champ>[
      _Champ(
        id: 'conservation',
        libelle: pol.conservation,
        consequence: pol.conservationDetail,
        nature: _Nature.jours,
        lue: _lue.joursConservationPlace,
        active: widget.active.joursConservationPlace,
      ),
    ];
  }

  List<_Champ> _tousLesChamps() => <_Champ>[
    ..._tarifs(),
    ..._essai(),
    ..._remises(),
    ..._enseignants(),
    ..._groupes(),
    ..._paiement(),
  ];

  /// Le brouillon tel qu'il est a l'ecran, dans la forme du port.
  PolitiqueCommerciale _brouillonAEcran() {
    final PolitiqueCommerciale b = widget.brouillon!;
    final Map<String, Object?> v = <String, Object?>{
      for (final _Champ c in _tousLesChamps()) c.id: _courante(c),
    };
    return PolitiqueCommerciale(
      version: b.version,
      statut: b.statut,
      dateEffet: b.dateEffet,
      tarifEnfant: v['tarifEnfant']! as Montant,
      tarifAdulte: v['tarifAdulte']! as Montant,
      essaisMax: v['essais']! as int,
      remisesParRang: <RemiseRang>[
        for (final RemiseRang r in b.remisesParRang)
          RemiseRang(
            aPartirDuRang: r.aPartirDuRang,
            remise: v['remise-${r.aPartirDuRang}']! as Montant,
          ),
      ],
      baseHoraire: v['baseHoraire']! as Montant,
      plafondHoraire: v['plafondHoraire']! as Montant,
      capaciteEnfant: v['capaciteEnfant']! as int,
      capaciteAdulte: v['capaciteAdulte']! as int,
      capaciteDebutant: v['capaciteDebutant']! as int,
      minimumOuverture: v['minimum']! as int,
      groupesObjectif: v['groupesObjectif']! as int,
      groupesMax: v['groupesMax']! as int,
      joursConservationPlace: v['conservation']! as int,
      margeReferencePourMille: b.margeReferencePourMille,
      railsActifs: b.railsActifs,
      allocationInternet: v['internet'] as Montant?,
    );
  }

  Future<void> _publier() async {
    if (_saisies.keys.any(_enErreur)) {
      setState(() => _publication = _Publication.champsACorriger);
      return;
    }
    setState(() => _enCours = true);
    _Publication resultat;
    try {
      await ref
          .read(portPolitiquesCommercialesProvider)
          .publier(_brouillonAEcran());
      // Aucune implementation ne publie a ce jour ; une reponse sans
      // erreur reste non confirmee tant que la version active n'est pas
      // relue (D5).
      resultat = _Publication.nonConfirmee;
    } on CapaciteIndisponible {
      resultat = _Publication.indisponible;
    } on Object {
      resultat = _Publication.nonConfirmee;
    }
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _publication = resultat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final pol = t.admin.finance.pol;
    // Les champs, puis la marge et les rails, lus sans champ.
    final int differences = _estBrouillon
        ? _tousLesChamps().where(_differe).length +
              (_margeDiffere ? 1 : 0) +
              (_railsDifferent ? 1 : 0)
        : 0;

    final List<Widget> sections = <Widget>[
      _section(pol.tarifs, pol.tarifsDetail, <Widget>[
        for (final _Champ c in _tarifs()) _ligne(c),
      ]),
      _section(pol.essai, pol.essaiDetail, <Widget>[
        for (final _Champ c in _essai()) _ligne(c),
      ]),
      _section(pol.remises, pol.remisesDetail, <Widget>[
        if (_lue.remisesParRang.isNotEmpty &&
            _lue.remisesParRang.first.aPartirDuRang > 1)
          LigneCleValeur(
            cle: pol.remiseAucune(
              rang: '${_lue.remisesParRang.first.aPartirDuRang - 1}',
            ),
            detailCle: pol.remiseAucuneDetail,
            valeur: pol.remiseAucuneValeur,
          ),
        for (final _Champ c in _remises()) _ligne(c),
      ]),
      _section(pol.enseignants, pol.enseignantsDetail, <Widget>[
        for (final _Champ c in _enseignants().take(2)) _ligne(c),
        LigneCleValeur(
          cle: pol.occupation,
          detailCle: pol.occupationDetail,
          valeur: pol.occupationValeur,
        ),
        for (final _Champ c in _enseignants().skip(2)) _ligne(c),
      ]),
      _section(pol.sectionGroupes, pol.sectionGroupesDetail, <Widget>[
        for (final _Champ c in _groupes()) _ligne(c),
      ]),
      _section(pol.paiement, pol.paiementDetail, <Widget>[
        LigneCleValeur(
          key: PolitiquesCommercialesContenu.champKey('rails'),
          cle: pol.railWeb,
          detailCle: pol.railWebDetail,
          valeur: _texteRail(_lue),
          complement: _railsDifferent
              ? _texteComparaison(
                  'rails',
                  _texteRail(widget.active),
                  chiffres: false,
                )
              : null,
        ),
        for (final _Champ c in _paiement()) _ligne(c),
      ]),
      _section(pol.pilotage, pol.pilotageDetail, <Widget>[_ligneMarge()]),
      _invariants(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          pol.contexte,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vXxl,
        _EnteteVersion(
          key: PolitiquesCommercialesContenu.enteteKey,
          active: widget.active,
          brouillon: widget.brouillon,
          differences: differences,
        ),
        Ecart.vXxl,
        _Historique(
          key: PolitiquesCommercialesContenu.historiqueKey,
          versions: widget.versions,
          active: widget.active,
        ),
        Ecart.vXxl,
        LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints contraintes) {
            if (_enColonne(contexte, contraintes)) {
              return PileCartes(children: sections);
            }
            return PileCartes(
              axe: Axis.horizontal,
              alignement: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: PileCartes(
                    children: <Widget>[
                      for (int i = 0; i < sections.length; i += 2) sections[i],
                    ],
                  ),
                ),
                Expanded(
                  child: PileCartes(
                    children: <Widget>[
                      for (int i = 1; i < sections.length; i += 2) sections[i],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        if (_estBrouillon) ...<Widget>[
          Ecart.vXxl,
          _Apercu(
            brouillon: _saisiesValides ? _brouillonAEcran() : null,
            empreinte: _empreinteSaisies,
          ),
          Ecart.vXxl,
          Text(pol.publierConsequence, style: textes.bodyLarge),
          ..._bandeauPublication(),
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ActionPrincipale(
              libelle: pol.publier,
              pleineLargeur: false,
              enCours: _enCours,
              onPress: _publier,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _bandeauPublication() {
    final pol = t.admin.finance.pol;
    final (String, String, TonEtat)? contenu = switch (_publication) {
      _Publication.aucune => null,
      _Publication.champsACorriger => (
        pol.champsACorriger,
        pol.champsACorrigerDetail,
        TonEtat.alerte,
      ),
      _Publication.indisponible => (
        pol.publicationIndisponible,
        pol.publicationIndisponibleDetail,
        TonEtat.avertissement,
      ),
      _Publication.nonConfirmee => (
        pol.publicationNonConfirmee,
        pol.publicationNonConfirmeeDetail,
        TonEtat.alerte,
      ),
    };
    if (contenu == null) return const <Widget>[];
    return <Widget>[
      Ecart.vLg,
      BandeauAttention(
        key: PolitiquesCommercialesContenu.publicationKey,
        titre: contenu.$1,
        message: contenu.$2,
        ton: contenu.$3,
      ),
    ];
  }

  /// Une section du guide : son titre, sa phrase, ses lignes separees par un
  /// filet fin, dans UNE carte (contenus lies, K-55).
  Widget _section(String titre, String detail, List<Widget> lignes) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(titre, style: textes.titleMedium),
          ),
          Ecart.vXs,
          Text(
            detail,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          for (int i = 0; i < lignes.length; i++) ...<Widget>[
            if (i > 0) ...<Widget>[Ecart.vSm, const FiletCarte(), Ecart.vSm],
            lignes[i],
          ],
        ],
      ),
    );
  }

  /// Une valeur de politique : un champ dans un brouillon, une ligne lue
  /// sinon.
  Widget _ligne(_Champ c) {
    final TextEditingController? saisie = _saisies[c.id];
    if (saisie == null) {
      return LigneCleValeur(
        key: PolitiquesCommercialesContenu.champKey(c.id),
        cle: c.libelle,
        detailCle: c.consequence,
        valeur: _texteValeur(c.lue, c.nature),
        chiffres: c.lue != null,
        complement: _estBrouillon && _differe(c) ? _comparaison(c) : null,
      );
    }
    return _ChampPolitique(
      key: PolitiquesCommercialesContenu.champKey(c.id),
      libelle: c.libelle,
      consequence: c.consequence,
      suffixe: _suffixe(c),
      controleur: saisie,
      erreur: _erreurDe(c),
      indice: c.facultatif ? t.admin.finance.pol.internetNonFixee : null,
      comparaison: _differe(c) ? _comparaison(c) : null,
    );
  }

  Widget _comparaison(_Champ c) =>
      _texteComparaison(c.id, _texteValeur(c.active, c.nature));

  /// « Version active : [valeur] », sous la ligne [id].
  Widget _texteComparaison(String id, String valeur, {bool chiffres = true}) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle base = textes.bodyMedium ?? const TextStyle();
    return Text(
      t.admin.finance.pol.versionActiveValeur(valeur: valeur),
      key: PolitiquesCommercialesContenu.comparaisonKey(id),
      style: palette.inkMuted.applyTo(
        chiffres ? AppTypography.tabulaire(base) : base,
      ),
    );
  }

  /// Vrai quand la marge de reference du brouillon differe de l'active.
  bool get _margeDiffere =>
      _estBrouillon &&
      _lue.margeReferencePourMille != widget.active.margeReferencePourMille;

  /// Vrai quand les rails actifs du brouillon different de l'active.
  bool get _railsDifferent =>
      _estBrouillon && !setEquals(_lue.railsActifs, widget.active.railsActifs);

  /// Le rail web de [p] en mots : actif ou inactif.
  String _texteRail(PolitiqueCommerciale p) =>
      p.railsActifs.contains(RailPaiement.webStripe)
      ? t.admin.finance.pol.railActif
      : t.admin.finance.pol.railInactif;

  String _suffixe(_Champ c) {
    final pol = t.admin.finance.pol;
    final String? devise = c.deviseMontant;
    final String symbole = c.estMontant && devise != null
        ? symboleDe(devise)
        : '';
    return switch (c.nature) {
      _Nature.montant => symbole,
      _Nature.montantHoraire => pol.suffixeParHeure(symbole: symbole),
      _Nature.remise => pol.suffixeRemise(symbole: symbole),
      _Nature.eleves => pol.uniteEleves,
      _Nature.seances => pol.uniteSeances,
      _Nature.groupes => pol.uniteGroupes,
      _Nature.jours => pol.uniteJours,
    };
  }

  /// La marge de reference : lue, jamais un champ sur cet ecran pour
  /// l'instant, jamais une sanction (FI21).
  Widget _ligneMarge() {
    final pol = t.admin.finance.pol;
    final ({int objectif, int forte, int stretch}) m =
        _lue.margeReferencePourMille;
    final ({int objectif, int forte, int stretch}) a =
        widget.active.margeReferencePourMille;
    String texte(({int objectif, int forte, int stretch}) r) => pol.margeValeur(
      objectif: pourMilleEnTexte(r.objectif),
      forte: pourMilleEnTexte(r.forte),
      stretch: pourMilleEnTexte(r.stretch),
    );
    return LigneCleValeur(
      key: PolitiquesCommercialesContenu.champKey('marge'),
      cle: pol.marge,
      detailCle: pol.margeDetail,
      valeur: texte(m),
      chiffres: true,
      complement: _margeDiffere
          ? _texteComparaison('marge', texte(a), chiffres: false)
          : null,
    );
  }

  /// Les regles fixes : du texte, jamais un champ (FI22).
  Widget _invariants() {
    final pol = t.admin.finance.pol;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      key: PolitiquesCommercialesContenu.invariantsKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(pol.invariants, style: textes.titleMedium),
          ),
          Ecart.vXs,
          Text(
            pol.invariantsDetail,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          for (final String regle in <String>[
            pol.invariantIdempotence,
            pol.invariantSoldes,
            pol.invariantHistorique,
            pol.invariantConfirmation,
            pol.invariantDoubleDebit,
            pol.invariantPeriode,
          ]) ...<Widget>[Ecart.vMd, Text(regle, style: textes.bodyMedium)],
        ],
      ),
    );
  }
}

/// Vrai quand les cartes s'empilent : ecran etroit ou texte agrandi.
bool _enColonne(BuildContext contexte, BoxConstraints contraintes) =>
    MediaQuery.textScalerOf(contexte).scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne ||
    contraintes.maxWidth < AppGabarit.seuilEtendu;

/// Une valeur mise en mots : montant (« 50 $ », « 4 $ / h », « −5 $ ») ou
/// nombre avec son unite (« 5 élèves »). `null` : pas de remise pour un
/// rang (« Prix normal »), pas encore fixee sinon (aide Internet).
String _texteValeur(Object? valeur, _Nature nature) {
  final pol = t.admin.finance.pol;
  return switch (valeur) {
    null when nature == _Nature.remise => pol.remiseAucuneValeur,
    null => pol.internetNonFixee,
    final Montant m when nature == _Nature.montantHoraire => pol.parHeure(
      montant: formaterMontant(m),
    ),
    final Montant m => formaterMontant(m),
    final int n => switch (nature) {
      _Nature.eleves => pol.eleves(n: n),
      _Nature.seances => pol.seances(n: n),
      _Nature.groupes => pol.groupes(n: n),
      _ => pol.jours(n: n),
    },
    _ => '$valeur',
  };
}

/// Une date d'effet en mots : « 1 octobre 2026 ».
String dateEffetEnTexte(DateTime date) => t.admin.finance.pol.date(
  jour: '${date.day}',
  mois: t.commun.dates.mois[date.month - 1],
  annee: '${date.year}',
);

/// L'en-tete de version (PolicyVersionHeader) : le brouillon et sa date
/// d'effet, la version active, et ce qui les distingue ; ou la seule version
/// active quand aucun brouillon n'est ouvert.
class _EnteteVersion extends StatelessWidget {
  const _EnteteVersion({
    required this.active,
    required this.brouillon,
    required this.differences,
    super.key,
  });

  final PolitiqueCommerciale active;
  final PolitiqueCommerciale? brouillon;
  final int differences;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final pol = t.admin.finance.pol;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    Widget version(StatusPill pastille, String titre, String detail) =>
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              pastille,
              Ecart.vSm,
              Text(titre, style: textes.titleMedium),
              Ecart.vXs,
              Text(detail, style: attenue),
            ],
          ),
        );
    final Widget versionActive = version(
      StatusPill(libelle: pol.statutPubliee, ton: TonEtat.succes),
      pol.versionActive(version: active.version),
      pol.enVigueur(date: dateEffetEnTexte(active.dateEffet)),
    );
    final PolitiqueCommerciale? b = brouillon;
    return CarteGroupee(
      sections: <Widget>[
        if (b != null) ...<Widget>[
          version(
            StatusPill(
              libelle: pol.statutBrouillon,
              ton: TonEtat.avertissement,
            ),
            pol.versionBrouillon(version: b.version),
            pol.dateEffet(date: dateEffetEnTexte(b.dateEffet)),
          ),
          Text(pol.dateEffetDetail, style: attenue),
        ],
        versionActive,
        if (b != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                differences == 0
                    ? pol.aucuneDifference
                    : pol.differences(n: differences),
                style: textes.bodyLarge,
              ),
              Ecart.vSm,
              Text(pol.nonEnregistre, style: attenue),
            ],
          )
        else
          Text(pol.sansBrouillon, style: textes.bodyLarge),
      ],
    );
  }
}

/// Un champ de politique (PolicyField), compose ici : le libelle, la
/// consequence en une phrase (K-58), la saisie en nombre entier avec son
/// unite, l'erreur de saisie, et la valeur active quand elle differe.
class _ChampPolitique extends StatelessWidget {
  const _ChampPolitique({
    required this.libelle,
    required this.consequence,
    required this.suffixe,
    required this.controleur,
    required this.erreur,
    required this.comparaison,
    super.key,
    this.indice,
  });

  final String libelle;
  final String consequence;
  final String suffixe;
  final TextEditingController controleur;
  final String? erreur;
  final Widget? comparaison;

  /// Le texte d'un champ facultatif laisse vide (« Pas encore fixée »).
  final String? indice;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(libelle, style: textes.titleSmall),
        Ecart.vXs,
        Text(
          consequence,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        Semantics(
          label: libelle,
          child: TextField(
            controller: controleur,
            keyboardType: TextInputType.number,
            style: AppTypography.tabulaire(
              textes.bodyLarge ?? const TextStyle(),
            ),
            decoration: InputDecoration(
              suffixText: suffixe,
              hintText: indice,
              errorText: erreur,
              errorMaxLines: 4,
            ),
          ),
        ),
        if (comparaison case final Widget c) ...<Widget>[Ecart.vXs, c],
      ],
    );
  }
}

/// La forme de la page pendant la lecture : la phrase, l'en-tete, des
/// sections.
class _Squelette extends StatelessWidget {
  const _Squelette();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Skeleton.texte(lignes: 2),
      Ecart.vXxl,
      Skeleton.liste(lignes: 4),
    ],
  );
}

/// Le titre d'une carte et sa phrase, comme les sections.
class _TitreCarte extends StatelessWidget {
  const _TitreCarte({required this.titre, required this.detail});

  final String titre;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(header: true, child: Text(titre, style: textes.titleMedium)),
        Ecart.vXs,
        Text(
          detail,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

/// Des lignes separees par un filet fin, dans une meme carte (K-55).
List<Widget> _avecFilets(List<Widget> lignes) => <Widget>[
  for (int i = 0; i < lignes.length; i++) ...<Widget>[
    if (i > 0) ...<Widget>[Ecart.vSm, const FiletCarte(), Ecart.vSm],
    lignes[i],
  ],
];

/// L'historique des versions (PolicyVersionHistory) : version, statut, date
/// d'effet, la version active marquee. Rien ne s'y modifie.
class _Historique extends StatelessWidget {
  const _Historique({required this.versions, required this.active, super.key});

  final List<PolitiqueCommerciale> versions;
  final PolitiqueCommerciale active;

  @override
  Widget build(BuildContext context) {
    final pol = t.admin.finance.pol;
    final TextTheme textes = Theme.of(context).textTheme;
    // La version active est toujours dans l'historique, meme quand la
    // liste rendue l'omet.
    final List<PolitiqueCommerciale> liste = <PolitiqueCommerciale>[
      ...versions,
      if (!versions.any(
        (PolitiqueCommerciale v) => v.version == active.version,
      ))
        active,
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _TitreCarte(titre: pol.historique, detail: pol.historiqueDetail),
          Ecart.vMd,
          ..._avecFilets(<Widget>[
            for (final PolitiqueCommerciale v in liste)
              LigneCleValeur(
                key: PolitiquesCommercialesContenu.historiqueLigneKey(
                  v.version,
                ),
                cle: pol.historiqueVersion(version: v.version),
                detailCle: pol.dateEffet(date: dateEffetEnTexte(v.dateEffet)),
                valeur: v.statut == StatutPolitique.brouillon
                    ? pol.statutBrouillon
                    : pol.statutPubliee,
                complement: v.version == active.version
                    ? StatusPill(
                        libelle: pol.historiqueActive,
                        ton: TonEtat.succes,
                      )
                    : null,
              ),
          ]),
          if (liste.length == 1) ...<Widget>[
            Ecart.vMd,
            Text(pol.historiqueVide, style: textes.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Le type de classe de l'apercu enseignant : sa capacite se lit dans le
/// brouillon.
enum _TypeClasse { enfants, adultes, debutants }

/// L'« Apercu avant publication » du brouillon a l'ecran : un foyer et un
/// enseignant. [brouillon] nul : une saisie est invalide, l'apercu attend.
/// Les montants viennent du port, relus quand [empreinte] change.
class _Apercu extends ConsumerStatefulWidget {
  const _Apercu({required this.brouillon, required this.empreinte});

  final PolitiqueCommerciale? brouillon;
  final String empreinte;

  @override
  ConsumerState<_Apercu> createState() => _ApercuState();
}

class _ApercuState extends ConsumerState<_Apercu> {
  /// Le foyer de la maquette 10 : trois enfants payants.
  int _enfants = 3;
  _TypeClasse _type = _TypeClasse.enfants;

  /// Les sieges eligibles choisis ; nul : toute la classe.
  int? _eligibles;

  AsyncValue<ApercuFamille>? _famille;
  AsyncValue<ApercuEnseignant>? _enseignant;
  int _jetonFamille = 0;
  int _jetonEnseignant = 0;

  /// Vrai pendant un nouveau calcul : le resultat affiche est celui du choix
  /// precedent, et l'apercu le dit.
  bool _familleARelire = false;
  bool _enseignantARelire = false;

  @override
  void initState() {
    super.initState();
    _relireFamille();
    _relireEnseignant();
  }

  @override
  void didUpdateWidget(_Apercu ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.empreinte != widget.empreinte ||
        (ancien.brouillon == null) != (widget.brouillon == null)) {
      _relireFamille();
      _relireEnseignant();
    }
  }

  int? get _capacite => switch ((widget.brouillon, _type)) {
    (null, _) => null,
    (final PolitiqueCommerciale b, _TypeClasse.enfants) => b.capaciteEnfant,
    (final PolitiqueCommerciale b, _TypeClasse.adultes) => b.capaciteAdulte,
    (final PolitiqueCommerciale b, _TypeClasse.debutants) => b.capaciteDebutant,
  };

  /// Les sieges eligibles retenus, jamais au-dessus de la capacite.
  int _eligiblesPour(int capacite) {
    final int e = _eligibles ?? capacite;
    return e > capacite ? capacite : e;
  }

  void _relireFamille() {
    final int jeton = ++_jetonFamille;
    final PolitiqueCommerciale? b = widget.brouillon;
    if (b == null) {
      _famille = null;
      _familleARelire = false;
      return;
    }
    // Pendant le calcul, un ancien resultat reste en place (pas de saut de
    // mise en page) mais il est signale perime ; sans resultat, le squelette.
    _familleARelire = _famille is AsyncData<ApercuFamille>;
    if (!_familleARelire) _famille = const AsyncLoading<ApercuFamille>();
    ref
        .read(portPolitiquesCommercialesProvider)
        .apercuFamille(b, _enfants)
        .then(
          (ApercuFamille a) =>
              _poserFamille(jeton, AsyncData<ApercuFamille>(a)),
          onError: (Object e, StackTrace s) =>
              _poserFamille(jeton, AsyncError<ApercuFamille>(e, s)),
        );
  }

  void _poserFamille(int jeton, AsyncValue<ApercuFamille> v) {
    if (!mounted || jeton != _jetonFamille) return;
    setState(() {
      _famille = v;
      _familleARelire = false;
    });
  }

  void _relireEnseignant() {
    final int jeton = ++_jetonEnseignant;
    final PolitiqueCommerciale? b = widget.brouillon;
    final int? capacite = _capacite;
    if (b == null || capacite == null || capacite < 1) {
      _enseignant = null;
      _enseignantARelire = false;
      return;
    }
    _enseignantARelire = _enseignant is AsyncData<ApercuEnseignant>;
    if (!_enseignantARelire) {
      _enseignant = const AsyncLoading<ApercuEnseignant>();
    }
    ref
        .read(portPolitiquesCommercialesProvider)
        .apercuEnseignant(
          b,
          capacite: capacite,
          eligibles: _eligiblesPour(capacite),
        )
        .then(
          (ApercuEnseignant a) =>
              _poserEnseignant(jeton, AsyncData<ApercuEnseignant>(a)),
          onError: (Object e, StackTrace s) =>
              _poserEnseignant(jeton, AsyncError<ApercuEnseignant>(e, s)),
        );
  }

  void _poserEnseignant(int jeton, AsyncValue<ApercuEnseignant> v) {
    if (!mounted || jeton != _jetonEnseignant) return;
    setState(() {
      _enseignant = v;
      _enseignantARelire = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pol = t.admin.finance.pol;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final Widget famille = AppCard(
      key: PolitiquesCommercialesContenu.apercuFamilleKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _TitreCarte(
            titre: pol.apercuFamille,
            detail: pol.apercuFamilleDetail,
          ),
          Ecart.vLg,
          Text(pol.apercuEnfantsChoix, style: textes.titleSmall),
          Ecart.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (int n = 1; n <= 5; n++)
                FilterPill(
                  libelle: pol.apercuEnfants(n: n),
                  retenue: _enfants == n,
                  onPress: () => setState(() {
                    _enfants = n;
                    _relireFamille();
                  }),
                ),
            ],
          ),
          Ecart.vLg,
          const FiletCarte(),
          Ecart.vLg,
          _resultat<ApercuFamille>(
            _famille,
            aRelire: _familleARelire,
            horsLigne: horsLigne,
            attente: pol.apercuAttenteDetail,
            relancer: () => setState(_relireFamille),
            contenu: _contenuFamille,
          ),
        ],
      ),
    );
    final int? capacite = _capacite;
    final Widget enseignant = AppCard(
      key: PolitiquesCommercialesContenu.apercuEnseignantKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _TitreCarte(
            titre: pol.apercuEnseignant,
            detail: pol.apercuEnseignantDetail,
          ),
          Ecart.vLg,
          Text(pol.apercuTypeClasse, style: textes.titleSmall),
          Ecart.vSm,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final _TypeClasse type in _TypeClasse.values)
                FilterPill(
                  libelle: switch (type) {
                    _TypeClasse.enfants => pol.apercuClasseEnfants,
                    _TypeClasse.adultes => pol.apercuClasseAdultes,
                    _TypeClasse.debutants => pol.apercuClasseDebutants,
                  },
                  retenue: _type == type,
                  onPress: () => setState(() {
                    _type = type;
                    _eligibles = null;
                    _relireEnseignant();
                  }),
                ),
            ],
          ),
          if (capacite != null && capacite >= 1) ...<Widget>[
            Ecart.vLg,
            Text(pol.apercuEligiblesChoix, style: textes.titleSmall),
            Ecart.vXs,
            Text(
              pol.apercuEligiblesDetail,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
            Ecart.vSm,
            _pasEligibles(capacite),
          ],
          Ecart.vLg,
          const FiletCarte(),
          Ecart.vLg,
          _resultat<ApercuEnseignant>(
            _enseignant,
            aRelire: _enseignantARelire,
            horsLigne: horsLigne,
            attente: widget.brouillon == null
                ? pol.apercuAttenteDetail
                : pol.apercuCapaciteAttente,
            relancer: () => setState(_relireEnseignant),
            contenu: _contenuEnseignant,
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(pol.apercu, style: textes.titleLarge),
        ),
        Ecart.vXs,
        Text(
          pol.apercuDetail,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints contraintes) {
            if (_enColonne(contexte, contraintes)) {
              return PileCartes(children: <Widget>[famille, enseignant]);
            }
            return PileCartes(
              axe: Axis.horizontal,
              alignement: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: famille),
                Expanded(child: enseignant),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Le pas des sieges eligibles : moins, « 4 sur 5 », plus. Une fleche qui
  /// ne peut plus aboutir disparait (sa place reste), jamais grisee (K-56).
  Widget _pasEligibles(int capacite) {
    final pol = t.admin.finance.pol;
    final TextTheme textes = Theme.of(context).textTheme;
    final int e = _eligiblesPour(capacite);
    Widget fleche({
      required bool visible,
      required AppIcon icone,
      required String libelle,
      required int vers,
    }) => Visibility(
      visible: visible,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: BoutonIcone(
        icone: icone,
        libelle: libelle,
        onPress: () => setState(() {
          _eligibles = vers;
          _relireEnseignant();
        }),
      ),
    );
    return Row(
      children: <Widget>[
        fleche(
          visible: e > 0,
          icone: AppIcons.moins,
          libelle: pol.apercuEligiblesMoins,
          vers: e - 1,
        ),
        Expanded(
          child: Text(
            pol.apercuEligibles(eligibles: '$e', capacite: '$capacite'),
            textAlign: TextAlign.center,
            style: AppTypography.tabulaire(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
        ),
        fleche(
          visible: e < capacite,
          icone: AppIcons.ajouter,
          libelle: pol.apercuEligiblesPlus,
          vers: e + 1,
        ),
      ],
    );
  }

  Widget _contenuFamille(ApercuFamille a) {
    final pol = t.admin.finance.pol;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _avecFilets(<Widget>[
        for (final MensualiteApercu m in a.enfants)
          LigneFinance(
            key: PolitiquesCommercialesContenu.apercuEnfantKey(m.rang),
            libelle: pol.apercuEnfant(rang: '${m.rang}'),
            detail: switch (m.remise) {
              null => pol.apercuPrixNormal,
              final Montant r => pol.apercuRemise(montant: formaterMontant(r)),
            },
            montant: m.mensualite,
          ),
        LigneFinance(
          key: PolitiquesCommercialesContenu.apercuTotalKey,
          libelle: pol.apercuTotalFamille,
          montant: a.total,
          total: true,
        ),
      ]),
    );
  }

  Widget _contenuEnseignant(ApercuEnseignant a) {
    final pol = t.admin.finance.pol;
    String parHeure(Montant m) => pol.parHeure(montant: formaterMontant(m));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: _avecFilets(<Widget>[
        LigneCleValeur(
          cle: pol.apercuBase,
          valeur: parHeure(a.baseHoraire),
          chiffres: true,
        ),
        LigneCleValeur(
          cle: pol.apercuOccupation,
          detailCle: pol.apercuOccupationDetail(
            eligibles: '${a.eligibles}',
            capacite: '${a.capacite}',
          ),
          valeur: parHeure(a.occupation),
          chiffres: true,
        ),
        LigneCleValeur(
          key: PolitiquesCommercialesContenu.apercuTauxKey,
          cle: pol.apercuTaux,
          detailCle: pol.apercuTauxDetail(plafond: parHeure(a.plafondHoraire)),
          valeur: parHeure(a.tauxHoraire),
          chiffres: true,
          valeurForte: true,
        ),
      ]),
    );
  }

  /// Le resultat d'un apercu : attente d'une saisie valide, calcul, contenu
  /// (signale perime pendant un nouveau calcul, [aRelire]),
  /// indisponible, hors ligne ou echec (K-59 : ce qui manque, pourquoi, quoi
  /// faire).
  Widget _resultat<T>(
    AsyncValue<T>? valeur, {
    required bool aRelire,
    required bool horsLigne,
    required String attente,
    required VoidCallback relancer,
    required Widget Function(T) contenu,
  }) {
    final pol = t.admin.finance.pol;
    return switch (valeur) {
      null => _EtatApercu(titre: pol.apercuAttente, detail: attente),
      AsyncData<T>(:final T value) when aRelire => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _EtatApercu(
            titre: pol.apercuRecalcul,
            detail: pol.apercuRecalculDetail,
          ),
          Ecart.vMd,
          contenu(value),
        ],
      ),
      AsyncData<T>(:final T value) => contenu(value),
      AsyncError<T>(:final Object error) when error is CapaciteIndisponible =>
        _EtatApercu(
          titre: pol.apercuIndisponible,
          detail: pol.apercuIndisponibleDetail,
        ),
      AsyncError<T>() when horsLigne => _EtatApercu(
        titre: pol.apercuHorsLigne,
        detail: pol.apercuHorsLigneDetail,
        relancer: relancer,
      ),
      AsyncError<T>() => _EtatApercu(
        titre: pol.apercuErreur,
        detail: pol.apercuErreurDetail,
        relancer: relancer,
      ),
      _ => const Skeleton.texte(lignes: 3),
    };
  }
}

/// Un etat de l'apercu, dans sa carte : un titre, une phrase, et « Relancer
/// le calcul » quand un nouvel essai peut aboutir.
class _EtatApercu extends StatelessWidget {
  const _EtatApercu({required this.titre, required this.detail, this.relancer});

  final String titre;
  final String detail;
  final VoidCallback? relancer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VoidCallback? action = relancer;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(titre, style: textes.titleSmall),
          Ecart.vXs,
          Text(
            detail,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          if (action != null) ...<Widget>[
            Ecart.vSm,
            LienFleche(
              libelle: t.admin.finance.pol.apercuRecalculer,
              onPress: action,
            ),
          ],
        ],
      ),
    );
  }
}
