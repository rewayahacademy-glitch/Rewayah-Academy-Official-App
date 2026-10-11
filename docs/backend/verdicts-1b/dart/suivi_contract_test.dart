import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/offres/demandes_suivi_supabase.dart';
import 'package:rewayah_academy/core/offres/port_suivi_demandes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Sortie reelle de public.suivi_demandes_horaires_foyer() (PG16, canon-fixes
// ea1a0da9), foyer America/New_York, deux demandes (envoyee, refusee).
const String _reel = '''[
{"etape":"envoyee","motif":null,"prenom":"Amine","eleve_id":"e1","demande_id":"d1",
 "enseignant":null,"debut_cours":null,"fuseau_iana":"America/New_York",
 "occurrences":[{"heure":17,"minute":0,"jour_iso":2},{"heure":17,"minute":0,"jour_iso":4}],
 "personnalisee":true,"peut_choisir_autre_creneau":false},
{"etape":"close","motif":"refus_direction","prenom":"Amine","eleve_id":"e1","demande_id":"d2",
 "enseignant":null,"debut_cours":null,"fuseau_iana":"America/New_York",
 "occurrences":[{"heure":9,"minute":0,"jour_iso":6}],
 "personnalisee":true,"peut_choisir_autre_creneau":true}]''';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  String body = _reel;
  final List<String> paths = <String>[];

  setUp(() async {
    paths.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((HttpRequest r) async {
      paths.add(r.uri.path);
      await utf8.decoder.bind(r).join();
      r.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(body);
      await r.response.close();
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

  test('decode la sortie reelle : envoyee et refusee', () async {
    final List<SuiviDemande> l =
        await DemandesSuiviSupabase(client).suivre().first;
    expect(paths.first, '/rest/v1/rpc/suivi_demandes_horaires_foyer');
    expect(l, hasLength(2));
    expect(l[0].etape, EtapeDemande.envoyee);
    expect(l[0].creneau.occurrences.map((o) => o.jourIso), <int>[2, 4]);
    expect(l[0].creneau.occurrences.every((o) => o.heure == 17), isTrue);
    expect(l[0].fuseauIana, 'America/New_York');
    expect(l[0].personnalise, isTrue);
    expect(l[0].debutCours, isNull);
    expect(l[1].etape, EtapeDemande.close);
    expect(l[1].motif, MotifCloture.refusDirection);
    expect(l[1].peutChoisirAutreCreneau, isTrue);
  });

  test('debut du cours : heure murale sans decalage acceptee', () async {
    body = '''[{"etape":"enseignant_affecte","motif":null,"prenom":"A",
"eleve_id":"e","demande_id":"d","enseignant":"Sana B","debut_cours":"2026-10-15T18:00:00",
"fuseau_iana":"America/New_York","occurrences":[{"heure":18,"minute":0,"jour_iso":4}],
"personnalisee":false,"peut_choisir_autre_creneau":false}]''';
    final List<SuiviDemande> l =
        await DemandesSuiviSupabase(client).suivre().first;
    expect(l.single.debutCours, DateTime(2026, 10, 15, 18));
    expect(l.single.debutCours!.isUtc, isFalse);
    expect(l.single.enseignant, 'Sana B');
  });

  test('etape inconnue : FormatException', () async {
    body = '''[{"etape":"zzz","motif":null,"prenom":"A","eleve_id":"e","demande_id":"d",
"enseignant":null,"debut_cours":null,"fuseau_iana":"Europe/Paris",
"occurrences":[],"personnalisee":false,"peut_choisir_autre_creneau":false}]''';
    await expectLater(
      DemandesSuiviSupabase(client).suivre().first,
      throwsFormatException,
    );
  });

  test('ligne non objet : FormatException', () async {
    body = '[1]';
    await expectLater(
      DemandesSuiviSupabase(client).suivre().first,
      throwsFormatException,
    );
  });

  test('champ obligatoire absent (demande_id) : erreur typee, pas une valeur muette', () async {
    body = '''[{"etape":"envoyee","motif":null,"prenom":"A","eleve_id":"e",
"enseignant":null,"debut_cours":null,"fuseau_iana":"Europe/Paris",
"occurrences":[{"heure":17,"minute":0,"jour_iso":2}],"personnalisee":false,
"peut_choisir_autre_creneau":false}]''';
    await expectLater(
      DemandesSuiviSupabase(client).suivre().first,
      throwsA(isA<FormatException>()),
    );
  });
}
