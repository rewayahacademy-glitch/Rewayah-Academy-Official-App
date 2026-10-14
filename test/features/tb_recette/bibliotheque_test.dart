// TB-8 (LIB-01 a LIB-04 ; plan V2 §3, §12, §19.1, UX-17) : la Bibliotheque
// en seance.
//
// Une seule bibliotheque (R14 : SurfaceBibliotheque) ; choisir une carte
// ouvre un apercu personnel, la classe garde le support actuel jusqu'a
// « Presenter » (UX-17) ; Presenter verifie le chargement ; un fichier non
// charge ne remplace jamais le support (LIB-03) ; recherche sans resultat
// et retour (LIB-04).
//
// Revue du 09/10 : « Revenir aux supports » pendant l'ouverture n'active
// rien ; « Presenter » est dans la vue de la feuille sans la faire defiler
// (390 x1 et x2, 320 x2) ; apres un echec, le titre du message et
// « Reessayer » sont visibles ensemble, au texte x2 aussi. Mesure : les
// rectangles rendus et le toucher (hit test) aux coins, jamais le code.

import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/bibliotheque_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_catalogue/surface_bibliotheque.dart';

import '../../capture/outil_capture.dart' hide stabiliser;
import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

final Finder _bibliotheque = find.byType(BibliothequeSeance);
final Finder _catalogue = find.byType(SurfaceBibliotheque);
final Finder _apercu = find.byKey(BibliothequeSeance.cleApercu);
final Finder _presenter = find.byKey(BibliothequeSeance.clePresenter);
final Finder _revenir = find.byKey(BibliothequeSeance.cleRevenir);
final Finder _echec = find.byKey(BibliothequeSeance.cleEchec);
final Finder _titreEchec = find.byKey(BibliothequeSeance.cleTitreEchec);
final Finder _feuille = find.byKey(
  const ValueKey<String>('panneau-seance-feuille'),
);

Future<void> _monter(
  WidgetTester tester, {
  Size taille = _bureau,
  RoleSeance role = RoleSeance.enseignant,
  SituationTb situation = SituationTb.lib01,
}) async {
  fixerVueCapture(tester, taille, 1);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(DemoSallePage(role: role, situation: situation)),
  );
  await tester.pumpAndSettle();
}

/// Monte la salle au cadrage des captures (zone sure du telephone a 390,
/// texte agrandi), comme `captures_tb_test` (tb8_).
Future<void> _monterCadre(
  WidgetTester tester, {
  required Size taille,
  required double texte,
}) async {
  fixerVueCapture(
    tester,
    taille,
    2,
    zoneSure: taille.width == 390
        ? const EdgeInsets.only(top: 47, bottom: 34)
        : EdgeInsets.zero,
  );
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      const DemoSallePage(
        role: RoleSeance.enseignant,
        situation: SituationTb.lib01,
      ),
      echelleTexte: texte,
    ),
  );
  await tester.pumpAndSettle();
}

/// [cible] est dans la vue et sous le doigt : ses quatre coins (a 2 px du
/// bord) et son centre touchent [cible] elle-meme, rien ne la couvre ni ne
/// la rogne (bord de la feuille, defilement, barre de l'appel, ecran).
void _attendreDansLaVue(WidgetTester tester, Finder cible, String quoi) {
  final Rect r = tester.getRect(cible);
  final RenderObject objet = tester.renderObject(cible);
  final Rect ecran =
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
  for (final Offset point in <Offset>[
    r.topLeft + const Offset(2, 2),
    r.topRight + const Offset(-2, 2),
    r.bottomLeft + const Offset(2, -2),
    r.bottomRight + const Offset(-2, -2),
    r.center,
  ]) {
    expect(ecran.contains(point), isTrue, reason: '$quoi hors ecran ($r)');
    final HitTestResult touche = tester.hitTestOnBinding(point);
    expect(
      touche.path.any((HitTestEntry e) => identical(e.target, objet)),
      isTrue,
      reason: '$quoi : le point $point de $r ne la touche pas (hors vue)',
    );
  }
}

Future<void> _taper(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// La carte d'un support dans le catalogue.
Finder _carte(String titre) =>
    find.descendant(of: _catalogue, matching: find.text(titre)).first;

/// Le catalogue defile en slivers (cartes construites a la demande) :
/// descend jusqu'a la carte avant de la toucher ou de la compter.
Future<Finder> _versCarte(WidgetTester tester, String titre) async {
  await tester.scrollUntilVisible(
    find.descendant(of: _catalogue, matching: find.text(titre)),
    120,
    scrollable: find
        .descendant(of: _catalogue, matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
  return _carte(titre);
}

/// Le titre ecrit sur la page presentee a la classe.
Finder _pageAvecTitre(String titre) => find.descendant(
  of: find.byKey(SurfacePageFixe.clePage),
  matching: find.text(titre),
);

const String _titreInitial = 'Les bonnes manières';
const String _autre = 'Fiche de mémorisation';
const String _indisponible = "Cahier d'écriture";

void main() {
  test('la Bibliotheque en seance ne touche jamais la connexion', () {
    // Comme ClassLibraryPicker : aucun import de core/video, donc aucun
    // moyen d'appeler disconnect ni de voir la Room.
    final List<String> imports = File(
      'lib/features/salle_seance/bibliotheque_seance.dart',
    ).readAsLinesSync().where((String l) => l.startsWith('import ')).toList();
    expect(imports, isNotEmpty);
    for (final String ligne in imports) {
      expect(ligne.contains('core/video'), isFalse, reason: ligne);
      expect(ligne.contains('livekit'), isFalse, reason: ligne);
    }
  });

  for (final Size taille in <Size>[_telephone, _bureau]) {
    final String cas = '${taille.width.toInt()}';

    testWidgets('LIB-01 : la Bibliotheque unique, ses supports ($cas)', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: taille);
      expect(tester.takeException(), isNull);
      expect(_bibliotheque, findsOneWidget);
      expect(_catalogue, findsOneWidget);
      expect(find.text(t.salle.seance.bibliotheque.intro), findsOneWidget);
      expect(await _versCarte(tester, _autre), findsOneWidget);
      expect(await _versCarte(tester, _indisponible), findsOneWidget);
    });

    testWidgets('UX-17 : l\'apercu est personnel, la classe garde son '
        'support jusqu\'a Presenter ($cas)', (WidgetTester tester) async {
      await _monter(tester, taille: taille);
      expect(_pageAvecTitre(_titreInitial), findsOneWidget);
      await _taper(tester, await _versCarte(tester, _autre));
      expect(_apercu, findsOneWidget);
      expect(find.text(t.salle.seance.bibliotheque.apercu), findsOneWidget);
      expect(
        find.text(t.salle.seance.bibliotheque.apercuClasse),
        findsOneWidget,
      );
      // Rien n'a change pour la classe.
      expect(_pageAvecTitre(_titreInitial), findsOneWidget);
      expect(_pageAvecTitre(_autre), findsNothing);
      await _taper(tester, _presenter);
      expect(tester.takeException(), isNull);
      // Presente : la page change, le panneau se ferme.
      expect(_pageAvecTitre(_autre), findsOneWidget);
      expect(_pageAvecTitre(_titreInitial), findsNothing);
      expect(_bibliotheque, findsNothing);
    });

    testWidgets('LIB-03 : un fichier non charge ne remplace jamais le '
        'support ($cas)', (WidgetTester tester) async {
      await _monter(tester, taille: taille);
      await _taper(tester, await _versCarte(tester, _indisponible));
      await _taper(tester, _presenter);
      expect(tester.takeException(), isNull);
      expect(_echec, findsOneWidget);
      expect(find.text(t.salle.seance.bibliotheque.echec), findsOneWidget);
      expect(
        find.text(t.salle.seance.bibliotheque.echecDetail),
        findsOneWidget,
      );
      // Le titre du message et « Reessayer » sont visibles ensemble, au
      // pied de la feuille, au-dessus de la barre de l'appel.
      _attendreDansLaVue(tester, _titreEchec, 'le titre du message');
      _attendreDansLaVue(tester, _presenter, 'Reessayer');
      verifierUnSeulBoutonPlein(tester);
      verifierSansChevauchement(tester, <Finder>[_titreEchec, _presenter]);
      // La classe garde le support d'avant ; Reessayer, et le retour.
      expect(_pageAvecTitre(_titreInitial), findsOneWidget);
      expect(
        find.descendant(
          of: _presenter,
          matching: find.text(t.commun.reessayer),
        ),
        findsOneWidget,
      );
      await _taper(tester, _presenter);
      expect(_echec, findsOneWidget);
      expect(_pageAvecTitre(_titreInitial), findsOneWidget);
      await _taper(tester, _revenir);
      expect(_catalogue, findsOneWidget);
      expect(_echec, findsNothing);
    });
  }

  testWidgets('LIB-03 : « Ouverture du support… » pendant le chargement', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _taper(tester, await _versCarte(tester, _autre));
    await tester.ensureVisible(_presenter);
    await tester.pumpAndSettle();
    await tester.tap(_presenter);
    // Un seul cadre : le chargement n'est pas encore termine.
    await tester.pump();
    expect(find.text(t.salle.seance.bibliotheque.ouverture), findsOneWidget);
    expect(_pageAvecTitre(_titreInitial), findsOneWidget);
    await tester.pumpAndSettle();
    expect(_pageAvecTitre(_autre), findsOneWidget);
  });

  testWidgets('Revenir aux supports pendant l\'ouverture : rien n\'est '
      'presente, meme quand le chargement aboutit ensuite', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _taper(tester, await _versCarte(tester, _autre));
    await tester.tap(_presenter);
    // Un seul cadre : « Ouverture du support... », le chargement court.
    await tester.pump();
    expect(find.text(t.salle.seance.bibliotheque.ouverture), findsOneWidget);
    await tester.tap(_revenir);
    // Le chargement se termine apres le retour.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_catalogue, findsOneWidget);
    expect(_bibliotheque, findsOneWidget);
    // La classe garde son support : le futur termine n'a rien active.
    expect(_pageAvecTitre(_titreInitial), findsOneWidget);
    expect(_pageAvecTitre(_autre), findsNothing);
  });

  testWidgets('Revenir pendant une ouverture qui echoue : le catalogue, '
      'aucun echec d\'un support abandonne', (WidgetTester tester) async {
    await _monter(tester);
    await _taper(tester, await _versCarte(tester, _indisponible));
    await tester.tap(_presenter);
    await tester.pump();
    await tester.tap(_revenir);
    await tester.pumpAndSettle();
    expect(_catalogue, findsOneWidget);
    expect(_echec, findsNothing);
    expect(_pageAvecTitre(_titreInitial), findsOneWidget);
  });

  testWidgets('un chargement termine apres le retour n\'active rien, ni ne '
      'montre d\'echec sur le support choisi ensuite', (
    WidgetTester tester,
  ) async {
    // La Bibliotheque seule, avec un chargement que le test tient : la
    // demonstration se charge en un tour de boucle, trop vite pour revenir
    // ET choisir une autre carte avant la fin.
    final List<Completer<VoidCallback>> chargements =
        <Completer<VoidCallback>>[];
    int activations = 0;
    fixerVueCapture(tester, _bureau, 1);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        Scaffold(
          body: BibliothequeSeance(
            groupeId: DonneesSeanceDemo.groupeDemo,
            onPresenter: (LibraryResource r, ContentPosition? p) {
              final Completer<VoidCallback> c = Completer<VoidCallback>();
              chargements.add(c);
              return c.future;
            },
          ),
        ),
        surcharges: <Override>[
          donneesCatalogueProvider(DonneesSeanceDemo.groupeDemo).overrideWith(
            (Ref _) => lireDonneesCatalogue(
              catalogue: DonneesSeanceDemo.catalogueTb,
              offline: DonneesSeanceDemo.etatOfflineTb,
              groupeId: DonneesSeanceDemo.groupeDemo,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    // 1. Presenter, revenir, puis le chargement aboutit : rien n'est active.
    await _taper(tester, await _versCarte(tester, _autre));
    await _taper(tester, _presenter);
    expect(find.text(t.salle.seance.bibliotheque.ouverture), findsOneWidget);
    await _taper(tester, _revenir);
    chargements.last.complete(() => activations++);
    await tester.pumpAndSettle();
    expect(activations, 0);
    expect(_catalogue, findsOneWidget);
    // 2. Presenter un support qui echouera, revenir, choisir un autre
    // support, puis l'ancien chargement echoue : aucun echec sur le nouveau.
    await _taper(tester, await _versCarte(tester, _indisponible));
    await _taper(tester, _presenter);
    await _taper(tester, _revenir);
    await _taper(tester, await _versCarte(tester, _autre));
    chargements.last.completeError(StateError('fichier absent'));
    await tester.pumpAndSettle();
    expect(_echec, findsNothing);
    expect(
      find.descendant(
        of: _presenter,
        matching: find.text(t.salle.seance.bibliotheque.presenter),
      ),
      findsOneWidget,
    );
    // 3. Le chargement en cours, lui, active bien.
    await _taper(tester, _presenter);
    chargements.last.complete(() => activations++);
    await tester.pumpAndSettle();
    expect(activations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LIB-04 : recherche sans resultat, puis tout afficher', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await tester.enterText(
      find.descendant(of: _catalogue, matching: find.byType(TextField)),
      'zzzz',
    );
    await tester.pumpAndSettle();
    expect(find.text(t.tc.bibliotheque.aucunResultat.message), findsOneWidget);
    await _taper(
      tester,
      find
          .descendant(
            of: _catalogue,
            matching: find.text(t.tc.bibliotheque.effacerRecherche),
          )
          .last,
    );
    expect(find.text(t.tc.bibliotheque.aucunResultat.message), findsNothing);
    expect(await _versCarte(tester, _autre), findsOneWidget);
  });

  testWidgets('Revenir aux supports depuis l\'apercu : rien n\'est presente', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _taper(tester, await _versCarte(tester, _autre));
    await _taper(tester, _revenir);
    expect(_catalogue, findsOneWidget);
    expect(_pageAvecTitre(_titreInitial), findsOneWidget);
  });

  testWidgets('eleve : aucune Bibliotheque (TB14)', (
    WidgetTester tester,
  ) async {
    await _monter(tester, role: RoleSeance.eleve, situation: SituationTb.ped03);
    expect(_bibliotheque, findsNothing);
    expect(_catalogue, findsNothing);
  });

  testWidgets('K-07 : Commandes > Bibliotheque depuis la vraie coquille', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await monterRouteur(
      tester,
      Routes.demoSalle,
      taille: _bureau,
    );
    final Finder lien = find.byKey(
      ValueKey<String>(
        'lien-${RoleSeance.enseignant.name}-tb-${SituationTb.cmd01.name}',
      ),
    );
    await tester.ensureVisible(lien);
    await tester.pump();
    await tester.tap(lien);
    await stabiliser(tester);
    expect(
      lieu(routeur),
      adresseDemoSalleTb(RoleSeance.enseignant, SituationTb.cmd01),
    );
    await _taper(tester, find.byKey(CommandesPedagogiques.cleBibliotheque));
    expect(_bibliotheque, findsOneWidget);
    await _taper(tester, await _versCarte(tester, _autre));
    await _taper(tester, _presenter);
    expect(_pageAvecTitre(_autre), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Revue du 09/10 : a la largeur du telephone, l'action est dans la vue de
  // la feuille sans defiler, et apres un echec le titre du message et
  // « Reessayer » se voient ensemble. Polices du depot : les memes lignes
  // que les captures tb8_.
  group('TB-8 : l\'action et l\'echec dans la vue du telephone', () {
    setUpAll(chargerPolicesDuDepot);
    for (final (Size taille, double texte) in <(Size, double)>[
      (const Size(390, 844), 1),
      (const Size(390, 844), 2),
      (const Size(320, 700), 2),
    ]) {
      final String cas = '${taille.width.toInt()} x${texte.toInt()}';

      testWidgets('LIB-02 : Presenter est dans la vue de la feuille, sans '
          'defiler ($cas)', (WidgetTester tester) async {
        await _monterCadre(tester, taille: taille, texte: texte);
        await tester.tap(await _versCarte(tester, _autre));
        await tester.pumpAndSettle();
        expect(_apercu, findsOneWidget);
        expect(_feuille, findsOneWidget);
        // Aucun ensureVisible : la feuille telle qu'elle s'ouvre.
        final Rect feuille = tester.getRect(_feuille);
        final Rect bouton = tester.getRect(_presenter);
        expect(bouton.top, greaterThanOrEqualTo(feuille.top - 0.5));
        expect(bouton.bottom, lessThanOrEqualTo(feuille.bottom + 0.5));
        _attendreDansLaVue(tester, _presenter, 'Presenter');
        verifierUnSeulBoutonPlein(tester);
        // Le retour part du bord du contenu, comme « Apercu personnel »
        // (revue : 4 px de decalage), sa fleche en tete.
        expect(
          tester
              .getRect(
                find.descendant(of: _revenir, matching: find.byType(Icon)),
              )
              .left,
          closeTo(
            tester.getRect(find.text(t.salle.seance.bibliotheque.apercu)).left,
            0.5,
          ),
        );
        // Le doigt l'atteint tel quel : le support est presente.
        await tester.tap(_presenter);
        await tester.pumpAndSettle();
        expect(_pageAvecTitre(_autre), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      // Verification TB-8 : a 320 x2, la vue de l'apercu ne fait qu'environ
      // 51 px et le message d'ouverture y etait coupe (« Ouverture du »).
      // Le message entier est dans la vue, sous le doigt, sans defiler.
      testWidgets('LIB-03 : « Ouverture du support… » se lit entier pendant '
          'le chargement ($cas)', (WidgetTester tester) async {
        await _monterCadre(tester, taille: taille, texte: texte);
        await tester.tap(await _versCarte(tester, _autre));
        await tester.pumpAndSettle();
        await tester.tap(_presenter);
        // Un seul cadre, puis celui du defilement eventuel : le chargement
        // court encore.
        await tester.pump();
        await tester.pump();
        final Finder message = find.text(t.salle.seance.bibliotheque.ouverture);
        expect(message, findsOneWidget);
        _attendreDansLaVue(tester, message, 'le message d\'ouverture');
        final Rect feuille = tester.getRect(_feuille);
        final Rect rect = tester.getRect(message);
        expect(rect.top, greaterThanOrEqualTo(feuille.top - 0.5));
        expect(rect.bottom, lessThanOrEqualTo(feuille.bottom + 0.5));
        final RenderParagraph texteRendu = tester.renderObject(message);
        expect(texteRendu.didExceedMaxLines, isFalse);
        verifierUnSeulBoutonPlein(tester);
        await tester.pumpAndSettle();
        expect(_pageAvecTitre(_autre), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('LIB-03 : apres un echec, le titre du message et '
          'Reessayer sont visibles ensemble ($cas)', (
        WidgetTester tester,
      ) async {
        await _monterCadre(tester, taille: taille, texte: texte);
        await tester.tap(await _versCarte(tester, _indisponible));
        await tester.pumpAndSettle();
        await tester.tap(_presenter);
        await tester.pumpAndSettle();
        expect(_echec, findsOneWidget);
        _attendreDansLaVue(tester, _titreEchec, 'le titre du message');
        _attendreDansLaVue(tester, _presenter, 'Reessayer');
        verifierSansChevauchement(tester, <Finder>[_titreEchec, _presenter]);
        expect(
          find.descendant(
            of: _presenter,
            matching: find.text(t.commun.reessayer),
          ),
          findsOneWidget,
        );
        expect(_pageAvecTitre(_titreInitial), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
