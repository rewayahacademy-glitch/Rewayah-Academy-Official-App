// PRAXIS-VISIBLE : ce que Praxis a fait sur les dossiers des candidats
// enseignants, lu par la direction. Trois lectures du serveur, reservees a la
// direction, deja installees :
//
//  - `direction_praxis_rangements(pile, limite, decalage)` (PX-3) : la pile ou
//    Praxis a range chaque dossier encore en cours, et sa raison ;
//  - `direction_praxis_impressions(etiquette, limite, decalage)` (PX-4) :
//    l'impression courante de Praxis sur un dossier (etiquette, criteres,
//    confiance, contexte, synthese, texte) ;
//  - `direction_praxis_objectifs(filtre, limite, decalage)` (PX-3) : les
//    objectifs du jour et de la semaine que Praxis se fixe.
//
// **Rien n'est calcule ici** : l'ecran montre ce que le serveur rend, mot pour
// mot. Une lecture qui echoue reste une ERREUR (jamais « aucun dossier ») ; un
// refus du serveur (`42501`, lecteur qui n'est pas la direction) devient
// [PermissionInsuffisante] : l'ecran se tait alors au lieu de dire une panne.
//
// Ce qui MANQUE au serveur (dit dans le rapport du lot) : aucune des deux
// lectures ne filtre par reference de dossier. Le dossier lit donc toutes les
// pages (200 lignes par appel) et retient la sienne, comme les propositions de
// Praxis (PX-2) le font deja ; la liste des candidatures, paginee au serveur,
// ne peut pas etre filtree par pile ou par etiquette sans un nouveau parametre
// de `lister_candidatures` : d'ou la page « Le travail de Praxis ».
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/permission_insuffisante.dart';

/// Les quatre piles ou Praxis range un dossier (liste fermee du serveur).
enum PilePraxis {
  /// Tout est la : la direction peut decider.
  pretADecider('pret_a_decider'),

  /// Il manque une piece ou une reponse.
  incomplet('incomplet'),

  /// Le candidat ne s'est pas manifeste depuis longtemps.
  sansNouvelles('sans_nouvelles'),

  /// Praxis demande a la direction de regarder.
  aRegarder('a_regarder');

  const PilePraxis(this.sql);

  /// La valeur du serveur, et celle de l'adresse.
  final String sql;

  /// La pile de la valeur [brut], ou `null` : une valeur inconnue n'est pas
  /// inventee.
  static PilePraxis? depuisSql(Object? brut) {
    for (final PilePraxis p in values) {
      if (p.sql == brut) return p;
    }
    return null;
  }
}

/// L'etiquette d'une impression (liste fermee du serveur), dans l'ordre du
/// serveur.
enum EtiquettePraxis {
  /// Un dossier remarquable.
  pepite('pepite'),

  /// Un dossier solide.
  solide('solide'),

  /// Un dossier a creuser.
  aCreuser('a_creuser'),

  /// Un dossier avec des reserves.
  reserve('reserve');

  const EtiquettePraxis(this.sql);

  /// La valeur du serveur, et celle de l'adresse.
  final String sql;

  /// L'etiquette de la valeur [brut], ou `null`.
  static EtiquettePraxis? depuisSql(Object? brut) {
    for (final EtiquettePraxis e in values) {
      if (e.sql == brut) return e;
    }
    return null;
  }
}

/// La confiance de Praxis dans son impression.
enum ConfiancePraxis {
  /// Faible.
  faible,

  /// Moyenne.
  moyenne,

  /// Forte.
  forte;

  /// La confiance de la valeur [brut], ou `null`.
  static ConfiancePraxis? depuisSql(Object? brut) {
    for (final ConfiancePraxis c in values) {
      if (c.name == brut) return c;
    }
    return null;
  }
}

/// Les cinq criteres qu'une impression peut noter de 1 a 5, dans l'ordre du
/// serveur. Chacun est facultatif.
enum CriterePraxis {
  /// La maitrise.
  maitrise,

  /// La pedagogie.
  pedagogie,

  /// La vision.
  vision,

  /// Le comportement.
  comportement,

  /// La disponibilite.
  disponibilite,
}

/// L'effet d'un element du contexte (liste fermee du serveur).
enum EffetContexte {
  /// Un atout.
  atout('atout'),

  /// Un risque.
  risque('risque'),

  /// A verifier.
  aVerifier('a_verifier');

  const EffetContexte(this.sql);

  /// La valeur du serveur.
  final String sql;

  /// L'effet de la valeur [brut], ou `null`.
  static EffetContexte? depuisSql(Object? brut) {
    for (final EffetContexte e in values) {
      if (e.sql == brut) return e;
    }
    return null;
  }
}

DateTime? _instant(Object? brut) =>
    brut is String ? DateTime.tryParse(brut)?.toUtc() : null;

String? _texte(Object? brut) {
  if (brut is! String) return null;
  final String t = brut.trim();
  return t.isEmpty ? null : t;
}

/// Le rangement courant d'un dossier.
@immutable
class RangementPraxis {
  /// Cree le rangement.
  const RangementPraxis({
    required this.reference,
    required this.nom,
    required this.pile,
    required this.raison,
    required this.rangeLe,
    this.enPause = false,
  });

  /// Lit une ligne du serveur, ou `null` quand elle est illisible.
  static RangementPraxis? depuisJson(Object? brut) {
    if (brut is! Map<String, dynamic>) return null;
    final Object? reference = brut['reference'];
    final PilePraxis? pile = PilePraxis.depuisSql(brut['pile']);
    final DateTime? le = _instant(brut['rangeLe']);
    if (reference is! String || pile == null || le == null) return null;
    return RangementPraxis(
      reference: reference,
      nom: _texte(brut['nom']) ?? '',
      pile: pile,
      raison: _texte(brut['raison']) ?? '',
      rangeLe: le,
      enPause: brut['enPause'] == true,
    );
  }

  /// La reference du dossier (`CAND-...`).
  final String reference;

  /// Le nom du candidat, tel que la direction le lit deja.
  final String nom;

  /// La pile.
  final PilePraxis pile;

  /// La raison ecrite par Praxis (200 signes au plus), mot pour mot.
  final String raison;

  /// Quand Praxis a range le dossier.
  final DateTime rangeLe;

  /// Le dossier est en pause.
  final bool enPause;
}

/// Un element du contexte d'une impression.
@immutable
class ElementContexte {
  /// Cree l'element.
  const ElementContexte({
    required this.theme,
    required this.constat,
    required this.source,
    required this.effet,
  });

  /// Lit un element, ou `null` quand il est illisible.
  static ElementContexte? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final String? theme = _texte(brut['theme']);
    final String? constat = _texte(brut['constat']);
    final EffetContexte? effet = EffetContexte.depuisSql(brut['effet']);
    if (theme == null || constat == null || effet == null) return null;
    return ElementContexte(
      theme: theme,
      constat: constat,
      source: _texte(brut['source']) ?? '',
      effet: effet,
    );
  }

  /// Le theme (libre).
  final String theme;

  /// Le constat.
  final String constat;

  /// La source (quelle reponse du dossier, quel message).
  final String source;

  /// L'effet.
  final EffetContexte effet;
}

/// La synthese d'une impression : cinq champs, tous facultatifs.
@immutable
class SynthesePraxis {
  /// Cree la synthese.
  const SynthesePraxis({
    this.utilePour,
    this.situation,
    this.reserves,
    this.video,
    this.videoPourquoi,
  });

  /// Lit la synthese, ou `null` quand elle est absente ou vide.
  static SynthesePraxis? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final SynthesePraxis s = SynthesePraxis(
      utilePour: _texte(brut['utile_pour']),
      situation: _texte(brut['situation']),
      reserves: _texte(brut['reserves']),
      video: brut['video'] is bool ? brut['video'] as bool : null,
      videoPourquoi: _texte(brut['video_pourquoi']),
    );
    return s.estVide ? null : s;
  }

  /// A quoi le candidat serait utile.
  final String? utilePour;

  /// Dans quelle situation.
  final String? situation;

  /// Les reserves.
  final String? reserves;

  /// A voir en video : oui, non, ou `null` (non dit).
  final bool? video;

  /// Pourquoi le voir (ou non) en video.
  final String? videoPourquoi;

  /// Aucun champ n'est rempli.
  bool get estVide =>
      utilePour == null &&
      situation == null &&
      reserves == null &&
      video == null &&
      videoPourquoi == null;
}

/// L'impression courante de Praxis sur un dossier.
@immutable
class ImpressionPraxis {
  /// Cree l'impression.
  const ImpressionPraxis({
    required this.reference,
    required this.nom,
    required this.etiquette,
    required this.confiance,
    required this.texte,
    required this.noteeLe,
    this.notes = const <CriterePraxis, int>{},
    this.contexte = const <ElementContexte>[],
    this.synthese,
  });

  /// Lit une ligne du serveur, ou `null` quand elle est illisible.
  static ImpressionPraxis? depuisJson(Object? brut) {
    if (brut is! Map<String, dynamic>) return null;
    final Object? reference = brut['reference'];
    final EtiquettePraxis? etiquette = EtiquettePraxis.depuisSql(
      brut['etiquette'],
    );
    final ConfiancePraxis? confiance = ConfiancePraxis.depuisSql(
      brut['confiance'],
    );
    final DateTime? le = _instant(brut['noteeLe']);
    if (reference is! String ||
        etiquette == null ||
        confiance == null ||
        le == null) {
      return null;
    }
    final Object? notes = brut['notes'];
    final Object? contexte = brut['contexte'];
    return ImpressionPraxis(
      reference: reference,
      nom: _texte(brut['nom']) ?? '',
      etiquette: etiquette,
      confiance: confiance,
      texte: _texte(brut['texte']) ?? '',
      noteeLe: le,
      notes: <CriterePraxis, int>{
        if (notes is Map)
          for (final CriterePraxis c in CriterePraxis.values)
            if (notes[c.name] case final num n when n >= 1 && n <= 5)
              c: n.toInt(),
      },
      contexte: <ElementContexte>[
        if (contexte is List)
          for (final Object? e in contexte) ?ElementContexte.depuisJson(e),
      ],
      synthese: SynthesePraxis.depuisJson(brut['synthese']),
    );
  }

  /// La reference du dossier (`CAND-...`).
  final String reference;

  /// Le nom du candidat.
  final String nom;

  /// L'etiquette.
  final EtiquettePraxis etiquette;

  /// La confiance.
  final ConfiancePraxis confiance;

  /// Le texte court ecrit par Praxis (800 signes au plus), mot pour mot.
  final String texte;

  /// Quand Praxis l'a notee.
  final DateTime noteeLe;

  /// Les criteres notes, et eux seuls.
  final Map<CriterePraxis, int> notes;

  /// Le contexte (12 elements au plus).
  final List<ElementContexte> contexte;

  /// La synthese, ou `null`.
  final SynthesePraxis? synthese;
}

/// La periode d'un objectif.
enum PeriodeObjectif {
  /// Un objectif du jour.
  jour,

  /// Un objectif de la semaine.
  semaine,
}

/// L'etat d'un objectif.
enum EtatObjectif {
  /// Ouvert.
  ouvert,

  /// Atteint.
  atteint,

  /// Abandonne.
  abandonne,
}

/// Un objectif que Praxis s'est fixe.
@immutable
class ObjectifPraxis {
  /// Cree l'objectif.
  const ObjectifPraxis({
    required this.id,
    required this.periode,
    required this.debut,
    required this.libelle,
    required this.etat,
    required this.creeLe,
    this.cible,
    this.noteCloture,
    this.closLe,
    this.echu = false,
  });

  /// Lit une ligne du serveur, ou `null` quand elle est illisible.
  static ObjectifPraxis? depuisJson(Object? brut) {
    if (brut is! Map<String, dynamic>) return null;
    final Object? id = brut['id'];
    final PeriodeObjectif? periode = switch (brut['periode']) {
      'jour' => PeriodeObjectif.jour,
      'semaine' => PeriodeObjectif.semaine,
      _ => null,
    };
    final EtatObjectif? etat = switch (brut['etat']) {
      'ouvert' => EtatObjectif.ouvert,
      'atteint' => EtatObjectif.atteint,
      'abandonne' => EtatObjectif.abandonne,
      _ => null,
    };
    final DateTime? debut = brut['debut'] is String
        ? DateTime.tryParse(brut['debut'] as String)
        : null;
    final String? libelle = _texte(brut['libelle']);
    final DateTime? cree = _instant(brut['creeLe']);
    if (id is! String ||
        periode == null ||
        etat == null ||
        debut == null ||
        libelle == null ||
        cree == null) {
      return null;
    }
    return ObjectifPraxis(
      id: id,
      periode: periode,
      debut: DateTime(debut.year, debut.month, debut.day),
      libelle: libelle,
      etat: etat,
      creeLe: cree,
      cible: (brut['cible'] as num?)?.toInt(),
      noteCloture: _texte(brut['noteCloture']),
      closLe: _instant(brut['closLe']),
      echu: brut['echu'] == true,
    );
  }

  /// L'identifiant.
  final String id;

  /// Jour ou semaine.
  final PeriodeObjectif periode;

  /// Le jour vise, ou le lundi de la semaine visee (date du serveur).
  final DateTime debut;

  /// Le libelle ecrit par Praxis (200 signes au plus), mot pour mot.
  final String libelle;

  /// L'etat.
  final EtatObjectif etat;

  /// Quand Praxis l'a fixe.
  final DateTime creeLe;

  /// La cible chiffree, ou `null`.
  final int? cible;

  /// La note de cloture ecrite par Praxis, ou `null`.
  final String? noteCloture;

  /// Quand Praxis l'a clos, ou `null`.
  final DateTime? closLe;

  /// Ouvert et sa periode est passee (calcule par le serveur).
  final bool echu;
}

/// Une page de rangements : les lignes, le total du filtre, et le nombre par
/// pile (tous les dossiers visibles du lecteur, quel que soit le filtre).
@immutable
class PageRangements {
  /// Cree la page.
  const PageRangements({
    required this.lignes,
    required this.total,
    required this.parPile,
  });

  /// Les lignes.
  final List<RangementPraxis> lignes;

  /// Le total du filtre.
  final int total;

  /// Le nombre par pile.
  final Map<PilePraxis, int> parPile;
}

/// Une page d'impressions : les lignes, le total du filtre, le nombre par
/// etiquette.
@immutable
class PageImpressions {
  /// Cree la page.
  const PageImpressions({
    required this.lignes,
    required this.total,
    required this.parEtiquette,
  });

  /// Les lignes.
  final List<ImpressionPraxis> lignes;

  /// Le total du filtre.
  final int total;

  /// Le nombre par etiquette.
  final Map<EtiquettePraxis, int> parEtiquette;
}

/// L'acces de la direction au travail de Praxis.
abstract interface class ServiceTravailPraxis {
  /// Une page de rangements (les plus recents d'abord).
  Future<PageRangements> rangements({
    PilePraxis? pile,
    int limite = 200,
    int decalage = 0,
  });

  /// Une page d'impressions (par etiquette, puis note de vision).
  Future<PageImpressions> impressions({
    EtiquettePraxis? etiquette,
    int limite = 200,
    int decalage = 0,
  });

  /// Les objectifs : les ouverts seuls, ou tous ([tous]).
  Future<List<ObjectifPraxis>> objectifs({
    bool tous = true,
    int limite = 50,
    int decalage = 0,
  });
}

/// L'implementation Supabase.
class ServiceTravailPraxisSupabase implements ServiceTravailPraxis {
  /// Cree le service.
  ServiceTravailPraxisSupabase(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> _lire(
    String fonction,
    Map<String, dynamic> params,
  ) async {
    final Object? rendu;
    try {
      rendu = await _client.rpc<Object?>(fonction, params: params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(fonction);
      rethrow;
    }
    if (rendu is! Map<String, dynamic>) {
      throw FormatException('$fonction illisible');
    }
    return rendu;
  }

  static Map<E, int> _comptes<E>(Object? brut, E? Function(Object?) lire) =>
      <E, int>{
        if (brut is Map)
          for (final MapEntry<Object?, Object?> e in brut.entries)
            if (lire(e.key) case final E cle)
              if (e.value case final num n) cle: n.toInt(),
      };

  @override
  Future<PageRangements> rangements({
    PilePraxis? pile,
    int limite = 200,
    int decalage = 0,
  }) async {
    final Map<String, dynamic> r = await _lire(
      'direction_praxis_rangements',
      <String, dynamic>{
        'p_pile': pile?.sql,
        'p_limite': limite,
        'p_decalage': decalage,
      },
    );
    if (r['rangements'] is! List) {
      throw const FormatException('rangements illisibles');
    }
    return PageRangements(
      lignes: <RangementPraxis>[
        for (final Object? l in r['rangements'] as List)
          ?RangementPraxis.depuisJson(l),
      ],
      total: (r['total'] as num?)?.toInt() ?? 0,
      parPile: _comptes<PilePraxis>(r['parPile'], PilePraxis.depuisSql),
    );
  }

  @override
  Future<PageImpressions> impressions({
    EtiquettePraxis? etiquette,
    int limite = 200,
    int decalage = 0,
  }) async {
    final Map<String, dynamic> r = await _lire(
      'direction_praxis_impressions',
      <String, dynamic>{
        'p_etiquette': etiquette?.sql,
        'p_limite': limite,
        'p_decalage': decalage,
      },
    );
    if (r['impressions'] is! List) {
      throw const FormatException('impressions illisibles');
    }
    return PageImpressions(
      lignes: <ImpressionPraxis>[
        for (final Object? l in r['impressions'] as List)
          ?ImpressionPraxis.depuisJson(l),
      ],
      total: (r['total'] as num?)?.toInt() ?? 0,
      parEtiquette: _comptes<EtiquettePraxis>(
        r['parEtiquette'],
        EtiquettePraxis.depuisSql,
      ),
    );
  }

  @override
  Future<List<ObjectifPraxis>> objectifs({
    bool tous = true,
    int limite = 50,
    int decalage = 0,
  }) async {
    final Map<String, dynamic> r = await _lire(
      'direction_praxis_objectifs',
      <String, dynamic>{
        'p_filtre': tous ? 'tous' : 'ouverts',
        'p_limite': limite,
        'p_decalage': decalage,
      },
    );
    if (r['objectifs'] is! List) {
      throw const FormatException('objectifs illisibles');
    }
    return <ObjectifPraxis>[
      for (final Object? l in r['objectifs'] as List)
        ?ObjectifPraxis.depuisJson(l),
    ];
  }
}

/// Le service du travail de Praxis.
final Provider<ServiceTravailPraxis> serviceTravailPraxisProvider =
    Provider<ServiceTravailPraxis>(
      (Ref ref) => ServiceTravailPraxisSupabase(Supabase.instance.client),
    );

/// La taille d'une page lue au serveur (son maximum).
const int taillePagePraxis = 200;

/// Le nombre de pages lues au plus : 2 000 dossiers, au-dela de la file
/// actuelle (pres de 600). Une file plus longue se dirait par un total plus
/// grand que les lignes lues ; elle demanderait la lecture par reference qui
/// manque au serveur.
const int pagesPraxisMax = 10;

/// Tous les rangements courants que la direction peut lire, page apres page.
final FutureProvider<PageRangements> rangementsPraxisProvider =
    FutureProvider.autoDispose<PageRangements>((Ref ref) async {
      final ServiceTravailPraxis s = ref.watch(serviceTravailPraxisProvider);
      final List<RangementPraxis> lignes = <RangementPraxis>[];
      PageRangements? premiere;
      for (int i = 0; i < pagesPraxisMax; i++) {
        final PageRangements p = await s.rangements(
          decalage: i * taillePagePraxis,
        );
        premiere ??= p;
        lignes.addAll(p.lignes);
        if (p.lignes.length < taillePagePraxis || lignes.length >= p.total) {
          break;
        }
      }
      return PageRangements(
        lignes: List<RangementPraxis>.unmodifiable(lignes),
        total: premiere!.total,
        parPile: premiere.parPile,
      );
    }, retry: (int retryCount, Object error) => null);

/// Toutes les impressions courantes que la direction peut lire.
final FutureProvider<PageImpressions> impressionsPraxisProvider =
    FutureProvider.autoDispose<PageImpressions>((Ref ref) async {
      final ServiceTravailPraxis s = ref.watch(serviceTravailPraxisProvider);
      final List<ImpressionPraxis> lignes = <ImpressionPraxis>[];
      PageImpressions? premiere;
      for (int i = 0; i < pagesPraxisMax; i++) {
        final PageImpressions p = await s.impressions(
          decalage: i * taillePagePraxis,
        );
        premiere ??= p;
        lignes.addAll(p.lignes);
        if (p.lignes.length < taillePagePraxis || lignes.length >= p.total) {
          break;
        }
      }
      return PageImpressions(
        lignes: List<ImpressionPraxis>.unmodifiable(lignes),
        total: premiere!.total,
        parEtiquette: premiere.parEtiquette,
      );
    }, retry: (int retryCount, Object error) => null);

/// Les objectifs de Praxis (ouverts et clos, les plus recents d'abord).
final FutureProvider<List<ObjectifPraxis>> objectifsPraxisProvider =
    FutureProvider.autoDispose<List<ObjectifPraxis>>(
      (Ref ref) => ref.watch(serviceTravailPraxisProvider).objectifs(),
      retry: (int retryCount, Object error) => null,
    );
