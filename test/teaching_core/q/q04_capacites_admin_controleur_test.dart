// Q-04 : les capacites de l Admin (incognito / visible) et du Controleur
// (incognito seul) sont correctes.
//
// INVARIANT 6 de la Phase 6 (spec section 15 : « aucun Admin/Controleur
// incognito n apparait chez les participants ») et section 15 encore
// (« aucun participant visible ne peut obtenir des capacites superieures a
// son token »). Decisions D-15 et D-16.
//
// OU EST LA VERITE. Les capacites viennent du jeton serveur
// (`autoriser_jeton_video`), derivees du SEUL role. Ce test ne les applique
// pas : il verifie que la table des roles dit la bonne chose, pour qu Agent Z
// la confronte au SQL. C est une specification executable, pas une barriere.

// Suppression du 08/11/2026 (feu vert du directeur) : la table des
// capacites par role (`capacites_observateur.dart`, double de test) est
// retiree ; la verite reste `autoriser_jeton_video`. Reste la visite journalisee.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';

import '../fixtures/fixtures_observation.dart';
import 'faux/faux_serveur_observation.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 19, 16);

void main() {
  group('Q-04 : le role est porte par la visite journalisee', () {
    test('une visite Admin incognito est auditee comme les autres', () {
      final FauxServeurObservation serveur = FauxServeurObservation(
        politique: politiquePersonnalisee,
      );
      serveur.entrer(
        sessionId: 'seance-1',
        groupeId: 'grp-plein',
        observateurProfilId: 'admin-1',
        role: RoleObservateur.adminIncognito,
        maintenantUtc: _t0,
      );
      final GuardianSessionVisit? fermee = serveur.sortir(
        maintenantUtc: _t0.add(const Duration(seconds: 60)),
      );

      expect(fermee?.role, RoleObservateur.adminIncognito);
      expect(fermee?.durationSeconds, const Duration(seconds: 60));
      expect(fermee?.policyVersion, politiquePersonnalisee.policyVersion);
      // Un Admin n observe pas « un enfant » : il observe une seance.
      expect(fermee?.enfantConcerneId, isNull);
      expect(serveur.journal, hasLength(1));
    });
  });
}
