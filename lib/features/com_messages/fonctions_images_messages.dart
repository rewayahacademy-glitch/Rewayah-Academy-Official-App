// IMAGES-MESSAGERIE : l'appel des fonctions Edge `message-image-depot` et
// `message-images-lecture` (contrat : `docs/current/IMAGES-MESSAGERIE.md`).
//
// Le client se regle sur le `code` du refus, jamais sur sa phrase ; un statut
// 0 (aucune reponse) est la seule cause qui soit « la connexion ».

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/communications/image_message.dart';

/// Un appel de fonction Edge : nom, corps JSON, reponse JSON. Echoue par
/// [EchecImage].
typedef AppelFonction = Future<Map<String, dynamic>> Function(
  String fonction,
  Map<String, dynamic> corps,
);

/// L'appel de fonction Edge du client Supabase de l'application.
AppelFonction appelFonctionSupabase(SupabaseClient client) =>
    (String fonction, Map<String, dynamic> corps) async {
      try {
        final FunctionResponse reponse = await client.functions.invoke(
          fonction,
          body: corps,
        );
        final Object? donnees = reponse.data;
        return donnees is Map
            ? Map<String, dynamic>.from(donnees)
            : const <String, dynamic>{};
      } on FunctionException catch (e) {
        if (e.status == 0) throw const EchecImage(RefusImage.reseau);
        final Object? details = e.details;
        throw EchecImage(
          RefusImage.depuisCode(details is Map ? details['code'] : null),
        );
      } on EchecImage {
        rethrow;
      } on Object {
        throw const EchecImage(RefusImage.reseau);
      }
    };
