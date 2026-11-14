// CAND-01 et CAND-03 : le portail `/attente` d'un candidat. Ou en est la
// candidature (a completer, en examen, en pause, refusee, retiree), la
// prochaine action, et le retrait avec sa confirmation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/port_ma_candidature.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/candidature/portail_candidature.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';
import 'hote_candidature.dart';

Finder _texte(String t) => find.text(t);

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

/// Touche un texte, apres l'avoir amene a l'ecran (le pied peut le couvrir).
Future<void> _toucherTexte(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Confirme le retrait : le bouton de la feuille est le dernier de l'arbre.
Future<void> _confirmerRetrait(WidgetTester tester) async {
  await tester.tap(_texte(t.recrutement.retrait.confirmer).last);
  await tester.pumpAndSettle();
}

/// Monte le portail pour un etat de candidature.
Future<FauxServiceDossier> _portail(
  WidgetTester tester,
  CandidatureDossier candidature, {
  FauxMaCandidature? port,
  bool horsLigne = false,
  Size taille = const Size(390, 844),
  TextDirection? direction,
  double echelle = 1,
  bool accordsFaits = true,
  bool pieceDeposee = true,
  bool? photoPosee,
  bool? accordPublicationSigne,
}) async {
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..etatRendu = etatCandidat(
      candidature: candidature,
      accordsFaits: accordsFaits,
      pieceDeposee: pieceDeposee,
      photoPosee: photoPosee,
      accordPublicationSigne: accordPublicationSigne,
    );
  await monterQuestionnaire(
    tester,
    port: port ?? FauxMaCandidature(),
    depart: Routes.attente,
    horsLigne: horsLigne,
    taille: taille,
    direction: direction,
    echelle: echelle,
    dossier: dossier,
  );
  return dossier;
}

const CandidatureDossier _enExamen = CandidatureDossier(
  existe: true,
  etape: EtapeCandidature.prequalification,
  etat: EtatCandidature.enExamen,
  version: 4,
);

void main() {
  group('SALLE-1-TOUT-ICI : la page unique « Votre candidature »', () {
    testWidgets('accords a faire : la prochaine action est de les lire', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        candidatureAFaire(),
        accordsFaits: false,
        pieceDeposee: false,
      );
      expect(_texte(t.recrutement.portail.toutIci), findsOneWidget);
      expect(_texte(t.recrutement.portail.listeTitre), findsOneWidget);
      expect(_texte(t.recrutement.portail.elementAccords), findsOneWidget);
      expect(_texte(t.recrutement.portail.elementPiece), findsOneWidget);
      expect(_texte(t.recrutement.portail.etatADeposer), findsOneWidget);
      // Le cadre est accepte : il est marque « Fait », il ne disparait pas.
      expect(_texte(t.recrutement.portail.elementCadre), findsOneWidget);
      expect(_texte(t.recrutement.portail.etatFait), findsOneWidget);
      expect(_texte(t.attente.lireEtAccepter), findsOneWidget);
      expect(_texte(t.attente.deposerLaPiece), findsNothing);
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets(
      'accords faits, piece a deposer : la prochaine action est la piece',
      (WidgetTester tester) async {
        await _portail(tester, candidatureAFaire(), pieceDeposee: false);
        expect(_texte(t.attente.deposerLaPiece), findsOneWidget);
        expect(_texte(t.recrutement.portail.etatFait), findsNWidgets(2));
        expect(_texte(t.recrutement.portail.etatADeposer), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets(
      'tout est fait sauf les reponses : le questionnaire, et ce qui reste',
      (WidgetTester tester) async {
        await _portail(tester, candidatureAFaire());
        expect(_texte(t.recrutement.portail.completer), findsOneWidget);
        expect(_texte(t.recrutement.portail.etatFait), findsNWidgets(3));
        expect(_texte(t.recrutement.portail.elementReponses), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
      },
    );

    test(
      'regle 296/312 : cadre non accepte, la prochaine action est le cadre',
      () {
        final r = prochaineCandidature(
          candidatureAFaire(cadreAccepte: false),
          dossier: etatCandidat(accordsFaits: false, pieceDeposee: false),
        );
        expect(r?.chemin, Routes.attenteCadre);
      },
    );

    test('regle 296/312 : cadre accepte, accords non faits : les accords', () {
      final r = prochaineCandidature(
        candidatureAFaire(),
        dossier: etatCandidat(accordsFaits: false, pieceDeposee: false),
      );
      expect(r?.chemin, Routes.attenteAccords);
      expect(r?.libelle, t.attente.lireEtAccepter);
    });

    test('accords faits, piece a deposer : la piece ; tout fait : le questionnaire', () {
      expect(
        prochaineCandidature(
          candidatureAFaire(),
          dossier: etatCandidat(pieceDeposee: false),
        )?.chemin,
        Routes.attentePiece,
      );
      expect(
        prochaineCandidature(
          candidatureAFaire(),
          dossier: etatCandidat(),
        )?.chemin,
        Routes.attenteCandidature,
      );
    });

    testWidgets('HARMONISATION-E : sans etat de la photo, pas de ligne photo', (
      WidgetTester tester,
    ) async {
      await _portail(tester, candidatureAFaire());
      expect(_texte(t.recrutement.portail.elementPhoto), findsNothing);
    });

    testWidgets('HARMONISATION-E : photo et accord faits, « Fait »', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        candidatureAFaire(),
        photoPosee: true,
        accordPublicationSigne: true,
      );
      expect(_texte(t.recrutement.portail.elementPhoto), findsOneWidget);
      expect(_texte(t.recrutement.portail.etatAAjouter), findsNothing);
      // Cadre, accords, piece et photo : quatre « Fait ».
      expect(_texte(t.recrutement.portail.etatFait), findsNWidgets(4));
    });

    testWidgets('HARMONISATION-E : photo posee sans accord, « À ajouter »', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        candidatureAFaire(),
        photoPosee: true,
        accordPublicationSigne: false,
      );
      expect(_texte(t.recrutement.portail.etatAAjouter), findsOneWidget);
    });

    test(
      'pendant l\'examen de la candidature envoyee, la piece est suspendue',
      () {
        const CandidatureDossier envoyee = CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.prequalification,
          etat: EtatCandidature.enExamen,
        );
        expect(envoyee.depotPieceSuspendu, isTrue);
        expect(candidatureAFaire().depotPieceSuspendu, isFalse);
      },
    );
  });

  tearDown(() => LocaleSettings.setLocale(AppLocale.fr));

  group('la salle et la prochaine action', () {
    testWidgets(
      'a completer : la salle, le titre, « Completer ma candidature »',
      (WidgetTester tester) async {
        await _portail(tester, candidatureAFaire());
        expect(_cle('portail-salle'), findsOneWidget);
        expect(
          tester.widget<Text>(_cle('portail-salle')).data,
          t.recrutement.sallesCandidat.candidature,
        );
        // Lot 4 SALLE-1-TOUT-ICI : jamais un nom de salle de la direction.
        expect(find.textContaining('Salle'), findsNothing);
        // CANDIDATURE-UX : « Etape 1 sur 3 », sans phrase de passage.
        expect(_texte(t.commun.etape.surLue(n: 1, total: 3)), findsOneWidget);
        expect(_cle('portail-passage'), findsNothing);
        expect(_texte(t.recrutement.portail.aCompleterTitre), findsOneWidget);
        expect(_texte(t.recrutement.portail.completer), findsOneWidget);
        // Aucun code d'etat ne s'affiche.
        expect(find.textContaining('a_completer'), findsNothing);
        expect(find.textContaining('prequalification'), findsNothing);
        verifierUnSeulBoutonPlein(tester);
      },
    );

    testWidgets('« Completer ma candidature » ouvre le questionnaire', (
      WidgetTester tester,
    ) async {
      await _portail(tester, candidatureAFaire());
      await _toucherTexte(tester, _texte(t.recrutement.portail.completer));
      expect(
        _texte(t.recrutement.parcours.presentation.p1.titre),
        findsOneWidget,
      );
    });

    testWidgets('le cadre publie et pas accepte passe avant : la page du '
        'cadre, jamais celle des accords (CADRE-ECRAN)', (
      WidgetTester tester,
    ) async {
      await _portail(tester, candidatureAFaire(cadreAccepte: false));
      expect(_texte(t.attente.lireEtAccepter), findsOneWidget);
      expect(_texte(t.recrutement.portail.completer), findsNothing);
      await _toucherTexte(tester, _texte(t.attente.lireEtAccepter));
      expect(_texte('PAGE DU CADRE'), findsOneWidget);
      expect(_texte('PAGE DES ACCORDS'), findsNothing);
    });

    testWidgets('en examen : la direction lit, aucune action a faire', (
      WidgetTester tester,
    ) async {
      await _portail(tester, _enExamen);
      expect(_texte(t.recrutement.portail.enExamenTitre), findsOneWidget);
      expect(_texte(t.recrutement.portail.enExamen), findsOneWidget);
      expect(_texte(t.recrutement.portail.completer), findsNothing);
      expect(_cle('portail-versement'), findsNothing);
    });

    testWidgets(
      'versement pas encore possible : son titre et sa phrase, jamais « en '
      'examen »',
      (WidgetTester tester) async {
        // L'etat vient du serveur (`paiement_non_disponible`, transition 8 de
        // L6) : la direction n'examine plus rien tant qu'aucun moyen n'est
        // possible, « en examen » serait faux.
        await _portail(
          tester,
          const CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.paiementNonDisponible,
            version: 4,
            paiement: EtatVersement.incompatible,
          ),
        );
        expect(
          _texte(t.recrutement.portail.versementImpossibleTitre),
          findsOneWidget,
        );
        expect(_cle('portail-versement'), findsOneWidget);
        expect(
          _texte(t.recrutement.portail.versementImpossible),
          findsOneWidget,
        );
        expect(_texte(t.recrutement.portail.libreDePartir), findsOneWidget);
        expect(_texte(t.recrutement.portail.enExamenTitre), findsNothing);
        expect(_texte(t.recrutement.portail.enExamen), findsNothing);
        expect(_texte(t.recrutement.portail.completer), findsNothing);
        // Aucun code d'etat brut.
        expect(find.textContaining('paiement_non_disponible'), findsNothing);
      },
    );

    testWidgets(
      'apres l envoi, « Relire ma candidature » ouvre la lecture seule',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature(
          questionnaireJson: questionnaireJsonDeTest(
            dernieresReponses: reponsesCompletesDeTest(),
            brouillon: false,
          ),
        );
        await _portail(
          tester,
          CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.enExamen,
            version: 4,
            questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 10, 22)),
          ),
          port: port,
        );
        expect(_cle('portail-relire'), findsOneWidget);
        expect(_texte(t.recrutement.portail.relire), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);
        await _toucherTexte(tester, _texte(t.recrutement.portail.relire));
        // La lecture seule : ses reponses, aucun champ, aucun bouton plein.
        expect(_cle('lecture-envoyee'), findsOneWidget);
        expect(_texte(t.recrutement.questionnaire.envoyee), findsOneWidget);
      },
    );

    testWidgets(
      'sans envoi, ou quand le questionnaire est ouvert : aucun lien',
      (WidgetTester tester) async {
        // Rien n'a ete envoye : rien a relire.
        await _portail(tester, _enExamen);
        expect(_cle('portail-relire'), findsNothing);
        // A completer : la prochaine action est le parcours, pas la relecture.
        await _portail(
          tester,
          CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.aCompleter,
            version: 5,
            questionnaire: EtatQuestionnaire(envoyeLe: DateTime(2026, 10, 22)),
          ),
        );
        expect(_cle('portail-relire'), findsNothing);
        expect(_texte(t.recrutement.portail.completer), findsOneWidget);
      },
    );

    testWidgets('en examen : « Actualiser » relit l etat, et disparait quand '
        'plus rien ne s attend', (WidgetTester tester) async {
      final FauxServiceDossier dossier = await _portail(tester, _enExamen);
      expect(_texte(t.attente.actualiser), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      // La direction a decide pendant l'attente : la relecture le montre.
      dossier.etatRendu = etatCandidat(
        candidature: const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.prequalification,
          etat: EtatCandidature.enExamen,
          issue: IssueCandidature.refusee,
          version: 5,
        ),
      );
      await _toucherTexte(tester, _texte(t.attente.actualiser));
      expect(_texte(t.recrutement.portail.refuseeTitre), findsOneWidget);
      expect(_texte(t.recrutement.portail.enExamenTitre), findsNothing);
      // Une candidature refusee n'attend plus rien : plus d'« Actualiser ».
      expect(_texte(t.attente.actualiser), findsNothing);
    });

    testWidgets('a completer : pas d « Actualiser », la prochaine action est '
        'le parcours', (WidgetTester tester) async {
      await _portail(tester, candidatureAFaire());
      expect(_texte(t.attente.actualiser), findsNothing);
      expect(_texte(t.recrutement.portail.completer), findsOneWidget);
    });

    testWidgets('en examen, le versement ne se deduit pas : aucune phrase', (
      WidgetTester tester,
    ) async {
      // Un versement « incompatible » seul ne change pas l'etat dit : c'est
      // l'etat que le serveur rend qui commande le portail.
      await _portail(
        tester,
        const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.prequalification,
          etat: EtatCandidature.enExamen,
          version: 4,
          paiement: EtatVersement.incompatible,
        ),
      );
      expect(_texte(t.recrutement.portail.enExamenTitre), findsOneWidget);
      expect(_cle('portail-versement'), findsNothing);
    });

    testWidgets('un complement demande se liste, sans code', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        candidatureAFaire(complement: <String>['publics', 'inconnu_de_nous']),
      );
      expect(_texte(t.recrutement.portail.complementDemande), findsOneWidget);
      final Finder liste = _cle('portail-complement');
      expect(liste, findsOneWidget);
      expect(
        tester.widget<Text>(liste).data,
        t.recrutement.portail.complementListe(
          elements: t.recrutement.questionnaire.publics,
        ),
      );
      expect(find.textContaining('inconnu_de_nous'), findsNothing);
    });

    testWidgets(
      'en verification : l en-tete de la salle, les ecrans du dossier restent',
      (WidgetTester tester) async {
        await _portail(
          tester,
          const CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.verifications,
            etat: EtatCandidature.entretienAPlanifier,
            version: 5,
          ),
        );
        expect(
          _texte(t.recrutement.sallesCandidat.connaissance),
          findsOneWidget,
        );
        // CANDIDATURE-UX (directeur, 14/11/2026) : la bonne nouvelle au-dessus,
        // puis « Etape 2 sur 3 », lus de l'etape rendue par le serveur.
        expect(_texte(t.recrutement.sallesCandidat.retenue), findsOneWidget);
        expect(_texte(t.commun.etape.surLue(n: 2, total: 3)), findsOneWidget);
        expect(
          tester.getTopLeft(_cle('portail-passage')).dy,
          lessThan(tester.getTopLeft(_cle('portail-salle')).dy),
        );
        // Lot 4 SALLE-1-TOUT-ICI : jamais un nom de salle de la direction.
        expect(find.textContaining('Salle'), findsNothing);
        expect(_texte(t.recrutement.portail.aCompleterTitre), findsNothing);
      },
    );

    testWidgets(
      'confirmee : « Bienvenue dans l\'equipe », jamais un nom de salle',
      (WidgetTester tester) async {
        await _portail(
          tester,
          const CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.confirmee,
            etat: EtatCandidature.decisionEnAttente,
            version: 9,
          ),
        );
        expect(_texte(t.recrutement.sallesCandidat.equipe), findsOneWidget);
        expect(_texte(t.recrutement.sallesCandidat.arrivee), findsOneWidget);
        expect(_texte(t.commun.etape.surLue(n: 3, total: 3)), findsOneWidget);
        expect(_texte(t.recrutement.salles.prets), findsNothing);
        expect(find.textContaining('Salle'), findsNothing);
      },
    );

    testWidgets('sans candidature : le portail d avant, inchange', (
      WidgetTester tester,
    ) async {
      await _portail(tester, CandidatureDossier.aucune);
      expect(_cle('portail-salle'), findsNothing);
      expect(_cle('retrait-lien'), findsNothing);
      expect(_texte(t.attente.titreDossier), findsOneWidget);
    });
  });

  group('pause, refus, retrait', () {
    testWidgets(
      'en pause : le texte de la direction, la reprise, jamais un motif',
      (WidgetTester tester) async {
        await _portail(
          tester,
          CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            etat: EtatCandidature.enExamen,
            enPause: true,
            version: 4,
            pauseTexte: 'Nous reprenons les candidatures en janvier.',
            repriseLe: DateTime(2027, 1, 10),
          ),
        );
        expect(_texte(t.recrutement.portail.enPauseTitre), findsOneWidget);
        expect(
          _texte('Nous reprenons les candidatures en janvier.'),
          findsOneWidget,
        );
        expect(find.textContaining('10/01/2027'), findsOneWidget);
        expect(_texte(t.recrutement.portail.libreDePartir), findsOneWidget);
        // Le retrait reste possible en pause.
        expect(_cle('retrait-lien'), findsOneWidget);
      },
    );

    testWidgets(
      'refusee : le texte du modele, pas de retrait, pas de questionnaire',
      (WidgetTester tester) async {
        await _portail(
          tester,
          const CandidatureDossier(
            existe: true,
            etape: EtapeCandidature.prequalification,
            issue: IssueCandidature.refusee,
            version: 6,
            refusTexte: 'Nous ne pouvons pas donner suite pour le moment.',
          ),
        );
        expect(_texte(t.recrutement.portail.refuseeTitre), findsOneWidget);
        expect(_cle('portail-refus-texte'), findsOneWidget);
        expect(_cle('retrait-lien'), findsNothing);
        expect(_texte(t.recrutement.portail.completer), findsNothing);
      },
    );

    testWidgets('refusee sans texte : le titre seul, jamais un motif invente', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.prequalification,
          issue: IssueCandidature.refusee,
          version: 6,
        ),
      );
      expect(_texte(t.recrutement.portail.refuseeTitre), findsOneWidget);
      expect(_cle('portail-refus-texte'), findsNothing);
    });

    testWidgets('retiree : la phrase, seule l academie rouvre', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.prequalification,
          issue: IssueCandidature.retiree,
          version: 6,
        ),
      );
      expect(_texte(t.recrutement.portail.retireeTitre), findsOneWidget);
      expect(_texte(t.recrutement.portail.retiree), findsOneWidget);
      expect(_cle('retrait-lien'), findsNothing);
    });
  });

  group('le retrait de la candidature', () {
    testWidgets('la confirmation dit l effet avant ; annuler n envoie rien', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await _portail(tester, candidatureAFaire(), port: port);
      await toucherCle(tester, 'retrait-lien');
      expect(_texte(t.recrutement.retrait.question), findsOneWidget);
      expect(_texte(t.recrutement.retrait.consequence), findsOneWidget);
      await tester.tap(_texte(t.commun.annuler));
      await tester.pumpAndSettle();
      expect(port.retraits, isEmpty);
      expect(_texte(t.recrutement.portail.aCompleterTitre), findsOneWidget);
    });

    testWidgets(
      'confirmer envoie la version et une cle ; le portail relit l etat',
      (WidgetTester tester) async {
        final FauxMaCandidature port = FauxMaCandidature();
        final FauxServiceDossier dossier = await _portail(
          tester,
          candidatureAFaire(),
          port: port,
        );
        await toucherCle(tester, 'retrait-lien');
        // Le serveur retire, puis le dossier le dit.
        dossier.etatRendu = etatCandidat(
          candidature: port.candidatureApresRetrait,
        );
        await _confirmerRetrait(tester);
        expect(port.retraits, hasLength(1));
        expect(port.retraits.single.$1, 3);
        expect(port.retraits.single.$2, startsWith('cand-'));
        expect(_texte(t.recrutement.portail.retireeTitre), findsOneWidget);
        expect(_cle('retrait-lien'), findsNothing);
      },
    );

    testWidgets('un entretien planifie dit qu il sera annule', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        const CandidatureDossier(
          existe: true,
          etape: EtapeCandidature.verifications,
          etat: EtatCandidature.entretienPlanifie,
          version: 5,
        ),
      );
      await toucherCle(tester, 'retrait-lien');
      expect(
        _texte(t.recrutement.retrait.consequenceEntretien),
        findsOneWidget,
      );
    });

    for (final (String nom, Object erreur, String Function() message)
        in <(String, Object, String Function())>[
          (
            'conflit',
            const ConflitCandidature(9),
            () => t.recrutement.retrait.conflit,
          ),
          (
            'transition interdite',
            const TransitionInterdite(),
            () => t.recrutement.retrait.interdit,
          ),
          (
            'capacite indisponible',
            const CapaciteIndisponible(dependanceCandidature),
            () => t.recrutement.retrait.echec,
          ),
          (
            'issue incertaine',
            const HorsLigneCandidature(),
            () => t.recrutement.retrait.incertain,
          ),
        ]) {
      testWidgets('refus « $nom » : une phrase, la candidature reste', (
        WidgetTester tester,
      ) async {
        final FauxMaCandidature port = FauxMaCandidature()
          ..erreurRetrait = erreur;
        await _portail(tester, candidatureAFaire(), port: port);
        await toucherCle(tester, 'retrait-lien');
        await _confirmerRetrait(tester);
        expect(_cle('retrait-message'), findsOneWidget);
        expect(_texte(message()), findsOneWidget);
        expect(_texte(t.recrutement.portail.retireeTitre), findsNothing);
      });
    }

    testWidgets('issue incertaine : le second essai rejoue la meme cle', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurRetrait = const HorsLigneCandidature();
      await _portail(tester, candidatureAFaire(), port: port);
      await toucherCle(tester, 'retrait-lien');
      await _confirmerRetrait(tester);
      port.erreurRetrait = null;
      await toucherCle(tester, 'retrait-lien');
      await _confirmerRetrait(tester);
      expect(port.retraits, hasLength(2));
      expect(port.retraits.last.$2, port.retraits.first.$2);
    });

    testWidgets('un refus net change la cle du second essai', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature()
        ..erreurRetrait = const ConflitCandidature(9);
      await _portail(tester, candidatureAFaire(), port: port);
      await toucherCle(tester, 'retrait-lien');
      await _confirmerRetrait(tester);
      port.erreurRetrait = null;
      await toucherCle(tester, 'retrait-lien');
      await _confirmerRetrait(tester);
      expect(port.retraits.last.$2, isNot(port.retraits.first.$2));
    });

    testWidgets('hors ligne : pas de lien, une note qui dit quand', (
      WidgetTester tester,
    ) async {
      final FauxMaCandidature port = FauxMaCandidature();
      await _portail(tester, candidatureAFaire(), port: port, horsLigne: true);
      expect(_cle('retrait-lien'), findsNothing);
      expect(_cle('retrait-hors-ligne'), findsOneWidget);
      expect(port.retraits, isEmpty);
    });
  });

  group('largeurs, arabe', () {
    testWidgets('a 1440 le portail garde une colonne bornee', (
      WidgetTester tester,
    ) async {
      await _portail(
        tester,
        candidatureAFaire(),
        taille: const Size(1440, 900),
      );
      final Rect carte = tester.getRect(
        find.byKey(const ValueKey<String>('portail-titre')),
      );
      expect(carte.width, lessThan(900));
      verifierUnSeulBoutonPlein(tester);
    });

    for (final Size taille in const <Size>[Size(390, 844), Size(320, 640)]) {
      testWidgets(
        'en arabe, de droite a gauche, texte x2, a ${taille.width.toInt()}',
        (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
          await _portail(
            tester,
            candidatureAFaire(complement: <String>['publics']),
            taille: taille,
            direction: TextDirection.rtl,
            echelle: 2,
          );
          expect(tester.takeException(), isNull);
          expect(_cle('portail-titre'), findsOneWidget);
          expect(_cle('retrait-lien'), findsOneWidget);
        },
      );
    }
  });
}
