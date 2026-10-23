// COURRIELS-1 : l'adaptateur des e-mails sortants. Noms de fonctions et
// parametres, decodage strict, erreurs serveur mappees (22023 champ, P0002
// introuvable, 42501 refus, PGRST202 fonction absente), reseau remonte tel quel.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/courriels_supabase.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_courriels.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Faux {
  _Faux(this.reponse);
  final Object? Function(String, Map<String, dynamic>?) reponse;
  final List<(String, Map<String, dynamic>?)> appels =
      <(String, Map<String, dynamic>?)>[];

  Future<Object?> call(String f, Map<String, dynamic>? p) async {
    appels.add((f, p));
    return reponse(f, p);
  }
}

CourrielsSupabase _adaptateur(_Faux faux) =>
    CourrielsSupabase.avecAppel(faux.call);

PostgrestException _pg(String code, [String message = 'x']) =>
    PostgrestException(message: message, code: code);

Map<String, Object?> _ligne({String statut = 'envoye'}) => <String, Object?>{
  'id': 'c1',
  'categorie': 'direction',
  'modele': 'message_libre',
  'destinataire_adresse': 'awa@exemple.com',
  'origine': 'manuel',
  'statut': statut,
  'tentatives': 1,
  'derniere_erreur': null,
  'cree_le': '2026-10-23T10:00:00+00:00',
  'envoye_le': statut == 'envoye' ? '2026-10-23T10:01:00+00:00' : null,
  'sujet': 'Bonjour',
};

Future<String> _envoyer(CourrielsSupabase a) => a.envoyer(
  categorie: 'direction',
  sujet: '  Bonjour  ',
  corps: '  Un message.  ',
  cle: 'k1',
  adresse: '  awa@exemple.com ',
);

void main() {
  test('envoyer : parametres propres, identifiant rendu', () async {
    final _Faux faux = _Faux((_, _) => 'c9');
    expect(await _envoyer(_adaptateur(faux)), 'c9');
    expect(faux.appels.single.$1, 'admin_courriel_envoyer');
    expect(faux.appels.single.$2, <String, dynamic>{
      'p_profil': null,
      'p_adresse': 'awa@exemple.com',
      'p_categorie': 'direction',
      'p_sujet': 'Bonjour',
      'p_corps': 'Un message.',
      'p_cle': 'k1',
    });
  });

  test('envoyer : 22023 nomme le champ, un nom inconnu reste nul', () async {
    for (final (String m, ChampCourriel? champ) in <(String, ChampCourriel?)>[
      ('adresse', ChampCourriel.adresse),
      ('categorie', ChampCourriel.categorie),
      ('sujet', ChampCourriel.sujet),
      ('corps', ChampCourriel.corps),
      ('destinataire exclu', ChampCourriel.destinataireExclu),
      ('cle', null),
    ]) {
      final _Faux faux = _Faux((_, _) => throw _pg('22023', m));
      await expectLater(
        _envoyer(_adaptateur(faux)),
        throwsA(isA<CourrielInvalide>().having((e) => e.champ, 'champ', champ)),
      );
    }
  });

  test('envoyer : refus, fonction absente, reseau, reponse invalide', () async {
    await expectLater(
      _envoyer(_adaptateur(_Faux((_, _) => throw _pg('42501')))),
      throwsA(isA<PermissionInsuffisante>()),
    );
    await expectLater(
      _envoyer(_adaptateur(_Faux((_, _) => throw _pg('PGRST202')))),
      throwsA(isA<CapaciteIndisponible>()),
    );
    await expectLater(
      _envoyer(_adaptateur(_Faux((_, _) => throw Exception('reseau')))),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      _envoyer(_adaptateur(_Faux((_, _) => null))),
      throwsA(isA<FormatException>()),
    );
  });

  test('lister : filtre, limite et decodage', () async {
    final _Faux faux = _Faux(
      (_, _) => <Object?>[_ligne(), _ligne(statut: 'echec')],
    );
    final List<CourrielSortant> l = await _adaptateur(faux)
        .lister(statut: StatutCourriel.echec, limite: 50);
    expect(faux.appels.single.$1, 'admin_courriels_lister');
    expect(faux.appels.single.$2, <String, dynamic>{
      'p_statut': 'echec',
      'p_limite': 50,
    });
    expect(l, hasLength(2));
    expect(l.first.statut, StatutCourriel.envoye);
    expect(l.first.envoyeLe, isNotNull);
    expect(l.last.envoyeLe, isNull);
    expect(l.first.origine, OrigineCourriel.manuel);
    expect(l.first.sujet, 'Bonjour');
  });

  test(
    'lister : rien vaut une liste vide, un statut inconnu est refuse',
    () async {
      expect(await _adaptateur(_Faux((_, _) => null)).lister(), isEmpty);
      await expectLater(
        _adaptateur(_Faux((_, _) => <Object?>[_ligne(statut: 'perdu')]))
            .lister(),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('reessayer : P0002 devient introuvable', () async {
    final _Faux faux = _Faux((_, _) => null);
    await _adaptateur(faux).reessayer('c1');
    expect(faux.appels.single.$1, 'admin_courriel_reessayer');
    expect(faux.appels.single.$2, <String, dynamic>{'p_id': 'c1'});
    await expectLater(
      _adaptateur(_Faux((_, _) => throw _pg('P0002'))).reessayer('c1'),
      throwsA(isA<CourrielIntrouvable>()),
    );
    await expectLater(
      _adaptateur(_Faux((_, _) => throw _pg('42501'))).reessayer('c1'),
      throwsA(isA<PermissionInsuffisante>()),
    );
  });

  test('categories : decodage', () async {
    final _Faux faux = _Faux(
      (_, _) => <Object?>[
        <String, Object?>{
          'code': 'nouvelles',
          'libelle': "Nouvelles de l'académie",
          'expediteur_adresse': 'contact@rewayahacademy.com',
          'expediteur_nom': 'Rewayah Academy',
          'repondre_a': 'contact@rewayahacademy.com',
          'essentielle': false,
          'active': true,
          'modifie_le': '2026-10-23T10:00:00+00:00',
        },
      ],
    );
    final List<CategorieCourriel> l = await _adaptateur(faux).categories();
    expect(faux.appels.single.$1, 'admin_courriel_categories');
    expect(l.single.code, 'nouvelles');
    expect(l.single.essentielle, isFalse);
    expect(l.single.active, isTrue);
  });
}
