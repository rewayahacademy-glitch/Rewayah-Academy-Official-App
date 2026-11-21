// GUIDE-COMMENTAIRES : captures R3 de la page de la direction (1440 et 390,
// fr et ar). Sautees sans CAPTURE_DIR.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_guide/commentaires_guide_page.dart';
import 'package:rewayah_academy/features/admin_guide/port_commentaires_guide.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

class _Faux implements PortCommentairesGuide {
  int lectures = 0;
  final List<(String, String)> reponses = <(String, String)>[];

  @override
  Future<List<PartieGuideDirection>> lire() async {
    lectures++;
    return <PartieGuideDirection>[
      PartieGuideDirection(
        code: 'p4',
        titre: 'La paie',
        jaime: 12,
        pasClair: 3,
        fils: <FilGuide>[
          FilGuide(
            lecteur: 'Amina Exemple',
            messages: <MessageGuide>[
              MessageGuide(
                id: 'm1',
                corps: 'Et pour les adultes ?',
                creeLe: DateTime(2026, 11, 21, 9),
                auteur: AuteurMessageGuide.lecteur,
              ),
            ],
          ),
        ],
      ),
      const PartieGuideDirection(
        code: 'p1',
        titre: 'Pourquoi vous recevez ce guide',
        jaime: 4,
        pasClair: 0,
        fils: <FilGuide>[],
      ),
    ];
  }

  @override
  Future<MessageGuide> repondre({
    required String commentaire,
    required String corps,
  }) async {
    reponses.add((commentaire, corps));
    return MessageGuide(
      id: 'm2',
      corps: corps,
      creeLe: DateTime(2026, 11, 21, 10),
      auteur: AuteurMessageGuide.direction,
    );
  }
}

Future<void> _monter(WidgetTester tester, _Faux port, {Size? taille}) async {
  tester.view.physicalSize = taille ?? const Size(1440, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.adminOperationsGuide,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.adminOperationsGuide,
          builder: (BuildContext _, GoRouterState _) =>
              const CommentairesGuidePage(),
        ),
      ],
      surcharges: <Override>[
        portCommentairesGuideProvider.overrideWithValue(port),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('GUIDE-COMMENTAIRES', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);
    for (final (String nom, AppLocale langue, Size taille)
        in <(String, AppLocale, Size)>[
          ('1440-fr', AppLocale.fr, const Size(1440, 900)),
          ('1440-ar', AppLocale.ar, const Size(1440, 900)),
          ('390-fr', AppLocale.fr, const Size(390, 844)),
          ('390-ar', AppLocale.ar, const Size(390, 844)),
        ]) {
      testWidgets('page-$nom', (WidgetTester tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(langue));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
        await _monter(tester, _Faux(), taille: taille);
        await capturerVue(tester, 'GUIDE-COMMENTAIRES/page-$nom');
      });
    }
  });
}
