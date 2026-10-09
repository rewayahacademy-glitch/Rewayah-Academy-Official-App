// FILTRES-1b, Observations (admin) :
//
// (4) a partir de 600 px, une personne retenue (tuteur ou eleve) rejoint
//     les menus sur la MEME rangee, jamais une seconde rangee de puces ;
// (5) a 320 px texte x2, aucune ligne de la liste ne coupe un mot : ni le
//     nom (« Fatouma / ta »), ni la date (« 23/09/2026 »).
//
// L'ecran se monte seul sur des doubles en memoire (port, annuaire),
// aucun Supabase.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/rangee_filtres.dart';
import 'package:rewayah_academy/features/admin_observations/annuaire_observations.dart';
import 'package:rewayah_academy/features/admin_observations/observations_admin_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../router/support_routeur.dart' show stabiliser;
import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart' show FauxServiceReseau;
import '../../support/sens_et_echelle.dart';
import 'support_admin_observations.dart';

Finder get _champ => find.descendant(
  of: find.byType(RechercheObservations),
  matching: find.byType(TextField),
);

final Finder _puces = find.byWidgetPredicate(
  (Widget w) => w is FilterPill || (w is MenuFiltre && !w.selecteurDeSection),
);

Future<void> _monter(
  WidgetTester tester,
  Size vue, {
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
}) async {
  tester.view.physicalSize = vue;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portHistoriqueObservationsAdminProvider.overrideWithValue(
          FauxHistoriqueObservationsAdmin(),
        ),
        annuaireObservationsProvider.overrideWithValue(FauxAnnuaire()),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          locale: AppLocale.fr.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: sensEtEchelle(direction: sens, echelle: echelle),
          home: ObservationsAdminPage(horloge: () => DateTime(2026, 10, 5, 12)),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

/// Choisit un tuteur puis un eleve par la recherche.
Future<void> _retenirPersonnes(WidgetTester tester) async {
  for (final (String saisie, String cle) in <(String, String)>[
    ('Fatou', 'personne-tuteur-fatoumata'),
    ('Mari', 'personne-eleve-mariam'),
  ]) {
    await tester.enterText(_champ, saisie);
    await stabiliser(tester);
    await tester.tap(find.byKey(ValueKey<String>(cle)));
    await stabiliser(tester);
  }
}

void main() {
  setUpAll(chargerPolicesDuDepot);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final double largeur in const <double>[600, 1024, 1440]) {
    for (final double echelle in const <double>[1, 2]) {
      testWidgets('$largeur texte x${echelle.toInt()} : tuteur et eleve '
          'retenus, UNE seule rangee de filtres', (WidgetTester tester) async {
        await _monter(tester, Size(largeur, 900), echelle: echelle);
        await _retenirPersonnes(tester);
        expect(
          find.text(t.admin.observations.filtreTuteur(nom: 'Fatoumata Diallo')),
          findsOneWidget,
        );
        final List<Rect> boites = <Rect>[
          for (int i = 0; i < _puces.evaluate().length; i++)
            tester.getRect(_puces.at(i)),
        ];
        // Les menus et les deux personnes.
        expect(boites.length, greaterThanOrEqualTo(4));
        for (final Rect b in boites) {
          expect(
            b.top,
            moreOrLessEquals(boites.first.top, epsilon: 0.5),
            reason: 'une seconde rangee de puces : $boites',
          );
        }
        // La recherche garde sa place a cote de la rangee : un tiers de la
        // barre au moins.
        final Rect champ = tester.getRect(_champ);
        final Rect barre = champ.expandToInclude(
          tester.getRect(find.byType(RangeeFiltres)),
        );
        expect(champ.top, lessThan(boites.first.bottom));
        expect(champ.width, greaterThanOrEqualTo(barre.width / 3 - 1));
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final TextDirection sens in TextDirection.values) {
    testWidgets('320 texte x2 ${sens.name} : aucune ligne de la liste ne '
        'coupe un mot (nom, date)', (WidgetTester tester) async {
      await _monter(tester, const Size(320, 640), echelle: 2, sens: sens);
      // Le premier nom et la premiere date se lisent.
      expect(find.text('Fatoumata Diallo'), findsWidgets);
      final Finder liste = find.byWidgetPredicate(
        (Widget w) => w is ListView && w.scrollDirection == Axis.vertical,
      );
      expect(liste, findsOneWidget);
      verifierAucunMotCoupe(tester, liste);
      // Jusqu'a la derniere ligne.
      final ScrollableState defileur = tester.state<ScrollableState>(
        find.descendant(of: liste, matching: find.byType(Scrollable)).first,
      );
      while (defileur.position.pixels < defileur.position.maxScrollExtent) {
        defileur.position.jumpTo(
          (defileur.position.pixels + 200).clamp(
            0,
            defileur.position.maxScrollExtent,
          ),
        );
        await tester.pump();
        verifierAucunMotCoupe(tester, liste);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
