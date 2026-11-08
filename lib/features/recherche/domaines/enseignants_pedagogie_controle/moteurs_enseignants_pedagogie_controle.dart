import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enseignant/modeles_enseignant.dart';
import '../../../../core/enseignant/port_remplacements.dart';
import '../../../../core/enseignant/service_enseignant.dart';
import '../../../../core/recherche/port_recherche.dart';
import '../../../../core/tc_classe/roster_enseignant.dart';
import '../../../../core/tc_groupe/port_groupes.dart';
import '../../../controleur/mission_controle.dart';
import 'moteur_controle_mission.dart';
import 'moteurs_enseignants.dart';

/// Les moteurs du domaine « enseignants, remplacements, pedagogie, controle »
/// (RECH-D3), branches sur les ports que l'application lit deja.
///
/// **A ne poser que dans une demonstration ou une fois le serveur la** :
/// `moteursRechercheProvider` reste vide en production. Le moteur des
/// remplacements n'existe que si son port est branche (`portRemplacementsProvider`
/// est nul tant que REMPL-BR n'est pas servi).
///
/// [sourcesReelles] : faux (recette, demonstration), `PortGroupes` sert aussi
/// l'enseignant. Vrai (application reelle, RECHERCHE-LIVRAISON, verdict du
/// garde-cap sur la PR 347) : `PortGroupes` lit en production une vue qui ne
/// rend AUCUNE ligne a un enseignant ; ses eleves se cherchent donc par ses
/// classes lues comme « Mes classes » les lit (`ServiceEnseignant.groupes`).
List<MoteurRechercheDomaine> moteursEnseignantsPedagogieControle(
  Ref ref, {
  bool sourcesReelles = false,
}) {
  final PortRemplacements? remplacements = ref.watch(portRemplacementsProvider);
  final PortGroupes groupes = ref.watch(portGroupesProvider);
  return <MoteurRechercheDomaine>[
    MoteurEnseignantsDesClasses(groupes),
    if (remplacements != null) MoteurRemplacements(remplacements),
    if (sourcesReelles)
      // Les eleves de l'ENSEIGNANT par ses classes, lues comme « Mes classes »
      // les lit, a chaque recherche (voir [sourcesReelles]).
      MoteurPedagogieEleves.surClassesEnseignant(
        classes: () async => <ClasseCherchee>[
          for (final GroupeEnseignant g
              in await ref.read(serviceEnseignantProvider).groupes())
            (id: g.id, libelle: g.libelle),
        ],
        roster: ref.watch(portRosterEnseignantProvider),
      )
    else
      MoteurPedagogieEleves(groupes, ref.watch(portRosterEnseignantProvider)),
    // La mission est relue a chaque recherche dans l'application reelle ; la
    // recette garde la valeur memorisee de `missionControleProvider`.
    MoteurControleMission(
      lire: sourcesReelles
          ? () => ref.read(portMissionControleProvider).maMission()
          : () => ref.read(missionControleProvider.future),
    ),
  ];
}
