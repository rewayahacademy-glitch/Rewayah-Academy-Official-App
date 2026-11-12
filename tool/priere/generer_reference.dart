// Genere la reference de la preuve PRIERE-1 : les heures de priere que le paquet
// Dart `adhan` (celui que l'application employait) calcule pour une matrice de
// lieux, de dates, de methodes et d'ecoles d'Asr. Le calcul SQL du serveur
// (private.priere_calculer) est compare a ce fichier par
// supabase/tests/scenarios_priere_serveur.sql, avec un ecart maximal de 2 minutes.
//
// Usage, depuis la racine du depot (le fichier est ecrit dans supabase/tests) :
//   TZ=UTC dart run tool/priere/generer_reference.dart
//
// Une ligne par combinaison. Les heures sont des secondes UTC depuis 1970 ; une
// case vide veut dire que le paquet ne sait pas calculer (il leve une erreur : le
// soleil ne se leve ou ne se couche pas), et le serveur doit rendre zero ligne.
import 'dart:io';

import 'package:adhan/adhan.dart' as adhan;

const List<(String, double, double)> lieux = <(String, double, double)>[
  ('Conakry', 9.6412, -13.5784),
  ('Dakar', 14.6937, -17.4441),
  ('Paris', 48.8566, 2.3522),
  ('Montreal', 45.5017, -73.5673),
  ('Londres', 51.5074, -0.1278),
  ('Reykjavik', 64.1466, -21.9426),
  ('Tromso', 69.6492, 18.9553),
  ('Sydney', -33.8688, 151.2093),
];

const List<String> methodesPrincipales = <String>[
  'muslim_world_league',
  'egyptian',
  'umm_al_qura',
];

const List<String> toutesLesMethodes = <String>[
  'muslim_world_league',
  'egyptian',
  'karachi',
  'umm_al_qura',
  'dubai',
  'moon_sighting_committee',
  'north_america',
  'kuwait',
  'qatar',
  'singapore',
  'turkey',
  'tehran',
];

adhan.CalculationParameters parametres(String methode) => switch (methode) {
  'muslim_world_league' => adhan.CalculationMethod.muslim_world_league,
  'egyptian' => adhan.CalculationMethod.egyptian,
  'karachi' => adhan.CalculationMethod.karachi,
  'umm_al_qura' => adhan.CalculationMethod.umm_al_qura,
  'dubai' => adhan.CalculationMethod.dubai,
  'moon_sighting_committee' => adhan.CalculationMethod.moon_sighting_committee,
  'north_america' => adhan.CalculationMethod.north_america,
  'kuwait' => adhan.CalculationMethod.kuwait,
  'qatar' => adhan.CalculationMethod.qatar,
  'singapore' => adhan.CalculationMethod.singapore,
  'turkey' => adhan.CalculationMethod.turkey,
  'tehran' => adhan.CalculationMethod.tehran,
  _ => throw ArgumentError(methode),
}.getParameters();

String ligne(
  (String, double, double) lieu,
  DateTime jour,
  String methode,
  String ecole,
) {
  final adhan.CalculationParameters p = parametres(methode)
    ..madhab = ecole == 'hanafi' ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
  String date =
      '${jour.year}-${jour.month.toString().padLeft(2, '0')}-${jour.day.toString().padLeft(2, '0')}';
  List<String> heures;
  try {
    final adhan.PrayerTimes t = adhan.PrayerTimes.utc(
      adhan.Coordinates(lieu.$2, lieu.$3),
      adhan.DateComponents(jour.year, jour.month, jour.day),
      p,
    );
    heures = <DateTime>[t.fajr, t.dhuhr, t.asr, t.maghrib, t.isha]
        .map((DateTime d) => (d.millisecondsSinceEpoch ~/ 1000).toString())
        .toList();
  } on ArgumentError {
    heures = <String>['', '', '', '', ''];
  }
  return <String>[
    lieu.$1,
    lieu.$2.toString(),
    lieu.$3.toString(),
    date,
    methode,
    ecole,
    ...heures,
  ].join(',');
}

void main() {
  // 24 dates reparties sur l'annee : le 1er et le 16 de chaque mois, de decembre
  // 2026 a novembre 2027.
  final List<DateTime> dates = <DateTime>[];
  for (int i = 0; i < 12; i++) {
    final int mois = 12 + i;
    final int annee = 2026 + (mois - 1) ~/ 12;
    final int m = (mois - 1) % 12 + 1;
    dates
      ..add(DateTime.utc(annee, m, 1))
      ..add(DateTime.utc(annee, m, 16));
  }
  final Set<String> vues = <String>{};
  final List<String> lignes = <String>[];
  void ajouter((String, double, double) lieu, DateTime j, String m, String e) {
    final String cle = '${lieu.$1}|$j|$m|$e';
    if (vues.add(cle)) {
      lignes.add(ligne(lieu, j, m, e));
    }
  }

  // Matrice principale : 8 lieux x 24 dates x 3 methodes x 2 ecoles = 1152.
  for (final lieu in lieux) {
    for (final DateTime j in dates) {
      for (final String m in methodesPrincipales) {
        for (final String e in <String>['shafi', 'hanafi']) {
          ajouter(lieu, j, m, e);
        }
      }
    }
  }
  // Complement : les douze methodes sur trois lieux et quatre dates.
  for (final lieu in <(String, double, double)>[lieux[0], lieux[2], lieux[5]]) {
    for (final DateTime j in <DateTime>[dates[0], dates[6], dates[12], dates[18]]) {
      for (final String m in toutesLesMethodes) {
        for (final String e in <String>['shafi', 'hanafi']) {
          ajouter(lieu, j, m, e);
        }
      }
    }
  }

  final File sortie = File('supabase/tests/fixtures/priere_reference_adhan.csv');
  sortie.parent.createSync(recursive: true);
  sortie.writeAsStringSync(
    'lieu,latitude,longitude,jour,methode,ecole,fajr,dhuhr,asr,maghrib,isha\n'
    '${lignes.join('\n')}\n',
  );
  stdout.writeln('${lignes.length} lignes ecrites dans ${sortie.path}');
}
