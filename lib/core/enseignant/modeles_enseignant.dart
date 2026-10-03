/// Les modeles du role Enseignant.
///
/// Contrat partage du lot « role Enseignant » (protocole multi-agents du
/// 19 septembre 2026). **Ecrit par l'Agent Z, consomme par les agents A a E,
/// modifie par personne d'autre** : voir
/// `docs/archive/2026-09-pre-remise-a-plat/architecture/TEACHER_FILE_OWNERSHIP.md`.
///
/// Rien ici ne duplique un modele existant. [Creneau], [TypePublicGroupe],
/// [PositionLecture] et [EtatPresence] sont importes plutot que recrees.
library;

import 'package:flutter/foundation.dart';

import '../admin/service_groupes.dart' show TypePublicGroupe;
import '../coran/service_coran.dart' show PositionLecture;
import '../domain/enums.dart';
import '../planning/service_planning.dart' show Creneau;
import '../presence/service_presence.dart' show EtatPresence;

/// Une seance telle que l'enseignant la lit : **une ligne par seance**.
///
/// Pourquoi un modele de plus a cote de `Seance`. `mes_seances_v` joint
/// `session_participants` et rend donc une ligne **par eleve** : pour un cours
/// de groupe, la meme seance y revient cinq fois. `Seance` est juste pour le
/// tuteur et l'eleve, qui ne voient que leur propre ligne ; elle ne peut pas
/// porter la Journee d'un enseignant de groupe. Ce modele lit
/// `mes_seances_enseignant_v`, groupee par seance (migration `0025`).
///
/// Il ne porte **aucun prenom**, volontairement : le roster se lit a part, par
/// [MembreSeance], qui applique le masquage d'observation.
@immutable
class SeanceEnseignant {
  /// Cree une seance.
  const SeanceEnseignant({
    required this.id,
    required this.debut,
    required this.fin,
    required this.statut,
    required this.nbParticipants,
    required this.cahierDepose,
    this.groupeId,
    this.groupeLibelle,
    this.typePublic,
    this.seuilMax,
    this.minutesInterruption = 0,
  });

  /// Lit une ligne de `mes_seances_enseignant_v`.
  factory SeanceEnseignant.depuisJson(Map<String, dynamic> json) =>
      SeanceEnseignant(
        id: json['session_id'] as String,
        debut:
            DateTime.tryParse(json['started_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        fin:
            DateTime.tryParse(json['ended_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        statut: StatutSeance.depuisSql(json['status'] as String?),
        nbParticipants: (json['nb_participants'] as num?)?.toInt() ?? 0,
        cahierDepose: json['cahier_depose'] as bool? ?? false,
        groupeId: json['groupe_id'] as String?,
        groupeLibelle: json['groupe_libelle'] as String?,
        typePublic: json['type_public'] == null
            ? null
            : TypePublicGroupe.depuisSql(json['type_public'] as String?),
        seuilMax: (json['seuil_max'] as num?)?.toInt(),
        minutesInterruption:
            (json['prayer_pause_minutes'] as num?)?.toInt() ?? 0,
      );

  /// Identifiant de la seance.
  final String id;

  /// Debut, dans le fuseau de l'appareil.
  final DateTime debut;

  /// Fin prevue.
  final DateTime fin;

  /// L'etat tel que la base l'a decide. `null` quand il est illisible : un etat
  /// illisible ne se replie jamais sur `planifiee`, qui ferait croire a un cours
  /// a venir.
  final StatutSeance? statut;

  /// Le nombre d'eleves attendus.
  final int nbParticipants;

  /// Vrai quand le cahier de transmission a deja ete depose.
  final bool cahierDepose;

  /// Le groupe dont cette seance est la reunion. Nul pour un cours individuel.
  final String? groupeId;

  /// Le nom du groupe. Nul pour un cours individuel.
  final String? groupeLibelle;

  /// Le public du groupe. Nul pour un cours individuel.
  final TypePublicGroupe? typePublic;

  /// Le plafond du groupe. Nul pour un cours individuel.
  final int? seuilMax;

  /// Minutes d'interruption consignees, prieres comprises (ADR-017).
  final int minutesInterruption;

  /// Vrai quand cette seance est la reunion d'un groupe.
  ///
  /// Une seance sans groupe est un cours individuel anterieur au pivot du
  /// 19 septembre 2026, pas une donnee incomplete.
  bool get estGroupe => groupeId != null;

  /// La duree prevue.
  Duration get duree => fin.difference(debut);

  /// Vrai quand la seance se tient a l'instant donne.
  ///
  /// Un cours que la base declare `en_cours` l'emporte sur l'heure : un cours
  /// qui deborde reste le cours courant.
  bool enCoursA(DateTime maintenant) =>
      statut == StatutSeance.enCours ||
      (!maintenant.isBefore(debut) && maintenant.isBefore(fin));

  /// Le temps restant avant le debut. Zero quand il est passe.
  Duration avantDebut(DateTime maintenant) {
    final Duration reste = debut.difference(maintenant);
    return reste.isNegative ? Duration.zero : reste;
  }

  /// Vrai quand la seance est terminee et attend son cahier.
  bool get attendSonCahier =>
      !cahierDepose &&
      (statut == StatutSeance.terminee ||
          statut == StatutSeance.eleveAbsent ||
          statut == StatutSeance.incidentTechnique);
}

/// Un eleve d'une seance ou d'un groupe, vu par son enseignant.
///
/// **Aucun champ de nom de famille n'existe ici, et c'est le point.**
/// `MembreGroupe` (`core/admin/service_groupes.dart`) en porte un parce que
/// l'administration en a le droit ; l'enseignant ne l'a pas (ADR-008). Un modele
/// distinct tient l'invariant par construction plutot que par vigilance : il n'y
/// a pas de champ a oublier de masquer.
@immutable
class MembreSeance {
  /// Cree un membre.
  const MembreSeance({
    required this.studentId,
    required this.identifiantImmuable,
    this.prenom,
    this.niveau,
    this.riwaya,
    this.rejointLe,
  });

  /// Lit une ligne de `teacher_roster_v`.
  factory MembreSeance.depuisRoster(Map<String, dynamic> json) => MembreSeance(
    studentId: json['student_id'] as String,
    identifiantImmuable: json['immutable_id'] as String? ?? '',
    prenom: json['first_name'] as String?,
    niveau: json['level'] as String?,
    riwaya: json['riwaya'] as String?,
  );

  /// Lit une ligne de `mon_groupe_detail()`.
  factory MembreSeance.depuisGroupe(Map<String, dynamic> json) => MembreSeance(
    studentId: json['student_id'] as String,
    identifiantImmuable: json['identifiant_immuable'] as String? ?? '',
    prenom: json['prenom'] as String?,
    niveau: json['niveau'] as String?,
    riwaya: json['riwaya'] as String?,
    rejointLe: DateTime.tryParse(json['joined_at'] as String? ?? '')?.toLocal(),
  );

  /// L'identifiant technique de l'eleve.
  final String studentId;

  /// L'identifiant immuable, celui que l'enseignant voit et prononce.
  final String identifiantImmuable;

  /// Le prenom. **Nul quand un agent observe** : le masquage vient de la base,
  /// pas de l'ecran.
  final String? prenom;

  /// Le niveau, tel que `student_profiles.level` le tient.
  final String? niveau;

  /// La riwaya suivie.
  final String? riwaya;

  /// La date d'entree dans le groupe. Nulle quand la source est un roster de
  /// seance, qui ne la porte pas.
  final DateTime? rejointLe;

  /// Ce qui s'affiche pour nommer l'eleve.
  ///
  /// L'identifiant immuable prend le relais quand le prenom est masque : un
  /// eleve doit rester designable meme sous observation.
  String get libelle {
    final String? p = prenom?.trim();
    return p == null || p.isEmpty ? identifiantImmuable : p;
  }
}

/// Un groupe, vu par son enseignant.
///
/// Distinct de `GroupeAdmin` pour la meme raison que [MembreSeance] : celui-la
/// porte `teacherNom`, que l'enseignant n'a pas a lire, et lui vient de
/// `groupes_admin()`, reserve a l'administration.
@immutable
class GroupeEnseignant {
  /// Cree un groupe.
  const GroupeEnseignant({
    required this.id,
    required this.libelle,
    required this.type,
    required this.seuilMax,
    required this.creneau,
    required this.nbMembres,
    required this.creeLe,
  });

  /// Lit une ligne de `mes_groupes_v`.
  factory GroupeEnseignant.depuisJson(Map<String, dynamic> json) {
    int entier(String cle) => (json[cle] as num?)?.toInt() ?? 0;

    return GroupeEnseignant(
      id: json['groupe_id'] as String,
      libelle: json['libelle'] as String? ?? '',
      type: TypePublicGroupe.depuisSql(json['type_public'] as String?),
      seuilMax: entier('seuil_max'),
      creneau: Creneau(
        jour: entier('weekday'),
        heure: entier('hour_local'),
        fuseau: json['timezone_iana'] as String? ?? 'Europe/Paris',
      ),
      nbMembres: entier('nb_membres'),
      creeLe:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  /// L'identifiant du groupe.
  final String id;

  /// Le nom du groupe.
  final String libelle;

  /// Le public du groupe.
  final TypePublicGroupe type;

  /// Le plafond de membres actifs.
  final int seuilMax;

  /// Le rendez-vous hebdomadaire partage.
  final Creneau creneau;

  /// Le nombre de membres actifs.
  final int nbMembres;

  /// Depuis quand le groupe existe.
  final DateTime creeLe;

  /// Les places encore libres. Jamais negatif.
  int get placesLibres => seuilMax - nbMembres < 0 ? 0 : seuilMax - nbMembres;

  /// Vrai quand le groupe est au plafond.
  bool get complet => nbMembres >= seuilMax;
}

/// Une seance terminee dont le cahier manque.
///
/// C'est la file que `ENS-02` affiche sous « rapports en attente », et dont une
/// ligne disparait d'elle-meme des que le cahier est depose.
@immutable
class CahierEnRetard {
  /// Cree une ligne de retard.
  const CahierEnRetard({
    required this.seanceId,
    required this.debut,
    required this.fin,
    required this.nbParticipants,
    required this.heuresDeRetard,
    this.groupeId,
    this.groupeLibelle,
  });

  /// Lit une ligne de `mes_rapports_en_attente()`.
  factory CahierEnRetard.depuisJson(Map<String, dynamic> json) =>
      CahierEnRetard(
        seanceId: json['session_id'] as String,
        debut:
            DateTime.tryParse(json['started_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        fin:
            DateTime.tryParse(json['ended_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        nbParticipants: (json['nb_participants'] as num?)?.toInt() ?? 0,
        heuresDeRetard: (json['heures_de_retard'] as num?)?.toInt() ?? 0,
        groupeId: json['groupe_id'] as String?,
        groupeLibelle: json['groupe_libelle'] as String?,
      );

  /// La seance concernee.
  final String seanceId;

  /// Quand elle a commence.
  final DateTime debut;

  /// Quand elle s'est terminee.
  final DateTime fin;

  /// Combien d'eleves elle comptait.
  final int nbParticipants;

  /// Depuis combien d'heures le cahier manque.
  final int heuresDeRetard;

  /// Le groupe, s'il y en avait un.
  final String? groupeId;

  /// Le nom du groupe, s'il y en avait un.
  final String? groupeLibelle;

  /// Vrai au dela de vingt-quatre heures : c'est le seuil a partir duquel la
  /// Journee parle de retard et non plus d'attente.
  bool get enRetard => heuresDeRetard >= 24;
}

/// L'unite de curriculum d'un eleve, quand le programme existe.
///
/// **Nulle tant que les migrations `0020` a `0024` ne sont pas appliquees**, et
/// l'ecran doit alors taire le sujet : une ligne « unite : - » serait une
/// promesse non tenue a chaque eleve.
@immutable
class UniteCurriculum {
  /// Cree une unite.
  const UniteCurriculum({
    required this.niveauId,
    required this.nomHumain,
    required this.codeTechnique,
    required this.cycle,
    required this.ordre,
    this.depuis,
  });

  /// Lit l'objet `unite_curriculum` du brouillon. `null` quand le programme
  /// pedagogique n'est pas installe.
  static UniteCurriculum? depuisJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return UniteCurriculum(
      niveauId: json['niveau_id'] as String? ?? '',
      nomHumain: json['nom_humain'] as String? ?? '',
      codeTechnique: json['code_technique'] as String? ?? '',
      cycle: json['cycle'] as String? ?? '',
      ordre: (json['ordre'] as num?)?.toInt() ?? 0,
      depuis: DateTime.tryParse(json['depuis'] as String? ?? '')?.toLocal(),
    );
  }

  /// L'identifiant du niveau.
  final String niveauId;

  /// **Le libelle a afficher.**
  final String nomHumain;

  /// L'identifiant technique, par exemple `F1-PHO-01`.
  ///
  /// **Interdiction UX explicite** : il ne sert jamais de titre, seulement de
  /// sous-texte technique discret (`0020_programme_pedagogique.sql`).
  final String codeTechnique;

  /// Le cycle auquel ce niveau appartient.
  final String cycle;

  /// La place du niveau dans son cycle.
  final int ordre;

  /// Depuis quand l'eleve est a ce niveau.
  final DateTime? depuis;
}

/// Un eleve, tel que le brouillon du cahier le prerempli.
@immutable
class ParticipantBrouillon {
  /// Cree une ligne de brouillon.
  const ParticipantBrouillon({
    required this.membre,
    required this.presence,
    this.entreLe,
    this.derniereTraceLe,
    this.position,
    this.unite,
    this.devoirPrecedent,
    this.suspensionPermise = true,
    this.performancePrecedente,
    this.faiblessesPrecedentes = const <FaiblesseRecitation>{},
  });

  /// Lit une ligne du tableau `participants`.
  factory ParticipantBrouillon.depuisJson(Map<String, dynamic> json) =>
      ParticipantBrouillon(
        membre: MembreSeance(
          studentId: json['student_id'] as String,
          identifiantImmuable: json['identifiant_immuable'] as String? ?? '',
          prenom: json['prenom'] as String?,
          niveau: json['niveau'] as String?,
          riwaya: json['riwaya'] as String?,
        ),
        presence: EtatPresence.depuisSql(json['presence'] as String?),
        entreLe: DateTime.tryParse(json['entre_le'] as String? ?? '')
            ?.toLocal(),
        derniereTraceLe: DateTime.tryParse(
          json['derniere_trace_le'] as String? ?? '',
        )?.toLocal(),
        position: switch (json['position']) {
          final Map<String, dynamic> p => PositionLecture.depuisJson(p),
          _ => null,
        },
        unite: UniteCurriculum.depuisJson(
          json['unite_curriculum'] as Map<String, dynamic>?,
        ),
        devoirPrecedent: json['devoir_precedent'] as String?,
        suspensionPermise: json['suspension_permise'] as bool? ?? true,
        performancePrecedente: NiveauPerformance.depuisNom(
          json['performance_precedente'] as String?,
        ),
        faiblessesPrecedentes: FaiblesseRecitation.depuisNoms(
          json['faiblesses_precedentes'] as List<Object?>?,
        ),
      );

  /// Le niveau retenu a la seance precedente (N1, directeur 27/09), pour
  /// preremplir le cahier. Nul s'il n'y en avait pas.
  final NiveauPerformance? performancePrecedente;

  /// Les faiblesses cochees a la seance precedente, pour preremplir le cahier.
  final Set<FaiblesseRecitation> faiblessesPrecedentes;

  /// Le devoir donne a la seance precedente, tel que le systeme l'a garde
  /// (doc 04 §20.1, « travail precedent »). Nul s'il n'y en avait pas.
  final String? devoirPrecedent;

  /// Vrai quand la logique academique permet de proposer « Suspendre le
  /// nouveau » pour cet eleve (doc 04 §20.4). Vrai par defaut tant que le
  /// serveur ne le dit pas (BR-1).
  final bool suspensionPermise;

  /// L'eleve.
  final MembreSeance membre;

  /// La presence **deduite par la base**, jamais saisie par l'enseignant.
  ///
  /// Jamais nulle : [EtatPresence.inconnu] porte deja l'absence de reponse, et
  /// une presence indisponible s'affiche « inconnu », jamais « absent »
  /// (invariant J3, lot N4). Un second « je ne sais pas » sous forme de `null`
  /// ferait deux facons de dire la meme chose.
  final EtatPresence presence;

  /// Premiere entree en salle.
  final DateTime? entreLe;

  /// Derniere trace laissee dans la seance.
  final DateTime? derniereTraceLe;

  /// Ou l'eleve en etait dans sa lecture.
  ///
  /// **Sa position lui appartient** (invariant J2) : l'enseignant la LIT pour
  /// preremplir « ce qui a ete travaille », il ne l'ecrit jamais. Une page
  /// tournee par l'enseignant pour tout le groupe n'ecrase pas l'endroit ou
  /// chacun en etait.
  final PositionLecture? position;

  /// L'unite de curriculum, quand le programme existe.
  final UniteCurriculum? unite;

  /// Vrai quand cet eleve est une **exception** a confirmer par l'enseignant.
  ///
  /// C'est tout le principe anti-burnout : par defaut chaque ligne vaut
  /// « Continuer », et l'enseignant ne touche que celles-ci. Une presence
  /// inconnue en fait partie : ne pas savoir demande un regard, exactement
  /// comme une absence.
  bool get estUneException => switch (presence) {
    EtatPresence.presente ||
    EtatPresence.reconnectee ||
    EtatPresence.finalisee => false,
    _ => true,
  };
}

/// Un evenement de seance, tel que le serveur l'a consigne.
@immutable
class EvenementSeance {
  /// Cree un evenement.
  const EvenementSeance({
    required this.type,
    required this.instant,
    this.profilId,
  });

  /// Lit une ligne du tableau `evenements`.
  factory EvenementSeance.depuisJson(Map<String, dynamic> json) =>
      EvenementSeance(
        type: json['type'] as String? ?? '',
        instant:
            DateTime.tryParse(json['instant'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        profilId: json['profile_id'] as String?,
      );

  /// Le type, valeur SQL de `session_event_type`.
  final String type;

  /// Quand il a eu lieu, heure serveur ramenee au fuseau de l'appareil.
  final DateTime instant;

  /// Qui il concerne. Nul pour un evenement de salle.
  final String? profilId;
}

/// Tout ce que le systeme sait deja d'une seance, avant que l'enseignant
/// n'ecrive un mot.
///
/// C'est le contrat qui rend l'objectif des 45 secondes atteignable : presence,
/// duree, contenu presente, unite et evenements sont **deduits**, et
/// l'enseignant ne confirme que les exceptions. Aucune donnee deductible ne lui
/// est redemandee.
@immutable
class BrouillonCahier {
  /// Cree un brouillon.
  const BrouillonCahier({
    required this.seanceId,
    required this.debut,
    required this.fin,
    required this.statut,
    required this.dureeMinutes,
    required this.minutesInterruption,
    required this.dejaDepose,
    required this.participants,
    required this.evenements,
    this.groupeId,
  });

  /// Lit ce que rend `brouillon_cahier()`.
  factory BrouillonCahier.depuisJson(Map<String, dynamic> json) =>
      BrouillonCahier(
        seanceId: json['session_id'] as String,
        debut:
            DateTime.tryParse(json['debut'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        fin:
            DateTime.tryParse(json['fin'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        statut: StatutSeance.depuisSql(json['statut'] as String?),
        dureeMinutes: (json['duree_minutes'] as num?)?.toInt() ?? 0,
        minutesInterruption:
            (json['minutes_interruption'] as num?)?.toInt() ?? 0,
        dejaDepose: json['deja_depose'] as bool? ?? false,
        groupeId: json['groupe_id'] as String?,
        participants: <ParticipantBrouillon>[
          for (final Object? ligne
              in json['participants'] as List<Object?>? ?? const <Object?>[])
            ParticipantBrouillon.depuisJson(ligne! as Map<String, dynamic>),
        ],
        evenements: <EvenementSeance>[
          for (final Object? ligne
              in json['evenements'] as List<Object?>? ?? const <Object?>[])
            EvenementSeance.depuisJson(ligne! as Map<String, dynamic>),
        ],
      );

  /// La seance concernee.
  final String seanceId;

  /// Debut de la seance.
  final DateTime debut;

  /// Fin de la seance.
  final DateTime fin;

  /// L'etat de la seance.
  final StatutSeance? statut;

  /// La duree reelle, calculee par la base.
  final int dureeMinutes;

  /// Les minutes d'interruption consignees.
  final int minutesInterruption;

  /// Vrai quand un cahier existe deja pour cette seance.
  final bool dejaDepose;

  /// Le groupe, s'il y en a un.
  final String? groupeId;

  /// Les eleves, prets a confirmer.
  final List<ParticipantBrouillon> participants;

  /// Les evenements consignes par le serveur.
  final List<EvenementSeance> evenements;

  /// Les seuls eleves que l'enseignant doit regarder.
  List<ParticipantBrouillon> get exceptions => participants
      .where((ParticipantBrouillon p) => p.estUneException)
      .toList(growable: false);

  /// Vrai quand rien ne demande l'attention de l'enseignant : il valide d'un
  /// geste.
  bool get toutEstNominal => exceptions.isEmpty && participants.isNotEmpty;
}

/// Ce que l'enseignant decide pour un eleve, en complement de ce que la base a
/// deduit.
///
/// Volontairement etroit. L'enseignant confirme, signale une exception, note un
/// point phonetique, ajuste un objectif personnel et le travail maison. Il ne
/// peut pas modifier le curriculum institutionnel, changer un cycle fixe, ni
/// valider un gate : aucun champ ne le lui permet.
@immutable
class DecisionEleve {
  /// Cree une decision.
  const DecisionEleve({
    required this.studentId,
    this.confirme = true,
    this.motifException,
    this.pointPhonetique,
    this.objectifPersonnel,
    this.travailMaison,
    this.devoirSuggere = false,
    this.suite = SuiteEleve.continuer,
    this.performance,
    this.faiblesses = const <FaiblesseRecitation>{},
  });

  /// La decision de depart d'un eleve : la performance et les faiblesses de
  /// la seance precedente, reprises telles quelles (N1, cahier en moins de
  /// 45 s). L'enseignant les confirme en validant, ou les change.
  ///
  /// EN-7c-SUGG-T : le devoir n'est **pas** prerempli. Aucune source de
  /// devoir propose n'existe : `brouillon_cahier()` ne rend que le devoir de
  /// la seance precedente ([ParticipantBrouillon.devoirPrecedent]), deja
  /// rappele en lecture, et le recopier comme devoir a venir serait inventer
  /// une decision pedagogique. [devoirSuggere] reste donc faux ici.
  factory DecisionEleve.preremplie(ParticipantBrouillon participant) =>
      DecisionEleve(
        studentId: participant.membre.studentId,
        performance: participant.performancePrecedente,
        faiblesses: participant.faiblessesPrecedentes,
      );

  /// L'echelle de performance, choix unique (N1, directeur 27/09).
  final NiveauPerformance? performance;

  /// Les faiblesses constatees, choix multiple (N1, directeur 27/09).
  final Set<FaiblesseRecitation> faiblesses;

  /// L'eleve concerne.
  final String studentId;

  /// Vrai quand l'enseignant confirme ce que la base a deduit. C'est le defaut.
  final bool confirme;

  /// Le motif, quand l'enseignant signale une exception.
  final String? motifException;

  /// Un point de prononciation utile, consigne dans `makharij_findings`.
  final String? pointPhonetique;

  /// L'objectif personnel, dans la marge autorisee par les regles.
  final String? objectifPersonnel;

  /// Le travail maison : saisi par l'enseignant, ou ajuste a partir d'une
  /// suggestion du systeme quand [devoirSuggere] est vrai.
  final String? travailMaison;

  /// Vrai seulement quand [travailMaison] vient d'une suggestion du systeme,
  /// pas encore modifiee par l'enseignant (K-57 : proposer, puis saisir).
  /// La feuille ne dit « Ajustez la suggestion » que dans ce cas. Provenance
  /// d'ecran : elle ne part pas dans le cahier.
  final bool devoirSuggere;

  /// La suite pedagogique choisie pour cet eleve (doc 04 §20.4). « Continuer »
  /// par defaut.
  final SuiteEleve suite;

  /// Vrai quand l'enseignant suspend le nouveau contenu pour cet eleve.
  bool get nouveauSuspendu => suite == SuiteEleve.suspendreNouveau;

  /// Ce qui part dans `lesson_reports.content`.
  Map<String, dynamic> versJson() => <String, dynamic>{
    'student_id': studentId,
    'confirme': confirme,
    if (motifException != null) 'motif_exception': motifException,
    if (pointPhonetique != null) 'point_phonetique': pointPhonetique,
    if (objectifPersonnel != null) 'objectif_personnel': objectifPersonnel,
    if (travailMaison != null) 'travail_maison': travailMaison,
    if (suite != SuiteEleve.continuer) 'suite': suite.name,
    if (nouveauSuspendu) 'nouveau_suspendu': true,
    if (performance case final NiveauPerformance p) 'performance': p.name,
    if (faiblesses.isNotEmpty)
      'faiblesses': <String>[
        for (final FaiblesseRecitation f in FaiblesseRecitation.values)
          if (faiblesses.contains(f)) f.name,
      ],
  };
}

/// L'echelle de performance du cahier, choix unique (N1, directeur 27/09).
enum NiveauPerformance {
  /// A revoir.
  aRevoir,

  /// En progres.
  enProgres,

  /// Acquis.
  acquis,

  /// Maitrise.
  maitrise;

  /// Lit un nom serialise ; nul s'il est absent ou inconnu.
  static NiveauPerformance? depuisNom(String? nom) {
    for (final NiveauPerformance n in values) {
      if (n.name == nom) return n;
    }
    return null;
  }
}

/// Les faiblesses du cahier, choix multiple (N1, directeur 27/09).
enum FaiblesseRecitation {
  /// Makharij.
  makharij,

  /// Madd.
  madd,

  /// Ghunna.
  ghunna,

  /// Waqf.
  waqf,

  /// Fluidite.
  fluidite,

  /// Memorisation.
  memorisation;

  /// Lit une liste de noms serialises ; les noms inconnus sont ignores.
  static Set<FaiblesseRecitation> depuisNoms(List<Object?>? noms) =>
      <FaiblesseRecitation>{
        for (final FaiblesseRecitation f in values)
          if (noms?.contains(f.name) ?? false) f,
      };
}

/// Les actions pedagogiques du cahier pour un eleve (doc 04 §20.4) :
/// « Continuer », « Renforcer », « Suspendre le nouveau ».
enum SuiteEleve {
  /// L'etat par defaut, fourni par le curriculum.
  continuer,

  /// L'eleve revoit ce qui est en cours avant d'avancer.
  renforcer,

  /// La revision continue, rien de nouveau n'est ajoute.
  suspendreNouveau,
}

/// Le cahier tel qu'il part au serveur.
///
/// La cle d'idempotence n'est **pas** portee ici : elle est generee par
/// `FileRapports.enregistrer` au moment de la redaction, et jamais regeneree au
/// rejeu. C'est elle qui permet a la contrainte d'unicite C9 de refuser un
/// doublon en base.
@immutable
class CahierARendre {
  /// Cree un cahier.
  const CahierARendre({
    required this.seanceId,
    required this.decisions,
    this.noteGroupe,
    this.positionReprise,
  });

  /// La seance concernee.
  final String seanceId;

  /// Une decision par eleve.
  final List<DecisionEleve> decisions;

  /// Une note qui vaut pour le groupe entier. Facultative : le protocole
  /// interdit tout rapport narratif obligatoire.
  final String? noteGroupe;

  /// Ou la Classe s'est arretee : la position de reprise d'un remplacant,
  /// obligatoire a la validation (K-45, point 2). Le contrat serveur la
  /// recevra a BR-1.
  final String? positionReprise;

  /// Le contenu serialise, tel qu'il sera ecrit dans `lesson_reports.content`.
  Map<String, dynamic> versJson() => <String, dynamic>{
    'version': 1,
    'session_id': seanceId,
    if (noteGroupe != null && noteGroupe!.trim().isNotEmpty)
      'note_groupe': noteGroupe!.trim(),
    if (positionReprise != null && positionReprise!.trim().isNotEmpty)
      'position_reprise': positionReprise!.trim(),
    'eleves': <Map<String, dynamic>>[
      for (final DecisionEleve d in decisions) d.versJson(),
    ],
  };
}
