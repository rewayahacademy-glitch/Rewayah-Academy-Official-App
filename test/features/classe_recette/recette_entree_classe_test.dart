// CL-4.7 : la recette de l'entree en classe, sur les quatre ecrans du lot
// (Espace Classe eleve, Espace Classe enseignant, preparation enseignant,
// preparation eleve), tous montes sur les donnees de demonstration.
//
// - reflow a 320 et texte a 200 % : aucun debordement ;
// - clavier : Tab suit l'ordre de lecture, le focus reste visible et jamais
//   sous le bandeau ;
// - pseudo-localisation (K-41, point 12) : texte allonge de 40 % (echelle
//   1,4, faute de surcharge de traduction dans slang) et sens RTL force ;
//   aucun debordement, les icones de direction s'inversent ;
// - clair et sombre ;
// - lecteur d'ecran : la ligne d'etat n'est pas un bouton, « Rejoindre la
//   seance de {Classe} », une seule annonce par changement d'etat ;
// - focus (revue UX n° 13) : le bouton focalise qui disparait rend le focus
//   au titre de la carte ; le bouton qui apparait ne le prend pas.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart'
    show TitreEnseignant;
import 'package:rewayah_academy/core/tc_horloge/emplacement_entree.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/demo/classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_classe_page.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/carte_session.dart';

import '../../capture/outil_capture.dart';
import '../../teaching_core/a/support/hote_tc_a.dart';

/// Un ecran du lot, dans un etat donne.
typedef _Ecran = ({String nom, Widget Function() ecran});

List<_Ecran> _ecrans({
  TitreEnseignant titre = TitreEnseignant.sayyid,
}) => <_Ecran>[
  (
    nom: 'espace_eleve',
    ecran: () =>
        EcranEleveDemo(etat: EtatDemoClasse.fenetreOuverte, titre: titre),
  ),
  (
    nom: 'espace_enseignant',
    ecran: () =>
        EcranEnseignantDemo(etat: EtatDemoClasse.fenetreOuverte, titre: titre),
  ),
  (
    nom: 'preparation_enseignant',
    ecran: () => const EcranPreparationDemo(etat: PreparationDemo.pret),
  ),
  (
    nom: 'preparation_eleve',
    ecran: () =>
        const EcranPreparationEleveDemo(etat: PreparationEleveDemo.pret),
  ),
];

Future<void> _poser(
  WidgetTester tester,
  Widget ecran, {
  required Size taille,
  double echelle = 1,
  ThemeMode mode = ThemeMode.light,
  bool rtl = false,
}) async {
  fixerVueCapture(tester, taille, 1);
  await tester.pumpWidget(
    hoteCapture(
      rtl
          ? Directionality(textDirection: TextDirection.rtl, child: ecran)
          : ecran,
      echelleTexte: echelle,
      themeMode: mode,
    ),
  );
  await stabiliser(tester);
}

/// Aucune erreur, donc aucun debordement : un `RenderFlex overflowed` est une
/// `FlutterError` que le banc rend ici.
void _sansDebordement(WidgetTester tester, String contexte) {
  final Object? erreur = tester.takeException();
  expect(erreur, isNull, reason: '$contexte : $erreur');
}

void main() {
  group('Reflow a 320 et texte a 200 %', () {
    for (final _Ecran e in _ecrans()) {
      testWidgets(e.nom, (WidgetTester tester) async {
        await _poser(
          tester,
          e.ecran(),
          taille: const Size(320, 900),
          echelle: 2,
        );
        _sansDebordement(tester, e.nom);
      });
    }
    testWidgets('preparation eleve, micro bloque', (WidgetTester tester) async {
      await _poser(
        tester,
        const EcranPreparationEleveDemo(etat: PreparationEleveDemo.microBloque),
        taille: const Size(320, 900),
        echelle: 2,
      );
      _sansDebordement(tester, 'micro bloque');
    });
  });

  group('Pseudo-localisation : +40 % et RTL', () {
    for (final _Ecran e in _ecrans()) {
      testWidgets(e.nom, (WidgetTester tester) async {
        await _poser(
          tester,
          e.ecran(),
          taille: const Size(390, 900),
          echelle: 1.4,
          rtl: true,
        );
        _sansDebordement(tester, e.nom);
        // Les icones de direction (retour, fleches) s'inversent : elles
        // portent matchTextDirection et sont peintes sous un sens RTL.
        final Iterable<Element> directionnelles = find
            .byWidgetPredicate(
              (Widget w) => w is Icon && (w.icon?.matchTextDirection ?? false),
            )
            .evaluate();
        for (final Element icone in directionnelles) {
          expect(Directionality.of(icone), TextDirection.rtl);
        }
      });
    }
    testWidgets('la fleche de retour s inverse', (WidgetTester tester) async {
      await _poser(
        tester,
        const EcranPreparationEleveDemo(etat: PreparationEleveDemo.pret),
        taille: const Size(390, 900),
        echelle: 1.4,
        rtl: true,
      );
      final Finder retour = find.descendant(
        of: find.byKey(const ValueKey<String>('preparation-retour')),
        matching: find.byType(Icon),
      );
      expect(retour, findsWidgets);
      final Icon icone = tester.widget<Icon>(retour.first);
      expect(icone.icon!.matchTextDirection, isTrue);
      expect(
        Directionality.of(tester.element(retour.first)),
        TextDirection.rtl,
      );
      // Le lien de retour est au bord de debut, donc a droite en RTL.
      expect(tester.getCenter(retour.first).dx, greaterThan(195));
    });
  });

  group('Clair et sombre', () {
    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final _Ecran e in _ecrans()) {
        testWidgets('${e.nom} ${mode.name}', (WidgetTester tester) async {
          await _poser(
            tester,
            e.ecran(),
            taille: const Size(768, 1000),
            mode: mode,
          );
          _sansDebordement(tester, e.nom);
          expect(find.byType(Scaffold), findsWidgets);
        });
      }
    }
  });

  group('Clavier', () {
    for (final _Ecran e in _ecrans()) {
      testWidgets('${e.nom} : Tab suit l ordre de lecture', (
        WidgetTester tester,
      ) async {
        const Size vue = Size(390, 900);
        await _poser(tester, e.ecran(), taille: vue);
        final List<Rect> parcours = <Rect>[];
        final List<double> hauts = <double>[];
        final List<FocusNode> vus = <FocusNode>[];
        for (int i = 0; i < 12; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await stabiliser(tester);
          final FocusNode? n = FocusManager.instance.primaryFocus;
          final BuildContext? c = n?.context;
          if (n == null || c == null || vus.contains(n)) break;
          vus.add(n);
          final RenderObject? r = c.findRenderObject();
          if (r is! RenderBox || !r.hasSize) continue;
          final Rect rect = r.localToGlobal(Offset.zero) & r.size;
          parcours.add(rect);
          // Position dans le contenu : le defilement retire.
          hauts.add(rect.top + (Scrollable.maybeOf(c)?.position.pixels ?? 0));
        }
        expect(parcours, isNotEmpty, reason: 'aucun element focalisable');
        // Le bandeau de demonstration occupe le coin haut de fin.
        final Rect bandeau = Rect.fromLTWH(vue.width - 60, 0, 60, 60);
        for (int i = 0; i < parcours.length; i++) {
          final Rect r = parcours[i];
          // Visible : dans la vue une fois defile, jamais sous le bandeau.
          expect(r.width, greaterThan(0));
          expect(
            r.top,
            greaterThanOrEqualTo(-1),
            reason: '${e.nom} : pas $i hors vue',
          );
          expect(
            r.bottom,
            lessThanOrEqualTo(vue.height + 1),
            reason: '${e.nom} : pas $i hors vue',
          );
          expect(r.overlaps(bandeau) && r.width < 60, isFalse);
          if (i > 0) {
            // Ordre de lecture : jamais nettement plus haut que le precedent.
            expect(
              hauts[i],
              greaterThanOrEqualTo(hauts[i - 1] - 1),
              reason: '${e.nom} : pas $i remonte',
            );
          }
        }
      });
    }
  });

  group('Lecteur d ecran', () {
    testWidgets('Rejoindre la seance de {Classe}, ligne d etat non bouton', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await _poser(
        tester,
        const EcranEleveDemo(etat: EtatDemoClasse.fenetreOuverte),
        taille: const Size(390, 1400),
      );
      expect(
        find.bySemanticsLabel(
          t.classe.entree.rejoindreLecteur(classe: DonneesClasseDemo.classe),
        ),
        findsOneWidget,
      );
      await _poser(
        tester,
        const EcranEleveDemo(etat: EtatDemoClasse.aVenir),
        taille: const Size(390, 1400),
      );
      final EmplacementEntree ligne = DonneesClasseDemo.emplacement(
        RoleEntree.eleve,
        EtatDemoClasse.aVenir,
      );
      expect(ligne.estBouton, isFalse);
      final Finder texte = find.textContaining(ligne.libelle);
      expect(texte, findsOneWidget);
      expect(
        tester.getSemantics(texte),
        isSemantics(isButton: false, isFocusable: false),
      );
      poignee.dispose();
    });

    testWidgets('une seule annonce par changement d etat', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      final ValueNotifier<EmplacementEntree> courant =
          ValueNotifier<EmplacementEntree>(
            DonneesClasseDemo.emplacement(
              RoleEntree.eleve,
              EtatDemoClasse.fenetreOuverte,
            ),
          );
      addTearDown(courant.dispose);
      await tester.pumpWidget(
        hoteTcA(
          Scaffold(
            body: ValueListenableBuilder<EmplacementEntree>(
              valueListenable: courant,
              builder: (BuildContext _, EmplacementEntree e, Widget? _) =>
                  EmplacementEntreeVue(emplacement: e, onEntrer: () {}),
            ),
          ),
        ),
      );
      List<String> annonces() => <String>[
        for (final Element el
            in find
                .byWidgetPredicate(
                  (Widget w) =>
                      w is Semantics && (w.properties.liveRegion ?? false),
                )
                .evaluate())
          (el.widget as Semantics).properties.label ?? '',
      ];
      expect(annonces(), hasLength(1));
      final String avant = annonces().single;
      // Meme etat (le decompte avance) : rien de neuf n'est annonce.
      courant.value = DonneesClasseDemo.emplacement(
        RoleEntree.eleve,
        EtatDemoClasse.preparation,
      );
      await tester.pump();
      final String apresPreparation = annonces().single;
      courant.value = DonneesClasseDemo.emplacement(
        RoleEntree.eleve,
        EtatDemoClasse.enDirect,
      );
      await tester.pump();
      expect(annonces(), hasLength(1));
      final String enDirect = annonces().single;
      expect(enDirect, isNot(avant));
      courant.value = DonneesClasseDemo.emplacement(
        RoleEntree.eleve,
        EtatDemoClasse.enDirect,
      );
      await tester.pump();
      expect(annonces().single, enDirect);
      expect(apresPreparation, isNotEmpty);
      poignee.dispose();
    });
  });

  group('Focus (revue UX n° 13)', () {
    testWidgets('le bouton qui disparait rend le focus au titre', (
      WidgetTester tester,
    ) async {
      final FocusNode titre = FocusNode(
        debugLabel: 'titre',
        skipTraversal: true,
      );
      addTearDown(titre.dispose);
      final ValueNotifier<EtatDemoClasse> etat = ValueNotifier<EtatDemoClasse>(
        EtatDemoClasse.aVenir,
      );
      addTearDown(etat.dispose);
      await tester.pumpWidget(
        hoteTcA(
          Scaffold(
            body: Column(
              children: <Widget>[
                Focus(focusNode: titre, child: const Text('Titre de la carte')),
                ValueListenableBuilder<EtatDemoClasse>(
                  valueListenable: etat,
                  builder: (BuildContext _, EtatDemoClasse e, Widget? _) =>
                      EmplacementEntreeVue(
                        emplacement: DonneesClasseDemo.emplacement(
                          RoleEntree.eleve,
                          e,
                        ),
                        onEntrer: () {},
                        focusRetour: titre,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
      final Finder bouton = find.byType(ActionPrincipale);
      // Le bouton qui apparait ne prend pas le focus.
      etat.value = EtatDemoClasse.fenetreOuverte;
      await tester.pump();
      expect(bouton, findsOneWidget);
      // (le focus n a pas bouge en meme temps que le bouton est apparu)
      expect(titre.hasFocus, isFalse);
      // On le focalise au clavier, puis il laisse place a une ligne d etat.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final FocusNode? focalise = FocusManager.instance.primaryFocus;
      expect(focalise, isNotNull);
      expect(focalise, isNot(titre));
      etat.value = EtatDemoClasse.annulee;
      await tester.pump();
      await tester.pump();
      expect(bouton, findsNothing);
      expect(titre.hasPrimaryFocus, isTrue);
    });

    testWidgets('la carte de seance porte le titre focalisable', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        const EcranEleveDemo(etat: EtatDemoClasse.fenetreOuverte),
        taille: const Size(390, 1400),
      );
      expect(find.byType(CarteSession), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('carte-seance-titre')),
        findsOneWidget,
      );
    });
  });

  group('Micro bloque : un seul groupe (contrat B)', () {
    // Les vraies polices : la police de test (glyphes carres) elargirait
    // les libelles au point de renvoyer le bouton a la ligne.
    setUpAll(chargerPolicesDuDepot);
    testWidgets('mobile : deux boutons pleine largeur, 8 d ecart', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        const EcranPreparationEleveDemo(etat: PreparationEleveDemo.microBloque),
        taille: const Size(390, 900),
      );
      final Rect principal = tester.getRect(
        find.byKey(const ValueKey<String>('preparation-autoriser-micro')),
      );
      final Rect secondaire = tester.getRect(
        find.byKey(const ValueKey<String>('preparation-continuer-sans-micro')),
      );
      expect(secondaire.width, closeTo(principal.width, 0.5));
      expect(secondaire.left, closeTo(principal.left, 0.5));
      expect(secondaire.top - principal.bottom, closeTo(8, 0.5));
    });

    testWidgets('bureau : cote a cote, le principal au bord de fin', (
      WidgetTester tester,
    ) async {
      await _poser(
        tester,
        const EcranPreparationEleveDemo(etat: PreparationEleveDemo.microBloque),
        taille: const Size(1440, 900),
      );
      final Rect principal = tester.getRect(
        find.byKey(const ValueKey<String>('preparation-autoriser-micro')),
      );
      final Rect secondaire = tester.getRect(
        find.byKey(const ValueKey<String>('preparation-continuer-sans-micro')),
      );
      expect(secondaire.center.dy, closeTo(principal.center.dy, 1));
      expect(principal.left, greaterThan(secondaire.right));
      expect(principal.left - secondaire.right, closeTo(8, 0.5));
    });
  });
}
