import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/recherche/port_recherche.dart';
import 'domaines/classes_supports/moteurs_classes_supports.dart';
import 'domaines/enseignants_pedagogie_controle/moteurs_enseignants_pedagogie_controle.dart';

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
/// est faux. Donc, par `sourcesReelles: true` :
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
List<MoteurRechercheDomaine> moteursRechercheProduction(Ref ref) =>
    <MoteurRechercheDomaine>[
      ...moteursClassesSupports(ref, sourcesReelles: true),
      ...moteursEnseignantsPedagogieControle(ref, sourcesReelles: true),
    ];
