import 'package:flutter/foundation.dart';

import '../domain/enums.dart';

/// Ce que le routeur a le droit de laisser atteindre.
///
/// Cette porte est une **commodite d'experience**, pas une barriere de
/// securite : la protection reelle reste la RLS de l'etape 1. Un compte qui
/// contournerait cette redirection ne lirait rien de plus en base
/// (`docs/architecture/etape-2-core-flutter.md` section 3).
enum PorteAcces {
  /// La session n'est pas encore resolue. Aucune redirection tant qu'on ne
  /// sait pas : rediriger sur un etat inconnu ferait clignoter l'ecran.
  chargement,

  /// Aucune session. Seules les routes publiques sont atteignables.
  deconnecte,

  /// Session valide, aucun profil. L'inscription reste a terminer.
  ///
  /// Sans cette porte, un compte tout juste cree n'avait ni role ni foyer dans
  /// son jeton, tombait en [deconnecte] et repartait sur l'ecran de connexion :
  /// le produit n'avait aucune porte d'entree
  /// (`docs/architecture/etape-3-auth-kyc.md` section 2.1).
  inscription,

  /// Dossier non valide. Portail d'attente uniquement, quelle que soit l'URL
  /// tapee directement dans un navigateur.
  attente,

  /// Compte suspendu. Portail d'attente, avec un motif different.
  suspendu,

  /// Acces complet aux routes du role.
  actif,
}

/// Ce que la lecture du profil a appris.
///
/// **Une absence n'est pas un echec.** Les deux se ressemblent depuis le client
/// et ne veulent pas dire la meme chose : l'absence ouvre l'inscription,
/// l'echec ferme sur le portail d'attente. Les confondre enverrait un compte
/// suspendu recreer un profil.
enum LectureProfil {
  /// Pas encore lue.
  enAttente,

  /// Lue, aucune ligne : le compte existe, le profil reste a creer.
  absente,

  /// Lue, une ligne.
  presente,

  /// La lecture a echoue, reseau ou refus. On ne devine pas.
  echouee,
}

/// L'etat de session dont depend toute la navigation.
///
/// Le role vient du JWT, jamais du client. Le statut de compte vient d'une
/// lecture de `profiles` : le hook de jeton n'injecte que le role et le foyer,
/// pas le statut.
@immutable
class SessionState {
  /// Cree un etat de session.
  const SessionState({
    required this.resolue,
    this.role,
    this.householdId,
    this.profileId,
    this.accountStatus,
    this.interfaceMode = InterfaceMode.standard,
    this.lectureProfil = LectureProfil.enAttente,
  });

  /// L'etat initial, avant toute resolution.
  const SessionState.chargement() : this(resolue: false);

  /// L'etat d'un visiteur sans session.
  const SessionState.deconnecte() : this(resolue: true);

  /// La session a fini d'etre resolue. Tant que c'est faux, le routeur ne
  /// redirige pas.
  final bool resolue;

  /// Role lu dans `app_metadata.role` du jeton d'acces.
  final AppRole? role;

  /// Foyer lu dans `app_metadata.household_id` du jeton d'acces.
  final String? householdId;

  /// Identifiant du profil connecte.
  final String? profileId;

  /// Statut de compte lu dans `profiles`.
  final AccountStatus? accountStatus;

  /// Mode d'interface, porte par le profil eleve. Change ce qu'un ecran
  /// affiche, jamais l'arborescence de navigation (ADR-009).
  final InterfaceMode interfaceMode;

  /// Ce que la lecture du profil a appris.
  final LectureProfil lectureProfil;

  /// Vrai quand une session existe.
  bool get connecte => profileId != null;

  /// La porte a appliquer dans le routeur.
  PorteAcces get porte {
    if (!resolue) {
      return PorteAcces.chargement;
    }
    if (!connecte) {
      return PorteAcces.deconnecte;
    }

    switch (lectureProfil) {
      // On ne sait pas encore : on ne redirige pas.
      case LectureProfil.enAttente:
        return PorteAcces.chargement;

      // Le compte existe, le profil reste a creer. C'est la seule porte qui
      // ouvre l'inscription, et elle ne s'ouvre que sur une lecture reussie.
      case LectureProfil.absente:
        return PorteAcces.inscription;

      // Refus ou reseau : on ferme. Ouvrir l'inscription ici laisserait un
      // compte suspendu s'en refabriquer un.
      case LectureProfil.echouee:
        return PorteAcces.attente;

      case LectureProfil.presente:
        // Le profil existe mais le jeton ne porte pas encore son role : c'est
        // la fenetre entre la creation du profil et le rafraichissement du
        // jeton. On ferme le temps qu'elle se referme.
        if (role == null) {
          return PorteAcces.attente;
        }
        return switch (accountStatus) {
          AccountStatus.active ||
          AccountStatus.provisionalActive => PorteAcces.actif,
          AccountStatus.disabled => PorteAcces.suspendu,
          // Un statut absent ou illisible se traite comme une attente : on ne
          // laisse jamais passer par defaut ce qu'on n'a pas su lire.
          AccountStatus.pendingKyc || null => PorteAcces.attente,
        };
    }
  }

  /// Copie avec remplacement.
  SessionState copyWith({
    bool? resolue,
    AppRole? role,
    String? householdId,
    String? profileId,
    AccountStatus? accountStatus,
    InterfaceMode? interfaceMode,
    LectureProfil? lectureProfil,
  }) {
    return SessionState(
      resolue: resolue ?? this.resolue,
      role: role ?? this.role,
      householdId: householdId ?? this.householdId,
      profileId: profileId ?? this.profileId,
      accountStatus: accountStatus ?? this.accountStatus,
      interfaceMode: interfaceMode ?? this.interfaceMode,
      lectureProfil: lectureProfil ?? this.lectureProfil,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SessionState &&
      other.resolue == resolue &&
      other.role == role &&
      other.householdId == householdId &&
      other.profileId == profileId &&
      other.accountStatus == accountStatus &&
      other.interfaceMode == interfaceMode &&
      other.lectureProfil == lectureProfil;

  @override
  int get hashCode => Object.hash(
    resolue,
    role,
    householdId,
    profileId,
    accountStatus,
    interfaceMode,
    lectureProfil,
  );
}
