import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rewayah_academy/core/admin/bibliotheque_upload_supabase.dart';
import 'package:rewayah_academy/core/admin/modeles_bibliotheque_admin.dart';
import 'package:rewayah_academy/core/admin/port_bibliotheque_admin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient supabase;
  late _TransportEnregistre transport;
  final List<Map<String, dynamic>> actions = <Map<String, dynamic>>[];
  // Action -> (statut, motif) : la fonction repond par ce refus.
  final Map<String, (int, String)> refus = <String, (int, String)>{};

  setUp(() async {
    actions.clear();
    refus.clear();
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
      final (int, String)? non = refus[corps['action']];
      request.response
        ..statusCode = non?.$1 ?? HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(
            non == null ? resultat : <String, String>{'error': non.$2},
          ),
        );
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
        .deposer(
          uploadId: intention.id,
          octets: Uint8List.fromList(<int>[1, 2, 3, 4]),
        )
        .toList();

    expect(intention.expireLeUtc.isUtc, isTrue);
    expect(transport.url, Uri.parse('https://r2.example.test/signe'));
    expect(transport.methode, 'PUT');
    expect(transport.octets, <int>[1, 2, 3, 4]);
    expect(progression.map((ProgressionUpload p) => p.phase), <PhaseUpload>[
      PhaseUpload.envoi,
      PhaseUpload.enAttenteConfirmation,
      PhaseUpload.verification,
      PhaseUpload.pret,
    ]);
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

  // Les trois fichiers reels du directeur (13/11/2026). Les deux premiers
  // etaient refuses par la fonction (lettres arabes ; espaces et apostrophe)
  // parce que leur nom entrait dans la cle de stockage, et l'ecran disait
  // « la connexion s'est interrompue ».
  for (final String nom in <String>[
    'متن الأخضري-1.pdf',
    "Programme d'initiation aux sciences Islamiques - PISI.pdf",
    'The_Mental_Fortress_Blueprint.pdf',
    '${'tres-long-' * 40}.pdf',
    'accentué çà et là (copie).PDF',
  ]) {
    test('le nom du fichier ne voyage jamais : « $nom » part sous un nom '
        'neutre', () async {
      final BibliothequeUploadSupabase port = BibliothequeUploadSupabase(
        supabase,
        transport: transport,
      );
      await port.demanderUpload(
        supportId: 'c2900000-0000-0000-0000-000000000002',
        fichier: FichierADeposer(
          nom: nom,
          octets: 4,
          mime: 'application/pdf',
          sha256: List<String>.filled(64, 'a').join(),
        ),
      );
      final String envoye =
          (actions.first['fichier'] as Map<String, dynamic>)['nom'] as String;
      expect(envoye, 'document.pdf');
      // La convention que la fonction, la base et la cle exigeaient du nom.
      expect(
        RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(envoye),
        isTrue,
      );
      port.dispose();
    });
  }

  FichierADeposer pdf() => FichierADeposer(
    nom: 'support.pdf',
    octets: 4,
    mime: 'application/pdf',
    sha256: List<String>.filled(64, 'a').join(),
  );

  group('une cause, une phrase : la demande', () {
    final Map<(int, String), ErreurUpload> cas = <(int, String), ErreurUpload>{
      (400, 'fichier invalide ou format non autorise'): ErreurUpload.type,
      (401, 'authentification requise'): ErreurUpload.session,
      (403, 'depot refuse'): ErreurUpload.refuse,
      (404, 'Function not found'): ErreurUpload.service,
      (500, 'erreur interne'): ErreurUpload.service,
      (503, 'stockage indisponible'): ErreurUpload.stockage,
    };
    for (final MapEntry<(int, String), ErreurUpload> c in cas.entries) {
      test('${c.key.$1} « ${c.key.$2} » -> ${c.value.name}', () async {
        refus['demander'] = c.key;
        final BibliothequeUploadSupabase port = BibliothequeUploadSupabase(
          supabase,
          transport: transport,
        );
        await expectLater(
          port.demanderUpload(
            supportId: 'c2900000-0000-0000-0000-000000000002',
            fichier: pdf(),
          ),
          throwsA(
            isA<DepotImpossible>().having(
              (DepotImpossible e) => e.cause,
              'cause',
              c.value,
            ),
          ),
        );
        port.dispose();
      });
    }

    test('aucune reponse du tout : la connexion, et elle seule', () async {
      await server.close(force: true);
      final BibliothequeUploadSupabase port = BibliothequeUploadSupabase(
        supabase,
        transport: transport,
      );
      await expectLater(
        port.demanderUpload(
          supportId: 'c2900000-0000-0000-0000-000000000002',
          fichier: pdf(),
        ),
        throwsA(isA<BibliothequeHorsLigne>()),
      );
      port.dispose();
    });

    test(
      'un type que le depot n\'accepte pas est refuse avant tout appel',
      () async {
        final BibliothequeUploadSupabase port = BibliothequeUploadSupabase(
          supabase,
          transport: transport,
        );
        await expectLater(
          port.demanderUpload(
            supportId: 'c2900000-0000-0000-0000-000000000002',
            fichier: FichierADeposer(
              nom: 'x.json',
              octets: 4,
              mime: 'application/json',
              sha256: List<String>.filled(64, 'a').join(),
            ),
          ),
          throwsA(
            isA<DepotImpossible>().having(
              (DepotImpossible e) => e.cause,
              'cause',
              ErreurUpload.type,
            ),
          ),
        );
        expect(actions, isEmpty);
        port.dispose();
      },
    );
  });

  group('une cause, une phrase : l\'envoi et la confirmation', () {
    Future<ProgressionUpload> dernier(BibliothequeUploadSupabase port) async {
      final IntentionUpload intention = await port.demanderUpload(
        supportId: 'c2900000-0000-0000-0000-000000000002',
        fichier: pdf(),
      );
      return (await port
              .deposer(
                uploadId: intention.id,
                octets: Uint8List.fromList(<int>[1, 2, 3, 4]),
              )
              .toList())
          .last;
    }

    test(
      'le stockage ne repond pas (origine non admise) : « envoi »',
      () async {
        // Dans un navigateur, un envoi bloque par la regle d'origine du seau
        // leve une exception sans statut. Avant : « la connexion a coupe ».
        final BibliothequeUploadSupabase port = BibliothequeUploadSupabase(
          supabase,
          transport: _TransportEnPanne(),
        );
        final ProgressionUpload p = await dernier(port);
        expect(p.phase, PhaseUpload.echec);
        expect(p.erreur, ErreurUpload.envoi);
        // La confirmation n'est jamais demandee pour un fichier qui n'est pas parti.
        expect(actions.map((Map<String, dynamic> a) => a['action']), [
          'demander',
        ]);
        port.dispose();
      },
    );

    test('le stockage repond non (403) : « stockage »', () async {
      final BibliothequeUploadSupabase port = BibliothequeUploadSupabase(
        supabase,
        transport: _TransportEnregistre(statut: HttpStatus.forbidden),
      );
      final ProgressionUpload p = await dernier(port);
      expect(p.erreur, ErreurUpload.stockage);
      port.dispose();
    });

    final Map<(int, String), ErreurUpload> cas = <(int, String), ErreurUpload>{
      (503, 'confirmation indisponible'): ErreurUpload.nonActive,
      (503, 'confirmation mal reglee'): ErreurUpload.reglage,
      (503, 'stockage indisponible'): ErreurUpload.stockage,
      (403, 'confirmation refusee'): ErreurUpload.refuse,
      (422, 'contenu depose invalide'): ErreurUpload.empreinte,
      (500, 'erreur interne'): ErreurUpload.service,
      (546, 'limite de ressources'): ErreurUpload.delai,
    };
    for (final MapEntry<(int, String), ErreurUpload> c in cas.entries) {
      test(
        'confirmation ${c.key.$1} « ${c.key.$2} » -> ${c.value.name}',
        () async {
          refus['confirmer'] = c.key;
          final BibliothequeUploadSupabase port = BibliothequeUploadSupabase(
            supabase,
            transport: transport,
          );
          final ProgressionUpload p = await dernier(port);
          expect(p.phase, PhaseUpload.echec);
          expect(p.erreur, c.value);
          expect(p.erreur, isNot(ErreurUpload.reseau));
          port.dispose();
        },
      );
    }
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

class _TransportEnPanne extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Future<http.StreamedResponse>.error(
        http.ClientException('XMLHttpRequest error.', request.url),
      );
}

class _TransportEnregistre extends http.BaseClient {
  _TransportEnregistre({this.statut = HttpStatus.ok});

  final int statut;
  Uri? url;
  String? methode;
  List<int>? octets;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    url = request.url;
    methode = request.method;
    octets = await request.finalize().toBytes();
    return http.StreamedResponse(const Stream<List<int>>.empty(), statut);
  }
}
