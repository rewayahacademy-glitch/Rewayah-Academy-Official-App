/// Miroirs Dart des types enumeres de la base.
///
/// Source de verite : `supabase/migrations/0001_fondations.sql` et
/// `0002_statut_attente_kyc.sql`. Les valeurs SQL sont en anglais, on les garde
/// telles quelles pour que la correspondance soit litterale et verifiable.
library;

/// Role d'un profil. Enumere SQL `public.app_role`.
enum AppRole {
  /// Administration de l'academie.
  admin('admin'),

  /// Comptabilite. Aucun ecran en MVP-0 (ADR-003).
  accountant('accountant'),

  /// Controleur qualite, observation invisible (ADR-011).
  controller('controller'),

  /// Enseignant.
  teacher('teacher'),

  /// Tuteur du foyer. Un eleve adulte autonome est son propre tuteur (ADR-009).
  guardian('guardian'),

  /// Eleve.
  student('student');

  const AppRole(this.valeurSql);

  /// La valeur telle qu'elle existe en base et dans le JWT.
  final String valeurSql;

  /// Lit un role depuis sa valeur SQL. Retourne `null` si la valeur est absente
  /// ou inconnue : un role illisible ne doit jamais se replier sur un role par
  /// defaut, il doit bloquer l'acces.
  static AppRole? depuisSql(String? valeur) {
    for (final AppRole role in AppRole.values) {
      if (role.valeurSql == valeur) {
        return role;
      }
    }
    return null;
  }
}

/// Statut d'un compte. Enumere SQL `public.account_status`.
///
/// Quatre valeurs conformement a l'ADR-014. `pendingKyc` est le defaut de toute
/// nouvelle inscription ; `provisionalActive` n'est atteignable que par un
/// import declenche par un administrateur, jamais par le parcours public.
enum AccountStatus {
  /// Inscription deposee, dossier non valide. Portail d'attente, aucun acces.
  pendingKyc('pending_kyc'),

  /// Compte valide.
  active('active'),

  /// Famille ou enseignant migre, acces complet, profil a completer sous 30 j.
  provisionalActive('provisional_active'),

  /// Compte suspendu par decision d'administration. Aucun acces.
  disabled('disabled');

  const AccountStatus(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL. Retourne `null` si la valeur est
  /// absente ou inconnue.
  static AccountStatus? depuisSql(String? valeur) {
    for (final AccountStatus statut in AccountStatus.values) {
      if (statut.valeurSql == valeur) {
        return statut;
      }
    }
    return null;
  }
}

/// Mode d'interface d'un eleve. Enumere SQL `public.interface_mode`.
///
/// Porte par le profil eleve, pas par le role (ADR-009). Il change ce qu'un
/// ecran affiche, jamais l'arborescence de navigation.
enum InterfaceMode {
  /// Environ 6 a 8 ans. Zero lecture, pictogrammes, audio, cibles de 72pt.
  enfant('child'),

  /// Environ 9 ans et plus, y compris les adultes autonomes.
  standard('standard');

  const InterfaceMode(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit un mode depuis sa valeur SQL. Se replie sur [standard], qui est le
  /// mode le moins permissif en surface d'affichage.
  static InterfaceMode depuisSql(String? valeur) {
    for (final InterfaceMode mode in InterfaceMode.values) {
      if (mode.valeurSql == valeur) {
        return mode;
      }
    }
    return InterfaceMode.standard;
  }
}

/// Politique camera d'un eleve. Enumere SQL `public.camera_policy`.
///
/// Attribut de profil fixe une fois, jamais une autorisation par seance
/// (ADR-009). Quand elle vaut [forbidden], le bouton camera **n'existe pas**
/// sur l'ecran : il n'est pas grise.
enum CameraPolicy {
  /// L'eleve allume et eteint sa camera librement.
  allowed('allowed'),

  /// Le token n'autorise que le micro. Aucun bouton camera n'est rendu.
  forbidden('forbidden');

  const CameraPolicy(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit une politique depuis sa valeur SQL. Se replie sur [forbidden], la
  /// valeur la plus protectrice.
  static CameraPolicy depuisSql(String? valeur) {
    for (final CameraPolicy politique in CameraPolicy.values) {
      if (politique.valeurSql == valeur) {
        return politique;
      }
    }
    return CameraPolicy.forbidden;
  }
}
