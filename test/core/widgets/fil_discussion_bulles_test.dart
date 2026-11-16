// BULLES-MESSAGERIE (directeur, 16/11/2026) : la forme, la place, la couleur et
// le pied des bulles de `FilDiscussion`, les groupes de messages rapproches,
// les separateurs de jour et le sens du texte de chaque bulle. Le contraste
// des deux paires de la bulle est mesure ici (clair et sombre).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/communications/textes_fil_communication.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_radius.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';

import '../../theme/support/contraste.dart';

/// Midi, heure de l'horloge du fil sous test (UTC, le profil n'en change pas).
final DateTime _maintenant = DateTime.utc(2026, 11, 16, 12);

MessageFil _m(
  String id, {
  required DateTime instant,
  bool deSoi = false,
  String auteur = 'Ahmed',
  String texte = 'Bonjour',
  RemiseMessage? remise,
}) => MessageFil(
  id: id,
  auteur: deSoi ? 'Vous' : auteur,
  texte: texte,
  horodatage: 'long-$id',
  instant: instant,
  deSoi: deSoi,
  remise: remise,
);

Widget _fil(
  List<MessageFil> messages, {
  bool afficherAuteur = true,
  Brightness luminosite = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) => ProviderScope(
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, luminosite),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: FilDiscussion(
            pleinEcran: true,
            messages: messages,
            textes: textesFilCommunication(),
            onEnvoyer: (String _) async {},
            afficherAuteur: afficherAuteur,
            horloge: () => _maintenant,
          ),
        ),
      ),
    ),
  ),
);

Finder _bulle(String id) => find.descendant(
  of: find.byKey(ValueKey<String>('message-$id')),
  matching: find.byType(DecoratedBox),
);

BoxDecoration _deco(WidgetTester tester, String id) =>
    tester.widget<DecoratedBox>(_bulle(id).first).decoration as BoxDecoration;

void main() {
  final DateTime hier = DateTime.utc(2026, 11, 15, 9);
  final DateTime aujourdhui = DateTime.utc(2026, 11, 16, 9);

  testWidgets('largeur : le contenu, 75 % de la colonne au plus, 560 au plus, '
      'et 64 toujours libres du cote oppose', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final String long = List<String>.filled(80, 'beaucoup').join(' ');
    await tester.pumpWidget(
      _fil(<MessageFil>[
        _m('court', instant: aujourdhui, texte: 'Oui'),
        _m(
          'long',
          instant: aujourdhui.add(const Duration(hours: 1)),
          texte: long,
        ),
        _m(
          'soi',
          instant: aujourdhui.add(const Duration(hours: 2)),
          deSoi: true,
          texte: long,
        ),
      ]),
    );
    await tester.pump();
    final double court = tester.getSize(_bulle('court').first).width;
    final double longue = tester.getSize(_bulle('long').first).width;
    expect(court, lessThan(100), reason: 'la bulle prend la taille du texte');
    expect(longue, lessThanOrEqualTo(560));
    final Rect soi = tester.getRect(_bulle('soi').first);
    final Rect colonne = tester.getRect(find.byType(CustomScrollView));
    expect(
      soi.width,
      lessThanOrEqualTo(colonne.width * FilDiscussion.partBulle + 0.01),
    );
    expect(
      colonne.right - soi.right,
      lessThan(40),
      reason: 'le sien, cote fin',
    );
    expect(soi.left - colonne.left, greaterThanOrEqualTo(64));
    final Rect recue = tester.getRect(_bulle('long').first);
    expect(
      recue.left - colonne.left,
      lessThan(40),
      reason: 'le recu, cote debut',
    );
    expect(colonne.right - recue.right, greaterThanOrEqualTo(64));
  });

  testWidgets('forme : rayon 16 partout, le coin du cote de celui qui parle '
      'au plus petit jeton, aucune bordure', (WidgetTester tester) async {
    await tester.pumpWidget(
      _fil(<MessageFil>[
        _m('a', instant: aujourdhui),
        _m('b', instant: aujourdhui.add(const Duration(hours: 1)), deSoi: true),
      ]),
    );
    await tester.pump();
    final BorderRadiusDirectional recu =
        _deco(tester, 'a').borderRadius! as BorderRadiusDirectional;
    expect(recu.bottomStart, const Radius.circular(AppRadius.xs));
    expect(recu.bottomEnd, const Radius.circular(AppRadius.md));
    expect(recu.topStart, const Radius.circular(AppRadius.md));
    final BorderRadiusDirectional soi =
        _deco(tester, 'b').borderRadius! as BorderRadiusDirectional;
    expect(soi.bottomEnd, const Radius.circular(AppRadius.xs));
    expect(soi.bottomStart, const Radius.circular(AppRadius.md));
    expect(_deco(tester, 'a').border, isNull);
    expect(_deco(tester, 'b').border, isNull);
  });

  testWidgets('couleur : le sien en violet profond, le recu en carte claire '
      'avec UNE ombre ; le fil, plus sombre que la carte', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _fil(<MessageFil>[
        _m('a', instant: aujourdhui),
        _m('b', instant: aujourdhui.add(const Duration(hours: 1)), deSoi: true),
      ]),
    );
    await tester.pump();
    final AppPalette p = AppPalette.claire();
    expect(_deco(tester, 'b').color, p.surfaceBulleSoi.background);
    expect(_deco(tester, 'b').boxShadow, anyOf(isNull, isEmpty));
    expect(_deco(tester, 'a').color, p.surfaceRaised.background);
    expect(_deco(tester, 'a').boxShadow, hasLength(1));
    final ColoredBox fond = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byKey(FilDiscussion.cleMessages),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(fond.color, p.fondFil.background);
  });

  test('contrastes mesures : le texte de la bulle, la bulle sur le fil, '
      'l\'encre du pied sur le fil (clair et sombre)', () {
    for (final AppPalette p in <AppPalette>[
      AppPalette.claire(),
      AppPalette.sombre(),
    ]) {
      final double texte = contraste(
        p.surfaceBulleSoi.background,
        p.surfaceBulleSoi.onBackground,
      );
      // ignore: avoid_print
      print(
        '${p.estSombre ? 'sombre' : 'clair'} : texte sur bulle '
        '${texte.toStringAsFixed(2)}:1',
      );
      expect(texte, greaterThanOrEqualTo(seuilTexte));
      expect(
        p.surfaceBulleSoi.onBackground,
        isNot(const Color(0xFFFFFFFF)),
        reason: 'blanc casse, jamais le blanc pur (effet de reflexion)',
      );
      final double bulleSurFil = contraste(
        p.surfaceBulleSoi.background,
        p.fondFil.background,
      );
      // ignore: avoid_print
      print(
        '${p.estSombre ? 'sombre' : 'clair'} : bulle sur fil '
        '${bulleSurFil.toStringAsFixed(2)}:1',
      );
      expect(bulleSurFil, greaterThanOrEqualTo(seuilComposant - 0.5));
      final Color discrete = p.inkMuted.asBorderSide().color;
      expect(
        contraste(discrete, p.fondFil.background),
        greaterThanOrEqualTo(seuilTexte),
      );
    }
  });

  testWidgets('l\'heure sous la bulle, seule la derniere d\'un groupe de '
      'messages rapproches la porte, avec 4 points d\'ecart', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _fil(<MessageFil>[
        _m('g1', instant: aujourdhui, deSoi: true, texte: 'Un'),
        _m(
          'g2',
          instant: aujourdhui.add(const Duration(minutes: 2)),
          deSoi: true,
          texte: 'Deux',
        ),
        _m(
          'g3',
          instant: aujourdhui.add(const Duration(minutes: 20)),
          deSoi: true,
          texte: 'Trois',
        ),
      ]),
    );
    await tester.pump();
    expect(find.text('09:00'), findsNothing);
    expect(find.text('09:02'), findsOneWidget);
    expect(find.text('09:20'), findsOneWidget);
    final BorderRadiusDirectional premier =
        _deco(tester, 'g1').borderRadius! as BorderRadiusDirectional;
    expect(premier.bottomEnd, const Radius.circular(AppRadius.md));
    final BorderRadiusDirectional dernier =
        _deco(tester, 'g2').borderRadius! as BorderRadiusDirectional;
    expect(dernier.bottomEnd, const Radius.circular(AppRadius.xs));
    final double ecartGroupe =
        tester.getTopLeft(_bulle('g2').first).dy -
        tester.getBottomLeft(_bulle('g1').first).dy;
    expect(ecartGroupe, 4);
  });

  testWidgets('separateurs de jour : « Aujourd\'hui », « Hier », la date', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _fil(<MessageFil>[
        _m('v', instant: DateTime.utc(2026, 11, 10, 9)),
        _m('h', instant: hier),
        _m('a', instant: aujourdhui),
      ]),
    );
    await tester.pump();
    expect(find.text(t.com.socle.lexique.aujourdhui), findsOneWidget);
    expect(find.text(t.com.socle.lexique.hier), findsOneWidget);
    expect(find.textContaining('10 novembre'), findsOneWidget);
  });

  testWidgets('moins de texte : aucun « Vous » ; le nom de l\'autre disparait '
      'a deux et reste en groupe ; le lecteur d\'ecran annonce l\'auteur', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final List<MessageFil> messages = <MessageFil>[
      _m('a', instant: aujourdhui),
      _m('b', instant: aujourdhui.add(const Duration(hours: 1)), deSoi: true),
    ];
    await tester.pumpWidget(_fil(messages, afficherAuteur: false));
    await tester.pumpAndSettle();
    expect(find.text('Vous'), findsNothing);
    expect(find.text('Ahmed'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Ahmed')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Vous')), findsOneWidget);
    await tester.pumpWidget(_fil(messages));
    await tester.pump();
    expect(find.text('Ahmed'), findsOneWidget);
    expect(find.text('Vous'), findsNothing);
    handle.dispose();
  });

  testWidgets('sens du texte : l\'arabe dans une interface francaise suit sa '
      'langue, et inversement', (WidgetTester tester) async {
    await tester.pumpWidget(
      _fil(<MessageFil>[
        _m('ar', instant: aujourdhui, texte: 'شكرا جزيلا'),
        _m(
          'fr',
          instant: aujourdhui.add(const Duration(hours: 1)),
          texte: 'Merci beaucoup',
        ),
      ]),
    );
    await tester.pump();
    TextDirection sens(String texte) =>
        tester.widget<Text>(find.text(texte)).textDirection!;
    expect(sens('شكرا جزيلا'), TextDirection.rtl);
    expect(sens('Merci beaucoup'), TextDirection.ltr);
  });

  testWidgets('arabe : le miroir est la norme, le recu cote debut (a droite) '
      'et le sien cote fin (a gauche)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _fil(<MessageFil>[
        _m('a', instant: aujourdhui),
        _m('b', instant: aujourdhui.add(const Duration(hours: 1)), deSoi: true),
      ], direction: TextDirection.rtl),
    );
    await tester.pump();
    expect(
      tester.getCenter(_bulle('a').first).dx,
      greaterThan(tester.getCenter(_bulle('b').first).dx),
    );
  });
}
