import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce que la fonction Edge `agent-session` rend contre un jeton d'observation.
@immutable
class RemiseAgent {
  /// Cree une remise.
  const RemiseAgent({
    required this.jetonAcces,
    required this.expireA,
    required this.parcours,
    required this.identiteMasquee,
    required this.jetonExpireLe,
  });

  /// Lit la reponse de la fonction Edge.
  factory RemiseAgent.depuisJson(Map<String, dynamic> json) {
    final int expiresAt = (json['expires_at'] as num?)?.toInt() ?? 0;
    return RemiseAgent(
      jetonAcces: json['access_token'] as String? ?? '',
      expireA: DateTime.fromMillisecondsSinceEpoch(
        expiresAt * 1000,
        isUtc: true,
      ),
      parcours: json['parcours'] as String? ?? '',
      identiteMasquee: json['identite_masquee'] as bool? ?? true,
      jetonExpireLe: DateTime.tryParse(json['jeton_expire_le'] as String? ?? '')
          ?.toLocal(),
    );
  }

  /// Le jeton signe, a presenter a PostgREST.
  final String jetonAcces;

  /// Quand ce jeton signe cesse d'etre accepte.
  final DateTime expireA;

  /// Le parcours observe : `student`, `teacher`, `guardian`, `admin`...
  final String parcours;

  /// Vrai quand les prenoms sont remplaces par l'identifiant immuable.
  final bool identiteMasquee;

  /// Quand le jeton d'observation lui-meme expire. La session ne lui survit
  /// jamais.
  final DateTime? jetonExpireLe;

  /// Vrai quand ce jeton signe est encore utilisable.
  bool valideA(DateTime maintenant) =>
      jetonAcces.isNotEmpty && maintenant.toUtc().isBefore(expireA);
}

/// Pourquoi une entree d'agent a echoue.
///
/// Trois causes seulement, et le refus du jeton n'en distingue aucune sous-cause :
/// « inconnu », « revoque » et « expire » rendent volontairement le meme message,
/// en base comme ici.
enum EchecAgent {
  /// Le jeton est refuse par la base.
  jetonRefuse,

  /// La fonction `agent-session` n'a pas repondu, ou le reseau est tombe.
  serviceIndisponible,

  /// La reponse est arrivee mais ne porte pas de jeton exploitable.
  reponseIllisible,
}

/// Echec d'une remise, avec sa cause.
class ErreurAgent implements Exception {
  /// Cree une erreur d'agent.
  const ErreurAgent(this.cause);

  /// La cause du refus.
  final EchecAgent cause;

  @override
  String toString() => 'ErreurAgent(${cause.name})';
}

/// Le porteur d'une session d'observation (ADR-025).
///
/// Il detient le jeton `rag_` en memoire **et nulle part ailleurs** : ni disque,
/// ni stockage du navigateur. Fermer l'onglet met fin a l'observation, et une
/// adresse copiee ne rouvre rien sans le jeton.
///
/// Son unique responsabilite est de rendre un jeton signe **frais** a chaque
/// fois que le client Supabase en demande un. Il n'existe deliberement aucun
/// jeton de rafraichissement : la seule facon de prolonger est de repasser par
/// la fonction Edge, donc par la base, donc par la verification de vivacite du
/// jeton. C'est ce qui rend une revocation effective en moins de quinze minutes
/// meme si le garde central n'etait pas atteint.
class PorteurSessionAgent {
  /// Cree un porteur pour ce jeton d'observation.
  PorteurSessionAgent({
    required this.jeton,
    required this.url,
    required this.cleAnon,
    @visibleForTesting this.echangeur,
  });

  /// Marge avant l'expiration en deca de laquelle on redemande un jeton.
  ///
  /// Sans elle, une requete partie a l'instant precis de l'expiration
  /// reviendrait en 401 alors que tout etait valide au moment de la decision.
  static const Duration _marge = Duration(seconds: 60);

  /// Le jeton d'observation, tel qu'il est arrive dans l'adresse.
  final String jeton;

  /// L'URL du projet Supabase.
  final String url;

  /// La cle publiable, celle du navigateur.
  final String cleAnon;

  /// Remplace l'echange reel dans les tests.
  @visibleForTesting
  final Future<Map<String, dynamic>> Function(String jeton)? echangeur;

  RemiseAgent? _courante;
  Future<RemiseAgent>? _enCours;

  /// La derniere remise obtenue, pour le bandeau d'observation.
  RemiseAgent? get derniere => _courante;

  /// Ouvre la session. A appeler une fois au demarrage, pour echouer tot et en
  /// clair plutot que sur un ecran vide.
  Future<RemiseAgent> ouvrir() => _obtenir(DateTime.now());

  /// Le passe-vole remis a `Supabase.initialize(accessToken: ...)`.
  ///
  /// Rend `null` plutot que de lever : une erreur ici traverserait chaque
  /// requete du client. L'ecran d'entree, lui, a deja dit ce qui n'allait pas.
  Future<String?> jetonFrais() async {
    try {
      final RemiseAgent remise = await _obtenir(DateTime.now());
      return remise.jetonAcces;
    } on Object {
      return null;
    }
  }

  Future<RemiseAgent> _obtenir(DateTime maintenant) {
    final RemiseAgent? courante = _courante;
    if (courante != null && courante.valideA(maintenant.add(_marge))) {
      return Future<RemiseAgent>.value(courante);
    }

    // Une seule remise en vol a la fois : au demarrage, plusieurs ecrans
    // demandent leurs donnees en meme temps, et autant d'echanges paralleles
    // feraient autant d'ecritures de compteur pour une seule ouverture.
    return _enCours ??= _echanger().whenComplete(() => _enCours = null);
  }

  Future<RemiseAgent> _echanger() async {
    final Map<String, dynamic> corps;
    try {
      corps = await (echangeur ?? _remiseReelle)(jeton);
    } on ErreurAgent {
      rethrow;
    } on Object {
      throw const ErreurAgent(EchecAgent.serviceIndisponible);
    }

    final RemiseAgent remise = RemiseAgent.depuisJson(corps);
    if (remise.jetonAcces.isEmpty) {
      throw const ErreurAgent(EchecAgent.reponseIllisible);
    }
    _courante = remise;
    return remise;
  }

  /// L'echange reel.
  ///
  /// Il passe par un client Supabase **jetable**, et non par
  /// `Supabase.instance.client` : ce dernier porte le passe-vole `accessToken`,
  /// qui rappellerait cette meme methode pour se fabriquer un en-tete. Le client
  /// jetable n'a pas de passe-vole, donc pas de boucle.
  Future<Map<String, dynamic>> _remiseReelle(String secret) async {
    final SupabaseClient client = SupabaseClient(url, cleAnon);
    try {
      final FunctionResponse reponse = await client.functions.invoke(
        'agent-session',
        body: <String, String>{'jeton': secret},
      );
      if (reponse.status == 401 || reponse.status == 400) {
        throw const ErreurAgent(EchecAgent.jetonRefuse);
      }
      final Object? data = reponse.data;
      if (data is! Map<String, dynamic>) {
        throw const ErreurAgent(EchecAgent.reponseIllisible);
      }
      return data;
    } on FunctionException catch (e) {
      // `functions.invoke` leve sur les statuts d'erreur selon la version : on
      // retombe sur la meme lecture plutot que sur deux chemins divergents.
      if (e.status == 401 || e.status == 400) {
        throw const ErreurAgent(EchecAgent.jetonRefuse);
      }
      throw const ErreurAgent(EchecAgent.serviceIndisponible);
    } finally {
      unawaited(client.dispose());
    }
  }
}
