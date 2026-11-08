import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/port_remplacements.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/recherche/modeles_recherche.dart';
import '../../core/recherche/port_recherche.dart';
import '../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../core/tc_classe/roster_enseignant.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../controleur/mission_controle.dart';
import 'domaines/classes_supports/moteur_classes_enseignant.dart';
import 'domaines/classes_supports/moteur_classes_groupes.dart';
import 'domaines/classes_supports/moteur_supports_catalogue.dart';
import 'domaines/enseignants_pedagogie_controle/moteur_controle_mission.dart';
import 'domaines/enseignants_pedagogie_controle/moteurs_enseignants.dart';

/// Les moteurs de la recherche en PRODUCTION (RECHERCHE-LIVRAISON, directeur,
/// 08/11/2026 : « la recherche ne marche pas, codee mais jamais livree »).
///
/// Avant ce fichier, `moteursRechercheProvider` etait vide hors demonstration :
/// aucun domaine n'etait servi, donc la loupe et Ctrl/Cmd + K restaient
/// masquees dans toutes les coques et `/recherche` disait « Recherche
/// indisponible pour le moment ».
///
/// Deux domaines, branches sur les ports REELS que l'application lit deja
/// (jamais ceux de la demonstration, jamais un corpus local) :
///
/// - classes et supports (RECH-D1) ;
/// - enseignants, remplacements, pedagogie, controle (RECH-D3).
///
/// **Chaque role lit une source qui le couvre** (verdict du garde-cap sur la
/// PR 347). `PortGroupes` lit en production `mes_groupes_famille_v`, qui ne
/// filtre que l'eleve et le foyer : elle ne rend AUCUNE ligne a un enseignant.
/// Branche sur elle, la recherche de l'enseignant aurait dit « aucun resultat »
/// pour une classe qu'il enseigne, un vide presente comme confirme alors qu'il
/// est faux. Donc :
///
/// - famille, eleve, eleve guide : `PortGroupes` (classes, enseignants de mes
///   classes) ; le moteur des classes leur est limite ;
/// - enseignant : `ServiceEnseignant.groupes` (`mes_groupes_v`, la source de
///   « Mes classes »), lue a chaque recherche, pour ses classes et ses eleves.
///
/// Chaque moteur ne repond que pour les espaces qui y ont droit ; un domaine
/// interdit est absent de `portees`. Une erreur d'un port est une PANNE
/// (`ReponseEchec`), jamais un vide confirme : `PortRechercheParMoteurs` la
/// rend telle quelle. Aucune copie n'est gardee entre deux recherches.
///
/// Familles et eleves (D2, identifiant exact) et finance et communications
/// (D4) ne sont pas branches ici.
///
/// Le branchement se fait dans `lib/main.dart` (`_surchargesAppReelle`), a cote
/// des autres adaptateurs serveur : ce fichier ne cite aucun port de
/// demonstration.
List<MoteurRechercheDomaine> moteursRechercheProduction(Ref ref) {
  final PortGroupes groupes = ref.watch(portGroupesProvider);
  final PortRemplacements? remplacements = ref.watch(portRemplacementsProvider);
  Future<List<GroupeEnseignant>> classesEnseignant() =>
      ref.read(serviceEnseignantProvider).groupes();
  return <MoteurRechercheDomaine>[
    // Classes : la famille et l'eleve par `PortGroupes`, l'enseignant par la
    // source de « Mes classes ».
    MoteurClassesGroupes(
      groupes,
      espaces: const <EspaceRecherche>{
        EspaceRecherche.famille,
        EspaceRecherche.eleve,
        EspaceRecherche.eleveGuide,
      },
    ),
    MoteurClassesEnseignant(classesEnseignant),
    MoteurSupportsCatalogue(ref.watch(portCatalogueProvider)),
    MoteurEnseignantsDesClasses(groupes),
    if (remplacements != null) MoteurRemplacements(remplacements),
    MoteurPedagogieEleves.surClassesEnseignant(
      classes: () async => <ClasseCherchee>[
        for (final GroupeEnseignant g in await classesEnseignant())
          (id: g.id, libelle: g.libelle),
      ],
      roster: ref.watch(portRosterEnseignantProvider),
    ),
    MoteurControleMission(
      lire: () => ref.read(portMissionControleProvider).maMission(),
    ),
  ];
}
