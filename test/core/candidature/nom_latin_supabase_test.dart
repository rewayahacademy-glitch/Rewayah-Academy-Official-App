// CAND-NOM-LATIN : l'adaptateur Supabase du nom latin sur les RPC de
// `20261024000000_cand_nom_latin.sql` (`lire_nom_latin`, `confirmer_nom_latin`).
// Ce que le test prouve :
// - la forme envoyee : le seul texte confirme, sous `p_nom_latin`, aucune autre
//   cle ; la lecture n'envoie rien ;
// - la lecture rend l'etat tel que le serveur le dit (a confirmer, deja latin,
//   confirme), sans rien deduire ni translitterer cote adaptateur ;
// - le refus rendu `nom_non_latin` devient `NomNonLatin` ;
// - 42501 devient `PermissionInsuffisante`, une fonction absente du serveur
//   (lot non verse) devient `CapaciteIndisponible`, une panne reseau devient
//   `HorsLigneCandidature` (issue non confirmee) ;
// - une reponse mal formee n'est jamais un succes (`FormatException`).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/nom_latin_supabase.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart'
    show HorsLigneCandidature;
import 'package:rewayah_academy/core/candidature/port_nom_latin.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Map<String, String> _json = <String, String>{
  'content-type': 'application/json',
};

class _Appel {
  _Appel(this.fonction, this.corps);

  final String fonction;
  final Map<String, dynamic> corps;
}

SupabaseClient _client(
  http.Response Function(_Appel appel) repondre,
  List<_Appel> appels,
) => SupabaseClient(
  'https://exemple.supabase.co',
  'cle-anonyme',
  httpClient: MockClient((http.Request r) async {
    final Object? corps = r.body.isEmpty ? null : jsonDecode(r.body);
    final _Appel a = _Appel(
      r.url.pathSegments.last,
      corps is Map<String, dynamic> ? corps : <String, dynamic>{},
    );
    appels.add(a);
    final http.Response h = repondre(a);
    return http.Response(h.body, h.statusCode, headers: h.headers, request: r);
  }),
);

NomLatinSupabase _port(
  http.Response Function(_Appel appel) repondre,
  List<_Appel> appels,
) => NomLatinSupabase(_client(repondre, appels));

http.Response _ok(Object? corps) =>
    http.Response(jsonEncode(corps), 200, headers: _json);

http.Response _erreurPg(String code, String message, {int statut = 400}) =>
    http.Response(
      jsonEncode(<String, String>{'code': code, 'message': message}),
      statut,
      headers: _json,
    );

void main() {
  group('lire', () {
    test('un nom a confirmer', () async {
      final List<_Appel> appels = <_Appel>[];
      final EtatNomLatin etat = await _port(
        (_Appel _) => _ok(<String, Object?>{
          'nomComplet': 'محمد الدوسري',
          'nomLatin': null,
          'dejaLatin': false,
          'aConfirmer': true,
        }),
        appels,
      ).lire();
      expect(appels.single.fonction, 'lire_nom_latin');
      expect(appels.single.corps, isEmpty);
      expect(etat.nomComplet, 'محمد الدوسري');
      expect(etat.nomLatin, isNull);
      expect(etat.dejaLatin, isFalse);
      expect(etat.aConfirmer, isTrue);
    });

    test('un nom confirme, un nom deja latin', () async {
      final EtatNomLatin confirme = await _port(
        (_Appel _) => _ok(<String, Object?>{
          'nomComplet': 'محمد الدوسري',
          'nomLatin': 'Mohamed Al-Dousari',
          'dejaLatin': false,
          'aConfirmer': false,
        }),
        <_Appel>[],
      ).lire();
      expect(confirme.nomLatin, 'Mohamed Al-Dousari');
      expect(confirme.aConfirmer, isFalse);
      final EtatNomLatin latin = await _port(
        (_Appel _) => _ok(<String, Object?>{
          'nomComplet': 'Amina Diallo',
          'nomLatin': null,
          'dejaLatin': true,
          'aConfirmer': false,
        }),
        <_Appel>[],
      ).lire();
      expect(latin.dejaLatin, isTrue);
      expect(latin.aConfirmer, isFalse);
    });

    test('une reponse mal formee n\'est pas un etat', () async {
      await expectLater(
        _port((_Appel _) => _ok('rien'), <_Appel>[]).lire(),
        throwsFormatException,
      );
    });
  });

  group('confirmer', () {
    test('envoie le seul texte, rend le nom retenu', () async {
      final List<_Appel> appels = <_Appel>[];
      final String retenu = await _port(
        (_Appel a) => _ok(<String, Object?>{
          'nomLatin': a.corps['p_nom_latin'],
          'aConfirmer': false,
        }),
        appels,
      ).confirmer('Mohamed Al-Dousari');
      expect(retenu, 'Mohamed Al-Dousari');
      expect(appels.single.fonction, 'confirmer_nom_latin');
      expect(appels.single.corps, <String, dynamic>{
        'p_nom_latin': 'Mohamed Al-Dousari',
      });
    });

    test('le refus rendu devient NomNonLatin', () async {
      await expectLater(
        _port(
          (_Appel _) => _ok(<String, Object?>{'erreur': 'nom_non_latin'}),
          <_Appel>[],
        ).confirmer('محمد'),
        throwsA(isA<NomNonLatin>()),
      );
    });

    test('une reponse sans nom n\'est jamais un succes', () async {
      await expectLater(
        _port(
          (_Appel _) => _ok(<String, Object?>{'aConfirmer': false}),
          <_Appel>[],
        ).confirmer('Mohamed'),
        throwsFormatException,
      );
    });
  });

  group('les pannes', () {
    test('42501 : pas de candidature pour ce compte', () async {
      final NomLatinSupabase port = _port(
        (_Appel _) => _erreurPg('42501', 'reserve au titulaire', statut: 403),
        <_Appel>[],
      );
      await expectLater(port.lire(), throwsA(isA<PermissionInsuffisante>()));
      await expectLater(
        port.confirmer('Mohamed'),
        throwsA(isA<PermissionInsuffisante>()),
      );
    });

    test('fonction absente du serveur : capacite indisponible', () async {
      for (final String code in <String>['PGRST202', '42883']) {
        final NomLatinSupabase port = _port(
          (_Appel _) => _erreurPg(code, 'absente', statut: 404),
          <_Appel>[],
        );
        await expectLater(port.lire(), throwsA(isA<CapaciteIndisponible>()));
        await expectLater(
          port.confirmer('Mohamed'),
          throwsA(isA<CapaciteIndisponible>()),
        );
      }
    });

    test('panne de reseau : issue non confirmee', () async {
      final NomLatinSupabase port = NomLatinSupabase.avecAppel(
        (String _, Map<String, dynamic>? _) =>
            Future<Object?>.error(Exception('reseau')),
      );
      await expectLater(port.lire(), throwsA(isA<HorsLigneCandidature>()));
      await expectLater(
        port.confirmer('Mohamed'),
        throwsA(isA<HorsLigneCandidature>()),
      );
    });
  });
}
