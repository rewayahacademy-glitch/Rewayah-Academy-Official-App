// Lot demarrage, audit du lancement du 25/10/2026 (point b) : dire qu'une
// nouvelle version de l'application est prete, sans la forcer.
//
// Au demarrage, l'application lit `version.json` (ecrit par `flutter build
// web`, servi a cote de `main.dart.js`) et garde `version` et `build_number`.
// Puis toutes les 15 minutes, et a chaque retour au premier plan, elle le
// relit ; si la valeur a change, un bandeau discret le dit en tete de
// l'ecran courant, avec « Recharger ». Hors ligne : aucune requete.
//
// LIMITE constatee le 03/11/2026 (RECHARGE-1) : le workflow ne passe pas
// --build-number, `version.json` vaut toujours « 0.2.0+1 » en production et
// ce bandeau ne s'affichait jamais. L'empreinte porte donc aussi l'ETag de
// `main.dart.js` (servi par Vercel, il change avec le contenu) : un
// deploiement qui change le code change l'empreinte, sans numero de build.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../reseau/service_reseau.dart';
import 'adresse_version.dart';

/// La cadence de relecture de `version.json`.
const Duration cadenceVersion = Duration(minutes: 15);

/// L'empreinte d'un `version.json` : `version+build_number`, ou `null` si le
/// corps est illisible ou ne porte ni l'une ni l'autre.
String? empreinteVersion(String corps) {
  try {
    final Object? brut = jsonDecode(corps);
    if (brut is! Map<String, dynamic>) return null;
    final Object? version = brut['version'];
    final Object? build = brut['build_number'];
    if (version == null && build == null) return null;
    return '${version ?? ''}+${build ?? ''}';
  } on FormatException {
    return null;
  }
}

/// L'empreinte complete : celle de `version.json` et l'ETag de
/// `main.dart.js` quand le serveur en donne un. `null` si aucune des deux
/// n'est lisible. **Pure.**
String? empreinteServie(String? versionJson, String? etagCode) {
  final String? etag = (etagCode == null || etagCode.trim().isEmpty)
      ? null
      : etagCode.trim();
  if (versionJson == null && etag == null) return null;
  return '${versionJson ?? ''}#${etag ?? ''}';
}

/// Lit l'empreinte de la version servie, `null` si rien n'est lisible.
typedef LecteurVersion = Future<String?> Function();

/// La lecture reelle : `version.json` et l'ETag de `main.dart.js`, sans cache
/// (parametre unique) ; hors web aucune requete.
Future<String?> lireVersionServie() async {
  final Uri? adresse = adresseVersion();
  if (adresse == null) return null;
  final Uri sansCache = adresse.replace(
    queryParameters: <String, String>{
      'v': DateTime.now().millisecondsSinceEpoch.toString(),
    },
  );
  final http.Response reponse = await http.get(sansCache);
  final String? version = reponse.statusCode == 200
      ? empreinteVersion(reponse.body)
      : null;
  String? etag;
  try {
    final http.Response code = await http.head(
      adresse
          .resolve('main.dart.js')
          .replace(queryParameters: sansCache.queryParameters),
    );
    if (code.statusCode == 200) etag = code.headers['etag'];
  } on Object {
    // Sans ETag, l'empreinte de `version.json` seule.
  }
  return empreinteServie(version, etag);
}

/// La lecture employee (surchargee dans les tests).
final Provider<LecteurVersion> lecteurVersionProvider =
    Provider<LecteurVersion>((Ref ref) => lireVersionServie);

/// Vrai : la surveillance tourne. Seul le web sert un `version.json` ; hors
/// web (et dans les tests qui ne la demandent pas), aucune minuterie.
final Provider<bool> surveillanceVersionActiveProvider = Provider<bool>(
  (Ref ref) => kIsWeb,
);

/// Vrai quand la version servie n'est plus celle du demarrage.
final NotifierProvider<SurveillanceVersion, bool> nouvelleVersionProvider =
    NotifierProvider<SurveillanceVersion, bool>(SurveillanceVersion.new);

/// Lit la version au demarrage, puis toutes les [cadenceVersion] et a chaque
/// retour au premier plan ; passe a vrai, une fois pour toutes, quand elle a
/// change.
class SurveillanceVersion extends Notifier<bool> {
  String? _initiale;
  Timer? _minuterie;
  AppLifecycleListener? _cycle;
  bool _enCours = false;

  @override
  bool build() {
    if (!ref.watch(surveillanceVersionActiveProvider)) return false;
    // Garde l'etat du reseau lu : sans abonnement, `horsLigneProvider` resterait
    // en chargement et une lecture hors ligne partirait.
    ref.listen<AsyncValue<bool>>(horsLigneProvider, (_, _) {});
    _minuterie = Timer.periodic(cadenceVersion, (_) => verifier());
    _cycle = AppLifecycleListener(onResume: verifier);
    ref.onDispose(() {
      _minuterie?.cancel();
      _cycle?.dispose();
    });
    // Apres `build` : l'etat n'existe pas encore pendant.
    Future<void>.microtask(verifier);
    return false;
  }

  /// Relit `version.json` ; rien hors ligne, rien une fois le changement vu.
  Future<void> verifier() async {
    if (state || _enCours) return;
    if (ref.read(horsLigneProvider).value ?? false) return;
    _enCours = true;
    try {
      final String? lue = await ref.read(lecteurVersionProvider)();
      if (lue == null) return;
      final String? initiale = _initiale;
      if (initiale == null) {
        _initiale = lue;
      } else if (lue != initiale) {
        _minuterie?.cancel();
        state = true;
      }
    } on Object {
      // Une lecture qui echoue n'est pas un incident : on relira plus tard.
    } finally {
      _enCours = false;
    }
  }
}
