import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/marque/trace_svg.dart';

/// Le lecteur de traces SVG du logo (LOGO-APP) : commandes, repetitions
/// implicites, ecritures de nombres, refus des commandes inconnues.
CommandeTrace _c(NatureCommande n, List<double> p) => CommandeTrace(n, p);

void main() {
  test('M L H V Z absolus et relatifs', () {
    expect(
      lireTraceSvg('M10 20L30 40H50V60Z m5 5 l1 1 h2 v3 z'),
      <CommandeTrace>[
        _c(NatureCommande.deplacer, <double>[10, 20]),
        _c(NatureCommande.ligne, <double>[30, 40]),
        _c(NatureCommande.ligne, <double>[50, 40]),
        _c(NatureCommande.ligne, <double>[50, 60]),
        _c(NatureCommande.fermer, <double>[]),
        // Apres Z, le point courant revient au depart du sous-trace (10 20).
        _c(NatureCommande.deplacer, <double>[15, 25]),
        _c(NatureCommande.ligne, <double>[16, 26]),
        _c(NatureCommande.ligne, <double>[18, 26]),
        _c(NatureCommande.ligne, <double>[18, 29]),
        _c(NatureCommande.fermer, <double>[]),
      ],
    );
  });

  test('repetitions implicites : M suivi de paires trace des lignes', () {
    expect(lireTraceSvg('M0 0 10 0 10 10'), <CommandeTrace>[
      _c(NatureCommande.deplacer, <double>[0, 0]),
      _c(NatureCommande.ligne, <double>[10, 0]),
      _c(NatureCommande.ligne, <double>[10, 10]),
    ]);
    expect(lireTraceSvg('m1 1 2 2 l1 0 0 1'), <CommandeTrace>[
      _c(NatureCommande.deplacer, <double>[1, 1]),
      _c(NatureCommande.ligne, <double>[3, 3]),
      _c(NatureCommande.ligne, <double>[4, 3]),
      _c(NatureCommande.ligne, <double>[4, 4]),
    ]);
  });

  test('ecritures de nombres : -.5, 1.5e-3, signes colles, 1.5.5', () {
    expect(lireTraceSvg('M-.5 1.5e-3L0-1.56-.14 2E2L1.5.5'), <CommandeTrace>[
      _c(NatureCommande.deplacer, <double>[-0.5, 0.0015]),
      _c(NatureCommande.ligne, <double>[0, -1.56]),
      _c(NatureCommande.ligne, <double>[-0.14, 200]),
      _c(NatureCommande.ligne, <double>[1.5, 0.5]),
    ]);
    expect(lireTraceSvg('M5.32907e-05 0')[0].coordonnees[0], 5.32907e-05);
  });

  test('C et S, avec la reflexion du point de controle', () {
    expect(
      lireTraceSvg('M0 0C0 10 10 10 10 0S20 -10 20 0s10 10 10 0'),
      <CommandeTrace>[
        _c(NatureCommande.deplacer, <double>[0, 0]),
        _c(NatureCommande.cubique, <double>[0, 10, 10, 10, 10, 0]),
        _c(NatureCommande.cubique, <double>[10, -10, 20, -10, 20, 0]),
        _c(NatureCommande.cubique, <double>[20, 10, 30, 10, 30, 0]),
      ],
    );
    // S sans cubique avant : le premier controle est le point courant.
    expect(
      lireTraceSvg('M1 1S2 2 3 3')[1],
      _c(NatureCommande.cubique, <double>[1, 1, 2, 2, 3, 3]),
    );
  });

  test('Q et q, et la cubique relative', () {
    expect(
      lireTraceSvg('M0 0Q5 10 10 0q5 -10 10 0c1 1 2 2 3 3'),
      <CommandeTrace>[
        _c(NatureCommande.deplacer, <double>[0, 0]),
        _c(NatureCommande.quadratique, <double>[5, 10, 10, 0]),
        _c(NatureCommande.quadratique, <double>[15, -10, 20, 0]),
        _c(NatureCommande.cubique, <double>[21, 1, 22, 2, 23, 3]),
      ],
    );
  });

  test('refuse ce qu il ne sait pas dessiner', () {
    expect(() => lireTraceSvg('M0 0A5 5 0 0 1 10 10'), throwsFormatException);
    expect(() => lireTraceSvg('10 10'), throwsFormatException);
    expect(() => lireTraceSvg('M0 0C1 1 2'), throwsFormatException);
  });
}
