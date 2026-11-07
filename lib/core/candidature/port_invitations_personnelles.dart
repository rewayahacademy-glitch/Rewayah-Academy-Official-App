// Le port des codes personnels des candidats importes (INVITATIONS-PERSONNELLES,
// lot 7 du plan des trois salles, 07/11/2026) : `PortInvitationsPersonnelles`.
//
// Trois RPC, reservees au super administrateur en double verification
// (`20261120000000_invitations_candidats_importes.sql`) :
//
// - `apercu_invitations_candidats_importes` : des comptes par situation, et le
//   plafond du jour. Aucune adresse n'est rendue ;
// - `envoyer_invitations_candidats_importes(p_attendu, p_limite)` : pour chaque
//   personne a inviter ou dont le code a expire, une invitation a code neuve et
//   son e-mail existant `invitation_enseignant`. Le serveur refuse si le nombre
//   a change depuis l'apercu, ou si le plafond du jour (300) est atteint ;
// - `lien_invitation_candidat_importe(p_reponse, p_courriel)` : le code d'une
//   reponse, pour « Copier le lien » (sans e-mail).
//
// Les refus metier arrivent **dans la reponse** (`{erreur: ...}`), sans
// ecriture : ils deviennent des [ErreurInvitationsPersonnelles] typees. « Mis
// en file » n'est pas « recu ».
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';

/// La dependance serveur, pour la trace et les tests : jamais affichee.
const String dependanceInvitationsPersonnelles = 'INVITATIONS-PERSONNELLES';

/// Le plus grand envoi qu'un geste demande (le serveur refuse au-dela).
const int limiteInvitationsParEnvoi = 200;

int _compte(Map<String, dynamic> j, String cle) {
  final Object? v = j[cle];
  if (v is int && v >= 0) return v;
  throw FormatException('compte attendu : $cle');
}

/// Ce que l'apercu dit, sans aucune adresse.
class ApercuInvitationsPersonnelles {
  /// Cree l'apercu.
  const ApercuInvitationsPersonnelles({
    required this.aInviter,
    required this.aRenvoyer,
    required this.dejaInvites,
    required this.dejaInscrits,
    required this.revoquees,
    required this.desinscrits,
    required this.sansAdresse,
    required this.plafondJour,
    required this.resteAujourdhui,
  });

  /// Lit la reponse du serveur. Une forme inattendue est une [FormatException].
  factory ApercuInvitationsPersonnelles.depuisJson(Map<String, dynamic> j) =>
      ApercuInvitationsPersonnelles(
        aInviter: _compte(j, 'aInviter'),
        aRenvoyer: _compte(j, 'aRenvoyer'),
        dejaInvites: _compte(j, 'dejaInvites'),
        dejaInscrits: _compte(j, 'dejaInscrits'),
        revoquees: _compte(j, 'revoquees'),
        desinscrits: _compte(j, 'desinscrits'),
        sansAdresse: _compte(j, 'sansAdresse'),
        plafondJour: _compte(j, 'plafondJour'),
        resteAujourdhui: _compte(j, 'resteAujourdhui'),
      );

  /// Les personnes qui n'ont jamais recu de code.
  final int aInviter;

  /// Les personnes dont le code a expire sans compte : un nouveau code part.
  final int aRenvoyer;

  /// Les personnes qui ont deja un code valide.
  final int dejaInvites;

  /// Les personnes qui ont deja un compte.
  final int dejaInscrits;

  /// Les personnes dont la direction a retire un code : pas d'envoi groupe.
  final int revoquees;

  /// Les personnes desinscrites des messages du recrutement.
  final int desinscrits;

  /// Les reponses importees sans adresse.
  final int sansAdresse;

  /// Le plafond de cet envoi sur 24 heures glissantes.
  final int plafondJour;

  /// Ce qui peut encore partir aujourd'hui.
  final int resteAujourdhui;

  /// Le nombre que l'envoi attend : a inviter et a renvoyer.
  int get eligibles => aInviter + aRenvoyer;
}

/// Ce qu'un envoi a fait.
class ResultatInvitationsPersonnelles {
  /// Cree le resultat.
  const ResultatInvitationsPersonnelles({
    required this.misEnFile,
    required this.restants,
    required this.resteAujourdhui,
  });

  /// Lit la reponse du serveur. Une forme inattendue est une [FormatException].
  factory ResultatInvitationsPersonnelles.depuisJson(Map<String, dynamic> j) =>
      ResultatInvitationsPersonnelles(
        misEnFile: _compte(j, 'misEnFile'),
        restants: _compte(j, 'restants'),
        resteAujourdhui: _compte(j, 'resteAujourdhui'),
      );

  /// Les messages mis en file par cet envoi.
  final int misEnFile;

  /// Les personnes encore a inviter apres cet envoi.
  final int restants;

  /// Ce qui peut encore partir aujourd'hui.
  final int resteAujourdhui;
}

/// Pourquoi un envoi ou un apercu n'a pas abouti. Hors
/// [InvitationsPersonnellesHorsLigne] pendant un envoi, aucune n'a rien ecrit.
sealed class ErreurInvitationsPersonnelles implements Exception {
  const ErreurInvitationsPersonnelles();
}

/// Le nombre de personnes a change depuis l'apercu : rien n'est parti.
final class NombreChange extends ErreurInvitationsPersonnelles {
  /// Cree l'erreur.
  const NombreChange(this.eligibles);

  /// Le nombre que le serveur compte maintenant.
  final int eligibles;
}

/// Le plafond du jour est atteint : rien n'est parti, reprendre demain.
final class PlafondAtteint extends ErreurInvitationsPersonnelles {
  /// Cree l'erreur.
  const PlafondAtteint(this.restants);

  /// Les personnes qui attendent encore leur code.
  final int restants;
}

/// La connexion a coupe. Pour un envoi, c'est **non confirme** ; rejouer
/// n'envoie aucun second code valide a une meme personne.
final class InvitationsPersonnellesHorsLigne
    extends ErreurInvitationsPersonnelles {
  /// Cree l'erreur.
  const InvitationsPersonnellesHorsLigne();
}

/// Le serveur a refuse les arguments (`22023`). [message] ne s'affiche pas.
final class InvitationsPersonnellesInvalide
    extends ErreurInvitationsPersonnelles {
  /// Cree l'erreur.
  const InvitationsPersonnellesInvalide(this.message);

  /// Le message du serveur.
  final String message;
}

/// Le serveur a rendu un refus que ce client ne connait pas.
final class InvitationsPersonnellesRefusInconnu
    extends ErreurInvitationsPersonnelles {
  /// Cree l'erreur.
  const InvitationsPersonnellesRefusInconnu(this.code);

  /// Le code rendu (trace et tests, jamais affiche).
  final String code;
}

/// Le port des codes personnels des candidats importes.
abstract interface class PortInvitationsPersonnelles {
  /// Les comptes par situation et le plafond du jour. Aucune ecriture hors du
  /// journal. `PermissionInsuffisante` hors du super administrateur en double
  /// verification ; `CapaciteIndisponible` avant la migration.
  Future<ApercuInvitationsPersonnelles> apercu();

  /// Envoie au plus [limite] codes (1 a [limiteInvitationsParEnvoi]), si le
  /// serveur compte toujours [attendu] personnes. Lance [NombreChange] ou
  /// [PlafondAtteint] sans rien ecrire.
  Future<ResultatInvitationsPersonnelles> envoyer({
    required int attendu,
    int limite = limiteInvitationsParEnvoi,
  });
}

/// Le port : absent avant le branchement serveur.
final Provider<PortInvitationsPersonnelles?>
portInvitationsPersonnellesProvider = Provider<PortInvitationsPersonnelles?>(
  (Ref _) => null,
);

/// L'apercu. Sans port : [CapaciteIndisponible]. Relu a chaque ouverture de la
/// feuille, sans retentative automatique.
final FutureProvider<ApercuInvitationsPersonnelles>
apercuInvitationsPersonnellesProvider =
    FutureProvider.autoDispose<ApercuInvitationsPersonnelles>((Ref ref) {
      final PortInvitationsPersonnelles? port = ref.watch(
        portInvitationsPersonnellesProvider,
      );
      if (port == null) {
        return Future<ApercuInvitationsPersonnelles>.error(
          const CapaciteIndisponible(dependanceInvitationsPersonnelles),
        );
      }
      return port.apercu();
    }, retry: (int _, Object _) => null);
