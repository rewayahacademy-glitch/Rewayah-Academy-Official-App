// Revue croisee de LIB-DIR-1 (08/10) : l'arabe ne traduit pas toutes les
// cles ; les autres s'affichent en francais (repli). Sur un appareil en
// arabe, ce texte francais de repli garde son « de » / « d' » et son
// « que » / « qu' » : jamais « Les finances Aïcha ».
//
// Reunion de la ligne arabe dans ccr (10/10) : sans `cle:`, l'arabe recoit le
// nom seul (AR-ENS-1) ; l'appel d'une cle en repli passe donc sa cle. Les cles
// de ce fichier sont des cles de test absentes de l'arabe : le socle des cles
// non traduites est vide (LANGUES-1).

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

void main() {
  setUp(() async => LocaleSettings.setLocale(AppLocale.ar));
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  test('appareil en arabe : les textes de repli francais gardent « de »', () {
    expect(LocaleSettings.currentLocale, AppLocale.ar);
    // LANGUES-1 (13/11/2026) : l'arabe n'a plus aucune cle francaise sans
    // traduction (socle vide). La regle se prouve sur des cles absentes de
    // l'arabe : le repli francais garde « de » / « d' » et « que » / « qu' ».
    const String finances = 'test.finances.absente.de.l.arabe';
    const String demande = 'test.demande.absente.de.l.arabe';
    expect(t.$meta.getTranslation(finances), isNull);
    expect(t.$meta.getTranslation(demande), isNull);
    expect(
      'Voir le détail des finances ${deDevant('Aïcha', cle: finances)}',
      "Voir le détail des finances d'Aïcha",
    );
    expect(
      'Demande ${deDevant('Nour', cle: demande)} refusée.',
      'Demande de Nour refusée.',
    );
    expect(queDevant('Aya', cle: demande), "qu'Aya");
  });

  test('appareil en arabe : une cle traduite recoit le nom seul', () {
    expect(
      t.ficheEleve.lignes.appareils(dePrenom: deDevant('Aïcha')),
      isNot(contains("d'")),
    );
  });
}
