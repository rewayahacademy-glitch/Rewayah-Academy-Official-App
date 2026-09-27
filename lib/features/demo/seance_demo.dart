// Donnees fictives de la salle de seance (vague Classe, plan de code section 3).
//
// Aucun appel serveur (consigne K-28) : une seule source pour le compteur,
// le panneau Eleves et le recapitulatif de fin (I-6). Les contenus (noms,
// support) sont des contenus de demonstration, pas des libelles d'interface.

import '../../core/tc_bibliotheque/library_resource.dart';
import '../salle_seance/resultat_seance.dart';
import '../salle_seance/vue_seance.dart';

/// Les etats montrables de la salle de demonstration.
enum EtatDemoSalle {
  /// Seance en cours, sans visite.
  repos,

  /// Le tuteur de Mariam observe.
  visite,

  /// L'enseignante n'a rien partage.
  rienPartage,

  /// Panneau Eleves ouvert (enseignant).
  eleves,

  /// Panneau Supports ouvert (enseignant).
  supports,

  /// Seance terminee.
  fin,

  // --- Ecrans de secours (lot CL-7) ---

  /// Reseau faible, room connectee (P06).
  reseauFaible,

  /// Reconnexion en cours (P05).
  reconnexion,

  /// Connexion retablie (P05.6).
  retablie,

  /// Reconnexion impossible (P05.8).
  echec,

  /// Hors ligne confirme (P05.8).
  horsLigne,

  /// Micro bloque par le systeme (P09).
  microBloque,

  /// Camera interdite par le profil (P10).
  cameraInterdite,

  /// Heure de fin passee (P11).
  prolongee,

  /// Acces retire par le serveur (P12).
  accesRetire,
}

/// Les donnees exactes de la demonstration.
abstract final class DonneesSeanceDemo {
  static const String classe = 'Classe An-Nour';
  static const String enseignante = 'Sayyida Amina';
  static const String initialesEnseignante = 'SA';

  /// L'identifiant fictif de la Classe An-Nour (rail enseignant).
  static const String groupeDemo = 'demo-an-nour';
  static const String eleveCourant = 'Mariam';

  /// Les trois inscrits. « Eleves 1/3 » : seule Mariam est connectee.
  static const List<EleveSeance> eleves = <EleveSeance>[
    EleveSeance(
      prenom: 'Mariam',
      statut: StatutEleveSeance.connecte,
      fiche: FicheEleveSeance(
        // L'intitule « Niveau » est celui de la fiche : la valeur seule ici.
        niveau: '1',
        objectifActuel: 'Chapitre 1 (les bonnes manières)',
        derniereSeance: '24 sept. 2026',
        aReprendre: 'Pages 24 à 26',
        presenceRecente: '3 séances cette semaine',
        travailActuel: 'Écoute de la récitation',
      ),
    ),
    // Fiches fictives de Yusuf et Aicha : leurs lignes (repliees sur les
    // images) se deplient donc vraiment en demonstration.
    EleveSeance(
      prenom: 'Yusuf',
      statut: StatutEleveSeance.pasEncoreConnecte,
      fiche: FicheEleveSeance(
        niveau: '1',
        objectifActuel: 'Chapitre 1 (les bonnes manières)',
        derniereSeance: '24 sept. 2026',
        aReprendre: 'Pages 20 à 23',
        presenceRecente: '2 séances cette semaine',
        travailActuel: 'Lecture du chapitre',
      ),
    ),
    EleveSeance(
      prenom: 'Aïcha',
      statut: StatutEleveSeance.connexionInterrompue,
      fiche: FicheEleveSeance(
        niveau: '1',
        objectifActuel: 'Chapitre 1 (les bonnes manières)',
        derniereSeance: '24 sept. 2026',
        aReprendre: 'Pages 24 à 26',
        presenceRecente: '3 séances cette semaine',
        travailActuel: 'Écoute de la récitation',
      ),
    ),
  ];

  static const SupportSeance support = SupportSeance(
    chapitre: 'Chapitre 1',
    titre: 'Les bonnes manières en classe',
    encadre: 'Être attentif aux explications du professeur.',
    points: <String>[
      'Écouter avec calme.',
      'Poser des questions poliment.',
      'Respecter les camarades.',
    ],
    page: 1,
    pages: 12,
  );

  /// Le panneau Supports (CLV-08) : Reprendre, deux Recents, le fonds de la
  /// Classe. « Ouvrir » montre `contenu` dans la salle de demonstration.
  static const List<SupportDisponible> supports = <SupportDisponible>[
    SupportDisponible(
      id: 'demo-chapitre-1',
      surTitre: 'Chapitre 1',
      titre: 'Les bonnes manières',
      detail: 'Support de cours · v2.0',
      rubrique: RubriqueSupport.reprendre,
      type: TypeRessource.lecon,
      teinte: 9,
      monogramme: 'BM',
      contenu: support,
    ),
    SupportDisponible(
      id: 'demo-fiche-memorisation',
      titre: 'Fiche de mémorisation',
      detail: 'PDF · 12 pages · v1.1',
      rubrique: RubriqueSupport.recent,
      teinte: 25,
      monogramme: 'FM',
      contenu: SupportSeance(
        chapitre: 'Chapitre 1',
        titre: 'Fiche de mémorisation',
        encadre: 'Relire chaque règle à voix basse avant la séance.',
        points: <String>[
          'Écouter avant de parler.',
          'Lever la main pour demander la parole.',
          'Remercier le professeur.',
        ],
        page: 1,
        pages: 12,
      ),
    ),
    SupportDisponible(
      id: 'demo-exercices-chapitre-1',
      titre: 'Exercices – Chapitre 1',
      detail: 'PDF · 8 pages · v1.0',
      rubrique: RubriqueSupport.recent,
      teinte: 3,
      monogramme: 'EX',
      contenu: SupportSeance(
        chapitre: 'Chapitre 1',
        titre: 'Exercices – Chapitre 1',
        encadre: 'Associer chaque situation à la bonne manière.',
        points: <String>[
          'Un camarade parle : que fais-tu ?',
          'Tu as une question : que fais-tu ?',
          'Le professeur explique : que fais-tu ?',
        ],
        page: 1,
        pages: 8,
      ),
    ),
    SupportDisponible(
      id: 'demo-bibliotheque-an-nour',
      titre: 'Bibliothèque An-Nour',
      detail: '24 ressources',
      rubrique: RubriqueSupport.classe,
    ),
  ];

  static const FinSeance fin = FinSeance(
    heureFin: '15:16',
    cahierACompleter: true,
  );

  /// La vue d'un role dans un etat.
  ///
  /// Horloge : « 32 min restantes » par defaut ; l'etat visite de
  /// l'enseignant montre « La seance se poursuit. » comme l'image CLV-06.
  /// La vue eleve de la meme visite garde l'horloge en cours, comme CLV-04
  /// (l'eleve n'affiche la suite que depassee, sans duree restante).
  static VueSeance vue(RoleSeance role, EtatDemoSalle etat) {
    final bool enseignant = role == RoleSeance.enseignant;
    return VueSeance(
      role: role,
      nomClasse: classe,
      nomEnseignant: enseignante,
      initialesEnseignant: initialesEnseignante,
      prenomEleve: enseignant ? null : eleveCourant,
      horloge:
          (etat == EtatDemoSalle.visite && enseignant) ||
              etat == EtatDemoSalle.prolongee
          ? const HorlogeDepassee()
          : const HorlogeRestante(32),
      connexion: connexion(etat),
      cameraAutorisee: etat != EtatDemoSalle.cameraInterdite,
      microBloque: etat == EtatDemoSalle.microBloque,
      visite: etat == EtatDemoSalle.visite
          ? const VisiteSeance(prenomEnfant: eleveCourant, concerneMoi: true)
          : null,
      support: etat == EtatDemoSalle.rienPartage ? null : support,
      cameraEnseignantActive: true,
      groupeId: groupeDemo,
      eleves: eleves,
      supports: supports,
      // Acces retire, cote enseignant : la fin CLV-10 avec le cahier (P12.4).
      fin:
          etat == EtatDemoSalle.fin ||
              (etat == EtatDemoSalle.accesRetire && enseignant)
          ? fin
          : null,
      panneau: !enseignant
          ? PanneauOuvert.aucun
          : switch (etat) {
              EtatDemoSalle.eleves => PanneauOuvert.eleves,
              EtatDemoSalle.supports => PanneauOuvert.supports,
              _ => PanneauOuvert.aucun,
            },
      // Le point non lu de la cloche des images CLV-04 et CLV-06 desktop.
      notificationsNonLues: 2,
    );
  }

  /// La connexion montree par un etat de secours (lot CL-7).
  static ConnexionSeance connexion(EtatDemoSalle etat) => switch (etat) {
    EtatDemoSalle.reseauFaible => ConnexionSeance.reseauFaible,
    EtatDemoSalle.reconnexion => ConnexionSeance.reconnexion,
    EtatDemoSalle.retablie => ConnexionSeance.retablie,
    EtatDemoSalle.echec => ConnexionSeance.echec,
    EtatDemoSalle.horsLigne => ConnexionSeance.horsLigne,
    _ => ConnexionSeance.enLigne,
  };

  /// L'issue de l'eleve impose par l'etat, ou `null` (salle ouverte). La
  /// guidee n'a qu'un ecran de fin : son rendu ignore l'issue.
  static IssueSeance? issueEleve(EtatDemoSalle etat) => switch (etat) {
    EtatDemoSalle.fin => IssueSeance.terminee,
    EtatDemoSalle.accesRetire => IssueSeance.accesRetire,
    _ => null,
  };
}
