// SALLE-2-ENTRETIEN (07/11/2026) : la salle d'un entretien. Les roles du
// jeton `candidat` et `intervieweur` sont lus (plus de repli en lecture
// seule), et la mention « Cours enregistre, visite de controle possible » ne
// s'y affiche pas : un entretien n'est pas un cours, et rien n'y est
// enregistre. Le rappel « Entretien en visio » la remplace.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/service_video.dart';
import 'package:rewayah_academy/core/widgets/permanent_notice.dart';
import 'package:rewayah_academy/features/salle/salle_page.dart';
import 'package:rewayah_academy/features/salle/vue_salle.dart';
import 'package:rewayah_academy/features/salle_seance/presentation_observee.dart';

import '../../capture/outil_capture.dart';
import '../../support/demo/salle_controleur_demo.dart';

class _SessionCandidat extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.teacher,
    profileId: 'demo-candidat',
    accountStatus: AccountStatus.pendingKyc,
    lectureProfil: LectureProfil.presente,
  );
}

Future<void> _monter(WidgetTester tester, String roleJeton) async {
  fixerVueCapture(tester, const Size(390, 844), 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      ProviderScope(
        overrides: <Override>[
          sessionProvider.overrideWith(_SessionCandidat.new),
          moteurSalleProvider.overrideWith(
            (Ref _) => MoteurSalleControleurDemo(),
          ),
          serviceVideoProvider.overrideWithValue(
            ServiceVideoControleurDemo(role: roleJeton),
          ),
          servicePreVolProvider.overrideWithValue(const PreVolControleurDemo()),
          preVolProvider.overrideWith(
            (Ref _) => const PreVolControleurDemo().verifier(),
          ),
          presenceSeanceProvider.overrideWith(
            (Ref _, String _) => Stream<List<PresenceParticipant>?>.value(null),
          ),
          servicePresenceProvider.overrideWithValue(
            const PresenceControleurDemo(),
          ),
          presentationObserveeProvider.overrideWith((Ref _, String _) => null),
        ],
        child: const SallePage(seanceId: 'seance-entretien'),
      ),
    ),
  );
  await stabiliser(tester);
}

void main() {
  test('les roles du jeton candidat et intervieweur sont lus', () {
    expect(RoleSalle.depuis('candidat'), RoleSalle.candidat);
    expect(RoleSalle.depuis('intervieweur'), RoleSalle.intervieweur);
    expect(RoleSalle.depuis('autre_role'), RoleSalle.inconnu);
  });

  for (final String role in <String>['candidat', 'intervieweur']) {
    testWidgets('$role : aucune mention pendant l\'entretien (CAND-Q09) : '
        'ni « Cours enregistre », ni aucun rappel', (
      WidgetTester tester,
    ) async {
      await _monter(tester, role);
      expect(find.byType(PermanentNotice), findsNothing);
      expect(find.text(t.salle.bandeauPermanent), findsNothing);
      expect(
        find.byWidgetPredicate(
          (Widget w) => w.runtimeType.toString() == '_Rappel',
        ),
        findsNothing,
      );
    });
  }

  testWidgets('contre-epreuve : hors entretien (tuteur), la mention du cours '
      'reste', (WidgetTester tester) async {
    await _monter(tester, 'guardian_observer');
    expect(find.byType(PermanentNotice), findsOneWidget);
    // Le tuteur qui observe garde son rappel : le predicat voit bien un
    // _Rappel quand il y en a un.
    expect(
      find.byWidgetPredicate(
        (Widget w) => w.runtimeType.toString() == '_Rappel',
      ),
      findsOneWidget,
    );
  });
}
