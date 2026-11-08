import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enseignant/service_enseignant.dart';
import '../../../../core/recherche/modeles_recherche.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../../../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../../../core/tc_groupe/port_groupes.dart';
import 'moteur_classes_enseignant.dart';
import 'moteur_classes_groupes.dart';
import 'moteur_supports_catalogue.dart';

/// Les moteurs du domaine « classes et supports » (RECH-D1), branches sur les
/// ports que l'application lit deja (`PortGroupes`, `PortCatalogue`).
///
/// [sourcesReelles] : faux (recette, demonstration), `PortGroupes` sert tous les
/// espaces, l'enseignant compris. Vrai (application reelle, RECHERCHE-LIVRAISON,
/// verdict du garde-cap sur la PR 347) : `PortGroupes` lit en production
/// `mes_groupes_famille_v`, qui ne filtre que l'eleve et le foyer et ne rend
/// AUCUNE ligne a un enseignant ; le moteur des classes est alors limite a la
/// famille et a l'eleve, et l'enseignant cherche dans la source de « Mes
/// classes » (`ServiceEnseignant.groupes`, relue a chaque recherche).
List<MoteurRechercheDomaine> moteursClassesSupports(
  Ref ref, {
  bool sourcesReelles = false,
}) {
  final PortGroupes groupes = ref.watch(portGroupesProvider);
  return <MoteurRechercheDomaine>[
    if (sourcesReelles) ...<MoteurRechercheDomaine>[
      MoteurClassesGroupes(
        groupes,
        espaces: const <EspaceRecherche>{
          EspaceRecherche.famille,
          EspaceRecherche.eleve,
          EspaceRecherche.eleveGuide,
        },
      ),
      MoteurClassesEnseignant(
        () => ref.read(serviceEnseignantProvider).groupes(),
      ),
    ] else
      MoteurClassesGroupes(groupes),
    MoteurSupportsCatalogue(ref.watch(portCatalogueProvider)),
  ];
}
