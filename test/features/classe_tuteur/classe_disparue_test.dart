// Fiche « Fraicheur et notifications » (27/10/2026), ligne 7 : la classe est
// supprimee pendant que son ecran est ouvert. Le serveur le signale (veille
// de fraicheur), la relecture ne la trouve plus, la personne lit « Cette
// classe n'existe plus. » et revient a son accueil.
//
// Sur le VRAI routeur du tuteur, avec le faux canal de veille et le faux port
// des classes de `support_classe.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/fraicheur/avis_ephemere.dart';
import 'package:rewayah_academy/core/fraicheur/classe_disparue.dart';
import 'package:rewayah_academy/core/fraicheur/port_veille.dart';
import 'package:rewayah_academy/core/fraicheur/veille_fraicheur.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/accueil_famille/accueil_famille_page.dart';
import 'package:rewayah_academy/features/classe_tuteur/classe_tuteur_page.dart';

import '../../fixtures/tuteur/faux_classes_foyer.dart';
import '../../support/monter_admin_demo.dart' show stabiliser;
import 'support_classe.dart';

class _VeillePilotee implements PortVeille {
  // Ferme par `addTearDown` dans chaque test.
  // ignore: close_sinks
  final StreamController<SignalVeille> flux =
      StreamController<SignalVeille>.broadcast();

  @override
  Stream<SignalVeille> ecouter() => flux.stream;
}

void main() {
  testWidgets(
    'ligne 7 : classe supprimee, ecran ouvert : message et retour a l accueil',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final _VeillePilotee veille = _VeillePilotee();
      addTearDown(veille.flux.close);
      final FauxClassesFoyer classes = FauxClassesFoyer(
        classes: <ClasseFoyer>[
          ClasseFoyer(eleveId: eleveA1, classe: classeFictive()),
        ],
      );
      late GoRouter routeur;
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            ...surchargesClasse(portClasses: classes),
            portVeilleProvider.overrideWithValue(veille),
          ],
          child: TranslationProvider(
            child: Consumer(
              builder: (BuildContext _, WidgetRef ref, Widget? _) {
                routeur = ref.read(routeurProvider);
                // Comme `RewayahApp` : la veille est montee avec l'application
                // et l'avis prend sa place au-dessus des ecrans.
                ref.watch(veilleFraicheurProvider);
                return MaterialApp.router(
                  theme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.light,
                  ),
                  routerConfig: routeur,
                  builder: (BuildContext _, Widget? enfant) => Column(
                    children: <Widget>[
                      const BandeauAvisEphemere(),
                      Expanded(child: enfant ?? const SizedBox.shrink()),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await stabiliser(tester);
      routeur.go('${Routes.tuteurClasses}/$classeA?eleve=$eleveA1');
      await stabiliser(tester);
      expect(find.byType(ClasseTuteurPage), findsOneWidget);
      expect(find.text(t.classe.disparue), findsNothing);

      // L'administration supprime la classe : le serveur le signale.
      classes.classes = <ClasseFoyer>[];
      veille.flux.add(const ChangementTable('groupes'));
      await stabiliser(tester);

      expect(find.text(t.classe.disparue), findsOneWidget);
      expect(find.byType(AccueilFamillePage), findsOneWidget);
      expect(find.byType(ClasseTuteurPage), findsNothing);
      expect(
        routeur.routerDelegate.currentConfiguration.uri.path,
        Routes.tuteurAccueil,
      );

      // L'avis se retire de lui-meme.
      await tester.pump(AppMouvement.retourLocalMaintien);
      await stabiliser(tester);
      expect(find.text(t.classe.disparue), findsNothing);
    },
  );

  testWidgets('un signal qui ne change rien laisse l ecran en place', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final _VeillePilotee veille = _VeillePilotee();
    addTearDown(veille.flux.close);
    late GoRouter routeur;
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...surchargesClasse(),
          portVeilleProvider.overrideWithValue(veille),
        ],
        child: TranslationProvider(
          child: Consumer(
            builder: (BuildContext _, WidgetRef ref, Widget? _) {
              routeur = ref.read(routeurProvider);
              ref.watch(veilleFraicheurProvider);
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
    routeur.go('${Routes.tuteurClasses}/$classeA?eleve=$eleveA1');
    await stabiliser(tester);

    veille.flux.add(const ChangementTable('groupes'));
    await stabiliser(tester);
    veille.flux.add(const ChangementTable('sessions'));
    await stabiliser(tester);

    expect(find.byType(ClasseTuteurPage), findsOneWidget);
    expect(find.text(t.classe.disparue), findsNothing);
  });

  group('classeDisparue (pure)', () {
    bool presente(int? v) => v != null;

    test('vrai seulement : presente avant, absente apres, relecture finie', () {
      expect(
        classeDisparue<int?>(
          const AsyncData<int?>(1),
          const AsyncData<int?>(null),
          presente: presente,
        ),
        isTrue,
      );
    });

    test('faux pendant le chargement, en echec, ou sans lecture avant', () {
      expect(
        classeDisparue<int?>(
          const AsyncData<int?>(1),
          const AsyncLoading<int?>(),
          presente: presente,
        ),
        isFalse,
      );
      expect(
        classeDisparue<int?>(
          const AsyncData<int?>(1),
          AsyncError<int?>(StateError('reseau'), StackTrace.empty),
          presente: presente,
        ),
        isFalse,
      );
      expect(
        classeDisparue<int?>(
          null,
          const AsyncData<int?>(null),
          presente: presente,
        ),
        isFalse,
      );
      expect(
        classeDisparue<int?>(
          const AsyncData<int?>(null),
          const AsyncData<int?>(null),
          presente: presente,
        ),
        isFalse,
      );
      expect(
        classeDisparue<int?>(
          const AsyncData<int?>(1),
          const AsyncData<int?>(2),
          presente: presente,
        ),
        isFalse,
      );
    });
  });
}
