// AUTRE-PROFIL-ELEVE (12/11/2026) : l'adresse de l'application que la feuille
// « Utiliser un autre appareil » montre au titulaire.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/accueil_famille/feuille_autre_appareil.dart';

void main() {
  test('sur le Web : l origine de la page ouverte, sans itineraire', () {
    expect(
      adresseApplication(
        base: Uri.parse('https://app.rewayahacademy.com/#/tuteur'),
      ),
      'https://app.rewayahacademy.com',
    );
    expect(
      adresseApplication(base: Uri.parse('http://127.0.0.1:8090/#/tuteur')),
      'http://127.0.0.1:8090',
    );
  });

  test('hors du Web : l adresse de production de l application', () {
    expect(
      adresseApplication(base: Uri.parse('file:///data/app')),
      'https://app.rewayahacademy.com',
    );
  });
}
