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
// Les invariants (paiement web seul au lancement, confirmation avant credit,
// pas de double debit, acces par periode financee, soldes separes) ne sont
// JAMAIS des champs (FI22) : une carte « Regles fixes » les dit en texte.
//
// « Publier » appelle le port, qui rend `CapaciteIndisponible` en production
// comme en demonstration : l'ecran le dit honnetement, rien n'est ecrit.
// Aucun calcul de prix ni de remise ici (FI6) : seule la conversion d'une
// saisie en unites entieres vers les unites mineures (`montantDepuisUnites`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_politiques_commerciales.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/finance/politique_commerciale.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import 'vue_globale_finance.dart' show pourMilleEnTexte;

/// La version active et le brouillon en cours, s'il y en a un.
typedef PolitiquesLues = ({
  PolitiqueCommerciale active,
  PolitiqueCommerciale? brouillon,
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
  return (active: active, brouillon: brouillon);
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

  bool get estMontant =>
      nature == _Nature.montant ||
      nature == _Nature.montantHoraire ||
      nature == _Nature.remise;

  /// La valeur preremplie dans le champ, en unites entieres (une remise en
  /// valeur absolue), ou `null` quand une saisie entiere ne la represente
  /// pas : le champ reste alors en lecture.
  int? get saisieInitiale {
    final Object? v = lue;
    if (v is int) return v;
    if (v is Montant) {
      final int? unites = unitesEntieresDe(v);
      if (unites == null) return null;
      return nature == _Nature.remise ? -unites : unites;
    }
    return null;
  }

  /// La valeur d'une saisie [unites] (deja validee), dans la forme du port.
  Object depuisSaisie(int unites) {
    final Object? v = lue;
    if (v is Montant) {
      return montantDepuisUnites(
        nature == _Nature.remise ? -unites : unites,
        v.devise,
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
  });

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
      final int? initiale = c.saisieInitiale;
      if (initiale == null) continue;
      _saisies[c.id] = TextEditingController(text: '$initiale')
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
  /// ou mal formee (chiffres seulement, six au plus).
  int? _saisie(String id) {
    final String texte = _saisies[id]?.text.trim() ?? '';
    if (!RegExp(r'^\d{1,6}$').hasMatch(texte)) return null;
    return int.parse(texte);
  }

  bool _enErreur(String id) => _saisies.containsKey(id) && _saisie(id) == null;

  /// La valeur courante du champ : la saisie quand elle est valide, sinon
  /// la valeur lue.
  Object? _courante(_Champ c) {
    if (!_saisies.containsKey(c.id)) return c.lue;
    final int? s = _saisie(c.id);
    return s == null ? c.lue : c.depuisSaisie(s);
  }

  bool _differe(_Champ c) => _courante(c) != c.active;

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
    final int differences = _estBrouillon
        ? _tousLesChamps().where(_differe).length
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
          cle: pol.railWeb,
          detailCle: pol.railWebDetail,
          valeur: _lue.railsActifs.contains(RailPaiement.webStripe)
              ? pol.railActif
              : pol.railInactif,
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
        LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints contraintes) {
            final bool agrandi =
                MediaQuery.textScalerOf(contexte).scale(AppSpacing.lg) /
                    AppSpacing.lg >=
                AppGabarit.seuilTexteColonne;
            if (agrandi || contraintes.maxWidth < AppGabarit.seuilEtendu) {
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
      erreur: _enErreur(c.id) ? t.admin.finance.pol.erreurChamp : null,
      comparaison: _differe(c) ? _comparaison(c) : null,
    );
  }

  Widget _comparaison(_Champ c) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Text(
      t.admin.finance.pol.versionActiveValeur(
        valeur: _texteValeur(c.active, c.nature),
      ),
      key: PolitiquesCommercialesContenu.comparaisonKey(c.id),
      style: palette.inkMuted.applyTo(
        AppTypography.tabulaire(textes.bodyMedium ?? const TextStyle()),
      ),
    );
  }

  String _suffixe(_Champ c) {
    final pol = t.admin.finance.pol;
    final String symbole = c.lue is Montant
        ? symboleDe((c.lue! as Montant).devise)
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
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return LigneCleValeur(
      key: PolitiquesCommercialesContenu.champKey('marge'),
      cle: pol.marge,
      detailCle: pol.margeDetail,
      valeur: texte(m),
      chiffres: true,
      complement: _estBrouillon && m != a
          ? Text(
              pol.versionActiveValeur(valeur: texte(a)),
              key: PolitiquesCommercialesContenu.comparaisonKey('marge'),
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            )
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
            pol.invariantConfirmation,
            pol.invariantDoubleDebit,
            pol.invariantPeriode,
            pol.invariantSoldes,
          ]) ...<Widget>[Ecart.vMd, Text(regle, style: textes.bodyMedium)],
        ],
      ),
    );
  }
}

/// Une valeur mise en mots : montant (« 50 $ », « 4 $ / h », « −5 $ ») ou
/// nombre avec son unite (« 5 élèves »). `null` : pas encore fixee.
String _texteValeur(Object? valeur, _Nature nature) {
  final pol = t.admin.finance.pol;
  return switch (valeur) {
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
  });

  final String libelle;
  final String consequence;
  final String suffixe;
  final TextEditingController controleur;
  final String? erreur;
  final Widget? comparaison;

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
