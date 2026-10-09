// PHOTO-LIEN-1 (revue du directeur 01/10, K-54, K-56) : « Choisir une photo »
// n'est pas un gros bouton plein, c'est une ligne de lien (texte et fleche),
// au centre de sa ligne, avec sa cible de 48 ; toucher la photo ouvre aussi le
// choix ; le seul bouton plein de l'editeur est « Utiliser cette photo ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/raccourci_tactile.dart';
import 'package:rewayah_academy/features/profil_enseignant/photo_publique.dart';

import '../../capture/outil_capture.dart';
import '../../support/garde_interface.dart';

class _ChoixCompte implements ChoixPhotoPublique {
  _ChoixCompte();

  int appels = 0;

  @override
  Future<PhotoChoisie?> choisir() async {
    appels++;
    return const PhotoChoisie();
  }
}

Future<_ChoixCompte> _monter(
  WidgetTester tester, {
  required Size taille,
  double texte = 1,
}) async {
  final _ChoixCompte choix = _ChoixCompte();
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      MediaQuery(
        data: MediaQueryData(
          size: taille,
          textScaler: TextScaler.linear(texte),
        ),
        // La feuille qui porte l'editeur defile : a 320 px et texte x2, il
        // depasse la hauteur de l'ecran.
        child: const Scaffold(
          body: SingleChildScrollView(
            child: EditeurPhotoPublique(prenom: 'Ibrahim'),
          ),
        ),
      ),
      surcharges: <Override>[
        choixPhotoPubliqueProvider.overrideWithValue(choix),
        horsLigneProvider.overrideWith((_) => Stream<bool>.value(false)),
      ],
    ),
  );
  await stabiliser(tester);
  return choix;
}

void main() {
  for (final Size taille in const <Size>[Size(320, 700), Size(1440, 900)]) {
    for (final double texte in const <double>[1, 2]) {
      testWidgets(
        'le choix est une ligne de lien centree, jamais un bouton plein '
        '(${taille.width.toInt()} px, texte x${texte.toInt()})',
        (WidgetTester tester) async {
          await _monter(tester, taille: taille, texte: texte);

          final Finder lien = find.byKey(EditeurPhotoPublique.choisirKey);
          expect(lien, findsOneWidget);
          expect(tester.widget(lien), isA<LienFleche>());
          expect(
            find.byType(ActionPrincipale),
            findsNothing,
            reason: 'aucun bouton plein : l\'action est un lien',
          );
          final Rect cadre = tester.getRect(lien);
          expect(cadre.height, greaterThanOrEqualTo(48 - toleranceGarde));
          verifierContenuCentre(tester, lien, <Finder>[
            find.byType(Text),
            find.byType(Icon),
          ]);
          // Une ligne de lien a la largeur de son contenu (texte, fleche et
          // leur marge de 4), pas celle de la page : l'ancien bouton plein
          // ecrasait l'ecran.
          final Rect texteR = tester.getRect(
            find.descendant(of: lien, matching: find.byType(Text)),
          );
          final Rect flecheR = tester.getRect(
            find.descendant(of: lien, matching: find.byType(Icon)),
          );
          expect(
            cadre.width,
            lessThanOrEqualTo(
              texteR.expandToInclude(flecheR).width + 2 * AppSpacing.xs + 1,
            ),
            reason: 'le lien s\'etire au dela de son contenu : $cadre',
          );
          verifierUnSeulBoutonPlein(tester);
        },
      );
    }
  }

  testWidgets('toucher la photo ouvre aussi le choix', (
    WidgetTester tester,
  ) async {
    final _ChoixCompte choix = await _monter(
      tester,
      taille: const Size(390, 800),
    );
    expect(find.byType(RaccourciTactile), findsOneWidget);
    await tester.tap(find.byType(RaccourciTactile));
    await stabiliser(tester);
    expect(choix.appels, 1);
    expect(find.byKey(EditeurPhotoPublique.apercuKey), findsOneWidget);
  });

  testWidgets('le raccourci de la photo n\'ajoute ni arret de focus ni bouton '
      'annonce : le lien reste le seul controle', (WidgetTester tester) async {
    await _monter(tester, taille: const Size(390, 800));
    final SemanticsHandle poignee = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(t.enseignant.photo.choisir),
      findsOneWidget,
      reason: 'un seul controle porte ce nom',
    );
    poignee.dispose();
  });

  testWidgets('apercu : un seul bouton plein, « autre photo » est un lien', (
    WidgetTester tester,
  ) async {
    await _monter(tester, taille: const Size(390, 800));
    await tester.tap(find.byKey(EditeurPhotoPublique.choisirKey));
    await stabiliser(tester);

    verifierUnSeulBoutonPlein(tester);
    final Finder utiliser = find.byKey(EditeurPhotoPublique.utiliserKey);
    expect(tester.widget(utiliser), isA<ActionPrincipale>());
    verifierBoutonCentre(tester, utiliser, t.enseignant.photo.utiliser);
    expect(
      find.ancestor(
        of: find.text(t.enseignant.photo.autre),
        matching: find.byType(LienFleche),
      ),
      findsOneWidget,
    );
  });
}
