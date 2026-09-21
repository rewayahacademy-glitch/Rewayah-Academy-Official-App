import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/classes/domaine/erreur_domaine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('EchecDomaine.depuis classe sans jamais recopier', () {
    test('une fonction absente est une capacite absente', () {
      // PostgREST resout une RPC par le nom de ses arguments : un appel a une
      // fonction qui n'existe pas encore revient en PGRST202.
      expect(
        EchecDomaine.depuis(
          const PostgrestException(
            message: 'Could not find the function public.candidater_classe',
            code: 'PGRST202',
          ),
        ).motif,
        MotifEchec.capaciteAbsente,
      );
      expect(
        EchecDomaine.depuis(
          const PostgrestException(
            message: 'relation "classes" does not exist',
            code: '42P01',
          ),
        ).motif,
        MotifEchec.capaciteAbsente,
      );
    });

    test('un refus de droit est un refus', () {
      expect(
        EchecDomaine.depuis(
          const PostgrestException(
            message: 'permission denied for function creer_groupe',
            code: '42501',
          ),
        ).motif,
        MotifEchec.refuse,
      );
    });

    test('une regle metier se classe par ses mots', () {
      expect(
        EchecDomaine.depuis(
          const PostgrestException(
            message: 'plafond du groupe atteint',
            code: 'P0001',
          ),
        ).motif,
        MotifEchec.complet,
      );
      expect(
        EchecDomaine.depuis(
          const PostgrestException(
            message: 'candidature deja deposee',
            code: 'P0001',
          ),
        ).motif,
        MotifEchec.dejaCandidat,
      );
      expect(
        EchecDomaine.depuis(
          const PostgrestException(
            message: 'duplicate key value violates unique constraint',
            code: '23505',
          ),
        ).motif,
        MotifEchec.dejaInscrit,
      );
    });

    test('une coupure reseau est une coupure reseau', () {
      expect(
        EchecDomaine.depuis(TimeoutException('lent')).motif,
        MotifEchec.reseau,
      );
      expect(
        EchecDomaine.depuis(
          StateError('SocketException: Failed host lookup'),
        ).motif,
        MotifEchec.reseau,
      );
    });

    test('tout le reste est inconnu, et le detail reste dans les journaux', () {
      final EchecDomaine echec = EchecDomaine.depuis(StateError('bizarre'));
      expect(echec.motif, MotifEchec.inconnu);
      expect(echec.detailTechnique, contains('bizarre'));
      expect(echec.toString(), isNot(contains('bizarre')));
    });

    test('un echec de domaine passe tel quel', () {
      const EchecDomaine origine = EchecDomaine(MotifEchec.conflit);
      expect(identical(EchecDomaine.depuis(origine), origine), isTrue);
    });
  });

  group('messageHumain ne rend jamais une erreur brute', () {
    test('le message Postgres ne traverse pas', () {
      const String brut =
          'ERROR: duplicate key value violates unique constraint "x"';
      final String message = messageHumain(
        const PostgrestException(message: brut, code: '23505'),
      );
      expect(message, t.classes.erreur.dejaInscrit);
      expect(message, isNot(contains('ERROR')));
      expect(message, isNot(contains('unique')));
    });

    test('chaque motif a sa phrase', () {
      for (final MotifEchec motif in MotifEchec.values) {
        final String message = messageHumain(EchecDomaine(motif));
        expect(message, isNotEmpty, reason: '$motif');
        expect(message, isNot(contains('EchecDomaine')), reason: '$motif');
      }
    });
  });
}
