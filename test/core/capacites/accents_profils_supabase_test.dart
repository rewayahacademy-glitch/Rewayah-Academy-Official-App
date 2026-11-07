// COULEUR-PROFIL (22 i) : l'adaptateur des couleurs de profil. Noms de
// fonctions et parametres, decodage strict, cle inconnue ignoree, erreurs
// serveur mappees (42501 refus, PGRST202 fonction absente).
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/accents_profils_supabase.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/theme/accent_profil.dart';
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

AccentsProfilsSupabase _adaptateur(_Faux f) =>
    AccentsProfilsSupabase.avecAppel(f.call);

PostgrestException _pg(String code) =>
    PostgrestException(message: 'x', code: code);

void main() {
  test('lire : accents decodes par profil, cle inconnue ignoree', () async {
    final _Faux f = _Faux(
      (_, _) => <Object?>[
        <String, Object?>{'profile_id': 'a', 'accent_key': 'menthe'},
        <String, Object?>{'profile_id': 'b', 'accent_key': 'sable'},
        <String, Object?>{'profile_id': 'c', 'accent_key': '#ff0000'},
      ],
    );
    final Map<String, AccentProfil> accents = await _adaptateur(f).lire();
    expect(f.appels.single.$1, 'accents_profils_du_foyer');
    expect(accents, <String, AccentProfil>{
      'a': AccentProfil.menthe,
      'b': AccentProfil.sable,
    });
  });

  test('lire : null vaut aucun accent, forme invalide refusee', () async {
    expect(await _adaptateur(_Faux((_, _) => null)).lire(), isEmpty);
    await expectLater(
      _adaptateur(_Faux((_, _) => 'x')).lire(),
      throwsFormatException,
    );
    await expectLater(
      _adaptateur(
        _Faux(
          (_, _) => <Object?>[
            <String, Object?>{'accent_key': 'ciel'},
          ],
        ),
      ).lire(),
      throwsFormatException,
    );
  });

  test('choisir : nom de la cle, null pour sans couleur', () async {
    final _Faux f = _Faux((_, _) => null);
    await _adaptateur(f).choisir('a', AccentProfil.lavande);
    await _adaptateur(f).choisir('a', null);
    expect(f.appels.map(((String, Map<String, dynamic>?) a) => a.$1), <String>[
      'choisir_accent_profil',
      'choisir_accent_profil',
    ]);
    expect(f.appels.first.$2, <String, dynamic>{
      'p_profil': 'a',
      'p_accent': 'lavande',
    });
    expect(f.appels.last.$2, <String, dynamic>{
      'p_profil': 'a',
      'p_accent': null,
    });
  });

  test('erreurs : fonction absente, refus, autre', () async {
    await expectLater(
      _adaptateur(_Faux((_, _) => throw _pg('PGRST202'))).lire(),
      throwsA(isA<CapaciteIndisponible>()),
    );
    await expectLater(
      _adaptateur(_Faux((_, _) => throw _pg('42501')))
          .choisir('a', AccentProfil.rose),
      throwsA(isA<PermissionInsuffisante>()),
    );
    await expectLater(
      _adaptateur(_Faux((_, _) => throw _pg('22023')))
          .choisir('a', AccentProfil.rose),
      throwsA(isA<PostgrestException>()),
    );
  });
}
