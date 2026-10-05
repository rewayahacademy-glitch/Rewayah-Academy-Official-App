// JUR-APP-1 : le lien « En savoir plus » du bandeau de la salle et les textes
// d'information E-1 / E-2 valides par le directeur le 02/10/2026
// (pilotage 14_controleur/juridique/INFO_ELEVES_PARENTS.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/information_controle.dart';
import 'package:rewayah_academy/features/salle_seance/mention_seance.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';

import '../../capture/outil_capture.dart';

VueSeance _vue(RoleSeance role) => VueSeance(
  role: role,
  nomClasse: 'Classe',
  nomEnseignant: 'Sayyid Ibrahim',
  initialesEnseignant: 'SI',
  enregistrementConfirme: true,
);

Future<void> _mention(
  WidgetTester tester,
  RoleSeance role, {
  bool lienAccepte = true,
  String? contact,
}) async {
  await tester.pumpWidget(
    hoteCapture(
      Scaffold(
        body: Center(
          child: MentionSeance(
            vue: _vue(role),
            lienAccepte: lienAccepte,
            contact: contact,
          ),
        ),
      ),
    ),
  );
  await stabiliser(tester);
}

Finder get _lien => find.text(t.salle.informationControle.lien);

void main() {
  group('Les cles des textes valides existent, mot pour mot', () {
    test('E-1 : le texte de l enfant de moins de 13 ans', () {
      final Traductions$salle$informationControle$e1$fr e1 =
          t.salle.informationControle.e1;
      expect(e1.titre, "Quelqu'un veille sur ton cours");
      expect(
        e1.p3,
        'Elle ne parle pas. Elle ne filme pas. Elle ne montre ton cours à '
        'personne.',
      );
      expect(e1.signaler, 'Tu peux aussi appuyer sur Signaler.');
    });

    test('E-2 : le texte de l eleve de 13 a 17 ans, contact en parametre', () {
      final Traductions$salle$informationControle$e2$fr e2 =
          t.salle.informationControle.e2;
      expect(e2.titre, 'Les visites de contrôle');
      expect(
        e2.p4(contact: 'X'),
        endsWith('parle à tes parents ou écris à X.'),
      );
    });

    test('A3, E1 et la clause enseignant', () {
      expect(
        t.contrat.a3.titre,
        'Les cours sont enregistrés (le son seulement)',
      );
      expect(t.contrat.a3.quoi, contains("L'image n'est pas enregistrée."));
      expect(t.contrat.a3.qui, isNot(contains('qui a écouté')));
      expect(
        t.contrat.a3.qui,
        endsWith(
          'Vous pouvez demander si un enregistrement a été écouté, et pourquoi.',
        ),
      );
      expect(
        t.contrat.e1.quoi,
        contains(
          'Elle n\'enregistre rien. Elle envoie ensuite un compte rendu à '
          "l'académie.",
        ),
      );
      expect(
        t.contrat.a3.duree(duree: 30),
        startsWith('30 jours, puis effacé.'),
      );
      expect(t.contrat.clauseControle.titre, 'Visites de contrôle.');
      expect(
        t.contrat.clauseControle.texte,
        endsWith('En signant, vous confirmez l\'avoir reçue.'),
      );
      expect(t.contrat.clauseControle.caseReligion, startsWith("J'accepte"));
    });

    test('le bandeau lui-meme ne change pas (decision du 24/09)', () {
      expect(
        t.salle.bandeauPermanent,
        'Cours enregistré, visite de contrôle possible.',
      );
    });
  });

  group('Le lien « En savoir plus » du bandeau', () {
    testWidgets('interface guidee : le lien ouvre le texte E-1', (
      WidgetTester tester,
    ) async {
      await _mention(tester, RoleSeance.guidee);
      expect(_lien, findsOneWidget);

      await tester.tap(_lien);
      await stabiliser(tester);
      final Traductions$salle$informationControle$e1$fr e1 =
          t.salle.informationControle.e1;
      expect(find.text(e1.titre), findsOneWidget);
      for (final String p in <String>[e1.p1, e1.p2, e1.p3, e1.p4, e1.p5]) {
        expect(find.text(p), findsOneWidget);
      }
      // Le bouton « Signaler » n'existe pas pour l'eleve : sa phrase est cachee.
      expect(find.textContaining(e1.signaler), findsNothing);

      // Rien a accepter : la lecture se ferme d'un geste.
      await tester.tap(find.byType(DisqueRetour).last);
      await stabiliser(tester);
      expect(find.text(e1.titre), findsNothing);
      expect(_lien, findsOneWidget);
    });

    testWidgets('eleve, contact fourni : le lien ouvre le texte E-2', (
      WidgetTester tester,
    ) async {
      await _mention(tester, RoleSeance.eleve, contact: 'contact-test');
      await tester.tap(_lien);
      await stabiliser(tester);
      final Traductions$salle$informationControle$e2$fr e2 =
          t.salle.informationControle.e2;
      expect(find.text(e2.titre), findsOneWidget);
      expect(find.text(e2.p1), findsOneWidget);
      expect(find.text(e2.p4(contact: 'contact-test')), findsOneWidget);
    });

    testWidgets('eleve sans contact fourni : pas de lien (pas de trou)', (
      WidgetTester tester,
    ) async {
      await _mention(tester, RoleSeance.eleve);
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
      expect(_lien, findsNothing);
    });

    testWidgets("l'enseignant n'a pas de lien", (WidgetTester tester) async {
      await _mention(tester, RoleSeance.enseignant, contact: 'contact-test');
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
      expect(_lien, findsNothing);
    });

    testWidgets('refus du directeur : le bandeau redevient seul', (
      WidgetTester tester,
    ) async {
      await _mention(tester, RoleSeance.guidee, lienAccepte: false);
      expect(find.text(t.salle.bandeauPermanent), findsOneWidget);
      expect(_lien, findsNothing);
    });

    test('le reglage par defaut : lien accepte, contact pas encore fourni', () {
      expect(InformationControle.lienAccepte, isTrue);
      expect(InformationControle.contactConfidentialite, isNull);
      expect(InformationControle.boutonSignalerEleve, isFalse);
    });

    testWidgets('dans la vraie salle guidee (390 x 844), le lien est la', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteCapture(
          SalleDemo(
            role: RoleSeance.guidee,
            etat: EtatDemoSalle.repos,
            onSortir: () {},
          ),
        ),
      );
      await stabiliser(tester);
      expect(_lien, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Mise en page : la salle ne bouge pas, la lecture defile', () {
    // Les mesures se font avec les vraies polices du depot : la police de
    // test (Ahem) elargit chaque glyphe et fait passer la mention sur deux
    // lignes.
    setUpAll(chargerPolicesDuDepot);

    Future<void> salle(
      WidgetTester tester,
      Size taille,
      double densite, {
      ThemeMode mode = ThemeMode.light,
      double echelle = 1,
      VoidCallback? onSortir,
    }) async {
      tester.view.physicalSize = taille * densite;
      tester.view.devicePixelRatio = densite;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteCapture(
          SalleDemo(
            role: RoleSeance.guidee,
            etat: EtatDemoSalle.repos,
            onSortir: onSortir ?? () {},
          ),
          themeMode: mode,
          echelleTexte: echelle,
          interfaceMode: InterfaceMode.enfant,
        ),
      );
      await stabiliser(tester);
    }

    double hautCours(WidgetTester tester) =>
        tester.getTopLeft(find.text('Chapitre 1').first).dy;
    Finder mention() => find.text(t.salle.bandeauPermanent);

    // Le haut de la surface du cours SANS le lien (base, mesure du
    // 04/10/2026 sur la branche commune) : 100 au telephone.
    const double hautSansLien = 100;

    testWidgets('390 : le lien suit la mention sur sa ligne, le cours ne '
        'bouge pas', (WidgetTester tester) async {
      await salle(tester, const Size(390, 844), 2);
      expect(tester.takeException(), isNull);
      expect(hautCours(tester), hautSansLien);
      final Rect texte = tester.getRect(mention());
      final Rect lien = tester.getRect(_lien);
      expect(lien.center.dy, closeTo(texte.center.dy, 0.5));
      expect(lien.left, greaterThan(texte.right));
      expect(lien.right, lessThanOrEqualTo(390 - 16));
      // Souligne : reconnaissable comme lien sans couleur ajoutee.
      final Text widget = tester.widget<Text>(_lien);
      expect(widget.style?.decoration, TextDecoration.underline);
    });

    testWidgets('320 : le lien passe sous le texte, avec la seule hauteur de '
        'son texte', (WidgetTester tester) async {
      await salle(tester, const Size(320, 690), 2);
      expect(tester.takeException(), isNull);
      final Rect texte = tester.getRect(mention());
      final Rect lien = tester.getRect(_lien);
      expect(lien.left, closeTo(texte.left, 0.5));
      expect(lien.top, closeTo(texte.bottom, 0.5));
      expect(hautCours(tester), hautSansLien + lien.height);
    });

    for (final double y in <double>[-30, -12, 0, 6]) {
      testWidgets('la cible tactile deborde sans prendre de hauteur '
          '(touche a ${y.toInt()} du centre du lien)', (
        WidgetTester tester,
      ) async {
        await salle(tester, const Size(390, 844), 2);
        final Offset centre = tester.getCenter(_lien);
        await tester.tapAt(centre + Offset(0, y));
        await stabiliser(tester);
        expect(find.text(t.salle.informationControle.e1.titre), findsOneWidget);
      });
    }

    testWidgets('une touche hors de la cible (sur la carte du cours) '
        "n'ouvre rien", (WidgetTester tester) async {
      await salle(tester, const Size(390, 844), 2);
      final Offset centre = tester.getCenter(_lien);
      await tester.tapAt(centre + const Offset(0, 24));
      await stabiliser(tester);
      expect(find.text(t.salle.informationControle.e1.titre), findsNothing);
    });

    // Revue croisee du 05/10 : a 320 le lien passe sous la mention, sans
    // retrait, et sa cible agrandie monte jusque sous le chevron Retour. Le
    // chevron garde toujours ses touches ; la cible ne prend que les touches
    // qui ne tombent sur aucune autre commande.
    Finder chevron() => find.bySemanticsLabel(t.salle.seance.retour);
    Finder e1Titre() => find.text(t.salle.informationControle.e1.titre);

    for (final double largeur in <double>[320, 390]) {
      final Size taille = Size(largeur, largeur == 320 ? 690 : 844);
      testWidgets('${largeur.toInt()} : le chevron Retour garde ses touches, '
          'au centre et aux bords (sortie, pas de feuille)', (
        WidgetTester tester,
      ) async {
        int sorties = 0;
        await salle(tester, taille, 2, onSortir: () => sorties++);
        expect(chevron(), findsOneWidget);
        final Rect r = tester.getRect(chevron());
        final List<Offset> points = <Offset>[
          r.center,
          r.topLeft + const Offset(1, 1),
          r.topRight + const Offset(-1, 1),
          r.bottomLeft + const Offset(1, -1),
          r.bottomRight + const Offset(-1, -1),
          r.centerLeft + const Offset(1, 0),
          r.centerRight + const Offset(-1, 0),
          r.topCenter + const Offset(0, 1),
          r.bottomCenter + const Offset(0, -1),
        ];
        for (final Offset p in points) {
          await tester.tapAt(p);
          await stabiliser(tester);
          expect(e1Titre(), findsNothing, reason: 'touche en $p');
        }
        expect(sorties, points.length);
      });

      testWidgets('${largeur.toInt()} : une touche sur la carte du cours '
          "n'ouvre rien", (WidgetTester tester) async {
        int sorties = 0;
        await salle(tester, taille, 2, onSortir: () => sorties++);
        await tester.tapAt(tester.getCenter(find.text('Chapitre 1').first));
        await stabiliser(tester);
        expect(e1Titre(), findsNothing);
        expect(sorties, 0);
      });
    }

    testWidgets('320 : la touche a -30 du lien, hors de toute autre commande, '
        'ouvre toujours E-1', (WidgetTester tester) async {
      int sorties = 0;
      await salle(tester, const Size(320, 690), 2, onSortir: () => sorties++);
      final Offset p = tester.getCenter(_lien) + const Offset(0, -30);
      // Le point est bien au-dessus du lien, hors du chevron et de toute
      // autre commande de l'en-tete.
      expect(tester.getRect(chevron()).contains(p), isFalse);
      expect(tester.getRect(_lien).contains(p), isFalse);
      await tester.tapAt(p);
      await stabiliser(tester);
      expect(e1Titre(), findsOneWidget);
      expect(sorties, 0);
    });

    for (final double densite in <double>[1, 2]) {
      for (final double echelle in <double>[1, 2]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          testWidgets('E-1 a 320, densite x${densite.toInt()}, texte '
              '${(echelle * 100).toInt()} %, ${mode.name} : aucune erreur de '
              'mise en page, la derniere phrase est atteinte', (
            WidgetTester tester,
          ) async {
            await salle(
              tester,
              const Size(320, 690),
              densite,
              mode: mode,
              echelle: echelle,
            );
            expect(tester.takeException(), isNull);
            expect(_lien, findsOneWidget);
            await tester.tap(_lien);
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            final Finder fin = find.text(t.salle.informationControle.e1.p5);
            await tester.scrollUntilVisible(
              fin,
              200,
              scrollable: find.byType(Scrollable).last,
            );
            // Jusqu'au bout du defilement : la derniere phrase entiere.
            await tester.drag(
              find.byType(Scrollable).last,
              const Offset(0, -10000),
            );
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            final Rect derniere = tester.getRect(fin);
            expect(derniere.bottom, lessThanOrEqualTo(690));
            expect(derniere.top, greaterThanOrEqualTo(0));
          });
        }
      }
    }
  });
}
