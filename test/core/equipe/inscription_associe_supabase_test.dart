// L'adaptateur de l'inscription d'un associe : ce qu'il envoie, comment il lit
// les reponses, et comment il traduit les refus du serveur.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/equipe/inscription_associe_supabase.dart';
import 'package:rewayah_academy/core/equipe/port_inscription_associe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('verifier : la reponse valide porte la fin de validite', () async {
    final List<(String, Map<String, dynamic>)> appels =
        <(String, Map<String, dynamic>)>[];
    final InscriptionAssocieSupabase a = InscriptionAssocieSupabase.avecAppel((
      String f,
      Map<String, dynamic> p,
    ) async {
      appels.add((f, p));
      return <String, Object?>{
        'resultat': 'valide',
        'expire_le': '2026-12-01T00:00:00Z',
      };
    });
    final ResultatCodeAssocie r = await a.verifier('ABCD');
    expect(appels.single.$1, 'verifier_invitation_associe');
    expect(appels.single.$2, <String, dynamic>{'p_code': 'ABCD'});
    expect((r as CodeAssocieValide).expireLe, DateTime.utc(2026, 12, 1));
  });

  test('chaque resultat nomme est lu, un resultat inconnu est refuse', () {
    expect(
      resultatCodeAssocieJson(<String, Object?>{'resultat': 'inconnue'}),
      isA<CodeAssocieInconnu>(),
    );
    expect(
      resultatCodeAssocieJson(<String, Object?>{'resultat': 'deja_utilisee'}),
      isA<CodeAssocieDejaUtilise>(),
    );
    expect(
      resultatCodeAssocieJson(<String, Object?>{'resultat': 'expiree'}),
      isA<CodeAssocieExpire>(),
    );
    expect(
      () => resultatCodeAssocieJson(<String, Object?>{'resultat': 'zzz'}),
      throwsFormatException,
    );
    expect(
      resultatInscriptionAssocieJson(<String, Object?>{
        'resultat': 'consommee',
      }),
      ResultatInscriptionAssocie.consommee,
    );
    expect(() => resultatInscriptionAssocieJson('x'), throwsFormatException);
  });

  test('inscrire : les quatre parametres du serveur', () async {
    Map<String, dynamic>? recu;
    final InscriptionAssocieSupabase a = InscriptionAssocieSupabase.avecAppel((
      String f,
      Map<String, dynamic> p,
    ) async {
      expect(f, 'inscrire_associe_invite');
      recu = p;
      return <String, Object?>{'resultat': 'consommee'};
    });
    final ResultatInscriptionAssocie r = await a.inscrire(
      code: 'ABCD',
      prenom: 'Karim',
      nom: 'Associe',
      genre: 'male',
    );
    expect(r, ResultatInscriptionAssocie.consommee);
    expect(recu, <String, dynamic>{
      'p_code': 'ABCD',
      'p_first_name': 'Karim',
      'p_last_name': 'Associe',
      'p_gender': 'male',
    });
  });

  test('les refus du serveur deviennent des causes nommees', () async {
    Future<Object> essayer(String code) async {
      final InscriptionAssocieSupabase a = InscriptionAssocieSupabase.avecAppel(
        (String _, Map<String, dynamic> _) async =>
            throw PostgrestException(message: 'x', code: code),
      );
      try {
        await a.verifier('ABCD');
      } on Object catch (e) {
        return e;
      }
      return 'rien';
    }

    expect(
      ((await essayer('42501')) as RefusInscriptionAssocie).cause,
      CauseRefusInscriptionAssocie.sessionRefusee,
    );
    expect(
      ((await essayer('22023')) as RefusInscriptionAssocie).cause,
      CauseRefusInscriptionAssocie.champsRefuses,
    );
    expect(await essayer('PGRST202'), isA<CapaciteIndisponible>());
    expect(await essayer('42883'), isA<CapaciteIndisponible>());
  });

  test(
    'un reseau qui manque est dit hors ligne, une autre erreur reste',
    () async {
      final InscriptionAssocieSupabase reseau =
          InscriptionAssocieSupabase.avecAppel(
            (String _, Map<String, dynamic> _) async =>
                throw Exception('reseau'),
          );
      await expectLater(
        reseau.verifier('ABCD'),
        throwsA(isA<HorsLigneInscriptionAssocie>()),
      );
      final InscriptionAssocieSupabase autre =
          InscriptionAssocieSupabase.avecAppel(
            (String _, Map<String, dynamic> _) async =>
                throw const PostgrestException(message: 'x', code: '57014'),
          );
      await expectLater(
        autre.verifier('ABCD'),
        throwsA(isA<PostgrestException>()),
      );
    },
  );
}
