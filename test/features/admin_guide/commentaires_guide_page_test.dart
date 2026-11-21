// GUIDE-COMMENTAIRES : la page de la direction qui lit les commentaires du
// guide de l'enseignant et y repond. Ce que le test tient : les parties dans
// l'ordre du serveur (les moins claires d'abord), leurs totaux, les fils
// nommes, le badge « Attend une reponse », la reponse envoyee au dernier
// message du fil puis la page relue ; un echec dit sa phrase ; la capacite
// absente dit que la page n'est pas encore disponible.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_guide/commentaires_guide_page.dart';
import 'package:rewayah_academy/features/admin_guide/port_commentaires_guide.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

class _Faux implements PortCommentairesGuide {
  _Faux({this.erreur, this.panne = false});

  final Exception? erreur;
  final bool panne;
  int lectures = 0;
  final List<(String, String)> reponses = <(String, String)>[];

  @override
  Future<List<PartieGuideDirection>> lire() async {
    lectures++;
    if (erreur case final Exception e) throw e;
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
    if (panne) throw Exception('panne');
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

/// Passe sur « Toutes les parties ».
Future<void> _toutes(WidgetTester tester) async {
  final Finder choix = find.text(t.admin.guideCommentaires.filtreTous(n: 2));
  await tester.ensureVisible(choix.first);
  await tester.tap(choix.first);
  await tester.pumpAndSettle();
}

/// Un faux port avec beaucoup de fils et une longue conversation.
class _Nombreux extends _Faux {
  @override
  Future<List<PartieGuideDirection>> lire() async => <PartieGuideDirection>[
    PartieGuideDirection(
      code: 'p4',
      titre: 'La paie',
      jaime: 1,
      pasClair: 9,
      fils: <FilGuide>[
        for (int i = 0; i < 7; i++)
          FilGuide(
            lecteur: 'Lecteur $i',
            messages: <MessageGuide>[
              MessageGuide(
                id: 'a$i',
                corps: 'Premiere question $i',
                creeLe: DateTime(2026, 11, 21, 8),
                auteur: AuteurMessageGuide.lecteur,
              ),
              MessageGuide(
                id: 'b$i',
                corps: 'Reponse de la direction $i',
                creeLe: DateTime(2026, 11, 21, 9),
                auteur: AuteurMessageGuide.direction,
              ),
              MessageGuide(
                id: 'c$i',
                corps: 'Derniere question $i',
                creeLe: DateTime(2026, 11, 21, 10),
                auteur: AuteurMessageGuide.lecteur,
              ),
            ],
          ),
      ],
    ),
  ];
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final l = t.admin.guideCommentaires;

  testWidgets('les parties dans l\'ordre du serveur, totaux et fils nommes', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Faux());
    await _toutes(tester);
    final Offset p4 = tester.getTopLeft(
      find.byKey(CommentairesGuidePage.clePartie('p4')),
    );
    final Offset p1 = tester.getTopLeft(
      find.byKey(CommentairesGuidePage.clePartie('p1')),
    );
    // Ordre de lecture : sur ordinateur, deux colonnes, p4 a gauche de p1 sur
    // la meme ligne, et aucune carte etiree sur toute la largeur.
    expect(p4.dy, p1.dy);
    expect(p4.dx, lessThan(p1.dx));
    expect(
      tester.getSize(find.byKey(CommentairesGuidePage.clePartie('p4'))).width,
      lessThan(700),
    );
    expect(find.text('4. La paie'), findsOneWidget);
    expect(find.text(l.totaux(jaime: 12, pasClair: 3)), findsOneWidget);
    expect(find.text('Amina Exemple'), findsWidgets);
    expect(find.text('Et pour les adultes ?'), findsOneWidget);
    expect(find.text(l.attend), findsOneWidget);
    expect(find.text(l.aucun), findsOneWidget);
    verifierUnSeulBoutonPlein(tester, maximum: 0);
  });

  testWidgets('repondre : au dernier message du fil, puis la page relue', (
    WidgetTester tester,
  ) async {
    final _Faux port = _Faux();
    await _monter(tester, port);
    await tester.enterText(
      find.descendant(
        of: find.byKey(CommentairesGuidePage.cleChamp('p4', 'Amina Exemple')),
        matching: find.byType(EditableText),
      ),
      '  Oui, la meme regle.  ',
    );
    await tester.tap(
      find.byKey(CommentairesGuidePage.cleRepondre('p4', 'Amina Exemple')),
    );
    await tester.pumpAndSettle();
    expect(port.reponses, <(String, String)>[('m1', 'Oui, la meme regle.')]);
    expect(port.lectures, 2);
  });

  testWidgets('echec de la reponse : la phrase, le texte garde', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Faux(panne: true));
    await tester.enterText(
      find.descendant(
        of: find.byKey(CommentairesGuidePage.cleChamp('p4', 'Amina Exemple')),
        matching: find.byType(EditableText),
      ),
      'Oui.',
    );
    await tester.tap(
      find.byKey(CommentairesGuidePage.cleRepondre('p4', 'Amina Exemple')),
    );
    await tester.pumpAndSettle();
    expect(find.text(l.echec), findsOneWidget);
    expect(find.text('Oui.'), findsOneWidget);
  });

  testWidgets('serveur non installe : la page le dit, sans Reessayer', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      _Faux(erreur: const CapaciteIndisponible('GUIDE-COMMENTAIRES')),
    );
    expect(find.text(l.indisponible), findsOneWidget);
    expect(find.text(t.commun.reessayer), findsNothing);
  });

  testWidgets('390 : la page se lit sans debordement', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Faux(), taille: const Size(390, 844));
    expect(tester.takeException(), isNull);
    await _toutes(tester);
    expect(find.text('4. La paie'), findsOneWidget);
    // Au telephone, une colonne : p1 sous p4.
    expect(
      tester.getTopLeft(find.byKey(CommentairesGuidePage.clePartie('p4'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(CommentairesGuidePage.clePartie('p1'))).dy,
      ),
    );
  });

  // GUIDE-COMMENTAIRES-PILE (directeur, 21/11/2026 : « tu as omis de penser a
  // ce qui se passe quand les commentaires s'accumulent »).
  testWidgets('en attente d abord : la partie sans fil qui attend est cachee', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Faux());
    expect(find.text(l.filtreAttente(n: 1)), findsWidgets);
    expect(find.byKey(CommentairesGuidePage.clePartie('p4')), findsOneWidget);
    expect(find.byKey(CommentairesGuidePage.clePartie('p1')), findsNothing);
  });

  testWidgets('les fils s accumulent : 3 visibles, le reste a la demande', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Nombreux());
    expect(find.text('Lecteur 2'), findsWidgets);
    expect(find.text('Lecteur 3'), findsNothing);
    final Finder autres = find.byKey(CommentairesGuidePage.cleAutresFils('p4'));
    expect(find.text(l.autresFils(n: 4)), findsOneWidget);
    await tester.ensureVisible(autres);
    await tester.tap(autres);
    await tester.pumpAndSettle();
    expect(find.text('Lecteur 6'), findsWidgets);
    expect(find.text(l.replierFils), findsOneWidget);
  });

  testWidgets('un fil replie ne montre que son dernier message', (
    WidgetTester tester,
  ) async {
    await _monter(tester, _Nombreux());
    expect(find.text('Derniere question 0'), findsOneWidget);
    expect(find.text('Premiere question 0'), findsNothing);
    final Finder voir = find.byKey(
      CommentairesGuidePage.cleVoirFil('p4', 'Lecteur 0'),
    );
    await tester.ensureVisible(voir);
    await tester.tap(voir);
    await tester.pumpAndSettle();
    expect(find.text('Premiere question 0'), findsOneWidget);
    expect(find.text('Reponse de la direction 0'), findsOneWidget);
  });
}
