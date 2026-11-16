// VERSEMENT-QUESTIONS (pilote, 16/11/2026) : le serveur rend `debloquerVersement`
// dans les capacites de la direction avant que l'ecran n'existe. L'application
// actuelle doit le tolerer : ni plantage, ni geste propose, les autres gestes
// intacts.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/gestes_candidature.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart';

void main() {
  test('un geste inconnu dans les capacites est ignore, rien ne casse', () {
    final CapacitesCandidatures c = CapacitesCandidatures.depuisJson(
      const <String, dynamic>{
        'peutLire': true,
        'peutDecider': true,
        'genreLecteurConnu': true,
        'gestes': <String, dynamic>{
          'refuser': true,
          'confirmerMoyenPaiement': true,
          // Le geste du serveur sans ecran : inconnu de l'application.
          'debloquerVersement': true,
          'geste_futur_inconnu': true,
        },
      },
    );
    expect(c.peutDecider, isTrue);
    expect(c.geste('refuser'), isTrue);
    expect(c.geste('confirmerMoyenPaiement'), isTrue);
    // Les valeurs connues de l'application ne changent pas : aucune ne porte
    // le geste du serveur, donc aucun bouton, aucun ecran vide.
    expect(
      GesteCandidature.values.any(
        (GesteCandidature g) => g.name == 'debloquerVersement',
      ),
      isFalse,
    );
    expect(
      <bool>[
        for (final GesteCandidature g in GesteCandidature.values)
          c.geste(g.name),
      ].where((bool b) => b).length,
      lessThanOrEqualTo(GesteCandidature.values.length),
    );
  });

  test('sans la cle des gestes, aucune capacite n\'est supposee', () {
    final CapacitesCandidatures c = CapacitesCandidatures.depuisJson(
      const <String, dynamic>{'peutLire': true},
    );
    expect(c.geste('debloquerVersement'), isFalse);
    expect(c.geste('refuser'), isFalse);
  });
}
