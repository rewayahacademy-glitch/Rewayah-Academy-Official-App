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
/// aucune notification. Quand il est inconnu, la lecture des dossiers est
/// refusee, jamais filtree a moitie.
///
/// **Une exception d'affichage, decidee par le directeur le 22/10/2026** : la
/// carte que la personne partage depuis la salle d'attente prend la variante de
/// son genre (la teinte et la branche fleurie) et l'invitation a partager dit « une sœur »
/// ou « une personne » (`core/partage_offre/port_genre_partageur.dart`). Le
/// genre y est lu sur le profil de la personne, jamais devine, et inconnu il
/// donne la variante neutre.
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

  /// Autre piece officielle : une carte a part entiere du depot, choisie
  /// explicitement (`other` en base). Aucun champ libre ne l'accompagne.
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
  accuseEnregistrementControle('recording_and_control_notice'),

  /// Le code de conduite de l'enseignant (PE, 18/10/2026). Meme regle que
  /// l'accuse : il se signe une fois par version et ne se modifie jamais.
  codeConduiteEnseignant('teacher_conduct_code');

  const SorteContrat(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// La sorte de contrat que doit signer un role donne.
  static SorteContrat pour(AppRole role) => role == AppRole.teacher
      ? SorteContrat.contratEnseignant
      : SorteContrat.conditionsTuteur;
}

/// Etat d'une seance. Enumere SQL `public.session_status`.
///
/// La machine a etats est tenue en base par `guard_session_state_transition` :
/// cette enumeration ne fait que lire ce qu'elle a decide.
enum StatutSeance {
  /// Planifiee, personne n'est encore entre.
  planifiee('planned'),

  /// Verification technique en cours, avant l'entree en salle.
  preflight('preflight'),

  /// En cours.
  enCours('in_progress'),

  /// Terminee normalement.
  terminee('ended'),

  /// L'enseignant ne s'est pas presente.
  enseignantAbsent('teacher_absent'),

  /// L'eleve ne s'est pas presente.
  eleveAbsent('student_absent'),

  /// Interrompue par un incident technique.
  incidentTechnique('tech_failure'),

  /// Annulee tardivement.
  annuleeTard('canceled_late'),

  /// Annulee.
  annulee('canceled');

  const StatutSeance(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL. `null` si absent ou inconnu : un etat
  /// illisible ne doit pas se replier sur « planifiee », qui ferait croire a un
  /// cours a venir.
  static StatutSeance? depuisSql(String? valeur) {
    for (final StatutSeance statut in StatutSeance.values) {
      if (statut.valeurSql == valeur) {
        return statut;
      }
    }
    return null;
  }

  /// Vrai quand la seance n'aura pas lieu, quelle qu'en soit la raison.
  bool get estAnnulee =>
      this == StatutSeance.annulee || this == StatutSeance.annuleeTard;
}

/// Ce qu'une partie peut demander. Contrainte SQL `matching_requests.kind`.
///
/// Les trois sortes suivent le meme chemin : une demande motivee, une decision
/// de l'administration, un effet applique en base (ADR-017).
enum SorteDemande {
  /// Changer l'enseignant d'un eleve. Le seul chemin de rupture d'une
  /// affectation : personne ne se degage seul.
  reaffectation('reassignment'),

  /// Augmenter le plafond d'eleves d'un enseignant.
  plafond('capacity'),

  /// Changer une regle d'un eleve, duree ou minimum payable.
  regle('rule_change');

  const SorteDemande(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit une sorte depuis sa valeur SQL. `null` si absente ou inconnue.
  static SorteDemande? depuisSql(String? valeur) {
    for (final SorteDemande sorte in SorteDemande.values) {
      if (sorte.valeurSql == valeur) {
        return sorte;
      }
    }
    return null;
  }
}

/// Ou en est une demande. Contrainte SQL `matching_requests.status`.
enum StatutDemande {
  /// En attente d'une decision de l'administration.
  enAttente('pending'),

  /// Accordee, et son effet est deja applique en base.
  accordee('approved'),

  /// Refusee, avec un motif.
  refusee('rejected');

  const StatutDemande(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit un statut depuis sa valeur SQL. `null` si absent ou inconnu.
  static StatutDemande? depuisSql(String? valeur) {
    for (final StatutDemande statut in StatutDemande.values) {
      if (statut.valeurSql == valeur) {
        return statut;
      }
    }
    return null;
  }
}

/// Les regles qui peuvent differer d'un profil a l'autre (ADR-017 section 2.4).
///
/// **Aucune de ces valeurs n'est une constante Dart.** Elles se lisent par
/// `regle_effective()`, qui rend celle de ce profil, et non celle de la
/// plateforme. Un ecran qui lirait la valeur par defaut afficherait la mauvaise
/// regle a l'eleve qui n'en releve pas, et l'ecart ne se verrait qu'au moment
/// de la facture.
enum CleRegle {
  /// Duree d'une seance, en minutes.
  dureeSeance('session_duration_minutes'),

  /// Duree de presence minimale qui rend la seance payable, en minutes. Elle
  /// existe pour qu'une pause ou une priere ne fasse jamais tomber une seance
  /// sous le seuil de remuneration.
  minimumPayable('session_paid_minimum_minutes'),

  /// Pause entre deux cours, en minutes.
  pauseEntreCours('break_minutes_between_sessions'),

  /// Plafond d'eleves d'un enseignant. Seule regle qui porte sur un enseignant
  /// et non sur un eleve.
  plafondEleves('max_students_per_teacher');

  const CleRegle(this.valeurSql);

  /// La cle telle qu'elle existe en base.
  final String valeurSql;

  /// Lit une cle depuis sa valeur SQL. `null` si absente ou inconnue.
  static CleRegle? depuisSql(String? valeur) {
    for (final CleRegle cle in CleRegle.values) {
      if (cle.valeurSql == valeur) {
        return cle;
      }
    }
    return null;
  }
}

/// Une des cinq prieres. Cles de `prayer_settings.adjustments`, tenues par
/// `guard_prayer_adjustments` : ni plus, ni moins que ces cinq-la.
///
/// Le lever du soleil n'en fait pas partie. Le paquet de calcul le rend parce
/// qu'il borne le fajr, mais ce n'est pas une priere et cela n'interrompt aucun
/// cours.
enum Priere {
  /// Aube.
  fajr('fajr'),

  /// Midi.
  dhuhr('dhuhr'),

  /// Apres-midi. Son heure depend de l'ecole, voir [Madhab].
  asr('asr'),

  /// Coucher du soleil.
  maghrib('maghrib'),

  /// Nuit.
  isha('isha');

  const Priere(this.valeurSql);

  /// La cle telle qu'elle existe dans le jsonb des ajustements.
  final String valeurSql;

  /// Lit une priere depuis sa cle. `null` si absente ou inconnue.
  static Priere? depuisSql(String? valeur) {
    for (final Priere priere in Priere.values) {
      if (priere.valeurSql == valeur) {
        return priere;
      }
    }
    return null;
  }
}

/// Methode de calcul des horaires. Contrainte SQL `prayer_settings.method`.
///
/// Les douze valeurs sont celles du paquet `adhan`, reprises telles quelles :
/// une correspondance nom pour nom se verifie a l'oeil, une table de traduction
/// se trompe en silence.
enum MethodeCalcul {
  /// Ligue islamique mondiale. Defaut de la base.
  ligueMondiale('muslim_world_league'),

  /// Autorite generale egyptienne.
  egypte('egyptian'),

  /// Universite des sciences islamiques de Karachi.
  karachi('karachi'),

  /// Umm al-Qura, La Mecque.
  ummAlQura('umm_al_qura'),

  /// Golfe.
  dubai('dubai'),

  /// Moon Sighting Committee.
  moonSighting('moon_sighting_committee'),

  /// ISNA, Amerique du Nord.
  ameriqueDuNord('north_america'),

  /// Koweit.
  koweit('kuwait'),

  /// Qatar.
  qatar('qatar'),

  /// Singapour.
  singapour('singapore'),

  /// Teheran.
  teheran('tehran'),

  /// Diyanet, Turquie.
  turquie('turkey');

  const MethodeCalcul(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit une methode depuis sa valeur SQL. **`null` si elle est inconnue**, et
  /// surtout pas un repli sur la methode par defaut : une heure calculee avec
  /// la mauvaise methode est annoncee a tout le monde avec le meme aplomb, et
  /// c'est precisement le litige que l'ADR-017 ferme. Mieux vaut n'annoncer
  /// aucune interruption que la mauvaise.
  static MethodeCalcul? depuisSql(String? valeur) {
    for (final MethodeCalcul methode in MethodeCalcul.values) {
      if (methode.valeurSql == valeur) {
        return methode;
      }
    }
    return null;
  }
}

/// Ecole juridique qui decide de l'heure du asr. Contrainte SQL
/// `prayer_settings.madhab`.
enum Madhab {
  /// Ombre egale a la hauteur de l'objet. Defaut de la base.
  shafi('shafi'),

  /// Ombre egale au double. Le asr y tombe plus tard.
  hanafi('hanafi');

  const Madhab(this.valeurSql);

  /// La valeur telle qu'elle existe en base.
  final String valeurSql;

  /// Lit une ecole depuis sa valeur SQL. `null` si absente ou inconnue, pour la
  /// meme raison que [MethodeCalcul.depuisSql].
  static Madhab? depuisSql(String? valeur) {
    for (final Madhab madhab in Madhab.values) {
      if (madhab.valeurSql == valeur) {
        return madhab;
      }
    }
    return null;
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
