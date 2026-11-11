// GESTES-POINTEUR (directeur, 11/11/2026, cahier de la salle §8) : « le
// pointeur est trop discret, et il arrive en retard chez l'eleve. Attendu :
// quasi instantane, tres visible, avec un sillage qui s'efface presque
// aussitot. »
//
// Ce fichier prouve la cadence d'envoi (30 par seconde au plus, la derniere
// position toujours, le battement, le lever), le point et son sillage, et
// « Reduire les animations » (le point seul).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/salle_seance/pointeur_salle.dart';

const Key _clePoint = ValueKey<String>('point');

Future<void> _monter(
  WidgetTester tester,
  ValueNotifier<Offset?> source, {
  bool reduit = false,
  bool rattrapage = true,
  Brightness clarte = Brightness.light,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.pour(InterfaceMode.standard, clarte),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduit),
      child: Center(
        child: SizedBox(
          width: 400,
          height: 600,
          child: PointeurSalle(
            source: source,
            clePoint: _clePoint,
            rattrapage: rattrapage,
          ),
        ),
      ),
    ),
  ),
);

Finder get _sillage => find.byKey(PointeurSalle.cleSillage);

/// Laisse passer [duree], image par image (16 ms), comme un ecran.
Future<void> _images(WidgetTester tester, Duration duree) async {
  for (int ms = 0; ms < duree.inMilliseconds; ms += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Le point montre, dans le repere de la boite (de 0 a 1).
Offset _position(WidgetTester tester) {
  final Rect boite = tester.getRect(find.byType(PointeurSalle));
  final Offset centre = tester.getCenter(find.byKey(_clePoint));
  return Offset(
    (centre.dx - boite.left) / boite.width,
    (centre.dy - boite.top) / boite.height,
  );
}

void main() {
  group('CadencePointeur : ce qui part a la classe', () {
    testWidgets('la premiere position part aussitot', (WidgetTester _) async {
      final List<Offset?> envois = <Offset?>[];
      final CadencePointeur cadence = CadencePointeur(envoyer: envois.add);
      cadence.montrer(const Offset(0.1, 0.1));
      expect(envois, <Offset?>[const Offset(0.1, 0.1)]);
      cadence.liberer();
    });

    testWidgets('la derniere position d un geste part toujours, meme tombee '
        'dans l intervalle (l ancien pointeur la jetait)', (
      WidgetTester tester,
    ) async {
      final List<Offset?> envois = <Offset?>[];
      final CadencePointeur cadence = CadencePointeur(envoyer: envois.add);
      cadence
        ..montrer(const Offset(0.1, 0.1))
        ..montrer(const Offset(0.2, 0.2))
        ..montrer(const Offset(0.3, 0.3));
      // Dans la fenetre : une seule position est partie.
      expect(envois, hasLength(1));
      await tester.pump(AppMouvement.pointeurCadence);
      // A sa fermeture : la plus recente, et elle seule (aucune file).
      expect(envois, <Offset?>[const Offset(0.1, 0.1), const Offset(0.3, 0.3)]);
      cadence.liberer();
    });

    testWidgets('au plus trente positions par seconde, quel que soit le '
        'nombre de mouvements', (WidgetTester tester) async {
      final List<Offset?> envois = <Offset?>[];
      final CadencePointeur cadence = CadencePointeur(envoyer: envois.add);
      // Une seconde de mouvement, un evenement toutes les 4 ms (250 par
      // seconde, plus qu'une souris).
      for (int i = 0; i < 250; i++) {
        cadence.montrer(Offset(i / 250, 0.5));
        await tester.pump(const Duration(milliseconds: 4));
      }
      expect(envois.length, lessThanOrEqualTo(31));
      expect(
        envois.length,
        greaterThanOrEqualTo(25),
        reason: 'le plafond ne doit pas ralentir le pointeur',
      );
      cadence.liberer();
    });

    testWidgets('pose sans bouger, la position est redite : le canal ne '
        'retransmet rien, le battement rattrape un paquet perdu', (
      WidgetTester tester,
    ) async {
      final List<Offset?> envois = <Offset?>[];
      final CadencePointeur cadence = CadencePointeur(envoyer: envois.add);
      cadence.montrer(const Offset(0.4, 0.4));
      await tester.pump(AppMouvement.pointeurBattement * 4);
      expect(envois.length, inInclusiveRange(4, 5));
      expect(envois.toSet(), <Offset?>{const Offset(0.4, 0.4)});
      cadence.liberer();
    });

    testWidgets('le lever part aussitot, et plus rien ne part ensuite', (
      WidgetTester tester,
    ) async {
      final List<Offset?> envois = <Offset?>[];
      final CadencePointeur cadence = CadencePointeur(envoyer: envois.add);
      cadence
        ..montrer(const Offset(0.1, 0.1))
        ..montrer(const Offset(0.2, 0.2))
        ..lever();
      expect(envois.last, isNull);
      final int avant = envois.length;
      await tester.pump(AppMouvement.pointeurBattement * 4);
      expect(envois, hasLength(avant));
      expect(cadence.montre, isFalse);
      // Un lever sans rien de montre ne dit rien a la classe.
      cadence.lever();
      expect(envois, hasLength(avant));
    });
  });

  group('PointeurSalle : ce qui se voit', () {
    testWidgets('le centre du point est sur la position montree, a tous les '
        'coins de la page', (WidgetTester tester) async {
      final ValueNotifier<Offset?> source = ValueNotifier<Offset?>(null);
      addTearDown(source.dispose);
      await _monter(tester, source);
      expect(find.byKey(_clePoint), findsNothing);
      for (final Offset point in const <Offset>[
        Offset(0.5, 0.5),
        Offset.zero,
        Offset(1, 1),
        Offset(0.25, 0.9),
      ]) {
        source.value = null;
        await tester.pump();
        source.value = point;
        await tester.pump();
        expect(
          (_position(tester) - point).distance,
          lessThan(0.001),
          reason: '$point',
        );
      }
    });

    testWidgets('tres visible : plus grand que l ancien point (20), et il '
        'se lit en clair comme en sombre', (WidgetTester tester) async {
      for (final Brightness clarte in Brightness.values) {
        final ValueNotifier<Offset?> source = ValueNotifier<Offset?>(
          const Offset(0.5, 0.5),
        );
        await _monter(tester, source, clarte: clarte);
        await tester.pump();
        final Size taille = tester.getSize(find.byKey(_clePoint));
        expect(
          taille.shortestSide,
          greaterThanOrEqualTo(32),
          reason: '$clarte',
        );
        source.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('chez l eleve, le point rejoint la position recue sans '
        'sauter, en moins de deux dixiemes de seconde', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset?> source = ValueNotifier<Offset?>(
        const Offset(0.2, 0.2),
      );
      addTearDown(source.dispose);
      await _monter(tester, source);
      await tester.pump();
      source.value = const Offset(0.8, 0.2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final double apresUneImage = _position(tester).dx;
      expect(apresUneImage, greaterThan(0.2), reason: 'il est parti');
      expect(apresUneImage, lessThan(0.8), reason: 'il ne saute pas');
      await tester.pump(const Duration(milliseconds: 180));
      expect(
        (_position(tester) - const Offset(0.8, 0.2)).distance,
        lessThan(0.02),
        reason: 'aucun retard visible',
      );
    });

    testWidgets('chez l enseignant, le point reste sous son doigt (aucun '
        'rattrapage)', (WidgetTester tester) async {
      final ValueNotifier<Offset?> source = ValueNotifier<Offset?>(
        const Offset(0.2, 0.2),
      );
      addTearDown(source.dispose);
      await _monter(tester, source, rattrapage: false);
      await tester.pump();
      source.value = const Offset(0.8, 0.6);
      await tester.pump();
      expect(
        (_position(tester) - const Offset(0.8, 0.6)).distance,
        lessThan(0.001),
      );
    });

    testWidgets('un sillage suit le mouvement et s efface presque aussitot', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset?> source = ValueNotifier<Offset?>(
        const Offset(0.2, 0.2),
      );
      addTearDown(source.dispose);
      await _monter(tester, source);
      await tester.pump();
      expect(_sillage, findsNothing, reason: 'immobile : pas de sillage');
      for (int i = 1; i <= 6; i++) {
        source.value = Offset(0.2 + i * 0.1, 0.2);
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(_sillage, findsOneWidget, reason: 'en mouvement');
      // Le mouvement s'arrete : le sillage disparait en moins d'une
      // demi-seconde, le point reste.
      await _images(tester, AppMouvement.pointeurSillage * 2);
      expect(_sillage, findsNothing, reason: 'efface');
      expect(find.byKey(_clePoint), findsOneWidget);
      expect(
        AppMouvement.pointeurSillage,
        lessThanOrEqualTo(const Duration(milliseconds: 400)),
      );
      // Plus rien ne bouge : aucune image n'est demandee.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('le pointeur se leve : le point disparait aussitot, le '
        'sillage finit de s effacer, puis plus rien', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<Offset?> source = ValueNotifier<Offset?>(
        const Offset(0.2, 0.2),
      );
      addTearDown(source.dispose);
      await _monter(tester, source);
      await tester.pump();
      for (int i = 1; i <= 4; i++) {
        source.value = Offset(0.2 + i * 0.1, 0.2);
        await tester.pump(const Duration(milliseconds: 16));
      }
      source.value = null;
      await tester.pump();
      expect(find.byKey(_clePoint), findsNothing);
      await _images(tester, AppMouvement.pointeurSillage * 2);
      expect(_sillage, findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('« Reduire les animations » : le point seul, a sa place, '
        'sans sillage ni glissade', (WidgetTester tester) async {
      final ValueNotifier<Offset?> source = ValueNotifier<Offset?>(
        const Offset(0.2, 0.2),
      );
      addTearDown(source.dispose);
      await _monter(tester, source, reduit: true);
      await tester.pump();
      for (int i = 1; i <= 6; i++) {
        source.value = Offset(0.2 + i * 0.1, 0.2);
        await tester.pump(const Duration(milliseconds: 16));
        expect(_sillage, findsNothing);
        expect(
          (_position(tester) - source.value!).distance,
          lessThan(0.001),
          reason: 'le point est a sa place sans glisser',
        );
      }
      expect(tester.binding.hasScheduledFrame, isFalse);
      source.value = null;
      await tester.pump();
      expect(find.byKey(_clePoint), findsNothing);
    });
  });
}
