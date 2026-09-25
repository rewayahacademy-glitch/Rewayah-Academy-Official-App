// Catalogue des classes ouvertes du mode demonstration (demande C-14).
//
// Donnees fictives, jamais envoyees au serveur : trois classes avec jours,
// heures, fuseau et parcours, pour que le catalogue se montre en entier.

import '../../core/capacites/port_catalogue_classes.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;

/// Catalogue fictif : une classe ouverte, une en liste d'attente, une
/// complete. Une inscription rend « demande recue », sans rien reserver.
class CatalogueClassesDemo implements PortCatalogueClasses {
  /// Cree le catalogue.
  const CatalogueClassesDemo();

  /// Les classes proposees en demonstration.
  static const List<ClasseOuverte> classes = <ClasseOuverte>[
    ClasseOuverte(
      classeId: 'demo-classe-coran-2',
      libelle: 'Coran, groupe du mardi',
      enseignant: EnseignantSeance(
        prenom: 'Maryam',
        titre: TitreEnseignant.sayyida,
      ),
      etat: EtatClasseOuverte.ouverte,
      placesRestantes: 2,
      seances: <CreneauHebdomadaire>[
        CreneauHebdomadaire(jourIso: 2, heure: 18, minute: 0, dureeMinutes: 45),
        CreneauHebdomadaire(jourIso: 4, heure: 18, minute: 0, dureeMinutes: 45),
      ],
      fuseauIana: 'Europe/Paris',
      cours: 'Coran',
      niveau: 'Niveau 1',
    ),
    ClasseOuverte(
      classeId: 'demo-classe-arabe-3',
      libelle: 'Arabe, groupe du samedi',
      enseignant: EnseignantSeance(
        prenom: 'Ibrahim',
        titre: TitreEnseignant.sayyid,
      ),
      etat: EtatClasseOuverte.listeAttente,
      seances: <CreneauHebdomadaire>[
        CreneauHebdomadaire(
          jourIso: 6,
          heure: 10,
          minute: 30,
          dureeMinutes: 60,
        ),
      ],
      fuseauIana: 'Europe/Paris',
      cours: 'Arabe',
      niveau: 'Niveau 2',
    ),
    ClasseOuverte(
      classeId: 'demo-classe-coran-4',
      libelle: 'Coran, groupe du dimanche',
      enseignant: EnseignantSeance(
        prenom: 'Maryam',
        titre: TitreEnseignant.sayyida,
      ),
      etat: EtatClasseOuverte.complete,
      placesRestantes: 0,
      seances: <CreneauHebdomadaire>[
        CreneauHebdomadaire(jourIso: 7, heure: 9, minute: 0, dureeMinutes: 45),
      ],
      fuseauIana: 'Europe/Paris',
      cours: 'Coran',
      niveau: 'Niveau 2',
    ),
  ];

  @override
  Future<List<ClasseOuverte>> compatibles({
    required String eleveId,
    required String fuseauIana,
  }) async => classes;

  @override
  Future<ResultatInscription> inscrire({
    required String classeId,
    required String eleveId,
    required String cleIdempotence,
  }) async => const ResultatInscription(StatutInscription.enAttenteValidation);
}
