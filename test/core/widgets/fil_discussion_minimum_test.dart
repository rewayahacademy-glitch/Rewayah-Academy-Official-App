// SUPERPOS-1b (09/10/2026, reserve 1 de la relecture SUPERPOS-1-R2) : la
// hauteur minimale de la liste du fil, `FilDiscussion.minimumListe`.
//
// La regle (SUPERPOS-1, decide par delegation le 05/10) : la liste garde au
// moins la hauteur d'une bulle de deux lignes A L'ECHELLE DU TEXTE, au lieu
// d'un minimum fixe de 96 qui ne laissait voir, a 320 en texte double, qu'une
// tranche de bulle. La relecture a montre qu'aucun test ne protegeait cette
// hauteur : remettre 96 laissait la suite verte (mutation M3).
//
// Mesure : on rend une vraie bulle de deux lignes et on compare.
// - `minimumListe` grandit avec le texte et couvre la bulle rendue, en texte
//   normal comme en texte double ;
// - dans une vue trop basse (320 x 640, texte double, clavier de 300), la
//   liste rendue montre la bulle entiere : la page defile au lieu
//   d'ecraser la liste.
//
// Contre-epreuve faite le 09/10 : `minimumListe` renvoyant 96 (l'ancien
// minimum fixe), les trois tests echouent.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/widgets/fil_discussion.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/harnais.dart';

const TextesFilDiscussion _textes = TextesFilDiscussion(
  aideChamp: 'Répondre à l administration…',
  libelleChamp: 'Répondre à l administration',
  envoyer: 'Envoyer',
  champVide: 'Écrivez un message pour pouvoir l envoyer.',
  enCours: 'Envoi en cours.',
  envoye: 'Envoyé.',
  echec: 'L envoi n est pas confirmé.',
  reessayer: 'Réessayer',
  auteurSoi: 'Vous',
  annonce: _annonce,
);

String _annonce(String a, String t) => '$a : $t';

/// Un message de deux lignes : la bulle que la regle compte.
const MessageFil _deuxLignes = MessageFil(
  id: '1',
  auteur: 'Admin',
  texte: 'Merci.\nÀ demain.',
  horodatage: '09:30',
  deSoi: false,
);

const Key _bulle = ValueKey<String>('message-1');

Future<void> _monter(
  WidgetTester tester, {
  required Size taille,
  required double echelle,
  double clavier = 0,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: clavier);
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = echelle;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    hote(
      PageShell(
        titre: 'Classe Al-Badr',
        defilante: false,
        child: FilDiscussion(
          messages: const <MessageFil>[_deuxLignes],
          textes: _textes,
          onEnvoyer: (String _) async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _minimum(WidgetTester tester) =>
    FilDiscussion.minimumListe(tester.element(find.byType(FilDiscussion)));

void main() {
  setUpAll(chargerPolicesDuDepot);

  for (final double echelle in <double>[1, 2]) {
    testWidgets('texte x${echelle.toInt()} : le minimum couvre une bulle de '
        'deux lignes rendue', (WidgetTester tester) async {
      await _monter(tester, taille: const Size(390, 844), echelle: echelle);
      expect(tester.takeException(), isNull);
      final double bulle = tester.getSize(find.byKey(_bulle)).height;
      expect(
        _minimum(tester),
        greaterThanOrEqualTo(bulle),
        reason: 'minimum ${_minimum(tester)}, bulle de deux lignes $bulle',
      );
      // Le minimum suit l'echelle : il n'est pas une constante.
      if (echelle > 1) {
        tester.platformDispatcher.textScaleFactorTestValue = 1;
        await tester.pumpAndSettle();
        final double simple = _minimum(tester);
        tester.platformDispatcher.textScaleFactorTestValue = echelle;
        await tester.pumpAndSettle();
        expect(_minimum(tester), greaterThan(simple * 1.5));
      }
    });
  }

  testWidgets('320 x2, clavier ouvert : la liste montre la bulle entiere', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      taille: const Size(320, 640),
      echelle: 2,
      clavier: 300,
    );
    expect(tester.takeException(), isNull);
    final Rect liste = tester.getRect(
      find.descendant(
        of: find.byType(FilDiscussion),
        matching: find.byType(ListView),
      ),
    );
    final double bulle = tester.getSize(find.byKey(_bulle)).height;
    expect(
      liste.height,
      greaterThanOrEqualTo(bulle),
      reason: 'liste $liste, bulle de deux lignes $bulle',
    );
    expect(liste.height, greaterThanOrEqualTo(_minimum(tester) - 0.5));
  });
}
