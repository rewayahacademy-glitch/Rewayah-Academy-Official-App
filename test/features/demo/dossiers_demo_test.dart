import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_politique_revue_kyc.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';

final DateTime _maintenant = DateTime.utc(2026, 9, 26, 12);

Matcher _erreur(CodeErreurRevue code) => throwsA(
  isA<ErreurRevueDossier>().having(
    (ErreurRevueDossier e) => e.code,
    'code',
    code,
  ),
);

typedef _Doubles = (EtatRevueDemo, RevueDossiersDemo, PolitiqueRevueKycDemo);

_Doubles _doubles({
  bool superAdmin = true,
  bool politiqueGenre = true,
  bool genreRelecteurRenseigne = true,
}) {
  final EtatRevueDemo etat = EtatRevueDemo.initial(
    maintenant: _maintenant,
    superAdmin: superAdmin,
    politiqueGenre: politiqueGenre,
    genreRelecteurRenseigne: genreRelecteurRenseigne,
  );
  return (etat, RevueDossiersDemo(etat), PolitiqueRevueKycDemo(etat));
}

Future<ResultatDecision> _valider(
  RevueDossiersDemo revue,
  String id, {
  String commande = 'c1',
  Set<String>? verifications,
}) async {
  final DossierPourRevue d = await revue.dossierPourRevue(id);
  return revue.decider(
    dossierId: id,
    revisionAttendue: d.revision,
    decision: DecisionDossier.valider,
    commandeId: commande,
    verificationsFaites: verifications ?? verificationsDemo.toSet(),
  );
}

void main() {
  group('file', () {
    test('10 dossiers a verifier, tries, total et pagination', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      final PageDossiers tout = await revue.listerDossiers();
      expect(tout.total, 10);
      expect(tout.elements, hasLength(10));
      expect(
        tout.elements.first.dossierId,
        DonneesDossiersDemo.enseignantNominal,
      );
      for (int i = 1; i < tout.elements.length; i++) {
        expect(
          tout.elements[i - 1].soumisLeUtc.isAfter(
            tout.elements[i].soumisLeUtc,
          ),
          isFalse,
        );
      }
      expect(
        tout.elements.every(
          (DossierEnFile d) => d.statut == StatutRevue.aVerifier,
        ),
        isTrue,
      );

      final PageDossiers p1 = await revue.listerDossiers(limite: 4);
      final PageDossiers p2 = await revue.listerDossiers(
        limite: 4,
        curseur: p1.curseurSuivant,
      );
      final PageDossiers p3 = await revue.listerDossiers(
        limite: 4,
        curseur: p2.curseurSuivant,
      );
      expect(
        <int>[p1.elements.length, p2.elements.length, p3.elements.length],
        <int>[4, 4, 2],
      );
      expect(p1.aSuite && p2.aSuite, isTrue);
      expect(p3.aSuite, isFalse);

      final PageDossiers enseignants = await revue.listerDossiers(
        role: AppRole.teacher,
      );
      expect(
        enseignants.elements.every(
          (DossierEnFile d) => d.role == AppRole.teacher,
        ),
        isTrue,
      );
      expect(enseignants.total, 6);
    });

    test('toutes les pieces sont fictives', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles(politiqueGenre: false);
      for (final String id in <String>[
        DonneesDossiersDemo.enseignantNominal,
        DonneesDossiersDemo.tuteurDocumentaire,
        DonneesDossiersDemo.conflit,
        DonneesDossiersDemo.horsPortee,
        DonneesDossiersDemo.reponsePerdue,
      ]) {
        final DossierPourRevue d = await revue.dossierPourRevue(id);
        final VuePiece vue = await revue.demanderVuePiece(
          dossierId: id,
          documentId: d.documentId!,
        );
        expect(vue.source, isA<SourcePieceFictive>());
      }
    });
  });

  group('cas de revue', () {
    test('famille dispensee : validable sans piece', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      final DossierPourRevue d = await revue.dossierPourRevue(
        DonneesDossiersDemo.familleDispensee,
      );
      expect(d.etatPiece, EtatPieceRevue.nonRequise);
      expect(d.peutValider, isTrue);
      expect(d.verifications, isEmpty);
      final ResultatDecision r = await _valider(
        revue,
        DonneesDossiersDemo.familleDispensee,
        verifications: const <String>{},
      );
      expect(r.statutFinal, StatutRevue.valide);
    });

    test('piece absente : validation fermee, refus possible', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.pieceAbsente;
      final DossierPourRevue d = await revue.dossierPourRevue(id);
      expect(d.peutValider, isFalse);
      expect(d.blocagesValidation, <BlocageRevue>[BlocageRevue.pieceAbsente]);
      expect(d.peutRefuser, isTrue);
      expect(d.peutVoirPiece, isFalse);
      await expectLater(
        _valider(revue, id),
        _erreur(CodeErreurRevue.pieceIndisponible),
      );
      final ResultatDecision r = await revue.decider(
        dossierId: id,
        revisionAttendue: d.revision,
        decision: DecisionDossier.refuser,
        commandeId: 'r1',
        verificationsFaites: const <String>{},
        motif: 'Piece manquante',
      );
      expect(r.statutFinal, StatutRevue.refuse);
    });

    test('revision : succes, retrait de la file, revision perimee', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.enseignantNominal;
      await expectLater(
        revue.decider(
          dossierId: id,
          revisionAttendue: 1,
          decision: DecisionDossier.valider,
          commandeId: 'vieux',
          verificationsFaites: verificationsDemo.toSet(),
        ),
        _erreur(CodeErreurRevue.perime),
      );
      final ResultatDecision r = await _valider(revue, id);
      expect(r.nouvelleRevision, 3);
      expect(r.etatCompte, AccountStatus.active);
      final PageDossiers file = await revue.listerDossiers();
      expect(file.total, 9);
      expect(
        file.elements.any((DossierEnFile d) => d.dossierId == id),
        isFalse,
      );
    });

    test('conflit : perime, puis deja decide', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.conflit;
      await expectLater(_valider(revue, id), _erreur(CodeErreurRevue.perime));
      final DossierPourRevue d = await revue.dossierPourRevue(id);
      expect(d.statut, StatutRevue.valide);
      expect(d.blocagesValidation, <BlocageRevue>[BlocageRevue.dejaDecide]);
      expect(d.peutValider || d.peutRefuser, isFalse);
      await expectLater(
        _valider(revue, id, commande: 'c2'),
        _erreur(CodeErreurRevue.dejaDecide),
      );
    });

    test('idempotence par commande', () async {
      final (EtatRevueDemo etat, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.tuteurDocumentaire;
      final ResultatDecision r1 = await revue.decider(
        dossierId: id,
        revisionAttendue: 1,
        decision: DecisionDossier.valider,
        commandeId: 'k',
        verificationsFaites: verificationsDemo.toSet(),
      );
      final ResultatDecision r2 = await revue.decider(
        dossierId: id,
        revisionAttendue: 1,
        decision: DecisionDossier.valider,
        commandeId: 'k',
        verificationsFaites: verificationsDemo.toSet(),
      );
      expect(identical(r1, r2), isTrue);
      expect(etat.nombreDecisions, 1);
      // Variante 13.2 : documentaire seule, aucune activation.
      expect(r1.etatCompte, isNot(AccountStatus.active));
      await expectLater(
        revue.decider(
          dossierId: id,
          revisionAttendue: 1,
          decision: DecisionDossier.refuser,
          commandeId: 'k',
          verificationsFaites: const <String>{},
          motif: 'x',
        ),
        _erreur(CodeErreurRevue.commandeIncoherente),
      );
    });

    test('reponse perdue : decision enregistree, resultat relu', () async {
      final (EtatRevueDemo etat, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.reponsePerdue;
      await expectLater(
        _valider(revue, id, commande: 'p'),
        _erreur(CodeErreurRevue.reponsePerdue),
      );
      final EtatCommande etatCommande = await revue.resultatDecision(
        dossierId: id,
        commandeId: 'p',
      );
      expect(etatCommande, isA<EtatCommandeEnAttente>());
      final EtatCommande relu = await revue.resultatDecision(
        dossierId: id,
        commandeId: 'p',
      );
      expect(relu, isA<EtatCommandeReussie>());
      final ResultatDecision rejoue = await revue.decider(
        dossierId: id,
        revisionAttendue: 1,
        decision: DecisionDossier.valider,
        commandeId: 'p',
        verificationsFaites: verificationsDemo.toSet(),
      );
      expect(identical(rejoue, (relu as EtatCommandeReussie).resultat), isTrue);
      expect(etat.nombreDecisions, 1);
      expect(
        await revue.resultatDecision(dossierId: id, commandeId: 'autre'),
        isA<EtatCommandeInconnue>(),
      );
    });

    test('accord manquant : validation fermee et refusee', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.accordManquant;
      final DossierPourRevue d = await revue.dossierPourRevue(id);
      expect(d.peutValider, isFalse);
      expect(d.blocagesValidation, <BlocageRevue>[BlocageRevue.accordManquant]);
      expect(d.peutRefuser, isTrue);
      await expectLater(
        _valider(revue, id),
        _erreur(CodeErreurRevue.accordManquant),
      );
    });

    test('consequence indeterminee : decision indisponible', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.decisionIndisponible;
      final DossierPourRevue d = await revue.dossierPourRevue(id);
      expect(d.consequence, ConsequenceValidation.indeterminee);
      expect(d.peutValider, isFalse);
      expect(d.blocagesValidation, <BlocageRevue>[
        BlocageRevue.decisionIndisponible,
      ]);
      // Le serveur recontrole malgre can_validate (17.4).
      await expectLater(
        _valider(revue, id),
        _erreur(CodeErreurRevue.indisponibleTemporairement),
      );
    });

    test('echec metier memorise et relu (conflit)', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.conflit;
      await expectLater(
        _valider(revue, id, commande: 'cf'),
        _erreur(CodeErreurRevue.perime),
      );
      final EtatCommande relu = await revue.resultatDecision(
        dossierId: id,
        commandeId: 'cf',
      );
      expect(
        relu,
        isA<EtatCommandeEchouee>().having(
          (EtatCommandeEchouee e) => e.code,
          'code',
          CodeErreurRevue.perime,
        ),
      );
      // Meme commande, meme charge : meme echec rejoue.
      await expectLater(
        revue.decider(
          dossierId: id,
          revisionAttendue: 1,
          decision: DecisionDossier.valider,
          commandeId: 'cf',
          verificationsFaites: verificationsDemo.toSet(),
        ),
        _erreur(CodeErreurRevue.perime),
      );
    });

    test('lien expire puis renouvele', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.lienExpire;
      await expectLater(
        revue.demanderVuePiece(dossierId: id, documentId: 'demo-piece-08'),
        _erreur(CodeErreurRevue.expire),
      );
      final VuePiece vue = await revue.demanderVuePiece(
        dossierId: id,
        documentId: 'demo-piece-08',
      );
      expect(vue.expireLeUtc.isAfter(_maintenant), isTrue);
      expect(vue.typeMime, 'image/png');
    });

    test('motif requis, verifications manquantes', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.enseignantNominal;
      for (final String? motif in <String?>[null, '   ']) {
        await expectLater(
          revue.decider(
            dossierId: id,
            revisionAttendue: 2,
            decision: DecisionDossier.refuser,
            commandeId: 'm$motif',
            verificationsFaites: const <String>{},
            motif: motif,
          ),
          _erreur(CodeErreurRevue.motifRequis),
        );
      }
      await expectLater(
        _valider(revue, id, verifications: <String>{'lisible'}),
        _erreur(CodeErreurRevue.verificationManquante),
      );
    });
  });

  group('politique de genre', () {
    test('active : piece hors portee ; desactivee : validable', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.horsPortee;
      final DossierPourRevue ferme = await revue.dossierPourRevue(id);
      expect(ferme.etatPiece, EtatPieceRevue.nonVisible);
      expect(ferme.peutVoirPiece || ferme.peutValider, isFalse);
      expect(ferme.blocagesValidation, <BlocageRevue>[
        BlocageRevue.pieceNonVisible,
      ]);
      await expectLater(
        revue.demanderVuePiece(dossierId: id, documentId: 'demo-piece-06'),
        _erreur(CodeErreurRevue.interdit),
      );
      await expectLater(
        _valider(revue, id),
        _erreur(CodeErreurRevue.pieceIndisponible),
      );

      final (_, RevueDossiersDemo libre, _) = _doubles(politiqueGenre: false);
      final DossierPourRevue ouvert = await libre.dossierPourRevue(id);
      expect(ouvert.etatPiece, EtatPieceRevue.disponible);
      expect(ouvert.peutValider, isTrue);
      expect((await _valider(libre, id)).statutFinal, StatutRevue.valide);
    });

    test('genre du relecteur non renseigne', () async {
      final (_, RevueDossiersDemo active, _) = _doubles(
        genreRelecteurRenseigne: false,
      );
      await expectLater(
        active.listerDossiers(),
        _erreur(CodeErreurRevue.profilACompleter),
      );
      await expectLater(
        active.dossierPourRevue(DonneesDossiersDemo.enseignantNominal),
        _erreur(CodeErreurRevue.profilACompleter),
      );
      final (_, RevueDossiersDemo desactivee, _) = _doubles(
        genreRelecteurRenseigne: false,
        politiqueGenre: false,
      );
      expect((await desactivee.listerDossiers()).total, 10);
      // Lecture de la piece et decision fermees aussi (0004:202-204).
      await expectLater(
        active.demanderVuePiece(
          dossierId: DonneesDossiersDemo.enseignantNominal,
          documentId: 'demo-piece-01',
        ),
        _erreur(CodeErreurRevue.profilACompleter),
      );
      await expectLater(
        active.decider(
          dossierId: DonneesDossiersDemo.enseignantNominal,
          revisionAttendue: 2,
          decision: DecisionDossier.refuser,
          commandeId: 'pr',
          verificationsFaites: const <String>{},
          motif: 'x',
        ),
        _erreur(CodeErreurRevue.profilACompleter),
      );
    });

    test('hors portee : refus ferme aussi, rouvert sans politique', () async {
      final (_, RevueDossiersDemo revue, _) = _doubles();
      const String id = DonneesDossiersDemo.horsPortee;
      final DossierPourRevue d = await revue.dossierPourRevue(id);
      expect(d.peutRefuser, isFalse);
      expect(d.blocagesRefus, <BlocageRevue>[BlocageRevue.pieceNonVisible]);
      expect(d.blocagesAcces, <BlocageRevue>[BlocageRevue.pieceNonVisible]);
      await expectLater(
        revue.decider(
          dossierId: id,
          revisionAttendue: d.revision,
          decision: DecisionDossier.refuser,
          commandeId: 'hr',
          verificationsFaites: const <String>{},
          motif: 'Piece illisible',
        ),
        _erreur(CodeErreurRevue.interdit),
      );

      final (_, RevueDossiersDemo libre, _) = _doubles(politiqueGenre: false);
      final DossierPourRevue ouvert = await libre.dossierPourRevue(id);
      expect(ouvert.peutRefuser, isTrue);
      expect(ouvert.blocagesAcces, isEmpty);
      final ResultatDecision r = await libre.decider(
        dossierId: id,
        revisionAttendue: ouvert.revision,
        decision: DecisionDossier.refuser,
        commandeId: 'hr',
        verificationsFaites: const <String>{},
        motif: 'Piece illisible',
      );
      expect(r.statutFinal, StatutRevue.refuse);
      expect((await libre.dossierPourRevue(id)).peutResoumettre, isTrue);
    });

    test('Super Admin simule', () async {
      final (_, _, PolitiqueRevueKycDemo simple) = _doubles(superAdmin: false);
      expect((await simple.lire()).peutModifier, isFalse);
      await expectLater(
        simple.modifier(genreRelecteurApplique: false, versionAttendue: 1),
        _erreur(CodeErreurRevue.interdit),
      );

      final (_, RevueDossiersDemo revue, PolitiqueRevueKycDemo politique) =
          _doubles();
      final PolitiqueRevueKyc avant = await politique.lire();
      expect(avant.peutModifier, isTrue);
      final PolitiqueRevueKyc apres = await politique.modifier(
        genreRelecteurApplique: false,
        versionAttendue: avant.version,
      );
      expect(apres.version, avant.version + 1);
      expect(apres.genreRelecteurApplique, isFalse);
      final DossierPourRevue d = await revue.dossierPourRevue(
        DonneesDossiersDemo.horsPortee,
      );
      expect(d.etatPiece, EtatPieceRevue.disponible);
      await expectLater(
        politique.modifier(
          genreRelecteurApplique: true,
          versionAttendue: avant.version,
        ),
        _erreur(CodeErreurRevue.perime),
      );
    });
  });

  group('pont ADM-02', () {
    test(
      'file de l\'ecran : traitables d\'abord, hors portee en fin',
      () async {
        final (EtatRevueDemo etat, _, _) = _doubles();
        final List<String> ids = <String>[
          for (final DossierAValider d in await ServiceValidationDemo(
            etat,
          ).enAttente())
            d.profilId,
        ];
        expect(ids, isNot(contains(DonneesDossiersDemo.familleDispensee)));
        expect(ids, isNot(contains(DonneesDossiersDemo.pieceAbsente)));
        expect(ids.last, DonneesDossiersDemo.horsPortee);
        expect(ids.first, DonneesDossiersDemo.enseignantNominal);
        expect(ids, contains(DonneesDossiersDemo.reponsePerdue));
      },
    );

    test('reponse perdue : meme commande, succes relu', () async {
      final (EtatRevueDemo etat, _, _) = _doubles();
      final ServiceValidationDemo pont = ServiceValidationDemo(etat);
      const String doc = 'demo-piece-07';
      // Premier tap : decision enregistree, relecture « en attente ».
      await expectLater(
        pont.decider(documentId: doc, approuve: true),
        _erreur(CodeErreurRevue.reponsePerdue),
      );
      expect(etat.nombreDecisions, 1);
      // Second tap : la meme commande est rejouee, aucun « deja decide ».
      await pont.decider(documentId: doc, approuve: true);
      expect(etat.nombreDecisions, 1);
      expect(
        etat.dossiers[DonneesDossiersDemo.reponsePerdue]!.statut,
        StatutRevue.valide,
      );
      expect(etat.commandes.keys.single, startsWith('demo-demo-dossier-07-r1'));
    });
  });
}
