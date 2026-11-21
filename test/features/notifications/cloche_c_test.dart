// CLOCHE-C (directeur, 21/11/2026, DECISION-ANNONCES-NOTIFS-2026-11-21) : la
// cloche ouvre un panneau ancre de 400 (840 et plus) ou une feuille du bas ;
// trois onglets avec leur nombre, une ligne par element, detail, fermeture
// avec « Annuler », « Tout marquer comme lu », 20 a la fois, tous les etats.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart'
    show Segment;
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/selecteur_section.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/notifications/cloche/annonces_cloche.dart';
import 'package:rewayah_academy/features/notifications/cloche/contenu_cloche.dart';
import 'package:rewayah_academy/features/notifications/cloche/elements_cloche.dart';
import 'package:rewayah_academy/features/notifications/cloche/ligne_cloche.dart';
import 'package:rewayah_academy/features/notifications/cloche/ouvrir_cloche.dart';

import '../../support/garde_interface.dart';
import 'support_cloche.dart';

Finder _ligne(String cle) => find.byKey(ContenuCloche.cleLigne(cle));

/// Ce que dit chaque onglet (son nom et son nombre), quel que soit son
/// rendu (libelle et pastille, ou icone seule a l'etroit).
List<String> _onglets(WidgetTester tester) => <String>[
  for (final Segment<OngletCloche> s
      in tester
          .widget<SelecteurSection<OngletCloche>>(
            find.byKey(ContenuCloche.cleOnglets),
          )
          .sections)
    s.libelleLu ?? s.libelle,
];

/// Choisit un onglet comme une personne : le segment a sa place (jamais un
/// menu deroulant, CLOCHE-C).
Future<void> _onglet(WidgetTester tester, OngletCloche onglet) async {
  expect(
    find.descendant(
      of: find.byKey(ContenuCloche.cleOnglets),
      matching: find.byType(MenuFiltre<OngletCloche>),
    ),
    findsNothing,
  );
  await tester.tap(
    find
        .descendant(
          of: find.byKey(ContenuCloche.cleOnglets),
          matching: find.byType(Pressable),
        )
        .at(onglet.index),
  );
  await pas(tester);
}

Future<void> _langue(WidgetTester tester, AppLocale langue) async {
  await tester.runAsync(() => LocaleSettings.setLocale(langue));
  addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
}

/// Le titre de l'annonce traduite (toucher le centre de la ligne tomberait
/// sur son bouton « Ouvrir le lien »).
Finder _titreA1() => find
    .descendant(
      of: find.byKey(ContenuCloche.cleLigne('a-a1')),
      matching: find.byType(RichText),
    )
    .first;

void main() {
  group('Panneau d ordinateur', () {
    for (final double largeur in <double>[1280, 1440]) {
      testWidgets('$largeur : panneau de 400 sous la cloche, trois onglets '
          'avec leur nombre, un seul bouton plein', (
        WidgetTester tester,
      ) async {
        await monterCloche(
          tester,
          taille: Size(largeur, 900),
          port: FauxNotifsCloche(notifsDemo()),
          source: FausseSourceAnnonces(annoncesDemo()),
        );
        // Le point de la cloche compte les notifications et les annonces non
        // lues : 2 + 1.
        expect(
          tester
              .widget<ClocheNotifications>(find.byType(ClocheNotifications))
              .nonLues,
          3,
        );
        final Rect cloche = tester.getRect(
          find.byType(ClocheNotifications).first,
        );
        await ouvrirLaCloche(tester);
        final Finder panneau = find.byKey(clePanneauCloche);
        expect(panneau, findsOneWidget);
        final Rect rect = tester.getRect(panneau);
        expect(rect.width, largeurPanneauCloche);
        expect(rect.top, greaterThan(cloche.bottom));
        expect(rect.right, closeTo(cloche.right, 1));
        expect(rect.bottom, lessThanOrEqualTo(900));
        final ct = t.notifications.cloche;
        expect(_onglets(tester), <String>[
          ct.avecNombre(libelle: ct.ongletTout, n: 3),
          ct.avecNombre(libelle: ct.ongletAnnonces, n: 1),
          ct.avecNombre(libelle: t.notifications.sectionAFaire, n: 1),
        ]);
        for (final String c in <String>['n-n1', 'n-n2', 'a-a1', 'a-a2']) {
          expect(_ligne(c), findsOneWidget);
        }
        expect(find.byKey(ContenuCloche.cleVoirTout), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
        expect(tester.takeException(), isNull);

        // Echap le ferme.
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await pas(tester);
        expect(panneau, findsNothing);
      });
    }

    testWidgets('arabe 1440 : le panneau suit la cloche, a gauche', (
      WidgetTester tester,
    ) async {
      await _langue(tester, AppLocale.ar);
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: FauxNotifsCloche(notifsDemo(arabe: true)),
        source: FausseSourceAnnonces(annoncesDemo(arabe: true)),
      );
      final Rect cloche = tester.getRect(
        find.byType(ClocheNotifications).first,
      );
      await ouvrirLaCloche(tester);
      final Rect rect = tester.getRect(find.byKey(clePanneauCloche));
      expect(rect.left, closeTo(cloche.left, 1));
      expect(tester.takeException(), isNull);
    });
  });

  group('Feuille du telephone', () {
    testWidgets('390 : la cloche ouvre la feuille, 90 % au plus', (
      WidgetTester tester,
    ) async {
      await monterCloche(
        tester,
        port: FauxNotifsCloche(notifsDemo()),
        source: FausseSourceAnnonces(annoncesDemo()),
      );
      await ouvrirLaCloche(tester);
      expect(find.byType(AppBottomSheet), findsOneWidget);
      expect(find.byKey(clePanneauCloche), findsNothing);
      expect(
        tester.getSize(find.byType(AppBottomSheet)).height,
        lessThanOrEqualTo(844 * 0.9 + 1),
      );
      verifierUnSeulBoutonPlein(tester);
      expect(tester.takeException(), isNull);
    });

    for (final (AppLocale langue, bool sombre) in <(AppLocale, bool)>[
      (AppLocale.fr, false),
      (AppLocale.ar, true),
    ]) {
      testWidgets('320, texte x2, ${langue.languageCode}, '
          '${sombre ? 'sombre' : 'clair'} : rien ne deborde', (
        WidgetTester tester,
      ) async {
        await _langue(tester, langue);
        await monterCloche(
          tester,
          taille: const Size(320, 700),
          echelle: 2,
          theme: sombre ? ThemeMode.dark : ThemeMode.light,
          port: FauxNotifsCloche(notifsDemo(arabe: langue == AppLocale.ar)),
          source: FausseSourceAnnonces(
            annoncesDemo(arabe: langue == AppLocale.ar),
          ),
        );
        await ouvrirLaCloche(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(_titreA1());
        await pas(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Gestes', () {
    testWidgets('toucher une annonce ouvre son detail, la compte vue, montre '
        'l original ; le retour ramene a la liste', (
      WidgetTester tester,
    ) async {
      final FausseSourceAnnonces source = FausseSourceAnnonces(annoncesDemo());
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: FauxNotifsCloche(notifsDemo()),
        source: source,
      );
      await ouvrirLaCloche(tester);
      await tester.tap(_titreA1());
      await pas(tester);
      expect(source.vues, <String>['a1']);
      expect(find.byKey(ContenuCloche.cleRetourListe), findsOneWidget);
      expect(
        find.textContaining('Tout sur les séances', findRichText: true),
        findsWidgets,
      );
      await tester.tap(find.byKey(ContenuCloche.cleOriginal));
      await pas(tester);
      expect(find.text('دليل المعلم متاح في التطبيق'), findsOneWidget);
      expect(find.text(t.notifications.cloche.voirTraduction), findsOneWidget);
      await tester.tap(find.byKey(ContenuCloche.cleRetourListe));
      await pas(tester);
      expect(_ligne('a-a1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la croix ferme l annonce : « Annuler » 5 s, puis la ligne '
        's efface', (WidgetTester tester) async {
      final FausseSourceAnnonces source = FausseSourceAnnonces(annoncesDemo());
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: FauxNotifsCloche(notifsDemo()),
        source: source,
      );
      await ouvrirLaCloche(tester);
      await tester.tap(
        find.byKey(LigneCloche.cleFermer(ContenuCloche.cleLigne('a-a2').value)),
      );
      await pas(tester, fois: 3);
      expect(source.fermees, <String>['a2']);
      expect(find.byKey(ContenuCloche.cleAnnulation('a2')), findsOneWidget);
      // Annuler la rouvre.
      await tester.tap(find.text(t.notifications.cloche.annuler));
      await pas(tester, fois: 3);
      expect(source.rouvertes, <String>['a2']);
      expect(_ligne('a-a2'), findsOneWidget);
      // Fermer de nouveau, puis laisser passer les 5 s.
      await tester.tap(
        find.byKey(LigneCloche.cleFermer(ContenuCloche.cleLigne('a-a2').value)),
      );
      await pas(tester, fois: 60);
      expect(find.byKey(ContenuCloche.cleAnnulation('a2')), findsNothing);
      expect(_ligne('a-a2'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('une fermeture refusee rend la ligne et le dit', (
      WidgetTester tester,
    ) async {
      final FausseSourceAnnonces source = FausseSourceAnnonces(
        annoncesDemo(),
        echecFermeture: true,
      );
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: FauxNotifsCloche(notifsDemo()),
        source: source,
      );
      await ouvrirLaCloche(tester);
      await tester.tap(
        find.byKey(LigneCloche.cleFermer(ContenuCloche.cleLigne('a-a2').value)),
      );
      await pas(tester, fois: 3);
      expect(_ligne('a-a2'), findsOneWidget);
      expect(
        find.text(t.notifications.cloche.fermetureNonConfirmee),
        findsOneWidget,
      );
    });

    testWidgets('sans fermeture servie, aucune croix (jamais un bouton qui ne '
        'peut pas aboutir)', (WidgetTester tester) async {
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: FauxNotifsCloche(notifsDemo()),
        source: FausseSourceAnnonces(annoncesDemo(), fermeture: false),
      );
      await ouvrirLaCloche(tester);
      expect(
        find.byKey(LigneCloche.cleFermer(ContenuCloche.cleLigne('a-a1').value)),
        findsNothing,
      );
    });

    testWidgets('« Tout marquer comme lu » eteint les nombres et dit « Tout '
        'est lu »', (WidgetTester tester) async {
      final FauxNotifsCloche port = FauxNotifsCloche(notifsDemo());
      final FausseSourceAnnonces source = FausseSourceAnnonces(annoncesDemo());
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: port,
        source: source,
      );
      await ouvrirLaCloche(tester);
      await tester.tap(find.byKey(ContenuCloche.cleToutLire));
      await pas(tester);
      expect(port.toutesLues, 1);
      expect(source.vues, contains('a1'));
      expect(find.byKey(ContenuCloche.cleToutLu), findsOneWidget);
      expect(
        tester
            .widget<ClocheNotifications>(find.byType(ClocheNotifications))
            .nonLues,
        0,
      );
    });

    testWidgets('« A faire » : le geste attendu est sur la ligne ; vide, une '
        'phrase', (WidgetTester tester) async {
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: FauxNotifsCloche(notifsDemo()),
        source: FausseSourceAnnonces(annoncesDemo()),
      );
      await ouvrirLaCloche(tester);
      await _onglet(tester, OngletCloche.aFaire);
      expect(_ligne('n-n1'), findsOneWidget);
      expect(_ligne('n-n2'), findsNothing);
      expect(
        find.byKey(LigneCloche.cleAction(ContenuCloche.cleLigne('n-n1').value)),
        findsOneWidget,
      );
    });

    testWidgets('20 a la fois, puis « Voir plus »', (
      WidgetTester tester,
    ) async {
      final List<AnnonceCloche> beaucoup = <AnnonceCloche>[
        for (int i = 0; i < 25; i++)
          AnnonceCloche(
            id: 'x$i',
            titre: 'Annonce $i',
            texte: 'Texte $i',
            publieeLe: instantCloche.subtract(Duration(hours: i + 1)),
            vue: true,
          ),
      ];
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: FauxNotifsCloche(const <NotificationTuteur>[]),
        source: FausseSourceAnnonces(beaucoup),
      );
      await ouvrirLaCloche(tester);
      expect(find.byType(LigneCloche), findsNWidgets(20));
      await tester.ensureVisible(find.byKey(ContenuCloche.cleVoirPlus));
      await tester.tap(find.byKey(ContenuCloche.cleVoirPlus));
      await pas(tester);
      expect(find.byType(LigneCloche), findsNWidgets(25));
      expect(find.byKey(ContenuCloche.cleVoirPlus), findsNothing);
    });
  });

  group('Etats', () {
    testWidgets('chargement : le squelette', (WidgetTester tester) async {
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: FauxNotifsCloche(
          const <NotificationTuteur>[],
          mode: ModeNotifs.attente,
        ),
        source: FausseSourceAnnonces(const <AnnonceCloche>[]),
      );
      await ouvrirLaCloche(tester);
      expect(
        find.descendant(
          of: find.byKey(clePanneauCloche),
          matching: find.byType(Skeleton),
        ),
        findsWidgets,
      );
    });

    testWidgets('echec : la cause et « Reessayer »', (
      WidgetTester tester,
    ) async {
      final FauxNotifsCloche port = FauxNotifsCloche(
        notifsDemo(),
        mode: ModeNotifs.echec,
      );
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: port,
        source: FausseSourceAnnonces(const <AnnonceCloche>[]),
      );
      await ouvrirLaCloche(tester);
      expect(find.text(t.notifications.cloche.erreurTitre), findsOneWidget);
      port.mode = ModeNotifs.donnees;
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      await pas(tester);
      expect(_ligne('n-n1'), findsOneWidget);
    });

    testWidgets('vide : une phrase par onglet', (WidgetTester tester) async {
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        port: FauxNotifsCloche(const <NotificationTuteur>[]),
        source: FausseSourceAnnonces(const <AnnonceCloche>[]),
      );
      await ouvrirLaCloche(tester);
      expect(find.text(t.notifications.cloche.videToutTitre), findsOneWidget);
      await _onglet(tester, OngletCloche.annonces);
      expect(
        find.text(t.notifications.cloche.videAnnoncesTitre),
        findsOneWidget,
      );
    });

    testWidgets('hors ligne avec des donnees : la phrase, la liste reste', (
      WidgetTester tester,
    ) async {
      await monterCloche(
        tester,
        taille: const Size(1440, 900),
        horsLigne: true,
        port: FauxNotifsCloche(notifsDemo()),
        source: FausseSourceAnnonces(annoncesDemo()),
      );
      await ouvrirLaCloche(tester);
      expect(find.text(t.notifications.cloche.horsLigne), findsOneWidget);
      expect(_ligne('n-n1'), findsOneWidget);
    });
  });

  test('texteSansLiens : l adresse quitte le texte affiche', () {
    expect(
      texteSansLiens('Lisez-le ici : https://exemple.org/guide\nRien a faire.'),
      'Lisez-le ici\nRien a faire.',
    );
    expect(
      texteSansLiens('Tout sur les règles. https://exemple.org/guide'),
      'Tout sur les règles.',
    );
    expect(texteSansLiens('Sans lien.'), 'Sans lien.');
  });

  testWidgets('320, texte x2 : des onglets, jamais un menu deroulant', (
    WidgetTester tester,
  ) async {
    await monterCloche(
      tester,
      taille: const Size(320, 700),
      echelle: 2,
      port: FauxNotifsCloche(notifsDemo()),
      source: FausseSourceAnnonces(annoncesDemo()),
    );
    await ouvrirLaCloche(tester);
    expect(
      find.descendant(
        of: find.byKey(ContenuCloche.cleOnglets),
        matching: find.byType(MenuFiltre<OngletCloche>),
      ),
      findsNothing,
    );
    await _onglet(tester, OngletCloche.aFaire);
    expect(_ligne('n-n1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
