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

/// Genre du titulaire d'un profil. Enumere SQL `public.gender`.
///
/// **Un seul usage dans tout le produit** : confier un dossier d'identite a un
/// membre du personnel du meme genre (audit 1.3). Il ne pilote aucun droit,
/// aucun affichage, aucune notification. Quand il est inconnu, la lecture des
/// dossiers est refusee, jamais filtree a moitie.
enum Genre {
  /// Homme.
  homme('male'),

  /// Femme.
  femme('female');

  const Genre(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit un genre depuis sa valeur SQL. `null` si absent ou inconnu.
  static Genre? depuisSql(String? valeur) {
    for (final Genre genre in Genre.values) {
      if (genre.valeurSql == valeur) {
        return genre;
      }
    }
    return null;
  }
}

/// Type de piece d'identite. Contrainte SQL `kyc_documents.doc_type`.
enum TypePiece {
  /// Carte nationale d'identite.
  carteIdentite('id_card'),

  /// Passeport.
  passeport('passport'),

  /// Titre de sejour.
  titreSejour('residence_permit'),

  /// Autre piece, decrite en saisie libre.
  autre('other');

  const TypePiece(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit un type depuis sa valeur SQL. `null` si absent ou inconnu.
  static TypePiece? depuisSql(String? valeur) {
    for (final TypePiece type in TypePiece.values) {
      if (type.valeurSql == valeur) {
        return type;
      }
    }
    return null;
  }
}

/// Statut d'une piece deposee. Enumere SQL `public.kyc_doc_status`.
enum StatutPiece {
  /// Deposee, pas encore examinee.
  enAttente('pending'),

  /// Validee par l'administration.
  validee('approved'),

  /// Refusee, avec un motif.
  refusee('rejected');

  const StatutPiece(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL. `null` si absent ou inconnu.
  static StatutPiece? depuisSql(String? valeur) {
    for (final StatutPiece statut in StatutPiece.values) {
      if (statut.valeurSql == valeur) {
        return statut;
      }
    }
    return null;
  }
}

/// Ce qu'un utilisateur peut signer. Contrainte SQL
/// `contract_acceptances.contract_kind`.
enum SorteContrat {
  /// Conditions d'utilisation du tuteur.
  conditionsTuteur('guardian_terms'),

  /// Contrat de non-concurrence de l'enseignant.
  contratEnseignant('teacher_nda'),

  /// La carte a accuser une fois : enregistrement audio et visite de controle
  /// (ADR-011). Elle n'est pas un contrat, mais elle suit la meme regle : elle
  /// se signe une fois et ne se modifie jamais.
  accuseEnregistrementControle('recording_and_control_notice');

  const SorteContrat(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// La sorte de contrat que doit signer un role donne.
  static SorteContrat pour(AppRole role) => role == AppRole.teacher
      ? SorteContrat.contratEnseignant
      : SorteContrat.conditionsTuteur;
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
