// ANNONCES-SERVEUR (21/11/2026, DECISION-ANNONCES-NOTIFS-2026-11-21.md §2) :
// l'adaptateur lit le contrat du fil pagine et traduit, ferme et rouvre ; il
// retombe sur l'ancien fil tant que la migration 20261130976000 n'est pas
// installee.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/features/com_annonces/annonces_direction_supabase.dart';
import 'package:rewayah_academy/features/com_annonces/port_annonces_direction.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

const String _id1 = '11111111-1111-4111-8111-111111111111';
const String _id2 = '22222222-2222-4222-8222-222222222222';

class _Appels {
  _Appels(this.reponse);

  final Object? Function(String fonction, Map<String, dynamic> p) reponse;
  final List<(String, Map<String, dynamic>)> faits =
      <(String, Map<String, dynamic>)>[];

  Future<Object?> appel(String fonction, Map<String, dynamic> p) async {
    faits.add((fonction, p));
    return reponse(fonction, p);
  }
}

Map<String, dynamic> _annonce({
  String id = _id1,
  String titre = 'Back to school',
  String texte = 'School starts on Monday.',
  bool traduite = true,
  bool fermee = false,
}) => <String, dynamic>{
  'id': id,
  'titre': titre,
  'texte': texte,
  'titre_original': 'Rentree',
  'texte_original': 'La rentree est lundi.',
  'langue_originale': 'fr',
  'traduite': traduite,
  'publiee_le': '2026-11-21T10:00:00+00:00',
  'vue': false,
  'fermee': fermee,
};

void main() {
  test('le fil : parametres du contrat, langue de l\'interface, page et '
      'curseur', () async {
    final _Appels a = _Appels(
      (_, _) => <String, dynamic>{
        'annonces': <Object>[_annonce()],
        'suite': '2026-11-20T09:00:00+00:00',
      },
    );
    final PageAnnonces page = await AnnoncesDirectionSupabase(
      a.appel,
      langue: () => 'en',
    ).mesAnnonces(avant: DateTime.utc(2026, 11, 21, 12), fermees: true);

    expect(a.faits.single.$1, 'com_mes_annonces');
    expect(a.faits.single.$2, <String, dynamic>{
      'p_limite': 20,
      'p_avant': '2026-11-21T12:00:00.000Z',
      'p_langue': 'en',
      'p_fermees': true,
    });
    expect(page.suite, DateTime.utc(2026, 11, 20, 9));
    final AnnonceRecue r = page.annonces.single;
    expect(r.texte, 'School starts on Monday.');
    expect(r.texteOriginal, 'La rentree est lundi.');
    expect(r.titreOriginal, 'Rentree');
    expect(r.langueOriginale, 'fr');
    expect(r.traduite, isTrue);
    expect(r.fermee, isFalse);
  });

  test('la limite est bornee (1 a 50) et la derniere page n\'a pas de '
      'suite', () async {
    final _Appels a = _Appels(
      (_, _) => <String, dynamic>{'annonces': <Object>[], 'suite': null},
    );
    final AnnoncesDirectionSupabase port = AnnoncesDirectionSupabase(
      a.appel,
      langue: () => 'ar',
    );
    final PageAnnonces page = await port.mesAnnonces(limite: 500);
    await port.mesAnnonces(limite: 0);
    expect(a.faits[0].$2['p_limite'], 50);
    expect(a.faits[1].$2['p_limite'], 1);
    expect(a.faits[0].$2['p_fermees'], isFalse);
    expect(page.annonces, isEmpty);
    expect(page.suite, isNull);
  });

  test('jamais vide : sans texte rendu, l\'original', () async {
    final _Appels a = _Appels(
      (_, _) => <String, dynamic>{
        'annonces': <Object>[_annonce(titre: '', texte: '', traduite: true)],
        'suite': null,
      },
    );
    final AnnonceRecue r = (await AnnoncesDirectionSupabase(
      a.appel,
      langue: () => 'en',
    ).mesAnnonces()).annonces.single;
    expect(r.titre, 'Rentree');
    expect(r.texte, 'La rentree est lundi.');
    expect(r.traduite, isFalse);
  });

  test('l\'ancien serveur (sans les nouveaux champs) se lit encore', () async {
    final _Appels a = _Appels((String f, Map<String, dynamic> p) {
      if (p.isNotEmpty) {
        throw const PostgrestException(message: 'absente', code: 'PGRST202');
      }
      return <String, dynamic>{
        'annonces': <Object>[
          <String, dynamic>{
            'id': _id2,
            'titre': 'Horaires',
            'texte': 'Les horaires changent.',
            'publiee_le': '2026-11-21T10:00:00Z',
            'vue': true,
          },
        ],
      };
    });
    final AnnoncesDirectionSupabase port = AnnoncesDirectionSupabase(
      a.appel,
      langue: () => 'fr',
    );
    final PageAnnonces page = await port.mesAnnonces();
    expect(
      a.faits.map(((String, Map<String, dynamic>) f) => f.$2.isEmpty),
      <bool>[false, true],
    );
    final AnnonceRecue r = page.annonces.single;
    expect(r.texte, 'Les horaires changent.');
    expect(r.texteOriginal, 'Les horaires changent.');
    expect(r.traduite, isFalse);
    expect(r.fermee, isFalse);
    expect(r.vue, isTrue);
    expect(page.suite, isNull);
    // Une page suivante n'existe pas sur l'ancien serveur.
    expect(
      (await port.mesAnnonces(avant: DateTime.utc(2026))).annonces,
      isEmpty,
    );
  });

  test('un refus du serveur est une capacite indisponible', () async {
    final _Appels a = _Appels(
      (_, _) => throw const PostgrestException(message: 'non', code: '42501'),
    );
    await expectLater(
      AnnoncesDirectionSupabase(a.appel, langue: () => 'fr').mesAnnonces(),
      throwsA(same(AnnoncesDirectionIndisponibles.manque)),
    );
  });

  test('fermer et rouvrir appellent le serveur avec l\'identifiant', () async {
    final _Appels a = _Appels((_, _) => null);
    final AnnoncesDirectionSupabase port = AnnoncesDirectionSupabase(
      a.appel,
      langue: () => 'fr',
    );
    await port.fermer(_id1);
    await port.rouvrir(_id1);
    expect(
      a.faits.map(((String, Map<String, dynamic>) f) => f.$1).toList(),
      <String>['com_annonce_fermer', 'com_annonce_rouvrir'],
    );
    for (final (String, Map<String, dynamic>) f in a.faits) {
      expect(f.$2, <String, dynamic>{'p_annonce_id': _id1});
    }
    expect(() => port.fermer('pas-un-id'), throwsArgumentError);
  });

  test('avecFermee garde tout le reste', () {
    final AnnonceRecue r = AnnonceRecue(
      id: _id1,
      titre: 'T',
      texte: 'X',
      publieeLe: DateTime.utc(2026),
      titreOriginal: 'TO',
      texteOriginal: 'XO',
      langueOriginale: 'ar',
      traduite: true,
    );
    final AnnonceRecue f = r.avecFermee(true);
    expect(f.fermee, isTrue);
    expect(
      <Object?>[f.id, f.titre, f.texte, f.titreOriginal, f.texteOriginal],
      <Object?>[_id1, 'T', 'X', 'TO', 'XO'],
    );
    expect(f.langueOriginale, 'ar');
    expect(f.traduite, isTrue);
    expect(f.avecFermee(false).fermee, isFalse);
  });
}
