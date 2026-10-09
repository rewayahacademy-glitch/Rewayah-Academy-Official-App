// ENS-PAYS-1 (demande du directeur du 04/10/2026) : le pays de chaque
// enseignant apparait sur sa carte, pour tous les roles ; rien s'il n'est pas
// declare ; jamais deux lettres orphelines a la place d'un drapeau.
// ENS-DRAPEAU-1 (decision Q-5 du 05/10/2026) : le drapeau est une image
// embarquee, la meme sur toutes les plateformes, Windows compris.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/pays_enseignant.dart';
import 'package:rewayah_academy/features/profil_enseignant/declaration_choix.dart';

import '../../capture/outil_capture.dart';
import '../../support/aucun_mot_coupe.dart';
import 'support_ens_pays1.dart';

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

/// Le chemin de l'image du drapeau a l'ecran (un seul attendu).
String? _imageDuDrapeau(WidgetTester tester) {
  final Iterable<Image> images = tester.widgetList<Image>(find.byType(Image));
  if (images.isEmpty) return null;
  final ImageProvider<Object> source = images.single.image;
  return source is AssetImage ? source.assetName : null;
}

/// Laisse le decodage des images se terminer (il tourne hors du temps
/// simule des tests), puis redessine.
Future<void> _chargerImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final Element e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();
}

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

    test('chacun des 19 pays a son image de drapeau dans le paquet', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final String code in codesIsoDesPays.values) {
        final ByteData png = await rootBundle.load(cheminDrapeau(code));
        // Signature PNG, puis largeur et hauteur de l'en-tete IHDR : 64 x 48.
        expect(png.getUint32(0), 0x89504E47, reason: code);
        expect(png.getUint32(16), 64, reason: code);
        expect(png.getUint32(20), 48, reason: code);
      }
    });
  });

  group('PaysEnseignant', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    testWidgets('non declare : rien, pas de « inconnu »', (
      WidgetTester tester,
    ) async {
      for (final String? vide in <String?>[null, '', '   ']) {
        await tester.pumpWidget(_seul(PaysEnseignant(pays: vide)));
        expect(find.byKey(PaysEnseignant.ligneKey), findsNothing);
        expect(find.byType(Text), findsNothing);
        expect(find.byType(Image), findsNothing);
      }
      await tester.pumpWidget(
        _seul(
          const AvatarNom.enLigne(prenom: 'Khadija', nom: 'Sayyida Khadija'),
        ),
      );
      expect(find.byKey(PaysEnseignant.ligneKey), findsNothing);
    });

    testWidgets('identite masquee (prenom vide) : pas de pays seul', (
      WidgetTester tester,
    ) async {
      for (final String prenom in <String>['', '  ']) {
        await tester.pumpWidget(
          _seul(AvatarNom.enLigne(prenom: prenom, nom: 'Sayyid', pays: 'Mali')),
        );
        expect(find.byKey(PaysEnseignant.ligneKey), findsNothing);
        expect(find.byType(Image), findsNothing);
        await tester.pumpWidget(
          _seul(AvatarNom.vertical(prenom: prenom, pays: 'Mali')),
        );
        expect(find.byKey(PaysEnseignant.ligneKey), findsNothing);
        expect(find.byType(Image), findsNothing);
      }
      await tester.pumpWidget(
        _seul(const AvatarNom.enLigne(prenom: 'Oumar', pays: 'Mali')),
      );
      expect(find.byKey(PaysEnseignant.ligneKey), findsOneWidget);
      expect(_imageDuDrapeau(tester), 'assets/flags/ml.png');
    });

    // ENS-DRAPEAU-1 : un seul rendu, l'image embarquee, sur TOUTES les
    // plateformes ; Windows (ou les drapeaux emoji ne s'affichent pas) en tete.
    for (final TargetPlatform plateforme in <TargetPlatform>[
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.fuchsia,
    ]) {
      testWidgets('${plateforme.name} : l image du drapeau precede le nom, '
          'jamais de lettres regionales', (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = plateforme;
        await tester.pumpWidget(_seul(const PaysEnseignant(pays: 'Guinée')));
        await _chargerImages(tester);
        expect(find.text('Guinée', findRichText: true), findsOneWidget);
        expect(find.byKey(PaysEnseignant.drapeauKey), findsOneWidget);
        expect(_imageDuDrapeau(tester), 'assets/flags/gn.png');
        // L'image est decodee et peinte (pas le repli vide de errorBuilder).
        final RawImage peinte = tester.widget<RawImage>(find.byType(RawImage));
        expect(peinte.image, isNotNull);
        expect(peinte.image!.width, 64);
        expect(
          tester.getCenter(find.byKey(PaysEnseignant.drapeauKey)).dx,
          lessThan(tester.getCenter(find.text('Guinée')).dx),
        );
        expect(
          find.textContaining(
            RegExp('[\u{1F1E6}-\u{1F1FF}]', unicode: true),
            findRichText: true,
          ),
          findsNothing,
        );
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('taille alignee sur la ligne : hauteur du corps, 4:3, '
        'agrandie avec le texte', (WidgetTester tester) async {
      for (final double echelle in <double>[1, 2]) {
        await tester.pumpWidget(
          hoteCapture(
            const Scaffold(
              body: Center(child: PaysEnseignant(pays: 'Mali')),
            ),
            echelleTexte: echelle,
          ),
        );
        final BuildContext ctx = tester.element(find.byType(PaysEnseignant));
        final double corps =
            Theme.of(ctx).textTheme.bodySmall!.fontSize! * echelle;
        final Size image = tester.getSize(find.byType(Image));
        expect(image.height, moreOrLessEquals(corps), reason: 'x$echelle');
        expect(image.width, moreOrLessEquals(corps * 4 / 3));
        // Le drapeau ne depasse pas la hauteur de la ligne de texte.
        final Size texte = tester.getSize(find.text('Mali'));
        expect(image.height, lessThanOrEqualTo(texte.height));
        // Et il est centre sur elle.
        expect(
          tester.getCenter(find.byType(Image)).dy,
          moreOrLessEquals(tester.getCenter(find.text('Mali')).dy, epsilon: 1),
        );
      }
    });

    testWidgets('en arabe, le drapeau passe de l autre cote', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _seul(const PaysEnseignant(pays: 'Guinée'), sens: TextDirection.rtl),
      );
      expect(
        tester.getCenter(find.byKey(PaysEnseignant.drapeauKey)).dx,
        greaterThan(tester.getCenter(find.text('Guinée')).dx),
      );
    });

    testWidgets('pays ecrit a la main mais reconnu : son drapeau', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _seul(const PaysEnseignant(pays: 'cote d’ivoire')),
      );
      expect(_imageDuDrapeau(tester), 'assets/flags/ci.png');
    });

    testWidgets('pays sans image (hors liste) : le nom seul, rien d autre', (
      WidgetTester tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await tester.pumpWidget(_seul(const PaysEnseignant(pays: 'Comores')));
      expect(find.text('Comores', findRichText: true), findsOneWidget);
      expect(find.byKey(PaysEnseignant.drapeauKey), findsNothing);
      expect(find.byType(Image), findsNothing);
      // Aucun autre texte que le nom (ni code, ni lettres).
      expect(find.byType(Text), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('le lecteur d ecran lit « Pays : Guinée », l image est '
        'decorative', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(_seul(const PaysEnseignant(pays: 'Guinée')));
      await _chargerImages(tester);
      expect(find.bySemanticsLabel('Pays : Guinée'), findsOneWidget);
      final Image image = tester.widget<Image>(find.byType(Image));
      expect(image.excludeFromSemantics, isTrue);
      final SemanticsNode noeud = tester.getSemantics(
        find.byKey(PaysEnseignant.ligneKey),
      );
      expect(noeud.label, 'Pays : Guinée');
      // Le noeud du pays n'a aucun enfant : l'image n'en ajoute pas.
      int enfants = 0;
      noeud.visitChildren((SemanticsNode _) {
        enfants++;
        return true;
      });
      expect(enfants, 0);
      h.dispose();
    });
  });

  group('le pays sur chaque carte recensee, pour chaque role', () {
    for (final EcranPays e in ecransPays()) {
      testWidgets('${e.role} / ${e.nom} : pays sous le nom', (
        WidgetTester tester,
      ) async {
        await _monter(tester, e);
        expect(tester.takeException(), isNull);
        await montrerPays(tester);
        expect(
          rectangleVisibleDuPays(tester, const Size(390, 844)),
          isNotNull,
          reason: '${e.nom} : la ligne du pays est visible apres defilement',
        );
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
        await montrerPays(tester);
        tester.takeException();
        expect(
          rectangleVisibleDuPays(tester, Size(320, e.hauteur320)),
          isNotNull,
          reason: '${e.nom} : la ligne du pays est visible a 320 x2',
        );
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

    // ENS-PAYS-SALLE-1 (decision Q-4 = b du 05/10) : le pays de l'enseignant
    // s'affiche sur les cartes, jamais dans la salle pendant le cours. Le
    // contexte declare pourtant « Guinée » : l'en-tete doit le taire, avec ou
    // sans photo, pour le tuteur comme pour le controleur, a 390 et 320 x2.
    for (final EcranPays e in ecransClasseLive()) {
      testWidgets('classe en direct ${e.nom} : aucun pays dans l en-tete', (
        WidgetTester tester,
      ) async {
        for (final (Size taille, double echelle) in <(Size, double)>[
          (const Size(390, 844), 1),
          (const Size(320, 700), 2),
        ]) {
          await _monter(tester, e, taille: taille, echelle: echelle);
          expect(tester.takeException(), isNull, reason: '${e.nom} $taille');
          // L'en-tete est bien la : le nom de l'enseignant s'affiche.
          expect(
            find.textContaining('Youssouf', findRichText: true),
            findsWidgets,
            reason: '${e.nom} $taille : nom de l enseignant',
          );
          expect(find.byType(PaysEnseignant), findsNothing, reason: e.nom);
          expect(find.byKey(PaysEnseignant.ligneKey), findsNothing);
          expect(find.byKey(PaysEnseignant.drapeauKey), findsNothing);
          expect(
            find.textContaining('Guinée', findRichText: true),
            findsNothing,
            reason: '${e.nom} $taille : pays absent de la salle',
          );
        }
      });
    }

    testWidgets('classe en direct, identite masquee : aucun pays', (
      WidgetTester tester,
    ) async {
      for (final bool photo in <bool>[true, false]) {
        await _monter(tester, classeLiveTuteur(photo: photo, prenom: ''));
        expect(find.byKey(PaysEnseignant.ligneKey), findsNothing);
      }
    });

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
