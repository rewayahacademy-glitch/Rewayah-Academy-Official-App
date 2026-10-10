// COM-RC tour 2, lot D (Studio, Messages admin et socle).
//
// Chaque test echouait avant le lot D ; il passe apres.
//
// - R-05 (regression) et R-09 : a 320 et texte x2, le titre d'une page a
//   retour et actions (« Aujourd'hui » du Studio avec « Mon compte » et la
//   cloche, « Administration des communications » avec le retour et la
//   cloche) ne se coupe plus dans un mot : il passe sous la rangee du retour
//   et des actions ;
// - R-11 (regression) : le nom d'un fichier dans sa carte n'est jamais coupe
//   au milieu (« Devoir_semaine_3.pd / f ») : son milieu s'efface, son
//   extension reste visible, le lecteur d'ecran lit le nom complet ;
// - recette (mineur) : l'etiquette des champs de recherche des Messages et
//   du Studio n'est plus tronquee a 768.
//
// R-02 (premier ecran du canal du Studio et des Messages admin a 320 et
// texte x2) est prouve par `com_rc_lot_a_test.dart`, groupe R-02, qui ne
// fait plus rien defiler avant de verifier.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/communications/port_pieces_jointes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/carte_piece_jointe.dart';
import 'package:rewayah_academy/core/widgets/champ_recherche.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/features/com_messages/recherche_fils.dart'
    show ClesRechercheFils;
import 'package:rewayah_academy/features/com_studio/port_studio.dart'
    show portStudioProvider;
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';

import '../../router/support_routeur.dart';
import '../../support/aucun_mot_coupe.dart';
import '../com_studio/support_studio.dart' as studio;
import 'support_messages.dart';

const Size _petit = Size(320, 640);
const Size _tablette = Size(768, 1024);

/// La vraie application en demonstration admin (aucun serveur), sur
/// [depart].
Future<void> _monterAdmin(
  WidgetTester tester,
  String depart, {
  required Size taille,
  double echelleTexte = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  tester.platformDispatcher.textScaleFactorTestValue = echelleTexte;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        portStudioProvider.overrideWithValue(studio.portDemo()),
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  ProviderScope.containerOf(tester.element(find.byType(RewayahApp)))
      .read(routeurProvider)
      .go(depart);
  await stabiliser(tester);
}

/// Un en-tete de page seul, a [largeur] et texte [echelle].
Future<void> _monterEntete(
  WidgetTester tester,
  EntetePage entete, {
  double largeur = 320,
  double echelle = 2,
}) async {
  tester.view.physicalSize = Size(largeur, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
        locale: AppLocale.fr.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(largeur, 800),
            textScaler: TextScaler.linear(echelle),
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: entete,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Une action d'en-tete de la taille d'une cible tactile.
Widget _action() => ClocheNotifications(onPress: () {});

void main() {
  group('R-05 et R-09 : titre de page a 320 et texte x2', () {
    testWidgets('« Aujourd hui » avec retour, compte et cloche : aucun mot '
        'coupe, le titre passe sous la rangee des actions', (
      WidgetTester tester,
    ) async {
      await _monterEntete(
        tester,
        EntetePage(
          titre: t.com.studio.aujourdhui.titre,
          sousTitre: t.com.studio.aujourdhui.sousTitre,
          onRetour: () {},
          actions: <Widget>[_action(), _action()],
        ),
      );
      verifierAucunMotCoupe(tester, find.byType(EntetePage));
      final Rect titre = tester.getRect(
        find.text(t.com.studio.aujourdhui.titre),
      );
      final Rect retour = tester.getRect(find.byType(DisqueRetour));
      expect(titre.top, greaterThanOrEqualTo(retour.bottom));
      expect(tester.takeException(), isNull);
    });

    // La police de test dessine chaque lettre sur un carre : elle est bien
    // plus large que la police du produit. A 320, « Administration » ne tient
    // pas meme seule ; a 360, elle tient sur la largeur entiere, pas a cote
    // du retour et de la cloche.
    testWidgets('« Administration des communications » avec retour et '
        'cloche : aucun mot coupe', (WidgetTester tester) async {
      await _monterEntete(
        tester,
        EntetePage(
          titre: t.com.socle.navigation.provisoire.administrationTitre,
          onRetour: () {},
          actions: <Widget>[_action()],
        ),
        largeur: 360,
      );
      verifierAucunMotCoupe(tester, find.byType(EntetePage));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a 390 et texte x1, un titre court garde sa rangee', (
      WidgetTester tester,
    ) async {
      await _monterEntete(
        tester,
        EntetePage(
          titre: t.com.messages.titre,
          onRetour: () {},
          actions: <Widget>[_action()],
        ),
        largeur: 390,
        echelle: 1,
      );
      final Rect titre = tester.getRect(find.text(t.com.messages.titre));
      final Rect retour = tester.getRect(find.byType(DisqueRetour));
      expect(titre.top, lessThan(retour.bottom));
    });

    testWidgets('Studio, Aujourd hui, vraie route : aucun mot coupe dans '
        'l en-tete', (WidgetTester tester) async {
      await _monterAdmin(
        tester,
        Routes.adminStudio,
        taille: _petit,
        echelleTexte: 2,
      );
      expect(find.byType(CoquilleStudio), findsOneWidget);
      expect(find.byKey(cleCompteStudio), findsOneWidget);
      verifierAucunMotCoupe(tester, find.byType(EntetePage));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Administration des communications, vraie route : aucun mot '
        'coupe dans l en-tete', (WidgetTester tester) async {
      await _monterAdmin(
        tester,
        Routes.adminCommunicationsAnnonces,
        taille: _petit,
        echelleTexte: 2,
      );
      verifierAucunMotCoupe(tester, find.byType(EntetePage));
      expect(tester.takeException(), isNull);
    });
  });

  group('R-11 : le nom de fichier de la carte', () {
    const String nom = 'Devoir_semaine_3.pdf';
    final PieceJointe piece = PieceJointe(
      reference: ReferencePieceJointe('pj-devoir'),
      nom: nom,
      nature: NaturePieceJointe.document,
      typeLisible: 'PDF',
      tailleOctets: 2500000,
    );

    for (final double echelle in <double>[1, 2]) {
      testWidgets('carte etroite, texte x$echelle : nom jamais coupe, '
          'extension visible, nom complet lu', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(320, 800),
                  textScaler: TextScaler.linear(echelle),
                ),
                child: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 288,
                      child: CartePieceJointe(piece: piece),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        verifierAucunMotCoupe(tester, find.byType(CartePieceJointe));
        // Le nom ne tient pas : son milieu s'efface, l'extension reste.
        final Finder affiche = find.byWidgetPredicate(
          (Widget w) =>
              w is Text &&
              (w.data ?? '').endsWith('.pdf') &&
              (w.data ?? '').contains('\u2026'),
        );
        expect(affiche, findsOneWidget);
        expect(find.bySemanticsLabel(nom), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('une carte large garde le nom entier', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 1000,
                  child: CartePieceJointe(piece: piece),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(nom), findsOneWidget);
    });
  });

  group('Recette : les champs de recherche a 768', () {
    testWidgets('Messages : l etiquette n est pas tronquee', (
      WidgetTester tester,
    ) async {
      await monterMessages(
        tester,
        port: portDemo(RoleDemoCommunications.tuteur),
        depart: cheminFilTest('fil-adam'),
        taille: _tablette,
      );
      expect(find.byType(ChampRecherche), findsOneWidget);
      verifierAucunMotCoupe(tester, find.byType(ChampRecherche));
      // Sortie du champ, l'etiquette reste son nom pour le lecteur d'ecran.
      final SemanticsHandle semantique = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(ClesRechercheFils.champ)).label,
        contains(t.com.messages.recherche.champ),
      );
      semantique.dispose();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Studio : l etiquette n est pas tronquee', (
      WidgetTester tester,
    ) async {
      await studio.monterStudio(
        tester,
        port: studio.portDemo(),
        depart: Routes.canalStudioPour('organisation'),
        taille: _tablette,
      );
      expect(find.byType(ChampRecherche), findsOneWidget);
      verifierAucunMotCoupe(tester, find.byType(ChampRecherche));
      expect(tester.takeException(), isNull);
    });
  });
}
