import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_range.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_outils/annotation_layer.dart';
import 'package:rewayah_academy/core/tc_outils/etat_outils.dart';
import 'package:rewayah_academy/core/tc_outils/evenements_outils.dart';
import 'package:rewayah_academy/core/tc_outils/libelles_tc_outils.dart';
import 'package:rewayah_academy/core/tc_outils/port_annotations.dart';
import 'package:rewayah_academy/core/tc_outils/port_assignations.dart';
import 'package:rewayah_academy/core/tc_outils/port_dock_hote.dart';
import 'package:rewayah_academy/core/tc_outils/ports_externes/port_realtime_pedagogique.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/features/tc_dock/bouton_outil.dart';
import 'package:rewayah_academy/features/tc_dock/teaching_dock.dart';

import 'faux/faux_dock_hote.dart';
import 'support/hote_d.dart';

void main() {
  late FauxDockHote faux;
  late AnnotationsMemoire annotations;
  late AssignationsMemoire assignations;
  late PositionDockMemoire position;
  late List<EvenementOutil> emis;

  ContentRange plageTest() => ContentRange(
    resourceId: ressourceTest,
    debut: ayah1,
    fin: ayah2,
  );

  /// Le bouton qui porte ce libelle.
  ///
  /// Passer par le type plutot que par `find.bySemanticsLabel` : ce dernier
  /// exige un handle de semantique ouvert, et le test dedie ci-dessous s'en
  /// charge une fois pour toutes.
  Finder boutonNomme(String libelle) => find.byWidgetPredicate(
    (Widget widget) => widget is BoutonOutil && widget.libelle == libelle,
  );

  setUp(() {
    faux = FauxDockHote(
      support: supportTest(),
      selection: SelectionSupport(
        plage: plageTest(),
        ancrageSemantique: ayah1,
        ancrageSpatial: pageCourante,
      ),
    );
    annotations = AnnotationsMemoire('prof-1');
    assignations = AssignationsMemoire('prof-1');
    position = PositionDockMemoire();
    emis = <EvenementOutil>[];
  });

  tearDown(() async => annotations.liberer());

  List<Override> surcharges() => <Override>[
    portAnnotationsProvider.overrideWithValue(annotations),
    portAssignationsProvider.overrideWithValue(assignations),
    portPositionDockProvider.overrideWithValue(position),
  ];

  Widget dock() =>
      TeachingDock(hote: faux, onEvenement: emis.add);

  group('ce que le dock propose', () {
    testWidgets('les sept outils quand tout est permis', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));

      for (final OutilDock outil in OutilDock.values) {
        expect(
          boutonNomme(LibellesOutils.outil(outil)),
          findsOneWidget,
          reason: 'outil manquant : ${LibellesOutils.outil(outil)}',
        );
      }
    });

    testWidgets('un observateur silencieux n a aucun outil', (
      WidgetTester tester,
    ) async {
      faux.capacitesRendues = const CapacitesPedagogiques(
        peutPiloterSupport: false,
        peutAnnoter: false,
        peutEmettreNudge: false,
        estObservateurSilencieux: true,
      );
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));

      expect(find.byType(BoutonOutil), findsNothing);
    });

    testWidgets('sans selection, seuls les outils sans objet restent', (
      WidgetTester tester,
    ) async {
      faux.selection = null;
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));

      expect(boutonNomme(LibellesOutils.outilBibliotheque), findsOneWidget);
      expect(boutonNomme(LibellesOutils.outilFocus), findsNothing);
      expect(boutonNomme(LibellesOutils.outilMarquer), findsNothing);
      // Le stylet, lui, n'a pas besoin d'une selection : on ecrit la ou on
      // pose la pointe.
      expect(boutonNomme(LibellesOutils.outilStylet), findsOneWidget);
    });

    testWidgets('un support non annotable ne propose ni stylet ni marqueur', (
      WidgetTester tester,
    ) async {
      faux.support = supportTest(
        capacites: const <CapaciteRessource>{
          CapaciteRessource.focusable,
          CapaciteRessource.selectable,
        },
      );
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));

      expect(boutonNomme(LibellesOutils.outilStylet), findsNothing);
      expect(boutonNomme(LibellesOutils.outilMarquer), findsNothing);
      expect(boutonNomme(LibellesOutils.outilFocus), findsOneWidget);
    });

    testWidgets('sans groupe, aucune revision ne peut etre posee', (
      WidgetTester tester,
    ) async {
      faux.contexteRendu = const ContexteDock(
        sessionId: 'seance-1',
        profilId: 'prof-1',
      );
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));

      expect(boutonNomme(LibellesOutils.outilRevision), findsNothing);
    });
  });

  group('ce que le dock fait', () {
    testWidgets('la Bibliotheque est ouverte par l hote, jamais par le dock', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));
      await tester.tap(boutonNomme(LibellesOutils.outilBibliotheque));
      await tester.pump();

      expect(faux.ouverturesBibliotheque, 1);
    });

    testWidgets('le focus se pose, s annonce, puis se quitte', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(TeachingDock)),
      );

      await tester.tap(boutonNomme(LibellesOutils.outilFocus));
      await tester.pump();

      expect(conteneur.read(etatOutilsProvider).focus, plageTest());
      expect(conteneur.read(etatOutilsProvider).chromeReduit, isTrue);
      expect(emis.single, isA<EvenementFocus>());
      expect((emis.single as EvenementFocus).plage, plageTest());

      await tester.tap(boutonNomme(LibellesOutils.outilFocus));
      await tester.pump();

      expect(conteneur.read(etatOutilsProvider).focus, isNull);
      expect((emis.last as EvenementFocus).plage, isNull);
    });

    testWidgets('masquer puis reveler la meme plage', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(TeachingDock)),
      );

      await tester.tap(boutonNomme(LibellesOutils.outilMasquer));
      await tester.pump();
      expect(conteneur.read(etatOutilsProvider).masquage.estMasque(ayah1), isTrue);

      await tester.tap(boutonNomme(LibellesOutils.outilMasquer));
      await tester.pump();
      expect(
        conteneur.read(etatOutilsProvider).masquage.estMasque(ayah1),
        isFalse,
      );
      expect(
        conteneur.read(etatOutilsProvider).masquage.plages,
        isNotEmpty,
        reason: 'reveler n efface pas le masquage',
      );
      expect(emis.whereType<EvenementMasquage>().length, 2);
    });

    testWidgets('marquer pose un marqueur portant l intention choisie', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));

      await tester.tap(boutonNomme(LibellesOutils.outilMarquer));
      await tester.pumpAndSettle();
      expect(find.text(LibellesOutils.marquerTitre), findsOneWidget);

      await tester.tap(find.text(LibellesOutils.intentionARenforcer));
      await tester.pumpAndSettle();

      final AnnotationLayer couche = annotations.couches.single;
      expect(couche.marqueurs.single.intention.valeurSql, 'reinforce');
      expect(couche.marqueurs.single.plage, plageTest());
      expect(couche.traits, isEmpty);
      expect(emis.single, isA<EvenementMarqueur>());
    });

    testWidgets('la revision cree un travail a preparer et laisse annuler', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));

      await tester.tap(boutonNomme(LibellesOutils.outilRevision));
      await tester.pumpAndSettle();
      await tester.tap(find.text(LibellesOutils.intentionAApprendre));
      await tester.pumpAndSettle();

      expect((await assignations.pourGroupe('groupe-1')).single.purpose.valeurSql, 'learn');
      expect(find.text(LibellesOutils.revisionPosee), findsOneWidget);

      await tester.tap(find.text(LibellesOutils.traitAnnuler));
      await tester.pumpAndSettle();
      expect(
        (await assignations.pourGroupe('groupe-1')).single.status.valeurSql,
        'annule',
      );
    });

    testWidgets('le stylet ouvre sa barre courte, et pas une palette', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));

      expect(boutonNomme(LibellesOutils.traitGomme), findsNothing);

      await tester.tap(boutonNomme(LibellesOutils.outilStylet));
      await tester.pump();

      // Cinq boutons, pas un de plus : stylet, surligner, gomme, annuler, plus.
      for (final String libelle in <String>[
        LibellesOutils.traitSurligneur,
        LibellesOutils.traitGomme,
        LibellesOutils.traitAnnuler,
        LibellesOutils.traitPlus,
      ]) {
        expect(boutonNomme(libelle), findsOneWidget);
      }
      // « Stylet » nomme deux boutons : celui du dock qui arme l'outil, et
      // celui de la barre qui choisit l'encre. Le mot est le bon des deux
      // cotes, et la barre n'existe que si le premier est arme.
      expect(boutonNomme(LibellesOutils.traitStylet), findsNWidgets(2));
    });
  });

  group('ou le dock se pose', () {
    testWidgets('la position se deplace et se memorise', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(TeachingDock)),
      );

      expect(conteneur.read(etatOutilsProvider).position, PositionDock.bas);

      await tester.tap(boutonNomme(LibellesOutils.dockDeplacer));
      await tester.pump();

      expect(conteneur.read(etatOutilsProvider).position, PositionDock.droite);
      expect(
        position.lire(),
        PositionDock.droite,
        reason: 'la position est memorisee localement (spec 8)',
      );
    });

    testWidgets('une position deja memorisee est reprise a l ouverture', (
      WidgetTester tester,
    ) async {
      position.ecrire(PositionDock.gauche);
      await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));
      final ProviderContainer conteneur = ProviderScope.containerOf(
        tester.element(find.byType(TeachingDock)),
      );

      expect(conteneur.read(etatOutilsProvider).position, PositionDock.gauche);
    });

    testWidgets('le dock ne couvre jamais le contenu actif', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        hoteD(
          HoteDuDock(
            contenu: const SizedBox.expand(key: ValueKey<String>('contenu')),
            dock: dock(),
          ),
          surcharges: surcharges(),
        ),
      );
      // Deux images : la premiere rend le dock, la seconde applique la marge
      // relevee sur sa taille reelle.
      await tester.pump();
      await tester.pump();

      final Rect contenu = tester.getRect(
        find.byKey(const ValueKey<String>('contenu')),
      );
      final Rect dockRendu = tester.getRect(find.byType(TeachingDock));

      expect(dockRendu.height, greaterThan(0));
      expect(contenu.overlaps(dockRendu), isFalse);
      expect(contenu.bottom, lessThanOrEqualTo(dockRendu.top));
    });

    testWidgets('a gauche, la marge passe du cote du debut de lecture', (
      WidgetTester tester,
    ) async {
      position.ecrire(PositionDock.gauche);
      await tester.pumpWidget(
        hoteD(
          HoteDuDock(
            contenu: const SizedBox.expand(key: ValueKey<String>('contenu')),
            dock: dock(),
          ),
          surcharges: surcharges(),
        ),
      );
      await tester.pump();
      await tester.pump();

      final Rect contenu = tester.getRect(
        find.byKey(const ValueKey<String>('contenu')),
      );
      final Rect dockRendu = tester.getRect(find.byType(TeachingDock));

      expect(contenu.overlaps(dockRendu), isFalse);
      expect(contenu.left, greaterThanOrEqualTo(dockRendu.right));
    });

    testWidgets('la rotation ne laisse ni debordement ni recouvrement', (
      WidgetTester tester,
    ) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        hoteD(
          HoteDuDock(
            contenu: const SizedBox.expand(key: ValueKey<String>('contenu')),
            dock: dock(),
          ),
          surcharges: surcharges(),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Paysage.
      tester.view.physicalSize = const Size(800, 400);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      final Rect contenu = tester.getRect(
        find.byKey(const ValueKey<String>('contenu')),
      );
      final Rect dockRendu = tester.getRect(find.byType(TeachingDock));
      expect(contenu.overlaps(dockRendu), isFalse);
    });
  });

  testWidgets('chaque outil porte un nom pour les technologies d assistance', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();

    await tester.pumpWidget(hoteD(dock(), surcharges: surcharges()));

    for (final OutilDock outil in OutilDock.values) {
      expect(
        find.bySemanticsLabel(LibellesOutils.outil(outil)),
        findsOneWidget,
        reason: 'une icone sans nom ne dit rien a un lecteur d ecran',
      );
    }
    expect(
      find.bySemanticsLabel(LibellesOutils.dockDeplacer),
      findsOneWidget,
    );

    // Libere avant la fin du test : le framework verifie qu'aucun handle ne
    // survit, et un `addTearDown` passerait apres cette verification.
    semantique.dispose();
  });

  testWidgets('en Interface guidee, les cibles restent grandes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hoteD(
        dock(),
        surcharges: surcharges(),
        mode: InterfaceMode.enfant,
      ),
    );

    for (final Element bouton
        in find.byType(BoutonOutil).evaluate().toList()) {
      final Size taille = bouton.size!;
      expect(
        taille.width,
        greaterThanOrEqualTo(AppTouchTarget.enfant),
        reason: 'cible tactile de l Interface guidee',
      );
      expect(taille.height, greaterThanOrEqualTo(AppTouchTarget.enfant));
    }
    expect(tester.takeException(), isNull);
  });
}
