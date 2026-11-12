// Captures de RELEVE-SUIVI point 7 (08/11/2026) : Ma classe de l'eleve
// adulte, avec sa ligne de progression lue par `progression_famille` (niveau
// et derniere etape partagee), puis la meme ligne quand la lecture echoue
// (« Non disponible » pour elle seule). 390x844 @3 et 1440x900 @1, clair,
// francais et arabe. Donnees de test uniquement.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/accueil_adulte/port_espace_adulte.dart';
import 'package:rewayah_academy/features/ma_classe_adulte/ma_classe_adulte_page.dart';

import '../support/demo/classe_demo.dart';
import '../support/demo/demo_classe_page.dart' show surchargesEleveDemo;
import 'outil_capture.dart';

class _Progression implements PortProgressionFamille {
  const _Progression({required this.panne, required this.ar});
  final bool panne;
  final bool ar;

  @override
  Future<ProgressionEleve> progression(String eleveId) async {
    if (panne) throw StateError('progression indisponible');
    return ProgressionEleve(
      eleveId: eleveId,
      niveauHumain: ar ? 'الأساسيات' : 'Les bases',
      jalons: <String>[ar ? 'القراءة بالحركات' : 'Lire avec les voyelles'],
    );
  }
}

class _Espace extends EspaceAdulteIndisponible {
  const _Espace();

  @override
  Future<MaClasseAdulteVM> maClasse() async =>
      const MaClasseAdulteVM(groupeId: DonneesClasseDemo.groupeId);
}

class _Session extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.guardian,
    profileId: 'p-adulte',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
    eleveAutonome: true,
  );
}

void main() {
  group('Capture : progression de l eleve adulte', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size taille, double densite) in <(Size, double)>[
      (const Size(390, 844), 3),
      (const Size(1440, 900), 1),
    ]) {
      final String format =
          '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        for (final bool panne in <bool>[false, true]) {
          final String cas =
              '${langue.languageCode}_${panne ? 'panne' : 'complete'}';
          testWidgets('$format, $cas', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, densite);
            final bool ar = langue == AppLocale.ar;
            await tester.pumpWidget(
              hoteCapture(
                const MaClasseAdultePage(),
                surcharges: <Override>[
                  ...surchargesEleveDemo(EtatDemoClasse.aVenir),
                  sessionProvider.overrideWith(_Session.new),
                  portEspaceAdulteProvider.overrideWithValue(const _Espace()),
                  portProgressionFamilleProvider.overrideWithValue(
                    _Progression(panne: panne, ar: ar),
                  ),
                ],
              ),
            );
            await stabiliser(tester);
            final Finder ligne = find.byKey(
              const ValueKey<String>('ma-classe-progression'),
            );
            await tester.scrollUntilVisible(
              ligne,
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await stabiliser(tester);
            expect(
              find.text(t.compte.nonDisponible),
              panne ? findsOneWidget : findsNothing,
            );
            expect(tester.takeException(), isNull);
            debugPrint('PNG ${await capturer(tester, 'pa_${format}_$cas')}');
            await tester.pumpWidget(const SizedBox());
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
          });
        }
      }
    }
  });
}
