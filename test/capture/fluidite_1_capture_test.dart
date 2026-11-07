// Captures de FLUIDITE-1 (R3, demande du garde-cap du 07/11) :
// - le Skeleton : au repos (le reflet entre a peine), le reflet a mi-course
//   (une demi-periode plus tard), et sous mouvement reduit (aucun reflet) ;
//   en francais (LTR) et en arabe (RTL, le reflet va dans l'autre sens) ;
//   390x844 @3 ;
// - le fil : un message « non confirme » avec « Reessayer », par l'outil
//   commun d'affichage anticipe. 390x844 @3.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Donnees : fixtures synthetiques, aucune personne reelle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';

import 'outil_capture.dart';

Widget _squelettes({required bool reduit}) => Builder(
  builder: (BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduit),
    child: const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Skeleton.texte(differe: false),
              SizedBox(height: AppSpacing.xl),
              Skeleton.liste(differe: false),
            ],
          ),
        ),
      ),
    ),
  ),
);

const TextesFilDiscussion _textes = TextesFilDiscussion(
  aideChamp: 'Écrire un message…',
  libelleChamp: 'Écrire un message',
  envoyer: 'Envoyer',
  champVide: 'Écrivez un message pour pouvoir l’envoyer.',
  enCours: 'Envoi en cours.',
  envoye: 'Envoyé.',
  echec: 'L’envoi n’est pas confirmé.',
  reessayer: 'Réessayer',
  auteurSoi: 'Vous',
  annonce: _annonce,
);

String _annonce(String a, String t) => '$a : $t';

void main() {
  group('Capture : FLUIDITE-1', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      testWidgets('skeleton, ${langue.languageCode}', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        fixerVueCapture(tester, const Size(390, 844), 3);
        final String l = langue.languageCode;
        await tester.pumpWidget(hoteCapture(_squelettes(reduit: false)));
        await tester.pump(const Duration(milliseconds: 100));
        debugPrint('PNG ${await capturer(tester, 'fl1_skeleton_repos_$l')}');
        // Une demi-periode plus tard : le reflet a mi-course.
        await tester.pump(
          Duration(
            milliseconds: AppMouvement.refletSquelette.inMilliseconds ~/ 2,
          ),
        );
        debugPrint(
          'PNG ${await capturer(tester, 'fl1_skeleton_mi_course_$l')}',
        );
        // Un nouvel ecran, sous mouvement reduit : aucun reflet.
        await tester.pumpWidget(
          hoteCapture(
            KeyedSubtree(
              key: const ValueKey<String>('reduit'),
              child: _squelettes(reduit: true),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.descendant(
            of: find.byType(Skeleton),
            matching: find.byType(Transform),
          ),
          findsNothing,
        );
        debugPrint('PNG ${await capturer(tester, 'fl1_skeleton_reduit_$l')}');
      });
    }

    testWidgets('skeleton, theme sombre, fr', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      await tester.pumpWidget(
        hoteCapture(_squelettes(reduit: false), themeMode: ThemeMode.dark),
      );
      await tester.pump(const Duration(milliseconds: 100));
      debugPrint('PNG ${await capturer(tester, 'fl1_skeleton_repos_sombre')}');
      await tester.pump(
        Duration(
          milliseconds: AppMouvement.refletSquelette.inMilliseconds ~/ 2,
        ),
      );
      debugPrint(
        'PNG ${await capturer(tester, 'fl1_skeleton_mi_course_sombre')}',
      );
    });

    testWidgets('fil : un message non confirme, avec Reessayer', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 844), 3);
      await tester.pumpWidget(
        hoteCapture(
          Scaffold(
            body: SafeArea(
              child: FilDiscussion(
                messages: const <MessageFil>[
                  MessageFil(
                    id: 'm1',
                    auteur: 'Administration',
                    texte: 'Bonjour, la séance de jeudi est maintenue.',
                    horodatage: '09:30',
                    deSoi: false,
                  ),
                ],
                textes: _textes,
                onEnvoyer: (String _) async => throw StateError('reseau'),
              ),
            ),
          ),
        ),
      );
      await stabiliser(tester);
      await tester.enterText(
        find.byKey(FilDiscussion.champKey),
        'Merci, à jeudi.',
      );
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await stabiliser(tester);
      expect(find.text('Réessayer'), findsOneWidget);
      debugPrint('PNG ${await capturer(tester, 'fl1_fil_non_confirme')}');
    });
  });
}
