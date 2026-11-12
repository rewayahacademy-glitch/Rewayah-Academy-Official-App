// L'adaptateur `/salle` -> `VueSeance` (T7).
//
// Pur : il ne lit que ce que `SallePage` a DEJA lu (la `VueSalle` du jeton,
// la presence de `presenceSeanceProvider`, `monTuteurObserveProvider`,
// `annoncesObservationProvider`) et n'ouvre aucun appel serveur (K-28).
// Le support partage, les outils et Supports restent sans rappel tant que
// BR-1 ne les a pas cables : `support` est nul ici.

import '../../core/accessibilite/age_eleve.dart';
import '../../core/coran/service_coran.dart' show pagesMushafMedine;
import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/presence/service_presence.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/chrono_seance.dart' show BornesChrono;
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/tc_observation/port_annonce_observation.dart';
import '../../core/video/seuils_reseau.dart' show EtatReseau;
import '../../core/video/video_session_provider.dart'
    show ParticipantSalle, QualiteLien;
import '../salle/vue_salle.dart';
import 'presentation_observee.dart';
import 'vue_seance.dart';

/// Construit la `VueSeance` d'une salle `/salle`.
abstract final class DepuisSalle {
  /// `null` si le role du jeton n'a pas de salle de seance (tuteur
  /// observateur, controleur, administration, inconnu) : l'ancien rendu reste.
  static VueSeance? vue({
    required VueSalle salle,
    required InterfaceMode mode,
    List<PresenceParticipant>? presence,
    String? monProfil,
    bool monTuteurObserve = false,
    List<AnnonceObservation> annonces = const <AnnonceObservation>[],
    String nomClasse = '',
    String? groupeId,
    FinSeance? fin,
    AgeEleve age = AgeEleve.inconnu,
    bool releveTenu = false,
    SupportPageFixe? supportPresente,
    bool videoSuspendue = false,
    String? nomEnseignantConnu,
    String? paysEnseignant,
    String? idEnseignant,
    TitreEnseignant? titreEnseignant,
    BornesChrono? chrono,
    Map<String, EtatReseau> reseaux = const <String, EtatReseau>{},
    bool reseauDansIle = true,
  }) {
    final RoleSeance? role = RoleSeance.resoudre(salle.role, mode);
    if (role == null) return null;
    final bool enseignant = role == RoleSeance.enseignant;
    final List<PresenceParticipant> lignes =
        presence ?? const <PresenceParticipant>[];

    String? prenomDe(RoleSalle cible) {
      for (final PresenceParticipant p in lignes) {
        if (RoleSalle.depuis(p.role) == cible && p.prenom.isNotEmpty) {
          return p.prenom;
        }
      }
      return null;
    }

    // Directeur, 26/10/2026 : « Sayyid Prenom » ou « Sayyida Prenom »,
    // celui de l'annuaire de la seance ([nomEnseignantConnu], connu avant
    // meme son entree), sinon le prenom de la presence.
    final String nomEnseignant =
        nomEnseignantConnu ?? prenomDe(RoleSalle.enseignant) ?? '';

    String? prenomEleve;
    if (!enseignant) {
      for (final PresenceParticipant p in lignes) {
        if (p.profilId == monProfil && p.prenom.isNotEmpty) {
          prenomEleve = p.prenom;
        }
      }
      prenomEleve ??= salle.moi?.nom;
    }

    // La visite : a l'eleve seulement si c'est SON tuteur (serveur) ; a
    // l'enseignant toujours, des qu'une annonce existe. Jamais au controleur
    // (il n'a pas de salle de seance : `role` nul plus haut).
    VisiteSeance? visite;
    if (enseignant && annonces.isNotEmpty) {
      visite = VisiteSeance(
        prenomEnfant: annonces.first.prenomEnfant,
        concerneMoi: false,
      );
    } else if (!enseignant && monTuteurObserve) {
      visite = VisiteSeance(prenomEnfant: prenomEleve ?? '', concerneMoi: true);
    }

    // RESEAU-ELEVES (11/11/2026) : le reseau de chacun, filtre contre le
    // clignotement par la salle (`SuiviReseau`), par identite LiveKit (le
    // profil). Le micro publie de chaque participant choisit la phrase.
    final Map<String, ParticipantSalle> parIdentite =
        <String, ParticipantSalle>{
          for (final ParticipantSalle p in salle.participantsListes)
            if (p.identite.isNotEmpty) p.identite: p,
        };
    final ParticipantSalle? moi = salle.moi;
    final EtatReseau? monReseau = moi == null ? null : reseaux[moi.identite];
    EleveSeance avecReseau(EleveSeance e) {
      final String? id = e.profilId;
      if (id == null) return e;
      final EtatReseau? reseau = reseaux[id];
      if (reseau == null) return e;
      return EleveSeance(
        prenom: e.prenom,
        statut: e.statut,
        fiche: e.fiche,
        id: e.id,
        cleAvatar: e.cleAvatar,
        peutEcrire: e.peutEcrire,
        profilId: e.profilId,
        reseau: reseau,
        microOuvert: parIdentite[id]?.micro ?? false,
      );
    }

    return VueSeance(
      role: role,
      nomClasse: nomClasse,
      nomEnseignant: nomEnseignant,
      // DRAPEAUX : le pays seulement avec le nom de l'annuaire (le prenom de
      // la presence seul n'en porte pas).
      paysEnseignant: nomEnseignantConnu == null ? null : paysEnseignant,
      initialesEnseignant: initiales(nomEnseignant),
      // PHOTOS-A : les ids, pour lire les photos a la source unique.
      idEnseignant: idEnseignant,
      idEleve: enseignant ? null : monProfil,
      titreEnseignant: titreEnseignant,
      prenomEleve: prenomEleve,
      // FN-023 : T0 et la fin prevue servies par le serveur
      // (`bornesSalleProvider`), ou `null` : pas de chrono, rien d'invente.
      chrono: chrono,
      connexion: connexionDe(salle.phase, qualite: salle.qualite),
      // Defaut R-1 (11/11/2026) : les barres disent la qualite reelle.
      // RESEAU-ELEVES : filtree contre le clignotement quand la salle la
      // suit ; sinon la mesure brute.
      signalEnseignant: reseaux.isEmpty
          ? barresDuLien(salle.qualite)
          : monReseau?.barres,
      // Defaut C6-4 : la ou l'ile reste posee (eleve partout, enseignant sur
      // ordinateur), c'est elle qui dit le reseau, une seule fois ; ailleurs
      // (telephone de l'enseignant, ou l'ile ne vit que dans le profil
      // deplie), le bandeau le dit, une seule fois aussi.
      reseauDansIle: reseauDansIle,
      // On l'entend peut-etre mal : mauvais lien qui dure, micro ouvert.
      onVousEntendMal: (monReseau?.alerte ?? false) && (moi?.micro ?? false),
      // Une impasse n'est pas une salle : rien n'y est enregistre.
      enregistrementConfirme: salle.phase != PhaseSalle.refus,
      visite: visite,
      cameraEnseignantActive:
          (enseignant ? salle.moi?.camera : salle.dominant?.camera) ?? false,
      cameraAutorisee: salle.peutMontrer,
      // MICRO-AVANT-ENSEIGNANT : decide par le serveur, lu ici.
      microEnAttente: salle.microEnAttente,
      // L'eleve ne lit jamais la liste de ses camarades (roster enseignant).
      // Plan de composition du 26/10/2026 : presence illisible (lecture en
      // echec ou pas encore rendue), l'enseignant voit au moins les eleves
      // que la salle connait, connectes ; jamais une liste vide qui dirait
      // « personne ».
      eleves: <EleveSeance>[
        for (final EleveSeance e in _eleves(
          salle: salle,
          enseignant: enseignant,
          presence: presence,
          lignes: lignes,
        ))
          avecReseau(e),
      ],
      fin: fin,
      groupeId: groupeId,
      // MA-TUTOIEMENT-1 : le registre suit l'age, jamais la presentation ;
      // un age inconnu (avant BR-1) vouvoie.
      tutoiement: age.tutoiement,
      releveTenu: releveTenu,
      // S0 : la page du Coran presentee (canal de donnees, D9), dans la
      // surface a page fixe, au seul affichage « Avec notes ».
      supportPresente: supportPresente,
      videoSuspendue: videoSuspendue,
    );
  }

  /// La liste des inscrits de l'enseignant (vide pour l'eleve).
  static List<EleveSeance> _eleves({
    required VueSalle salle,
    required bool enseignant,
    required List<PresenceParticipant>? presence,
    required List<PresenceParticipant> lignes,
  }) => enseignant && presence == null
      ? <EleveSeance>[
          for (final ParticipantSalle p in salle.participantsListes)
            if (RoleSalle.depuis(p.role) == RoleSalle.eleve)
              EleveSeance(
                prenom: p.nom,
                statut: StatutEleveSeance.connecte,
                // L'identite LiveKit est l'identifiant de profil.
                profilId: p.identite.isEmpty ? null : p.identite,
              ),
        ]
      : enseignant
      ? <EleveSeance>[
          for (final PresenceParticipant p in lignes)
            if (RoleSalle.depuis(p.role) == RoleSalle.eleve)
              EleveSeance(
                prenom: p.prenom,
                statut: statut(p),
                // Le matricule : la fiche et ses actions (rappel,
                // recitation) visent l'eleve par lui.
                id: p.identifiantImmuable.isEmpty
                    ? null
                    : p.identifiantImmuable,
                profilId: p.profilId.isEmpty ? null : p.profilId,
              ),
        ]
      : const <EleveSeance>[];

  /// S0 : la page [numero] du mushaf de Medine comme support a page fixe,
  /// au ratio du papier A4 (directeur, 24/10/2026), jamais etiree.
  static SupportPageFixe pageCoran(int numero) => SupportPageFixe(
    id: 'mushaf-madina-15',
    version: '1',
    titre: t.salle.coran.titrePage,
    page: numero,
    total: pagesMushafMedine,
    largeurCanonique: 1000,
    hauteurCanonique: 1414,
  );

  /// TB-11a (plan V2 §5, UX-21) : la vue de la presentation que suit un
  /// observateur (tuteur, controleur), lue par la surface partagee
  /// (`ZoneSupport`, `SurfacePageFixe`), ou `null` : le role ne la suit pas
  /// ([VueSalle.suitLaPresentationEnLecture]), ou rien n'est presente.
  ///
  /// La vue porte le role de lecture de la classe (`RoleSeance.eleve` :
  /// qui suit l'enseignant sans rien diriger) et ferme tout ce que la surface
  /// pourrait ajouter : aucune consigne de tableau (`voitConsigneTableauLibre`
  /// est celle de l'enseignant), aucune vignette (camera de l'enseignant
  /// tenue pour eteinte : sa video est deja dans la scene de l'observateur),
  /// aucun panneau, aucune visite ni mention (la mention de visite n'est
  /// jamais montree au controleur, CTRL-SALLE-1). Aucune commande ne vit dans
  /// cette surface : la page, l'affichage et les notes se lisent, rien ne se
  /// touche.
  static VueSeance? presentationObservee({
    required VueSalle salle,
    required PresentationObservee? presentation,
  }) {
    if (!salle.suitLaPresentationEnLecture) return null;
    if (presentation == null || !presentation.aMontrer) return null;
    final String nomEnseignant = salle.dominant?.nom ?? '';
    return VueSeance(
      role: RoleSeance.eleve,
      nomClasse: '',
      nomEnseignant: nomEnseignant,
      initialesEnseignant: initiales(nomEnseignant),
      connexion: connexionDe(salle.phase),
      enregistrementConfirme: false,
      cameraEnseignantActive: false,
      supportPresente: presentation.supportPresente,
      affichage: presentation.affichage,
      tableauLibre: presentation.tableauLibre,
    );
  }

  /// La connexion vue par la salle de seance : seulement les phases DEJA
  /// connues du moteur (lot CL-7). Echec durable et hors ligne confirme
  /// viendront du moteur a BR-1.
  ///
  /// S0 : un lien que le SDK mesure mediocre se dit « Reseau faible » meme
  /// quand la phase reste en salle (« un etat ne se dit jamais par la couleur
  /// seule », J7).
  /// Les barres de signal (0 a 3) que donne la qualite du lien mesuree par
  /// le serveur de visio, ou `null` tant qu'elle n'est pas connue : on ne
  /// montre jamais un signal qu'on n'a pas mesure.
  static int? barresDuLien(QualiteLien qualite) => switch (qualite) {
    QualiteLien.excellente => 3,
    QualiteLien.bonne => 2,
    QualiteLien.mediocre => 1,
    QualiteLien.perdue => 0,
    QualiteLien.inconnue => null,
  };

  static ConnexionSeance connexionDe(
    PhaseSalle phase, {
    QualiteLien qualite = QualiteLien.inconnue,
  }) => switch (phase) {
    PhaseSalle.enSalle when qualite == QualiteLien.mediocre =>
      ConnexionSeance.reseauFaible,
    PhaseSalle.instable => ConnexionSeance.reseauFaible,
    PhaseSalle.reconnexion => ConnexionSeance.reconnexion,
    PhaseSalle.retabli => ConnexionSeance.retablie,
    PhaseSalle.materiel ||
    PhaseSalle.ouverture ||
    PhaseSalle.connexion ||
    PhaseSalle.enSalle ||
    PhaseSalle.refus => ConnexionSeance.enLigne,
  };

  /// Le statut d'un inscrit pendant la seance, depuis l'etat derive en base.
  /// Jamais « absent » : qui n'est pas venu est « pas encore connecte » (I-6).
  static StatutEleveSeance statut(PresenceParticipant p) => switch (p.etat) {
    EtatPresence.presente ||
    EtatPresence.enRetard ||
    EtatPresence.reconnectee => StatutEleveSeance.connecte,
    EtatPresence.deconnectee ||
    EtatPresence.enReconnexion ||
    EtatPresence.sortie => StatutEleveSeance.connexionInterrompue,
    _ =>
      p.entreLe == null
          ? StatutEleveSeance.pasEncoreConnecte
          : StatutEleveSeance.connexionInterrompue,
  };

  /// « SA » pour « Sayyida Amina ».
  static String initiales(String nom) {
    final List<String> mots = nom
        .trim()
        .split(RegExp(r'\s+'))
        .where((String m) => m.isNotEmpty)
        .toList();
    return mots.take(2).map((String m) => m[0].toUpperCase()).join();
  }

  /// « 15:16 », a l'heure du profil de la personne ([heureChezMoi]), sinon
  /// a celle de l'appareil. HEURE-PROFIL (12/11/2026) : [moment] est un
  /// INSTANT reel (jamais une valeur deja convertie), et ce texte se forme au
  /// dessin, a partir de l'instant garde : il suit le fuseau quand il arrive.
  static String heure(DateTime moment) => heureChezMoi(moment);

  /// [heure], suivie de « Heure de cet appareil » quand le fuseau du profil
  /// n'est pas lu (repli) : la personne sait de quelle heure on parle.
  static String heureDite(DateTime moment) => estHeureDeLAppareil(moment)
      ? LibellesGroupe.joindre(heure(moment), t.tuteur.accueil.heureAppareil)
      : heure(moment);

  /// Une phrase qui dit l'heure de [moment], suivie de « A l'heure de cet
  /// appareil. » en repli seulement.
  static String phraseDite(String phrase, DateTime moment) =>
      estHeureDeLAppareil(moment)
      ? '$phrase ${t.snt.planning.heureAppareil}'
      : phrase;
}
