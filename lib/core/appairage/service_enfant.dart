import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ce qu'un appairage rend a l'appareil de l'enfant.
@immutable
class AppairageReussi {
  /// Cree le resultat d'un appairage.
  const AppairageReussi({
    required this.profilId,
    required this.prenom,
    required this.jetonAppareil,
  });

  /// Le profil auquel l'appareil vient d'etre appaire.
  final String profilId;

  /// Le prenom, pour la tuile de choix de profil.
  final String prenom;

  /// Le jeton emis par le serveur. **Rendu une seule fois** : la base n'en garde
  /// que l'empreinte. Il doit etre ecrit dans le coffre du systeme
  /// immediatement, sinon l'appairage est a refaire.
  final String jetonAppareil;
}

/// La connexion de l'eleve, cote appareil de l'enfant.
///
/// L'enfant n'a ni courriel ni mot de passe. Sa ligne `profiles` reference
/// pourtant `auth.users`, et une session Supabase ne se fabrique pas cote
/// client : les deux operations passent donc par une fonction Edge, seule
/// detentrice de la cle de service.
abstract interface class ServiceEnfant {
  /// Echange un code d'appairage contre une session et un jeton d'appareil.
  Future<AppairageReussi> appairer({
    required String code,
    required String empreinteAppareil,
    required String plateforme,
  });

  /// Rouvre une session a partir du jeton deja stocke sur l'appareil.
  Future<void> ouvrirSession(String jetonAppareil);
}

/// L'implementation reelle.
class ServiceEnfantSupabase implements ServiceEnfant {
  /// Cree le service.
  const ServiceEnfantSupabase(this._client);

  final SupabaseClient _client;

  /// Le nom de la fonction Edge.
  static const String fonction = 'session-enfant';

  @override
  Future<AppairageReussi> appairer({
    required String code,
    required String empreinteAppareil,
    required String plateforme,
  }) async {
    final FunctionResponse reponse = await _client.functions.invoke(
      fonction,
      body: <String, dynamic>{
        'code': code,
        'device_fingerprint': empreinteAppareil,
        'platform': plateforme,
      },
    );

    final Map<String, dynamic> corps = _corps(reponse);
    await _ouvrirDepuis(corps);

    return AppairageReussi(
      profilId: corps['profile_id'] as String,
      prenom: corps['first_name'] as String? ?? '',
      jetonAppareil: corps['device_token'] as String,
    );
  }

  @override
  Future<void> ouvrirSession(String jetonAppareil) async {
    final FunctionResponse reponse = await _client.functions.invoke(
      fonction,
      body: <String, dynamic>{'device_token': jetonAppareil},
    );
    await _ouvrirDepuis(_corps(reponse));
  }

  Map<String, dynamic> _corps(FunctionResponse reponse) {
    final Object? donnees = reponse.data;
    if (donnees is! Map<String, dynamic>) {
      throw StateError('reponse inattendue de la fonction $fonction');
    }
    final Object? erreur = donnees['error'];
    if (erreur != null) {
      throw StateError(erreur.toString());
    }
    return donnees;
  }

  /// Ouvre la session a partir du jeton a usage unique rendu par la fonction.
  ///
  /// La fonction Edge ne rend jamais de jeton d'acces tout fait : elle rend un
  /// jeton de courriel a usage unique, que le client echange lui-meme. Le jeton
  /// d'acces ne transite donc jamais dans un corps de reponse que l'on
  /// pourrait journaliser par accident.
  Future<void> _ouvrirDepuis(Map<String, dynamic> corps) async {
    await _client.auth.verifyOTP(
      type: OtpType.magiclink,
      tokenHash: corps['token_hash'] as String,
    );
  }
}

/// Le service employe par l'application.
final Provider<ServiceEnfant> serviceEnfantProvider = Provider<ServiceEnfant>(
  (Ref ref) => ServiceEnfantSupabase(Supabase.instance.client),
);
