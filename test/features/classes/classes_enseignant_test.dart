import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/classes/carte_classe.dart';
import 'package:rewayah_academy/features/classes/domaine/classe_vm.dart';
import 'package:rewayah_academy/features/classes/domaine/conformite.dart';
import 'package:rewayah_academy/features/classes/domaine/erreur_domaine.dart';
import 'package:rewayah_academy/features/classes/domaine/providers.dart';
import 'package:rewayah_academy/features/classes/routes_core24.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/harnais.dart';
import 'faux/faux_ports_classes.dart';
import 'support/largeurs.dart';

GoRoute _temoin(String chemin, String texte) => GoRoute(
  path: chemin,
  builder: (BuildContext _, GoRouterState _) => Scaffold(body: Text(texte)),
);

const ConformiteCompte _cleare = ConformiteCompte(
  exigence: ExigenceKyc.requise,
  etat: EtatKyc.verifie,
  contratAccepte: true,
);

const ConformiteCompte _sansKyc = ConformiteCompte(
  exigence: ExigenceKyc.requise,
  etat: EtatKyc.nonCommence,
  contratAccepte: true,
);

const ConformiteCompte _dispense = ConformiteCompte(
  exigence: ExigenceKyc.dispensee,
  etat: EtatKyc.nonCommence,
  contratAccepte: true,
);

/// Les Classes disponibles de l'appelant (`null` : pas de membre).
Map<String?, List<ClasseVM>> _pourMoi(List<ClasseVM> classes) =>
    <String?, List<ClasseVM>>{null: classes};

Future<FauxPortMarketplace> _monter(
  WidgetTester tester, {
  required ConformiteCompte conformite,
  FauxPortMarketplace? marche,
}) async {
  final FauxPortMarketplace faux = marche ?? FauxPortMarketplace();
  await tester.pumpWidget(
    hoteRoutant(
      depart: CheminsCore24.enseignantClasses,
      routes: <RouteBase>[
        ...routesCore24(),
        _temoin(Routes.enseignantJournee, 'journee'),
        _temoin(Routes.attentePiece, 'piece'),
        _temoin(Routes.attenteContrat, 'contrat'),
        GoRoute(
          path: '${Routes.enseignantGroupe}/:groupeId',
          builder: (BuildContext _, GoRouterState etat) =>
              Text('fiche:${etat.pathParameters['groupeId']}'),
        ),
      ],
      surcharges: <Override>[
        portConformiteProvider.overrideWithValue(
          FauxPortConformite(mienne: conformite),
        ),
        portMarketplaceProvider.overrideWithValue(faux),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return faux;
}

void main() {
  group('Avant la clearance, l enseignant reste dans son onboarding', () {
    testWidgets('KYC requis et non commence : les classes restent masquees', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _monter(
          tester,
          conformite: _sansKyc,
          marche: FauxPortMarketplace(
            disponiblesParMembre: _pourMoi(<ClasseVM>[classeDeTest()]),
          ),
        );

        expect(find.text(t.classes.enseignant.onboardingTitre), findsOneWidget);
        expect(find.text(t.classes.enseignant.clearanceAttente), findsOneWidget);
        expect(find.text(t.classes.enseignant.disponibles), findsNothing);
        expect(find.byType(CarteClasse), findsNothing);
        // L'etape KYC dit ou l'on en est, et ce qui debloque.
        expect(find.text(t.classes.conformite.etatNonCommence), findsOneWidget);
        await tester.tap(find.text(t.classes.enseignant.deposerPiece));
        await tester.pumpAndSettle();
        expect(find.text('piece'), findsOneWidget);
      });
    });

    testWidgets('le contrat reste obligatoire, meme KYC verifie', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _monter(
          tester,
          conformite: const ConformiteCompte(
            exigence: ExigenceKyc.requise,
            etat: EtatKyc.verifie,
            contratAccepte: false,
          ),
        );

        expect(find.text(t.classes.conformite.contratManquant), findsOneWidget);
        expect(find.text(t.classes.enseignant.disponibles), findsNothing);
        await tester.tap(find.text(t.classes.enseignant.signerContrat));
        await tester.pumpAndSettle();
        expect(find.text('contrat'), findsOneWidget);
      });
    });

    testWidgets('une dispense sans contrat se lit comme telle', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _monter(
          tester,
          conformite: const ConformiteCompte(
            exigence: ExigenceKyc.dispensee,
            etat: EtatKyc.nonCommence,
            contratAccepte: false,
          ),
        );

        // La dispense est une decision de l'academie : nommee, jamais un
        // contournement.
        expect(find.text(t.classes.conformite.exigenceDispensee), findsOneWidget);
        expect(find.text(t.classes.enseignant.etapeKycDispense), findsOneWidget);
        expect(find.text(t.classes.enseignant.deposerPiece), findsNothing);
        expect(find.text(t.classes.conformite.contratManquant), findsOneWidget);
      });
    });
  });

  group('Apres la clearance, deux sections et un seul bouton par carte', () {
    testWidgets('mes classes ouvrent la fiche, les disponibles se candidatent', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurTabletteLarge, () async {
        final FauxPortMarketplace marche = await _monter(
          tester,
          conformite: _cleare,
          marche: FauxPortMarketplace(
            miennes: <ClasseVM>[classeDeTest(id: 'mienne', libelle: 'Ma classe')],
            disponiblesParMembre: _pourMoi(<ClasseVM>[
              classeDeTest(id: 'ouverte', libelle: 'Classe ouverte'),
            ]),
          ),
        );

        // Le titre de page et l'en-tete de section portent le meme mot : deux
        // occurrences, et c'est voulu.
        expect(find.text(t.classes.enseignant.mesClasses), findsNWidgets(2));
        expect(find.text(t.classes.enseignant.disponibles), findsOneWidget);
        expect(find.byType(CarteClasse), findsNWidgets(2));

        await tester.tap(
          find.widgetWithText(ActionPrincipale, t.classes.enseignant.candidater),
        );
        await tester.pumpAndSettle();

        expect(marche.candidatures, <String>['ouverte']);
        expect(find.text(t.classes.enseignant.candidatureEnvoyee), findsWidgets);
        // Une candidature partie n'a plus de bouton.
        expect(
          find.widgetWithText(ActionPrincipale, t.classes.enseignant.candidater),
          findsNothing,
        );

        await tester.tap(
          find.widgetWithText(ActionPrincipale, t.classes.enseignant.ouvrirFiche),
        );
        await tester.pumpAndSettle();
        expect(find.text('fiche:mienne'), findsOneWidget);
      });
    });

    testWidgets('une dispense reste visible apres clearance', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _monter(tester, conformite: _dispense);
        expect(find.text(t.classes.enseignant.disponibles), findsOneWidget);
        expect(find.text(t.classes.enseignant.etapeKycDispense), findsOneWidget);
      });
    });

    testWidgets('un refus de candidature se dit en langage humain', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _monter(
          tester,
          conformite: _cleare,
          marche: FauxPortMarketplace(
            disponiblesParMembre: _pourMoi(<ClasseVM>[classeDeTest()]),
          )..erreurAction = const PostgrestException(
            message: 'candidature deja deposee pour ce groupe',
            code: 'P0001',
          ),
        );

        final Finder bouton = find.widgetWithText(
          ActionPrincipale,
          t.classes.enseignant.candidater,
        );
        await tester.ensureVisible(bouton);
        await tester.pumpAndSettle();
        await tester.tap(bouton);
        await tester.pumpAndSettle();

        expect(find.text(t.classes.erreur.dejaCandidat), findsOneWidget);
        expect(find.textContaining('P0001'), findsNothing);
        expect(find.textContaining('deposee pour ce groupe'), findsNothing);
      });
    });

    testWidgets('une capacite serveur absente se dit, sans faire semblant', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _monter(
          tester,
          conformite: _cleare,
          marche: FauxPortMarketplace()
            ..erreurDisponibles = const EchecDomaine(MotifEchec.capaciteAbsente),
        );

        expect(find.text(t.classes.commun.capaciteAbsente), findsOneWidget);
        expect(find.text(t.classes.enseignant.aucuneAssignee), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });

  testWidgets('la page tient sur les cinq largeurs sans deborder', (
    WidgetTester tester,
  ) async {
    for (final double largeur in largeursP0) {
      await avecLargeur(tester, largeur, () async {
        await _monter(
          tester,
          conformite: _cleare,
          marche: FauxPortMarketplace(
            miennes: <ClasseVM>[classeDeTest()],
            disponiblesParMembre: _pourMoi(<ClasseVM>[
              classeDeTest(id: 'a', libelle: 'A'),
              classeDeTest(id: 'b', libelle: 'B'),
            ]),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$largeur');
        expect(find.byType(CarteClasse), findsNWidgets(3), reason: '$largeur');
      });
    }
  });
}
