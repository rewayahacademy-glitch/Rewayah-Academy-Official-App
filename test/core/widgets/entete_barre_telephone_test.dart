// EN-TETES AU TELEPHONE (directeur, 10/11/2026 ; arbitrages du pilote et du
// garde-cap). Sous 600, une page de niveau 2 ou plus (celle qui porte un disque
// retour) a une barre compacte : retour et titre cote a cote, le titre un palier
// au-dessus d'un titre de section (HIER-1, sans reduction), a la ligne entre
// ses mots, deux lignes au plus. Un titre plus long est abrege en fin de mot,
// suivi de « … » : aucun mot coupe (COUPE-MOTS-1), le titre entier au lecteur
// d'ecran et en infobulle a la pression longue. Un mot plus large que la ligne,
// ou un texte au-dela de 130 %, garde l'en-tete d'avant ; le grand titre reste
// celui des pages racines, de la tablette et du bureau.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/section_header.dart';

import '../../capture/outil_capture.dart'
    show capturerVue, chargerPolicesDuDepot, masquerRubanDebug, sautSansCapture;
import '../../support/aucun_mot_coupe.dart' show motsCoupes;
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

  group('Telephone, niveau 2 : retour et titre cote a cote, deux lignes au '
      'plus', () {
    for (final String titre in <String>[
      'Mes séances passées',
      'Cahier de transmission',
      'Appareils du foyer',
      'Détail de la séance',
    ]) {
      testWidgets('320 px : « $titre » prend la barre, deux lignes au plus, '
          'sans ellipse ni mot coupe', (WidgetTester tester) async {
        await _poser(tester, vue: const Size(320, 640), titre: titre);
        expect(tester.takeException(), isNull);
        expect(find.byKey(EnteteCompact.barreKey), findsOneWidget);
        final RenderParagraph p = _paragraphe(tester, titre);
        expect(p.didExceedMaxLines, isFalse);
        expect(
          p.size.height,
          lessThanOrEqualTo(p.text.style!.fontSize! * 2 * 1.5),
          reason: 'deux lignes au plus',
        );
        // Le garde partage, sans exception : aucun mot coupe ni tronque.
        expect(motsCoupes(tester, find.byType(EntetePage)), isEmpty);
        // Le titre garde sa taille : un palier au-dessus d'un titre de
        // section (22), jamais reduit.
        expect(_taille(tester, titre), 24);
      });
    }

    testWidgets('un titre court tient sur une ligne, a cote du disque', (
      WidgetTester tester,
    ) async {
      await _poser(tester, vue: const Size(390, 844), titre: _court);
      expect(find.byKey(EnteteCompact.barreKey), findsOneWidget);
      final Rect disque = tester.getRect(find.byType(DisqueRetour));
      final Rect texte = tester.getRect(find.byKey(EnteteCompact.titreKey));
      expect((disque.center.dy - texte.center.dy).abs(), lessThan(6));
      expect(texte.left, greaterThanOrEqualTo(disque.right));
    });

    testWidgets('un titre trop long : deux lignes, coupe en fin de mot, « … », '
        'le titre entier lu et en infobulle', (WidgetTester tester) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await _poser(tester, vue: const Size(320, 640));
      expect(tester.takeException(), isNull);
      expect(find.byKey(EnteteCompact.barreKey), findsOneWidget);
      // Le texte montre les premiers mots entiers, puis « … ».
      final Text rendu = tester.widget<Text>(
        find.byKey(EnteteCompact.titreKey),
      );
      final String texte = rendu.data!;
      expect(texte.endsWith('\u2026'), isTrue, reason: texte);
      final String debut = texte.substring(0, texte.length - 1);
      expect(_long.startsWith(debut), isTrue, reason: 'prefixe du titre');
      // Fin de mot : le caractere qui suit le prefixe est une espace.
      expect(_long[debut.length], ' ');
      // Deux lignes au plus, rien de coupe : le garde partage, sans exception.
      final RenderParagraph p = _paragraphe(tester, texte);
      expect(p.didExceedMaxLines, isFalse);
      expect(
        p.size.height,
        lessThanOrEqualTo(p.text.style!.fontSize! * 2 * 1.5),
      );
      expect(motsCoupes(tester, find.byType(EntetePage)), isEmpty);
      expect(_taille(tester, texte), 24);
      // Le titre entier au lecteur d'ecran...
      expect(find.bySemanticsLabel(_long), findsOneWidget);
      // ...et en infobulle a la pression longue.
      expect(find.byTooltip(_long), findsOneWidget);
      await tester.longPress(find.byKey(EnteteCompact.titreKey));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_long), findsOneWidget);
      poignee.dispose();
    });

    testWidgets('l\'abreviation garde les espaces insecables du titre', (
      WidgetTester tester,
    ) async {
      const String titre =
          'Fil\u00A0\u00AB\u00A0Profil de paiement de la famille\u00A0\u00BB suite';
      await _poser(tester, vue: const Size(320, 640), titre: titre);
      final String texte = tester
          .widget<Text>(find.byKey(EnteteCompact.titreKey))
          .data!;
      expect(texte.endsWith('\u2026'), isTrue, reason: texte);
      expect(
        titre.startsWith(texte.substring(0, texte.length - 1)),
        isTrue,
        reason: 'prefixe exact du titre, espaces insecables comprises',
      );
    });

    testWidgets('un titre qui tient : aucune infobulle, titre entier', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        vue: const Size(320, 640),
        titre: 'Mes séances passées',
      );
      expect(find.byType(Tooltip), findsNothing);
      expect(find.text('Mes séances passées'), findsOneWidget);
    });

    testWidgets(
      'un nom compose qui se couperait apres son trait d\'union reste '
      'entier : la barre le garde, sans mot coupe',
      (WidgetTester tester) async {
        await _poser(
          tester,
          vue: const Size(320, 640),
          titre: 'Classe An-Nour',
          actions: <Widget>[
            ClocheNotifications(onPress: () {}),
            ClocheNotifications(onPress: () {}),
          ],
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(EnteteCompact.barreKey), findsOneWidget);
        expect(motsCoupes(tester, find.byType(EntetePage)), isEmpty);
      },
    );

    // EXCEPTION ECRITE (garde-cap, 11/11/2026) : mot seul plus large que la
    // ligne : reduction bornee, HIER-1 toleré (voir aussi
    // `test/theme/hierarchie_titres_test.dart`). Un mot de 23 lettres ne tient
    // pas dans les 236 de la barre a 320 px : la barre le garde, sans ellipse,
    // avec la reduction habituelle et bornee de l'application ; mesure : 23,8
    // au lieu de 24, encore au-dessus d'un titre de section (22).
    testWidgets('mot seul de 23 lettres plus large que la ligne : la barre le '
        'garde, reduction bornee, jamais sous un titre de section', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        vue: const Size(320, 640),
        titre: 'Électroencéphalographie',
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(EnteteCompact.barreKey), findsOneWidget);
      expect(find.text('Électroencéphalographie'), findsOneWidget);
      expect(find.byType(Tooltip), findsNothing, reason: 'jamais d\'ellipse');
      final double taille = _taille(tester, 'Électroencéphalographie');
      // Un titre de section est a 22 en echelle standard.
      expect(taille, greaterThanOrEqualTo(22));
      expect(taille, lessThanOrEqualTo(24));
    });

    testWidgets('la place du titre est mesuree, pas estimee : des actions '
        'invisibles ne l\'abregent pas', (WidgetTester tester) async {
      await _poser(
        tester,
        vue: const Size(390, 844),
        titre: 'Mes séances passées',
        actions: const <Widget>[
          SizedBox.shrink(),
          SizedBox.shrink(),
          SizedBox.shrink(),
          SizedBox.shrink(),
        ],
      );
      expect(find.byKey(EnteteCompact.barreKey), findsOneWidget);
      expect(find.text('Mes séances passées'), findsOneWidget);
      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets('le lecteur d\'ecran lit le titre entier, annonce comme '
        'en-tete', (WidgetTester tester) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await _poser(
        tester,
        vue: const Size(320, 640),
        titre: 'Mes séances passées',
      );
      expect(find.bySemanticsLabel('Mes séances passées'), findsOneWidget);
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
      expect(find.byKey(EnteteCompact.barreKey), findsOneWidget);
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
        titre: 'Mes séances passées',
        actions: <Widget>[ClocheNotifications(onPress: () {})],
      );
      expect(tester.takeException(), isNull);
      final Rect cloche = tester.getRect(find.byType(ClocheNotifications));
      final Rect texte = tester.getRect(find.byKey(EnteteCompact.titreKey));
      expect(texte.right, lessThanOrEqualTo(cloche.left));
      expect(cloche.right, lessThanOrEqualTo(320));
      expect(motsCoupes(tester, find.byType(EntetePage)), isEmpty);
    });
  });

  group('HIER-1 : le titre de la barre reste strictement plus grand qu\'un '
      'titre de section', () {
    for (final InterfaceMode mode in <InterfaceMode>[
      InterfaceMode.standard,
      InterfaceMode.enfant,
    ]) {
      testWidgets('320 px, ${mode.name}', (WidgetTester tester) async {
        fixerVue(tester, const Size(320, 640));
        const Widget corps = Column(
          children: <Widget>[
            EntetePage(titre: 'Mes séances passées', onRetour: _rien),
            SectionHeader(titre: 'Titre de section'),
          ],
        );
        await tester.pumpWidget(
          mode == InterfaceMode.standard
              ? hoteTheme(corps)
              : hote(const SingleChildScrollView(child: corps), mode: mode),
        );
        await tester.pump();
        expect(
          _taille(tester, 'Mes séances passées'),
          greaterThan(_taille(tester, 'Titre de section')),
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
      for (final (String, String) cas in <(String, String)>[
        ('cahier-de-transmission', 'Cahier de transmission'),
        ('mes-seances-passees', 'Mes séances passées'),
        ('titre-long', 'Cahier de transmission à valider'),
      ]) {
        final String nom = '320-x${echelle.round()}-${cas.$1}';
        testWidgets('capture $nom', (WidgetTester tester) async {
          fixerVue(tester, const Size(320, 640));
          await tester.pumpWidget(
            hoteTheme(
              PageShell(
                titre: cas.$2,
                sousTitre: _sousTitre,
                onRetour: () {},
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

    testWidgets('capture 320-x1-racine', (WidgetTester tester) async {
      fixerVue(tester, const Size(320, 640));
      await tester.pumpWidget(
        hoteTheme(
          const PageShell(
            titre: 'Cahier de transmission',
            sousTitre: _sousTitre,
            child: SectionHeader(titre: 'Titre de section'),
          ),
          defilant: false,
        ),
      );
      await tester.pump();
      await capturerVue(tester, '320-x1-racine');
    });
  }, skip: sautSansCapture);
}

void _rien() {}
