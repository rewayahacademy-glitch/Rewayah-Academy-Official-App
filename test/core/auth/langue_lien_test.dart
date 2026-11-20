// LANGUE-LIEN (pilote, 20/11/2026) : la langue de l'interface voyage avec la
// demande du lien de connexion (`data.langue`), sans rien changer d'autre a
// l'appel. Ce que le test prouve : la requete `/otp` porte `data.langue` (fr,
// ar), le jeton du controle et l'adresse inchanges.
//
// Ce qu'il ne prouve pas : qu'un compte deja confirme garde sa langue. C'est
// le serveur d'authentification qui decide (`data` ne sert qu'a l'inscription
// d'un compte non confirme) ; non verifie sur l'instance de production.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, AuthFlowType, SupabaseClient;

Future<Map<String, dynamic>> _demande(AppLocale langue) async {
  await LocaleSettings.setLocale(langue);
  final List<http.Request> appels = <http.Request>[];
  final SupabaseClient client = SupabaseClient(
    'https://exemple.supabase.test',
    'cle-publique',
    // Le flux PKCE demande un stockage ; il ne change pas `data`.
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    httpClient: MockClient((http.Request r) async {
      appels.add(r);
      return http.Response('{}', 200);
    }),
  );
  addTearDown(client.dispose);
  await ServiceAuthSupabase(client)
      .envoyerLienCourriel(' ami@example.test ', jetonControle: 'jeton-1');
  final http.Request otp = appels.singleWhere(
    (http.Request r) => r.url.path.endsWith('/auth/v1/otp'),
  );
  return jsonDecode(otp.body) as Map<String, dynamic>;
}

void main() {
  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  test('la langue de l interface part avec la demande', () async {
    final Map<String, dynamic> fr = await _demande(AppLocale.fr);
    expect(fr['data'], <String, dynamic>{'langue': 'fr'});
    expect(fr['email'], 'ami@example.test');
    expect(fr['create_user'], isTrue);
    expect(
      (fr['gotrue_meta_security'] as Map<String, dynamic>)['captcha_token'],
      'jeton-1',
    );

    final Map<String, dynamic> ar = await _demande(AppLocale.ar);
    expect(ar['data'], <String, dynamic>{'langue': 'ar'});
  });
}
