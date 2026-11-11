// SCENE-CLASSE (MODES-AFFICHAGE §2, regle 7) : un seul etat de la scene,
// calcule a un seul endroit, qui redit exactement les drapeaux d'avant.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/salle_seance/media_salle.dart';

void main() {
  group('voirLaClasse : la demande telle que /salle la posait avant', () {
    test('rien de presente, rien choisi : la classe', () {
      expect(voirLaClasse(tableauOuvert: false, pagePresentee: false), isTrue);
    });
    test('une page presentee, rien choisi : la page', () {
      expect(voirLaClasse(tableauOuvert: false, pagePresentee: true), isFalse);
    });
    test('« voir la classe » devant une page : la classe', () {
      expect(
        voirLaClasse(tableauOuvert: false, pagePresentee: true, choix: true),
        isTrue,
      );
    });
    test('le tableau ouvert tient la classe fermee, quel que soit le choix', () {
      for (final bool? choix in <bool?>[null, true, false]) {
        expect(
          voirLaClasse(tableauOuvert: true, pagePresentee: false, choix: choix),
          isFalse,
        );
      }
    });
  });

  group('calculerModeScene', () {
    ModeScene mode({
      bool scene = true,
      bool classe = false,
      bool surface = true,
      bool tableau = false,
    }) => calculerModeScene(
      sceneDisponible: scene,
      voirLaClasse: classe,
      surfaceMontree: surface,
      tableau: tableau,
    );

    test('rien a montrer : la classe', () {
      expect(mode(surface: false), ModeScene.classe);
    });
    test('la classe demandee devant une page ou un tableau : la classe', () {
      expect(mode(classe: true), ModeScene.classe);
      expect(mode(classe: true, tableau: true), ModeScene.classe);
    });
    test('une page : le document ; un tableau : le tableau', () {
      expect(mode(), ModeScene.document);
      expect(mode(tableau: true), ModeScene.tableau);
    });
    test('sans scene (demonstration) : la zone garde son rendu', () {
      expect(mode(scene: false, surface: false), ModeScene.document);
      expect(mode(scene: false, classe: true), ModeScene.document);
    });
  });
}
