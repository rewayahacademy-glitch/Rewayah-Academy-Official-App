// N4 : la cause d'un depot de piece qui n'a pas abouti (K-59).
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/dossier/echec_depot.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientException implements Exception {}

void main() {
  test('format refuse par le seau : 415', () {
    expect(
      causeEchecDepot(
        const StorageException(
          'mime type application/octet-stream is not supported',
          error: 'invalid_mime_type',
          statusCode: '415',
        ),
      ),
      CauseEchecDepot.format,
    );
  });

  test('fichier trop lourd : 413', () {
    expect(
      causeEchecDepot(
        const StorageException('Payload too large', statusCode: '413'),
      ),
      CauseEchecDepot.taille,
    );
  });

  test('sans reponse HTTP : connexion coupee', () {
    expect(
      causeEchecDepot(
        const StorageException(
          'Failed host lookup',
          statusCode: 'ClientException',
        ),
      ),
      CauseEchecDepot.reseau,
    );
    expect(causeEchecDepot(ClientException()), CauseEchecDepot.reseau);
  });

  test('PE-B10 : les codes vus en production le 15/11 sont passagers', () {
    for (final String code in <String>['544', '504', '500', '520', '429']) {
      final CauseEchecDepot cause = causeEchecDepot(
        StorageException('Gateway error', statusCode: code),
      );
      expect(cause, CauseEchecDepot.indisponible, reason: code);
      expect(causePassagere(cause), isTrue, reason: code);
    }
    expect(
      causeEchecDepot(const FunctionException(status: 503)),
      CauseEchecDepot.indisponible,
    );
    expect(
      causeEchecDepot(const FunctionsFetchException(details: 'coupure')),
      CauseEchecDepot.reseau,
    );
  });

  test('PE-B10 : session expiree, jamais reessayee comme une panne', () {
    expect(
      causeEchecDepot(const FunctionException(status: 401)),
      CauseEchecDepot.session,
    );
    expect(
      causeEchecDepot(const StorageException('jwt expired', statusCode: '400')),
      CauseEchecDepot.session,
    );
    expect(causeEchecDepot(const SessionAbsente()), CauseEchecDepot.session);
    expect(
      causeEchecDepot(
        const PostgrestException(message: 'JWT expired', code: 'PGRST303'),
      ),
      CauseEchecDepot.session,
    );
    expect(causePassagere(CauseEchecDepot.session), isFalse);
  });

  test('PE-B10 : un refus du serveur est un refus, pas une connexion', () {
    expect(
      causeEchecDepot(
        const StorageException(
          'new row violates row-level security policy',
          error: 'Unauthorized',
          statusCode: '403',
        ),
      ),
      CauseEchecDepot.refuse,
    );
    expect(
      causeEchecDepot(const FunctionException(status: 403)),
      CauseEchecDepot.refuse,
    );
    expect(
      causeEchecDepot(
        const PostgrestException(message: 'refus', code: '42501'),
      ),
      CauseEchecDepot.refuse,
    );
    expect(causePassagere(CauseEchecDepot.refuse), isFalse);
  });

  test('toute autre cause reste dite comme telle', () {
    expect(causeEchecDepot(StateError('inattendu')), CauseEchecDepot.autre);
    expect(
      causeEchecDepot(const FunctionException(status: 409)),
      CauseEchecDepot.autre,
    );
  });

  test('PE-B10 : « existe deja » apres un nouvel essai', () {
    expect(
      dejaDepose(
        const StorageException(
          'The resource already exists',
          error: 'Duplicate',
          statusCode: '409',
        ),
      ),
      isTrue,
    );
    expect(
      dejaDepose(const PostgrestException(message: 'dup', code: '23505')),
      isTrue,
    );
    expect(
      dejaDepose(const StorageException('Gateway', statusCode: '544')),
      isFalse,
    );
  });
}
