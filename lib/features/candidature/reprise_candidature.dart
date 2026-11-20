// PE-A6 (directeur, 19/11/2026 : « Retrait : 7 jours d'accord, a condition que
// le candidat comprenne par l'ecran ce qui lui arrive ; jamais de silence ») :
// le candidat qui a retire sa candidature la reprend lui-meme pendant 7 jours.
//
// Le port de la reprise, sur `20261130910000_reprise_candidature.sql` :
// - la lecture est la cle `reprise` du bloc `candidature` de `etat_dossier()`
//   (la seule lecture de l'etat du candidat, contrat des ports, section 3) :
//   le delai, la date limite et la raison d'une reprise fermee viennent du
//   serveur ; l'ecran n'en deduit rien ;
// - `reprise_candidat(version, cle)` : le geste, par le moteur des
//   candidatures (version attendue, cle d'idempotence).
//
// Tant que la migration n'est pas installee, `etat_dossier()` ne rend pas la
// cle : la lecture leve [CapaciteIndisponible], l'ecran dit alors ce qui est
// vrai sans elle (« seule l'academie peut la rouvrir ») et ne propose aucune
// reprise.
//
// Dette : `CandidatureDossier` (`lib/core/candidature/`, hors de la zone de ce
// lot) ne lit pas encore cette cle ; ce port relit donc `etat_dossier()` pour
// elle seule. Le jour ou le modele la porte, ce port ne garde que le geste.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/candidature/port_ma_candidature.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/dossier/service_dossier.dart';

/// L'identifiant de la dependance serveur de la reprise, pour la trace et les
/// tests : jamais affiche.
const String dependanceReprise = 'PE-A6-REPRISE';

/// Pourquoi une candidature retiree ne se reprend pas par la personne.
enum RaisonRepriseFermee {
  /// Le retrait a ete consigne par la direction.
  retraitParLaDirection('retrait_par_la_direction'),

  /// Les 7 jours sont passes.
  delaiDepasse('delai_depasse'),

  /// Un controle de la reouverture est faux (un element a change depuis).
  controles('controles_non_satisfaits'),

  /// La candidature n'est pas celle d'un enseignant.
  type('type');

  const RaisonRepriseFermee(this.code);

  /// Le code rendu par le serveur.
  final String code;

  /// La raison lue, [controles] pour un code que cette version ne connait
  /// pas : la suite est la meme (ecrire a l'academie).
  static RaisonRepriseFermee depuisCode(Object? code) {
    for (final RaisonRepriseFermee r in values) {
      if (r.code == code) return r;
    }
    return RaisonRepriseFermee.controles;
  }
}

/// Ce que le serveur dit de la reprise (`etat_dossier().candidature.reprise`).
@immutable
class RepriseCandidature {
  /// Cree la lecture.
  const RepriseCandidature({
    required this.retiree,
    required this.possible,
    required this.delaiJours,
    this.retireeLe,
    this.repriseJusquAu,
    this.raison,
  });

  /// Lit la cle `reprise`. Elle ne porte `possible` que pour une candidature
  /// retiree. Une forme inattendue leve [FormatException].
  factory RepriseCandidature.depuisJson(Object? brut) {
    if (brut is! Map || brut['delaiJours'] is! int) {
      throw const FormatException('Reprise : objet attendu.');
    }
    final bool retiree = brut['possible'] is bool;
    final bool possible = brut['possible'] == true;
    return RepriseCandidature(
      retiree: retiree,
      possible: possible,
      delaiJours: brut['delaiJours'] as int,
      retireeLe: _instant(brut['retireeLe']),
      repriseJusquAu: _instant(brut['repriseJusquAu']),
      raison: retiree && !possible
          ? RaisonRepriseFermee.depuisCode(brut['raison'])
          : null,
    );
  }

  /// Vrai quand la candidature du compte est retiree.
  final bool retiree;

  /// Vrai quand la personne peut la reprendre elle-meme maintenant.
  final bool possible;

  /// Le delai de reprise, en jours (7), dit par le serveur : l'ecran qui
  /// explique le retrait le cite avant le geste.
  final int delaiJours;

  /// La date du retrait, si le serveur la rend.
  final DateTime? retireeLe;

  /// Jusqu'a quand la reprise est (ou etait) possible ; nulle pour un retrait
  /// consigne par la direction.
  final DateTime? repriseJusquAu;

  /// Pourquoi elle ne se reprend pas ; nulle quand elle se reprend, ou quand
  /// la candidature n'est pas retiree.
  final RaisonRepriseFermee? raison;

  static DateTime? _instant(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  @override
  bool operator ==(Object other) =>
      other is RepriseCandidature &&
      other.retiree == retiree &&
      other.possible == possible &&
      other.delaiJours == delaiJours &&
      other.retireeLe == retireeLe &&
      other.repriseJusquAu == repriseJusquAu &&
      other.raison == raison;

  @override
  int get hashCode => Object.hash(
    retiree,
    possible,
    delaiJours,
    retireeLe,
    repriseJusquAu,
    raison,
  );
}

/// Le serveur refuse la reprise : [raison] dit pourquoi.
final class RepriseFermee implements Exception {
  /// Cree le refus.
  const RepriseFermee(this.raison);

  /// La raison du refus.
  final RaisonRepriseFermee raison;
}

/// Le port de la reprise d'une candidature retiree.
abstract interface class PortRepriseCandidature {
  /// Lit ce que le serveur dit de la reprise. [CapaciteIndisponible] tant que
  /// la migration n'est pas installee.
  Future<RepriseCandidature> lire();

  /// Reprend la candidature. Leve [RepriseFermee], [ConflitCandidature],
  /// [TransitionInterdite] (elle n'est plus retiree), [HorsLigneCandidature]
  /// (issue inconnue : la meme cle se rejoue), [PermissionInsuffisante] ou
  /// [CapaciteIndisponible].
  Future<void> reprendre({
    required int versionAttendue,
    required String cleIdempotence,
  });
}

/// La reprise servie par Supabase.
class RepriseCandidatureSupabase implements PortRepriseCandidature {
  /// Cree l'adaptateur. [client] est lu a l'appel : un hote sans Supabase
  /// (test, galerie) n'echoue qu'a la lecture, comme une capacite absente.
  const RepriseCandidatureSupabase(this._client);

  final SupabaseClient Function() _client;

  Future<Object?> _appel(
    String fonction, [
    Map<String, dynamic>? params,
  ]) async {
    final SupabaseClient client;
    try {
      client = _client();
      // Supabase non initialise leve une erreur d'assertion, pas une exception.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      throw const CapaciteIndisponible(dependanceReprise);
    }
    try {
      return await client.rpc<Object?>(fonction, params: params);
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw PermissionInsuffisante(fonction);
      // PGRST202 : fonction absente du cache de schema ; 42883 : inconnue de
      // la base. La migration n'est pas encore installee.
      if (e.code == 'PGRST202' || e.code == '42883') {
        throw const CapaciteIndisponible(dependanceReprise);
      }
      rethrow;
    } on FormatException {
      rethrow;
    } on Exception {
      throw const HorsLigneCandidature();
    }
  }

  @override
  Future<RepriseCandidature> lire() async {
    final Object? dossier = await _appel('etat_dossier');
    final Object? candidature = dossier is Map ? dossier['candidature'] : null;
    final Object? reprise = candidature is Map ? candidature['reprise'] : null;
    // Un serveur d'avant la migration ne rend pas la cle.
    if (reprise == null) throw const CapaciteIndisponible(dependanceReprise);
    return RepriseCandidature.depuisJson(reprise);
  }

  @override
  Future<void> reprendre({
    required int versionAttendue,
    required String cleIdempotence,
  }) async {
    final Object? brut = await _appel('reprise_candidat', <String, dynamic>{
      'p_version_attendue': versionAttendue,
      'p_cle_idempotence': cleIdempotence,
    });
    if (brut is! Map) throw const FormatException('Reprise : objet attendu.');
    final Object? erreur = brut['erreur'];
    if (erreur == null) {
      // Jamais de faux succes : sans le bloc relu, rien n'est dit fait.
      final Object? c = brut['candidature'];
      if (c is! Map || c['issue'] != 'en_cours') {
        throw const FormatException('Reprise : candidature relue absente.');
      }
      return;
    }
    switch (erreur) {
      case 'conflit_candidature':
        final Object? v = brut['versionCourante'];
        throw ConflitCandidature(v is int ? v : null);
      case 'transition_interdite':
        throw const TransitionInterdite();
      case 'reprise_fermee':
        throw RepriseFermee(RaisonRepriseFermee.depuisCode(brut['raison']));
      case 'controles_non_satisfaits':
        throw const RepriseFermee(RaisonRepriseFermee.controles);
      case 'absente':
        throw const CandidatureAbsente();
      default:
        throw FormatException('Refus inconnu : $erreur');
    }
  }
}

/// Le port de la reprise ; surcharge par les tests.
final Provider<PortRepriseCandidature> portRepriseCandidatureProvider =
    Provider<PortRepriseCandidature>(
      (Ref _) => RepriseCandidatureSupabase(() => Supabase.instance.client),
    );

/// Ce que le serveur dit de la reprise. Une lecture en echec ne se relance
/// pas seule : l'ecran dit alors ce qui est vrai sans elle.
///
/// Elle suit le dossier : chaque relecture de [etatDossierProvider]
/// (« Actualiser », tirer pour actualiser, retour dans l'application, un
/// geste qui l'invalide) relit aussi la reprise, sans qu'aucun appelant ait a
/// la nommer. On peut aussi l'invalider seule.
final FutureProvider<RepriseCandidature> repriseCandidatureProvider =
    FutureProvider<RepriseCandidature>((Ref ref) {
      // Seule la relecture compte ici, pas sa valeur ni son echec.
      ref.watch(etatDossierProvider.future).ignore();
      return ref.watch(portRepriseCandidatureProvider).lire();
    }, retry: (int _, Object _) => null);
