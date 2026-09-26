// Donnees de demonstration de l'entree en classe (CL-4.2).
//
// Donnees fictives, jamais envoyees au serveur (K-28), sur le patron de
// catalogue_demo.dart et seance_demo.dart. Aucune photo reelle : l'enseignante
// est rendue par ses initiales. Les eleves ne portent qu'une projection
// pedagogique (R15), sans donnee famille.

import 'package:flutter/foundation.dart';

import '../../core/tc_groupe/group_home_vm.dart' show SlotAction;
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_horloge/emplacement_entree.dart';
import '../../core/tc_horloge/session_clock_vm.dart';

/// Un eleve vu par l'enseignant : projection pedagogique seulement.
@immutable
class EleveProjectionDemo {
  /// Cree la projection.
  const EleveProjectionDemo({
    required this.prenom,
    required this.niveau,
    required this.pageReprise,
    required this.dernierPoint,
    required this.presenceRecente,
  });

  /// Prenom (initiales a l'ecran, jamais de photo d'enfant).
  final String prenom;

  /// Niveau.
  final String niveau;

  /// Page de reprise.
  final String pageReprise;

  /// Dernier point utile, en texte neutre.
  final String dernierPoint;

  /// Presence recente, en texte neutre, sans jugement.
  final String presenceRecente;
}

/// Un support de la bibliotheque de la classe.
@immutable
class RessourceDemo {
  /// Cree la ressource.
  const RessourceDemo({
    required this.titre,
    required this.type,
    required this.taille,
  });

  /// Titre.
  final String titre;

  /// Type lisible (PDF, audio...).
  final String type;

  /// Taille lisible.
  final String taille;
}

/// Les situations de la demonstration de l'entree.
enum EtatDemoClasse {
  /// Avant l'ouverture de la fenetre.
  aVenir,

  /// Fenetre ouverte, avant T0.
  fenetreOuverte,

  /// Pre-vol en cours.
  preparation,

  /// Deja dans la salle avant T0.
  attente,

  /// En direct.
  enDirect,

  /// Apres la fin prevue, seance encore ouverte.
  tempsEcoule,

  /// Seance close.
  terminee,

  /// Seance annulee.
  annulee,

  /// Hors ligne.
  horsLigne,

  /// Information de seance illisible.
  indisponible,

  /// Avis de changement d'heure.
  changementHeure,
}

/// Le jeu de donnees de l'entree en classe.
abstract final class DonneesClasseDemo {
  /// Nom de la classe.
  static const String classe = 'Classe An-Nour';

  /// Cours et niveau.
  static const String cours = 'Lecture du Coran';

  /// Niveau.
  static const String niveau = 'Niveau 1';

  /// L'enseignante, sans photo : repli sur les initiales.
  static const EnseignantVM enseignante = EnseignantVM(
    enseignantId: 'demo-ens-amina',
    titre: TitreEnseignant.sayyida,
    nomAffichage: 'Amina',
  );

  /// Initiales de repli de l'avatar.
  static const String initialesEnseignante = 'A';

  /// Les eleves, projection pedagogique seulement.
  static const List<EleveProjectionDemo> eleves = <EleveProjectionDemo>[
    EleveProjectionDemo(
      prenom: 'Mariam',
      niveau: 'Niveau 1',
      pageReprise: 'Page 24',
      dernierPoint: 'Lecture fluide des lettres liées',
      presenceRecente: '3 séances sur les 3 dernières',
    ),
    EleveProjectionDemo(
      prenom: 'Yusuf',
      niveau: 'Niveau 1',
      pageReprise: 'Page 22',
      dernierPoint: 'Reprendre les voyelles longues',
      presenceRecente: '2 séances sur les 3 dernières',
    ),
    EleveProjectionDemo(
      prenom: 'Aïcha',
      niveau: 'Niveau 1',
      pageReprise: 'Page 24',
      dernierPoint: 'Arrêts en fin de verset',
      presenceRecente: '3 séances sur les 3 dernières',
    ),
  ];

  /// Le support prevu.
  static const String supportPrevu =
      'Les bonnes manières, chapitre 1, pages 24 à 26';

  /// « Avant le prochain cours » : trois actions au plus.
  static const List<SlotAction> actions = <SlotAction>[
    SlotAction(id: 'demo-relire', libelle: 'Relire les pages 22 et 23'),
    SlotAction(
      id: 'demo-ecouter',
      libelle: 'Écouter la récitation du chapitre 1',
      disponibleHorsLigne: true,
    ),
    SlotAction(id: 'demo-preparer', libelle: 'Préparer le livre et un crayon'),
  ];

  /// Les ressources de la classe.
  static const List<RessourceDemo> ressources = <RessourceDemo>[
    RessourceDemo(
      titre: 'Les bonnes manières, chapitre 1',
      type: 'PDF',
      taille: '2,4 Mo',
    ),
    RessourceDemo(
      titre: 'Récitation, chapitre 1',
      type: 'Audio',
      taille: '8,1 Mo',
    ),
    RessourceDemo(
      titre: 'Fiche des lettres liées',
      type: 'PDF',
      taille: '640 Ko',
    ),
  ];

  /// Debut de la seance (horodatage qui fait foi).
  static final DateTime debutUtc = DateTime.utc(2026, 9, 28, 16);

  /// Fin prevue (horodatage, jamais une duree en dur).
  static final DateTime finPrevueUtc = DateTime.utc(2026, 9, 28, 16, 45);

  /// Ouverture de la fenetre d'acces (donnee serveur simulee).
  static final DateTime ouvertureUtc = DateTime.utc(2026, 9, 28, 15, 40);

  /// Fermeture de la seance (donnee serveur simulee).
  static final DateTime fermetureUtc = DateTime.utc(2026, 9, 28, 17);

  /// La fenetre, derivee des seuls horodatages.
  static FenetreSeance get fenetre => FenetreSeance(
    debutUtc: debutUtc,
    finPrevueUtc: finPrevueUtc,
    fenetreAcces: debutUtc.difference(ouvertureUtc),
    graceApresFin: fermetureUtc.difference(finPrevueUtc),
  );

  /// L'heure de la personne qui regarde, deja rendue.
  static const HorlogeAffichee horlogeUtilisateur = HorlogeAffichee(
    fuseauIana: 'Europe/Paris',
    libelleVille: 'Paris',
    heureLocaleRendue: '18:00',
    dateLocaleRendue: 'Lundi 28 septembre',
  );

  /// La notice de changement d'heure de la situation dediee.
  static final NoticeDst noticeDst = NoticeDst(
    transitionUtc: DateTime.utc(2026, 10, 25, 1),
    fuseauConcerne: 'Europe/Paris',
    heureAvantRendue: '18:00',
    heureApresRendue: '17:00',
    echeance: EcheanceDst.j30,
  );

  /// L'instant simule de chaque situation.
  static DateTime instant(EtatDemoClasse etat) => switch (etat) {
    EtatDemoClasse.aVenir ||
    EtatDemoClasse.annulee ||
    EtatDemoClasse.horsLigne ||
    EtatDemoClasse.indisponible ||
    EtatDemoClasse.changementHeure => debutUtc.subtract(
      const Duration(hours: 3, minutes: 28),
    ),
    EtatDemoClasse.fenetreOuverte ||
    EtatDemoClasse.preparation ||
    EtatDemoClasse.attente => debutUtc.subtract(const Duration(minutes: 8)),
    EtatDemoClasse.enDirect => debutUtc.add(const Duration(minutes: 12)),
    EtatDemoClasse.tempsEcoule => finPrevueUtc.add(const Duration(minutes: 4)),
    EtatDemoClasse.terminee => fermetureUtc.add(const Duration(minutes: 1)),
  };

  /// L'horloge de seance d'une situation, derivee par [SessionClockVM].
  static SessionClockVM horloge(EtatDemoClasse etat) =>
      SessionClockVM.depuisFenetre(
        fenetre: fenetre,
        maintenantServeurUtc: instant(etat),
        horlogeUtilisateur: horlogeUtilisateur,
        sessionId: 'demo-seance-an-nour',
        connecte: etat == EtatDemoClasse.attente,
        noticeDst: etat == EtatDemoClasse.changementHeure ? noticeDst : null,
      );

  /// L'emplacement d'entree d'un role dans une situation.
  static EmplacementEntree emplacement(RoleEntree role, EtatDemoClasse etat) =>
      EmplacementEntree.pour(
        role: role,
        horloge: horloge(etat),
        nomClasse: classe,
        annulee: etat == EtatDemoClasse.annulee,
        horsLigne: etat == EtatDemoClasse.horsLigne,
        lectureEchouee: etat == EtatDemoClasse.indisponible,
        preparationEnCours: etat == EtatDemoClasse.preparation,
      );
}
