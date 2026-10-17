// Les Politiques commerciales, cote direction (`/admin/finance/politiques`,
// FI-11b ; guide Finance V4 §1, §5.7, §8 LOT F8 ; maquette 10 ; K-57, K-58).
//
// Une politique est versionnee : l'en-tete dit le statut (brouillon ou
// publiee) et la date d'effet. Les sections du guide (Tarifs, Essai, Remises,
// Enseignants, Classes, Paiement, Pilotage) LISENT les valeurs du port ; dans
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
// FI-Q21, decide par delegation le 05/10 : (1) la marge de reference (trois
// reperes, en pourcentage entier) et le paiement web sont modifiables dans un
// brouillon ; (2) les paiements iOS et Android se lisent « Préparé
// (inactif) », jamais un reglage ; (3) edition directe des champs (K-57),
// sans bouton « Modifier » par carte ; (4) la date d'effet se regle dans le
// brouillon et s'appliquera a la publication, au branchement du serveur.
// FI-R6 (a) (revue FI-VAGUE-R R6-08) : les sections se lisent rangee par
// rangee (gauche puis droite, puis la rangee suivante), l'en-tete de version
// tient sur une rangee sur ordinateur et l'historique passe en fin de page.
//
// FI-11c : l'historique des versions (lecture seule, la version active
// marquee) et, sous un brouillon, l'« Apercu avant publication » : un foyer
// de 1 a 5 enfants payants et le taux horaire d'une classe. Les montants de
// l'apercu sont ARRETES par le port (`apercuFamille`, `apercuEnseignant`) a
// partir du brouillon a l'ecran, relus a chaque saisie valide ; jamais
// calcules ici (garde de source dans le test).

import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_politiques_commerciales.dart';
import '../../core/finance/format_montant.dart';
import '../../core/finance/montant.dart';
import '../../core/finance/politique_commerciale.dart';
import '../../core/i18n/jour_du_mois.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
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
    FutureProvider<PolitiquesLues>((Ref ref) {
      surveillerPersonneConnectee(ref);
      return lirePolitiques(ref.watch(portPolitiquesCommercialesProvider));
    }, retry: (int retryCount, Object error) => null);

/// Vrai quand le serveur vient de confirmer une publication : le message
/// « Version publiee » survit a la relecture des versions, qui reconstruit le
/// contenu sur le nouveau brouillon. Oublie a la premiere saisie et a la
/// sortie de l'onglet.
class PublicationPolitiqueControleur extends Notifier<bool> {
  @override
  bool build() => false;

  /// Retient la publication confirmee.
  void confirmer() => state = true;

  /// Oublie la publication confirmee.
  void oublier() => state = false;
}

/// La publication confirmee de l'onglet en cours.
final NotifierProvider<PublicationPolitiqueControleur, bool>
publicationPolitiqueProvider =
    NotifierProvider.autoDispose<PublicationPolitiqueControleur, bool>(
      PublicationPolitiqueControleur.new,
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
    // Garde en vie la publication confirmee le temps de l'onglet.
    ref.watch(publicationPolitiqueProvider);
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
  classes,
  jours,

  /// Un repere de marge : saisi en pourcentage entier, rendu en pour mille.
  pourcent,
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
    if (v is int && nature == _Nature.pourcent) {
      // Un pour mille qui n'est pas un pourcentage entier reste en lecture.
      return v % 10 == 0 ? '${v ~/ 10}' : null;
    }
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
    if (nature == _Nature.pourcent) return unites * 10;
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

  /// La cle du groupe « Marge de reference » (ses trois reperes).
  static const Key margeKey = ValueKey<String>('fi-pol-marge');

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
enum _Publication {
  aucune,
  champsACorriger,
  indisponible,
  nonConfirmee,
  faite,
  refusee,
  invalide,
}

class _PolitiquesCommercialesContenuState
    extends ConsumerState<PolitiquesCommercialesContenu> {
  final Map<String, TextEditingController> _saisies =
      <String, TextEditingController>{};
  late _Publication _publication = ref.read(publicationPolitiqueProvider)
      ? _Publication.faite
      : _Publication.aucune;
  bool _enCours = false;

  /// L'activation de l'essai a l'ecran, dans un brouillon (guide §5.7,
  /// ECARTS D8 : un interrupteur).
  late bool _essaiActif = _lue.essaiActif;

  /// Le paiement web a l'ecran, dans un brouillon (FI-Q21.1).
  late bool _webActif = _lue.railsActifs.contains(RailPaiement.webStripe);

  /// La date d'effet a l'ecran, dans un brouillon (FI-Q21.4).
  late DateTime _dateEffet = _lue.dateEffet;

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
    if (_publication == _Publication.champsACorriger ||
        _publication == _Publication.faite) {
      _publication = _Publication.aucune;
      ref.read(publicationPolitiqueProvider.notifier).oublier();
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
      case 'classesMax':
        if (autre('classesObjectif') case final int objectif
            when s < objectif) {
          return pol.erreurClassesMax(objectif: pol.classes(n: objectif));
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
      case 'margeObjectif' || 'margeForte' || 'margeStretch':
        if (s > 100) return pol.erreurMargeMax;
        if (c.id == 'margeForte') {
          if (autre('margeObjectif') case final int objectif
              when (v as int) < objectif) {
            return pol.erreurMargeForte(
              objectif: _texteValeur(objectif, c.nature),
            );
          }
        }
        if (c.id == 'margeStretch') {
          if (autre('margeForte') case final int forte
              when (v as int) < forte) {
            return pol.erreurMargeStretch(forte: _texteValeur(forte, c.nature));
          }
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
        id: 'classesObjectif',
        libelle: pol.classesObjectif,
        consequence: pol.classesObjectifDetail,
        nature: _Nature.classes,
        lue: _lue.classesObjectif,
        active: a.classesObjectif,
      ),
      _Champ(
        id: 'classesMax',
        libelle: pol.classesMax,
        consequence: pol.classesMaxDetail,
        nature: _Nature.classes,
        lue: _lue.classesMax,
        active: a.classesMax,
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

  List<_Champ> _classes() {
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

  /// Les trois reperes de la marge de reference (guide §1.5), saisis en
  /// pourcentage entier dans un brouillon (FI-Q21.1).
  List<_Champ> _marge() {
    final pol = t.admin.finance.pol;
    final ({int objectif, int forte, int stretch}) m =
        _lue.margeReferencePourMille;
    final ({int objectif, int forte, int stretch}) a =
        widget.active.margeReferencePourMille;
    return <_Champ>[
      _Champ(
        id: 'margeObjectif',
        libelle: pol.margeObjectif,
        consequence: pol.margeObjectifDetail,
        nature: _Nature.pourcent,
        lue: m.objectif,
        active: a.objectif,
      ),
      _Champ(
        id: 'margeForte',
        libelle: pol.margeForte,
        consequence: pol.margeForteDetail,
        nature: _Nature.pourcent,
        lue: m.forte,
        active: a.forte,
      ),
      _Champ(
        id: 'margeStretch',
        libelle: pol.margeStretch,
        consequence: pol.margeStretchDetail,
        nature: _Nature.pourcent,
        lue: m.stretch,
        active: a.stretch,
      ),
    ];
  }

  List<_Champ> _tousLesChamps() => <_Champ>[
    ..._tarifs(),
    ..._essai(),
    ..._remises(),
    ..._enseignants(),
    ..._classes(),
    ..._paiement(),
    ..._marge(),
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
      dateEffet: _dateEffet,
      tarifEnfant: v['tarifEnfant']! as Montant,
      tarifAdulte: v['tarifAdulte']! as Montant,
      essaisMax: v['essais']! as int,
      essaiActif: _essaiActif,
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
      classesObjectif: v['classesObjectif']! as int,
      classesMax: v['classesMax']! as int,
      joursConservationPlace: v['conservation']! as int,
      margeReferencePourMille: (
        objectif: v['margeObjectif']! as int,
        forte: v['margeForte']! as int,
        stretch: v['margeStretch']! as int,
      ),
      railsActifs: _railsAEcran,
      allocationInternet: v['internet'] as Montant?,
      joursRelance: b.joursRelance,
      budgets: b.budgets,
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
      // Le serveur rend la version qu'il a inscrite (FAC-A-01) : la
      // publication est faite. Les versions sont relues pour proposer le
      // brouillon suivant.
      resultat = _Publication.faite;
    } on CapaciteIndisponible {
      resultat = _Publication.indisponible;
    } on PostgrestException catch (e) {
      // 42501 : hors direction en double verification ; 22023 : une valeur
      // refusee (date d'effet, numero, remise). Le reste n'est pas confirme.
      resultat = switch (e.code) {
        '42501' => _Publication.refusee,
        '22023' => _Publication.invalide,
        _ => _Publication.nonConfirmee,
      };
    } on Object {
      resultat = _Publication.nonConfirmee;
    }
    if (!mounted) return;
    setState(() {
      _enCours = false;
      _publication = resultat;
    });
    if (resultat == _Publication.faite) {
      ref.read(publicationPolitiqueProvider.notifier).confirmer();
      ref.invalidate(politiquesCommercialesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final pol = t.admin.finance.pol;
    // Les champs, puis la marge et les rails, lus sans champ.
    final int differences = _estBrouillon
        ? _tousLesChamps().where(_differe).length +
              (_essaiDiffere ? 1 : 0) +
              (_railsDifferent ? 1 : 0) +
              (_dateModifiee ? 1 : 0) +
              (_relancesDifferent ? 1 : 0) +
              (_budgetsDifferent ? 1 : 0)
        : 0;

    final List<Widget> sections = <Widget>[
      _section(pol.tarifs, pol.tarifsDetail, <Widget>[
        for (final _Champ c in _tarifs()) _ligne(c),
      ]),
      _section(pol.essai, pol.essaiDetail, <Widget>[
        _ligneActivationEssai(),
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
      _section(pol.sectionClasses, pol.sectionClassesDetail, <Widget>[
        for (final _Champ c in _classes()) _ligne(c),
      ]),
      _section(pol.paiement, pol.paiementDetail, <Widget>[
        _ligneRailWeb(),
        for (final String rail in <String>[pol.railIos, pol.railAndroid])
          LigneCleValeur(
            key: PolitiquesCommercialesContenu.champKey(
              rail == pol.railIos ? 'railIos' : 'railAndroid',
            ),
            cle: rail,
            detailCle: pol.railMobileDetail,
            valeur: pol.railPrepare,
          ),
        for (final _Champ c in _paiement()) _ligne(c),
        ..._lignesRelance(),
      ]),
      _section(pol.pilotage, pol.pilotageDetail, <Widget>[
        _groupeMarge(),
        ..._lignesBudgets(),
      ]),
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
          dateEffet: _dateEffet,
          onChangerDate: _estBrouillon ? _changerDate : null,
          differences: differences,
        ),
        Ecart.vXxl,
        // Rangee par rangee (revue FI-VAGUE-R R6-08) : l'ordre de lecture
        // suit l'ordre du guide §5.7, a gauche puis a droite, et jamais une
        // colonne entiere avant l'autre.
        LayoutBuilder(
          builder: (BuildContext contexte, BoxConstraints contraintes) {
            if (_enColonne(contexte, contraintes)) {
              return PileCartes(children: sections);
            }
            return PileCartes(
              children: <Widget>[
                for (int i = 0; i < sections.length; i += 2)
                  PileCartes(
                    axe: Axis.horizontal,
                    alignement: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: sections[i]),
                      Expanded(
                        child: i + 1 < sections.length
                            ? sections[i + 1]
                            : const SizedBox.shrink(),
                      ),
                    ],
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
        // L'historique en fin de page (R6-08) : il ne remplit plus le
        // premier ecran sur ordinateur.
        Ecart.vXxl,
        _Historique(
          key: PolitiquesCommercialesContenu.historiqueKey,
          versions: widget.versions,
          active: widget.active,
        ),
      ],
    );
  }

  /// Vrai quand la date d'effet du brouillon a ete changee a l'ecran : elle
  /// compte alors parmi les differences (contre-revue FI-DIR-1). Sa date
  /// lue n'y compte pas : un brouillon a toujours une date posterieure a
  /// celle de la version active, ce ne serait jamais « aucune difference ».
  bool get _dateModifiee => _estBrouillon && _dateEffet != _lue.dateEffet;

  /// Le groupe « Marge de reference » : son titre, lu et visible, sa phrase,
  /// puis ses trois reperes (FI-Q21.1).
  Widget _groupeMarge() {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final pol = t.admin.finance.pol;
    final List<_Champ> champs = _marge();
    return Semantics(
      key: PolitiquesCommercialesContenu.margeKey,
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(pol.marge, style: textes.titleSmall),
          ),
          Ecart.vXs,
          Text(
            pol.margeDetail,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          for (final _Champ c in champs) ...<Widget>[
            Ecart.vSm,
            const FiletCarte(),
            Ecart.vSm,
            _ligne(c),
          ],
        ],
      ),
    );
  }

  /// Ouvre le calendrier et regle la date d'effet du brouillon (FI-Q21.4) :
  /// a partir du lendemain, jamais retroactive (guide §1.3). Les bornes
  /// tiennent toujours la date de depart : une date d'effet deja posee
  /// au-dela de la borne technique l'etend, une date passee part du
  /// lendemain ; le calendrier ne peut donc jamais lever d'assertion.
  Future<void> _changerDate() async {
    final DateTime maintenant = DateTime.now();
    final DateTime premier = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day + 1,
    );
    final DateTime initiale = _dateEffet.isBefore(premier)
        ? premier
        : _dateEffet;
    final DateTime borne = DateTime(maintenant.year + 5, 12, 31);
    final DateTime dernier = initiale.isAfter(borne) ? initiale : borne;
    final DateTime choisie =
        await showDatePicker(
          context: context,
          initialDate: initiale,
          firstDate: premier,
          lastDate: dernier,
          helpText: t.admin.finance.pol.changerDate,
        ) ??
        _dateEffet;
    if (!mounted || choisie == _dateEffet) return;
    setState(() => _dateEffet = choisie);
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
      _Publication.faite => (
        pol.publicationFaite,
        pol.publicationFaiteDetail,
        TonEtat.succes,
      ),
      _Publication.refusee => (
        pol.publicationRefusee,
        pol.publicationRefuseeDetail,
        TonEtat.alerte,
      ),
      _Publication.invalide => (
        pol.publicationInvalide,
        pol.publicationInvalideDetail,
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

  /// Vrai quand l'activation de l'essai a l'ecran differe de l'active.
  bool get _essaiDiffere =>
      _estBrouillon && _essaiActif != widget.active.essaiActif;

  /// Vrai quand les relances du brouillon different de l'active.
  bool get _relancesDifferent =>
      _estBrouillon &&
      !listEquals(_lue.joursRelance, widget.active.joursRelance);

  /// Vrai quand les budgets du brouillon different de l'active.
  bool get _budgetsDifferent =>
      _estBrouillon && !listEquals(_lue.budgets, widget.active.budgets);

  /// L'activation de l'essai en mots.
  String _texteEssai(bool actif) => actif
      ? t.admin.finance.pol.essaiActive
      : t.admin.finance.pol.essaiDesactive;

  /// L'activation de l'essai : un interrupteur dans un brouillon (ECARTS
  /// D8), une ligne lue sinon (revue FI-VAGUE-R R6-06).
  Widget _ligneActivationEssai() {
    final pol = t.admin.finance.pol;
    final Widget? comparaison = _essaiDiffere
        ? _texteComparaison(
            'essaiActif',
            _texteEssai(widget.active.essaiActif),
            chiffres: false,
          )
        : null;
    if (!_estBrouillon) {
      return LigneCleValeur(
        key: PolitiquesCommercialesContenu.champKey('essaiActif'),
        cle: pol.essaiActivation,
        detailCle: pol.essaiActivationDetail,
        valeur: _texteEssai(_lue.essaiActif),
      );
    }
    return _InterrupteurPolitique(
      key: PolitiquesCommercialesContenu.champKey('essaiActif'),
      libelle: pol.essaiActivation,
      consequence: pol.essaiActivationDetail,
      etat: _texteEssai(_essaiActif),
      valeur: _essaiActif,
      onChanged: (bool v) => setState(() {
        _essaiActif = v;
        if (_publication == _Publication.champsACorriger) {
          _publication = _Publication.aucune;
        }
      }),
      comparaison: comparaison,
    );
  }

  /// Les regles de relance (guide §5.7 « regles de relance visibles »,
  /// ECARTS D7) : une ligne par relance, ou « Pas encore fixées ». Lues,
  /// jamais un champ : FI-Q21 n'ouvre au brouillon que la marge et le paiement
  /// web (decide par delegation le 05/10).
  List<Widget> _lignesRelance() {
    final pol = t.admin.finance.pol;
    final List<int>? jours = _lue.joursRelance;
    final Widget? comparaison = _relancesDifferent
        ? _texteComparaison(
            'relances',
            _texteRelances(widget.active.joursRelance),
            chiffres: false,
          )
        : null;
    if (jours == null || jours.isEmpty) {
      return <Widget>[
        LigneCleValeur(
          key: PolitiquesCommercialesContenu.champKey('relances'),
          cle: pol.relances,
          detailCle: pol.relancesDetail,
          valeur: pol.relancesNonFixees,
          complement: comparaison,
        ),
      ];
    }
    return <Widget>[
      for (int i = 0; i < jours.length; i++)
        LigneCleValeur(
          key: PolitiquesCommercialesContenu.champKey('relance-${i + 1}'),
          cle: pol.relanceRang(rang: '${i + 1}'),
          detailCle: i == 0 ? pol.relancesDetail : null,
          valeur: pol.relanceApres(
            jours: LibellesGroupe.insecable(pol.jours(n: jours[i])),
          ),
          chiffres: true,
          complement: i == jours.length - 1 ? comparaison : null,
        ),
    ];
  }

  /// Les relances de [jours] en une phrase, pour la comparaison.
  String _texteRelances(List<int>? jours) {
    final pol = t.admin.finance.pol;
    if (jours == null || jours.isEmpty) return pol.relancesNonFixees;
    return <String>[
      for (int i = 0; i < jours.length; i++)
        pol.relanceComparaison(
          rang: pol.relanceRang(rang: '${i + 1}'),
          apres: pol.relanceApres(
            jours: LibellesGroupe.insecable(pol.jours(n: jours[i])),
          ),
        ),
    ].join(pol.separateurComparaison);
  }

  /// Les budgets de pilotage, **non contraignants** (guide §5.7, ECARTS
  /// D5) : une ligne par budget, ou « Pas encore fixés ». Lus, jamais un
  /// champ : FI-Q21 n'ouvre au brouillon que la marge et le paiement web
  /// (decide par delegation le 05/10).
  List<Widget> _lignesBudgets() {
    final pol = t.admin.finance.pol;
    final List<BudgetPilotage> budgets = _lue.budgets;
    final Widget? comparaison = _budgetsDifferent
        ? _texteComparaison(
            'budgets',
            _texteBudgets(widget.active.budgets),
            chiffres: false,
          )
        : null;
    if (budgets.isEmpty) {
      return <Widget>[
        LigneCleValeur(
          key: PolitiquesCommercialesContenu.champKey('budgets'),
          cle: pol.budgets,
          detailCle: pol.budgetsDetail,
          valeur: pol.budgetsNonFixes,
          complement: comparaison,
        ),
      ];
    }
    return <Widget>[
      for (int i = 0; i < budgets.length; i++)
        LigneCleValeur(
          key: PolitiquesCommercialesContenu.champKey(
            'budget-${budgets[i].nature.name}',
          ),
          cle: _libelleBudget(budgets[i].nature),
          detailCle: i == 0 ? pol.budgetsDetail : null,
          valeur: pol.budgetValeur(
            valeur: pourMilleEnTexte(budgets[i].pourMille),
          ),
          chiffres: true,
          complement: i == budgets.length - 1 ? comparaison : null,
        ),
    ];
  }

  String _libelleBudget(NatureBudget nature) => switch (nature) {
    NatureBudget.marketing => t.admin.finance.pol.budgetMarketing,
    NatureBudget.operationnel => t.admin.finance.pol.budgetOperationnel,
  };

  /// Les budgets de [budgets] en une phrase, pour la comparaison.
  String _texteBudgets(List<BudgetPilotage> budgets) {
    final pol = t.admin.finance.pol;
    if (budgets.isEmpty) return pol.budgetsNonFixes;
    return <String>[
      for (final BudgetPilotage b in budgets)
        pol.budgetComparaison(
          libelle: _libelleBudget(b.nature),
          valeur: pol.budgetValeur(valeur: pourMilleEnTexte(b.pourMille)),
        ),
    ].join(pol.separateurComparaison);
  }

  /// Les rails du brouillon a l'ecran : le paiement web selon son
  /// interrupteur, les autres rails tels que le brouillon les porte.
  Set<RailPaiement> get _railsAEcran => <RailPaiement>{
    for (final RailPaiement r in _lue.railsActifs)
      if (r != RailPaiement.webStripe) r,
    if (_webActif) RailPaiement.webStripe,
  };

  /// Vrai quand les rails actifs a l'ecran different de l'active.
  bool get _railsDifferent =>
      _estBrouillon && !setEquals(_railsAEcran, widget.active.railsActifs);

  /// Le rail web en mots : actif ou inactif.
  String _texteRailWeb(bool actif) =>
      actif ? t.admin.finance.pol.railActif : t.admin.finance.pol.railInactif;

  /// Le paiement web : un interrupteur dans un brouillon (FI-Q21.1), une
  /// ligne lue sinon.
  Widget _ligneRailWeb() {
    final pol = t.admin.finance.pol;
    final bool actifEnVigueur = widget.active.railsActifs.contains(
      RailPaiement.webStripe,
    );
    if (!_estBrouillon) {
      return LigneCleValeur(
        key: PolitiquesCommercialesContenu.champKey('rails'),
        cle: pol.railWeb,
        detailCle: pol.railWebDetail,
        valeur: _texteRailWeb(
          _lue.railsActifs.contains(RailPaiement.webStripe),
        ),
      );
    }
    return _InterrupteurPolitique(
      key: PolitiquesCommercialesContenu.champKey('rails'),
      libelle: pol.railWeb,
      consequence: pol.railWebDetail,
      etat: _texteRailWeb(_webActif),
      valeur: _webActif,
      onChanged: (bool v) => setState(() {
        _webActif = v;
        if (_publication == _Publication.champsACorriger) {
          _publication = _Publication.aucune;
        }
      }),
      comparaison: _railsDifferent
          ? _texteComparaison(
              'rails',
              _texteRailWeb(actifEnVigueur),
              chiffres: false,
            )
          : null,
    );
  }

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
      _Nature.classes => pol.uniteClasses,
      _Nature.jours => pol.uniteJours,
      _Nature.pourcent => pol.unitePourcent,
    };
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
      _Nature.pourcent => pol.pourcentValeur(valeur: pourMilleEnTexte(n)),
      _Nature.eleves => pol.eleves(n: n),
      _Nature.seances => pol.seances(n: n),
      _Nature.classes => pol.classes(n: n),
      _ => LibellesGroupe.insecable(pol.jours(n: n)),
    },
    _ => '$valeur',
  };
}

/// Une date d'effet en mots : « 1er octobre 2026 » (R8-05).
String dateEffetEnTexte(DateTime date) => t.admin.finance.pol.date(
  jour: jourDuMois(date.day),
  mois: t.commun.dates.mois[date.month - 1],
  annee: '${date.year}',
);

/// L'en-tete de version (PolicyVersionHeader) : le brouillon et sa date
/// d'effet (reglable, FI-Q21.4), la version active, et ce qui les
/// distingue ; ou la seule version active quand aucun brouillon n'est
/// ouvert. Sur ordinateur, une seule rangee (revue FI-VAGUE-R R6-08) : il ne
/// remplit plus le premier ecran.
class _EnteteVersion extends StatelessWidget {
  const _EnteteVersion({
    required this.active,
    required this.brouillon,
    required this.dateEffet,
    required this.onChangerDate,
    required this.differences,
    super.key,
  });

  final PolitiqueCommerciale active;
  final PolitiqueCommerciale? brouillon;

  /// La date d'effet du brouillon a l'ecran.
  final DateTime dateEffet;

  /// Ouvre le calendrier de la date d'effet ; nul hors brouillon.
  final VoidCallback? onChangerDate;
  final int differences;

  /// La cle de « Changer la date d'effet ».
  static const Key changerDateKey = ValueKey<String>('fi-pol-changer-date');

  /// La cle de la date d'effet du brouillon.
  static const Key dateEffetKey = ValueKey<String>('fi-pol-date-effet');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final pol = t.admin.finance.pol;
    final TextStyle attenue = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    Widget version(
      StatusPill pastille,
      String titre,
      String detail, {
      Key? cleDetail,
    }) => MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          pastille,
          Ecart.vSm,
          Text(titre, style: textes.titleMedium),
          Ecart.vXs,
          Text(detail, key: cleDetail, style: attenue),
        ],
      ),
    );
    final Widget versionActive = version(
      StatusPill(libelle: pol.statutPubliee, ton: TonEtat.succes),
      pol.versionActive(version: active.version),
      pol.enVigueur(date: dateEffetEnTexte(active.dateEffet)),
    );
    final PolitiqueCommerciale? b = brouillon;
    final VoidCallback? changer = onChangerDate;
    final Widget? versionBrouillon = b == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              version(
                StatusPill(
                  libelle: pol.statutBrouillon,
                  ton: TonEtat.avertissement,
                ),
                pol.versionBrouillon(version: b.version),
                pol.dateEffet(date: dateEffetEnTexte(dateEffet)),
                cleDetail: dateEffetKey,
              ),
              Ecart.vXs,
              Text(pol.dateEffetDetail, style: attenue),
              Ecart.vXs,
              Text(pol.dateEffetReglable, style: attenue),
              if (changer != null) ...<Widget>[
                Ecart.vSm,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LienFleche(
                    key: changerDateKey,
                    libelle: pol.changerDate,
                    onPress: changer,
                  ),
                ),
              ],
            ],
          );
    final Widget etat = b != null
        ? Column(
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
        : Text(pol.sansBrouillon, style: textes.bodyLarge);
    final List<Widget> blocs = <Widget>[?versionBrouillon, versionActive, etat];
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        if (_enColonne(contexte, contraintes)) {
          return CarteGroupee(sections: blocs);
        }
        return AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < blocs.length; i++) ...<Widget>[
                if (i > 0) Ecart.hXl,
                Expanded(child: blocs[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Un reglage oui ou non d'un brouillon (activation de l'essai) : libelle,
/// consequence (K-58), etat en mots et interrupteur, en un seul noeud pour
/// le lecteur d'ecran.
class _InterrupteurPolitique extends StatelessWidget {
  const _InterrupteurPolitique({
    required this.libelle,
    required this.consequence,
    required this.etat,
    required this.valeur,
    required this.onChanged,
    required this.comparaison,
    super.key,
  });

  final String libelle;
  final String consequence;

  /// L'etat en mots (« Activé », « Désactivé ») : jamais l'interrupteur seul.
  final String etat;
  final bool valeur;
  final ValueChanged<bool> onChanged;
  final Widget? comparaison;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MergeSemantics(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Ecart.vXs,
                    Text(etat, style: textes.bodyMedium),
                  ],
                ),
              ),
              Ecart.hMd,
              Switch.adaptive(value: valeur, onChanged: onChanged),
            ],
          ),
        ),
        if (comparaison case final Widget c) ...<Widget>[Ecart.vXs, c],
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
          // Choix de formulaire, pas un filtre : le nombre d'enfants de l'apercu.
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
          // Choix de formulaire, pas un filtre : le type de classe de l'apercu.
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
          valeurEnFin: true,
        ),
        LigneCleValeur(
          cle: pol.apercuOccupation,
          detailCle: pol.apercuOccupationDetail(
            eligibles: '${a.eligibles}',
            capacite: '${a.capacite}',
          ),
          valeur: parHeure(a.occupation),
          chiffres: true,
          valeurEnFin: true,
        ),
        LigneCleValeur(
          key: PolitiquesCommercialesContenu.apercuTauxKey,
          cle: pol.apercuTaux,
          detailCle: pol.apercuTauxDetail(plafond: parHeure(a.plafondHoraire)),
          valeur: parHeure(a.tauxHoraire),
          chiffres: true,
          valeurForte: true,
          valeurEnFin: true,
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
