import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/marque_page.dart';
import 'package:rewayah_academy/features/dossier/accords_page.dart';
import 'package:rewayah_academy/features/dossier/attente_page.dart';
import 'package:rewayah_academy/features/inscription/brouillon_inscription.dart';

import '../support/harnais.dart';

Future<void> _monter(WidgetTester tester, FauxServiceDossier dossier) async {
  await tester.pumpWidget(
    hote(
      const AttentePage(),
      surcharges: <Override>[serviceDossierProvider.overrideWithValue(dossier)],
    ),
  );
  await tester.pumpAndSettle();
}

// K-47 (HL-A-6) : la piece, sa verification et son refus ne concernent que
// l'enseignant ; le tuteur se construit avec [role] explicite.
EtatDossier _etat({
  AppRole role = AppRole.teacher,
  AccountStatus statut = AccountStatus.pendingKyc,
  bool accuse = false,
  bool contrat = false,
  bool piece = false,
  StatutPiece? statutPiece,
  String? motif,
  DateTime? depose,
  bool? correction,
  UsageTitulaire? usage,
}) => EtatDossier(
  profilExiste: true,
  role: role,
  statutCompte: statut,
  accuseSigne: accuse,
  contratSigne: contrat,
  pieceDeposee: piece,
  statutPiece: statutPiece,
  motifRefus: motif,
  deposeLe: depose,
  correctionAutorisee: correction,
  usage: usage,
);

void main() {
  // AD-NETTOYAGE-2 (m6, m7, m8, m11).
  group('mise en page du portail d attente', () {
    testWidgets('une seule tete : le titre de la page, pas le mot-marque', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.enAttente,
        );
      await _monter(tester, dossier);
      expect(find.byType(MarquePage), findsNothing);
      expect(find.text(t.attente.titreDossier), findsOneWidget);
    });

    testWidgets('1440 : la colonne est bornee a 760 et Actualiser tient au '
        'bord de fin', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      addTearDown(tester.view.reset);
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.enAttente,
        );
      await _monter(tester, dossier);
      final Rect carte = tester.getRect(find.byType(AppCard));
      expect(carte.width, lessThanOrEqualTo(AppPage.largeurReglages));
      final Rect actualiser = tester.getRect(
        find.widgetWithText(ActionPrincipale, t.attente.actualiser),
      );
      // Au bord de fin de la colonne, pas au centre : le bouton est a droite
      // de la moitie de la carte, et aligne sur son bord de fin.
      expect(actualiser.right, closeTo(carte.right, 1));
      expect(actualiser.width, lessThan(carte.width - 4 * AppSpacing.lg));
    });

    testWidgets('refus : l element a reprendre, en minuscule apres la '
        'ponctuation, et le motif en encre normale', (
      WidgetTester tester,
    ) async {
      const String motif = 'Photo illisible, merci de la reprendre.';
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.refusee,
          motif: motif,
        );
      await _monter(tester, dossier);
      expect(
        t.attente.refuseDetail(element: t.attente.pieceIdentite),
        startsWith('Élément à reprendre'),
      );
      final Text texteMotif = tester.widget<Text>(find.text(motif));
      final Text titre = tester.widget<Text>(find.text(t.attente.refuse));
      // Le motif n'est plus plus visible que le titre « Dossier refusé ».
      expect(texteMotif.style!.fontSize!, lessThan(titre.style!.fontSize!));
    });
  });

  group('Scenario 10 : le portail d attente affiche le bon etat', () {
    testWidgets('dossier incomplet : la liste de ce qui manque, dans l ordre', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat();
      await _monter(tester, dossier);

      expect(find.text(t.attente.dossierIncomplet), findsOneWidget);
      // Lot E6 : l'accuse et le contrat ne font plus qu'une ligne, la page
      // unique des accords ; la piece reste une etape a part.
      expect(find.text(t.attente.nosConditions), findsOneWidget);
      expect(find.text(t.attente.carteAccuse), findsNothing);
      expect(find.text(t.attente.signatureContrat), findsNothing);
      expect(find.text(t.attente.pieceIdentite), findsOneWidget);
      expect(find.text(t.attente.reste(n: 2)), findsOneWidget);

      // Les accords precedent la piece.
      final double yAccords = tester
          .getTopLeft(find.text(t.attente.nosConditions))
          .dy;
      final double yPiece = tester
          .getTopLeft(find.text(t.attente.pieceIdentite))
          .dy;
      expect(yAccords, lessThan(yPiece));
    });

    testWidgets('en verification : le statut, la date et le delai', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.enAttente,
          depose: DateTime(2026, 9, 4),
        );
      await _monter(tester, dossier);

      expect(find.text(t.attente.titre), findsOneWidget);
      expect(find.textContaining('04/09/2026'), findsOneWidget);
      expect(find.text(t.attente.dossierIncomplet), findsNothing);
    });

    testWidgets('refuse : le motif en une phrase, et de quoi corriger', (
      WidgetTester tester,
    ) async {
      const String motif = 'Photo illisible, merci de la reprendre.';
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.refusee,
          motif: motif,
        );
      await _monter(tester, dossier);

      expect(find.text(t.attente.refuse), findsOneWidget);
      expect(find.text(motif), findsOneWidget);
      expect(find.text(t.attente.corriger), findsOneWidget);
    });

    testWidgets('suspendu : le motif prime sur l etat du dossier', (
      WidgetTester tester,
    ) async {
      // Un compte suspendu le reste meme si son dossier est complet : sinon
      // l ecran lui dirait « nous verifions » alors que rien n avance.
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          statut: AccountStatus.disabled,
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.enAttente,
        );
      await _monter(tester, dossier);

      expect(find.text(t.attente.suspendu), findsOneWidget);
      expect(find.text(t.attente.titre), findsNothing);
    });

    testWidgets('un etat illisible se dit, et laisse reessayer', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..erreurAJeter = StateError('reseau');
      await _monter(tester, dossier);

      expect(find.text(t.commun.reessayer), findsOneWidget);
      expect(find.text(t.attente.dossierIncomplet), findsNothing);
    });

    testWidgets('le portail ne laisse jamais deviner ce qui est derriere', (
      WidgetTester tester,
    ) async {
      // Un portail qui montre l application sous un voile cree de la
      // frustration. Aucun libelle de navigation de role ne doit apparaitre.
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat();
      await _monter(tester, dossier);

      for (final String interdit in <String>[
        t.nav.tuteur.foyer,
        t.nav.tuteur.disponibilites,
        t.nav.eleve.coran,
        t.nav.enseignant.journee,
      ]) {
        expect(find.text(interdit), findsNothing, reason: interdit);
      }
    });
  });

  group('La prochaine action mene au bon contrat, geste depuis le portail', () {
    Future<void> monter(
      WidgetTester tester, {
      required UsageInscription? usage,
      UsageTitulaire? usageServeur,
    }) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          role: AppRole.guardian,
          accuse: true,
          usage: usageServeur,
        );
      final List<Override> surcharges = <Override>[
        serviceDossierProvider.overrideWithValue(dossier),
      ];
      if (usage != null) {
        surcharges.add(
          brouillonInscriptionProvider.overrideWith(
            () => _ControleurBrouillonDeTest(usage),
          ),
        );
      }
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.attente,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.attente,
              builder: (BuildContext _, GoRouterState _) => const AttentePage(),
            ),
            GoRoute(
              path: Routes.attenteAccords,
              builder: (BuildContext _, GoRouterState _) => const AccordsPage(),
            ),
          ],
          surcharges: surcharges,
        ),
      );
      await tester.pumpAndSettle();

      // HL-A-5 : l'action est sous la carte d'etat, dans le corps defilant.
      // Lot E6 : une seule action, vers la page unique des accords.
      expect(find.text(t.attente.signerLeContrat), findsNothing);
      await tester.ensureVisible(find.text(t.attente.lireEtAccepter));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.attente.lireEtAccepter));
      await tester.pumpAndSettle();
    }

    testWidgets('inscription « Moi uniquement » : variante eleve adulte', (
      WidgetTester tester,
    ) async {
      await monter(tester, usage: UsageInscription.moi);

      expect(find.text(t.consentement.texte.caseAdulte), findsOneWidget);
      expect(find.text(t.consentement.texte.caseResponsable), findsNothing);
    });

    testWidgets('sans brouillon (rechargement) : variante responsable legal', (
      WidgetTester tester,
    ) async {
      await monter(tester, usage: null);

      expect(find.text(t.consentement.texte.caseResponsable), findsOneWidget);
      expect(find.text(t.consentement.texte.caseAdulte), findsNothing);
    });

    testWidgets('L5-01 : « Moi » garde par le serveur, sans brouillon '
        '(rechargement) : variante eleve adulte', (WidgetTester tester) async {
      await monter(tester, usage: null, usageServeur: UsageTitulaire.moi);

      expect(find.text(t.consentement.texte.caseAdulte), findsOneWidget);
      expect(find.text(t.consentement.texte.caseResponsable), findsNothing);
    });

    testWidgets('L5-01 : le serveur prime sur le brouillon', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        usage: UsageInscription.moi,
        usageServeur: UsageTitulaire.famille,
      );

      expect(find.text(t.consentement.texte.caseResponsable), findsOneWidget);
      expect(find.text(t.consentement.texte.caseAdulte), findsNothing);
    });
  });

  group('EtatDossier : ce qui manque, et dans quel ordre', () {
    test('un refus prime sur une piece manquante', () {
      // C est le refus qui porte le motif, donc ce que la famille doit lire.
      final EtatDossier refuse = _etat(
        accuse: true,
        contrat: true,
        piece: true,
        statutPiece: StatutPiece.refusee,
        motif: 'flou',
      );
      expect(refuse.etape, EtapeDossier.refuse);
    });

    test('un dossier complet passe en verification', () {
      expect(
        _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.enAttente,
        ).etape,
        EtapeDossier.enVerification,
      );
    });

    test('la lecture de etat_dossier() sait rendre un compte sans profil', () {
      final EtatDossier lu = EtatDossier.depuisJson(const <String, dynamic>{
        'profil': false,
      });
      expect(lu.profilExiste, isFalse);
    });

    test('L5-01 : la lecture reprend usage et suit_des_cours', () {
      final EtatDossier lu = EtatDossier.depuisJson(const <String, dynamic>{
        'profil': true,
        'role': 'guardian',
        'statut': 'pending_kyc',
        'usage': 'moi',
        'suit_des_cours': true,
      });
      expect(lu.usage, UsageTitulaire.moi);
      expect(lu.suitDesCours, isTrue);
      final EtatDossier ancien = EtatDossier.depuisJson(const <String, dynamic>{
        'profil': true,
        'role': 'guardian',
      });
      expect(ancien.usage, isNull);
      expect(ancien.suitDesCours, isFalse);
    });

    test(
      'la lecture reprend le motif et la date telle que la base les donne',
      () {
        final EtatDossier lu = EtatDossier.depuisJson(const <String, dynamic>{
          'profil': true,
          'role': 'teacher',
          'statut': 'pending_kyc',
          'piece_deposee': true,
          'piece_statut': 'rejected',
          'motif_refus': 'Photo illisible.',
          'depose_le': '2026-09-04T08:30:00Z',
          'contrat_signe': true,
          'accuse_signe': true,
        });

        expect(lu.role, AppRole.teacher);
        expect(lu.statutPiece, StatutPiece.refusee);
        expect(lu.motifRefus, 'Photo illisible.');
        expect(lu.deposeLe?.toUtc(), DateTime.utc(2026, 9, 4, 8, 30));
        expect(lu.etape, EtapeDossier.refuse);
      },
    );
  });

  group('AD-10 : correction, correction interdite, relecture au retour', () {
    Future<(FausseSourceSession, FauxServiceAuth)> monter(
      WidgetTester tester,
      EtatDossier etat,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()..etatRendu = etat;
      final FausseSourceSession source = FausseSourceSession();
      final FauxServiceAuth auth = FauxServiceAuth();
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.attente,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.attente,
              builder: (BuildContext _, GoRouterState _) => const AttentePage(),
            ),
            GoRoute(
              path: Routes.attenteAccords,
              builder: (BuildContext _, GoRouterState _) => const AccordsPage(),
            ),
            GoRoute(
              path: Routes.attentePiece,
              builder: (BuildContext _, GoRouterState _) =>
                  const Text('route-piece'),
            ),
          ],
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(dossier),
            sourceSessionProvider.overrideWithValue(source),
            serviceAuthProvider.overrideWithValue(auth),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return (source, auth);
    }

    testWidgets(
      'T6 correction interdite : le texte de la spec, sans Corriger',
      (WidgetTester tester) async {
        final (FausseSourceSession _, FauxServiceAuth auth) = await monter(
          tester,
          _etat(
            accuse: true,
            contrat: true,
            piece: true,
            statutPiece: StatutPiece.refusee,
            motif: 'Motif fictif.',
            correction: false,
          ),
        );

        expect(find.text(t.attente.refuse), findsOneWidget);
        expect(find.text(t.attente.correctionImpossible), findsOneWidget);
        expect(find.text(t.attente.corriger), findsNothing);
        expect(
          find.text(t.attente.refuseDetail(element: t.attente.pieceIdentite)),
          findsNothing,
        );

        await tester.tap(find.text(t.attente.seDeconnecter));
        await tester.pumpAndSettle();
        expect(auth.deconnexions, 1);
      },
    );

    testWidgets('T7 Corriger mene au premier element a corriger', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        _etat(
          accuse: true,
          piece: true,
          statutPiece: StatutPiece.refusee,
          motif: 'Motif fictif.',
        ),
      );

      // Le texte nomme l'element que « Corriger » ouvre, et non la piece :
      // depuis le lot E6, la page unique des accords.
      expect(
        find.text(t.attente.refuseDetail(element: t.attente.nosConditions)),
        findsOneWidget,
      );
      await tester.tap(find.text(t.attente.corriger));
      await tester.pumpAndSettle();
      expect(find.byType(AccordsPage), findsOneWidget);
      expect(find.text('route-piece'), findsNothing);
    });

    testWidgets('Corriger mene au depot quand seule la piece est refusee', (
      WidgetTester tester,
    ) async {
      await monter(
        tester,
        _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.refusee,
          motif: 'Motif fictif.',
        ),
      );

      await tester.tap(find.text(t.attente.corriger));
      await tester.pumpAndSettle();
      expect(find.text('route-piece'), findsOneWidget);
    });

    testWidgets('en verification : aucune promesse, et l actualisation relit', (
      WidgetTester tester,
    ) async {
      final (FausseSourceSession source, FauxServiceAuth _) = await monter(
        tester,
        _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.enAttente,
        ),
      );

      expect(find.textContaining('notification'), findsNothing);
      await tester.tap(find.text(t.attente.actualiser));
      await tester.pumpAndSettle();
      expect(source.rafraichissements, 1);
    });

    testWidgets('T8 le retour dans l application relit la session', (
      WidgetTester tester,
    ) async {
      final (FausseSourceSession source, FauxServiceAuth _) = await monter(
        tester,
        _etat(
          accuse: true,
          contrat: true,
          piece: true,
          statutPiece: StatutPiece.enAttente,
        ),
      );

      // Les transitions une a une, comme la plateforme les envoie.
      for (final AppLifecycleState s in <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump();
      expect(source.rafraichissements, 0);
      for (final AppLifecycleState s in <AppLifecycleState>[
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pumpAndSettle();
      expect(source.rafraichissements, 1);
    });

    // K-47 (HL-A-6) : le tuteur ne depose aucune piece et n'attend aucune
    // validation ; ses accords restent.
    testWidgets('tuteur incomplet : ses accords, jamais la piece', (
      WidgetTester tester,
    ) async {
      await monter(tester, _etat(role: AppRole.guardian));

      expect(find.text(t.attente.accordsARelire), findsOneWidget);
      // Lot E6 : une seule ligne pour les accords, et aucun « element a
      // fournir » pour qui n'a rien a fournir (E11).
      expect(find.text(t.attente.nosConditions), findsOneWidget);
      expect(find.text(t.attente.etatAAccepter), findsOneWidget);
      expect(find.text(t.attente.reste(n: 1)), findsNothing);
      expect(find.text(t.attente.carteAccuse), findsNothing);
      expect(find.text(t.attente.signatureContrat), findsNothing);
      expect(find.text(t.attente.pieceIdentite), findsNothing);
      expect(find.text(t.attente.deposerLaPiece), findsNothing);
      expect(find.text(t.attente.dossierIncomplet), findsNothing);
      expect(find.text(t.attente.titreDossier), findsNothing);
    });

    testWidgets(
      'tuteur accords signes, compte en attente : etat honnete, sans piece',
      (WidgetTester tester) async {
        final (FausseSourceSession source, FauxServiceAuth auth) = await monter(
          tester,
          _etat(role: AppRole.guardian, accuse: true, contrat: true),
        );

        expect(find.text(t.attente.accesTitre), findsOneWidget);
        expect(find.text(t.attente.accesEnPreparation), findsOneWidget);
        expect(find.textContaining(t.attente.aucunDocument), findsOneWidget);
        // Aucune ouverture n'est promise « en cours » : la sortie est dite.
        expect(find.textContaining(t.attente.accesContact), findsOneWidget);
        expect(find.text(t.attente.titreCompte), findsWidgets);
        for (final String interdit in <String>[
          t.attente.titre,
          t.attente.enVerification,
          t.attente.delai,
          t.attente.pieceIdentite,
          t.attente.deposerLaPiece,
          t.attente.corriger,
        ]) {
          expect(find.text(interdit), findsNothing, reason: interdit);
        }

        await tester.tap(find.text(t.attente.actualiserCompte));
        await tester.pumpAndSettle();
        expect(source.rafraichissements, 1);

        await tester.tap(find.text(t.attente.seDeconnecter));
        await tester.pumpAndSettle();
        expect(auth.deconnexions, 1);
      },
    );

    testWidgets(
      'tuteur avec une ancienne piece refusee : ni refus ni Corriger',
      (WidgetTester tester) async {
        await monter(
          tester,
          _etat(
            role: AppRole.guardian,
            accuse: true,
            contrat: true,
            piece: true,
            statutPiece: StatutPiece.refusee,
            motif: 'Motif fictif.',
          ),
        );

        expect(find.text(t.attente.refuse), findsNothing);
        expect(find.text('Motif fictif.'), findsNothing);
        expect(find.text(t.attente.corriger), findsNothing);
        expect(find.text(t.attente.accesEnPreparation), findsOneWidget);
        expect(find.text('route-piece'), findsNothing);
      },
    );

    test('tuteur : aucune piece exigee, meme si la base ne le dit pas', () {
      final EtatDossier lu = EtatDossier.depuisJson(const <String, dynamic>{
        'profil': true,
        'role': 'guardian',
        'statut': 'pending_kyc',
        'contrat_signe': true,
        'accuse_signe': true,
      });
      expect(lu.pieceExigee, isFalse);
      expect(lu.manquants, isEmpty);
      expect(lu.etape, EtapeDossier.accesEnPreparation);
    });

    testWidgets(
      'role illisible : etat illisible et Reessayer, jamais la piece',
      (WidgetTester tester) async {
        final FauxServiceDossier dossier = FauxServiceDossier()
          ..etatRendu = const EtatDossier(
            profilExiste: true,
            statutCompte: AccountStatus.pendingKyc,
          );
        await _monter(tester, dossier);

        expect(find.text(t.attente.illisible), findsOneWidget);
        expect(find.text(t.commun.reessayer), findsOneWidget);
        expect(find.text(t.attente.pieceIdentite), findsNothing);
        expect(find.text(t.attente.deposerLaPiece), findsNothing);
        expect(
          const EtatDossier(profilExiste: true).pieceExigee,
          isFalse,
          reason: 'un role absent n exige aucune piece',
        );
      },
    );

    test('T11 correction_autorisee absente : nulle, la correction reste', () {
      final EtatDossier sans = EtatDossier.depuisJson(const <String, dynamic>{
        'profil': true,
        'piece_statut': 'rejected',
      });
      final EtatDossier interdite = EtatDossier.depuisJson(
        const <String, dynamic>{
          'profil': true,
          'piece_statut': 'rejected',
          'correction_autorisee': false,
        },
      );
      expect(sans.correctionAutorisee, isNull);
      expect(interdite.correctionAutorisee, isFalse);
      expect(sans == interdite, isFalse);
    });
  });
}

/// Un brouillon d'inscription fige a un usage, pour tester la variante lue
/// par le portail d'attente sans rejouer les quatre etapes.
class _ControleurBrouillonDeTest extends BrouillonInscriptionControleur {
  _ControleurBrouillonDeTest(this._usage);

  final UsageInscription _usage;

  @override
  BrouillonInscription build() =>
      const BrouillonInscription().copier(usage: _usage);
}
