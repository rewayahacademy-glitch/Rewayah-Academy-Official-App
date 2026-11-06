// V2-a (04/11/2026) : le port des entretiens de la direction (`ADM-21`, bloc
// Entretien), sur les RPC de V1-a et V1-a-bis.
//
// Le serveur decide de tout : la portee de genre (le super-admin des deux
// cotes), le personnel qu'on peut choisir, la regle des fondateurs, l'etat de
// la candidature. Les refus nommes arrivent en [RefusEntretien] (propres a
// l'entretien) ou en `RefusGeste` (ceux du moteur des candidatures : version
// perimee, geste interdit depuis l'etat, cle reutilisee, reponse absente).
// Un port absent (le provider vaut `null`) rend la capacite indisponible :
// jamais une liste vide, jamais un entretien fictif.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
// `FutureProviderFamily` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../capacites/capacite_indisponible.dart';
import 'modeles_candidature_detail.dart';
import 'modeles_entretien_direction.dart';

/// L'identifiant de la dependance serveur des entretiens (V1-a), pour la
/// trace et les tests : jamais affiche.
const String dependanceEntretiens = 'V1-a';

/// Le port des entretiens, cote direction.
abstract interface class PortEntretiensDirection {
  /// Les entretiens de [candidatureId], du plus ancien au plus recent, lus sur
  /// les 90 derniers jours (`mes_entretiens`).
  Future<List<EntretienCandidature>> entretiens(String candidatureId);

  /// Les participants, les comptes rendus et les presences d'un entretien.
  /// [EntretienIntrouvable] quand il est hors de portee ou absent.
  Future<DetailEntretien> lire(String sessionId);

  /// Le personnel qu'on peut choisir pour [candidatureId] : du cote de la
  /// candidature, plus le super-admin.
  Future<List<PersonnelEntretien>> personnel(String candidatureId);

  /// Planifie l'entretien. Rend la candidature relue.
  Future<ResultatGeste> planifier({
    required String candidatureId,
    required DateTime debut,
    required int dureeMinutes,
    required List<String> participants,
    required int versionAttendue,
    required String cleIdempotence,
  });

  /// Ajoute [profilId] aux participants d'un entretien ouvert.
  Future<void> ajouter(String sessionId, String profilId);

  /// Retire [profilId] des participants d'un entretien ouvert.
  Future<void> retirer(String sessionId, String profilId);

  /// Consigne l'issue. [motif] est exige pour toute issue sauf « tenu ».
  Future<ResultatGeste> consigner({
    required String sessionId,
    required IssueEntretien issue,
    required String? motif,
    required int versionAttendue,
    required String cleIdempotence,
  });
}

/// Le port des entretiens : absent avant le branchement serveur.
final Provider<PortEntretiensDirection?> portEntretiensDirectionProvider =
    Provider<PortEntretiensDirection?>((Ref _) => null);

/// Les entretiens d'une candidature. Sans port : [CapaciteIndisponible].
final FutureProviderFamily<List<EntretienCandidature>, String>
entretiensCandidatureProvider = FutureProvider.autoDispose
    .family<List<EntretienCandidature>, String>((Ref ref, String candidature) {
      final PortEntretiensDirection? port = ref.watch(
        portEntretiensDirectionProvider,
      );
      if (port == null) {
        return Future<List<EntretienCandidature>>.error(
          const CapaciteIndisponible(dependanceEntretiens),
        );
      }
      return port.entretiens(candidature);
    }, retry: (int _, Object _) => null);

/// Le detail d'un entretien. Sans port : [CapaciteIndisponible].
final FutureProviderFamily<DetailEntretien, String> detailEntretienProvider =
    FutureProvider.autoDispose.family<DetailEntretien, String>((
      Ref ref,
      String session,
    ) {
      final PortEntretiensDirection? port = ref.watch(
        portEntretiensDirectionProvider,
      );
      if (port == null) {
        return Future<DetailEntretien>.error(
          const CapaciteIndisponible(dependanceEntretiens),
        );
      }
      return port.lire(session);
    }, retry: (int _, Object _) => null);

/// Le personnel qu'on peut choisir. Sans port : [CapaciteIndisponible].
final FutureProviderFamily<List<PersonnelEntretien>, String>
personnelEntretienProvider = FutureProvider.autoDispose
    .family<List<PersonnelEntretien>, String>((Ref ref, String candidature) {
      final PortEntretiensDirection? port = ref.watch(
        portEntretiensDirectionProvider,
      );
      if (port == null) {
        return Future<List<PersonnelEntretien>>.error(
          const CapaciteIndisponible(dependanceEntretiens),
        );
      }
      return port.personnel(candidature);
    }, retry: (int _, Object _) => null);
