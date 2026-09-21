import '../../../core/admin/service_comptes.dart';
import '../../../core/admin/service_configuration.dart';
import '../../../core/admin/service_groupes.dart';
import '../../../core/admin/service_programme.dart';
import '../../../core/appairage/service_appairage.dart';
import '../../../core/domain/enums.dart';
import '../../../core/dossier/etat_dossier.dart';
import '../../../core/dossier/service_dossier.dart';
import '../../../core/enseignant/modeles_enseignant.dart';
import '../../../core/enseignant/service_enseignant.dart';
import '../../../core/planning/service_planning.dart' show Creneau;
import '../../../core/tc_groupe/group_summary_vm.dart';
import '../../../core/tc_groupe/port_groupes.dart';
import 'classe_vm.dart';
import 'conformite.dart';
import 'erreur_domaine.dart';
import 'ports.dart';

/// Les adaptateurs qui branchent les ports de Classe sur ce que le serveur
/// sait deja faire.
///
/// **Aucun faux ici.** Chaque methode lit ou ecrit une donnee reelle par un
/// service existant de `lib/core/`, ou leve `capaciteAbsente` quand la base
/// n'a pas encore l'objet demande. Ce que le sprint attend d'Astra est ecrit
/// dans `docs/core24/CONTRACT_REQUEST_FABLE.md` : quand une RPC arrive, seul
/// l'adaptateur change, jamais l'ecran.
///
/// Les services sont recus comme des **fabriques** : `Supabase.instance` leve
/// tant que l'application n'est pas initialisee, et un adaptateur construit
/// dans un test ne doit pas echouer avant d'avoir ete appele.
class ClassesAdminDepuisExistant implements PortClassesAdmin {
  /// Cree l'adaptateur.
  const ClassesAdminDepuisExistant({
    required this.groupes,
    required this.programme,
    required this.configuration,
    required this.comptes,
  });

  /// Les groupes de l'administration (`groupes_admin`, `creer_groupe`).
  final ServiceGroupes Function() groupes;

  /// Le programme publie (`programme_versions_admin`, `programme_niveaux_admin`).
  final ServiceProgramme Function() programme;

  /// Les regles de l'academie (`app_config`).
  final ServiceConfiguration Function() configuration;

  /// Les comptes, pour la liste des enseignants (`comptes_admin`).
  final ServiceComptes Function() comptes;

  /// La cle de `app_config` qui porte la duree d'une seance.
  static const String cleDuree = 'session_duration_minutes';

  /// Le fuseau propose par defaut tant que `groupes_admin()` ne rend pas
  /// `timezone_iana` (demande §1.3 de `TC_CONTRACT_REQUEST_A.md`).
  static const String fuseauParDefaut = 'Europe/Paris';

  @override
  Future<List<ClasseVM>> classes() async {
    final ReglesClasse regles = await this.regles();
    final List<GroupeAdmin> lignes = await groupes().groupes();
    return lignes
        .map((GroupeAdmin g) => classeDepuisGroupeAdmin(g, regles: regles))
        .toList(growable: false);
  }

  @override
  Future<ReglesClasse> regles() async {
    int? duree;
    try {
      final List<ValeurConfig> valeurs = await configuration().lire(
        const <String>[cleDuree],
      );
      // Par cle, jamais par rang : un service qui rend plus que demande ne
      // doit pas faire lire une autre valeur a la place de la duree.
      for (final ValeurConfig lue in valeurs) {
        if (lue.cle == cleDuree && lue.valeur != null && lue.versEntier > 0) {
          duree = lue.versEntier;
        }
      }
    } on Object {
      // Une regle illisible ne bloque pas la creation : la base applique son
      // propre defaut, et l'ecran dit « Defaut de l'academie ».
      duree = null;
    }
    // Les capacites par public et le seuil minimal ne sont pas encore dans
    // `app_config` : `creer_groupe` applique son defaut quand `p_seuil_max`
    // est nul. Les laisser nuls, c'est exactement ce que la base attend.
    return ReglesClasse(fuseauIana: fuseauParDefaut, dureeMinutes: duree);
  }

  @override
  Future<List<ProgrammeChoix>> programmes() async {
    final List<VersionProgramme> versions = await programme().versions();
    VersionProgramme? active;
    for (final VersionProgramme v in versions) {
      if (v.statut == StatutVersionProgramme.publiee) {
        active = v;
        break;
      }
    }
    if (active == null) {
      return const <ProgrammeChoix>[];
    }
    final List<NiveauProgramme> niveaux = await programme().niveaux(active.id);
    return niveaux
        .map(
          (NiveauProgramme n) => ProgrammeChoix(
            niveauId: n.id,
            nomHumain: n.nomHumain,
            cycle: n.cycle,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<EnseignantEligible>> enseignantsEligibles(
    BrouillonClasse brouillon,
  ) async {
    // Les enseignants actifs, tels que `comptes_admin()` les rend. La
    // compatibilite avec le creneau et le public est une regle **serveur**
    // (`CONTRACT_REQUEST_FABLE.md`, demande 2) : tant qu'elle n'existe pas,
    // la liste est celle des enseignants reellement actifs, jamais un champ.
    final List<CompteAdmin> lignes = await comptes().comptes();
    return lignes
        .where(
          (CompteAdmin c) =>
              c.role == AppRole.teacher &&
              (c.etat == AccountStatus.active ||
                  c.etat == AccountStatus.provisionalActive),
        )
        .map(
          (CompteAdmin c) =>
              EnseignantEligible(id: c.profilId, nomAffichage: c.libelle),
        )
        .toList(growable: false);
  }

  @override
  Future<List<String>> publier(List<BrouillonClasse> brouillons) async {
    // `creer_groupe` exige un enseignant : publier sans lui est la capacite
    // que le sprint demande au serveur (`enseignant a affecter`). On le dit
    // AVANT de creer quoi que ce soit, pour ne jamais publier une moitie.
    if (brouillons.any((BrouillonClasse b) => b.enseignantId == null)) {
      throw const EchecDomaine(
        MotifEchec.capaciteAbsente,
        detailTechnique: 'creer_groupe exige p_teacher_profile_id',
      );
    }
    final List<String> crees = <String>[];
    for (final BrouillonClasse b in brouillons) {
      try {
        final String id = await groupes().creer(
          teacherId: b.enseignantId!,
          type: b.publicClasse == PublicClasse.enfants
              ? TypePublicGroupe.enfant
              : TypePublicGroupe.adulte,
          libelle: b.libelle,
          creneau: Creneau(
            jour: b.creneau.jourIso,
            heure: b.creneau.heure,
            fuseau: b.creneau.fuseauIana,
          ),
          seuilMax: b.capacite,
        );
        crees.add(id);
      } on Object catch (erreur) {
        final EchecDomaine echec = EchecDomaine.depuis(erreur);
        if (crees.isEmpty) {
          throw echec;
        }
        throw EchecPublicationPartielle(
          faites: crees.length,
          total: brouillons.length,
          motif: echec.motif,
          detailTechnique: echec.detailTechnique,
        );
      }
    }
    return crees;
  }

  @override
  Future<List<MembreClasse>> membres(String classeId) async {
    final List<MembreGroupe> lignes = await groupes().membres(classeId);
    return lignes
        .map((MembreGroupe m) => MembreClasse(id: m.studentId, libelle: m.libelle))
        .toList(growable: false);
  }
}

/// Une Classe lue depuis `groupes_admin()`.
ClasseVM classeDepuisGroupeAdmin(GroupeAdmin g, {required ReglesClasse regles}) =>
    ClasseVM(
      id: g.id,
      libelle: g.libelle,
      publicClasse: g.type == TypePublicGroupe.enfant
          ? PublicClasse.enfants
          : PublicClasse.adultes,
      creneau: CreneauClasse(
        jourIso: g.creneau.jour.clamp(1, 7),
        heure: g.creneau.heure.clamp(0, 23),
        fuseauIana: g.creneau.fuseau,
      ),
      duree: regles.dureeMinutes == null
          ? null
          : Duration(minutes: regles.dureeMinutes!),
      capacite: g.seuilMax < 1 ? 1 : g.seuilMax,
      inscrits: g.nombreMembres,
      etat: g.actif ? EtatPublication.publiee : EtatPublication.cloturee,
      enseignant: g.teacherId.isEmpty
          ? null
          : EnseignantClasse(id: g.teacherId, nomAffichage: g.teacherLibelle),
    );

/// Une Classe lue depuis `mes_groupes_v`, cote enseignant.
ClasseVM classeDepuisGroupeEnseignant(GroupeEnseignant g) => ClasseVM(
  id: g.id,
  libelle: g.libelle,
  publicClasse: g.type == TypePublicGroupe.enfant
      ? PublicClasse.enfants
      : PublicClasse.adultes,
  creneau: CreneauClasse(
    jourIso: g.creneau.jour.clamp(1, 7),
    heure: g.creneau.heure.clamp(0, 23),
    fuseauIana: g.creneau.fuseau,
  ),
  capacite: g.seuilMax < 1 ? 1 : g.seuilMax,
  inscrits: g.nbMembres,
  etat: EtatPublication.publiee,
  // C'est la Classe de l'appelant : l'enseignant est lui-meme. La vue ne
  // porte pas son nom, et la carte n'a pas a le dire.
  enseignant: const EnseignantClasse(id: '', nomAffichage: ''),
);

/// Une Classe lue depuis le port des groupes du Teaching Core, cote famille.
ClasseVM classeDepuisGroupSummary(GroupSummaryVM g) => ClasseVM(
  id: g.groupeId,
  libelle: g.libelle,
  programme: g.nomCours,
  niveauHumain: g.niveauHumain,
  publicClasse: g.typePublic == TypePublicGroupeVM.adulte
      ? PublicClasse.adultes
      : PublicClasse.enfants,
  creneau: CreneauClasse(
    // L'occurrence porte l'instant UTC ; le jour et l'heure locaux sont
    // rendus par l'horloge. A defaut, le motif hebdomadaire n'est pas connu
    // ici : on le reconstruit du debut UTC, ce qui est exact pour l'affichage
    // de la date rendue et ne sert jamais a convertir un fuseau.
    jourIso: g.prochaineSeance?.debutUtc.weekday ?? 1,
    heure: g.prochaineSeance?.debutUtc.hour ?? 0,
    fuseauIana:
        g.prochaineSeance?.fuseauReferenceGroupe ??
        g.horloge?.horlogeUtilisateur.fuseauIana ??
        'Europe/Paris',
  ),
  duree: g.prochaineSeance?.duree,
  capacite: g.seuilMax,
  inscrits: g.nombreMembres,
  etat: g.actif ? EtatPublication.publiee : EtatPublication.cloturee,
  enseignant: EnseignantClasse(
    id: g.enseignant.enseignantId,
    nomAffichage: g.enseignant.nomAffichage,
    titre: g.enseignant.titre,
  ),
  prochaineSeance: g.prochaineSeance == null
      ? null
      : SeanceAVenir(
          sessionId: g.prochaineSeance!.sessionId,
          debutUtc: g.prochaineSeance!.debutUtc,
          dateRendue: g.horloge?.horlogeUtilisateur.dateLocaleRendue,
          heureRendue: g.horloge?.horlogeUtilisateur.heureLocaleRendue,
          rejoindreOuvert: g.rejoindreOuvert,
        ),
  horloge: g.horloge,
  inscrit: true,
);

/// La marketplace, branchee sur ce que le serveur rend deja.
///
/// `mesClasses()` est reel : `mes_groupes_v` pour l'enseignant, le port des
/// groupes du Teaching Core pour la famille. Les trois autres capacites
/// (Classes disponibles, candidature, inscription, proposition de creneau)
/// sont **serveur** et n'existent pas encore : elles levent `capaciteAbsente`,
/// et l'ecran le dit.
class MarketplaceDepuisExistant implements PortMarketplaceClasses {
  /// Cree l'adaptateur.
  const MarketplaceDepuisExistant({
    required this.role,
    required this.enseignant,
    required this.groupes,
  });

  /// Le role de l'appelant, lu de la session a l'appel.
  final AppRole? Function() role;

  /// Le service de l'enseignant (`mes_groupes_v`).
  final ServiceEnseignant Function() enseignant;

  /// Le port des groupes du Teaching Core (famille).
  final PortGroupes Function() groupes;

  @override
  Future<List<ClasseVM>> mesClasses() async {
    if (role() == AppRole.teacher) {
      final List<GroupeEnseignant> lignes = await enseignant().groupes();
      return lignes.map(classeDepuisGroupeEnseignant).toList(growable: false);
    }
    final List<GroupSummaryVM> lignes = await groupes().mesGroupes();
    return lignes.map(classeDepuisGroupSummary).toList(growable: false);
  }

  @override
  Future<List<ClasseVM>> classesDisponibles({String? membreId}) =>
      Future<List<ClasseVM>>.error(
        const EchecDomaine(
          MotifEchec.capaciteAbsente,
          detailTechnique: 'classes_disponibles() absente',
        ),
      );

  @override
  Future<void> candidater(String classeId) => Future<void>.error(
    const EchecDomaine(
      MotifEchec.capaciteAbsente,
      detailTechnique: 'candidater_classe() absente',
    ),
  );

  @override
  Future<void> inscrire({required String classeId, required String membreId}) =>
      Future<void>.error(
        const EchecDomaine(
          MotifEchec.capaciteAbsente,
          detailTechnique: 'inscrire_classe() absente',
        ),
      );

  @override
  Future<void> proposerCreneau({
    required String membreId,
    required CreneauClasse creneau,
  }) => Future<void>.error(
    const EchecDomaine(
      MotifEchec.capaciteAbsente,
      detailTechnique: 'proposer_creneau() absente',
    ),
  );
}

/// La conformite, projetee depuis `etat_dossier()` et `comptes_admin()`.
///
/// **Les etats separes du sprint, lus dans des colonnes qui existent** :
/// le contrat dans `contract_acceptances`, la piece dans `kyc_documents`.
/// L'exigence se deduit du role (requise pour un enseignant, optionnelle
/// sinon) tant que la base ne porte pas de colonne d'exigence ; la dispense
/// n'a **aucune** source serveur aujourd'hui et n'est donc jamais inventee.
class ConformiteDepuisExistant implements PortConformite {
  /// Cree l'adaptateur.
  const ConformiteDepuisExistant({required this.dossier, required this.comptes});

  /// Le dossier de l'appelant (`etat_dossier`).
  final ServiceDossier Function() dossier;

  /// Les comptes, pour l'administration (`comptes_admin`).
  final ServiceComptes Function() comptes;

  @override
  Future<ConformiteCompte> laMienne() async {
    final EtatDossier etat = await dossier().etat();
    return ConformiteCompte(
      exigence: etat.role == AppRole.teacher
          ? ExigenceKyc.requise
          : ExigenceKyc.optionnelle,
      etat: !etat.pieceDeposee
          ? EtatKyc.nonCommence
          : switch (etat.statutPiece) {
              StatutPiece.validee => EtatKyc.verifie,
              StatutPiece.refusee => EtatKyc.refuse,
              StatutPiece.enAttente || null => EtatKyc.soumis,
            },
      contratAccepte: etat.contratSigne,
    );
  }

  @override
  Future<Map<String, ConformiteCompte>> pourComptes() async {
    final List<CompteAdmin> lignes = await comptes().comptes();
    return <String, ConformiteCompte>{
      for (final CompteAdmin c in lignes) c.profilId: conformiteDepuisCompte(c),
    };
  }

  @override
  Future<void> definirExigenceKyc({
    required String profilId,
    required bool requise,
    required String motif,
  }) => Future<void>.error(
    const EchecDomaine(
      MotifEchec.capaciteAbsente,
      detailTechnique: 'definir_exigence_kyc() absente',
    ),
  );
}

/// La conformite d'un compte, lue d'une ligne de `comptes_admin()`.
ConformiteCompte conformiteDepuisCompte(CompteAdmin c) => ConformiteCompte(
  exigence: c.role == AppRole.teacher
      ? ExigenceKyc.requise
      : ExigenceKyc.optionnelle,
  etat: switch (c.piece) {
    EtatPiece.aucune => EtatKyc.nonCommence,
    EtatPiece.aVerifier || EtatPiece.nonVisible => EtatKyc.soumis,
    EtatPiece.validee => EtatKyc.verifie,
    EtatPiece.refusee => EtatKyc.refuse,
  },
  contratAccepte: c.contrats > 0,
);

/// La precondition d'entree en Salle, lue du foyer.
///
/// `profils_du_foyer_v` rend la cle de photo de chaque membre : la photo est
/// donc **presente ou absente** pour de vrai. L'exigence, elle, est une regle
/// serveur que la base ne rend pas encore ; en attendant, seul un membre en
/// mode enfant est repute mineur, ce qui n'invente aucun blocage pour un
/// adulte. Un foyer illisible rend une precondition inconnue : le serveur
/// tranchera seul a l'emission du jeton.
class PreconditionDepuisFoyer implements PortPreconditionSalle {
  /// Cree l'adaptateur.
  const PreconditionDepuisFoyer({required this.appairage, this.monProfilId});

  /// Le service du foyer (`profils_du_foyer_v`).
  final ServiceAppairage Function() appairage;

  /// Le profil de l'appelant, pour une precondition sans `membreId`. Une
  /// fabrique, lue a l'appel et sous garde : une session illisible rend une
  /// precondition inconnue, jamais une erreur.
  final String? Function()? monProfilId;

  @override
  Future<PreconditionSalle> pour({String? membreId}) async {
    try {
      final String? cible = membreId ?? monProfilId?.call();
      if (cible == null) {
        return const PreconditionSalle.inconnue();
      }
      final List<EleveDuFoyer> membres = await appairage().eleves();
      for (final EleveDuFoyer m in membres) {
        if (m.id == cible) {
          return PreconditionSalle(
            prenom: m.prenom,
            photoRequise: m.mode == InterfaceMode.enfant,
            photoPresente: m.cleAvatar != null && m.cleAvatar!.trim().isNotEmpty,
          );
        }
      }
      return const PreconditionSalle.inconnue();
    } on Object {
      return const PreconditionSalle.inconnue();
    }
  }
}
