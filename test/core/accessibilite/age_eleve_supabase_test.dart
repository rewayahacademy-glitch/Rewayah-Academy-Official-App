import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/age_eleve.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient(
      'http://127.0.0.1:54321',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async => client.dispose());

  test('mappe uniquement les claims enfant et adulte', () async {
    await _installerSession(
      client,
      _jwt(<String, Object>{'tranche_age': 'enfant'}),
    );
    expect(AgeEleveSupabase(client).ageDeLEleve(), AgeEleve.mineur);

    await _installerSession(
      client,
      _jwt(<String, Object>{'tranche_age': 'adulte'}),
    );
    expect(AgeEleveSupabase(client).ageDeLEleve(), AgeEleve.adulte);
  });

  test('les claims absents ou inattendus restent inconnus', () async {
    for (final Map<String, Object> claims in <Map<String, Object>>[
      <String, Object>{},
      <String, Object>{'tranche_age': 'minor'},
      <String, Object>{'tranche_age': 18},
    ]) {
      await _installerSession(client, _jwt(claims));
      expect(AgeEleveSupabase(client).ageDeLEleve(), AgeEleve.inconnu);
    }
  });

  test('un JWT malformé ne détermine pas l’âge', () async {
    await _installerSession(client, 'header.payload.signature');
    expect(AgeEleveSupabase(client).ageDeLEleve(), AgeEleve.inconnu);
  });

  test('sans session l’âge reste inconnu', () {
    expect(AgeEleveSupabase(client).ageDeLEleve(), AgeEleve.inconnu);
  });
}

Future<void> _installerSession(SupabaseClient client, String token) async {
  await client.auth.recoverSession(
    jsonEncode(<String, Object>{
      'access_token': token,
      'refresh_token': 'refresh-fictif',
      'token_type': 'bearer',
      'user': <String, String>{'id': 'eleve-1'},
    }),
  );
}

String _jwt(Map<String, Object> claims) {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode(<String, Object>{'alg': 'none', 'typ': 'JWT'})}.'
      '${encode(claims)}.signature-fictive';
}
