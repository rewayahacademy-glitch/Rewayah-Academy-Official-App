import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/mode_entree_admin.dart';
import 'package:rewayah_academy/features/tc_observation_ui/options_entree_observation.dart';

void main() {
  group('Qui a le choix de son mode', () {
    test('l\'administration, et elle seule, a deux modes', () {
      final OptionsEntreeObservation options = OptionsEntreeObservation.depuis(
        const SessionState(resolue: true, role: AppRole.admin),
      );

      expect(options.choisitSonMode, isTrue);
      expect(options.modes, ModeEntreeAdmin.values);
      expect(options.modes.length, 2);
      // Le defaut est le moins invasif des deux.
      expect(options.role, RoleObservateur.adminIncognito);
    });

    test('le controleur n\'a AUCUNE option de mode (spec 11.6)', () {
      final OptionsEntreeObservation options = OptionsEntreeObservation.depuis(
        const SessionState(resolue: true, role: AppRole.controller),
      );

      expect(options.modes, isEmpty);
      expect(options.choisitSonMode, isFalse);
      expect(options.role, RoleObservateur.controleur);
    });

    test('on ne rend pas un controleur visible en lui passant un mode', () {
      // La porte derobee la plus evidente : passer le mode visible a un role
      // qui n'y a pas droit. Le mode est ignore, pas applique.
      final OptionsEntreeObservation options = OptionsEntreeObservation.depuis(
        const SessionState(resolue: true, role: AppRole.controller),
      );

      expect(
        options.roleDemande(ModeEntreeAdmin.rejoindreLaClasse),
        RoleObservateur.controleur,
      );
    });

    test('le tuteur entre sans choisir', () {
      final OptionsEntreeObservation options = OptionsEntreeObservation.depuis(
        const SessionState(resolue: true, role: AppRole.guardian),
      );

      expect(options.role, RoleObservateur.tuteur);
      expect(options.modes, isEmpty);
      expect(
        options.roleDemande(ModeEntreeAdmin.observerDiscretement),
        RoleObservateur.tuteur,
      );
    });

    test('l\'administration obtient le role de son mode', () {
      final OptionsEntreeObservation options = OptionsEntreeObservation.depuis(
        const SessionState(resolue: true, role: AppRole.admin),
      );

      expect(
        options.roleDemande(ModeEntreeAdmin.observerDiscretement),
        RoleObservateur.adminIncognito,
      );
      expect(
        options.roleDemande(ModeEntreeAdmin.rejoindreLaClasse),
        RoleObservateur.adminVisible,
      );
    });
  });

  group('Les roles qui n\'observent pas', () {
    test('enseignant, eleve, comptabilite et role inconnu', () {
      for (final AppRole? role in <AppRole?>[
        AppRole.teacher,
        AppRole.student,
        AppRole.accountant,
        null,
      ]) {
        final OptionsEntreeObservation options =
            OptionsEntreeObservation.depuis(
              SessionState(resolue: true, role: role),
            );
        expect(options.observationPossible, isFalse, reason: '$role');
        expect(options.role, isNull, reason: '$role');
        expect(options.roleDemande(null), isNull, reason: '$role');
      }
    });
  });
}
