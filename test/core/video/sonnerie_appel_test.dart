// DYNAMIQUE-CHRONO-2, point 6 (directeur, 12/11/2026 : « la sonnerie de
// l'appel d'un eleve est trop courte : l'allonger, repetee, meme espacee ») :
// le meme motif, trois fois, a 1,5 s d'intervalle, arrete au toucher.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/theme/app_mouvement.dart';
import 'package:rewayah_academy/core/video/signal_rappel.dart';

void main() {
  testWidgets('le motif est joue trois fois, espace', (
    WidgetTester tester,
  ) async {
    int joues = 0;
    final SonnerieAppel sonnerie = SonnerieAppel(() => joues++)..lancer();
    expect(joues, 1);
    expect(sonnerie.sonne, isTrue);
    await tester.pump(AppMouvement.sonnerieAppelEspace);
    expect(joues, 2);
    await tester.pump(AppMouvement.sonnerieAppelEspace);
    expect(joues, 3);
    await tester.pump(AppMouvement.sonnerieAppelEspace * 4);
    expect(joues, SonnerieAppel.repetitions);
    expect(sonnerie.sonne, isFalse);
  });

  testWidgets('un toucher l arrete ; un signal qui leve ne casse rien', (
    WidgetTester tester,
  ) async {
    int joues = 0;
    final SonnerieAppel sonnerie = SonnerieAppel(() => joues++)..lancer();
    await tester.pump(AppMouvement.sonnerieAppelEspace);
    sonnerie.arreter();
    await tester.pump(AppMouvement.sonnerieAppelEspace * 4);
    expect(joues, 2);

    // Le navigateur refuse le son : la sonnerie continue sans lever.
    int essais = 0;
    final SonnerieAppel refusee = SonnerieAppel(() {
      essais++;
      throw StateError('lecture refusee');
    })..lancer();
    await tester.pump(AppMouvement.sonnerieAppelEspace * 3);
    expect(essais, 3);
    expect(refusee.sonne, isFalse);
  });
}
