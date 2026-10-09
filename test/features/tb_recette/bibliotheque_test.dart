// TB-8 (LIB-01 a LIB-04 ; plan V2 §3, §12, §19.1, UX-17) : la Bibliotheque
// en seance.
//
// Une seule bibliotheque (R14 : SurfaceBibliotheque) ; choisir une carte
// ouvre un apercu personnel, la classe garde le support actuel jusqu'a
// « Presenter » (UX-17) ; Presenter verifie le chargement ; un fichier non
// charge ne remplace jamais le support (LIB-03) ; recherche sans resultat
// et retour (LIB-04).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/demo/demo_salle_page.dart';
import 'package:rewayah_academy/features/demo/seance_demo.dart';
import 'package:rewayah_academy/features/salle_seance/bibliotheque_seance.dart';
import 'package:rewayah_academy/features/salle_seance/commandes_pedagogiques.dart';
import 'package:rewayah_academy/features/salle_seance/surface_page_fixe.dart';
import 'package:rewayah_academy/features/salle_seance/vue_seance.dart';
import 'package:rewayah_academy/features/tc_catalogue/surface_bibliotheque.dart';

import '../../capture/outil_capture.dart' hide stabiliser;
import '../../router/support_routeur.dart';

const Size _telephone = Size(390, 844);
const Size _bureau = Size(1440, 900);

final Finder _bibliotheque = find.byType(BibliothequeSeance);
final Finder _catalogue = find.byType(SurfaceBibliotheque);
final Finder _apercu = find.byKey(BibliothequeSeance.cleApercu);
final Finder _presenter = find.byKey(BibliothequeSeance.clePresenter);
final Finder _revenir = find.byKey(BibliothequeSeance.cleRevenir);
final Finder _echec = find.byKey(BibliothequeSeance.cleEchec);

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
      // Le message et « Reessayer » sont visibles ensemble, au-dessus de la
      // barre de l'appel.
      final Rect bouton = tester.getRect(_presenter);
      // Le cadre visible de l'apercu (sa zone de defilement).
      final Rect cadre = tester.getRect(_apercu);
      expect(bouton.bottom, lessThanOrEqualTo(cadre.bottom + 0.5));
      expect(tester.getRect(_echec).top, greaterThanOrEqualTo(cadre.top - 0.5));
      // La classe garde le support d'avant ; Reessayer, et le retour.
      expect(_pageAvecTitre(_titreInitial), findsOneWidget);
      expect(
        find.descendant(of: _presenter, matching: find.text('Réessayer')),
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
}
