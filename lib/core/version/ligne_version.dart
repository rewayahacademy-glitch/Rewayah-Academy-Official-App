// Numero de version en bas du Profil (lot FOYER-UX, 06/11/2026).
//
// Decision du directeur du 03/11/2026, vers 03:42 UTC, mot pour mot :
// « Pour la version on utilise ce qui est compréhensible, pas le technique.
// En plus le mettre en anglais et rien d'autre suffit. »
// (`docs/current/08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md`, 2026-11-03.)
//
// Une seule ligne, en petit, « Version 0.2.0 (423) » : EXCEPTION EXPLICITE a
// la regle i18n, le texte est en anglais dans toutes les langues (la cle
// `compte.version` porte la meme valeur en francais et en arabe). Les valeurs
// sont lues dans `version.json`, jamais ecrites en dur, jamais « 0.2.0+423 ».
// Illisible (hors web, hors ligne, fichier absent) : aucune ligne, jamais une
// version inventee.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../i18n/strings.g.dart';
import '../theme/app_palette.dart';
import 'adresse_version.dart';

/// La version lisible d'un `version.json` : `(version, build)`, ou `null` si
/// le corps ne porte pas de `version`. **Pure.**
({String version, String? build})? versionLisible(String corps) {
  try {
    final Object? brut = jsonDecode(corps);
    if (brut is! Map<String, dynamic>) return null;
    final Object? version = brut['version'];
    if (version is! String || version.trim().isEmpty) return null;
    final Object? build = brut['build_number'];
    final String? b = build == null ? null : '$build'.trim();
    return (
      version: version.trim(),
      build: (b == null || b.isEmpty) ? null : b,
    );
  } on FormatException {
    return null;
  }
}

/// La ligne affichee : « Version 0.2.0 (423) », ou « Version 0.2.0 » sans
/// numero de construction. **Pure.**
String libelleVersion(({String version, String? build}) v) => v.build == null
    ? t.compte.versionSeule(version: v.version)
    : t.compte.version(version: v.version, build: v.build!);

/// Lit `version.json` une fois ; `null` hors web ou en cas d'echec.
final FutureProvider<({String version, String? build})?> versionAppliProvider =
    FutureProvider<({String version, String? build})?>((Ref ref) async {
      final Uri? adresse = adresseVersion();
      if (adresse == null) return null;
      try {
        final http.Response r = await http.get(adresse);
        return r.statusCode == 200 ? versionLisible(r.body) : null;
      } on Object {
        return null;
      }
    });

/// La ligne de version, en petit, en bas du Profil ; rien tant qu'elle n'est
/// pas lue.
class LigneVersion extends ConsumerWidget {
  /// Cree la ligne.
  const LigneVersion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<({String version, String? build})?> lue = ref.watch(
      versionAppliProvider,
    );
    final ({String version, String? build})? v = lue.hasValue && !lue.hasError
        ? lue.requireValue
        : null;
    if (v == null) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    return Text(
      libelleVersion(v),
      // L'anglais se lit de gauche a droite, meme en arabe.
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      style: palette.inkMuted.applyTo(
        Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
      ),
    );
  }
}
