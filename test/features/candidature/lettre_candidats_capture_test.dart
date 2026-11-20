// LETTRE-CANDIDATS : captures R3 de la lettre aux candidats (le haut avec
// Praxis, la paie, le verrou), sautees sans CAPTURE_DIR.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/candidature/lettre/interactions_guide.dart';
import 'package:rewayah_academy/features/candidature/lettre/lettre_candidats_page.dart';
import 'package:rewayah_academy/features/candidature/lettre/port_interactions_guide.dart';
import 'package:rewayah_academy/features/candidature/lettre/port_lettre.dart';

import '../../capture/outil_capture.dart';
import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';
import 'faux_port_lettre.dart';
import 'hote_candidature.dart';

class _Candidat extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    profileId: 'p1',
    role: AppRole.teacher,
    accountStatus: AccountStatus.pendingKyc,
    lectureProfil: LectureProfil.presente,
  );
}

Future<void> _monter(
  WidgetTester tester,
  Size taille, {
  required bool accordsFaits,
  TextDirection? direction,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.lettreEnseignants,
      direction: direction,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.lettreEnseignants,
          builder: (BuildContext _, GoRouterState _) =>
              const LettreCandidatsPage(),
        ),
        ...routesCandidature(),
      ],
      surcharges: <Override>[
        ...surchargesCandidature(
          port: FauxMaCandidature(),
          etat: etatCandidat(candidature: candidatureAFaire()),
        ),
        sessionProvider.overrideWith(_Candidat.new),
        portInteractionsProvider.overrideWithValue(
          FauxPortInteractions(
            jaime: 12,
            fil: <CommentaireGuide>[
              CommentaireGuide(
                id: 'c1',
                partie: 'p4',
                corps: 'Est-ce que la moitie pour un absent vaut aussi pour les adultes ?',
                creeLe: DateTime(2026, 11, 20, 21),
                auteur: AuteurCommentaire.moi,
              ),
              CommentaireGuide(
                id: 'c2',
                partie: 'p4',
                corps: 'Oui, la regle est la meme pour les enfants et les adultes.',
                creeLe: DateTime(2026, 11, 20, 22),
                auteur: AuteurCommentaire.direction,
                parentId: 'c1',
              ),
            ],
          ),
        ),
        portLettreProvider.overrideWithValue(
          FauxPortLettre(
            reponse: accordsFaits
                ? null
                : const LectureLettre.refusee(
                    raison: RaisonRefusLettre.accords,
                    manques: <AccordManquant>[
                      AccordManquant.contrat,
                      AccordManquant.conduite,
                    ],
                  ),
          ),
        ),
      ],
    ),
  );
  await stabiliser(tester);
}

void main() {
  group('captures', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      for (final Size taille in <Size>[
        const Size(1440, 900),
        const Size(390, 844),
      ]) {
        final String nom = '${taille.width.toInt()}-${langue.languageCode}';
        final TextDirection? sens = langue == AppLocale.ar
            ? TextDirection.rtl
            : null;
        testWidgets('lettre-$nom', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(tester, taille, accordsFaits: true, direction: sens);
          await capturerVue(tester, 'lettre-candidats/haut-$nom');
          await tester.scrollUntilVisible(
            find.byKey(ContenuLettre.clePartie(4)),
            400,
            scrollable: find
                .descendant(
                  of: find.byKey(LettreCandidatsPage.cleDefilement),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await stabiliser(tester);
          await capturerVue(tester, 'lettre-candidats/paie-$nom');
          await tester.scrollUntilVisible(
            find.byKey(InteractionsPartie.cleJaime('p4')),
            300,
            scrollable: find
                .descendant(
                  of: find.byKey(LettreCandidatsPage.cleDefilement),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.tap(find.byKey(InteractionsPartie.cleJaime('p4')));
          await stabiliser(tester);
          await capturerVue(tester, 'lettre-candidats/avis-$nom');
          await tester.tap(find.byKey(InteractionsPartie.cleCommenter('p4')));
          await stabiliser(tester);
          await capturerVue(tester, 'lettre-candidats/commentaire-$nom');
        });
        testWidgets('verrou-$nom', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          await _monter(tester, taille, accordsFaits: false, direction: sens);
          await capturerVue(tester, 'lettre-candidats/verrou-$nom');
        });
      }
    }
  }, skip: sautSansCapture);
}
