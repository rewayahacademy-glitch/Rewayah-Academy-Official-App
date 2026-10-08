// Revue croisee de LIB-DIR-1 (08/10) : l'arabe ne traduit qu'une partie des
// cles ; les autres s'affichent en francais (repli). Sur un appareil en
// arabe, ce texte francais de repli garde son « de » / « d' » et son
// « que » / « qu' » : jamais « Continuer en tant Aya » ni « Préparer la
// séance Al-Badr ».
//
// Ce fichier n'emploie que l'API d'avant la correction (deDevant(nom),
// queDevant(nom)) : il echoue sur 4286b13d et passe apres.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

void main() {
  setUp(() async => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('appareil en arabe : les textes de repli francais gardent « de »', () {
    expect(LocaleSettings.currentLocale, AppLocale.ar);
    expect(
      t.eleveConnexion.profils.profilLibelle(quePrenom: queDevant('Aya')),
      "Continuer en tant qu'Aya",
    );
    expect(
      t.ficheEleve.lignes.appareils(dePrenom: deDevant('Aïcha')),
      "Appareils d'Aïcha",
    );
    expect(
      t.tuteur.accueil.sansClassePhrase(quePrenom: queDevant('Nour')),
      'Choisissez une classe pour que Nour puisse commencer les cours.',
    );
    expect(
      t.enseignant.journee.preparerSeanceLecteur(classe: deDevant('Al-Badr')),
      "Préparer la séance d'Al-Badr",
    );
  });
}
