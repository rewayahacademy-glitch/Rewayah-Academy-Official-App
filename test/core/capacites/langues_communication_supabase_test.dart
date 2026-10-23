// COURRIELS-2 : l'adaptateur de la langue de communication. Noms de fonctions
// et parametres, decodage strict, erreurs serveur mappees (22023 langue, 42501
// refus, PGRST202 fonction absente), langue posee aux donnees d'authentification
// apres un reglage reussi seulement.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/langues_communication_supabase.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_langues_communication.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Faux {
  _Faux(this.reponse);
  final Object? Function(String, Map<String, dynamic>?) reponse;
  final List<(String, Map<String, dynamic>?)> appels =
      <(String, Map<String, dynamic>?)>[];
  final List<String> auth = <String>[];
  Exception? erreurAuth;

  Future<Object?> call(String f, Map<String, dynamic>? p) async {
    appels.add((f, p));
    return reponse(f, p);
  }

  Future<void> poserAuth(String code) async {
    auth.add(code);
    final Exception? e = erreurAuth;
    if (e != null) throw e;
  }
}

LanguesCommunicationSupabase _adaptateur(_Faux f) =>
    LanguesCommunicationSupabase.avecAppel(f.call, f.poserAuth);

PostgrestException _pg(String code, [String message = 'x']) =>
    PostgrestException(message: message, code: code);

void main() {
  test('lister : liste decodee dans l\'ordre du serveur', () async {
    final _Faux f = _Faux(
      (_, _) => <Object?>[
        <String, Object?>{
          'code': 'fr',
          'libelle': 'Français',
          'droite_a_gauche': false,
        },
        <String, Object?>{
          'code': 'ar',
          'libelle': 'العربية',
          'droite_a_gauche': true,
        },
      ],
    );
    final List<LangueCommunication> l = await _adaptateur(f).lister();
    expect(f.appels.single.$1, 'langues_communication_lister');
    expect(l.map((LangueCommunication x) => x.code), <String>['fr', 'ar']);
    expect(l.last.droiteAGauche, isTrue);
    expect(l.first.libelle, 'Français');
  });

  test(
    'lister : rien (null) vaut liste vide, ligne invalide est refusee',
    () async {
      expect(await _adaptateur(_Faux((_, _) => null)).lister(), isEmpty);
      await expectLater(
        _adaptateur(
          _Faux(
            (_, _) => <Object?>[
              <String, Object?>{'code': 'fr'},
            ],
          ),
        ).lister(),
        throwsFormatException,
      );
      await expectLater(
        _adaptateur(_Faux((_, _) => 'x')).lister(),
        throwsFormatException,
      );
    },
  );

  test(
    'maLangue : null veut dire francais cote ecran, texte rendu tel quel',
    () async {
      expect(await _adaptateur(_Faux((_, _) => null)).maLangue(), isNull);
      final _Faux f = _Faux((_, _) => ' en ');
      expect(await _adaptateur(f).maLangue(), 'en');
      expect(f.appels.single.$1, 'ma_langue_communication');
      await expectLater(
        _adaptateur(_Faux((_, _) => 3)).maLangue(),
        throwsFormatException,
      );
    },
  );

  test('regler : parametre propre, puis la langue part aux donnees '
      'd\'authentification', () async {
    final _Faux f = _Faux((_, _) => null);
    await _adaptateur(f).regler('ar');
    expect(f.appels.single.$1, 'ma_langue_communication_regler');
    expect(f.appels.single.$2, <String, dynamic>{'p_code': 'ar'});
    expect(f.auth, <String>['ar']);
  });

  test('regler : 22023 devient LangueRefusee, 42501 refus, rien n\'est pose '
      'cote authentification', () async {
    final _Faux f = _Faux((_, _) => throw _pg('22023', 'langue'));
    await expectLater(
      _adaptateur(f).regler('zz'),
      throwsA(isA<LangueRefusee>()),
    );
    expect(f.auth, isEmpty);
    await expectLater(
      _adaptateur(_Faux((_, _) => throw _pg('42501'))).regler('en'),
      throwsA(isA<PermissionInsuffisante>()),
    );
  });

  test(
    'regler : l\'echec de la seconde ecriture ne defait pas la premiere',
    () async {
      final _Faux f = _Faux((_, _) => null)..erreurAuth = Exception('auth');
      await _adaptateur(f).regler('es');
      expect(f.auth, <String>['es']);
    },
  );

  test(
    'fonction absente (PGRST202) : capacite indisponible; reseau tel quel',
    () async {
      await expectLater(
        _adaptateur(_Faux((_, _) => throw _pg('PGRST202'))).lister(),
        throwsA(isA<CapaciteIndisponible>()),
      );
      await expectLater(
        _adaptateur(_Faux((_, _) => throw Exception('reseau'))).maLangue(),
        throwsException,
      );
    },
  );
}
