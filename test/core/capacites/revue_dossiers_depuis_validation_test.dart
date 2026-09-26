// AD-5 : l'adaptateur de production du port de revue, sans Supabase. Il ne
// fait aucun appel serveur de plus que la file existante.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart' show EtatPiece;
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/capacites/revue_dossiers_depuis_validation.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_dossiers/textes_dossier.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

DossierAValider _d(String profil, {String? doc = 'doc', String prenom = 'A'}) =>
    DossierAValider(
      documentId: doc,
      profilId: profil,
      type: doc == null ? null : TypePiece.carteIdentite,
      cleObjet: doc == null ? null : 'x/$doc',
      deposeLe: DateTime.utc(2026, 9, 25, 14, 30),
      prenom: prenom,
      nom: 'Test',
      identifiantImmuable: 'ID-$profil',
      role: AppRole.teacher,
    );

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.fr));

  test(
    'mapping, dedoublonnage, total et curseur nuls, un seul appel',
    () async {
      int appels = 0;
      final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
        () async {
          appels++;
          return <DossierAValider>[
            _d('p1', doc: 'd1', prenom: 'Omar'),
            _d('p1', doc: 'd2', prenom: 'Omar'),
            _d('p2', doc: null, prenom: 'Ines'),
          ];
        },
      );
      final PageDossiers page = await port.listerDossiers();
      expect(appels, 1);
      expect(page.total, isNull);
      expect(page.curseurSuivant, isNull);
      expect(page.elements.map((DossierEnFile e) => e.dossierId), <String>[
        'p1',
        'p2',
      ]);
      expect(page.elements.first.nomAffiche, 'Omar Test');
      expect(page.elements.first.aPieceIdentite, isTrue);
      expect(page.elements.last.aPieceIdentite, isFalse);
      expect(page.elements.first.statut, StatutRevue.aVerifier);
      // Une suite demandee est vide, sans nouvel appel.
      expect((await port.listerDossiers(curseur: 'x')).elements, isEmpty);
      expect(appels, 1);
    },
  );

  test('etat de la piece lu dans la meme reponse (non_visible)', () async {
    int appels = 0;
    final PageDossiers page = await RevueDossiersDepuisValidation(() async {
      appels++;
      return <DossierAValider>[
        _d('p1', doc: 'd1'),
        DossierAValider(
          documentId: null,
          profilId: 'p2',
          type: null,
          cleObjet: null,
          deposeLe: DateTime.utc(2026, 9, 25, 15),
          prenom: 'B',
          nom: 'Test',
          identifiantImmuable: 'ID-p2',
          role: AppRole.teacher,
          etatPiece: EtatPiece.nonVisible,
        ),
        _d('p3', doc: null),
      ];
    }).listerDossiers();
    expect(appels, 1);
    expect(
      page.elements.map((DossierEnFile e) => e.etatPiece),
      <EtatPieceRevue?>[
        EtatPieceRevue.disponible,
        EtatPieceRevue.nonVisible,
        null,
      ],
    );
    expect(page.elements[1].aPieceIdentite, isTrue);
  });

  test('erreurs typees : genre inconnu, 42501', () async {
    await expectLater(
      RevueDossiersDepuisValidation(
        () async => throw const GenreLecteurInconnu(),
      ).listerDossiers(),
      throwsA(
        isA<ErreurRevueDossier>().having(
          (ErreurRevueDossier e) => e.code,
          'code',
          CodeErreurRevue.profilACompleter,
        ),
      ),
    );
    await expectLater(
      RevueDossiersDepuisValidation(
        () async =>
            throw const PostgrestException(message: 'refus', code: '42501'),
      ).listerDossiers(),
      throwsA(
        isA<ErreurRevueDossier>().having(
          (ErreurRevueDossier e) => e.code,
          'code',
          CodeErreurRevue.interdit,
        ),
      ),
    );
  });

  test('les gestes du port restent indisponibles', () async {
    final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
      () async => <DossierAValider>[],
    );
    await expectLater(
      port.dossierPourRevue('p1'),
      throwsA(isA<CapaciteIndisponible>()),
    );
    await expectLater(
      port.decider(
        dossierId: 'p1',
        revisionAttendue: 0,
        decision: DecisionDossier.valider,
        commandeId: 'c',
        verificationsFaites: <String>{},
      ),
      throwsA(isA<CapaciteIndisponible>()),
    );
  });

  test('elision : voyelles accentuees, ni Y ni H', () {
    expect(ouvrirDossier('Inès Exemple'), "Ouvrir le dossier d'Inès Exemple");
    expect(ouvrirDossier('Élise'), "Ouvrir le dossier d'Élise");
    expect(ouvrirDossier('Yusuf'), 'Ouvrir le dossier de Yusuf');
    expect(ouvrirDossier('Hana'), 'Ouvrir le dossier de Hana');
    expect(titreDossier('Omar Haddad'), "Dossier d'Omar Haddad");
  });

  test('date : toujours en UTC, et dit', () {
    final DateTime quand = DateTime.utc(2026, 9, 25, 14, 30);
    expect(dateRevue(quand).replaceAll(' ', ' '), '25/09/2026 à 14:30 (UTC)');
  });
}
