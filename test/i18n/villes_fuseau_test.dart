// AR-FUSEAU-VILLE : le nom de la ville d'un fuseau, dans la langue active.
//
// Ce que le test prouve :
// - chaque fuseau des donnees de l'application (tout identifiant IANA ecrit
//   dans `lib/`) a son nom arabe : un nouveau fuseau sans libelle fait
//   tomber le test ;
// - en arabe, « Europe/Paris » donne « باريس » et aucune lettre latine ne
//   reste ; en francais, le nom reste celui d'avant ;
// - un fuseau inconnu ou mal forme ne plante pas : son nom IANA, isole
//   (U+2068 ... U+2069) en arabe, tel quel en francais ;
// - les phrases du suivi (`deFuseau`) portent le nom arabe.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/i18n/villes_fuseau.dart';
import 'package:rewayah_academy/features/suivi_demandes/libelles_suivi_demandes.dart';

final RegExp _iana = RegExp(
  "'((?:Europe|America|Africa|Asia|Australia|Pacific|Atlantic|Indian)"
  "/[A-Za-z_]+(?:/[A-Za-z_]+)?)'",
);

Set<String> _fuseauxDeLib() => <String>{
  for (final FileSystemEntity f in Directory('lib').listSync(recursive: true))
    if (f is File && f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
      for (final RegExpMatch m in _iana.allMatches(f.readAsStringSync())) m[1]!,
};

final RegExp _latin = RegExp('[A-Za-z]');

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  test('la cle de table se calcule depuis l\'identifiant', () {
    expect(cleVilleFuseau('Europe/Paris'), 'europeParis');
    expect(cleVilleFuseau('America/Los_Angeles'), 'americaLosAngeles');
    expect(
      cleVilleFuseau('America/Argentina/Buenos_Aires'),
      'americaArgentinaBuenosAires',
    );
    expect(cleVilleFuseau(''), isNull);
    expect(cleVilleFuseau(' / _ '), isNull);
  });

  test('tout fuseau ecrit dans lib/ a son nom arabe', () async {
    final Set<String> fuseaux = _fuseauxDeLib();
    expect(fuseaux, isNotEmpty);
    await LocaleSettings.setLocale(AppLocale.ar);
    for (final String iana in fuseaux) {
      final String ville = villeDuFuseauLibelle(iana);
      expect(ville.contains('⁨'), isFalse, reason: '$iana hors table');
      expect(_latin.hasMatch(ville), isFalse, reason: iana);
    }
  });

  test('en arabe : les noms de la table', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    expect(villeDuFuseauLibelle('Europe/Paris'), 'باريس');
    expect(villeDuFuseauLibelle('America/New_York'), 'نيويورك');
    expect(villeDuFuseauLibelle('Africa/Conakry'), 'كوناكري');
    expect(villeDuFuseauLibelle('America/Los_Angeles'), 'لوس أنجلوس');
  });

  test('en francais : les noms d\'avant', () {
    expect(villeDuFuseauLibelle('Europe/Paris'), 'Paris');
    expect(villeDuFuseauLibelle('America/New_York'), 'New York');
    expect(villeDuFuseauLibelle('Europe/London'), 'London');
    expect(villeDuFuseauLibelle('Australia/Perth'), 'Perth');
  });

  test('un fuseau inconnu ne plante pas : nom IANA, isole en arabe', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    expect(villeDuFuseauLibelle('Australia/Perth'), '⁨Perth⁩');
    expect(villeDuFuseauLibelle('America/Port_of_Spain'), '⁨Port of Spain⁩');
    expect(villeDuFuseauLibelle('UTC'), '⁨UTC⁩');
    expect(villeDuFuseauLibelle(''), '');
    expect(() => villeDuFuseauLibelle('////'), returnsNormally);
    expect(() => villeDuFuseauLibelle('  '), returnsNormally);
  });

  test('les phrases du suivi portent le nom arabe', () async {
    await LocaleSettings.setLocale(AppLocale.ar);
    expect(deFuseau('Europe/Paris'), 'باريس');
    expect(
      t.suiviFamille.fuseau(deVille: deFuseau('Europe/Paris')),
      contains('باريس'),
    );
    expect(
      t.suiviDemandes.heureFuseau(
        heure: '18:00',
        deVille: deFuseau('Africa/Casablanca'),
      ),
      contains('الدار البيضاء'),
    );
    // Le temps universel garde son sigle.
    expect(deFuseau('Etc/UTC'), 'UTC');
  });
}
