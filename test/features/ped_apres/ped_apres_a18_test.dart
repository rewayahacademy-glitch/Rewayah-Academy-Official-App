// PED-APRES-1, A18 : les trois ecrans a 320, 390, 768 et 1440 de large, texte
// x1 et x2, clair et sombre, LTR et RTL (arabe), au clavier, avec des cibles
// de 48 : rien de coupe, rien qui deborde, un seul bouton plein, le focus
// atteint chaque controle.
//
// Rien n'est mesure avec une donnee de demonstration : le serveur est le
// simulateur du lot.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_partage_pedagogique.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/features/admin_groupes/apercu_familial.dart';
import 'package:rewayah_academy/features/admin_groupes/reglage_partage.dart';
import 'package:rewayah_academy/features/compte/carte_rubriques.dart';
import 'package:rewayah_academy/features/suivi_foyer/bloc_compte_rendu.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../fixtures/ped_apres/faux_partage_pedagogique.dart';
import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../historique/support_historique.dart';

const String _a1 = 'foyer-a-eleve-1';

typedef _Variante = ({
  String nom,
  double largeur,
  double echelle,
  bool sombre,
  bool arabe,
});

final List<_Variante> _variantes = <_Variante>[
  for (final double largeur in <double>[320, 390, 768, 1440])
    for (final double echelle in <double>[1, 2])
      for (final bool sombre in <bool>[false, true])
        (
          nom:
              '$largeur px, texte x${echelle.toInt()}, '
              '${sombre ? 'sombre' : 'clair'}',
          largeur: largeur,
          echelle: echelle,
          sombre: sombre,
          arabe: false,
        ),
  // RTL : les deux largeurs extremes, texte x2.
  for (final double largeur in <double>[320, 1440])
    for (final bool sombre in <bool>[false, true])
      (
        nom: '$largeur px, texte x2, arabe RTL, ${sombre ? 'sombre' : 'clair'}',
        largeur: largeur,
        echelle: 2,
        sombre: sombre,
        arabe: true,
      ),
];

FauxPartagePedagogique _serveur() => FauxPartagePedagogique()
  ..rapports[('s-presente', _a1)] = RapportSim()
  ..rapports[('s1', 'e1')] = RapportSim();

void _langue(WidgetTester tester, {required bool arabe}) {
  LocaleSettings.setLocaleSync(arabe ? AppLocale.ar : AppLocale.fr);
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
}

/// Les cibles de 48 : chaque lien fait au moins 48 de haut, chaque rangee de
/// reglage aussi (la `LigneRubrique` grandit avec le texte, jamais en dessous).
void _verifierCibles(WidgetTester tester) {
  for (final Element e in find.byType(LienFleche).evaluate()) {
    final RenderBox boite = e.renderObject! as RenderBox;
    expect(
      boite.size.height,
      greaterThanOrEqualTo(47.5),
      reason: 'LienFleche de moins de 48 de haut',
    );
  }
  for (final Element e in find.byType(GroupeReglages).evaluate()) {
    final RenderBox boite = e.renderObject! as RenderBox;
    expect(boite.size.height, greaterThanOrEqualTo(47.5));
  }
}

Widget _hote(Widget enfant, _Variante v, List<Override> surcharges) => hote(
  Directionality(
    textDirection: v.arabe ? TextDirection.rtl : TextDirection.ltr,
    child: Builder(
      builder: (BuildContext c) => MediaQuery(
        data: MediaQuery.of(c).copyWith(
          textScaler: TextScaler.linear(v.echelle),
          platformBrightness: v.sombre ? Brightness.dark : Brightness.light,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: enfant,
          ),
        ),
      ),
    ),
  ),
  surcharges: surcharges,
);

List<Override> _s(PortPartagePedagogique port) => <Override>[
  portPartagePedagogiqueProvider.overrideWithValue(port),
  sansPersonneConnectee(),
];

void main() {
  // Les vraies polices : les glyphes carres de la police de test fausseraient
  // la mesure des mots coupes.
  setUpAll(chargerPolicesDuDepot);
  // La bibliotheque arabe se charge une fois, hors du temps simule des tests.
  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.ar);
    LocaleSettings.setLocaleSync(AppLocale.fr);
  });

  group('A18 : TUT-PED-APR-01, detail de seance du tuteur', () {
    for (final _Variante v in _variantes) {
      testWidgets(v.nom, (WidgetTester tester) async {
        _langue(tester, arabe: v.arabe);
        tester.platformDispatcher.textScaleFactorTestValue = v.echelle;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final GoRouter routeur = await monterHistorique(
          tester,
          taille: Size(v.largeur, 1400),
          mode: v.sombre ? ThemeMode.dark : ThemeMode.light,
          autres: <Override>[
            portPartagePedagogiqueProvider.overrideWithValue(_serveur()),
          ],
        );
        routeur.go('${Routes.seancePour('s-presente')}?eleve=$_a1');
        await stabiliser(tester);
        expect(find.byType(CarteCompteRendu), findsOneWidget);
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester, maximum: 0);
        verifierAucunMotCoupe(tester, find.byType(CarteCompteRendu));
        verifierAucuneCarteCollee(
          tester,
          estCarte: (Widget w) => w is SurfaceCarte,
        );
        _verifierCibles(tester);
      });
    }

    testWidgets('chaque etat sans compte rendu tient aussi a 320 x2', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final FauxPartagePedagogique serveur = _serveur();
      final GoRouter routeur = await monterHistorique(
        tester,
        taille: const Size(320, 1600),
        autres: <Override>[
          portPartagePedagogiqueProvider.overrideWithValue(serveur),
        ],
      );
      for (final void Function() poser in <void Function()>[
        () => serveur.classeActive = false,
        () => serveur.rapports[('s-presente', _a1)]!.confirme = false,
        () => serveur.erreurs['compteRenduFamille'] = StateError('x'),
      ]) {
        poser();
        routeur.go('${Routes.seancePour('s-presente')}?eleve=$_a1');
        await stabiliser(tester);
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester, maximum: 0);
        routeur.go(Routes.tuteurSuivi);
        await stabiliser(tester);
      }
    });
  });

  group('A18 : ADM-PED-APR-02, groupe de reglage et exceptions', () {
    for (final _Variante v in _variantes) {
      testWidgets(v.nom, (WidgetTester tester) async {
        _langue(tester, arabe: v.arabe);
        tester.view.physicalSize = Size(v.largeur, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _hote(
            const GroupePartageClasse(classeId: 'c1', nomClasse: 'Classe'),
            v,
            _s(_serveur()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(Switch), findsOneWidget);
        verifierUnSeulBoutonPlein(tester, maximum: 0);
        verifierAucunMotCoupe(tester, find.byType(GroupePartageClasse));
        _verifierCibles(tester);
      });
    }

    for (final _Variante v in _variantes.where(
      (_Variante v) => v.largeur == 320 || v.largeur == 1440,
    )) {
      testWidgets('feuille des exceptions : ${v.nom}', (
        WidgetTester tester,
      ) async {
        _langue(tester, arabe: v.arabe);
        tester.view.physicalSize = Size(v.largeur, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _hote(
            const FeuilleExceptionsPartage(
              classeId: 'c1',
              nomClasse: 'Classe',
              onModifie: _rien,
            ),
            v,
            _s(_serveur()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester, maximum: 0);
        verifierAucunMotCoupe(tester, find.byType(FeuilleExceptionsPartage));
        _verifierCibles(tester);
      });
    }

    testWidgets('clavier : Tab atteint l interrupteur puis le lien des '
        'exceptions, Entree ouvre la feuille', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _hote(
          const GroupePartageClasse(classeId: 'c1', nomClasse: 'Classe'),
          _variantes.first,
          _s(_serveur()),
        ),
      );
      await tester.pumpAndSettle();
      bool dans<T extends Widget>() {
        final BuildContext? c = FocusManager.instance.primaryFocus?.context;
        if (c == null) {
          return false;
        }
        bool trouve = c.widget is T;
        c.visitAncestorElements((Element a) {
          if (a.widget is T) {
            trouve = true;
            return false;
          }
          return true;
        });
        return trouve;
      }

      bool surInterrupteur = false;
      bool surLien = false;
      for (int i = 0; i < 12 && !surLien; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        surInterrupteur = surInterrupteur || dans<Switch>();
        surLien = dans<LienFleche>();
      }
      expect(
        surInterrupteur,
        isTrue,
        reason: 'le focus atteint l interrupteur',
      );
      expect(surLien, isTrue, reason: 'le focus atteint le lien');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(FeuilleExceptionsPartage), findsOneWidget);
    });
  });

  group('A18 : ADM-PED-APR-03, apercu familial', () {
    for (final _Variante v in _variantes) {
      testWidgets(v.nom, (WidgetTester tester) async {
        _langue(tester, arabe: v.arabe);
        tester.view.physicalSize = Size(v.largeur, 3600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final FauxPartagePedagogique serveur = _serveur()
          ..classeActive = false
          ..historique = <ActionPartage>[
            ActionPartage(
              quand: DateTime(2026, 10, 9, 14, 20),
              type: 'publication',
              auteur: 'Direction',
            ),
          ];
        await tester.pumpWidget(
          _hote(
            const FeuilleApercuFamilial(seanceId: 's1', eleveId: 'e1'),
            v,
            _s(serveur),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        verifierUnSeulBoutonPlein(tester);
        verifierAucunMotCoupe(tester, find.byType(FeuilleApercuFamilial));
        verifierAucuneCarteCollee(
          tester,
          estCarte: (Widget w) => w is SurfaceCarte,
        );
        _verifierCibles(tester);
      });
    }
  });
}

void _rien() {}
