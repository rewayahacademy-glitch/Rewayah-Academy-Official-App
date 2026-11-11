// EN-TETES AU TELEPHONE (directeur, 10/11/2026) : un titre de trois mots ne
// prend jamais trois lignes. Sous 600, une page de niveau 2 ou plus (celle qui
// porte un disque retour) a une barre compacte : retour et titre sur UNE
// ligne, le titre un palier au-dessus d'un titre de section (HIER-1), puis des
// points de suspension. Le grand titre reste celui des pages racines des
// onglets, de la tablette et du bureau ; au-dela de 130 % de texte, la mise en
// page d'avant (retour au-dessus, mots entiers) reste celle du texte agrandi.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../support/harnais.dart' show hote;
import '../../support/hote_theme.dart';

const String _long = 'Cahier de transmission à valider';
const String _court = 'Foyer';
const String _sousTitre = 'Examinez les cahiers prêts pour une décision.';

RenderParagraph _paragraphe(WidgetTester tester, String texte) =>
    tester.renderObject<RenderParagraph>(
      find.byWidgetPredicate(
        (Widget w) =>
            w is RichText && w.text.toPlainText().replaceAll('⁠', '') == texte,
      ),
    );

double _taille(WidgetTester tester, String texte) {
  final RenderParagraph p = _paragraphe(tester, texte);
  return p.textScaler.scale(p.text.style!.fontSize!);
}

Future<void> _poser(
  WidgetTester tester, {
  required Size vue,
  double echelle = 1,
  String titre = _long,
  bool retour = true,
  TextDirection sens = TextDirection.ltr,
  String? sousTitre,
  List<Widget> actions = const <Widget>[],
}) async {
  fixerVue(tester, vue);
  await tester.pumpWidget(
    hoteTheme(
      Directionality(
        textDirection: sens,
        child: EntetePage(
          titre: titre,
          sousTitre: sousTitre,
          onRetour: retour ? () {} : null,
          actions: actions,
        ),
      ),
      echelleTexte: echelle,
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('Telephone, niveau 2 : retour et titre sur une ligne', () {
    for (final Size vue in <Size>[const Size(320, 640), const Size(390, 844)]) {
      testWidgets('${vue.width.toInt()} px : un long titre tient sur une '
          'ligne, avec ses points de suspension', (WidgetTester tester) async {
        await _poser(tester, vue: vue);
        expect(tester.takeException(), isNull);
        expect(find.byKey(EnteteCompact.barreKey), findsOneWidget);
        final RenderParagraph titre = _paragraphe(tester, _long);
        // Une ligne : la hauteur d'une ligne de ce corps, pas trois.
        expect(titre.size.height, lessThan(titre.text.style!.fontSize! * 2));
        expect(titre.maxLines, 1);
        expect(titre.overflow, TextOverflow.ellipsis);
        expect(titre.didExceedMaxLines, isTrue);
        // Sur la rangee du disque retour : leurs centres se confondent.
        final Rect disque = tester.getRect(find.byType(DisqueRetour));
        final Rect texte = tester.getRect(find.byKey(EnteteCompact.titreKey));
        expect((disque.center.dy - texte.center.dy).abs(), lessThan(6));
        // Et la barre ne depasse pas la hauteur du disque (48) de plus d'une
        // marge : retour et titre ne se sont pas empiles.
        expect(
          tester.getSize(find.byKey(EnteteCompact.barreKey)).height,
          lessThanOrEqualTo(56),
        );
      });
    }

    for (final String titre in <String>[
      'Mes séances passées',
      'Appareils du foyer',
      'Dossiers à valider',
      'Détail de la séance',
    ]) {
      testWidgets('320 px : « $titre » tient sur une ligne, sans points de '
          'suspension (le texte se reduit d\'abord)', (
        WidgetTester tester,
      ) async {
        await _poser(tester, vue: const Size(320, 640), titre: titre);
        expect(tester.takeException(), isNull);
        final RenderParagraph p = _paragraphe(tester, titre);
        expect(p.didExceedMaxLines, isFalse);
        expect(p.size.height, lessThan(p.text.style!.fontSize! * 2));
      });
    }

    testWidgets('un titre court reste entier, sans points de suspension', (
      WidgetTester tester,
    ) async {
      await _poser(tester, vue: const Size(390, 844), titre: _court);
      final RenderParagraph titre = _paragraphe(tester, _court);
      expect(titre.didExceedMaxLines, isFalse);
    });

    testWidgets('le lecteur d\'ecran lit le titre entier, annonce comme '
        'en-tete', (WidgetTester tester) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await _poser(tester, vue: const Size(320, 640));
      expect(
        find.bySemanticsLabel(_long),
        findsOneWidget,
        reason: 'le titre tronque se lit en entier',
      );
      poignee.dispose();
    });

    testWidgets('le sous-titre reste sous la barre', (
      WidgetTester tester,
    ) async {
      await _poser(tester, vue: const Size(390, 844), sousTitre: _sousTitre);
      final Rect barre = tester.getRect(find.byKey(EnteteCompact.barreKey));
      final Rect sous = tester.getRect(find.byKey(EnteteCompact.sousTitreKey));
      expect(sous.top, greaterThanOrEqualTo(barre.bottom));
    });

    testWidgets('droite a gauche : le retour est a droite, le titre le suit', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        vue: const Size(390, 844),
        sens: TextDirection.rtl,
        titre: 'دفتر المتابعة الخاص بالحصة',
      );
      final Rect disque = tester.getRect(find.byType(DisqueRetour));
      final Rect texte = tester.getRect(find.byKey(EnteteCompact.titreKey));
      expect(disque.center.dx, greaterThan(texte.center.dx));
      expect(texte.right, lessThanOrEqualTo(disque.left));
    });

    testWidgets('une action a droite garde sa place : le titre cede', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        vue: const Size(320, 640),
        actions: <Widget>[ClocheNotifications(onPress: () {})],
      );
      final Rect cloche = tester.getRect(find.byType(ClocheNotifications));
      final Rect texte = tester.getRect(find.byKey(EnteteCompact.titreKey));
      expect(texte.right, lessThanOrEqualTo(cloche.left));
      expect(cloche.right, lessThanOrEqualTo(320));
    });
  });

  group('HIER-1 : le titre de la barre ne passe jamais sous un titre de '
      'section', () {
    Future<void> poserAvecSection(
      WidgetTester tester,
      String titre, {
      InterfaceMode mode = InterfaceMode.standard,
    }) async {
      fixerVue(tester, const Size(320, 640));
      final Widget corps = Column(
        children: <Widget>[
          EntetePage(titre: titre, onRetour: _rien),
          const SectionHeader(titre: 'Titre de section'),
        ],
      );
      await tester.pumpWidget(
        mode == InterfaceMode.standard
            ? hoteTheme(corps)
            : hote(SingleChildScrollView(child: corps), mode: mode),
      );
      await tester.pump();
    }

    for (final InterfaceMode mode in <InterfaceMode>[
      InterfaceMode.standard,
      InterfaceMode.enfant,
    ]) {
      testWidgets('un titre qui tient a sa taille : strictement plus grand '
          '(${mode.name})', (WidgetTester tester) async {
        await poserAvecSection(tester, 'Foyer', mode: mode);
        expect(
          _taille(tester, 'Foyer'),
          greaterThan(_taille(tester, 'Titre de section')),
        );
      });

      testWidgets('un titre reduit pour tenir : jamais sous le titre de '
          'section (${mode.name})', (WidgetTester tester) async {
        await poserAvecSection(tester, _long, mode: mode);
        expect(
          _taille(tester, _long),
          greaterThanOrEqualTo(_taille(tester, 'Titre de section')),
        );
      });
    }
  });

  group('Ce qui ne change pas', () {
    testWidgets('page racine d\'onglet (sans retour) : le grand titre, sur '
        'plusieurs lignes si besoin', (WidgetTester tester) async {
      await _poser(tester, vue: const Size(320, 640), retour: false);
      expect(find.byKey(EnteteCompact.barreKey), findsNothing);
      expect(_taille(tester, _long), 28);
      expect(_paragraphe(tester, _long).didExceedMaxLines, isFalse);
    });

    testWidgets('tablette et bureau : le grand titre, avec le retour', (
      WidgetTester tester,
    ) async {
      for (final Size vue in <Size>[
        const Size(800, 1000),
        const Size(1440, 900),
      ]) {
        await _poser(tester, vue: vue);
        expect(find.byKey(EnteteCompact.barreKey), findsNothing);
        expect(_taille(tester, _long), 32);
      }
    });

    testWidgets('texte a 200 % : la mise en page d\'avant, mots entiers, '
        'sans points de suspension', (WidgetTester tester) async {
      await _poser(tester, vue: const Size(320, 640), echelle: 2);
      expect(find.byKey(EnteteCompact.barreKey), findsNothing);
      expect(_paragraphe(tester, _long).didExceedMaxLines, isFalse);
    });

    testWidgets('PageShell : une page de niveau 2 au telephone prend la '
        'barre', (WidgetTester tester) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        hoteTheme(
          PageShell(
            titre: _long,
            onRetour: () {},
            child: const SizedBox(height: 40),
          ),
          defilant: false,
        ),
      );
      await tester.pump();
      expect(find.byKey(EnteteCompact.barreKey), findsOneWidget);
    });
  });

  group('Captures R3 EN-TETES AU TELEPHONE', () {
    setUpAll(chargerPolicesDuDepot);
    setUp(masquerRubanDebug);

    for (final double echelle in <double>[1, 2]) {
      for (final bool niveau2 in <bool>[true, false]) {
        final String nom =
            '320-x${echelle.round()}-${niveau2 ? 'niveau2' : 'racine'}';
        testWidgets('capture $nom', (WidgetTester tester) async {
          fixerVue(tester, const Size(320, 640));
          await tester.pumpWidget(
            hoteTheme(
              PageShell(
                titre: _long,
                sousTitre: _sousTitre,
                onRetour: niveau2 ? () {} : null,
                child: const SectionHeader(titre: 'Titre de section'),
              ),
              echelleTexte: echelle,
              defilant: false,
            ),
          );
          await tester.pump();
          await capturerVue(tester, nom);
        });
      }
    }

    testWidgets('capture 320-x1-niveau2-trois-mots', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 640));
      await tester.pumpWidget(
        hoteTheme(
          PageShell(
            titre: 'Mes séances passées',
            onRetour: () {},
            child: const SectionHeader(titre: 'Titre de section'),
          ),
          defilant: false,
        ),
      );
      await tester.pump();
      await capturerVue(tester, '320-x1-niveau2-trois-mots');
    });
  }, skip: sautSansCapture);
}

void _rien() {}
