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

  test('AD-6 : detail depuis la meme file, sans appel de plus', () async {
    int appels = 0;
    final List<DossierAValider> file = <DossierAValider>[
      _d('p1', doc: 'd1', prenom: 'Omar'),
      _d('p2', doc: null, prenom: 'Ines'),
      DossierAValider(
        documentId: null,
        profilId: 'p3',
        type: null,
        cleObjet: null,
        deposeLe: DateTime.utc(2026, 9, 25, 15),
        prenom: 'B',
        nom: 'Test',
        identifiantImmuable: 'ID-p3',
        role: AppRole.teacher,
        etatPiece: EtatPiece.nonVisible,
      ),
    ];
    // Comme en production : un cache partage, lu une seule fois.
    final Future<List<DossierAValider>> cache = Future<List<DossierAValider>>(
      () {
        appels++;
        return file;
      },
    );
    final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
      () => cache,
    );
    await port.listerDossiers();
    final DossierPourRevue d = await port.dossierPourRevue('p1');
    expect(appels, 1);
    expect(d.dossierId, 'p1');
    expect(d.prenom, 'Omar');
    expect(d.nom, 'Test');
    expect(d.role, AppRole.teacher);
    expect(d.soumisLeUtc, DateTime.utc(2026, 9, 25, 14, 30));
    expect(d.revision, 0);
    expect(d.statut, StatutRevue.aVerifier);
    expect(d.etatPiece, EtatPieceRevue.disponible);
    expect(d.typePiece, TypePiece.carteIdentite);
    expect(d.documentId, 'd1');
    expect(d.verifications.map((VerificationRevue v) => v.id), <String>[
      'lisible',
      'nom',
      'validite',
    ]);
    expect(
      d.verifications.every(
        (VerificationRevue v) =>
            v.obligatoire &&
            // Jusqu'a AD-7 : pas d'attestation d'une piece non consultable.
            !v.modifiable &&
            v.etat == EtatVerification.aFaire &&
            v.origine == OrigineVerification.humaine,
      ),
      isTrue,
    );
    expect(d.accords, isEmpty);
    expect(d.peutValider, isFalse);
    // AD-M3-PROD : ni signature ni decision branchees (production jusqu'a
    // BR-1) : refus et consultation fermes comme la validation.
    expect(d.peutRefuser || d.peutVoirPiece, isFalse);
    expect(d.blocagesValidation, <BlocageRevue>[
      BlocageRevue.decisionIndisponible,
      BlocageRevue.pieceNonConsultable,
    ]);
    expect(d.blocagesRefus, <BlocageRevue>[BlocageRevue.decisionIndisponible]);
    expect(d.consequence, ConsequenceValidation.indeterminee);
    // Aucune cle d'objet dans le modele rendu.
    expect(d.toString().contains('x/d1'), isFalse);

    final DossierPourRevue sans = await port.dossierPourRevue('p2');
    expect(sans.etatPiece, EtatPieceRevue.absente);
    expect(sans.verifications, isEmpty);
    expect(sans.peutValider || sans.peutRefuser, isFalse);
    expect(sans.blocagesValidation, <BlocageRevue>[BlocageRevue.pieceAbsente]);
    expect(sans.blocagesRefus, <BlocageRevue>[BlocageRevue.pieceAbsente]);

    final DossierPourRevue horsPortee = await port.dossierPourRevue('p3');
    expect(horsPortee.etatPiece, EtatPieceRevue.nonVisible);
    expect(horsPortee.blocagesValidation, <BlocageRevue>[
      BlocageRevue.pieceNonVisible,
    ]);
    expect(appels, 1);

    await expectLater(
      port.dossierPourRevue('inconnu'),
      throwsA(
        isA<ErreurRevueDossier>().having(
          (ErreurRevueDossier e) => e.code,
          'code',
          CodeErreurRevue.introuvable,
        ),
      ),
    );
    await expectLater(
      RevueDossiersDepuisValidation(
        () async => throw const GenreLecteurInconnu(),
      ).dossierPourRevue('p1'),
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
      ).dossierPourRevue('p1'),
      throwsA(
        isA<ErreurRevueDossier>().having(
          (ErreurRevueDossier e) => e.code,
          'code',
          CodeErreurRevue.interdit,
        ),
      ),
    );
  });

  // K-47 (HL-A-6) : tant que dossiers_en_attente rend aussi les tuteurs
  // pending_kyc (BR-1.c), l'adaptateur les ecarte, sans appel de plus.
  test('K-47 : les lignes de tuteur sont ecartees de la file', () async {
    int appels = 0;
    final DossierAValider tuteur = DossierAValider(
      documentId: null,
      profilId: 'g1',
      type: null,
      cleObjet: null,
      deposeLe: DateTime.utc(2026, 9, 25, 13),
      prenom: 'Hana',
      nom: 'Test',
      identifiantImmuable: 'ID-g1',
      role: AppRole.guardian,
      etatPiece: EtatPiece.aucune,
    );
    final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
      () async {
        appels++;
        return <DossierAValider>[tuteur, _d('p1', doc: 'd1', prenom: 'Omar')];
      },
    );
    final PageDossiers page = await port.listerDossiers();
    expect(page.elements.map((DossierEnFile e) => e.dossierId), <String>['p1']);
    expect(
      (await port.listerDossiers(role: AppRole.guardian)).elements,
      isEmpty,
    );
    await expectLater(
      port.dossierPourRevue('g1'),
      throwsA(
        isA<ErreurRevueDossier>().having(
          (ErreurRevueDossier e) => e.code,
          'code',
          CodeErreurRevue.introuvable,
        ),
      ),
    );
    expect(appels, 3);
    // Un role illisible retombe sur guardian a la lecture : ecarte aussi.
    final DossierAValider sansRole = DossierAValider.depuisJson(
      const <String, dynamic>{'profile_id': 'x1', 'etat_piece': 'aucune'},
    );
    expect(
      RevueDossiersDepuisValidation.enseignantsSeulement(<DossierAValider>[
        sansRole,
      ]),
      isEmpty,
    );
  });

  test('sans RPC branchee, la decision reste indisponible', () async {
    int lectures = 0;
    final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
      () async {
        lectures++;
        return <DossierAValider>[_d('p1')];
      },
    );
    await expectLater(
      port.decider(
        dossierId: 'p1',
        revisionAttendue: 0,
        decision: DecisionDossier.refuser,
        commandeId: 'c',
        verificationsFaites: <String>{},
        motif: 'Motif fictif',
      ),
      throwsA(
        isA<CapaciteIndisponible>().having(
          (CapaciteIndisponible e) => e.dependance,
          'dependance',
          'AD-BR-06',
        ),
      ),
    );
    // Refuse avant toute lecture : aucune file relue, aucun appel.
    expect(lectures, 0);
  });

  // MUT-A-3 : a BR-1, l'apercu sera rebranche avant ou avec la decision. Une
  // piece consultable ne suffit pas : sans `decider_dossier`, la validation
  // reste fermee et dit pourquoi.
  test('apercu branche sans decision : la validation reste fermee', () async {
    final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
      () async => <DossierAValider>[
        DossierAValider(
          documentId: 'd1',
          profilId: 'p1',
          type: TypePiece.carteIdentite,
          cleObjet: 'x/d1.png',
          deposeLe: DateTime.utc(2026, 9, 25, 14, 30),
          prenom: 'Omar',
          nom: 'Test',
          identifiantImmuable: 'ID-p1',
          role: AppRole.teacher,
        ),
      ],
      apercu: (String cle) async => 'https://exemple.invalid/$cle',
    );
    final DossierPourRevue d = await port.dossierPourRevue('p1');
    // La piece est consultable : seule la decision manque.
    expect(d.peutVoirPiece, isTrue);
    expect(d.lectureRequise, isTrue);
    expect(d.peutValider, isFalse);
    expect(d.peutRefuser, isFalse);
    expect(d.blocagesValidation, <BlocageRevue>[
      BlocageRevue.decisionIndisponible,
    ]);
  });

  // AD-M3-PROD (decision du directeur du 27/09, S1 -> a) : le branchement
  // de production ne signe aucune URL et n'appelle jamais decider_dossier.
  test(
    'sans signature branchee, la piece reste fermee, rien n est signe',
    () async {
      int lectures = 0;
      final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
        () async {
          lectures++;
          return <DossierAValider>[_d('p1', doc: 'd1')];
        },
      );
      await expectLater(
        port.demanderVuePiece(dossierId: 'p1', documentId: 'd1'),
        throwsA(
          isA<CapaciteIndisponible>().having(
            (CapaciteIndisponible e) => e.dependance,
            'dependance',
            'AD-BR-03',
          ),
        ),
      );
      expect(lectures, 0);
    },
  );

  // L2-02 : l'apercu est demande par identifiant de document ; un refus de la
  // porte (403) est un acces interdit, jamais une panne.
  test('L2-02 : apercu par documentId, le refus de la porte remonte', () async {
    final List<String> demandes = <String>[];
    final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
      () async => <DossierAValider>[
        DossierAValider(
          documentId: 'd1',
          profilId: 'p1',
          type: TypePiece.carteIdentite,
          cleObjet: 'x/d1.png',
          deposeLe: DateTime.utc(2026, 9, 25, 14, 30),
          prenom: 'Omar',
          nom: 'Test',
          identifiantImmuable: 'ID-p1',
          role: AppRole.teacher,
        ),
      ],
      apercu: (String documentId) async {
        demandes.add(documentId);
        throw const ApercuRefuse();
      },
    );
    await expectLater(
      port.demanderVuePiece(dossierId: 'p1', documentId: 'd1'),
      throwsA(isA<ApercuRefuse>()),
    );
    expect(demandes, <String>['d1']);
  });

  // AD-RC m2 : la validation reste fermee en production jusqu'a BR-1, par
  // l'adaptateur lui-meme et non par le seul bouton de l'ecran.
  test('valider : AD-BR-02, sans lecture de file ni appel RPC', () async {
    int lectures = 0;
    int appels = 0;
    final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
      () async {
        lectures++;
        return <DossierAValider>[_d('p1')];
      },
      deciderExistant: ({
        required String documentId,
        required bool approuve,
        String? motif,
      }) async => appels++,
    );
    await expectLater(
      port.decider(
        dossierId: 'p1',
        revisionAttendue: 0,
        decision: DecisionDossier.valider,
        commandeId: 'c',
        verificationsFaites: verificationsRevue.toSet(),
      ),
      throwsA(
        isA<CapaciteIndisponible>().having(
          (CapaciteIndisponible e) => e.dependance,
          'dependance',
          'AD-BR-02',
        ),
      ),
    );
    expect(appels, 0);
    expect(lectures, 0);
  });

  group('AD-8 : decision sur decider_dossier existant', () {
    Future<ResultatDecision> deciderSur(
      RevueDossiersDepuisValidation port, {
      String dossierId = 'p1',
    }) => port.decider(
      dossierId: dossierId,
      revisionAttendue: 0,
      decision: DecisionDossier.refuser,
      commandeId: 'c1',
      verificationsFaites: const <String>{},
      motif: 'Motif fictif',
    );

    test('document absent du cache : deja decide, aucun appel', () async {
      int appels = 0;
      final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
        () async => <DossierAValider>[_d('p2')],
        deciderExistant: ({
          required String documentId,
          required bool approuve,
          String? motif,
        }) async => appels++,
      );
      await expectLater(
        deciderSur(port),
        throwsA(
          isA<ErreurRevueDossier>().having(
            (ErreurRevueDossier e) => e.code,
            'code',
            CodeErreurRevue.dejaDecide,
          ),
        ),
      );
      expect(appels, 0);
    });

    test(
      'appel unique avec le document du cache, sans promettre de compte',
      () async {
        final List<(String, bool, String?)> appels =
            <(String, bool, String?)>[];
        final RevueDossiersDepuisValidation port =
            RevueDossiersDepuisValidation(
              () async => <DossierAValider>[_d('p1')],
              deciderExistant: ({
                required String documentId,
                required bool approuve,
                String? motif,
              }) async => appels.add((documentId, approuve, motif)),
            );
        final ResultatDecision r = await deciderSur(port);
        expect(appels, <(String, bool, String?)>[
          ('doc', false, 'Motif fictif'),
        ]);
        expect(r.dossierId, 'p1');
        expect(r.statutFinal, StatutRevue.refuse);
        expect(r.etatCompte, isNull);
      },
    );

    test('carte des erreurs serveur, sans motif dans le message', () async {
      Future<void> Function({
        required String documentId,
        required bool approuve,
        String? motif,
      })
      jeter(Object e) =>
          ({
            required String documentId,
            required bool approuve,
            String? motif,
          }) => Future<void>.error(e);
      Future<Object?> erreur(Object e) async {
        try {
          await deciderSur(
            RevueDossiersDepuisValidation(
              () async => <DossierAValider>[_d('p1')],
              deciderExistant: jeter(e),
            ),
          );
        } on Object catch (x) {
          return x;
        }
        return null;
      }

      final Object? motifRequis = await erreur(
        const PostgrestException(
          message: 'un refus exige un motif',
          code: 'P0001',
        ),
      );
      expect(
        (motifRequis! as ErreurRevueDossier).code,
        CodeErreurRevue.motifRequis,
      );
      final Object? interdit = await erreur(
        const PostgrestException(message: 'x', code: '42501'),
      );
      expect((interdit! as ErreurRevueDossier).code, CodeErreurRevue.interdit);
      final Object? hors = await erreur(
        const PostgrestException(
          message: 'document introuvable ou hors du perimetre',
          code: 'P0001',
        ),
      );
      expect((hors! as ErreurRevueDossier).code, CodeErreurRevue.interdit);
      final Object? autre = await erreur(
        const PostgrestException(message: 'autre', code: 'P0001'),
      );
      expect(autre, isA<EchecDecisionCertain>());
      final Object? perdue = await erreur(Exception('coupure'));
      expect(
        (perdue! as ErreurRevueDossier).code,
        CodeErreurRevue.reponsePerdue,
      );
      expect(perdue.toString(), isNot(contains('Motif fictif')));
    });

    test(
      'L1-05 : « dossier déjà décidé » devient dejaDecide, pas un echec certain',
      () async {
        final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
          () async => <DossierAValider>[_d('p1')],
          deciderExistant: ({
            required String documentId,
            required bool approuve,
            String? motif,
          }) async => throw const PostgrestException(
            message: 'dossier déjà décidé',
            code: '23514',
          ),
        );
        await expectLater(
          deciderSur(port),
          throwsA(
            isA<ErreurRevueDossier>().having(
              (ErreurRevueDossier e) => e.code,
              'code',
              CodeErreurRevue.dejaDecide,
            ),
          ),
        );
      },
    );

    test('resultatDecision : cache, puis rechargement existant', () async {
      int recharges = 0;
      List<DossierAValider> recharge = <DossierAValider>[_d('p1')];
      final RevueDossiersDepuisValidation port = RevueDossiersDepuisValidation(
        () async => <DossierAValider>[_d('p1')],
        relire: () async {
          recharges++;
          return recharge;
        },
      );
      expect(
        await port.resultatDecision(dossierId: 'p1', commandeId: 'c1'),
        // Toujours present : en attente, jamais un echec (Q-AD8-9).
        isA<EtatCommandeEnAttente>(),
      );
      expect(recharges, 1);
      recharge = <DossierAValider>[];
      final EtatCommande e = await port.resultatDecision(
        dossierId: 'p1',
        commandeId: 'c1',
      );
      expect(
        e,
        isA<EtatCommandeEchouee>().having(
          (EtatCommandeEchouee x) => x.code,
          'code',
          CodeErreurRevue.dejaDecide,
        ),
      );
      // Absent du cache : aucun rechargement.
      final RevueDossiersDepuisValidation vide = RevueDossiersDepuisValidation(
        () async => <DossierAValider>[],
        relire: () async {
          recharges++;
          return <DossierAValider>[];
        },
      );
      await vide.resultatDecision(dossierId: 'p1', commandeId: 'c1');
      expect(recharges, 2);
    });
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
