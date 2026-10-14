// Donnees de demonstration du role controleur (CT-1b, vague Controleur).
//
// Donnees fictives, jamais envoyees au serveur (K-28), sur le patron de
// enseignant_demo.dart. Conformes a `14_controleur/V/00_MAQUETTES_CONTROLEUR.md`
// et aux decisions du directeur du 27/09/2026 (C1 a C21) :
// - la mission n'existe que pour une seance en direct : aucune date de
//   visite a choisir, aucun planning (C1, C3) ;
// - le rapport part automatiquement : aucun etat « a partager » (C2) ;
// - la Classe observee est celle des autres demonstrations (Classe An-Nour,
//   Sayyid Ibrahim, Mariam, Yusuf, Aicha), pour la coherence (C19, E20) ;
// - les eleves n'ont que leur prenom (C8), les fils Admin n'en citent aucun ;
// - les dates sont en septembre 2026.
//
// Rien ici n'est une autorisation : la capacite Controleur, l'attribution
// des missions et la transmission du rapport sont decidees par le serveur
// (BR-1, `14_controleur/CT-BR.md`).

import 'package:flutter/foundation.dart';

import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import 'classe_demo.dart' show DonneesClasseDemo, EleveProjectionDemo;

/// Les ecrans de la demonstration : les quatre destinations, dans l'ordre
/// de la barre (C13). L'index est celui de la destination active.
enum EcranDemoControleur {
  /// Controle (CTR-01).
  controle,

  /// Historique (CTR-05).
  historique,

  /// Echanges (CTR-04).
  echanges,

  /// Compte, partage par tous les roles.
  compte,
}

/// Les situations de la mission (doc 08 §7, CTR-01, et P-CTR-08).
enum EtatDemoControleur {
  /// Aucune mission attribuee.
  aucune,

  /// Une mission, sur une seance qui n'est pas encore en direct : ligne
  /// calme, jamais de bouton grise (C1, R4).
  pasEncoreEnDirect,

  /// La seance est en direct : « Commencer le controle » (C1, C14).
  enDirect,

  /// La seance est en direct, mais un autre controleur l'observe deja
  /// (CTRL-SALLE-1) : un seul controle a la fois par Classe.
  dejaControlee,

  /// La mission a ete retiree ou la seance annulee (P-CTR-08).
  indisponible,
}

/// Les trois profils de la demonstration (doc 08 §11).
enum ProfilDemoControleur {
  /// Controleur externe permanent : seul espace, Controle.
  externe,

  /// Enseignant-Controleur : sa propre Classe est exclue des missions.
  enseignant,

  /// Admin-Controleur : ses droits Admin ne s'ajoutent pas en Controle.
  admin,
}

/// Un profil de controleur de demonstration.
@immutable
class ControleurDemo {
  /// Cree le profil.
  const ControleurDemo({
    required this.id,
    required this.prenom,
    required this.profil,
    this.classeExclue,
  });

  /// Identifiant fictif.
  final String id;

  /// Prenom seul.
  final String prenom;

  /// Le cumul de roles.
  final ProfilDemoControleur profil;

  /// La propre Classe de l'Enseignant-Controleur, jamais proposee en
  /// mission (decision serveur, montree ici seulement).
  final String? classeExclue;
}

/// L'etat d'une mission.
enum EtatMissionDemo {
  /// Seance prevue, pas encore en direct.
  prevue,

  /// Seance en direct : le controle peut commencer.
  enDirect,

  /// Seance en direct, deja controlee par un autre controleur.
  dejaControlee,

  /// Mission retiree ou seance annulee.
  indisponible,
}

/// Une mission de controle de demonstration : une seance, une Classe.
@immutable
class MissionControleurDemo {
  /// Cree la mission.
  const MissionControleurDemo({
    required this.id,
    required this.seanceId,
    required this.classe,
    required this.cours,
    required this.niveau,
    required this.titreEnseignant,
    required this.enseignant,
    required this.nombreEleves,
    required this.debut,
    required this.finPrevue,
    required this.etat,
  });

  /// Identifiant fictif de la mission.
  final String id;

  /// Identifiant fictif de la seance.
  final String seanceId;

  /// Nom de la Classe.
  final String classe;

  /// Cours.
  final String cours;

  /// Niveau.
  final String niveau;

  /// Titre de l'enseignant (Sayyid, Sayyida).
  final TitreEnseignant titreEnseignant;

  /// Nom d'affichage de l'enseignant.
  final String enseignant;

  /// Nombre d'eleves attendus.
  final int nombreEleves;

  /// Debut prevu.
  final DateTime debut;

  /// Fin prevue.
  final DateTime finPrevue;

  /// Etat de la mission.
  final EtatMissionDemo etat;
}

/// Les faits automatiques d'une seance (doc 08 §1.1, C4) : releves par le
/// systeme, jamais saisis par le controleur.
@immutable
class FaitsAutomatiquesDemo {
  /// Cree les faits.
  const FaitsAutomatiquesDemo({
    required this.debutPrevu,
    required this.debutReel,
    required this.dureePrevue,
    required this.participantsAttendus,
    required this.participantsPresents,
    required this.reconnexions,
    this.finReelle,
  });

  /// Debut prevu.
  final DateTime debutPrevu;

  /// Debut reel.
  final DateTime debutReel;

  /// Duree prevue.
  final Duration dureePrevue;

  /// Fin reelle, nulle tant que la seance continue.
  final DateTime? finReelle;

  /// Participants attendus.
  final int participantsAttendus;

  /// Participants presents.
  final int participantsPresents;

  /// Nombre de reconnexions relevees.
  final int reconnexions;

  /// Le retard au demarrage, en minutes entieres (zero si a l'heure).
  int get minutesDeRetard {
    final int m = debutReel.difference(debutPrevu).inMinutes;
    return m > 0 ? m : 0;
  }
}

/// Le statut d'un rapport (doc 08 CTR-05).
enum StatutRapportDemo {
  /// Envoye.
  envoye,

  /// Complement ajoute.
  complementAjoute,

  /// A terminer.
  aTerminer,
}

/// Un rapport de controle de demonstration, pour l'Historique (CTR-05).
@immutable
class RapportControleurDemo {
  /// Cree le rapport.
  const RapportControleurDemo({
    required this.id,
    required this.missionId,
    required this.date,
    required this.classe,
    required this.titreEnseignant,
    required this.enseignant,
    required this.dureeObservee,
    required this.statut,
  });

  /// Identifiant fictif.
  final String id;

  /// La mission d'origine.
  final String missionId;

  /// Date et heure du controle.
  final DateTime date;

  /// Classe observee.
  final String classe;

  /// Titre de l'enseignant.
  final TitreEnseignant titreEnseignant;

  /// Nom d'affichage de l'enseignant.
  final String enseignant;

  /// Duree observee.
  final Duration dureeObservee;

  /// Statut.
  final StatutRapportDemo statut;
}

/// L'etat d'un fil avec l'administration (doc 08 CTR-04).
enum EtatFilDemo {
  /// Reponse recue.
  reponseRecue,

  /// En attente.
  enAttente,
}

/// L'auteur d'un message.
enum AuteurMessageDemo {
  /// Le controleur.
  controleur,

  /// L'administration.
  administration,
}

/// Un message d'un fil.
@immutable
class MessageFilDemo {
  /// Cree le message.
  const MessageFilDemo({
    required this.auteur,
    required this.texte,
    required this.date,
  });

  /// L'auteur.
  final AuteurMessageDemo auteur;

  /// Le texte, sans prenom d'eleve (C8).
  final String texte;

  /// Date d'envoi.
  final DateTime date;
}

/// Un fil avec l'administration (CTR-04), par mission ou par sujet (C17).
@immutable
class FilAdminDemo {
  /// Cree le fil.
  const FilAdminDemo({
    required this.id,
    required this.missionId,
    required this.classe,
    required this.debutMission,
    required this.etat,
    required this.messages,
  });

  /// Identifiant fictif.
  final String id;

  /// La mission du fil : un fil par mission seulement en V1 (CT-6). Le
  /// titre humain en est deduit (« {Classe} · {date} »), jamais un nom.
  final String missionId;

  /// La Classe de la mission.
  final String classe;

  /// Debut de la seance observee, epingle en haut du fil.
  final DateTime debutMission;

  /// Etat du fil.
  final EtatFilDemo etat;

  /// Les messages, du plus ancien au plus recent.
  final List<MessageFilDemo> messages;

  /// Derniere activite.
  DateTime get derniereActivite => messages.last.date;
}

/// Le jeu de donnees du controle.
abstract final class DonneesControleurDemo {
  /// L'instant de la demonstration : lundi 28 septembre 2026, 18 h 12,
  /// pendant la seance d'An-Nour (18 h a 18 h 45).
  static final DateTime maintenant = DateTime(2026, 9, 28, 18, 12);

  /// Le controleur de la session de demonstration.
  static const String controleurId = 'demo-controleur-hamza';

  /// Les trois profils (doc 08 §11).
  static const List<ControleurDemo> profils = <ControleurDemo>[
    ControleurDemo(
      id: controleurId,
      prenom: 'Hamza',
      profil: ProfilDemoControleur.externe,
    ),
    // Sayyid Ibrahim est aussi Controleur : sa propre Classe, An-Nour, ne
    // lui est jamais attribuee.
    ControleurDemo(
      id: 'demo-enseignant-ibrahim',
      prenom: 'Ibrahim',
      profil: ProfilDemoControleur.enseignant,
      classeExclue: 'demo-classe-an-nour',
    ),
    ControleurDemo(
      id: 'demo-admin-khadija',
      prenom: 'Khadija',
      profil: ProfilDemoControleur.admin,
    ),
  ];

  /// Les prenoms du roster minimal autorise (C8) : celui d'An-Nour.
  static List<String> get roster => <String>[
    for (final EleveProjectionDemo e in DonneesClasseDemo.eleves) e.prenom,
  ];

  /// L'initiale du nom de chaque eleve du roster (decision C7 = a) : la
  /// demonstration ne porte jamais de nom de famille entier.
  static const Map<String, String> initialesNom = <String, String>{
    'Mariam': 'S',
    'Yusuf': 'B',
    'Aïcha': 'N',
  };

  /// La mission de la situation, ou nulle (aucune mission).
  static MissionControleurDemo? mission(
    EtatDemoControleur etat,
  ) => switch (etat) {
    EtatDemoControleur.aucune => null,
    EtatDemoControleur.pasEncoreEnDirect => _mission(EtatMissionDemo.prevue),
    EtatDemoControleur.enDirect => _mission(EtatMissionDemo.enDirect),
    EtatDemoControleur.dejaControlee => _mission(EtatMissionDemo.dejaControlee),
    EtatDemoControleur.indisponible => _mission(EtatMissionDemo.indisponible),
  };

  static MissionControleurDemo _mission(EtatMissionDemo etat) =>
      MissionControleurDemo(
        id: 'demo-mission-an-nour-0928',
        seanceId: 'demo-seance-an-nour-0928',
        classe: DonneesClasseDemo.classe,
        cours: DonneesClasseDemo.cours,
        niveau: DonneesClasseDemo.niveau,
        titreEnseignant: DonneesClasseDemo.enseignant.titre,
        enseignant: DonneesClasseDemo.enseignant.nomAffichage,
        nombreEleves: DonneesClasseDemo.eleves.length,
        // Pas encore en direct : la meme seance, a 18 h, vue a 17 h 40.
        debut: DateTime(2026, 9, 28, 18),
        finPrevue: DateTime(2026, 9, 28, 18, 45),
        etat: etat,
      );

  /// Les faits automatiques de la seance en direct (la seance continue :
  /// aucune fin reelle).
  static final FaitsAutomatiquesDemo faitsEnDirect = FaitsAutomatiquesDemo(
    debutPrevu: DateTime(2026, 9, 28, 18),
    debutReel: DateTime(2026, 9, 28, 18, 3),
    dureePrevue: const Duration(minutes: 45),
    participantsAttendus: DonneesClasseDemo.eleves.length,
    participantsPresents: DonneesClasseDemo.eleves.length - 1,
    reconnexions: 1,
  );

  /// Les faits d'une seance finie (le controle du 24/09, Al-Badr).
  static final FaitsAutomatiquesDemo faitsSeanceFinie = FaitsAutomatiquesDemo(
    debutPrevu: DateTime(2026, 9, 24, 17),
    debutReel: DateTime(2026, 9, 24, 17, 8),
    dureePrevue: const Duration(minutes: 45),
    finReelle: DateTime(2026, 9, 24, 17, 49),
    participantsAttendus: 4,
    participantsPresents: 4,
    reconnexions: 0,
  );

  /// L'Historique : un rapport par statut, du plus recent au plus ancien.
  static final List<RapportControleurDemo> rapports = <RapportControleurDemo>[
    RapportControleurDemo(
      id: 'demo-rapport-0926',
      missionId: 'demo-mission-al-ikhlas-0926',
      date: DateTime(2026, 9, 26, 10, 5),
      classe: 'Classe Al-Ikhlas',
      titreEnseignant: TitreEnseignant.sayyid,
      enseignant: 'Ibrahim',
      dureeObservee: const Duration(minutes: 12),
      statut: StatutRapportDemo.aTerminer,
    ),
    RapportControleurDemo(
      id: 'demo-rapport-0924',
      missionId: 'demo-mission-al-badr-0924',
      date: DateTime(2026, 9, 24, 17, 20),
      classe: 'Classe Al-Badr',
      titreEnseignant: TitreEnseignant.sayyid,
      enseignant: 'Ibrahim',
      dureeObservee: const Duration(minutes: 18),
      statut: StatutRapportDemo.complementAjoute,
    ),
    RapportControleurDemo(
      id: 'demo-rapport-0921',
      missionId: 'demo-mission-an-nour-0921',
      date: DateTime(2026, 9, 21, 18, 10),
      classe: DonneesClasseDemo.classe,
      titreEnseignant: TitreEnseignant.sayyid,
      enseignant: 'Ibrahim',
      dureeObservee: const Duration(minutes: 15),
      statut: StatutRapportDemo.envoye,
    ),
  ];

  /// Les fils avec l'administration : un par mission seulement en V1 (C17,
  /// CT-6), aucun prenom d'eleve (C8).
  static final List<FilAdminDemo> fils = <FilAdminDemo>[
    FilAdminDemo(
      id: 'demo-fil-al-badr-0924',
      missionId: 'demo-mission-al-badr-0924',
      classe: 'Classe Al-Badr',
      debutMission: DateTime(2026, 9, 24, 17),
      etat: EtatFilDemo.reponseRecue,
      messages: <MessageFilDemo>[
        MessageFilDemo(
          auteur: AuteurMessageDemo.controleur,
          texte:
              'La séance a commencé avec huit minutes de retard. '
              "J'ai ajouté un complément au compte rendu.",
          date: DateTime(2026, 9, 24, 18, 2),
        ),
        MessageFilDemo(
          auteur: AuteurMessageDemo.administration,
          texte:
              "Merci, c'est noté. Nous en parlons avec l'enseignant cette "
              'semaine.',
          date: DateTime(2026, 9, 25, 9, 30),
        ),
      ],
    ),
    FilAdminDemo(
      id: 'demo-fil-al-ikhlas-0926',
      missionId: 'demo-mission-al-ikhlas-0926',
      classe: 'Classe Al-Ikhlas',
      debutMission: DateTime(2026, 9, 26, 10),
      etat: EtatFilDemo.enAttente,
      messages: <MessageFilDemo>[
        MessageFilDemo(
          auteur: AuteurMessageDemo.controleur,
          texte:
              "Le son a coupé deux fois pendant l'observation. "
              'Est-ce relevé de votre côté ?',
          date: DateTime(2026, 9, 26, 10, 30),
        ),
      ],
    ),
  ];

  /// Le nombre de controles realises cette semaine (C11 : une ligne, sans
  /// score), sur les rapports de la semaine du 21 septembre.
  static int get controlesCetteSemaine => rapports
      .where(
        (RapportControleurDemo r) => !r.date.isBefore(DateTime(2026, 9, 21)),
      )
      .length;
}
