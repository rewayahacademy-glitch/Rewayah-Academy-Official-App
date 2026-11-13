// HORS-SALLE-2 : le texte de l'accord du journal des sorties est, mot pour
// mot, celui de `docs/current/TEXTES-VALIDES/ACCORD-JOURNAL-SORTIES.md`
// (PROPOSITION a valider par le directeur), en francais et en arabe ; et il
// dit ce que le code fait, sans citer de loi ni inventer de duree.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';

List<String> _textes() {
  final Traductions$journalSorties$texte$fr x = t.journalSorties.texte;
  return <String>[
    x.titre,
    x.parent.quoi,
    x.parent.pourquoi,
    x.parent.qui,
    x.parent.retrait,
    x.parent.sansAccord,
    x.parent.caseAccord(prenom: '{prenom}'),
    x.adulte.quoi,
    x.adulte.pourquoi,
    x.adulte.qui,
    x.adulte.retrait,
    x.adulte.sansAccord,
    x.adulte.caseAccord,
  ];
}

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  final String registre = File(
    'docs/current/TEXTES-VALIDES/ACCORD-JOURNAL-SORTIES.md',
  ).readAsStringSync();

  test('le registre dit PROPOSITION, a valider par le directeur', () {
    expect(registre, contains('PROPOSITION, à valider par le directeur'));
    expect(registre, contains('durée de conservation'));
  });

  test('les cles sont, mot pour mot, les textes du registre, en francais et '
      'en arabe', () async {
    for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar]) {
      await LocaleSettings.setLocale(langue);
      for (final String texte in _textes()) {
        expect(registre, contains(texte), reason: '${langue.name} : $texte');
      }
    }
  });

  test('ce que le texte doit dire pour rester vrai', () {
    LocaleSettings.setLocaleSync(AppLocale.fr);
    final Traductions$journalSorties$texte$parent$fr p =
        t.journalSorties.texte.parent;
    expect(p.quoi, contains("l'heure où il la quitte"));
    expect(p.quoi, contains("l'heure où il revient"));
    expect(p.quoi, contains('ni son écran, ni son image, ni sa voix'));
    expect(p.qui, contains('Jamais les autres élèves ni leurs familles'));
    expect(p.retrait, contains('à tout moment'));
    expect(p.retrait, contains("plus rien n'est noté"));
    expect(p.sansAccord, contains("rien n'est noté"));
    expect(p.sansAccord, contains('avec ou sans accord'));
    for (final String texte in _textes()) {
      // Aucune loi citee, aucune duree de conservation inventee.
      expect(texte, isNot(contains('loi')));
      expect(texte, isNot(contains('article')));
      expect(texte, isNot(contains('jours')));
      // Espace insecable avant les deux-points.
      expect(texte, isNot(contains(' :')));
    }
  });
}
