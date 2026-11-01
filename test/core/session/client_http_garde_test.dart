// Session coupee cote serveur (prod du 01/11/2026, 18:09 UTC) : une 401 de
// PostgREST qui refuse le JETON declenche la fin de session, une fois par
// intervalle ; toute autre reponse passe intacte.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/session/client_http_garde.dart';
import 'package:rewayah_academy/core/session/source_session.dart'
    show jetonRefuse;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  const String jwtExpire =
      '{"code":"PGRST303","details":null,"hint":null,"message":"JWT expired"}';

  ClientHttpGarde client(
    int statut,
    String corps,
    List<int> appels, {
    DateTime Function()? maintenant,
  }) => ClientHttpGarde(
    MockClient((http.Request _) async => http.Response(corps, statut)),
    surJetonRefuse: () async => appels.add(1),
    maintenant: maintenant,
  );

  test('401 de la base qui refuse le jeton : fin de session demandee, '
      'reponse rendue intacte', () async {
    final List<int> appels = <int>[];
    final http.Response r = await client(
      401,
      jwtExpire,
      appels,
    ).get(Uri.parse('https://x.supabase.co/rest/v1/profiles'));
    expect(appels, hasLength(1));
    expect(r.statusCode, 401);
    expect(r.body, jwtExpire);
  });

  test('rafale de 401 : une seule demande par intervalle', () async {
    final List<int> appels = <int>[];
    DateTime t = DateTime(2026, 11, 1, 18, 9);
    final ClientHttpGarde c = client(
      401,
      jwtExpire,
      appels,
      maintenant: () => t,
    );
    final Uri u = Uri.parse('https://x.supabase.co/rest/v1/rpc/etat_dossier');
    for (int i = 0; i < 10; i++) {
      await c.post(u);
    }
    expect(appels, hasLength(1));
    t = t.add(const Duration(seconds: 21));
    await c.post(u);
    expect(appels, hasLength(2));
  });

  test('ni 401, ni hors de la base, ni refus de ligne : rien', () async {
    final List<int> appels = <int>[];
    await client(
      403,
      '{"code":"42501"}',
      appels,
    ).get(Uri.parse('https://x.supabase.co/rest/v1/profiles'));
    await client(
      401,
      jwtExpire,
      appels,
    ).get(Uri.parse('https://x.supabase.co/functions/v1/recharge-payer'));
    await client(
      401,
      '{"code":"42501","message":"permission denied"}',
      appels,
    ).get(Uri.parse('https://x.supabase.co/rest/v1/profiles'));
    await client(
      200,
      '[]',
      appels,
    ).get(Uri.parse('https://x.supabase.co/rest/v1/profiles'));
    expect(appels, isEmpty);
  });

  test('jetonRefuse : codes PGRST301 a 303 et « JWT expired »', () {
    expect(
      jetonRefuse(const PostgrestException(message: 'x', code: 'PGRST301')),
      isTrue,
    );
    expect(
      jetonRefuse(const PostgrestException(message: 'JWT expired')),
      isTrue,
    );
    expect(
      jetonRefuse(
        const PostgrestException(message: 'permission denied', code: '42501'),
      ),
      isFalse,
    );
  });
}
