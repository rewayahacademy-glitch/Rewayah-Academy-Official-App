// CAP29-G : le support actif d'une seance.
//
// Ce que le test prouve : la classe suit sans rien faire (aucun bouton
// « Suivre l'enseignant », le changement arrive tout seul) ; les cinq etats
// (attente, aucun support, support, retire en seance, erreur / connexion
// perdue) ; le Coran n'est jamais rendu, seulement un lien ; le « Presenter »
// ne part qu'avec la capacite, jamais au chargement, et reprend la meme cle
// apres une reponse non confirmee ; un conflit ou un refus du serveur est
// rendu a la salle ; 320 px, texte x2, LTR, RTL et theme sombre.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_support_actif.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/demo/support_actif_demo.dart';
import 'package:rewayah_academy/features/tc_catalogue/support_actif/presenter_port.dart';
import 'package:rewayah_academy/features/tc_catalogue/support_actif/support_actif_classe.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../teaching_core/b/faux/faux_ports_b.dart';

const String _seance = 's1';

/// Un port dont le flux echoue d'une panne du serveur (et non du reseau).
class _PortEnPanne extends SupportActifDemo {
  @override
  Stream<SupportActif?> suivre(String seanceId) =>
      Stream<SupportActif?>.error(StateError('serveur'));
}

Widget _hote(
  PortSupportActif? port, {
  Brightness luminosite = Brightness.light,
  TextDirection? direction,
  double echelle = 1,
}) {
  Widget corps = const Scaffold(
    body: SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: SupportActifClasse(seanceId: _seance),
    ),
  );
  if (direction != null) {
    corps = Directionality(textDirection: direction, child: corps);
  }
  return ProviderScope(
    overrides: <Override>[portSupportActifProvider.overrideWithValue(port)],
    child: TranslationProvider(
      child: MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, luminosite),
        builder: (BuildContext context, Widget? child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(echelle)),
          child: child!,
        ),
        home: corps,
      ),
    ),
  );
}

Finder _cle(String k) => find.byKey(ValueKey<String>(k));

void main() {
  final a = t.tc.bibliotheque.actif;

  group('la classe suit sans rien faire', () {
    testWidgets('port absent : dit sans faux contenu', (tester) async {
      await tester.pumpWidget(_hote(null));
      await tester.pumpAndSettle();
      expect(_cle('actif-indisponible'), findsOneWidget);
    });

    testWidgets('aucun support presente', (tester) async {
      final SupportActifDemo port = SupportActifDemo();
      await tester.pumpWidget(_hote(port));
      await tester.pumpAndSettle();
      expect(_cle('actif-aucun'), findsOneWidget);
      expect(find.textContaining('Suivre'), findsNothing);
    });

    testWidgets('le support arrive tout seul, sans geste', (tester) async {
      final SupportActifDemo port = SupportActifDemo();
      await tester.pumpWidget(_hote(port));
      await tester.pumpAndSettle();
      expect(_cle('actif-contenu'), findsNothing);
      await tester.runAsync(
        () => port.activer(
          seanceId: _seance,
          resourceId: 'demo-image',
          revisionAttendue: 0,
          cle: 'k1',
        ),
      );
      await tester.pumpAndSettle();
      expect(_cle('actif-contenu'), findsOneWidget);
      expect(find.text('Tableau des lettres'), findsOneWidget);
      expect(_cle('actif-ouvrir'), findsOneWidget);
      expect(find.textContaining('Suivre'), findsNothing);
    });

    testWidgets('Coran : un lien vers le lecteur, jamais rendu ici', (
      tester,
    ) async {
      final SupportActifDemo port = SupportActifDemo();
      await tester.pumpWidget(_hote(port));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => port.activer(
          seanceId: _seance,
          resourceId: 'demo-coran',
          revisionAttendue: 0,
          cle: 'k1',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(a.ouvrirCoran), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('retire en cours de seance : dit a la classe', (tester) async {
      final SupportActifDemo port = SupportActifDemo();
      await tester.pumpWidget(_hote(port));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await port.activer(
          seanceId: _seance,
          resourceId: 'demo-pdf',
          revisionAttendue: 0,
          cle: 'k1',
        );
        port.retirerEnSeance();
      });
      await tester.pumpAndSettle();
      expect(_cle('actif-retire'), findsOneWidget);
      expect(_cle('actif-ouvrir'), findsNothing);
    });

    testWidgets('connexion perdue : etat sans donnees avec relance', (
      tester,
    ) async {
      final SupportActifDemo port = SupportActifDemo()..panne = true;
      await tester.pumpWidget(_hote(port));
      await tester.pumpAndSettle();
      expect(_cle('actif-sans-donnees'), findsOneWidget);
    });

    testWidgets('panne du serveur : erreur avec relance', (tester) async {
      await tester.pumpWidget(_hote(_PortEnPanne()));
      await tester.pumpAndSettle();
      expect(_cle('actif-erreur'), findsOneWidget);
    });
  });

  group('presenter depuis la bibliotheque de la salle', () {
    PresentationPort presentation(SupportActifDemo port) => PresentationPort(
      port: port,
      seanceId: _seance,
      revision: () => port.actuel?.revision ?? 0,
    );
    final LibraryResource image = ressource(
      id: 'demo-image',
      type: TypeRessource.image,
    );

    test('sans capacite : aucun rappel, jamais un bouton grise', () async {
      final SupportActifDemo port = SupportActifDemo(
        capacitesServeur: const CapacitesSupportActif(),
      );
      expect(await presentation(port).pourSeance(), isNull);
    });

    test('l\'activation ne part qu\'a l\'appel', () async {
      final SupportActifDemo port = SupportActifDemo();
      final PresentationPort p = presentation(port);
      final presenter = (await p.pourSeance())!;
      final VoidCallback activer = await presenter(image, null);
      // Le chargement a reussi, rien n'est encore presente a la classe.
      expect(port.actuel, isNull);
      activer();
      await Future<void>.delayed(Duration.zero);
      expect(port.actuel?.resourceId, 'demo-image');
      expect(p.dernier.value, isA<ActivationFaite>());
    });

    test('renoncer avant l\'appel ne presente rien', () async {
      final SupportActifDemo port = SupportActifDemo();
      final presenter = (await presentation(port).pourSeance())!;
      await presenter(image, null);
      expect(port.actuel, isNull);
    });

    test('capacite retiree entre-temps : le chargement echoue', () async {
      final SupportActifDemo port = SupportActifDemo();
      final presenter = (await presentation(port).pourSeance())!;
      port.capacitesServeur = const CapacitesSupportActif();
      await expectLater(presenter(image, null), throwsStateError);
    });

    test('refus du serveur rendu a la salle', () async {
      final SupportActifDemo port = SupportActifDemo()
        ..refus = RefusActivation.droitsEchus;
      final PresentationPort p = presentation(port);
      (await (await p.pourSeance())!(image, null))();
      await Future<void>.delayed(Duration.zero);
      expect(p.dernier.value, isA<ActivationRefusee>());
      expect(port.actuel, isNull);
    });

    test('conflit de revision rendu a la salle', () async {
      final SupportActifDemo port = SupportActifDemo();
      final PresentationPort p = PresentationPort(
        port: port,
        seanceId: _seance,
        revision: () => 7,
      );
      (await (await p.pourSeance())!(image, null))();
      await Future<void>.delayed(Duration.zero);
      expect(p.dernier.value, isA<ActivationEnConflit>());
    });

    test('non confirme : meme cle reprise, une seule presentation', () async {
      final SupportActifDemo port = SupportActifDemo();
      final PresentationPort p = presentation(port);
      final presenter = (await p.pourSeance())!;
      final VoidCallback activer = await presenter(image, null);
      port.panne = true;
      activer();
      await Future<void>.delayed(Duration.zero);
      expect(p.nonConfirmee.value, isTrue);
      expect(port.actuel, isNull);
      port.panne = false;
      activer();
      await Future<void>.delayed(Duration.zero);
      expect(port.actuel?.resourceId, 'demo-image');
      expect(p.nonConfirmee.value, isFalse);
      // La reprise a presente une seule fois (revision 1).
      expect(port.actuel?.revision, 1);
    });
  });

  group('adaptation', () {
    setUpAll(chargerPolicesDuDepot);
    for (final Brightness l in Brightness.values) {
      for (final TextDirection d in TextDirection.values) {
        testWidgets('320 px, texte x2, ${d.name}, ${l.name}', (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final SupportActifDemo port = SupportActifDemo();
          await tester.pumpWidget(
            _hote(port, luminosite: l, direction: d, echelle: 2),
          );
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => port.activer(
              seanceId: _seance,
              resourceId: 'demo-image',
              revisionAttendue: 0,
              cle: 'k1',
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(_cle('actif-contenu'), findsOneWidget);
          verifierEcranSansMotCoupe(tester);
        });
      }
    }
  });
}
