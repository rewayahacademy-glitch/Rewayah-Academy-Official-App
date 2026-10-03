// COUPE-MOTS-1 (part 1/2) : les composants partages passent a la ligne ENTRE
// les mots, jamais dans un mot, et les libelles voisins gardent la meme
// echelle. Mesure par mot (getBoxesForSelection), en VRAIES polices : la
// police de test (carres de 1 em) rendrait « Aujourd'hui » a 36 px plus
// large qu'un telephone, ce que l'application ne fait pas.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/widgets/avatar_nom.dart';
import 'package:rewayah_academy/core/widgets/controle_segmente.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';
import '../support/harnais.dart';

void _vue(WidgetTester tester, Size taille, double echelle) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Les echelles distinctes des paragraphes sous [ou].
Set<double> _echelles(WidgetTester tester, Finder ou) {
  final Set<double> echelles = <double>{};
  void visiter(RenderObject o) {
    // Les icones sont aussi des paragraphes (un glyphe de la zone privee,
    // jamais agrandi) : seuls les libelles comptent.
    if (o is RenderParagraph &&
        !o.text.toPlainText().runes.every(
          (int r) => r >= 0xE000 && r <= 0xF8FF,
        )) {
      echelles.add((o.textScaler.scale(1) * 1000).roundToDouble() / 1000);
    }
    o.visitChildren(visiter);
  }

  visiter(tester.renderObject(ou));
  return echelles;
}

Widget _coquille(AppRole role, {TextDirection sens = TextDirection.ltr}) =>
    Directionality(
      textDirection: sens,
      child: NavShell(
        destinations: destinationsPour(
          role: role,
          mode: InterfaceMode.standard,
        ),
        indexActif: 0,
        libellesDansLeRail: role != AppRole.guardian,
        onAller: (String _) {},
        child: const SizedBox.expand(),
      ),
    );

void main() {
  setUpAll(chargerPolicesDuDepot);

  group('titres de page', () {
    for (final double echelle in <double>[1, 2]) {
      for (final String titre in <String>[
        "Aujourd'hui",
        'Centre de commande',
        'Cahier de transmission',
      ]) {
        testWidgets('« $titre » a 320 px, x$echelle, sans et avec retour', (
          WidgetTester tester,
        ) async {
          _vue(tester, const Size(320, 800), echelle);
          await tester.pumpWidget(
            hote(PageShell(titre: titre, child: const SizedBox())),
          );
          await tester.pumpAndSettle();
          verifierAucunMotCoupe(tester, find.byType(PageShell));

          // L'en-tete riche (EntetePage) : disque retour et titre.
          await tester.pumpWidget(
            hote(
              PageShell(titre: titre, onRetour: () {}, child: const SizedBox()),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          verifierAucunMotCoupe(tester, find.byType(PageShell));
        });
      }
    }
  });

  group('navigation', () {
    for (final double echelle in <double>[1, 2]) {
      testWidgets(
        'barre basse enseignant a 320, x$echelle : « Disponibilites » '
        'entier, une seule echelle',
        (WidgetTester tester) async {
          _vue(tester, const Size(320, 700), echelle);
          await tester.pumpWidget(hote(_coquille(AppRole.teacher)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final Finder barre = find.byKey(NavShell.barreBasseKey);
          verifierAucunMotCoupe(tester, barre);
          expect(_echelles(tester, barre), hasLength(1));
          // Les quatre libelles dans l'ecran.
          for (final Element e
              in find
                  .descendant(of: barre, matching: find.byType(Text))
                  .evaluate()) {
            final Rect r = tester.getRect(find.byWidget(e.widget));
            expect(r.left, greaterThanOrEqualTo(0));
            expect(r.right, lessThanOrEqualTo(320));
          }
        },
      );
    }

    for (final TextDirection sens in TextDirection.values) {
      testWidgets('rail controleur a 768, x2, ${sens.name} : aucun libelle '
          'tronque, une seule echelle', (WidgetTester tester) async {
        _vue(tester, const Size(768, 1024), 2);
        await tester.pumpWidget(
          hote(_coquille(AppRole.controller, sens: sens)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final Finder rail = find.byKey(NavShell.railKey);
        verifierAucunMotCoupe(tester, rail);
        expect(_echelles(tester, rail), hasLength(1));
      });
    }

    testWidgets('rail enseignant a 768, x1 : « Disponibilites » entier', (
      WidgetTester tester,
    ) async {
      _vue(tester, const Size(768, 1024), 1);
      await tester.pumpWidget(hote(_coquille(AppRole.teacher)));
      await tester.pumpAndSettle();
      verifierAucunMotCoupe(tester, find.byKey(NavShell.railKey));
      expect(_echelles(tester, find.byKey(NavShell.railKey)), hasLength(1));
    });

    testWidgets('barre laterale tuteur a 1440, x2 : le nom de l application '
        'entier, libelles a une seule echelle', (WidgetTester tester) async {
      _vue(tester, const Size(1440, 900), 2);
      await tester.pumpWidget(hote(_coquille(AppRole.guardian)));
      await tester.pumpAndSettle();
      final Finder barre = find.byKey(NavShell.barreLateraleKey);
      verifierAucunMotCoupe(tester, barre);
      // Les quatre destinations (le mot-symbole a sa propre echelle).
      final Set<double> echelles = <double>{
        for (final Element e
            in find
                .descendant(of: barre, matching: find.byType(Pressable))
                .evaluate())
          ..._echelles(tester, find.byWidget(e.widget)),
      };
      expect(echelles, hasLength(1));
    });
  });

  testWidgets('ControleSegmente a 320, x2 : une seule echelle', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(320, 400), 2);
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ControleSegmente<int>(
              segments: const <Segment<int>>[
                Segment<int>(valeur: 0, libelle: 'Séances'),
                Segment<int>(valeur: 1, libelle: 'Observations'),
              ],
              valeur: 0,
              onChange: (int _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Finder controle = find.byType(ControleSegmente<int>);
    verifierAucunMotCoupe(tester, controle);
    expect(_echelles(tester, controle), hasLength(1));
  });

  testWidgets('pied de barre laterale : « Administrateur » entier a x2', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(1440, 900), 2);
    await tester.pumpWidget(
      hote(
        const Scaffold(
          body: SizedBox(
            // La largeur du pied de la barre laterale admin (288 - 2 x 16).
            width: 256,
            child: AvatarNom.enLigne(
              prenom: 'Administrateur',
              role: 'Administrateur',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    verifierAucunMotCoupe(tester, find.byType(AvatarNom));
  });

  testWidgets('StatusPill « Remplacement » dans 140 px, x2', (
    WidgetTester tester,
  ) async {
    _vue(tester, const Size(320, 400), 2);
    await tester.pumpWidget(
      hote(
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 140,
              child: StatusPill(libelle: 'Remplacement', ton: TonEtat.accent),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    verifierAucunMotCoupe(tester, find.byType(StatusPill));
  });
}
