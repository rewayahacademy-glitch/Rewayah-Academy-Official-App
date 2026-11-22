// REF-SUIVI (directeur, 22/11/2026) : savoir quelle organisation a envoye
// chaque famille. Un courriel de mosquee porte un lien du site
// (`/en/familles?ref=chingford-londres`) ; le site garde ce `ref` et le recopie
// sur ses liens vers la connexion, qui arrivent ici avec `?ref=...`.
//
// Au demarrage, l'application lit `ref` dans l'adresse (forme `[a-z0-9-]{1,48}`,
// la meme que le CHECK du serveur) et le garde sur l'appareil (memoire de
// l'appareil, 30 jours) sans jamais ecraser une valeur plus ancienne encore
// valable : la premiere organisation gagne. Des que la personne est connectee,
// une seule porte serveur (`noter_source_inscription`, migration
// 20261130978000) la note pour son compte, une fois ; la valeur locale est
// alors effacee. Une panne la laisse en place pour la prochaine ouverture.
// Rien ici ne decide quoi que ce soit : la source est une statistique.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/inscription/questionnaire/memoire_appareil.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import '../theme/app_delais.dart';

/// La cle de la memoire de l'appareil : `ref|date ISO`.
const String cleSourceInscription = 'rewayah.source_ref';

/// Au-dela, la source gardee sur l'appareil est oubliee.
const Duration dureeSourceInscription = Duration(days: 30);

final RegExp _formeRef = RegExp(r'^[a-z0-9-]{1,48}$');

/// [brut] s'il a la forme d'un `ref`, sinon `null`.
String? refValide(String? brut) =>
    brut != null && _formeRef.hasMatch(brut) ? brut : null;

/// Au demarrage : garde le `ref` de [adresse] (par defaut l'adresse de la page)
/// s'il est valide et qu'aucune source encore valable n'est deja gardee.
void capturerSourceInscription({Uri? adresse, DateTime? maintenant}) {
  final String? ref = refValide((adresse ?? Uri.base).queryParameters['ref']);
  if (ref == null) return;
  final DateTime instant = maintenant ?? DateTime.now();
  if (_lireValable(instant) != null) return;
  ecrireMemoireAppareil(
    cleSourceInscription,
    '$ref|${instant.toUtc().toIso8601String()}',
  );
}

/// La source gardee sur l'appareil, encore valable, ou `null`.
String? sourceInscriptionEnAttente({DateTime? maintenant}) =>
    _lireValable(maintenant ?? DateTime.now());

String? _lireValable(DateTime instant) {
  final String? brut = lireMemoireAppareil(cleSourceInscription);
  if (brut == null) return null;
  final List<String> morceaux = brut.split('|');
  final String? ref = refValide(morceaux.first);
  final DateTime? le = morceaux.length == 2
      ? DateTime.tryParse(morceaux[1])
      : null;
  if (ref == null || le == null) return null;
  return instant.difference(le) < dureeSourceInscription ? ref : null;
}

/// Ce que la porte serveur repond : `true` si la source est posee, `false`
/// si le compte en avait deja une. Une erreur leve.
typedef NoterSource = Future<bool> Function(String ref);

/// La porte serveur ; nulle hors du demarrage applicatif (tests).
final Provider<NoterSource?> noterSourceProvider = Provider<NoterSource?>((
  Ref ref,
) {
  try {
    final SupabaseClient client = Supabase.instance.client;
    return (String r) async {
      final Object? reponse = await client
          .rpc(
            'noter_source_inscription',
            params: <String, Object?>{'p_ref': r},
          )
          .timeout(AppDelais.requeteMax);
      return reponse == true;
    };
  } on Object {
    return null;
  }
});

/// Ouverte avec la session : une fois par ouverture, envoie la source gardee
/// et l'efface si le serveur a repondu (posee ou deja connue) ou refuse la
/// forme ; la laisse en cas de panne.
final Provider<void> veilleSourceInscriptionProvider = Provider<void>((
  Ref ref,
) {
  final bool connecte = ref.watch(
    sessionProvider.select(
      (SessionState s) => s.profileId != null && s.observation == null,
    ),
  );
  if (!connecte) return;
  final String? enAttente = sourceInscriptionEnAttente();
  final NoterSource? noter = ref.read(noterSourceProvider);
  if (enAttente == null || noter == null) return;
  unawaited(() async {
    try {
      await noter(enAttente);
      effacerMemoireAppareil(cleSourceInscription);
    } on PostgrestException catch (e) {
      // 22023 : forme refusee, elle ne passera jamais ; le reste est une panne.
      if (e.code == '22023') effacerMemoireAppareil(cleSourceInscription);
    } on Object {
      return;
    }
  }());
});
