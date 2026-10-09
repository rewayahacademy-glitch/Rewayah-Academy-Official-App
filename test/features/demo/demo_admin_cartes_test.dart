// CARTES-PERSO-1c (revue CARTES-PERSO-1b, reserve 2) : dans la VRAIE
// demonstration de la direction (`?demo=admin`, montee comme `main.dart` la
// monte), le port des cartes de la Classe lit les cartes de demonstration,
// les memes que l'enseignant et le tuteur, en lecture seule. Avant, il
// restait le port de production : « Les cartes de la classe ne sont pas
// encore ouvertes ».
//
// Le retrait d'une carte par la direction est une ecriture serveur
// (CARTES-BR-02) : la capacite reste fausse et toute ecriture est refusee.
//
// Aucune injection manuelle des cartes : seules les surcharges de
// `surchargesDemoAdmin` sont employees (plus un reseau factice pour le
// rendu isole du bloc, sans rapport avec les cartes).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/cartes_classe.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/cartes_classe_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/bloc_cartes_classe.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/feuille_carte_classe.dart';

import '../../support/harnais.dart' show FauxServiceReseau;

const String _classe = 'demo-classe-direction';

List<String> _titresDemo() => <String>[
  for (final CarteClasse c in cartesClasseDemo(DateTime.now())) c.titre,
];

void main() {
  testWidgets('demonstration direction (montee comme main.dart) : le port '
      'des cartes lit les cartes de demonstration, en lecture seule', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: surchargesDemoAdmin(
          environnement: 'staging',
          etat: etatRevueDemoPour(Uri.parse('/?demo=admin')),
          avecAlertes: true,
          arriveeAlerte: dureeArriveeAlerteDemo,
        ),
        child: TranslationProvider(
          child: RewayahApp(
            builder: (BuildContext context, Widget? child) =>
                RepereDemonstration(child: child),
          ),
        ),
      ),
    );
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final ProviderContainer conteneur = ProviderScope.containerOf(
      tester.element(find.byType(RewayahApp)),
    );
    final PortCartesClasse port = conteneur.read(portCartesClasseProvider);
    expect(port, isA<PortCartesClasseDemo>());
    final CartesClasseVM lu = await conteneur.read(
      cartesClasseProvider(_classe).future,
    );
    expect(lu.cartes.map((CarteClasse c) => c.titre).toList(), _titresDemo());
    // Capacite fausse : aucun retrait ni ajout simule (CARTES-BR-02).
    expect(lu.peutModifier, isFalse);
    Object? refus;
    try {
      await port.retirer(_classe, lu.cartes.first.id);
    } on StateError catch (e) {
      refus = e;
    }
    expect(refus, isA<StateError>());
    // Laisse passer l'alerte de demonstration programmee (ALERTE-1).
    await tester.pump(dureeArriveeAlerteDemo + const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('demonstration direction : le bloc des cartes les montre, sans '
      'ajout ni feuille', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...surchargesDemoAdmin(environnement: 'staging'),
          serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: BlocCartesClasse(groupeId: _classe),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.classe.cartes.indisponibleTitre), findsNothing);
    final Finder cartes = find.byType(VueCarteClasse);
    expect(
      tester
          .widgetList<VueCarteClasse>(cartes)
          .map((VueCarteClasse v) => v.carte.titre)
          .toList(),
      _titresDemo(),
    );
    for (final VueCarteClasse v in tester.widgetList<VueCarteClasse>(cartes)) {
      expect(v.onModifier, isNull, reason: v.carte.titre);
    }
    expect(find.byKey(BlocCartesClasse.ajouterKey), findsNothing);
    await tester.tap(cartes.first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(FeuilleCarteClasse), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
