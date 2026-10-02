// Donnees de demonstration de l'entree en classe (CL-4.2).
//
// Donnees fictives, jamais envoyees au serveur (K-28), sur le patron de
// catalogue_demo.dart et seance_demo.dart. Aucune photo reelle : l'enseignant
// est rendu par ses initiales. Par defaut un homme au titre Sayyid (CL-4.7) ;
// la variante Sayyida se choisit par `&titre=sayyida`. Les eleves ne portent qu'une projection
// pedagogique (R15), sans donnee famille.

import 'package:flutter/foundation.dart';

import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_groupe/group_home_vm.dart' show SlotAction;
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_horloge/emplacement_entree.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../tc_espace_groupe/emplacements_groupe.dart' show ProgressionCompacte;

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
    required this.objectif,
  });

  /// Objectif en cours, en texte neutre (fiche ENS-11, EN-4).
  final String objectif;

  /// Prenom. La photo s'affiche chez l'enseignant (E5, K-44) ; aucune photo
  /// de demonstration n'est livree, les initiales tiennent donc lieu.
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

  /// L'enseignant par defaut, sans photo : repli sur les initiales.
  static const EnseignantVM enseignant = EnseignantVM(
    enseignantId: 'demo-ens-ibrahim',
    titre: TitreEnseignant.sayyid,
    nomAffichage: 'Ibrahim',
  );

  /// La variante Sayyida, choisie par `&titre=sayyida`.
  static const EnseignantVM enseignanteVariante = EnseignantVM(
    enseignantId: 'demo-ens-amina',
    titre: TitreEnseignant.sayyida,
    nomAffichage: 'Amina',
  );

  /// L'enseignant de la demonstration selon le titre choisi.
  static EnseignantVM enseignantPour(TitreEnseignant titre) =>
      titre == TitreEnseignant.sayyida ? enseignanteVariante : enseignant;

  /// Les eleves, projection pedagogique seulement.
  static const List<EleveProjectionDemo> eleves = <EleveProjectionDemo>[
    EleveProjectionDemo(
      prenom: 'Mariam',
      niveau: 'Niveau 1',
      pageReprise: 'Page 24',
      dernierPoint: 'Lecture fluide des lettres liées',
      presenceRecente: '3 séances sur les 3 dernières',
      objectif: 'Terminer la sourate Al-Mulk',
    ),
    EleveProjectionDemo(
      prenom: 'Yusuf',
      niveau: 'Niveau 1',
      pageReprise: 'Page 22',
      dernierPoint: 'Reprendre les voyelles longues',
      presenceRecente: '2 séances sur les 3 dernières',
      objectif: 'Maîtriser les voyelles longues',
    ),
    EleveProjectionDemo(
      prenom: 'Aïcha',
      niveau: 'Niveau 1',
      pageReprise: 'Page 24',
      dernierPoint: 'Arrêts en fin de verset',
      presenceRecente: '3 séances sur les 3 dernières',
      objectif: 'Respecter les arrêts',
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

  /// Identifiant de la classe de demonstration.
  static const String groupeId = 'demo-classe-an-nour';

  /// L'identite de la classe, avec l'horloge d'une situation.
  static GroupSummaryVM groupe(
    EtatDemoClasse etat, {
    TitreEnseignant titre = TitreEnseignant.sayyid,
  }) => GroupSummaryVM(
    groupeId: groupeId,
    libelle: classe,
    couleurJeton: const JetonCouleurGroupe(index: 2, codeStable: 'an-nour'),
    enseignant: enseignantPour(titre),
    nomCours: cours,
    niveauHumain: niveau,
    nombreMembres: eleves.length,
    seuilMax: 6,
    typePublic: TypePublicGroupeVM.enfant,
    actif: true,
    prochaineSeance: OccurrenceSeance(
      debutUtc: debutUtc,
      duree: finPrevueUtc.difference(debutUtc),
      fuseauReferenceGroupe: 'Europe/Paris',
      sessionId: 'demo-seance-an-nour',
    ),
    horloge: horloge(etat),
  );

  /// La progression compacte de l'eleve.
  static const ProgressionCompacte progression = ProgressionCompacte(
    chapitre: 'Chapitre 1',
    fraction: 0.6,
  );

  /// Les supports de la classe, en ressources de la Bibliotheque unique.
  static List<LibraryResource> get supports => <LibraryResource>[
    for (final (int i, RessourceDemo r) in ressources.indexed)
      LibraryResource.depuisJson(<String, dynamic>{
        'id': 'demo-support-$i',
        'title': r.titre,
        'short_title': '${r.titre}, ${r.type}, ${r.taille}',
      }),
  ];
}

/// Le travail « Avant le prochain cours » de la demonstration.
class TravailAVenirDemo implements PortTravailAVenir {
  /// Cree le port.
  const TravailAVenirDemo();

  @override
  Future<List<SlotAction>> avantProchainCours({
    required String groupeId,
    String? studentId,
  }) async => DonneesClasseDemo.actions;
}
