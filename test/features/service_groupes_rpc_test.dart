import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer serveur;
  late SupabaseClient client;
  late ServiceGroupesSupabase service;
  late Map<String, dynamic> parametres;
  late bool echec;

  setUp(() async {
    echec = false;
    parametres = <String, dynamic>{};
    serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    serveur.listen((HttpRequest requete) async {
      parametres = jsonDecode(
        await utf8.decoder.bind(requete).join(),
      ) as Map<String, dynamic>;
      requete.response.headers.contentType = ContentType.json;
      if (echec) {
        requete.response.statusCode = 300;
        requete.response.write(
          jsonEncode(<String, String>{
            'code': 'PGRST203',
            'message': 'Could not choose public.creer_groupe(secret_details)',
            'details': 'internal SQL',
            'hint': 'internal hint',
          }),
        );
      } else {
        requete.response.write(
          requete.uri.path.endsWith('creer_groupe')
              ? jsonEncode('00000000-0000-0000-0000-000000000001')
              : 'null',
        );
      }
      await requete.response.close();
    });
    client = SupabaseClient('http://127.0.0.1:${serveur.port}', 'test-key');
    service = ServiceGroupesSupabase(client);
  });

  tearDown(() async {
    await client.dispose();
    await serveur.close(force: true);
  });

  const Creneau creneau = Creneau(jour: 2, heure: 18, fuseau: 'Asia/Riyadh');

  test('la creation transmet le fuseau de la recurrence', () async {
    final String id = await service.creer(
      teacherId: 'teacher',
      type: TypePublicGroupe.adulte,
      libelle: 'Classe',
      creneau: creneau,
    );
    expect(id, '00000000-0000-0000-0000-000000000001');
    expect(parametres['p_timezone_iana'], 'Asia/Riyadh');
    expect(parametres['p_weekday'], 2);
    expect(parametres['p_hour_local'], 18);
  });

  test('la modification conserve le fuseau choisi', () async {
    await service.modifier(
      groupeId: 'classe',
      libelle: 'Classe',
      seuilMax: 5,
      creneau: creneau,
    );
    expect(parametres['p_timezone_iana'], 'Asia/Riyadh');
  });

  test('une erreur PostgREST ne divulgue pas le SQL a la feature', () async {
    echec = true;
    await expectLater(
      service.creer(
        teacherId: 'teacher',
        type: TypePublicGroupe.adulte,
        libelle: 'Classe',
        creneau: creneau,
      ),
      throwsA(
        isA<ErreurMutationClasse>().having(
          (ErreurMutationClasse e) => e.toString(),
          'message',
          isNot(contains('secret_details')),
        ),
      ),
    );
  });
}
