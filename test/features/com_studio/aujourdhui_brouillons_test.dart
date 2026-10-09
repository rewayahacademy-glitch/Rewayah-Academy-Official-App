// COM-STU-2 : les brouillons du Studio (`DraftPersistence`, spec section 8.2,
// section 25 « brouillon restaure ») : le texte d'un canal survit a la
// navigation locale (memoire de session, `BrouillonsMemoire` du socle), se
// retrouve dans Aujourd'hui et dans la vue Brouillons, rouvre son canal, et
// s'efface a l'envoi. Un canal qui n'est plus ouvert n'est pas nomme
// (R-COM-08).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/com_studio/aujourdhui_page.dart';
import 'package:rewayah_academy/features/com_studio/brouillons_studio.dart';
import 'package:rewayah_academy/features/com_studio/canal_page.dart';
import 'package:rewayah_academy/features/com_studio/port_studio.dart';
import 'package:rewayah_academy/features/com_studio/studio_page.dart';
import 'package:rewayah_academy/features/demo/communications/com_studio_demo.dart';

import 'support_studio.dart';

Finder _dansBrouillons(Finder cible) => find.descendant(
  of: find.byKey(TableauAujourdhui.cleBrouillons),
  matching: cible,
);

String _champ(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byType(FilDiscussion),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

void main() {
  for (final Size taille in <Size>[
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('${taille.width.toInt()} : le texte d un canal survit a la '
        'navigation, se retrouve dans Aujourd hui, rouvre le canal '
        '(« Brouillon restaure »), puis s efface a l envoi', (
      WidgetTester tester,
    ) async {
      final BrouillonsMemoire memoire = BrouillonsMemoire();
      final FauxStudio port = FauxStudio(
        canaux: <Canal>[canalSimple(id: 'c1', nom: 'Coordination')],
      );
      final GoRouter routeur = await monterStudio(
        tester,
        port: port,
        depart: Routes.canalStudioPour('c1'),
        brouillons: memoire,
        activite: ActiviteStudioDemo(
          situation: SituationDemoStudio.aujourdhuiVide,
        ),
        taille: taille,
      );
      expect(find.byKey(CanalStudio.cleBrouillonRestaure), findsNothing);
      await tester.enterText(
        find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.byType(EditableText),
        ),
        'Je prepare le planning de la semaine',
      );
      await tester.pump();
      expect(
        (await memoire.lire(cleBrouillonCanal('c1')))?.texte,
        'Je prepare le planning de la semaine',
      );

      // Navigation locale : le canal se ferme, Aujourd'hui s'ouvre.
      routeur.go(Routes.adminStudio);
      await tester.pumpAndSettle();
      expect(find.byType(TableauAujourdhui), findsOneWidget);
      final String libelle = t.com.studio.brouillons.dansCanal(
        nom: 'Coordination',
      );
      expect(_dansBrouillons(find.text(libelle)), findsOneWidget);
      expect(
        _dansBrouillons(
          find.textContaining('Je prepare le planning de la semaine'),
        ),
        findsOneWidget,
      );

      // Le brouillon rouvre son canal, texte remis.
      await tester.ensureVisible(_dansBrouillons(find.text(libelle)));
      await tester.pumpAndSettle();
      await tester.tap(_dansBrouillons(find.text(libelle)));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.canalStudioPour('c1'));
      expect(_champ(tester), 'Je prepare le planning de la semaine');
      expect(find.byKey(CanalStudio.cleBrouillonRestaure), findsOneWidget);
      expect(find.text(t.com.studio.brouillons.restaure), findsOneWidget);

      // Reprendre le texte : la phrase s'efface, le brouillon suit.
      await tester.enterText(
        find.descendant(
          of: find.byType(FilDiscussion),
          matching: find.byType(EditableText),
        ),
        'Je prepare le planning de la semaine prochaine',
      );
      await tester.pump();
      expect(find.byKey(CanalStudio.cleBrouillonRestaure), findsNothing);
      expect(
        (await memoire.lire(cleBrouillonCanal('c1')))?.texte,
        'Je prepare le planning de la semaine prochaine',
      );

      // L'envoi vide le champ : le brouillon est efface.
      await tester.tap(find.byKey(FilDiscussion.envoyerKey));
      await tester.pumpAndSettle();
      expect(
        port.envois.single.$2,
        'Je prepare le planning de la semaine prochaine',
      );
      expect(await memoire.lire(cleBrouillonCanal('c1')), isNull);
      routeur.go(Routes.adminStudio);
      await tester.pumpAndSettle();
      expect(
        _dansBrouillons(find.text(t.com.studio.brouillons.vide)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('changer de canal ne melange jamais deux brouillons', (
    WidgetTester tester,
  ) async {
    final BrouillonsMemoire memoire = BrouillonsMemoire();
    final GoRouter routeur = await monterStudio(
      tester,
      port: FauxStudio(
        canaux: <Canal>[
          canalSimple(id: 'c1', nom: 'Coordination'),
          canalSimple(id: 'c2', nom: 'Pedagogie'),
        ],
      ),
      depart: Routes.canalStudioPour('c1'),
      brouillons: memoire,
    );
    final Finder champ = find.descendant(
      of: find.byType(FilDiscussion),
      matching: find.byType(EditableText),
    );
    await tester.enterText(champ, 'Texte du premier canal');
    await tester.pump();
    routeur.go(Routes.canalStudioPour('c2'));
    await tester.pumpAndSettle();
    expect(_champ(tester), isEmpty);
    expect(find.byKey(CanalStudio.cleBrouillonRestaure), findsNothing);
    await tester.enterText(champ, 'Texte du second canal');
    await tester.pump();
    routeur.go(Routes.canalStudioPour('c1'));
    await tester.pumpAndSettle();
    expect(_champ(tester), 'Texte du premier canal');
    expect(
      (await memoire.lire(cleBrouillonCanal('c2')))?.texte,
      'Texte du second canal',
    );
  });

  testWidgets('un canal en lecture seule n a pas de champ : rien n est garde', (
    WidgetTester tester,
  ) async {
    final BrouillonsMemoire memoire = BrouillonsMemoire();
    await monterStudio(
      tester,
      port: FauxStudio(canaux: <Canal>[canalSimple(id: 'c1', ecrire: false)]),
      depart: Routes.canalStudioPour('c1'),
      brouillons: memoire,
    );
    expect(find.byKey(CanalStudio.cleLectureSeule), findsOneWidget);
    expect(await memoire.tous(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  group('La vue Brouillons', () {
    testWidgets('la vue de la navigation : tous les brouillons, la phrase '
        'qui dit la memoire de session ; un canal retire n est pas nomme', (
      WidgetTester tester,
    ) async {
      final BrouillonsMemoire memoire = BrouillonsMemoire();
      await memoire.enregistrer(cleBrouillonCanal('c1'), 'Premier texte');
      await memoire.enregistrer(cleBrouillonCanal('retire'), 'Texte perdu');
      // Un brouillon d'un fil de Messages metier vit dans Messages.
      await memoire.enregistrer(
        const CleBrouillon(type: TypeObjetLie.message, objetId: 'fil-1'),
        'Message a une famille',
      );
      final GoRouter routeur = await monterStudio(
        tester,
        port: FauxStudio(canaux: <Canal>[canalSimple(id: 'c1')]),
        depart: adresseVueStudio(VueStudio.brouillons),
        brouillons: memoire,
      );
      expect(find.byType(VueBrouillonsStudio), findsOneWidget);
      expect(
        tester.widget<NavShell>(find.byType(NavShell)).indexActif,
        VueStudio.brouillons.index,
      );
      final x = t.com.studio.brouillons;
      expect(find.text(x.detail), findsOneWidget);
      expect(find.text(x.dansCanal(nom: 'Coordination')), findsOneWidget);
      expect(find.text(x.canalIndisponible), findsOneWidget);
      expect(find.textContaining('Message a une famille'), findsNothing);
      // Le canal retire : ni nom, ni geste.
      expect(
        find
            .ancestor(
              of: find.text(x.canalIndisponible),
              matching: find.byType(Pressable),
            )
            .evaluate(),
        isEmpty,
      );
      await tester.tap(find.text(x.dansCanal(nom: 'Coordination')));
      await tester.pumpAndSettle();
      expect(cheminCourant(routeur), Routes.canalStudioPour('c1'));
      expect(_champ(tester), 'Premier texte');
    });

    testWidgets('vide : la phrase de la vue', (WidgetTester tester) async {
      await monterStudio(
        tester,
        port: FauxStudio(canaux: <Canal>[canalSimple()]),
        depart: adresseVueStudio(VueStudio.brouillons),
      );
      expect(find.text(t.com.studio.brouillons.videTitre), findsOneWidget);
    });

    testWidgets('liste des canaux illisible : le brouillon s ouvre quand '
        'meme, sans nom de canal', (WidgetTester tester) async {
      final BrouillonsMemoire memoire = BrouillonsMemoire();
      await memoire.enregistrer(cleBrouillonCanal('c1'), 'Premier texte');
      await monterStudio(
        tester,
        port: FauxStudio(erreurListe: Exception('reseau')),
        depart: adresseVueStudio(VueStudio.brouillons),
        brouillons: memoire,
      );
      expect(find.text(t.com.studio.brouillons.canalInconnu), findsOneWidget);
    });

    testWidgets("Aujourd'hui en montre trois, puis « Voir tous les "
        'brouillons »', (WidgetTester tester) async {
      final BrouillonsMemoire memoire = BrouillonsMemoire();
      final List<Canal> canaux = <Canal>[
        for (int i = 0; i < 5; i++) canalSimple(id: 'c$i', nom: 'Canal $i'),
      ];
      for (int i = 0; i < 5; i++) {
        await memoire.enregistrer(cleBrouillonCanal('c$i'), 'Texte $i');
      }
      final GoRouter routeur = await monterStudio(
        tester,
        port: FauxStudio(canaux: canaux),
        depart: Routes.adminStudio,
        brouillons: memoire,
        activite: ActiviteStudioDemo(
          situation: SituationDemoStudio.aujourdhuiVide,
        ),
      );
      expect(
        _dansBrouillons(find.textContaining('Brouillon dans Canal')),
        findsNWidgets(3),
      );
      final Finder tous = find.byKey(BlocBrouillons.cleVoirTous);
      expect(
        find.descendant(
          of: tous,
          matching: find.text(t.com.studio.brouillons.tous(nombre: 5)),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(tous);
      await tester.pumpAndSettle();
      await tester.tap(tous);
      await tester.pumpAndSettle();
      expect(adresseCourante(routeur), adresseVueStudio(VueStudio.brouillons));
      expect(
        find.descendant(
          of: find.byKey(VueBrouillonsStudio.cleListe),
          matching: find.textContaining('Brouillon dans Canal'),
        ),
        findsNWidgets(5),
      );
    });

    testWidgets('390 et arabe : la vue Brouillons se lit en miroir', (
      WidgetTester tester,
    ) async {
      final BrouillonsMemoire memoire = BrouillonsMemoire();
      await memoire.enregistrer(cleBrouillonCanal('c1'), 'نص المسودة');
      await monterStudio(
        tester,
        port: FauxStudio(
          canaux: <Canal>[canalSimple(id: 'c1', nom: 'التنسيق')],
        ),
        depart: adresseVueStudio(VueStudio.brouillons),
        brouillons: memoire,
        taille: const Size(390, 844),
        langue: AppLocale.ar,
        echelleTexte: 2,
      );
      expect(
        find.text(t.com.studio.brouillons.dansCanal(nom: 'التنسيق')),
        findsOneWidget,
      );
      expect(
        Directionality.of(tester.element(find.byType(VueBrouillonsStudio))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Le rendu des brouillons', () {
    test('resolution : connu, inconnu, indisponible ; les canaux seulement, '
        'le plus recent d abord', () {
      final DateTime t0 = maintenantTest;
      Brouillon b(
        String id,
        int minutes, {
        TypeObjetLie type = TypeObjetLie.canal,
      }) => Brouillon(
        cle: CleBrouillon(type: type, objetId: id),
        texte: id,
        modifieLe: t0.add(Duration(minutes: minutes)),
      );
      final List<Brouillon> tous = <Brouillon>[
        b('c1', 1),
        b('absent', 3),
        b('fil', 5, type: TypeObjetLie.message),
      ];
      final List<BrouillonStudio> r = resoudreBrouillonsStudio(
        tous,
        <ResumeCanal>[canalSimple(id: 'c1').resume],
        cheminCanalStudio,
      );
      expect(r.map((BrouillonStudio x) => x.brouillon.cle.objetId), <String>[
        'absent',
        'c1',
      ]);
      expect(r[0].canal, CanalDuBrouillon.indisponible);
      expect(r[0].destination, isNull);
      expect(r[1].canal, CanalDuBrouillon.connu);
      expect(r[1].destination?.chemin, Routes.canalStudioPour('c1'));
      final List<BrouillonStudio> sansListe = resoudreBrouillonsStudio(
        tous,
        null,
        cheminCanalStudio,
      );
      expect(
        sansListe.every(
          (BrouillonStudio x) => x.canal == CanalDuBrouillon.inconnu,
        ),
        isTrue,
      );
      // Un canal absent rendu par erreur dans la liste n'est pas « connu ».
      final List<BrouillonStudio> absent = resoudreBrouillonsStudio(
        <Brouillon>[b('secret', 1)],
        <ResumeCanal>[
          canalSimple(id: 'secret', visibilite: VisibiliteCanal.absent).resume,
        ],
        cheminCanalStudio,
      );
      expect(absent.single.canal, CanalDuBrouillon.indisponible);
    });

    test('extrait : une ligne, coupee proprement', () {
      expect(extraitBrouillon('  un\n  texte  '), 'un texte');
      final String long = 'mot ' * 40;
      final String e = extraitBrouillon(long);
      expect(e.length, lessThanOrEqualTo(81));
      expect(e.endsWith('…'), isTrue);
    });
  });

  group('La demonstration', () {
    testWidgets('le brouillon de la demonstration est dans Aujourd hui', (
      WidgetTester tester,
    ) async {
      final BrouillonsMemoire memoire = brouillonsStudioDemo(
        SituationDemoStudio.normale,
      );
      expect((await memoire.tous()).single.texte, texteBrouillonDemo);
      expect(
        await brouillonsStudioDemo(SituationDemoStudio.aujourdhuiVide).tous(),
        isEmpty,
      );
    });
  });
}
