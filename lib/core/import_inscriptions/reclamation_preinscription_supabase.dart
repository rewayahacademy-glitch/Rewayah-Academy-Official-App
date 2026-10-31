/// Adaptateur IMM-ACCUEIL-FRONT : `reclamer_preinscription_apres_preuve()`
/// (migrations 20261012185327 et 20261101000000). Le jeton de la session
/// decide ; aucune cle de service. La reponse est lue strictement : une forme
/// inattendue est un echec, jamais une famille inconnue.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_delais.dart';
import 'port_reclamation_preinscription.dart';

/// La reclamation servie par Supabase.
class ReclamationPreinscriptionSupabase
    implements PortReclamationPreinscription {
  /// Cree l'adaptateur sur le client de l'application.
  ReclamationPreinscriptionSupabase(SupabaseClient client)
    : _appel = (() =>
          client.rpc<Object?>('reclamer_preinscription_apres_preuve'));

  /// Cree l'adaptateur sur un appel injecte (tests).
  ReclamationPreinscriptionSupabase.avecAppel(this._appel);

  final Future<Object?> Function() _appel;

  @override
  bool get disponible => true;

  @override
  Future<ReclamationPreinscription> reclamer() async {
    final Object? reponse;
    try {
      reponse = await _appel().timeout(AppDelais.demarrageMax);
    } on PostgrestException {
      throw const ReclamationEnEchec();
    } on Object {
      throw const ReclamationInjoignable();
    }
    return lireReclamation(reponse);
  }
}

/// Lit la reponse du serveur. Fonction pure, testee seule.
///
/// `email_prouve` faux ou `inscription_connue` faux : aucune pre-inscription,
/// le parcours habituel. Toute autre forme : [ReclamationEnEchec].
ReclamationPreinscription lireReclamation(Object? reponse) {
  if (reponse is! Map) {
    throw const ReclamationEnEchec();
  }
  final Object? prouve = reponse['email_prouve'];
  final Object? connue = reponse['inscription_connue'];
  if (prouve is! bool || connue is! bool) {
    throw const ReclamationEnEchec();
  }
  if (!prouve || !connue) {
    return const ReclamationPreinscription.inconnue();
  }
  final Object? personnes = reponse['personnes'];
  if (personnes is! List) {
    throw const ReclamationEnEchec();
  }
  final List<PersonneImportee> lues = <PersonneImportee>[];
  for (final Object? p in personnes) {
    if (p is! Map) {
      throw const ReclamationEnEchec();
    }
    final Object? id = p['id'];
    final Object? prenom = p['prenom'];
    if (id is! String) {
      throw const ReclamationEnEchec();
    }
    lues.add(
      PersonneImportee(
        id: id,
        prenom: prenom is String ? prenom.trim() : '',
        nature: NaturePersonneImportee.depuisServeur(p['type']),
      ),
    );
  }
  return ReclamationPreinscription(
    connue: true,
    motAccueil:
        _texte(reponse['message_patience']) ??
        _texte(reponse['message_accueil']),
    personnes: lues,
  );
}

String? _texte(Object? valeur) {
  if (valeur is! String) {
    return null;
  }
  final String nettoye = valeur.trim();
  return nettoye.isEmpty ? null : nettoye;
}
