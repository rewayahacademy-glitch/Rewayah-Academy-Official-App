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

  test('toute autre cause reste dite comme telle', () {
    expect(
      causeEchecDepot(const StorageException('Forbidden', statusCode: '403')),
      CauseEchecDepot.autre,
    );
    expect(
      causeEchecDepot(StateError('aucune session')),
      CauseEchecDepot.autre,
    );
  });
}
