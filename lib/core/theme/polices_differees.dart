import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../observabilite/journal_dev.dart';

/// Les polices arabes et du Coran, a charger apres la premiere image (lot
/// ouverture rapide, 29/10/2026) : 1,2 Mo a eux trois, inutiles a l'ecran de
/// connexion en francais.
///
/// Le moteur web de Flutter attend toutes les polices de
/// `assets/FontManifest.json` avant sa premiere image. Tant que ces trois
/// familles sont declarees dans la section `fonts` du pubspec, elles y sont,
/// et [chargerPolicesDifferees] ne fait rien. Quand le directeur les deplace
/// dans la section `assets` (rapport `docs/current/OUVERTURE-RAPIDE-2026-10-29.md`),
/// elles sortent du manifeste et cette fonction les charge, en arriere-plan,
/// une fois l'application ouverte ; le texte se redessine de lui-meme.
const Map<String, String> policesDifferees = <String, String>{
  'NotoSansArabic': 'assets/fonts/NotoSansArabic-Variable.ttf',
  'UthmanicHafs': 'assets/fonts/UthmanicHafs-v-3.0.ttf',
  'UthmanTahaNaskh': 'assets/fonts/UthmanTahaNaskh-Regular.otf',
};

/// Charge celles des [policesDifferees] que le manifeste des polices ne
/// declare pas ; rend les familles chargees. Ne leve jamais : une police qui
/// manque laisse le texte dans la police de repli, l'application continue.
Future<List<String>> chargerPolicesDifferees({AssetBundle? paquet}) async {
  final AssetBundle source = paquet ?? rootBundle;
  final Set<String> declarees = <String>{};
  try {
    final Object? manifeste = jsonDecode(
      await source.loadString('FontManifest.json'),
    );
    if (manifeste is List<Object?>) {
      for (final Object? entree in manifeste) {
        if (entree is Map<String, Object?> && entree['family'] is String) {
          declarees.add(entree['family']! as String);
        }
      }
    }
  } on Object catch (erreur) {
    journalDev('Manifeste des polices illisible : $erreur');
    return const <String>[];
  }
  final List<String> chargees = <String>[];
  for (final MapEntry<String, String> police in policesDifferees.entries) {
    if (declarees.contains(police.key)) {
      continue;
    }
    try {
      await (FontLoader(police.key)..addFont(source.load(police.value))).load();
      chargees.add(police.key);
    } on Object catch (erreur) {
      journalDev('Police ${police.key} non chargee : $erreur');
    }
  }
  return chargees;
}
