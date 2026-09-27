import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/router/chemin_retour.dart';

void main() {
  group('Un retour est un chemin interne, et rien d autre', () {
    test('les chemins internes ordinaires passent inchanges', () {
      for (final String chemin in <String>[
        '/',
        '/tuteur',
        '/tuteur/foyer',
        '/tuteur/foyer?eleve=e1',
        '/tc/observation/s1',
        '/compte/profils/e2',
      ]) {
        expect(cheminRetourValide(chemin), chemin, reason: chemin);
      }
    });

    test('rien, une chaine vide ou un chemin relatif ne donnent rien', () {
      expect(cheminRetourValide(null), isNull);
      expect(cheminRetourValide(''), isNull);
      expect(cheminRetourValide('tuteur'), isNull);
      expect(cheminRetourValide(' /tuteur'), isNull);
      expect(cheminRetourValide('/tuteur '), isNull);
    });

    test('une adresse externe ne passe sous aucune forme', () {
      // Le cas que la regle existe pour fermer : une redirection ouverte vers
      // un site tiers apres connexion.
      for (final String externe in <String>[
        'https://exemple.test/tuteur',
        'http:/tuteur',
        '//exemple.test',
        '//exemple.test/tuteur',
        r'/\exemple.test',
        'javascript:alert(1)',
        '/tuteur#ancre',
      ]) {
        expect(cheminRetourValide(externe), isNull, reason: externe);
      }
    });

    test('la salle, la classe et l entree d agent sont refusees', () {
      for (final String interdit in <String>[
        '/salle',
        '/salle/s1',
        '/salle?billet=x',
        '/tc/classe',
        '/tc/classe/s1',
        '/agent',
        '/agent?jeton=abc',
        '/SALLE',
        '/Tc/Classe',
      ]) {
        expect(cheminRetourValide(interdit), isNull, reason: interdit);
      }
    });

    test('un encodage ou un segment ne change pas la destination en douce', () {
      for (final String detour in <String>[
        '/%73alle',
        '/tc%2Fclasse',
        '/tuteur/../salle',
        '/tuteur/./foyer',
        '/tuteur//foyer',
        '/tuteur/',
        '/%ff',
      ]) {
        expect(cheminRetourValide(detour), isNull, reason: detour);
      }
    });

    test('un caractere de controle ou une chaine demesuree sont refuses', () {
      expect(cheminRetourValide('/tuteur\n/foyer'), isNull);
      expect(cheminRetourValide('/tuteur\u0000'), isNull);
      expect(cheminRetourValide('/${'a' * 2000}'), isNull);
    });
  });
}
