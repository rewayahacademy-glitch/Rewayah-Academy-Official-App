// L'adaptateur `/tc/classe` -> `VueSeance` (T8 du lot Classe et visio).
//
// Pur, comme `depuis_salle.dart` : il ne lit que ce que `ClasseLivePage` a
// DEJA lu (la `VueSalle` du jeton, le `RosterClasseVM`, l'horloge de la
// seance, les annonces d'observation) et n'ouvre aucun appel serveur (K-28).
// Le roster reste la source unique du compteur, du panneau et du
// recapitulatif (I-6) : la liste d'eleves en est une projection, rien de plus.

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_classe/roster_classe_vm.dart';
import '../../core/tc_classe/teacher_student_projection.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../salle/vue_salle.dart';
import 'depuis_salle.dart';
import 'vue_seance.dart';

/// Construit la `VueSeance` d'une Classe Live `/tc/classe`.
abstract final class DepuisClasseLive {
  /// `null` si le role du jeton n'a pas de salle de seance (tuteur
  /// observateur, controleur, administration, inconnu) : l'ancien rendu reste.
  static VueSeance? vue({
    required VueSalle salle,
    required InterfaceMode mode,
    required RosterClasseVM roster,
    required String libelleGroupe,
    required String nomEnseignant,
    required String groupeId,
    SessionClockVM? horloge,
    bool monTuteurObserve = false,
    List<AnnonceObservation> annonces = const <AnnonceObservation>[],
    SupportSeance? support,
    PanneauOuvert panneau = PanneauOuvert.aucun,
  }) {
    final RoleSeance? role = RoleSeance.resoudre(salle.role, mode);
    if (role == null) return null;
    final bool enseignant = role == RoleSeance.enseignant;

    // L'eleve devant l'ecran : son nom vient du moteur (identite du jeton),
    // jamais du roster, que l'eleve ne lit pas.
    final String? prenomEleve = enseignant ? null : salle.moi?.nom;

    // La visite : meme regle que `/salle`. A l'enseignant des qu'une annonce
    // existe ; a l'eleve seulement si c'est SON tuteur (lecture serveur
    // `annonce_observation_pour_moi`). Jamais au controleur (role nul).
    VisiteSeance? visite;
    if (enseignant && annonces.isNotEmpty) {
      visite = VisiteSeance(
        prenomEnfant: annonces.first.prenomEnfant,
        concerneMoi: false,
      );
    } else if (!enseignant && monTuteurObserve) {
      visite = VisiteSeance(prenomEnfant: prenomEleve ?? '', concerneMoi: true);
    }

    return VueSeance(
      role: role,
      nomClasse: libelleGroupe,
      nomEnseignant: nomEnseignant,
      initialesEnseignant: DepuisSalle.initiales(nomEnseignant),
      prenomEleve: prenomEleve,
      horloge: enseignant ? horlogeDe(horloge) : null,
      connexion:
          salle.phase == PhaseSalle.reconnexion ||
              salle.phase == PhaseSalle.instable
          ? ConnexionSeance.reconnexion
          : ConnexionSeance.enLigne,
      enregistrementConfirme: salle.phase != PhaseSalle.refus,
      visite: visite,
      support: support,
      cameraEnseignantActive:
          (enseignant ? salle.moi?.camera : salle.dominant?.camera) ?? false,
      cameraAutorisee: salle.peutMontrer,
      // L'eleve ne lit jamais la liste de ses camarades (roster enseignant).
      eleves: enseignant && roster.disponible
          ? ordonner(<EleveSeance>[
              for (final TeacherStudentProjection e in roster.eleves)
                EleveSeance(
                  id: e.academyId,
                  prenom: e.firstName,
                  statut: statut(e.liveStatus),
                  fiche: fiche(e),
                ),
            ])
          : const <EleveSeance>[],
      elevesConnus: roster.disponible,
      panneau: enseignant ? panneau : PanneauOuvert.aucun,
      groupeId: groupeId,
    );
  }

  /// « 32 min restantes » pendant le cours, « La seance se poursuit. » apres
  /// la fin prevue, rien sinon (horloge non branchee, avant T0, terminee).
  static HorlogeSeance? horlogeDe(SessionClockVM? horloge) {
    if (horloge == null) return null;
    return switch (horloge.phase) {
      PhaseSeance.enCours => switch (horloge.restant) {
        final Duration r => HorlogeRestante((r.inSeconds / 60).ceil()),
        null => null,
      },
      PhaseSeance.prolongee => const HorlogeDepassee(),
      PhaseSeance.avantFenetre ||
      PhaseSeance.salleOuverte ||
      PhaseSeance.attenteAvantT0 ||
      PhaseSeance.terminee => null,
    };
  }

  /// L'ordre du panneau Eleves (image CLV-07) : connectes, pas encore
  /// connectes, connexion interrompue ; l'ordre du roster dans chaque statut.
  static List<EleveSeance> ordonner(List<EleveSeance> eleves) {
    final List<EleveSeance> tries = List<EleveSeance>.of(eleves);
    final Map<EleveSeance, int> rang = <EleveSeance, int>{
      for (int i = 0; i < eleves.length; i++) eleves[i]: i,
    };
    tries.sort(
      (EleveSeance a, EleveSeance b) => a.statut.index != b.statut.index
          ? a.statut.index.compareTo(b.statut.index)
          : rang[a]!.compareTo(rang[b]!),
    );
    return tries;
  }

  /// Les six champs de la fiche (CLV-07), depuis la projection pedagogique,
  /// avec les memes libelles que `FicheSeance`. Un fait inconnu se dit par
  /// un tiret, jamais par un zero. Aucune coordonnee familiale : la
  /// projection n'en porte pas (PII).
  static FicheEleveSeance fiche(TeacherStudentProjection e) {
    const String inconnu = '-';
    final int? page = e.lastLesson?.positionAtteinte?.page;
    return FicheEleveSeance(
      niveau: e.level ?? inconnu,
      objectifActuel: e.activeGoals.isNotEmpty
          ? e.activeGoals.first
          : e.currentUnit ?? inconnu,
      derniereSeance: page == null
          ? inconnu
          : t.tc.classe.fiche.page(page: page),
      aReprendre: e.lastLesson?.pointARevoir ?? inconnu,
      presenceRecente: switch (e.recentAttendance) {
        final AssiduiteRecente a => t.tc.classe.fiche.assiduite(
          presences: a.presences,
          total: a.total,
        ),
        null => inconnu,
      },
      travailActuel: e.currentAssignments.isEmpty
          ? inconnu
          : t.tc.classe.fiche.travailEnCours(
              nombre: e.currentAssignments.length,
            ),
    );
  }

  /// Le statut d'un inscrit, depuis l'etat projete. Jamais « absent » :
  /// qui n'est pas venu est « pas encore connecte » (I-6), et un etat
  /// inconnu ne se change pas en absence (J3).
  static StatutEleveSeance statut(EtatPresenceProjete etat) => switch (etat) {
    EtatPresenceProjete.present ||
    EtatPresenceProjete.enRetard => StatutEleveSeance.connecte,
    EtatPresenceProjete.deconnecte ||
    EtatPresenceProjete.enReconnexion ||
    EtatPresenceProjete.sorti => StatutEleveSeance.connexionInterrompue,
    EtatPresenceProjete.inconnu ||
    EtatPresenceProjete.attendu ||
    EtatPresenceProjete.enConnexion ||
    EtatPresenceProjete.absent => StatutEleveSeance.pasEncoreConnecte,
  };
}
