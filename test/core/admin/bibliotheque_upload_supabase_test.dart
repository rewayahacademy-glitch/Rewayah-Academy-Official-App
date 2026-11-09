import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rewayah_academy/core/admin/bibliotheque_upload_supabase.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient supabase;
  late _TransportEnregistre transport;
  final List<Map<String, dynamic>> actions = <Map<String, dynamic>>[];

  setUp(() async {
    actions.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest request) async {
      final Map<String, dynamic> corps = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      actions.add(corps);
      final Object resultat = switch (corps['action']) {
        'demander' => <String, Object?>{
          'upload_id': 'c2900000-0000-0000-0000-000000000001',
          'expire_le_utc': '2026-10-12T12:01:00Z',
          'url': 'https://r2.example.test/signe',
          'methode': 'PUT',
          'en_tetes_exiges': <String, String>{
            'content-type': 'application/pdf',
            'content-length': '4',
          },
        },
        'confirmer' => <String, Object?>{'phase': 'pret'},
        'annuler' => <String, Object?>{'annule': true},
        _ => <String, Object?>{'erreur': 'action inconnue'},
      };
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(resultat));
      await request.response.close();
    });
    supabase = SupabaseClient(
      'http://${server.address.address}:${server.port}',
      'cle-fictive',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    transport = _TransportEnregistre();
  });

  tearDown(() async {
    await supabase.dispose();
    transport.close();
    await server.close(force: true);
  });

  test('demande une URL liee au SHA annonce puis confirme le depot', () async {
    final BibliothequeUploadSupabase port = BibliothequeUploadSupabase(
      supabase,
      transport: transport,
    );
    final FichierADeposer fichier = FichierADeposer(
      nom: 'support.pdf',
      octets: 4,
      mime: 'application/pdf',
      sha256: List<String>.filled(64, 'a').join(),
    );

    final IntentionUpload intention = await port.demanderUpload(
      supportId: 'c2900000-0000-0000-0000-000000000002',
      fichier: fichier,
    );
    final List<ProgressionUpload> progression = await port
        .deposer(uploadId: intention.id, octets: Uint8List.fromList(<int>[1, 2, 3, 4]))
        .toList();

    expect(intention.expireLeUtc.isUtc, isTrue);
    expect(transport.url, Uri.parse('https://r2.example.test/signe'));
    expect(transport.methode, 'PUT');
    expect(transport.octets, <int>[1, 2, 3, 4]);
    expect(
      progression.map((ProgressionUpload p) => p.phase),
      <PhaseUpload>[
        PhaseUpload.envoi,
        PhaseUpload.enAttenteConfirmation,
        PhaseUpload.verification,
        PhaseUpload.pret,
      ],
    );
    expect(actions.map((Map<String, dynamic> a) => a['action']), [
      'demander',
      'confirmer',
    ]);
    expect(
      (actions.first['fichier'] as Map<String, dynamic>)['sha256'],
      List<String>.filled(64, 'a').join(),
    );
    port.dispose();
  });

  test('annule une intention via l’Edge authentifiee', () async {
    final BibliothequeUploadSupabase port = BibliothequeUploadSupabase(
      supabase,
      transport: transport,
    );
    final FichierADeposer fichier = FichierADeposer(
      nom: 'support.pdf',
      octets: 4,
      mime: 'application/pdf',
      sha256: List<String>.filled(64, 'b').join(),
    );
    final IntentionUpload intention = await port.demanderUpload(
      supportId: 'c2900000-0000-0000-0000-000000000002',
      fichier: fichier,
    );

    await port.annulerUpload(intention.id);

    expect(actions.last['action'], 'annuler');
    expect(actions.last['upload_id'], intention.id);
    port.dispose();
  });
}

class _TransportEnregistre extends http.BaseClient {
  Uri? url;
  String? methode;
  List<int>? octets;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    url = request.url;
    methode = request.method;
    octets = await request.finalize().toBytes();
    return http.StreamedResponse(const Stream<List<int>>.empty(), HttpStatus.ok);
  }
}
