// L2-02 : l'apercu d'une piece passe par la porte `piece-identite-acces`.
// Le client n'envoie que l'identifiant du document, jamais une cle d'objet.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  int statut = HttpStatus.ok;
  Object? reponse;
  String? chemin;
  String? corpsRecu;

  setUp(() async {
    statut = HttpStatus.ok;
    reponse = <String, Object?>{
      'url': 'https://signee.invalid/piece?sig=fictif',
      'expire_dans_secondes': 60,
    };
    chemin = null;
    corpsRecu = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest requete) async {
      chemin = requete.uri.path;
      corpsRecu = await utf8.decoder.bind(requete).join();
      requete.response
        ..statusCode = statut
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(reponse));
      await requete.response.close();
    });
    client = SupabaseClient(
      'http://${server.address.address}:${server.port}',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test('appelle la fonction Edge avec le seul document_id et rend l’URL',
      () async {
    final String url = await ServiceValidationSupabase(client).apercu('doc-7');

    expect(url, 'https://signee.invalid/piece?sig=fictif');
    expect(chemin, '/functions/v1/piece-identite-acces');
    expect(jsonDecode(corpsRecu!), <String, Object?>{'document_id': 'doc-7'});
  });

  test('un refus 403 devient ApercuRefuse, pas une panne', () async {
    statut = HttpStatus.forbidden;
    reponse = <String, Object?>{'error': 'acces a la piece refuse'};

    await expectLater(
      ServiceValidationSupabase(client).apercu('doc-8'),
      throwsA(isA<ApercuRefuse>()),
    );
    expect(chemin, '/functions/v1/piece-identite-acces');
  });

  test('un autre statut d’erreur reste une erreur, non masquee', () async {
    statut = HttpStatus.notFound;
    reponse = <String, Object?>{'error': 'document non trouve'};

    await expectLater(
      ServiceValidationSupabase(client).apercu('doc-9'),
      throwsA(isNot(isA<ApercuRefuse>())),
    );
  });
}
