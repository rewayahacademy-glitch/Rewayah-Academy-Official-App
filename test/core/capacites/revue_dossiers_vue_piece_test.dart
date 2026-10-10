// AD-7 : la vue de piece de l'adaptateur de production. Elle reutilise
// `ServiceValidation.apercu` (URL signee de 60 s, deja utilisee avant AD-6),
// sans nouvel appel ni changement serveur.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart' show EtatPiece;
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/capacites/revue_dossiers_depuis_validation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show StorageException;

DossierAValider _d(
  String cle, {
  String? doc = 'doc',
  EtatPiece etat = EtatPiece.aVerifier,
}) => DossierAValider(
  documentId: doc,
  profilId: 'p1',
  type: TypePiece.carteIdentite,
  cleObjet: cle,
  deposeLe: DateTime.utc(2026, 9, 25),
  prenom: 'A',
  nom: 'B',
  identifiantImmuable: 'ID',
  role: AppRole.teacher,
  etatPiece: etat,
);

void main() {
  final DateTime maintenant = DateTime.utc(2026, 9, 26, 12);

  RevueDossiersDepuisValidation port(
    DossierAValider d,
    List<String> signes, {
    Object? erreur,
  }) => RevueDossiersDepuisValidation(
    () async => <DossierAValider>[d],
    apercu: (String cle) async {
      signes.add(cle);
      if (erreur != null) {
        // ignore: only_throw_errors
        throw erreur;
      }
      return 'https://exemple.test/signe';
    },
    // Decision branchee comme apres BR-1 (AD-M3-PROD la ferme sinon).
    deciderExistant: ({
      required String documentId,
      required bool approuve,
      String? motif,
    }) async {},
    horloge: () => maintenant,
  );

  Future<CodeErreurRevue?> code(Future<VuePiece> Function() f) async {
    try {
      await f();
      return null;
    } on ErreurRevueDossier catch (e) {
      return e.code;
    }
  }

  test('une image est signee une fois, echeance 60 s, type deduit', () async {
    final List<String> signes = <String>[];
    final VuePiece vue = await port(
      _d('p1/piece.png'),
      signes,
    ).demanderVuePiece(dossierId: 'p1', documentId: 'doc');
    expect(signes, <String>['doc']);
    expect(vue.source, isA<SourcePieceUrl>());
    expect(vue.expireLeUtc, maintenant.add(const Duration(seconds: 60)));
    expect(vue.typeMime, 'image/png');
  });

  for (final String cle in <String>['p1/a.pdf', 'p1/a.heic', 'p1/sans']) {
    test('$cle : typeNonPrisEnCharge sans signer', () async {
      final List<String> signes = <String>[];
      final RevueDossiersDepuisValidation p = port(_d(cle), signes);
      expect(
        await code(
          () => p.demanderVuePiece(dossierId: 'p1', documentId: 'doc'),
        ),
        CodeErreurRevue.typeNonPrisEnCharge,
      );
      expect(signes, isEmpty);
      final DossierPourRevue r = await p.dossierPourRevue('p1');
      expect(r.peutValider, isFalse);
      expect(r.peutRefuser, isTrue);
      expect(r.blocagesValidation, <BlocageRevue>[
        BlocageRevue.pieceNonConsultable,
      ]);
      expect(
        r.verifications.every((VerificationRevue v) => !v.modifiable),
        isTrue,
      );
    });
  }

  test('image : verifications modifiables, validation rouverte', () async {
    final DossierPourRevue r = await port(
      _d('p1/piece.JPG'),
      <String>[],
    ).dossierPourRevue('p1');
    expect(r.peutValider, isTrue);
    expect(r.blocagesValidation, isEmpty);
    expect(r.verifications, hasLength(3));
    expect(
      r.verifications.every((VerificationRevue v) => v.modifiable),
      isTrue,
    );
  });

  test('hors de portee : interdit, jamais signe', () async {
    final List<String> signes = <String>[];
    expect(
      await code(
        () => port(
          _d('p1/a.png', etat: EtatPiece.nonVisible),
          signes,
        ).demanderVuePiece(dossierId: 'p1', documentId: 'doc'),
      ),
      CodeErreurRevue.interdit,
    );
    expect(signes, isEmpty);
  });

  test('document inconnu : introuvable', () async {
    expect(
      await code(
        () => port(
          _d('p1/a.png'),
          <String>[],
        ).demanderVuePiece(dossierId: 'p1', documentId: 'autre'),
      ),
      CodeErreurRevue.introuvable,
    );
  });

  test('StorageException 403 : interdit ; 404 : introuvable', () async {
    expect(
      await code(
        () => port(
          _d('p1/a.png'),
          <String>[],
          erreur: const StorageException('non', statusCode: '403'),
        ).demanderVuePiece(dossierId: 'p1', documentId: 'doc'),
      ),
      CodeErreurRevue.interdit,
    );
    expect(
      await code(
        () => port(
          _d('p1/a.png'),
          <String>[],
          erreur: const StorageException('non', statusCode: '404'),
        ).demanderVuePiece(dossierId: 'p1', documentId: 'doc'),
      ),
      CodeErreurRevue.introuvable,
    );
  });
}
