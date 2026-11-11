// TRANSITIONS-SALLE (directeur, 11/11/2026) : chaque transition de la salle
// a son depart, a son arrivee, en mouvement reduit et interrompue a
// mi-course ; et la preuve qu'aucune ne retarde rien.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/mouvement/panneau_glissant.dart';
import 'package:rewayah_academy/core/mouvement/passage_salle.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/entree_arche.dart';
import 'package:rewayah_academy/features/salle_seance/annonce_geste.dart';

/// Un seul theme : un theme neuf a chaque image ferait tourner
/// `AnimatedTheme` et fausserait la mesure du repos.
final ThemeData _theme = AppTheme.pour(
  InterfaceMode.standard,
  Brightness.light,
);

Widget _hote(
  Widget enfant, {
  bool reduit = false,
  Size taille = const Size(1440, 900),
}) => TranslationProvider(
  child: MaterialApp(
    theme: _theme,
    home: MediaQuery(
      data: MediaQueryData(size: taille, disableAnimations: reduit),
      child: Scaffold(body: enfant),
    ),
  ),
);

/// Laisse finir une transition de [duree] lancee a la derniere image (une
/// image de marge : le controleur demarre a l'image suivante).
Future<void> _jusquAuBout(WidgetTester tester, Duration duree) async {
  await tester.pump();
  await tester.pump(duree + const Duration(milliseconds: 16));
  await tester.pump();
}

/// La salle de l'ordinateur en miniature : un panneau de debut, la page.
class _Banc extends StatelessWidget {
  const _Banc({required this.ouvert});

  final bool ouvert;

  static const Key page = ValueKey<String>('page');
  static const Key panneau = ValueKey<String>('panneau');

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      PanneauGlissant(
        ouvert: ouvert,
        largeur: 320,
        ecart: 16,
        child: ouvert
            ? const SizedBox(key: panneau, width: 320, child: Text('Eleves'))
            : null,
      ),
      const Expanded(child: SizedBox(key: page)),
    ],
  );
}

void main() {
  group('le ressort sans rebond', () {
    test('part de 0, finit a 1, ne depasse jamais sa place', () {
      const Curve c = AppMouvement.ressortDeplacement;
      expect(c.transform(0), 0);
      expect(c.transform(1), 1);
      double avant = 0;
      for (int i = 1; i <= 100; i++) {
        final double v = c.transform(i / 100);
        expect(v, greaterThanOrEqualTo(avant), reason: 'monotone a $i %');
        expect(v, lessThanOrEqualTo(1), reason: 'aucun depassement a $i %');
        avant = v;
      }
      // Il part vite : plus de la moitie du chemin au premier quart.
      expect(c.transform(0.25), greaterThan(0.5));
    });

    test('la sortie dure les deux tiers de l entree, toutes en 150-300 ms', () {
      for (final (Duration entree, Duration sortie) in <(Duration, Duration)>[
        (AppMouvement.deplacementEntree, AppMouvement.deplacementSortie),
        (
          AppMouvement.deplacementEntreeOrdinateur,
          AppMouvement.deplacementSortieOrdinateur,
        ),
        (AppMouvement.fonduEntree, AppMouvement.fonduSortie),
      ]) {
        final double part = sortie.inMilliseconds / entree.inMilliseconds;
        expect(part, inInclusiveRange(0.6, 0.72));
        expect(entree.inMilliseconds, inInclusiveRange(200, 300));
      }
      // L'ordinateur, plus court que le telephone.
      expect(
        AppMouvement.deplacementEntreeOrdinateur,
        lessThan(AppMouvement.deplacementEntree),
      );
      expect(AppMouvement.sortieSalle.inMilliseconds, lessThanOrEqualTo(150));
      expect(
        AppMouvement.entreeArche.inMilliseconds,
        inInclusiveRange(600, 800),
      );
    });
  });

  group('PanneauGlissant (panneaux de l ordinateur)', () {
    testWidgets('rien au montage : ouvert d emblee, sans mouvement', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(const _Banc(ouvert: true)));
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.getSize(find.byKey(_Banc.panneau)).width, 320);
    });

    testWidgets('depart, arrivee : la page suit le meme ressort, sans saut', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(const _Banc(ouvert: false)));
      expect(find.byKey(_Banc.panneau), findsNothing);
      final double pleine = tester.getSize(find.byKey(_Banc.page)).width;
      await tester.pumpWidget(_hote(const _Banc(ouvert: true)));
      // Depart : la page n'a pas encore bouge.
      expect(tester.getSize(find.byKey(_Banc.page)).width, pleine);
      double avant = pleine;
      final List<double> pas = <double>[];
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 10));
        final double l = tester.getSize(find.byKey(_Banc.page)).width;
        expect(l, lessThanOrEqualTo(avant + 0.01), reason: 'jamais de retour');
        pas.add(avant - l);
        avant = l;
      }
      // Arrivee : 320 + 16 de moins, exactement.
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(_Banc.page)).width, pleine - 336);
      // Aucun saut : aucune image ne prend plus de 40 % du chemin.
      for (final double p in pas) {
        expect(p, lessThan(336 * 0.4));
      }
      // Le contenu garde sa largeur entiere pendant tout le mouvement.
      expect(tester.getSize(find.byKey(_Banc.panneau)).width, 320);
    });

    testWidgets('la fermeture est plus rapide que l ouverture', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(const _Banc(ouvert: false)));
      await tester.pumpWidget(_hote(const _Banc(ouvert: true)));
      final int ouverture = await tester.pumpAndSettle(
        const Duration(milliseconds: 10),
      );
      await tester.pumpWidget(_hote(const _Banc(ouvert: false)));
      // Pendant la fermeture, le dernier contenu reste.
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byKey(_Banc.panneau), findsOneWidget);
      final int fermeture = await tester.pumpAndSettle(
        const Duration(milliseconds: 10),
      );
      expect(fermeture, lessThan(ouverture));
      // Ferme et immobile : plus rien dans l'arbre.
      expect(find.byKey(_Banc.panneau), findsNothing);
    });

    testWidgets('interrompu a mi-course : repart de la ou il est', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(const _Banc(ouvert: false)));
      final double pleine = tester.getSize(find.byKey(_Banc.page)).width;
      await tester.pumpWidget(_hote(const _Banc(ouvert: true)));
      await tester.pump(const Duration(milliseconds: 60));
      final double mi = tester.getSize(find.byKey(_Banc.page)).width;
      expect(mi, lessThan(pleine));
      expect(mi, greaterThan(pleine - 336));
      // Nouveau geste : on referme. La page ne saute pas a une extremite.
      await tester.pumpWidget(_hote(const _Banc(ouvert: false)));
      await tester.pump(const Duration(milliseconds: 10));
      final double apres = tester.getSize(find.byKey(_Banc.page)).width;
      expect((apres - mi).abs(), lessThan(336 * 0.4));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(_Banc.page)).width, pleine);
    });

    testWidgets('mouvement reduit : la, ou pas la, sans mouvement', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(const _Banc(ouvert: false), reduit: true));
      final double pleine = tester.getSize(find.byKey(_Banc.page)).width;
      await tester.pumpWidget(_hote(const _Banc(ouvert: true), reduit: true));
      await tester.pump();
      expect(tester.getSize(find.byKey(_Banc.page)).width, pleine - 336);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('en arabe, il arrive par la droite', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: _Banc(ouvert: true),
          ),
        ),
      );
      expect(
        tester.getRect(find.byKey(_Banc.panneau)).left,
        greaterThan(tester.getRect(find.byKey(_Banc.page)).right - 0.5),
      );
    });
  });

  group('MonteeDuBas (tiroir et feuille du telephone)', () {
    const Key feuille = ValueKey<String>('feuille');
    const Key pilule = ValueKey<String>('pilule');
    Widget banc() => const Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        MonteeDuBas(child: SizedBox(key: feuille, height: 300)),
        SizedBox(key: pilule, height: 64),
      ],
    );

    testWidgets('monte de son bord, sans passer sur la pilule', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(banc(), taille: const Size(390, 844)));
      final Rect place = tester.getRect(find.byType(MonteeDuBas));
      // Depart : la feuille est sous sa place, rognee a ses bords.
      expect(tester.getRect(find.byKey(feuille)).top, greaterThan(place.top));
      expect(
        find.descendant(
          of: find.byType(MonteeDuBas),
          matching: find.byType(ClipRect),
        ),
        findsOneWidget,
      );
      // La place ne recouvre jamais la pilule.
      expect(
        place.bottom,
        lessThanOrEqualTo(tester.getRect(find.byKey(pilule)).top + 0.5),
      );
      await tester.pump(const Duration(milliseconds: 140));
      final double mi = tester.getRect(find.byKey(feuille)).top;
      expect(mi, greaterThan(place.top));
      // Arrivee : a sa place.
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(feuille)).top, place.top);
    });

    testWidgets('mouvement reduit : a sa place d emblee', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(banc(), reduit: true, taille: const Size(390, 844)),
      );
      await tester.pump();
      expect(
        tester.getRect(find.byKey(feuille)).top,
        tester.getRect(find.byType(MonteeDuBas)).top,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('PassageSalle', () {
    int touches = 0;
    Widget ecran(Object etape, {FaconPassage arrivee = FaconPassage.aucune}) =>
        PassageSalle(
          etape: etape,
          arrivee: arrivee,
          choisir: (Object avant, Object apres) =>
              avant == 'attente' && apres == 'salle'
              ? FaconPassage.voile
              : apres == 'fin'
              ? FaconPassage.fondu
              : FaconPassage.aucune,
          child: etape == 'attente'
              ? const EntreeArche()
              : Center(
                  child: ElevatedButton(
                    key: const ValueKey<String>('micro'),
                    onPressed: () => touches++,
                    child: Text('$etape'),
                  ),
                ),
        );

    testWidgets(
      'l arche passe la main : la salle recoit les gestes a la premiere image',
      (WidgetTester tester) async {
        touches = 0;
        await tester.pumpWidget(_hote(ecran('attente')));
        expect(find.byKey(EntreeArche.cle), findsOneWidget);
        // La salle est prete : une seule image.
        await tester.pumpWidget(_hote(ecran('salle')));
        expect(find.byKey(EntreeArche.cle), findsNothing);
        expect(find.byKey(PassageSalle.cleVoile), findsOneWidget);
        // Le voile ne prend aucun geste : la salle est utilisable a l'instant.
        await tester.tap(find.byKey(const ValueKey<String>('micro')));
        expect(touches, 1);
        // Arrivee : le voile est parti en 150 ms.
        await _jusquAuBout(tester, AppMouvement.passageArche);
        expect(find.byKey(PassageSalle.cleVoile), findsNothing);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets('le voile s efface a mi-course, interrompu par la sortie', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(ecran('attente')));
      await tester.pumpWidget(_hote(ecran('salle')));
      await tester.pump(const Duration(milliseconds: 70));
      final double mi = tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byKey(PassageSalle.cleVoile),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(mi, inExclusiveRange(0, 1));
      // Une sortie subie arrive pendant le voile : un fondu, sans voile.
      await tester.pumpWidget(_hote(ecran('fin')));
      expect(find.byKey(PassageSalle.cleVoile), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('fin'), findsOneWidget);
    });

    testWidgets(
      'la sortie : un fondu de 150 ms au plus, aucun moment de marque',
      (WidgetTester tester) async {
        await tester.pumpWidget(_hote(ecran('salle')));
        await tester.pumpWidget(_hote(ecran('fin')));
        expect(find.byKey(EntreeArche.cle), findsNothing);
        expect(find.byKey(PassageSalle.cleVoile), findsNothing);
        Opacity opacite() => tester.widget<Opacity>(
          find
              .ancestor(of: find.text('fin'), matching: find.byType(Opacity))
              .first,
        );
        expect(opacite().opacity, 0);
        await _jusquAuBout(tester, AppMouvement.sortieSalle);
        expect(opacite().opacity, 1);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets('retour depuis l ile : se redeplie depuis le haut, une fois', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(ecran('salle', arrivee: FaconPassage.depuisIle)),
      );
      Transform echelle() => tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(PassageSalle),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(echelle().transform.storage[0], lessThan(1));
      await tester.pumpAndSettle();
      expect(echelle().transform.storage[0], closeTo(1, 1e-9));
      // Une seconde image identique ne rejoue rien.
      await tester.pumpWidget(
        _hote(ecran('salle', arrivee: FaconPassage.depuisIle)),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('retour depuis l ile, mouvement reduit : le fondu seul', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(ecran('salle', arrivee: FaconPassage.depuisIle), reduit: true),
      );
      final Transform t0 = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(PassageSalle),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(t0.transform.storage[0], closeTo(1, 1e-9));
      await tester.pumpAndSettle();
    });
  });

  group('FonduAuChangement (d un support a l autre)', () {
    Widget zone(String cle) => FonduAuChangement(cle: cle, child: Text(cle));
    FadeTransition fondu(WidgetTester tester) => tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(FonduAuChangement),
        matching: find.byType(FadeTransition),
      ),
    );

    testWidgets('rien au montage, un fondu court au changement', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(zone('coran')));
      expect(tester.hasRunningAnimations, isFalse);
      expect(fondu(tester).opacity.value, 1);
      await tester.pumpWidget(_hote(zone('tableau')));
      expect(fondu(tester).opacity.value, 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(fondu(tester).opacity.value, inExclusiveRange(0, 1));
      // Interrompu : un autre support repart de zero, sans superposition.
      await tester.pumpWidget(_hote(zone('coran')));
      expect(find.text('tableau'), findsNothing);
      expect(fondu(tester).opacity.value, 0);
      await tester.pumpAndSettle();
      expect(fondu(tester).opacity.value, 1);
    });

    testWidgets('mouvement reduit : aucun fondu', (WidgetTester tester) async {
      await tester.pumpWidget(_hote(zone('coran'), reduit: true));
      await tester.pumpWidget(_hote(zone('tableau'), reduit: true));
      expect(fondu(tester).opacity.value, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('EntreeArche', () {
    testWidgets('la porte s ouvre une fois, puis tout reste immobile', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(const EntreeArche()));
      expect(tester.hasRunningAnimations, isTrue);
      await _jusquAuBout(tester, AppMouvement.entreeArche);
      // Aucune boucle : rien ne bouge pendant qu'on attend.
      expect(tester.hasRunningAnimations, isFalse);
      // Decorative : ni geste, ni lecteur d'ecran.
      expect(
        find.ancestor(
          of: find.byKey(EntreeArche.cle),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
      );
    });

    testWidgets('mouvement reduit : l image finale en un fondu court', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(const EntreeArche(), reduit: true));
      await _jusquAuBout(tester, AppMouvement.fonduEntree);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('retiree a mi-course (salle prete) : rien ne reste', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(const EntreeArche()));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpWidget(_hote(const Text('salle')));
      expect(find.byKey(EntreeArche.cle), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('annonces de tete', () {
    Widget couche(AnnonceGeste? a) =>
        CoucheAnnonceGeste(annonce: a, child: const SizedBox.expand());
    const AnnonceGeste appel = AnnonceGeste(
      titre: 'Votre enseignant vous appelle',
      message: 'Ouvrez votre micro.',
    );
    FractionalTranslation glisse(WidgetTester tester) =>
        tester.widget<FractionalTranslation>(
          find
              .ancestor(
                of: find.byKey(CoucheAnnonceGeste.cle),
                matching: find.byType(FractionalTranslation),
              )
              .first,
        );

    testWidgets('entre par le haut, sort en fondu, plus vite', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(couche(null)));
      await tester.pumpWidget(_hote(couche(appel)));
      // Depart : au-dessus de sa place.
      expect(glisse(tester).translation.dy, lessThan(0));
      await tester.pump(const Duration(milliseconds: 140));
      final double mi = glisse(tester).translation.dy;
      expect(mi, inExclusiveRange(-AppMouvement.glisseAnnonce, 0));
      final int entree = await tester.pumpAndSettle(
        const Duration(milliseconds: 10),
      );
      expect(glisse(tester).translation.dy, 0);
      // Sortie : en fondu, sans glisser.
      await tester.pumpWidget(_hote(couche(null)));
      await tester.pump(const Duration(milliseconds: 20));
      expect(glisse(tester).translation.dy, 0);
      final int sortie = await tester.pumpAndSettle(
        const Duration(milliseconds: 10),
      );
      // La sortie (190 ms) finit avant l'entree (280 ms : 140 + le reste).
      expect(sortie, lessThan(14 + entree));
      expect(find.byKey(CoucheAnnonceGeste.cle), findsNothing);
    });

    testWidgets('mouvement reduit : l annonce est la, sans mouvement', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_hote(couche(null), reduit: true));
      await tester.pumpWidget(_hote(couche(appel), reduit: true));
      await tester.pump();
      expect(find.byKey(CoucheAnnonceGeste.cle), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
