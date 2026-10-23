// COM-VOC-1 : la demonstration du message vocal, par sa vraie route
// (`/demo/communications?voie=vocal`), jamais en production. Le composer est
// rendu dans l'emplacement vocal du composer de COM-F (`FilDiscussion`) ;
// les cinq situations se choisissent ; 390, 768, 1440, clair et sombre,
// texte x2.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/features/com_vocal/composer_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/lecteur_vocal.dart';
import 'package:rewayah_academy/features/com_vocal/port_enregistreur_vocal.dart';
import 'package:rewayah_academy/features/demo/communications/com_vocal_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import 'support_vocal.dart';

Future<HorlogeManuelle> _monter(
  WidgetTester tester, {
  Size taille = const Size(390, 844),
  Brightness luminosite = Brightness.light,
  double echelle = 1,
  RoleDemoCommunications? role,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final HorlogeManuelle horloge = HorlogeManuelle();
  final GoRouter routeur = GoRouter(
    initialLocation: adresseDemoCommunications(
      VoieDemoCommunications.vocal,
      role: role,
    ),
    routes: <RouteBase>[...routesDemoCommunications('staging')],
  );
  addTearDown(routeur.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        horlogeVocaleProvider.overrideWithValue(horloge.horloge),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
          themeMode: luminosite == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          builder: (BuildContext context, Widget? app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: app!,
          ),
          routerConfig: routeur,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
  return horloge;
}

Future<void> _toucher(WidgetTester tester, Key cle) async {
  await tester.ensureVisible(find.byKey(cle));
  await tester.pump();
  await tester.tap(find.byKey(cle));
  await tester.pump();
  await tester.pump();
}

/// Choisit une situation par le vrai `SelecteurSection` : un segment s'il
/// tient en ligne, sinon le menu deroulant.
Future<void> _choisirSituation(WidgetTester tester, String libelle) async {
  final Finder segment = find.byWidgetPredicate(
    (Widget w) => w is TexteSansCoupure && w.texte == libelle,
  );
  if (segment.evaluate().isNotEmpty) {
    await tester.ensureVisible(segment);
    await tester.pump();
    await tester.tap(segment);
  } else {
    final Finder menu = find.byType(MenuFiltre<ScenarioVocalDemo>);
    await tester.ensureVisible(menu);
    await tester.pumpAndSettle();
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(libelle).last);
    await tester.pumpAndSettle();
  }
  await tester.pump();
  await tester.pump();
}

void main() {
  final d = t.com.vocal.demo;
  final c = t.com.vocal.composer;

  testWidgets('la voie vocal : composer dans le fil, vocal recu, envoi', (
    WidgetTester tester,
  ) async {
    final HorlogeManuelle horloge = await _monter(tester);
    expect(find.byType(ComVocalDemo), findsOneWidget);
    expect(find.text(t.com.vocal.titre), findsWidgets);
    expect(find.text(d.contexte), findsOneWidget);
    expect(find.text(d.recu), findsOneWidget);
    expect(find.text(d.auteurEnseignante), findsWidgets);
    expect(find.text(t.com.socle.navigation.bientot), findsNothing);

    // Le composer vit dans l'emplacement vocal du fil de COM-F.
    expect(
      find.descendant(
        of: find.byType(FilDiscussion),
        matching: find.byType(ComposerVocal),
      ),
      findsOneWidget,
    );

    await _toucher(tester, FilDiscussion.cleMicro);
    horloge.avancer(const Duration(seconds: 11));
    await tester.pump(const Duration(seconds: 11));
    await _toucher(tester, ComposerVocal.cleArreter);
    expect(find.text(c.duree(duree: '0:11')), findsOneWidget);
    expect(find.text(d.envoyes), findsNothing);

    await _toucher(tester, ComposerVocal.cleEnvoyer);
    expect(find.text(c.envoi), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text(c.envoye), findsOneWidget);
    expect(find.text(d.envoyes), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('vocal-demo-envoye-vocal-demo-1')),
      findsOneWidget,
    );
    verifierUnSeulBoutonPlein(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le role enseignant fait parler une famille', (
    WidgetTester tester,
  ) async {
    await _monter(tester, role: RoleDemoCommunications.enseignant);
    expect(find.text(d.auteurParent), findsWidgets);
    expect(find.text(d.auteurEnseignante), findsNothing);
  });

  testWidgets('situations : refuse, non confirme, indisponible', (
    WidgetTester tester,
  ) async {
    final HorlogeManuelle horloge = await _monter(
      tester,
      taille: const Size(1440, 1200),
    );
    // A 1440, les cinq situations tiennent en ligne.
    await _choisirSituation(tester, d.refuse);
    await _toucher(tester, FilDiscussion.cleMicro);
    expect(find.text(c.refuse), findsOneWidget);

    await _choisirSituation(tester, d.indisponible);
    expect(find.byKey(ComposerVocal.cleIndisponible), findsOneWidget);
    // Indisponible : aucun micro, aucun lien (R-28).
    expect(find.byKey(FilDiscussion.cleMicro), findsNothing);
    expect(find.byKey(ComposerVocal.cleEnregistrer), findsNothing);

    await _choisirSituation(tester, d.nonConfirme);
    await _toucher(tester, FilDiscussion.cleMicro);
    horloge.avancer(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 4));
    await _toucher(tester, ComposerVocal.cleArreter);
    await _toucher(tester, ComposerVocal.cleEnvoyer);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text(c.nonConfirme), findsOneWidget);
    await _toucher(tester, ComposerVocal.cleReessayer);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text(c.envoye), findsOneWidget);

    await _choisirSituation(tester, d.aDemander);
    await _toucher(tester, FilDiscussion.cleMicro);
    expect(find.text(c.permissionPhrase), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('le vocal recu se lit dans la demonstration', (
    WidgetTester tester,
  ) async {
    final HorlogeManuelle horloge = await _monter(tester);
    final Finder recu = find.byKey(const ValueKey<String>('vocal-demo-recu'));
    final Finder action = find.descendant(
      of: recu,
      matching: find.byKey(LecteurVocal.cleAction),
    );
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pump();
    await tester.pump();
    horloge.avancer(const Duration(seconds: 28));
    await tester.pump(const Duration(seconds: 28));
    expect(
      find.descendant(of: recu, matching: find.text(t.com.vocal.lecteur.fin)),
      findsOneWidget,
    );
    expect(dureeVocalRecuDemo, const Duration(seconds: 28));
  });

  group('Rendu de la demonstration', () {
    for (final Size taille in <Size>[
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1440, 900),
    ]) {
      for (final Brightness luminosite in Brightness.values) {
        testWidgets('${taille.width.toInt()} ${luminosite.name}', (
          WidgetTester tester,
        ) async {
          final HorlogeManuelle horloge = await _monter(
            tester,
            taille: taille,
            luminosite: luminosite,
          );
          await _toucher(tester, FilDiscussion.cleMicro);
          horloge.avancer(const Duration(seconds: 5));
          await tester.pump(const Duration(seconds: 5));
          await _toucher(tester, ComposerVocal.cleArreter);
          expect(tester.takeException(), isNull);
          verifierUnSeulBoutonPlein(tester);
          final Rect envoyer = tester.getRect(
            find.byKey(ComposerVocal.cleEnvoyer),
          );
          expect(envoyer.right, lessThanOrEqualTo(taille.width));
        });
      }
    }

    testWidgets('320 en texte x2 : la pre-ecoute tient dans le fil', (
      WidgetTester tester,
    ) async {
      final HorlogeManuelle horloge = await _monter(
        tester,
        taille: const Size(320, 800),
        echelle: 2,
      );
      expect(tester.takeException(), isNull);
      await _toucher(tester, FilDiscussion.cleMicro);
      horloge.avancer(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 5));
      await _toucher(tester, ComposerVocal.cleArreter);
      expect(tester.takeException(), isNull);
      expect(find.byKey(ComposerVocal.cleEnvoyer), findsOneWidget);
    });
  });
}
