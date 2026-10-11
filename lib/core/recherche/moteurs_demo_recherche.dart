import 'corpus_demo_recherche.dart';
import 'modeles_recherche.dart';
import 'moteur_recherche_demo.dart';
import 'port_recherche.dart';

/// Les moteurs de demonstration du socle : classes, supports et eleves en
/// projection pedagogique, plusieurs milliers d'elements chacun, filtres par
/// espace (RECH-1).
///
/// **Hors production seulement** : en production, `moteursRechercheProvider`
/// reste vide. Chaque domaine a son propre jeu d'espaces : un espace qui n'en
/// fait pas partie ne voit ni resultat ni domaine, et ne sait pas qu'il
/// existe. Les adaptateurs de domaine (RECH-D1, RECH-D3) remplacent ces
/// moteurs par les leurs, sur les vraies formes de leur domaine.
List<MoteurRechercheDomaine> moteursDemoRecherche({int nombre = 3000}) =>
    <MoteurRechercheDomaine>[
      MoteurRechercheDemo(
        domaine: DomaineRecherche.classes,
        corpus: corpusClassesDemo(nombre: nombre),
        espaces: const <EspaceRecherche>{
          EspaceRecherche.famille,
          EspaceRecherche.eleve,
          EspaceRecherche.eleveGuide,
          EspaceRecherche.enseignant,
          EspaceRecherche.administration,
        },
      ),
      MoteurRechercheDemo(
        domaine: DomaineRecherche.supports,
        corpus: corpusSupportsDemo(nombre: nombre),
        espaces: const <EspaceRecherche>{
          EspaceRecherche.famille,
          EspaceRecherche.eleve,
          EspaceRecherche.eleveGuide,
          EspaceRecherche.enseignant,
        },
      ),
      MoteurRechercheDemo(
        domaine: DomaineRecherche.pedagogie,
        corpus: corpusElevesClasseDemo(nombre: nombre),
        espaces: const <EspaceRecherche>{EspaceRecherche.enseignant},
      ),
    ];
