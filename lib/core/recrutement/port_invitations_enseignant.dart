/// RECRUT-ECRANS : l'invitation d'un enseignant, a usage unique et a duree
/// limitee (contrats C-13 et C-14 de la feuille de liaison, 10/10/2026).
///
/// Deux ports dans un fichier, deux acteurs :
///
/// - [PortInvitationsEnseignant] : l'administration invite, liste, revoque.
///   Seule l'administration emet une invitation ;
/// - [PortVerificationInvitation] : le candidat verifie son code. Les quatre
///   issues ([ResultatInvitation]) sont des reponses, pas des pannes. Le
///   resultat ne sert qu'a l'affichage : le serveur consomme le code
///   atomiquement a l'inscription et refuse un code invalide, quoi que
///   l'ecran ait cru.
///
/// Aucun branchement serveur ici : en production les deux ports valent `null`
/// et les ecrans le disent (« disponible au branchement serveur »). Les
/// adaptateurs `*_supabase.dart` sont a ChatGPT (Codex) ; la demonstration
/// surcharge les deux (`features/demo/recrutement_demo.dart`).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';

/// L'etat d'une invitation, tel que le serveur le rend.
enum EtatInvitation { active, utilisee, expiree, revoquee }

/// Une invitation emise par l'administration.
@immutable
class Invitation {
  /// Cree une invitation.
  const Invitation({
    required this.code,
    required this.email,
    required this.expireLe,
    required this.etat,
    this.utiliseeLe,
  });

  /// Le code a usage unique.
  final String code;

  /// L'adresse invitee.
  final String email;

  /// L'echeance, horodatage serveur.
  final DateTime expireLe;

  /// L'etat rendu par le serveur (jamais deduit de l'horloge de l'appareil).
  final EtatInvitation etat;

  /// Le moment de l'utilisation, quand [etat] vaut [EtatInvitation.utilisee].
  final DateTime? utiliseeLe;
}

/// Les refus metier du port administration.
sealed class ErreurInvitation implements Exception {
  const ErreurInvitation();
}

/// L'adresse n'a pas la forme d'une adresse.
final class EmailInvalide extends ErreurInvitation {
  /// Cree l'erreur.
  const EmailInvalide();
}

/// Une invitation active existe deja pour cette adresse : [existante] est
/// rendue, l'ecran la montre au lieu d'en creer une seconde.
final class DejaInvite extends ErreurInvitation {
  /// Cree l'erreur.
  const DejaInvite(this.existante);

  /// L'invitation active.
  final Invitation existante;
}

/// Un compte existe deja pour cette adresse.
final class CompteExistant extends ErreurInvitation {
  /// Cree l'erreur.
  const CompteExistant();
}

/// La personne connectee n'a pas la capacite d'inviter.
final class NonAutorise extends ErreurInvitation {
  /// Cree l'erreur.
  const NonAutorise();
}

/// Aucune reponse : l'appareil est hors ligne.
final class HorsLigne extends ErreurInvitation {
  /// Cree l'erreur.
  const HorsLigne();
}

/// Le port de l'administration.
abstract interface class PortInvitationsEnseignant {
  /// Emet une invitation pour [email].
  Future<Invitation> inviter(String email);

  /// Les invitations, la plus recente d'abord.
  Future<List<Invitation>> lister();

  /// Revoque l'invitation de ce code (sans effet sur une invitation deja
  /// utilisee ou expiree).
  Future<void> revoquer(String code);
}

/// Ce que le serveur dit d'un code, pour l'affichage.
sealed class ResultatInvitation {
  const ResultatInvitation();
}

/// Le code est valable.
final class InvitationValide extends ResultatInvitation {
  /// Cree le resultat.
  const InvitationValide({required this.expireLe});

  /// L'echeance.
  final DateTime expireLe;
}

/// Le code a expire.
final class InvitationExpiree extends ResultatInvitation {
  /// Cree le resultat.
  const InvitationExpiree({required this.expireLe});

  /// L'echeance depassee.
  final DateTime expireLe;
}

/// Le code a deja servi.
final class InvitationDejaUtilisee extends ResultatInvitation {
  /// Cree le resultat.
  const InvitationDejaUtilisee();
}

/// Le code est inconnu (ou revoque : on ne distingue pas, aucune fuite).
final class InvitationInconnue extends ResultatInvitation {
  /// Cree le resultat.
  const InvitationInconnue();
}

/// Le port du candidat.
abstract interface class PortVerificationInvitation {
  /// Verifie un code. Leve [HorsLigne] seulement en cas de panne reseau.
  Future<ResultatInvitation> verifierInvitation(String code);
}

/// L'identifiant de la dependance serveur, pour la trace et les tests.
const String dependanceInvitations = 'RECRUT-INVITATIONS';

/// Le port administration : absent avant le branchement serveur.
final Provider<PortInvitationsEnseignant?> portInvitationsEnseignantProvider =
    Provider<PortInvitationsEnseignant?>((Ref _) => null);

/// Le port candidat : absent avant le branchement serveur.
final Provider<PortVerificationInvitation?> portVerificationInvitationProvider =
    Provider<PortVerificationInvitation?>((Ref _) => null);

/// Les invitations de l'administration. Sans port : [CapaciteIndisponible].
final FutureProvider<List<Invitation>> invitationsEnseignantProvider =
    FutureProvider<List<Invitation>>((Ref ref) {
      final PortInvitationsEnseignant? port = ref.watch(
        portInvitationsEnseignantProvider,
      );
      if (port == null) {
        return Future<List<Invitation>>.error(
          const CapaciteIndisponible(dependanceInvitations),
        );
      }
      return port.lister();
    }, retry: (int _, Object _) => null);

/// Le code d'invitation verifie, conserve pour l'inscription enseignant :
/// `ServiceDossier.creerProfil` le recevra (parametre `codeInvitation`, a
/// ajouter par Codex, C-14). Jamais ecrit sur disque, jamais journalise.
final NotifierProvider<CodeInvitationRetenu, String?>
codeInvitationRetenuProvider = NotifierProvider<CodeInvitationRetenu, String?>(
  CodeInvitationRetenu.new,
);

/// Le notifier du code retenu.
class CodeInvitationRetenu extends Notifier<String?> {
  @override
  String? build() => null;

  /// Retient un code valide.
  void retenir(String code) => state = code;

  /// Oublie le code.
  void oublier() => state = null;
}
