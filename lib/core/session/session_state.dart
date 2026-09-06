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

  /// Dossier non valide. Portail d'attente uniquement, quelle que soit l'URL
  /// tapee directement dans un navigateur.
  attente,

  /// Compte suspendu. Portail d'attente, avec un motif different.
  suspendu,

  /// Acces complet aux routes du role.
  actif,
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

  /// Vrai quand une session existe.
  bool get connecte => profileId != null;

  /// La porte a appliquer dans le routeur.
  PorteAcces get porte {
    if (!resolue) {
      return PorteAcces.chargement;
    }
    if (!connecte || role == null) {
      return PorteAcces.deconnecte;
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

  /// Copie avec remplacement.
  SessionState copyWith({
    bool? resolue,
    AppRole? role,
    String? householdId,
    String? profileId,
    AccountStatus? accountStatus,
    InterfaceMode? interfaceMode,
  }) {
    return SessionState(
      resolue: resolue ?? this.resolue,
      role: role ?? this.role,
      householdId: householdId ?? this.householdId,
      profileId: profileId ?? this.profileId,
      accountStatus: accountStatus ?? this.accountStatus,
      interfaceMode: interfaceMode ?? this.interfaceMode,
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
      other.interfaceMode == interfaceMode;

  @override
  int get hashCode => Object.hash(
    resolue,
    role,
    householdId,
    profileId,
    accountStatus,
    interfaceMode,
  );
}
