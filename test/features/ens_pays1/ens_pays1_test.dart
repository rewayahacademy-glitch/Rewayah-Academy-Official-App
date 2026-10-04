// ENS-PAYS-1 (demande du directeur du 04/10/2026) : le pays de chaque
// enseignant apparait sur sa carte, pour tous les roles ; rien s'il n'est pas
// declare ; jamais deux lettres orphelines a la place d'un drapeau.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/pays_enseignant.dart';
import 'package:rewayah_academy/features/profil_enseignant/declaration_choix.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';
import 'support_ens_pays1.dart';

/// La police d'emoji de la machine, quand elle existe (Noto Color Emoji,
/// celle que Flutter Web et Android utilisent).
const String _policeEmoji = '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf';

Future<void> _monter(
  WidgetTester tester,
  EcranPays e, {
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection sens = TextDirection.ltr,
  ThemeMode theme = ThemeMode.light,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hotePays(e, theme: theme, echelle: echelle, sens: sens),
  );
  await stabiliser(tester);
  if (e.toucher != null) {
    await tester.tap(find.text(e.toucher!).first);
    await stabiliser(tester);
  }
}

/// Les pays rendus a l'ecran : chaque ligne `PaysEnseignant` montee.
List<String> _paysRendus(WidgetTester tester) => tester
    .widgetList<PaysEnseignant>(find.byType(PaysEnseignant))
    .map((PaysEnseignant p) => PaysEnseignant.nomAffichable(p.pays))
    .whereType<String>()
    .toList();

Widget _seul(Widget enfant, {TextDirection sens = TextDirection.ltr}) =>
    hoteCapture(
      Directionality(
        textDirection: sens,
        child: Scaffold(body: Center(child: enfant)),
      ),
    );

void main() {
  group('correspondance des pays', () {
    test('chacun des 19 pays de FORM-L8 a son code ISO', () {
      expect(paysProposes, hasLength(19));
      for (final PaysPropose p in paysProposes) {
        final String? code = codeIsoDuPays(p.nom);
        expect(code, isNotNull, reason: p.nom);
        expect(code, matches(RegExp(r'^[A-Z]{2}$')), reason: p.nom);
      }
      expect(codesIsoDesPays.keys.toSet(), <String>{
        for (final PaysPropose p in paysProposes) p.nom,
      });
      expect(codesIsoDesPays.values.toSet(), hasLength(19));
    });

    test('un pays ecrit dans « Autre » retrouve son code, ou n en a pas', () {
      expect(codeIsoDuPays('guinee'), 'GN');
      expect(codeIsoDuPays(' Cote d’Ivoire '), 'CI');
      expect(codeIsoDuPays('etats unis'), 'US');
      expect(codeIsoDuPays('ROYAUME UNI'), 'GB');
      expect(codeIsoDuPays('Comores'), isNull);
      expect(codeIsoDuPays(''), isNull);
      expect(codeIsoDuPays(null), isNull);
    });

    test('le drapeau est la paire de lettres regionales du code', () {
      expect(drapeauDuCode('GN').runes.toList(), <int>[0x1F1EC, 0x1F1F3]);
      expect(drapeauDuCode('fr').runes.toList(), <int>[0x1F1EB, 0x1F1F7]);
    });
  });

  group('PaysEnseignant', () {
    setUp(oublierDrapeauxMesures);

    testWidgets('non declare : rien, pas de « inconnu »', (
      WidgetTester tester,
    ) async {
      for (final String? vide in <String?>[null, '', '   ']) {
        await tester.pumpWidget(_seul(PaysEnseignant(pays: vide)));
        expect(find.byKey(PaysEnseignant.ligneKey), findsNothing);
        expect(find.byType(Text), findsNothing);
      }
      await tester.pumpWidget(
        _seul(
          const AvatarNom.enLigne(prenom: 'Khadija', nom: 'Sayyida Khadija'),
        ),
      );
      expect(find.byKey(PaysEnseignant.ligneKey), findsNothing);
    });

    testWidgets('sans police qui fusionne les lettres (Windows) : le nom seul, '
        'jamais deux lettres', (WidgetTester tester) async {
      await tester.pumpWidget(_seul(const PaysEnseignant(pays: 'Guinée')));
      expect(find.text('Guinée', findRichText: true), findsOneWidget);
      expect(find.byKey(PaysEnseignant.drapeauKey), findsNothing);
      expect(
        find.textContaining(drapeauDuCode('GN'), findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining(String.fromCharCode(0x1F1EC), findRichText: true),
        findsNothing,
      );
      expect(drapeauDessinable('GN', const TextStyle(fontSize: 14)), isFalse);
    });

    testWidgets('le lecteur d ecran lit « Pays : Guinée »', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(_seul(const PaysEnseignant(pays: 'Guinée')));
      expect(find.bySemanticsLabel('Pays : Guinée'), findsOneWidget);
      h.dispose();
    });

    group('avec une police d emoji (Android, Flutter Web)', () {
      final bool police = File(_policeEmoji).existsSync();
      setUpAll(() async {
        if (!police) return;
        final FontLoader l = FontLoader('Noto Color Emoji')
          ..addFont(
            Future<ByteData>.value(
              ByteData.sublistView(File(_policeEmoji).readAsBytesSync()),
            ),
          );
        await l.load();
      });

      testWidgets(
        'le drapeau precede le nom, et se met de l autre cote en arabe',
        skip: !police,
        (WidgetTester tester) async {
          oublierDrapeauxMesures();
          await tester.pumpWidget(_seul(const PaysEnseignant(pays: 'Guinée')));
          expect(find.byKey(PaysEnseignant.drapeauKey), findsOneWidget);
          final Finder nom = find.text('Guinée', findRichText: true);
          expect(
            tester.getCenter(find.byKey(PaysEnseignant.drapeauKey)).dx,
            lessThan(tester.getCenter(nom).dx),
          );
          await tester.pumpWidget(
            _seul(
              const PaysEnseignant(pays: 'Guinée'),
              sens: TextDirection.rtl,
            ),
          );
          await tester.pump();
          expect(
            tester.getCenter(find.byKey(PaysEnseignant.drapeauKey)).dx,
            greaterThan(tester.getCenter(nom).dx),
          );
        },
      );

      testWidgets(
        'un pays hors liste garde son nom, sans drapeau',
        skip: !police,
        (WidgetTester tester) async {
          await tester.pumpWidget(_seul(const PaysEnseignant(pays: 'Comores')));
          expect(find.text('Comores', findRichText: true), findsOneWidget);
          expect(find.byKey(PaysEnseignant.drapeauKey), findsNothing);
        },
      );
    });
  });

  group('le pays sur chaque carte recensee, pour chaque role', () {
    for (final EcranPays e in ecransPays()) {
      testWidgets('${e.role} / ${e.nom} : pays sous le nom', (
        WidgetTester tester,
      ) async {
        await _monter(tester, e);
        expect(tester.takeException(), isNull);
        final List<String> rendus = _paysRendus(tester);
        for (final String p in e.pays) {
          expect(rendus, contains(p), reason: '${e.nom} : $p');
          expect(
            find.text(p, findRichText: true),
            findsWidgets,
            reason: '${e.nom} : $p a l ecran',
          );
        }
      });

      testWidgets('${e.role} / ${e.nom} : 320 px, texte x2, arabe', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          e,
          taille: Size(320, e.hauteur320),
          echelle: 2,
          sens: TextDirection.rtl,
        );
        final Object? exception = tester.takeException();
        if (!e.debordementDeBase) expect(exception, isNull);
        expect(find.byKey(PaysEnseignant.ligneKey), findsWidgets);
        // La ligne du pays elle-meme reste dans l'ecran.
        for (final Element l
            in find.byKey(PaysEnseignant.ligneKey).evaluate()) {
          final Rect r = tester.getRect(find.byWidget(l.widget));
          expect(r.left, greaterThanOrEqualTo(0), reason: e.nom);
          expect(r.right, lessThanOrEqualTo(320.5), reason: e.nom);
        }
        verifierAucunMotCoupe(tester, find.byKey(PaysEnseignant.ligneKey));
      });
    }

    testWidgets('eleve : pays non declare, aucune ligne de pays', (
      WidgetTester tester,
    ) async {
      await _monter(tester, accueilEleve(pays: null));
      expect(find.text('Aminata', findRichText: true), findsNothing);
      expect(find.byKey(PaysEnseignant.ligneKey), findsNothing);
    });

    testWidgets('admin : la ligne sans pays declare n a rien', (
      WidgetTester tester,
    ) async {
      final EcranPays groupes = ecransPays().firstWhere(
        (EcranPays e) => e.nom == 'admin_groupes',
      );
      await _monter(tester, groupes, taille: const Size(1440, 900));
      expect(find.byKey(PaysEnseignant.ligneKey), findsOneWidget);
    });
  });
}
