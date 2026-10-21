// Revue croisee de LIB-DIR-1 (08/10) : l'arabe ne traduit pas toutes les
// cles ; les autres s'affichent en francais (repli). Sur un appareil en
// arabe, ce texte francais de repli garde son « de » / « d' » et son
// « que » / « qu' » : jamais « Les finances Aïcha ».
//
// Reunion de la ligne arabe dans ccr (10/10) : sans `cle:`, l'arabe recoit le
// nom seul (AR-ENS-1) ; l'appel d'une cle en repli passe donc sa cle. Les cles
// de ce fichier sont dans le socle des cles non traduites
// (`tool/ar_socle_non_traduites.txt`) ; quand l'une est traduite, la
// remplacer ici par une cle encore en repli.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

void main() {
  setUp(() async => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('appareil en arabe : les textes de repli francais gardent « de »', () {
    expect(LocaleSettings.currentLocale, AppLocale.ar);
    const String finances = 'ficheEleve.finances.erreurTitre';
    expect(
      t.ficheEleve.finances.erreurTitre(
        dePrenom: deDevant('Aïcha', cle: finances),
      ),
      "Les finances d'Aïcha ne peuvent pas être lues",
    );
    const String mouvements = 'ficheEleve.mouvements.erreurTitre';
    expect(
      t.ficheEleve.mouvements.erreurTitre(
        dePrenom: deDevant('Nour', cle: mouvements),
      ),
      'Les mouvements de Nour ne peuvent pas être lus',
    );
  });

  test('appareil en arabe : une cle traduite recoit le nom seul', () {
    expect(
      t.ficheEleve.lignes.appareils(dePrenom: deDevant('Aïcha')),
      isNot(contains("d'")),
    );
  });
}
