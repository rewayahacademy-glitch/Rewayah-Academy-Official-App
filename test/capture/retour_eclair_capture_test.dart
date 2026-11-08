// Captures du Retour eclair (NON-BRANCHE-LIVRAISON 5, 08/11/2026) :
// - eleve : l'ecran de fin de seance avec la question, puis la reponse non
//   partie (« Reessayer ») ;
// - enseignant : la tendance de comprehension de la Classe.
// 390x844 @3 et 1440x900 @1, clair, francais et arabe. Donnees de test.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_parcours/port_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/session_feedback.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/features/salle_seance/resultat_seance.dart';
import 'package:rewayah_academy/features/tc_flux_academique/carte_feedback_seance.dart';
import 'package:rewayah_academy/features/tc_flux_academique/tendance_feedback_classe.dart';

import 'outil_capture.dart';

class _Port implements PortFeedback {
  _Port({required this.perdu});

  final bool perdu;

  @override
  Future<QuestionFeedback?> questionPour(String sessionId) async =>
      const QuestionFeedback(
        id: 'comprehension',
        intitule: 'serveur',
        libelles: <ReponseFeedback, String>{
          ReponseFeedback.difficile: 'Difficile',
          ReponseFeedback.bien: 'Bien',
          ReponseFeedback.tresBien: 'Très bien',
        },
      );

  @override
  Future<void> soumettre({
    required String sessionId,
    required String questionId,
    required ReponseFeedback reponse,
  }) async {
    if (perdu) throw const EchecFeedback(MotifEchecFeedback.ecriture);
  }

  @override
  Future<TendanceFeedback> tendance({required String groupeId}) async =>
      const TendanceFeedback(
        groupeId: 'c1',
        nombreEchantillons: 12,
        seuilMinimum: 5,
        visibleParEnseignant: true,
        repartition: <ReponseFeedback, double>{
          ReponseFeedback.difficile: 0.25,
          ReponseFeedback.bien: 0.5,
          ReponseFeedback.tresBien: 0.25,
        },
      );
}

void main() {
  group('Capture : Retour eclair', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (Size taille, double densite) in <(Size, double)>[
      (const Size(390, 844), 3),
      (const Size(1440, 900), 1),
    ]) {
      final String format =
          '${taille.width.toInt()}x${taille.height.toInt()}@${densite.toInt()}';
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
        final String l = langue.languageCode;
        for (final String cas in <String>['question', 'non_partie']) {
          testWidgets('$format, ${l}_eleve_$cas', (WidgetTester tester) async {
            await tester.runAsync(() => LocaleSettings.setLocale(langue));
            fixerVueCapture(tester, taille, densite);
            await tester.pumpWidget(
              hoteCapture(
                ResultatSeance(
                  issue: IssueSeance.terminee,
                  heureFin: '18:45',
                  onRetour: () {},
                  complement: const CarteFeedbackSeance(sessionId: 's1'),
                ),
                surcharges: <Override>[
                  portFeedbackProvider.overrideWithValue(
                    _Port(perdu: cas == 'non_partie'),
                  ),
                ],
              ),
            );
            await stabiliser(tester);
            if (cas == 'non_partie') {
              await tester.tap(
                find.text(t.tc.parcours.feedback.comprehension.bien),
              );
              await stabiliser(tester);
              expect(
                find.byKey(CarteFeedbackSeance.nonPartieKey),
                findsOneWidget,
              );
            }
            expect(tester.takeException(), isNull);
            debugPrint(
              'PNG ${await capturer(tester, 're_${format}_${l}_eleve_$cas')}',
            );
            await tester.pumpWidget(const SizedBox());
            await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
          });
        }
        testWidgets('$format, ${l}_enseignant', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          fixerVueCapture(tester, taille, densite);
          await tester.pumpWidget(
            hoteCapture(
              Scaffold(
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppPage.largeurReglages,
                        ),
                        child: const BlocTendanceFeedback(groupeId: 'c1'),
                      ),
                    ),
                  ),
                ),
              ),
              surcharges: <Override>[
                portFeedbackProvider.overrideWithValue(_Port(perdu: false)),
              ],
            ),
          );
          await stabiliser(tester);
          expect(find.byKey(BlocTendanceFeedback.visibleKey), findsOneWidget);
          expect(tester.takeException(), isNull);
          debugPrint(
            'PNG ${await capturer(tester, 're_${format}_${l}_enseignant')}',
          );
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.fr));
        });
      }
    }
  });
}
