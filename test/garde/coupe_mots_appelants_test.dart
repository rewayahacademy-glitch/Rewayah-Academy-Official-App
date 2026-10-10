// COUPE-MOTS-FOND-1 (K-66.5) : les composants partages changes par l'etape
// (`DataCollection`, `RangeeFiltres`, `TexteSansCoupure`) mesures chez un
// appelant de chaque AUTRE role que l'administration, par la garde du
// rendu, aux gabarits de la fiche (320 x 568 texte x2, 390 x 844, 1440 x 900
// texte x2), francais et arabe, standard et Interface guidee :
//   * eleve : son Suivi (`SuiviElevePage`, une `DataCollection`) ;
//   * comptable : Paiements et Contractuels en demonstration (une
//     `DataCollection` et une `RangeeFiltres` chacun ; ecrans de la voie FIN,
//     mesures sans etre modifies).
// Le controleur (Historique, `RangeeFiltres`), le tuteur (Historique,
// `RangeeFiltres` partagee du foyer) et l'eleve ou le tuteur en Bibliotheque
// (`RangeeFiltres`) sont balayes par `coupe_mots_balayage_roles_test.dart`
// et `coupe_mots_balayage_pages_test.dart`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/features/demo/demo_comptable_page.dart';
import 'package:rewayah_academy/features/suivi_eleve/suivi_eleve_page.dart';

import '../support/balayage_ecrans.dart';
import '../support/harnais.dart' show FauxServiceSuivi;

final DateTime _maintenant = DateTime(2026, 9, 23, 18, 30);

Seance _seance(String id, int ilYAJours) {
  final DateTime debut = _maintenant.subtract(Duration(days: ilYAJours));
  return Seance(
    id: id,
    debut: debut,
    fin: debut.add(const Duration(minutes: 60)),
    statut: StatutSeance.terminee,
    eleveId: 'eleve-1',
    elevePrenom: 'Sofia',
    eleveIdentifiant: 'STUDENT-SF-000001',
    enseignantId: 'ens-1',
    enseignantPrenom: 'Rachid',
    enseignantIdentifiant: 'TEACHER-RB-000001',
  );
}

PresenceParticipant _presence(String seanceId) => PresenceParticipant(
  seanceId: seanceId,
  profilId: 'eleve-1',
  role: 'student',
  prenom: 'Sofia',
  identifiantImmuable: 'STUDENT-SF-000001',
  etat: EtatPresence.finalisee,
  consolide: true,
);

List<Override> _aucune() => const <Override>[];

/// Les appelants des autres roles.
List<EcranBalayage> ecransAppelants() => <EcranBalayage>[
  (
    nom: 'eleve suivi',
    page: () => SuiviElevePage(horloge: () => _maintenant),
    routeur: null,
    depart: null,
    surcharges: () => <Override>[
      serviceSuiviProvider.overrideWithValue(
        FauxServiceSuivi(
          seancesRendues: <Seance>[_seance('s1', 0), _seance('s2', 7)],
          presencesRendues: <PresenceParticipant>[
            _presence('s1'),
            _presence('s2'),
          ],
        ),
      ),
    ],
  ),
  for (final EcranDemoComptable e in <EcranDemoComptable>[
    EcranDemoComptable.paiements,
    EcranDemoComptable.contractuels,
  ])
    (
      nom: 'comptable ${e.name}',
      page: null,
      routeur: (WidgetRef _) => GoRouter(
        initialLocation: adresseDemoComptable(e),
        routes: routesDemoComptable('dev'),
      ),
      depart: null,
      surcharges: _aucune,
    ),
];

void main() {
  balayer(ecransAppelants());
}
