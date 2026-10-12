// FUSEAU-UNIQUE : une seule fonction donne le nom de la ville d'un fuseau
// (`villeDuFuseauLibelle`), la ou trois copies existaient (suivi des demandes,
// regroupements, compte).
//
// Ce que le test prouve :
// - en francais, pour tout identifiant IANA bien forme, le rendu est
//   strictement celui de chacune des trois anciennes fonctions, reproduites
//   ici mot pour mot (reference d'avant) ;
// - les appelants rendent les memes phrases qu'avant (`deFuseau`, la
//   reference du regroupement, la ville du compte) ;
// - les trois fonctions ont disparu : aucune definition de `villeDuFuseau`
//   ne reste dans `lib/`, un nouvel appel passe par la fonction unique ;
// - sur un identifiant degenere (vide, espaces), la fonction unique ne leve
//   jamais, et rend le nom rogne.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/i18n/villes_fuseau.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart'
    show PublicOffre;
import 'package:rewayah_academy/core/offres/port_regroupements_admin.dart';
import 'package:rewayah_academy/features/admin_regroupements/regroupements_libelles.dart';
import 'package:rewayah_academy/features/suivi_demandes/libelles_suivi_demandes.dart';

// Les anciennes fonctions, reproduites telles qu'elles etaient.

/// Ancienne `villeDuFuseau` du suivi des demandes.
String _avantSuivi(String fuseauIana) {
  final String dernier = fuseauIana.split('/').last;
  return dernier.replaceAll('_', ' ');
}

/// Ancienne `villeDuFuseau` des regroupements.
String _avantRegroupements(String iana) =>
    iana.substring(iana.lastIndexOf('/') + 1).replaceAll('_', ' ');

/// Ancienne `villeDuFuseau` du compte.
String _avantCompte(String iana) {
  final String ville = iana.split('/').last.replaceAll('_', ' ').trim();
  return ville.isEmpty ? iana.trim() : ville;
}

/// Les identifiants du depot (tout `lib/`) et d'autres, de forme courante.
const List<String> _corpus = <String>[
  'Europe/Paris',
  'Africa/Conakry',
  'America/Toronto',
  'Europe/London',
  'Asia/Riyadh',
  'America/Los_Angeles',
  'Africa/Lagos',
  'Africa/Abidjan',
  'America/New_York',
  'Africa/Casablanca',
  'Asia/Tokyo',
  'America/Argentina/Buenos_Aires',
  'Europe/Berlin',
  'Europe/Brussels',
  'Europe/Zurich',
  'Africa/Dakar',
  'Africa/Algiers',
  'Africa/Tunis',
  'Africa/Cairo',
  'Asia/Dubai',
  'Asia/Qatar',
  'Asia/Ho_Chi_Minh',
  'America/Sao_Paulo',
  'America/Port-au-Prince',
  'America/Indiana/Indianapolis',
  'America/Argentina/Salta',
  'Pacific/Auckland',
  'Australia/Perth',
  'Atlantic/Reykjavik',
  'Indian/Reunion',
  'Europe/Isle_of_Man',
  'UTC',
  'Etc/UTC',
  'GMT',
];

final RegExp _definition = RegExp(r'^String villeDuFuseau\(', multiLine: true);

void main() {
  test('en francais : identique aux trois anciennes fonctions', () {
    expect(LocaleSettings.currentLocale, AppLocale.fr);
    for (final String iana in _corpus) {
      final String unique = villeDuFuseauLibelle(iana);
      expect(unique, _avantSuivi(iana), reason: 'suivi : $iana');
      expect(
        unique,
        _avantRegroupements(iana),
        reason: 'regroupements : $iana',
      );
      expect(unique, _avantCompte(iana), reason: 'compte : $iana');
    }
  });

  test('les appelants rendent les memes phrases qu\'avant', () {
    // Suivi des demandes et frise : « heure de Paris ».
    expect(deFuseau('Europe/Paris'), 'de Paris');
    expect(deFuseau('America/New_York'), 'de New York');
    expect(deFuseau('Asia/Riyadh'), 'de Riyadh');
    expect(deFuseau('Africa/Abidjan'), 'd\'Abidjan');
    expect(deFuseau('Etc/UTC'), 'UTC');
    for (final String iana in _corpus) {
      final String nu = iana.trim();
      if (<String>{'UTC', 'Etc/UTC'}.contains(nu)) continue;
      expect(
        deFuseau(iana),
        '${_elision(_avantSuivi(iana))}${_avantSuivi(iana)}',
        reason: iana,
      );
    }
  });

  test(
    'regroupements : la reference et le fuseau rendent les memes phrases',
    () {
      for (final String iana in _corpus) {
        final RegroupementDemandes g = _regroupement(iana);
        final String avant = deDevant(_avantRegroupements(iana));
        expect(
          libelleFuseau(g),
          'Heure $avant',
          reason: 'libelleFuseau : $iana',
        );
        expect(
          libelleReference(g),
          '${libelleHeureCommune(g)}, heure $avant',
          reason: 'libelleReference : $iana',
        );
      }
    },
  );

  test('compte : la ville du compte rend le nom d\'avant', () {
    for (final String iana in _corpus) {
      final String avant = _avantCompte(iana);
      expect(villeDuFuseauLibelle(iana), avant, reason: 'ville : $iana');
      expect(
        t.compte.tuteur.informations.langueFuseau(
          ville: villeDuFuseauLibelle(iana),
        ),
        'Français · $avant',
        reason: 'langueFuseau : $iana',
      );
    }
  });

  test('aucune definition de villeDuFuseau ne reste dans lib/', () {
    final List<String> restantes = <String>[
      for (final FileSystemEntity f in Directory(
        'lib',
      ).listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            _definition.hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(restantes, isEmpty);
  });

  test('un identifiant degenere ne leve jamais et rend le nom rogne', () {
    expect(villeDuFuseauLibelle(''), '');
    expect(villeDuFuseauLibelle('   '), '');
    expect(villeDuFuseauLibelle(' Europe/Paris '), 'Paris');
    expect(villeDuFuseauLibelle('Europe/'), 'Europe/');
    expect(() => villeDuFuseauLibelle('////'), returnsNormally);
  });
}

RegroupementDemandes _regroupement(String fuseau) => RegroupementDemandes(
  id: 'r',
  public: PublicOffre.enfants,
  langueCode: 'fr',
  langueNom: 'Français',
  fuseau: fuseau,
  occurrences: const <OccurrenceCreneau>[
    OccurrenceCreneau(jourIso: 1, heure: 18),
  ],
  nombreEleves: 3,
  quota: 6,
);

/// « de » ou « d' » devant [nom], comme `deDevant` en francais.
String _elision(String nom) => commenceParVoyelleDe(nom) ? "d'" : 'de ';

bool commenceParVoyelleDe(String nom) {
  const String voyelles = 'aeiouàâäéèêëïîôöùûü';
  if (nom.isEmpty) return false;
  final String m = nom.toLowerCase();
  return m[0] == 'y'
      ? m.length > 1 && !voyelles.contains(m[1])
      : voyelles.contains(m[0]);
}
