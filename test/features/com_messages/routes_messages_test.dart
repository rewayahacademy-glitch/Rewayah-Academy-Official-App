// COM-MSG-1 sur le VRAI routeur (K-07) : `/enseignant/messages` et
// `/tuteur/messages` rendent la page remplie dans la coquille du role
// (aucune destination ajoutee), toucher une conversation ouvre
// `/messages/:filId`, le retour ramene a la liste.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/com_messages/entete_fil_contexte.dart';
import 'package:rewayah_academy/features/com_messages/liste_fils.dart';
import 'package:rewayah_academy/features/com_messages/messages_page.dart';
import 'package:rewayah_academy/features/com_messages/port_messages_metier.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';
import 'support_messages.dart';

Future<GoRouter> _monter(
  WidgetTester tester,
  String depart,
  AppRole role,
  PortMessagesMetier port, {
  Size taille = const Size(390, 844),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(FausseSourceSession(sessionActive(role))),
        portClassesFoyerProvider.overrideWithValue(
          const ClassesFoyerIndisponible(),
        ),
        portMessagesMetierProvider.overrideWithValue(port),
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

void main() {
  testWidgets('enseignant, 390 : la liste, puis le fil par l adresse, '
      'puis le retour', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(
      tester,
      Routes.enseignantMessages,
      AppRole.teacher,
      portDemo(RoleDemoCommunications.enseignant),
    );
    expect(lieu(routeur), Routes.enseignantMessages);
    expect(find.byType(NavShell), findsOneWidget);
    expect(find.byType(ListeFils), findsOneWidget);

    await tester.tap(find.byKey(ListeFils.cleLigne('fil-adam')));
    await stabiliser(tester);
    expect(lieu(routeur), Routes.enseignantFilPour('fil-adam'));
    expect(
      tester.widget<MessagesPage>(find.byType(MessagesPage)).filId,
      'fil-adam',
    );
    expect(find.byType(EnteteFilContexte), findsOneWidget);
    expect(find.byType(FilDiscussion), findsOneWidget);
    expect(
      tester.widget<NavShell>(find.byType(NavShell)).indexActif,
      1,
      reason: 'la pose garde la destination Classes',
    );

    await tester.tap(find.byType(DisqueRetour));
    await stabiliser(tester);
    expect(lieu(routeur), Routes.enseignantMessages);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tuteur, 1440 : trois panneaux dans la coquille, et la '
      'ligne d un autre fil change l adresse', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(
      tester,
      Routes.tuteurFilPour('fil-adam'),
      AppRole.guardian,
      portDemo(RoleDemoCommunications.tuteur),
      taille: const Size(1440, 900),
    );
    expect(find.byType(NavShell), findsOneWidget);
    expect(find.byType(FilDiscussion), findsOneWidget);
    await tester.tap(find.byKey(ListeFils.cleLigne('fil-dossier-adam')));
    await stabiliser(tester);
    expect(lieu(routeur), Routes.tuteurFilPour('fil-dossier-adam'));
    expect(
      find.descendant(
        of: find.byType(EnteteFilContexte),
        matching: find.text("Dossier d'inscription d'Adam"),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans port branche (production) : pas encore disponible', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      Routes.tuteurMessages,
      AppRole.guardian,
      const MessagesMetierIndisponibles(),
    );
    expect(
      find.text(t.com.socle.composants.etats.indisponibleTitre),
      findsWidgets,
    );
    expect(find.text(t.com.socle.composants.etats.reessayer), findsNothing);
  });

  test('le chemin de la liste se lit sur l adresse, jamais sur un role', () {
    expect(
      cheminListeMessages(Uri.parse('/enseignant/messages'), filOuvert: false),
      '/enseignant/messages',
    );
    expect(
      cheminListeMessages(Uri.parse('/tuteur/messages/fil-7'), filOuvert: true),
      '/tuteur/messages',
    );
  });
}
