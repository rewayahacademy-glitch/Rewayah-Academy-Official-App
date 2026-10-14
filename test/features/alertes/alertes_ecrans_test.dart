// ALERTE-1 : les alertes de la direction a l'ecran. Page des alertes (cinq
// etats), section du Centre de commande (en tete quand une alerte urgente est
// ouverte), temps reel sans recharger, bandeau et cloche sur la vraie coque
// admin. 320 px a texte x2, LTR et RTL, Interface guidee.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/alertes/alerte.dart';
import 'package:rewayah_academy/core/alertes/port_alertes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/grille_bento.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/alertes/alertes_page.dart';
import 'package:rewayah_academy/features/alertes/bandeau_alerte_urgente.dart';
import 'package:rewayah_academy/features/alertes/ligne_alerte.dart';
import 'package:rewayah_academy/features/alertes/section_alertes.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import '../../support/hors_ligne_une_fois.dart';

final DateTime _midi = DateTime(2026, 10, 5, 12);

Alerte _alerte(
  String id,
  GraviteAlerte gravite,
  int minutesAvant, {
  String? titre,
}) => Alerte(
  id: id,
  gravite: gravite,
  titre: titre ?? 'Alerte $id',
  creeeLe: _midi.subtract(Duration(minutes: minutesAvant)),
  destination: Routes.adminOperationsGroupes,
);

/// Un melange ou l'urgente n'est ni la premiere recue ni la plus recente.
List<Alerte> _melange() => <Alerte>[
  _alerte('info', GraviteAlerte.info, 1, titre: 'Programme mis à jour'),
  _alerte(
    'importante',
    GraviteAlerte.important,
    20,
    titre: 'Remplacement à confirmer pour la classe Al-Falaq',
  ),
  _alerte(
    'urgente',
    GraviteAlerte.urgent,
    40,
    titre: 'Classe An-Nour sans enseignant, séance dans 20 minutes',
  ),
];

/// Une source pilotee par le test : chaque `add` est une arrivee en temps
/// reel.
class _PortPilote implements PortAlertes {
  // Flux de test, libere avec le conteneur du test.
  // ignore: close_sinks
  final StreamController<List<Alerte>> flux =
      StreamController<List<Alerte>>.broadcast();
  int abonnements = 0;

  @override
  Stream<List<Alerte>> suivre() {
    abonnements++;
    return flux.stream;
  }
}

/// Une source qui rend une liste, puis eventuellement une erreur.
class _PortFixe implements PortAlertes {
  _PortFixe(this.alertes, {this.erreurEnSuite = false});
  final List<Alerte>? alertes;
  final bool erreurEnSuite;
  int abonnements = 0;

  @override
  Stream<List<Alerte>> suivre() async* {
    abonnements++;
    if (alertes case final List<Alerte> a) {
      yield a;
    }
    if (erreurEnSuite || alertes == null) {
      throw Exception('lecture des alertes en echec');
    }
  }
}

List<Override> _surcharges({
  PortAlertes? port,
  bool horsLigne = false,
  IndicateursAdmin? indicateurs,
}) => <Override>[
  if (port != null) portAlertesProvider.overrideWithValue(port),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  serviceAdminProvider.overrideWithValue(
    FauxServiceAdmin()
      ..indicateursRendus =
          indicateurs ??
          const IndicateursAdmin(
            dossiersEnAttente: 0,
            foyersSansEnseignant: 0,
            rapportsManquants: 0,
            incidents24h: 0,
            comptesEchus: 0,
            demandesEnAttente: 0,
          ),
  ),
  serviceValidationProvider.overrideWithValue(FauxServiceValidation()),
];

Future<void> _monter(
  WidgetTester tester,
  Widget ecran, {
  List<Override> surcharges = const <Override>[],
  double largeur = 390,
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
  InterfaceMode mode = InterfaceMode.standard,
}) async {
  tester.view.physicalSize = Size(largeur, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(mode, Brightness.light),
          builder: (BuildContext c, Widget? app) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: TextScaler.linear(echelle)),
            child: Directionality(textDirection: sens, child: app!),
          ),
          home: ecran,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

double _haut(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('ADM-ALERTES : cinq etats', () {
    testWidgets('chargement : un squelette de lignes', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const AlertesPage(),
        surcharges: _surcharges(port: _PortPilote()),
      );
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(LigneAlerte), findsNothing);
    });

    testWidgets('contenu : l urgente en tete, puis importante, puis info', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const AlertesPage(),
        surcharges: _surcharges(port: _PortFixe(_melange())),
      );
      final List<double> hauts = <double>[
        for (final String id in <String>['urgente', 'importante', 'info'])
          _haut(tester, find.byKey(ValueKey<String>('alerte-$id'))),
      ];
      expect(hauts[0], lessThan(hauts[1]));
      expect(hauts[1], lessThan(hauts[2]));
      // La gravite est ecrite, jamais dite par la seule couleur.
      expect(find.text(t.alertes.gravite.urgent), findsOneWidget);
      expect(find.text(t.alertes.gravite.important), findsOneWidget);
      expect(find.text(t.alertes.gravite.info), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('vide : aucune alerte en cours', (WidgetTester tester) async {
      await _monter(
        tester,
        const AlertesPage(),
        surcharges: _surcharges(port: _PortFixe(const <Alerte>[])),
      );
      expect(find.text(t.alertes.videTitre), findsOneWidget);
    });

    testWidgets('erreur : la phrase et Reessayer, qui relit', (
      WidgetTester tester,
    ) async {
      final _PortFixe port = _PortFixe(null);
      await _monter(
        tester,
        const AlertesPage(),
        surcharges: _surcharges(port: port),
      );
      expect(find.text(t.alertes.erreurTitre), findsOneWidget);
      final Finder reessayer = find.text(t.commun.etats.actions.reessayer);
      expect(reessayer, findsOneWidget);
      final int avant = port.abonnements;
      await tester.tap(reessayer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(port.abonnements, greaterThan(avant));
    });

    testWidgets('production : indisponible, sans Reessayer ni liste vide', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const AlertesPage(), surcharges: _surcharges());
      expect(find.text(t.alertes.indisponibleTitre), findsOneWidget);
      expect(find.text(t.commun.etats.actions.reessayer), findsNothing);
      expect(find.text(t.alertes.videTitre), findsNothing);
    });

    testWidgets('hors ligne sans liste : ce qui manque, bandeau seul signal', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const AlertesPage(),
        surcharges: _surcharges(port: _PortFixe(null), horsLigne: true),
      );
      expect(find.text(t.alertes.sansDonnees), findsOneWidget);
      expectHorsLigneUneFois();
    });

    testWidgets('hors ligne avec une liste lue : elle reste affichee', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const AlertesPage(),
        surcharges: _surcharges(
          port: _PortFixe(_melange(), erreurEnSuite: true),
          horsLigne: true,
        ),
      );
      expect(find.byType(LigneAlerte), findsNWidgets(3));
      expectHorsLigneUneFois();
    });
  });

  group('ADM-01 : la section Alertes', () {
    testWidgets('une alerte urgente passe au-dessus des tuiles', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        TableauDeBordPage(horloge: () => _midi),
        surcharges: _surcharges(port: _PortFixe(_melange())),
      );
      expect(
        _haut(tester, find.byKey(SectionAlertes.cle)),
        lessThan(_haut(tester, find.byType(GrilleBento))),
      );
      // La phrase calme serait fausse : une urgente attend.
      expect(find.text(t.admin.tableau.calme), findsNothing);
    });

    testWidgets('sans alerte urgente, la section suit les tuiles', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        TableauDeBordPage(horloge: () => _midi),
        surcharges: _surcharges(
          port: _PortFixe(<Alerte>[_alerte('info', GraviteAlerte.info, 1)]),
        ),
      );
      expect(
        _haut(tester, find.byKey(SectionAlertes.cle)),
        greaterThan(_haut(tester, find.byType(GrilleBento))),
      );
      // Une information n'empeche pas le calme.
      expect(find.text(t.admin.tableau.calme), findsOneWidget);
    });

    testWidgets('une importante ouverte retire la phrase calme', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        TableauDeBordPage(horloge: () => _midi),
        surcharges: _surcharges(
          port: _PortFixe(<Alerte>[_alerte('m', GraviteAlerte.important, 1)]),
        ),
      );
      expect(find.text(t.admin.tableau.calme), findsNothing);
    });

    testWidgets('toutes les urgentes, trois lignes sinon, puis Voir tout', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        TableauDeBordPage(horloge: () => _midi),
        surcharges: _surcharges(
          port: _PortFixe(<Alerte>[
            for (int i = 0; i < 4; i++)
              _alerte('u$i', GraviteAlerte.urgent, i + 1),
            _alerte('i', GraviteAlerte.info, 0),
          ]),
        ),
      );
      expect(find.byType(LigneAlerte), findsNWidgets(4));
      expect(find.byKey(const ValueKey<String>('alerte-i')), findsNothing);
      expect(find.text(t.alertes.voirTout), findsOneWidget);
    });

    testWidgets('temps reel : une urgente arrive, la section monte sans '
        'recharger', (WidgetTester tester) async {
      final _PortPilote port = _PortPilote();
      await _monter(
        tester,
        TableauDeBordPage(horloge: () => _midi),
        surcharges: _surcharges(port: port),
      );
      port.flux.add(<Alerte>[_alerte('i', GraviteAlerte.info, 1)]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        _haut(tester, find.byKey(SectionAlertes.cle)),
        greaterThan(_haut(tester, find.byType(GrilleBento))),
      );

      port.flux.add(<Alerte>[
        _alerte('i', GraviteAlerte.info, 1),
        _alerte('u', GraviteAlerte.urgent, 0, titre: 'Incident en séance'),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(port.abonnements, 1, reason: 'aucune relecture');
      expect(
        _haut(tester, find.byKey(SectionAlertes.cle)),
        lessThan(_haut(tester, find.byType(GrilleBento))),
      );
      expect(
        _haut(tester, find.byKey(const ValueKey<String>('alerte-u'))),
        lessThan(_haut(tester, find.byKey(const ValueKey<String>('alerte-i')))),
      );
    });
  });

  group('aucun mot coupe a 320 px, texte x2', () {
    for (final TextDirection sens in TextDirection.values) {
      for (final InterfaceMode mode in InterfaceMode.values) {
        testWidgets('page et section, ${sens.name}, ${mode.name}', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            const AlertesPage(),
            surcharges: _surcharges(port: _PortFixe(_melange())),
            largeur: 320,
            echelle: 2,
            sens: sens,
            mode: mode,
          );
          expect(tester.takeException(), isNull);
          expect(find.byType(LigneAlerte), findsNWidgets(3));
          verifierEcranSansMotCoupe(tester);

          await _monter(
            tester,
            TableauDeBordPage(horloge: () => _midi),
            surcharges: _surcharges(port: _PortFixe(_melange())),
            largeur: 320,
            echelle: 2,
            sens: sens,
            mode: mode,
          );
          expect(tester.takeException(), isNull);
          verifierAucunMotCoupe(tester, find.byKey(SectionAlertes.cle));
        });
      }
    }
  });

  group('coque admin : bandeau et cloche (vrai routeur, demonstration)', () {
    Future<GoRouter> monterCoque(
      WidgetTester tester, {
      required bool avecAlertes,
      Size taille = const Size(390, 844),
      double echelle = 1,
      Duration? arrivee,
    }) async {
      tester.view.physicalSize = taille;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      if (echelle != 1) {
        tester.platformDispatcher.textScaleFactorTestValue = echelle;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: surchargesDemoAdmin(
            environnement: 'staging',
            avecAlertes: avecAlertes,
            arriveeAlerte: arrivee,
          ),
          child: TranslationProvider(
            child: RewayahApp(
              builder: (BuildContext context, Widget? child) =>
                  RepereDemonstration(child: child),
            ),
          ),
        ),
      );
      final GoRouter routeur = ProviderScope.containerOf(
        tester.element(find.byType(RewayahApp)),
      ).read(routeurProvider);
      routeur.go(Routes.adminPersonnesDossiers);
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return routeur;
    }

    testWidgets('le bandeau est en tete de la page ouverte, au-dessus du '
        'titre ; la cloche dit l urgente', (WidgetTester tester) async {
      final GoRouter routeur = await monterCoque(tester, avecAlertes: true);
      final Finder bandeau = find.byKey(BandeauAlerteUrgente.cle);
      expect(bandeau, findsOneWidget);
      expect(
        find.textContaining(t.alertes.bandeauUne(titre: '')),
        findsOneWidget,
      );
      expect(
        _haut(tester, bandeau),
        lessThan(_haut(tester, find.text(t.dossiers.titre).first)),
      );
      expect(find.bySemanticsLabel(t.alertes.clocheUneUrgente), findsOneWidget);

      // Le bandeau ouvre la page des alertes, ou il ne se repete pas.
      await tester.tap(bandeau);
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        routeur.routerDelegate.currentConfiguration.uri.path,
        Routes.adminAlertes,
      );
      expect(find.byKey(BandeauAlerteUrgente.cle), findsNothing);
      expect(find.byType(LigneAlerte), findsNWidgets(4));
    });

    testWidgets('sans capacite alertes : ni bandeau ni cloche', (
      WidgetTester tester,
    ) async {
      await monterCoque(tester, avecAlertes: false);
      expect(find.byKey(BandeauAlerteUrgente.cle), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Alertes')), findsNothing);
    });

    testWidgets('une urgente arrive pendant la visite : bandeau et cloche a '
        'jour sans recharger', (WidgetTester tester) async {
      await monterCoque(
        tester,
        avecAlertes: true,
        arrivee: const Duration(seconds: 20),
      );
      expect(find.bySemanticsLabel(t.alertes.clocheUneUrgente), findsOneWidget);
      await tester.pump(const Duration(seconds: 20));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.bySemanticsLabel(t.alertes.clocheUrgentes(nombre: 2)),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          t.alertes.bandeauPlusieurs(nombre: 2, titre: '').trim(),
        ),
        findsOneWidget,
      );
    });

    testWidgets('320x640 : chaque focus au clavier reste visible, bandeau '
        'compris', (WidgetTester tester) async {
      await monterCoque(
        tester,
        avecAlertes: true,
        taille: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      final List<FocusNode> vus = <FocusNode>[];
      bool bandeauVu = false;
      for (int i = 0; i < 60; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        for (int j = 0; j < 4; j++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final FocusNode? n = FocusManager.instance.primaryFocus;
        if (n == null) continue;
        if (vus.contains(n)) break;
        vus.add(n);
        final Rect r = n.rect;
        expect(
          r.center.dy >= 0 && r.center.dy <= 640,
          isTrue,
          reason: 'focus hors vue : $r, $n',
        );
        final BuildContext? c = n.context;
        if (c != null &&
            c.findAncestorWidgetOfExactType<BandeauAlerteUrgente>() != null) {
          bandeauVu = true;
        }
      }
      expect(bandeauVu, isTrue, reason: 'le bandeau se rejoint au clavier');
    });

    testWidgets('bandeau a 320 px, texte x2 : aucun mot coupe', (
      WidgetTester tester,
    ) async {
      await monterCoque(
        tester,
        avecAlertes: true,
        taille: const Size(320, 2000),
        echelle: 2,
      );
      expect(tester.takeException(), isNull);
      verifierAucunMotCoupe(tester, find.byKey(BandeauAlerteUrgente.cle));
    });
  });
}
