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
/// - classes et supports (RECH-D1) : `PortGroupes` (les classes de la
///   personne, vue serveur) et `PortCatalogue` (la Bibliotheque, serveur) ;
/// - enseignants, remplacements, pedagogie, controle (RECH-D3) : les ports
///   des classes, des remplacements, du roster et de la mission de controle.
///
/// Chaque moteur ne repond que pour les espaces qui y ont droit ; un domaine
/// interdit est absent de `portees`. Une erreur d'un port est une PANNE
/// (`ReponseEchec`), jamais un vide confirme : `PortRechercheParMoteurs` la
/// rend telle quelle.
///
/// Familles et eleves (D2, identifiant exact) et finance et communications
/// (D4) ne sont pas branches ici.
///
/// Le branchement se fait dans `lib/main.dart` (`_surchargesAppReelle`), a cote
/// des autres adaptateurs serveur : ce fichier ne cite aucun port de
/// demonstration.
List<MoteurRechercheDomaine> moteursRechercheProduction(Ref ref) =>
    <MoteurRechercheDomaine>[
      ...moteursClassesSupports(ref),
      ...moteursEnseignantsPedagogieControle(ref),
    ];
