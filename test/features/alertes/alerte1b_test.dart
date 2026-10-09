// ALERTE-1b : les reserves de ALERTE-1.
//
// (1) `SignalRow` (composant partage) rend sa phrase par `TexteSansCoupure`
//     chez TOUS ses appelants : la liste des appelants est relevee dans
//     `lib/` et doit etre exactement celle que ce fichier mesure.
// (2) Le bandeau d'alerte urgente en RTL et en Interface guidee.
// (3) Le bandeau reste fige en haut de l'ecran pendant que la page defile,
//     sans recouvrir la page (il la pousse) : geometrie en defilant, sur la
//     vraie coque admin (demonstration), mobile et bureau, LTR et RTL,
//     320 px a texte x2.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/accessibilite/mode_accessibilite.dart';
import 'package:rewayah_academy/core/accessibilite/texte_sans_coupure.dart';
import 'package:rewayah_academy/core/alertes/alerte.dart';
import 'package:rewayah_academy/core/alertes/port_alertes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/signal_row.dart';
import 'package:rewayah_academy/features/_dev/galerie/catalogue_galerie.dart';
import 'package:rewayah_academy/features/alertes/bandeau_alerte_urgente.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';

/// Les fichiers de `lib/` qui construisent un `SignalRow`, et que ce fichier
/// mesure. Un appelant ajoute sans mesure fait echouer le releve.
const Set<String> _appelantsMesures = <String>{
  'lib/features/alertes/bandeau_alerte_urgente.dart',
  'lib/features/_dev/galerie/catalogue_galerie.dart',
};

/// Une source qui rend une liste fixe.
class _PortFixe implements PortAlertes {
  _PortFixe(this.alertes);
  final List<Alerte> alertes;

  @override
  Stream<List<Alerte>> suivre() => Stream<List<Alerte>>.value(alertes);
}

/// Monte [enfant] seul, a [largeur], texte a [echelle], dans le sens [sens].
Future<void> _monterSeul(
  WidgetTester tester,
  Widget enfant, {
  required TextDirection sens,
  double largeur = 320,
  double echelle = 2,
  InterfaceMode mode = InterfaceMode.standard,
  PortAlertes? port,
}) async {
  tester.view.physicalSize = Size(largeur, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        if (port != null) portAlertesProvider.overrideWithValue(port),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(mode, Brightness.light),
          builder: (BuildContext c, Widget? app) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: Directionality(textDirection: sens, child: app!),
          ),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: <Widget>[enfant]),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// La phrase d'un `SignalRow` est rendue par `TexteSansCoupure`, et aucun
/// mot n'y est coupe.
void _verifierPhrase(WidgetTester tester) {
  final Finder ligne = find.byType(SignalRow);
  expect(ligne, findsOneWidget);
  final SignalRow rendu = tester.widget<SignalRow>(ligne);
  final Finder texte = find.descendant(
    of: ligne,
    matching: find.byWidgetPredicate(
      (Widget w) => w is TexteSansCoupure && w.texte == rendu.phrase,
    ),
  );
  expect(
    texte,
    findsOneWidget,
    reason: 'La phrase de SignalRow passe par TexteSansCoupure',
  );
  verifierAucunMotCoupe(tester, ligne);
}

class _Cas {
  const _Cas(
    this.nom,
    this.taille, {
    this.sens = TextDirection.ltr,
    this.echelle = 1,
    this.guidee = false,
    this.route = Routes.adminPersonnesDossiers,
  });
  final String nom;
  final String route;
  final Size taille;
  final TextDirection sens;
  final double echelle;
  final bool guidee;
}

Future<GoRouter> _monterCoque(WidgetTester tester, _Cas cas) async {
  tester.view.physicalSize = cas.taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (cas.echelle != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = cas.echelle;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging', avecAlertes: true),
        if (cas.guidee)
          modeAccessibiliteActifProvider.overrideWith((Ref _) => true),
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) => Directionality(
            textDirection: cas.sens,
            child: RepereDemonstration(child: child),
          ),
        ),
      ),
    ),
  );
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(cas.route);
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return routeur;
}

/// Le defilement vertical le plus haut de la page ouverte (sous
/// `PageShell`) qui a quelque chose a defiler : celui de la page entiere
/// quand la tete defile avec elle, sinon celui du corps.
ScrollableState _defilementPage(WidgetTester tester) {
  final List<ScrollableState> candidats = tester
      .stateList<ScrollableState>(
        find.descendant(
          of: find.byType(PageShell),
          matching: find.byType(Scrollable),
        ),
      )
      .where(
        (ScrollableState s) =>
            s.position.axis == Axis.vertical &&
            s.position.hasContentDimensions &&
            s.position.maxScrollExtent > 0,
      )
      .toList();
  expect(
    candidats,
    isNotEmpty,
    reason: 'la page doit defiler pour que la mesure ait un sens',
  );
  double haut(ScrollableState s) => tester.getRect(find.byWidget(s.widget)).top;
  candidats.sort(
    (ScrollableState a, ScrollableState b) => haut(a).compareTo(haut(b)),
  );
  return candidats.first;
}

void main() {
  group('(1) SignalRow : TexteSansCoupure chez tous ses appelants', () {
    setUpAll(chargerPolicesDuDepot);

    test('les appelants releves dans lib/ sont ceux que ce fichier mesure', () {
      final Set<String> appelants = <String>{
        for (final FileSystemEntity f in Directory(
          'lib',
        ).listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              !f.path.endsWith('signal_row.dart') &&
              RegExp(r'\bSignalRow\(').hasMatch(f.readAsStringSync()))
            f.path.replaceAll(r'\', '/'),
      };
      expect(appelants, _appelantsMesures);
    });

    for (final TextDirection sens in TextDirection.values) {
      final List<EtatGalerie> etats = catalogueGalerie()
          .firstWhere((EntreeGalerie e) => e.nom == 'SignalRow')
          .etats;
      for (final EtatGalerie etat in etats) {
        testWidgets('galerie « ${etat.nom} », 320 px x2, ${sens.name}', (
          WidgetTester tester,
        ) async {
          await _monterSeul(
            tester,
            Builder(builder: etat.construire),
            sens: sens,
          );
          expect(tester.takeException(), isNull);
          _verifierPhrase(tester);
        });
      }

      for (final InterfaceMode mode in InterfaceMode.values) {
        testWidgets('bandeau d alerte urgente, 320 px x2, ${sens.name}, '
            '${mode.name}', (WidgetTester tester) async {
          await _monterSeul(
            tester,
            BandeauAlerteUrgente(onOuvrir: () {}),
            sens: sens,
            mode: mode,
            port: _PortFixe(<Alerte>[
              Alerte(
                id: 'u',
                gravite: GraviteAlerte.urgent,
                titre: 'Remplacement introuvable pour la classe An-Nour',
                creeeLe: DateTime.now().subtract(const Duration(minutes: 5)),
              ),
            ]),
          );
          expect(tester.takeException(), isNull);
          _verifierPhrase(tester);
        });
      }
    }
  });

  group('(2, 3) le bandeau reste en haut de l ecran pendant que la page '
      'defile, sans la recouvrir', () {
    setUpAll(chargerPolicesDuDepot);
    for (final _Cas cas in const <_Cas>[
      _Cas('390x700 LTR', Size(390, 700)),
      _Cas('390x700 RTL', Size(390, 700), sens: TextDirection.rtl),
      _Cas('390x700 Interface guidee', Size(390, 700), guidee: true),
      _Cas(
        '390x700 page defilante (regles)',
        Size(390, 700),
        route: Routes.adminConfigurationRegles,
      ),
      // La tete d'Interface guidee du Journal est haute : sans la regle de
      // `PageShell` (la tete defile tant qu'un bandeau est pose), elle
      // deborde de 164 sous le bandeau fige.
      _Cas(
        '390x844 Interface guidee, Journal',
        Size(390, 844),
        guidee: true,
        route: Routes.adminSecuriteAuditJournal,
      ),
      _Cas(
        '1440x600 Journal LTR',
        Size(1440, 600),
        route: Routes.adminSecuriteAuditJournal,
      ),
      _Cas(
        '1440x500 page defilante (regles)',
        Size(1440, 500),
        route: Routes.adminConfigurationRegles,
      ),
      _Cas(
        '1440x500 page defilante (regles) RTL',
        Size(1440, 500),
        sens: TextDirection.rtl,
        route: Routes.adminConfigurationRegles,
      ),
      _Cas('320x640 texte x2 LTR', Size(320, 640), echelle: 2),
      _Cas(
        '320x640 texte x2 RTL',
        Size(320, 640),
        echelle: 2,
        sens: TextDirection.rtl,
      ),
    ]) {
      testWidgets(cas.nom, (WidgetTester tester) async {
        final GoRouter routeur = await _monterCoque(tester, cas);
        expect(tester.takeException(), isNull);
        final Finder bandeau = find.byKey(BandeauAlerteUrgente.cle);
        expect(bandeau, findsOneWidget);
        final Rect avant = tester.getRect(bandeau);
        final double hauteurVue = cas.taille.height;
        expect(avant.top, greaterThanOrEqualTo(0));
        expect(avant.bottom, lessThanOrEqualTo(hauteurVue));
        // Jamais plus de la moitie de la vue (WCAG 1.4.10) : sur une vue
        // basse (moins de 480 de haut a texte normal), la forme courte.
        expect(avant.height, lessThanOrEqualTo(hauteurVue / 2));
        final bool court =
            hauteurVue / cas.echelle < BandeauAlerteUrgente.hauteurLisible;
        expect(
          find.descendant(
            of: bandeau,
            matching: court
                ? find.text(t.alertes.bandeauCourtUne)
                : find.textContaining(t.alertes.bandeauUne(titre: '')),
          ),
          findsOneWidget,
        );

        // Le sens d'ecriture : en RTL l'icone est a droite, le chevron a
        // gauche.
        final Finder icones = find.descendant(
          of: bandeau,
          matching: find.byType(Icon),
        );
        final double xIcone = tester.getCenter(icones.first).dx;
        final double xChevron = tester.getCenter(icones.last).dx;
        if (cas.sens == TextDirection.rtl) {
          expect(xIcone, greaterThan(xChevron));
        } else {
          expect(xIcone, lessThan(xChevron));
        }

        // Le bandeau pousse la page : la zone qui defile commence sous lui.
        final ScrollableState page = _defilementPage(tester);
        final Rect zone = tester.getRect(find.byWidget(page.widget));
        expect(zone.top, greaterThanOrEqualTo(avant.bottom - 0.5));
        expect(
          page.position.maxScrollExtent,
          greaterThan(0),
          reason: 'la page doit defiler pour que la mesure ait un sens',
        );

        // On defile jusqu'en bas.
        page.position.jumpTo(page.position.maxScrollExtent);
        await tester.pump();
        expect(tester.takeException(), isNull);

        final Rect apres = tester.getRect(bandeau);
        expect(apres, avant, reason: 'le bandeau ne bouge pas en defilant');
        expect(
          tester.getRect(find.byWidget(page.widget)).top,
          greaterThanOrEqualTo(apres.bottom - 0.5),
          reason: 'la page ne passe jamais sous le bandeau',
        );
        if (cas.echelle == 2) {
          verifierEcranSansMotCoupe(tester);
        }

        // Toujours actif apres defilement : il ouvre la page des alertes.
        await tester.tapAt(apres.center);
        for (int i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          routeur.routerDelegate.currentConfiguration.uri.path,
          Routes.adminAlertes,
        );
        expect(find.byKey(BandeauAlerteUrgente.cle), findsNothing);
      });
    }
  });

  group('barre mobile avec la cloche : aucun mot coupe dans la recherche', () {
    setUpAll(chargerPolicesDuDepot);

    Future<void> verifier(
      WidgetTester tester,
      _Cas cas, {
      required bool champEnLigne,
    }) async {
      // Un nouvel arbre : les surcharges changent d'un montage a l'autre.
      await tester.pumpWidget(const SizedBox.shrink());
      await _monterCoque(tester, cas);
      expect(tester.takeException(), isNull);
      expect(
        find.byType(TextField),
        champEnLigne ? findsOneWidget : findsNothing,
      );
      expect(
        find.bySemanticsLabel(
          champEnLigne
              ? t.nav.admin.rechercheIndication
              : t.nav.admin.recherche,
        ),
        findsWidgets,
        reason: 'la recherche reste atteignable',
      );
      verifierAucunMotCoupe(tester, find.byType(Scaffold).first);
    }

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('390x844 Interface guidee, ${sens.name} : le bouton ; '
          'en standard, le champ reste', (WidgetTester tester) async {
        await verifier(
          tester,
          _Cas('', const Size(390, 844), guidee: true, sens: sens),
          champEnLigne: false,
        );
        await verifier(
          tester,
          _Cas('', const Size(390, 844), sens: sens),
          champEnLigne: true,
        );
      });
    }

    testWidgets('320x640 standard : le bouton', (WidgetTester tester) async {
      await verifier(
        tester,
        const _Cas('', Size(320, 640)),
        champEnLigne: false,
      );
    });
  });
}
