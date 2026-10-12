import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/controle/port_tirage_controle.dart';
import 'package:rewayah_academy/core/controle/port_tirage_controle_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  final List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];

  setUp(() async {
    requests.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      final String body = await utf8.decoder.bind(request).join();
      requests.add(<String, dynamic>{
        'path': request.uri.path,
        'body': body.isEmpty ? <String, dynamic>{} : jsonDecode(body),
      });
      final Object response = request.uri.path.endsWith('/lire_regles_tirage')
          ? <String, dynamic>{
              'version': 7,
              'missions_par_semaine': 5,
              'ponderations': <String, String>{
                'enseignants_recents': 'normal',
                'classes_signalees': 'fort',
                'heures_de_pointe': 'aucun',
              },
              'cibles': <Object>[],
            }
          : <String, dynamic>{'statut': 'enregistrees', 'version': 8};
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
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

  test('lit et retourne les versions de regles et de mutation', () async {
    final PortTirageControleSupabase port = PortTirageControleSupabase(client);
    expect((await port.regles()).version, 7);
    final ResultatRegles saved = await port.enregistrer(
      const ReglesTirage(
        version: 7,
        missionsParSemaine: 5,
        ponderations: <CriterePonderation, NiveauPonderation>{
          CriterePonderation.enseignantsRecents: NiveauPonderation.normal,
          CriterePonderation.classesSignalees: NiveauPonderation.fort,
          CriterePonderation.heuresDePointe: NiveauPonderation.aucun,
        },
        cibles: <CibleTirage>[],
      ),
      cleEnvoi: 'c2911000-0000-0000-0000-000000000001',
    );
    expect(saved, isA<ReglesEnregistrees>());
    expect((saved as ReglesEnregistrees).version, 8);
    expect(requests.map((Map<String, dynamic> row) => row['path']), <String>[
      '/rest/v1/rpc/lire_regles_tirage',
      '/rest/v1/rpc/enregistrer_regles_tirage',
    ]);
  });
}
