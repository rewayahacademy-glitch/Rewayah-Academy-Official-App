// BE-2b : le port de l'ecran « Equipe ». Absent avant le branchement serveur :
// sans port, chaque lecture est une capacite indisponible. Le serveur decide de
// tout (direction active, double verification, portee de genre, journal) ; le
// port ne fait que transmettre et traduire ses refus.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'modeles_equipe.dart';

/// L'identifiant de la dependance serveur de l'ecran, pour la trace : jamais
/// affiche.
const String dependanceEquipe = 'BE-2b';

/// Pourquoi le serveur a refuse un geste de l'equipe (jamais par son texte).
enum CauseRefusEquipe {
  /// Le compte n'existe pas, n'est pas actif ou n'a pas un role admis.
  personneIndisponible,

  /// Le genre de la personne est inconnu : une mission se porte de son cote.
  genreInconnu,

  /// La personne porte deja cette mission : la retirer d'abord.
  attributionActive,

  /// La mission est inconnue ou archivee.
  missionIndisponible,

  /// Le perimetre ou les dates sont invalides.
  parametresInvalides,

  /// La cle d'idempotence a deja servi pour une autre demande.
  cleDejaUtilisee,

  /// Les gestes demandes ne sont pas tous admis dans une mission.
  gestesNonAdmis,

  /// Un refus que l'ecran ne sait pas nommer.
  autre,
}

/// Le serveur a refuse le geste, avec une cause nommee.
class RefusEquipe implements Exception {
  /// Cree le refus.
  const RefusEquipe(this.cause);

  /// La cause.
  final CauseRefusEquipe cause;

  @override
  String toString() => 'RefusEquipe(${cause.name})';
}

/// Le port de l'equipe : missions, attributions, personnes, invitations.
abstract interface class PortEquipe {
  /// Les missions (archivees comprises), de la plus ancienne a la plus recente.
  Future<List<Mission>> missions();

  /// Les attributions, de la plus recente a la plus ancienne.
  Future<List<Attribution>> attributions();

  /// Les personnes qui peuvent recevoir une mission.
  Future<List<PersonneMission>> personnes();

  /// Les codes des gestes que le serveur admet dans une mission.
  Future<List<String>> gestesOuverts();

  /// Les invitations d'associes.
  Future<List<InvitationAssocie>> invitations();

  /// Cree une mission. Rend son identifiant.
  Future<String> creerMission({
    required String nom,
    required List<String> gestes,
    required String cle,
  });

  /// Archive une mission.
  Future<void> archiverMission({
    required String id,
    required String motif,
    required String cle,
  });

  /// Accorde une mission. [langues] et [etapes] vides : sans limite. Le cote
  /// n'est jamais envoye : le serveur l'ecrit.
  Future<String> accorder({
    required String profil,
    required String mission,
    required List<String> langues,
    required List<String> etapes,
    required DateTime? debut,
    required DateTime? fin,
    required String cle,
  });

  /// Retire une attribution, avec un motif.
  Future<void> retirer({
    required String attribution,
    required String motif,
    required String cle,
  });

  /// Invite un associe.
  Future<ResultatInvitation> inviter({
    required String courriel,
    required String? nom,
    required String cle,
  });

  /// Revoque une invitation, avec un motif.
  Future<void> revoquer({
    required String id,
    required String motif,
    required String cle,
  });
}

/// Le port de l'equipe : absent avant le branchement serveur.
final Provider<PortEquipe?> portEquipeProvider = Provider<PortEquipe?>(
  (Ref _) => null,
);

FutureProvider<T> _lecture<T>(Future<T> Function(PortEquipe port) lire) =>
    FutureProvider.autoDispose<T>((Ref ref) {
      final PortEquipe? port = ref.watch(portEquipeProvider);
      if (port == null) {
        return Future<T>.error(const CapaciteIndisponible(dependanceEquipe));
      }
      return lire(port);
    }, retry: (int _, Object _) => null);

/// Les missions.
final FutureProvider<List<Mission>> missionsProvider = _lecture(
  (PortEquipe p) => p.missions(),
);

/// Les attributions.
final FutureProvider<List<Attribution>> attributionsProvider = _lecture(
  (PortEquipe p) => p.attributions(),
);

/// Les personnes qui peuvent recevoir une mission.
final FutureProvider<List<PersonneMission>> personnesMissionProvider = _lecture(
  (PortEquipe p) => p.personnes(),
);

/// Les gestes admis dans une mission.
final FutureProvider<List<String>> gestesOuvertsProvider = _lecture(
  (PortEquipe p) => p.gestesOuverts(),
);

/// Les invitations d'associes.
final FutureProvider<List<InvitationAssocie>> invitationsAssocieProvider =
    _lecture((PortEquipe p) => p.invitations());
