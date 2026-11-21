// GUIDE-AVIS : l'adaptateur Supabase des avis du guide de l'enseignant, sur
// `public.lire_interactions_guide()` et `public.donner_avis_guide(p_partie,
// p_avis)` (`20261130971000_guide_avis.sql`). Ce que le test prouve :
// - la forme envoyee : la partie et l'avis sous `p_partie` et `p_avis`, nul
//   pour retirer ;
// - la lecture rend les totaux, l'avis du lecteur et `commentairesOuverts`
//   faux quand le serveur le dit ;
// - 42501 devient `PermissionInsuffisante`, une fonction absente du serveur
//   `CapaciteIndisponible` ; `commenter` envoie la partie et le texte.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rewayah_academy/core/candidature/interactions_guide_supabase.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/features/candidature/lettre/port_interactions_guide.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Map<String, String> _json = <String, String>{
  'content-type': 'application/json',
};

class _Appel {
  _Appel(this.fonction, this.corps);

  final String fonction;
  final Map<String, dynamic> corps;
}

InteractionsGuideSupabase _port(
  http.Response Function(_Appel appel) repondre,
  List<_Appel> appels,
) => InteractionsGuideSupabase(
  SupabaseClient(
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
      return http.Response(
        h.body,
        h.statusCode,
        headers: h.headers,
        request: r,
      );
    }),
  ),
);

http.Response _erreur(String code) => http.Response(
  jsonEncode(<String, dynamic>{'code': code, 'message': 'refus'}),
  code == 'PGRST202' ? 404 : 400,
  headers: _json,
);

void main() {
  test('lire : totaux, avis du lecteur, commentaires fermes', () async {
    final List<_Appel> appels = <_Appel>[];
    final InteractionsGuide g = await _port(
      (_) => http.Response(
        jsonEncode(<String, dynamic>{
          'parties': <Map<String, dynamic>>[
            <String, dynamic>{
              'code': 'p1',
              'jaime': 2,
              'pas_clair': 1,
              'mon_avis': 'jaime',
            },
            <String, dynamic>{
              'code': 'p2',
              'jaime': 0,
              'pas_clair': 0,
              'mon_avis': null,
            },
          ],
          'commentaires': <Object>[],
          'commentaires_ouverts': false,
        }),
        200,
        headers: _json,
      ),
      appels,
    ).lire();
    expect(appels.single.fonction, fonctionLireInteractions);
    expect(g.avis['p1']!.jaime, 2);
    expect(g.avis['p1']!.pasClair, 1);
    expect(g.avis['p1']!.monAvis, AvisGuide.jaime);
    expect(g.avis['p2']!.monAvis, isNull);
    expect(g.commentaires, isEmpty);
    expect(g.commentairesOuverts, isFalse);
  });

  test('donner un avis : la partie et l\'avis ; nul pour retirer', () async {
    final List<_Appel> appels = <_Appel>[];
    final InteractionsGuideSupabase port = _port(
      (_Appel a) => http.Response(
        jsonEncode(<String, dynamic>{
          'code': 'p4',
          'jaime': 0,
          'pas_clair': a.corps['p_avis'] == null ? 0 : 1,
          'mon_avis': a.corps['p_avis'],
        }),
        200,
        headers: _json,
      ),
      appels,
    );
    final AvisPartie pose = await port.donnerAvis(
      partie: 'p4',
      avis: AvisGuide.pasClair,
    );
    expect(appels.last.fonction, fonctionDonnerAvis);
    expect(appels.last.corps, <String, dynamic>{
      'p_partie': 'p4',
      'p_avis': 'pas_clair',
    });
    expect(pose.monAvis, AvisGuide.pasClair);
    final AvisPartie retire = await port.donnerAvis(partie: 'p4');
    expect(appels.last.corps['p_avis'], isNull);
    expect(retire.monAvis, isNull);
  });

  test('42501 : permission insuffisante ; fonction absente : '
      'capacite indisponible', () async {
    await expectLater(
      _port((_) => _erreur('42501'), <_Appel>[]).lire(),
      throwsA(isA<PermissionInsuffisante>()),
    );
    await expectLater(
      _port((_) => _erreur('PGRST202'), <_Appel>[]).lire(),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });

  test('commenter : la partie et le texte ; le commentaire cree', () async {
    final List<_Appel> appels = <_Appel>[];
    final CommentaireGuide c = await _port(
      (_) => http.Response(
        jsonEncode(<String, dynamic>{
          'id': 'c1',
          'partie': 'p4',
          'corps': 'Question',
          'cree_le': '2026-11-21T12:00:00Z',
          'auteur': 'moi',
          'parent_id': null,
        }),
        200,
        headers: _json,
      ),
      appels,
    ).commenter(partie: 'p4', corps: 'Question');
    expect(appels.single.fonction, fonctionCommenter);
    expect(appels.single.corps, <String, dynamic>{
      'p_partie': 'p4',
      'p_corps': 'Question',
    });
    expect(c.auteur, AuteurCommentaire.moi);
  });
}
