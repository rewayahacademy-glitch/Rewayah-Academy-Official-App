import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enseignant/port_remplacements.dart';
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
List<MoteurRechercheDomaine> moteursEnseignantsPedagogieControle(Ref ref) {
  final PortRemplacements? remplacements = ref.watch(portRemplacementsProvider);
  return <MoteurRechercheDomaine>[
    MoteurEnseignantsDesClasses(ref.watch(portGroupesProvider)),
    if (remplacements != null) MoteurRemplacements(remplacements),
    MoteurPedagogieEleves(
      ref.watch(portGroupesProvider),
      ref.watch(portRosterEnseignantProvider),
    ),
    MoteurControleMission(lire: () => ref.read(missionControleProvider.future)),
  ];
}
