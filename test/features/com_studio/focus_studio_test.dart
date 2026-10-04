// COM-STU-3 : Le Studio, Mode focus (COM-W03F, COM-M05 ; spec section 10,
// section 20, section 23, R-COM-09, R-COM-10), sur la vraie `StudioPage`.
//
// R-COM-09 : en Focus, navigation (colonne, rail, barre basse), canaux,
// panneau droit, recherche et actions de coquille disparaissent ; contenu,
// champ et sortie restent. Ce n'est ni une route (l'adresse ne change pas)
// ni le plein ecran du navigateur (aucun appel `SystemChrome`).
// R-COM-10 : a la sortie, canal, position de lecture, brouillon (sans perte
// du texte ecrit en Focus), recherche et panneau sont restaures.
// A 390, 768 et 1440, en arabe, et dans la demonstration.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/espace_travail_adaptatif.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/vue_etat_communication.dart';
import 'package:rewayah_academy/features/com_studio/brouillons_studio.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/focus/bascule_focus.dart';
import 'package:rewayah_academy/features/com_studio/focus/sortie_focus.dart';
import 'package:rewayah_academy/features/com_studio/liste_canaux.dart';
import 'package:rewayah_academy/features/com_studio/panneau_partages.dart';
import 'package:rewayah_academy/features/com_studio/recherche_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';
import 'package:rewayah_academy/features/demo/communications/demo_communications_page.dart';

import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import 'support_focus.dart';
import 'support_studio.dart';

const Size _mobile = Size(390, 844);
const Size _tablette = Size(768, 1024);
const Size _bureau = Size(1440, 900);

final String _adresseC1 = Routes.canalStudioPour('c1');

/// Les appels de plateforme recus (plein ecran du navigateur ou du systeme).
List<String> _ecouterPlateforme(WidgetTester tester) {
  final List<String> appels = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall appel) async {
      appels.add(appel.method);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return appels;
}

/// Le texte de la ligne de canal [nom] dans la liste.
Finder _dansListe(Finder f) =>
    find.descendant(of: find.byType(ListeCanaux), matching: f);

void main() {
  group('R-COM-09 : ce qui disparait, ce qui reste', () {
    testWidgets('1440 : navigation, canaux, panneau, recherche et actions de '
        'coquille disparaissent ; fil, champ, sortie et indicateur restent ; '
        'ni route ni plein ecran', (WidgetTester tester) async {
      final List<String> appels = _ecouterPlateforme(tester);
      final GoRouter routeur = await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _bureau,
      );
      // Avant : la vraie disposition du canal (COM-W03).
      expect(find.byKey(NavShell.barreLateraleKey), findsOneWidget);
      expect(find.byType(ListeCanaux), findsOneWidget);
      expect(find.byType(ChampRechercheStudio), findsOneWidget);
      expect(find.byType(PanneauPartages), findsOneWidget);
      expect(find.byKey(EnteteCanal.cleLegende), findsOneWidget);
      expect(entrerFocus, findsOneWidget);
      expect(find.byKey(BandeauSortieFocus.cle), findsNothing);
      // L'aide de la spec (section 22) est l'infobulle de « Mode focus ».
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is Tooltip && w.message == t.com.studio.focus.aide,
        ),
        findsOneWidget,
      );

      appels.clear();
      await entrer(tester);

      // Disparu (section 10.3).
      expect(find.byKey(NavShell.barreLateraleKey), findsNothing);
      expect(find.byKey(NavShell.railKey), findsNothing);
      expect(find.byKey(NavShell.barreBasseKey), findsNothing);
      expect(find.byType(ListeCanaux), findsNothing);
      expect(find.byType(ChampRechercheStudio), findsNothing);
      expect(find.byType(PanneauPartages), findsNothing);
      expect(find.byKey(EspaceTravailAdaptatif.cleContexte), findsNothing);
      expect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
        findsNothing,
      );
      expect(find.byKey(EnteteCanal.cleLegende), findsNothing);
      expect(entrerFocus, findsNothing);
      // Le titre de la page et ses actions de coquille (cloche) aussi.
      final PageShell page = tester.widget<PageShell>(find.byType(PageShell));
      expect(page.titre, isNull);
      expect(page.onRetour, isNull);
      expect(page.actionsCoquille, isFalse);

      // Reste (section 10.4) : identite, canal, fil, champ, sortie, etat.
      final Finder bandeau = find.byKey(BandeauSortieFocus.cle);
      expect(bandeau, findsOneWidget);
      expect(
        find.descendant(of: bandeau, matching: find.text('Le Studio')),
        findsOneWidget,
      );
      expect(find.text('Focus activé. Échap pour quitter.'), findsOneWidget);
      expect(quitterFocus, findsOneWidget);
      expect(find.text('Quitter le focus'), findsOneWidget);
      expect(find.byType(EnteteCanal), findsOneWidget);
      expect(find.text('Coordination'), findsOneWidget);
      expect(find.byKey(FilDiscussion.champKey), findsOneWidget);
      expect(find.byKey(FilDiscussion.envoyerKey), findsOneWidget);
      expect(find.textContaining('Message 29'), findsOneWidget);

      // Contenu centre a la largeur de lecture (section 23).
      final Rect fil = tester.getRect(find.byType(FilDiscussion));
      expect(fil.width, AppPage.largeurLecture);
      expect(fil.center.dx, closeTo(_bureau.width / 2, 1));

      // Un etat, pas une destination ; pas de plein ecran du navigateur.
      expect(adresseCourante(routeur), _adresseC1);
      expect(
        appels.where(
          (String m) =>
              m == 'SystemChrome.setEnabledSystemUIMode' ||
              m == 'SystemChrome.setEnabledSystemUIOverlays',
        ),
        isEmpty,
      );
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('768 : le rail et la liste disparaissent, le contexte en '
        'feuille aussi', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _tablette,
      );
      expect(find.byKey(NavShell.railKey), findsOneWidget);
      expect(find.byType(ListeCanaux), findsOneWidget);
      expect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
        findsOneWidget,
      );

      await entrer(tester);

      expect(find.byKey(NavShell.railKey), findsNothing);
      expect(find.byType(ListeCanaux), findsNothing);
      expect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
        findsNothing,
      );
      expect(find.byKey(BandeauSortieFocus.cle), findsOneWidget);
      expect(find.byKey(FilDiscussion.champKey), findsOneWidget);
      expect(find.text('Focus activé. Échap pour quitter.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : la navigation secondaire (retour, titre), le panneau '
        'et la recherche disparaissent ; le champ et la sortie restent', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _mobile,
      );
      // Dans un canal ouvert, la barre basse est deja effacee (tache
      // focalisee) ; le disque retour et le titre sont la.
      expect(find.byKey(NavShell.barreBasseKey), findsNothing);
      expect(find.text('Le Studio'), findsOneWidget);
      expect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
        findsOneWidget,
      );

      await entrer(tester);

      expect(find.byKey(NavShell.barreBasseKey), findsNothing);
      expect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
        findsNothing,
      );
      expect(find.byKey(EspaceStudio.cleOuvrirRecherche), findsNothing);
      final PageShell page = tester.widget<PageShell>(find.byType(PageShell));
      expect(page.titre, isNull);
      expect(page.onRetour, isNull);
      // Sur telephone, l'indicateur ne parle pas d'Echap.
      expect(find.text('Focus activé'), findsOneWidget);
      expect(quitterFocus, findsOneWidget);
      expect(find.byKey(FilDiscussion.champKey), findsOneWidget);
      expect(find.byKey(EnteteCanal.cleLegende), findsNothing);
      expect(tester.takeException(), isNull);
    });

    for (final Size taille in <Size>[_mobile, _tablette, _bureau]) {
      for (final Brightness lum in Brightness.values) {
        testWidgets('aucun debordement en Focus a ${taille.width.toInt()}, '
            '${lum.name}, texte x2', (WidgetTester tester) async {
          await monterStudio(
            tester,
            port: portFocus(),
            depart: _adresseC1,
            taille: taille,
            luminosite: lum,
            echelleTexte: 2,
          );
          await entrer(tester);
          expect(find.byKey(BandeauSortieFocus.cle), findsOneWidget);
          expect(quitterFocus, findsOneWidget);
          expect(find.byKey(FilDiscussion.champKey), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('390, texte x2 : « Quitter le focus » reste a l ecran '
        'apres defilement du fil, de la page et ouverture du champ', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _mobile,
        echelleTexte: 2,
      );
      await entrer(tester);
      final Rect vue = Offset.zero & _mobile;

      void sortieVisible(String apres) {
        final Rect r = tester.getRect(quitterFocus);
        expect(
          r.top >= vue.top &&
              r.left >= vue.left &&
              r.bottom <= vue.bottom &&
              r.right <= vue.right,
          isTrue,
          reason: 'apres $apres : $r hors de $vue',
        );
        expect(quitterFocus.hitTestable(), findsOneWidget, reason: apres);
      }

      sortieVisible('l entree');
      // Le fil defile, dans les deux sens.
      await tester.drag(find.byType(FilDiscussion), const Offset(0, 600));
      await tester.pumpAndSettle();
      sortieVisible('le defilement du fil');
      // Un geste sur le bandeau lui-meme ne l emporte pas.
      await tester.drag(
        find.byKey(BandeauSortieFocus.cle),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      sortieVisible('un geste sur le bandeau');
      // Un geste sur le haut de la page, au-dessus du bandeau.
      await tester.dragFrom(const Offset(195, 4), const Offset(0, -400));
      await tester.pumpAndSettle();
      sortieVisible('un geste sur le haut de la page');
      // Le champ prend le focus (et se rend visible).
      await tester.showKeyboard(find.byKey(FilDiscussion.champKey));
      await tester.pumpAndSettle();
      sortieVisible('l ouverture du champ');
      await tester.drag(find.byType(FilDiscussion), const Offset(0, -600));
      await tester.pumpAndSettle();
      sortieVisible('un second defilement');
      expect(tester.takeException(), isNull);
    });

    testWidgets('hors ligne : le bandeau de la connexion reste en Focus '
        '(erreur reseau critique, section 10.4)', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _bureau,
        horsLigne: true,
      );
      expect(find.byType(BandeauHorsLigneCommunication), findsOneWidget);
      await entrer(tester);
      expect(find.byType(BandeauHorsLigneCommunication), findsOneWidget);
      expect(find.byKey(BandeauSortieFocus.cle), findsOneWidget);
    });

    testWidgets('un canal en lecture seule garde sa phrase en Focus, sans '
        'champ invente', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portFocus(ecrire: false),
        depart: _adresseC1,
        taille: _bureau,
      );
      await entrer(tester);
      expect(find.byKey(CanalStudio.cleLectureSeule), findsOneWidget);
      expect(find.byKey(FilDiscussion.champKey), findsNothing);
      expect(quitterFocus, findsOneWidget);
      await quitter(tester);
      expect(find.byType(ListeCanaux), findsOneWidget);
      expect(find.byKey(CanalStudio.cleLectureSeule), findsOneWidget);
    });

    testWidgets('arabe, 1440 : le bandeau se lit en miroir, la sortie au '
        'bout de la ligne', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _bureau,
        langue: AppLocale.ar,
      );
      await entrer(tester);
      final Finder bandeau = find.byKey(BandeauSortieFocus.cle);
      expect(Directionality.of(tester.element(bandeau)), TextDirection.rtl);
      expect(find.text('الخروج من التركيز'), findsOneWidget);
      expect(find.text('التركيز مفعّل. اضغط Esc للخروج.'), findsOneWidget);
      // En arabe, le debut est a droite : l'identite a droite, la sortie a
      // gauche.
      final Rect identite = tester.getRect(
        find.descendant(of: bandeau, matching: find.text(t.com.studio.titre)),
      );
      final Rect sortie = tester.getRect(quitterFocus);
      expect(sortie.center.dx, lessThan(identite.center.dx));
      expect(find.byType(ListeCanaux), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('R-COM-10 : la sortie restaure', () {
    testWidgets('1440 : canal, position de lecture, brouillon (texte ecrit en '
        'Focus compris) et panneau ouvert reviennent, sans perte', (
      WidgetTester tester,
    ) async {
      final BrouillonsMemoire brouillons = BrouillonsMemoire();
      final GoRouter routeur = await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _bureau,
        brouillons: brouillons,
      );
      // Une lecture au milieu du fil, proche du bas sans y etre : la
      // largeur de lecture du Focus raccourcit le fil et la rogne.
      final ScrollPosition avant = positionFil(tester);
      final double lu = avant.maxScrollExtent - 40;
      avant.jumpTo(lu);
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Je relis');
      champFil(tester).selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();
      expect(find.byType(PanneauPartages), findsOneWidget);

      await entrer(tester);
      // En Focus, la largeur change : la position en pixels ne vaut plus.
      expect(positionFil(tester).pixels, isNot(lu));
      // Le texte du champ est le meme, et on continue d'ecrire.
      expect(champFil(tester).text, 'Je relis');
      await tester.enterText(
        find.byKey(FilDiscussion.champKey),
        'Je relis le planning en Focus',
      );
      await tester.pump();

      await quitter(tester);

      // Canal : toujours le meme, selectionne dans la liste.
      expect(adresseCourante(routeur), _adresseC1);
      expect(find.byType(ListeCanaux), findsOneWidget);
      expect(
        tester.widget<ListeCanaux>(find.byType(ListeCanaux)).canalSelectionne,
        'c1',
      );
      expect(find.byKey(NavShell.barreLateraleKey), findsOneWidget);
      // Position de lecture : exactement la meme.
      expect(positionFil(tester).pixels, lu);
      // Brouillon : le texte ecrit en Focus, jamais l'ancien.
      expect(champFil(tester).text, 'Je relis le planning en Focus');
      final Brouillon? garde = await brouillons.lire(cleBrouillonCanal('c1'));
      expect(garde?.texte, 'Je relis le planning en Focus');
      // Panneau : ouvert, comme avant.
      expect(find.byType(PanneauPartages), findsOneWidget);
      expect(find.byKey(BandeauSortieFocus.cle), findsNothing);
      expect(entrerFocus, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 : un panneau ferme reste ferme, une lecture au bas du '
        'fil y revient', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _bureau,
      );
      await tester.tap(find.byKey(EspaceTravailAdaptatif.cleFermerContexte));
      await tester.pumpAndSettle();
      expect(find.byType(PanneauPartages), findsNothing);
      final ScrollPosition p = positionFil(tester);
      expect(p.pixels, p.maxScrollExtent);

      await entrer(tester);
      await quitter(tester);

      expect(find.byType(PanneauPartages), findsNothing);
      expect(
        find.byKey(EspaceTravailAdaptatif.cleOuvrirContexte),
        findsOneWidget,
      );
      final ScrollPosition apres = positionFil(tester);
      expect(apres.pixels, apres.maxScrollExtent);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440 : un message envoye en Focus reste, avec son etat, et '
        'le champ vide reste vide', (WidgetTester tester) async {
      final FauxStudio port = portFocus();
      await monterStudio(
        tester,
        port: port,
        depart: _adresseC1,
        taille: _bureau,
      );
      await entrer(tester);
      await tester.enterText(
        find.byKey(FilDiscussion.champKey),
        'Envoye pendant le Focus',
      );
      await tester.pump();
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(port.envois.single.$2, 'Envoye pendant le Focus');

      await quitter(tester);

      expect(find.text('Envoye pendant le Focus'), findsOneWidget);
      expect(find.text('Envoyé'), findsOneWidget);
      expect(champFil(tester).text, isEmpty);
    });

    testWidgets('390 : le retour du telephone quitte le Focus, pas la page ; '
        'le texte et le canal restent', (WidgetTester tester) async {
      final GoRouter routeur = await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _mobile,
      );
      await tester.enterText(find.byKey(FilDiscussion.champKey), 'Brouillon');
      await tester.pump();
      await entrer(tester);
      expect(find.byKey(BandeauSortieFocus.cle), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(BandeauSortieFocus.cle), findsNothing);
      expect(adresseCourante(routeur), _adresseC1);
      expect(find.byType(CanalStudio), findsOneWidget);
      expect(champFil(tester).text, 'Brouillon');
      expect(entrerFocus, findsOneWidget);
    });

    testWidgets('1440 : une recherche en cours est masquee en Focus (le fil '
        'reprend sa place), puis rendue telle quelle', (
      WidgetTester tester,
    ) async {
      await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _bureau,
      );
      await tester.enterText(find.byKey(ChampRechercheStudio.cle), 'planning');
      await tester.pumpAndSettle();
      expect(find.byKey(ResultatsRechercheStudio.cle), findsOneWidget);
      // Les resultats couvrent le canal : « Mode focus » n'est pas a portee
      // de main. L'etat du Focus peut toutefois etre demande (un raccourci a
      // venir, la demonstration) : la recherche ne doit pas couvrir le fil.
      expect(entrerFocus.hitTestable(), findsNothing);
      PorteeFocusStudio.de(tester.element(find.byType(EspaceStudio)))!.entrer();
      await tester.pumpAndSettle();

      expect(find.byKey(ResultatsRechercheStudio.cle), findsNothing);
      expect(find.byType(ChampRechercheStudio), findsNothing);
      expect(find.byKey(FilDiscussion.champKey).hitTestable(), findsOneWidget);

      await quitter(tester);

      expect(find.byType(ChampRechercheStudio), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(ChampRechercheStudio.cle))
            .controller!
            .text,
        'planning',
      );
      expect(find.byKey(ResultatsRechercheStudio.cle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ouvrir un autre canal met fin au Focus sans rien restaurer '
        'de l ancien', (WidgetTester tester) async {
      final GoRouter routeur = await monterStudio(
        tester,
        port: portFocus(),
        depart: _adresseC1,
        taille: _bureau,
      );
      await entrer(tester);
      routeur.go(Routes.canalStudioPour('c2'));
      await tester.pumpAndSettle();
      expect(find.byKey(BandeauSortieFocus.cle), findsNothing);
      expect(find.byType(ListeCanaux), findsOneWidget);
      expect(_dansListe(find.text('Planning')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('La demonstration', () {
    testWidgets('la situation « Un canal en mode focus » ouvre Organisation '
        'en Focus ; la sortie rend le Studio', (WidgetTester tester) async {
      tester.view.physicalSize = _bureau;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final GoRouter routeur = GoRouter(
        initialLocation: adresseDemoStudio(
          situation: SituationDemoStudio.focus,
        ),
        routes: <RouteBase>[...routesDemoCommunications('staging')],
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(BandeauSortieFocus.cle), findsOneWidget);
      expect(find.text('Organisation générale'), findsOneWidget);
      expect(find.byType(ListeCanaux), findsNothing);
      expect(find.byKey(FilDiscussion.champKey), findsOneWidget);

      await quitter(tester);

      expect(find.byType(ListeCanaux), findsOneWidget);
      expect(find.byType(PanneauPartages), findsOneWidget);
      expect(entrerFocus, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('la situation du Focus a son libelle', () {
      expect(
        libelleSituationDemoStudio(SituationDemoStudio.focus),
        'Un canal en mode focus',
      );
    });
  });
}
