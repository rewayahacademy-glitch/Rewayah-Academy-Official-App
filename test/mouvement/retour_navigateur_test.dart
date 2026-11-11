// TRANSITIONS, regle 9 (DECISION-MOUVEMENT-2026-11-11) : sur le web, seul un
// retour demande par le navigateur joue le fondu court ; la fleche de
// l'application garde l'axe partage inverse.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/mouvement/retour_navigateur.dart';

void main() {
  DateTime maintenant = DateTime.utc(2026, 11, 11, 12);

  setUp(() {
    RetourNavigateur.horloge = () => maintenant;
    RetourNavigateur.oublier();
  });
  tearDown(() {
    RetourNavigateur.horloge = DateTime.now;
    RetourNavigateur.oublier();
  });

  test('un retour du navigateur colore la transition qui le suit, '
      'puis s oublie', () {
    expect(RetourNavigateur.recent(), isFalse);
    RetourNavigateur.signaler();
    expect(RetourNavigateur.recent(), isTrue);
    maintenant = maintenant.add(const Duration(milliseconds: 400));
    expect(
      RetourNavigateur.recent(),
      isTrue,
      reason: 'la sortie de page la plus longue (187 ms) tient dans la fenetre',
    );
    maintenant = maintenant.add(RetourNavigateur.fenetre);
    expect(RetourNavigateur.recent(), isFalse);
  });

  test('fondu court : web, retour en cours, demande par le navigateur', () {
    expect(
      fonduDeRetourWeb(
        web: true,
        retourEnCours: true,
        retourDuNavigateur: true,
      ),
      isTrue,
    );
    // La fleche de l'application : axe partage inverse.
    expect(
      fonduDeRetourWeb(
        web: true,
        retourEnCours: true,
        retourDuNavigateur: false,
      ),
      isFalse,
    );
    // Une avance (meme demandee par le navigateur) : axe partage.
    expect(
      fonduDeRetourWeb(
        web: true,
        retourEnCours: false,
        retourDuNavigateur: true,
      ),
      isFalse,
    );
    // Hors web : la transition du systeme ou l'axe partage.
    expect(
      fonduDeRetourWeb(
        web: false,
        retourEnCours: true,
        retourDuNavigateur: true,
      ),
      isFalse,
    );
  });

  test('l ecoute ne se branche qu une fois, et hors web ne fait rien', () {
    RetourNavigateur.ecouter();
    RetourNavigateur.ecouter();
    expect(RetourNavigateur.recent(), isFalse);
  });
}
