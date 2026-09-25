// Donnees fictives de la salle de seance (vague Classe, plan de code section 3).
//
// Aucun appel serveur (consigne K-28) : une seule source pour le compteur,
// le panneau Eleves et le recapitulatif de fin (I-6). Les contenus (noms,
// support) sont des contenus de demonstration, pas des libelles d'interface.

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
}

/// Les donnees exactes de la demonstration.
abstract final class DonneesSeanceDemo {
  static const String classe = 'Classe An-Nour';
  static const String enseignante = 'Sayyida Amina';
  static const String initialesEnseignante = 'SA';
  static const String eleveCourant = 'Mariam';

  /// Les trois inscrits. « Eleves 1/3 » : seule Mariam est connectee.
  static const List<EleveSeance> eleves = <EleveSeance>[
    EleveSeance(
      prenom: 'Mariam',
      statut: StatutEleveSeance.connecte,
      fiche: FicheEleveSeance(
        niveau: 'Niveau 1',
        objectifActuel: 'Chapitre 1 (les bonnes manières)',
        derniereSeance: '24 sept. 2026',
        aReprendre: 'Pages 24 à 26',
        presenceRecente: '3 séances cette semaine',
        travailActuel: 'Écoute de la récitation',
      ),
    ),
    EleveSeance(prenom: 'Yusuf', statut: StatutEleveSeance.pasEncoreConnecte),
    EleveSeance(
      prenom: 'Aïcha',
      statut: StatutEleveSeance.connexionInterrompue,
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

  static const List<SupportDisponible> supports = <SupportDisponible>[
    SupportDisponible(
      titre: 'Chapitre 1 · Les bonnes manières',
      detail: 'Support de cours · v2.0',
    ),
    SupportDisponible(
      titre: 'Fiche de mémorisation',
      detail: 'PDF · 12 pages · v1.1',
    ),
    SupportDisponible(
      titre: 'Exercices – Chapitre 1',
      detail: 'PDF · 8 pages · v1.0',
    ),
    SupportDisponible(titre: 'Bibliothèque An-Nour', detail: '24 ressources'),
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
      horloge: etat == EtatDemoSalle.visite && enseignant
          ? const HorlogeDepassee()
          : const HorlogeRestante(32),
      visite: etat == EtatDemoSalle.visite
          ? const VisiteSeance(prenomEnfant: eleveCourant, concerneMoi: true)
          : null,
      support: etat == EtatDemoSalle.rienPartage ? null : support,
      cameraEnseignantActive: true,
      eleves: eleves,
      supports: supports,
      fin: etat == EtatDemoSalle.fin ? fin : null,
      panneau: !enseignant
          ? PanneauOuvert.aucun
          : switch (etat) {
              EtatDemoSalle.eleves => PanneauOuvert.eleves,
              EtatDemoSalle.supports => PanneauOuvert.supports,
              _ => PanneauOuvert.aucun,
            },
    );
  }
}
