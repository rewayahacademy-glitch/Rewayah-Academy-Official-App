import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/presence/service_presence.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/classes/carte_classe.dart';
import 'package:rewayah_academy/features/classes/domaine/classe_vm.dart';
import 'package:rewayah_academy/features/classes/domaine/conformite.dart';
import 'package:rewayah_academy/features/classes/domaine/erreur_domaine.dart';
import 'package:rewayah_academy/features/classes/domaine/providers.dart';
import 'package:rewayah_academy/features/classes/routes_core24.dart';
import 'package:rewayah_academy/features/disponibilites/grille_semaine.dart';
import 'package:rewayah_academy/features/tuteur_classes/classes_foyer_page.dart';

import '../../support/harnais.dart';
import 'faux/faux_ports_classes.dart';
import 'support/largeurs.dart';

final DateTime _maintenant = DateTime(2026, 9, 21, 10);

EleveDuFoyer _membre({
  required String id,
  required String prenom,
  InterfaceMode mode = InterfaceMode.enfant,
}) => EleveDuFoyer(
  id: id,
  prenom: prenom,
  identifiantImmuable: 'STUD-$id',
  mode: mode,
  camera: CameraPolicy.forbidden,
);

Seance _seance({
  required String id,
  required String eleveId,
  required DateTime debut,
}) => Seance(
  id: id,
  debut: debut,
  fin: debut.add(const Duration(minutes: 60)),
  statut: StatutSeance.planifiee,
  eleveId: eleveId,
  elevePrenom: 'x',
  eleveIdentifiant: 'STUD-$eleveId',
  enseignantId: 't1',
  enseignantPrenom: 'Aminata',
  enseignantIdentifiant: 'ENS-1',
);

Future<FauxPortMarketplace> _monter(
  WidgetTester tester, {
  List<EleveDuFoyer>? membres,
  FauxPortMarketplace? marche,
  List<Seance> seances = const <Seance>[],
  List<PresenceParticipant>? presences = const <PresenceParticipant>[],
}) async {
  final FauxPortMarketplace faux = marche ?? FauxPortMarketplace();
  await tester.pumpWidget(
    hoteRoutant(
      depart: CheminsCore24.tuteurClasses,
      routes: <RouteBase>[
        GoRoute(
          path: CheminsCore24.tuteurClasses,
          builder: (BuildContext _, GoRouterState _) =>
              ClassesFoyerPage(horloge: () => _maintenant),
        ),
        GoRoute(
          path: Routes.tuteurAccueil,
          builder: (BuildContext _, GoRouterState _) => const Text('accueil'),
        ),
        GoRoute(
          path: Routes.tuteurAjouterEnfant,
          builder: (BuildContext _, GoRouterState _) => const Text('ajout'),
        ),
        GoRoute(
          path: '${Routes.tcGroupes}/:id',
          builder: (BuildContext _, GoRouterState etat) =>
              Text('espace:${etat.pathParameters['id']}'),
        ),
      ],
      surcharges: <Override>[
        serviceAppairageProvider.overrideWithValue(
          FauxServiceAppairage()
            ..elevesRendus =
                membres ??
                <EleveDuFoyer>[
                  _membre(id: 'e1', prenom: 'Amina'),
                  _membre(id: 'e2', prenom: 'Ibrahim'),
                ],
        ),
        portMarketplaceProvider.overrideWithValue(faux),
        servicePlanningProvider.overrideWithValue(
          FauxServicePlanning()..seancesRendues = seances,
        ),
        serviceSuiviProvider.overrideWithValue(
          FauxServiceSuivi(presencesRendues: presences),
        ),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return faux;
}

Map<String?, List<ClasseVM>> _disponibles(Map<String?, List<ClasseVM>> m) => m;

Finder _caseLibre(int jour, int heure) => find.byWidgetPredicate(
  (Widget w) =>
      w is Pressable &&
      w.libelleSemantique ==
          t.disponibilites.celluleLibre(
            jour: t.disponibilites.joursLongs[jour - 1],
            heure: '$heure',
          ),
);

void main() {
  testWidgets('le tuteur choisit d abord le membre du foyer', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _monter(
        tester,
        marche: FauxPortMarketplace(
          disponiblesParMembre: _disponibles(<String?, List<ClasseVM>>{
            'e1': <ClasseVM>[classeDeTest(id: 'c1', libelle: 'Pour Amina')],
            'e2': <ClasseVM>[classeDeTest(id: 'c2', libelle: 'Pour Ibrahim')],
          }),
        ),
      );

      expect(find.text(t.classes.foyer.pourQui), findsOneWidget);
      expect(find.text('Amina'), findsWidgets);
      expect(find.text('Ibrahim'), findsWidgets);
      // Le produit dit « membres du foyer », jamais « enfants ».
      expect(find.text(t.classes.foyer.classesDuFoyer), findsOneWidget);
      expect(
        find.text(t.classes.foyer.disponiblesPour(prenom: 'Amina')),
        findsOneWidget,
      );
      expect(find.text('Pour Amina'), findsOneWidget);
      expect(find.text('Pour Ibrahim'), findsNothing);

      await tester.tap(find.text('Ibrahim').first);
      await tester.pumpAndSettle();
      expect(
        find.text(t.classes.foyer.disponiblesPour(prenom: 'Ibrahim')),
        findsOneWidget,
      );
      expect(find.text('Pour Ibrahim'), findsOneWidget);
    });
  });

  testWidgets('un seul membre : le choix est fait, le selecteur s absente', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _monter(
        tester,
        membres: <EleveDuFoyer>[
          _membre(id: 'a1', prenom: 'Karim', mode: InterfaceMode.standard),
        ],
      );
      expect(find.text(t.classes.foyer.pourQui), findsNothing);
      expect(
        find.text(t.classes.foyer.disponiblesPour(prenom: 'Karim')),
        findsOneWidget,
      );
    });
  });

  testWidgets('inscrire passe par le port, avec le membre choisi', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      final FauxPortMarketplace marche = await _monter(
        tester,
        marche: FauxPortMarketplace(
          disponiblesParMembre: _disponibles(<String?, List<ClasseVM>>{
            'e1': <ClasseVM>[classeDeTest(id: 'c1')],
          }),
        ),
      );

      final Finder bouton = find.widgetWithText(
        ActionPrincipale,
        t.classes.foyer.inscrire(prenom: 'Amina'),
      );
      await tester.ensureVisible(bouton);
      await tester.pumpAndSettle();
      await tester.tap(bouton);
      await tester.pumpAndSettle();

      expect(marche.inscriptions, <({String classeId, String membreId})>[
        (classeId: 'c1', membreId: 'e1'),
      ]);
      expect(
        find.text(t.classes.foyer.inscriptionFaite(prenom: 'Amina')),
        findsOneWidget,
      );
      // La carte le dit, et son bouton disparait : un second envoi serait
      // refuse.
      expect(find.text(t.classes.carte.inscrit), findsOneWidget);
      expect(bouton, findsNothing);
    });
  });

  testWidgets('une classe complete n a pas de bouton, seulement son mot', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _monter(
        tester,
        marche: FauxPortMarketplace(
          disponiblesParMembre: _disponibles(<String?, List<ClasseVM>>{
            'e1': <ClasseVM>[classeDeTest(id: 'c1', inscrits: 5)],
          }),
        ),
      );
      expect(find.text(t.classes.carte.complet), findsOneWidget);
      expect(
        find.widgetWithText(
          ActionPrincipale,
          t.classes.foyer.inscrire(prenom: 'Amina'),
        ),
        findsNothing,
      );
    });
  });

  testWidgets('aucune classe ne convient : proposer un creneau, une case', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      final FauxPortMarketplace marche = await _monter(tester);

      expect(find.text(t.classes.foyer.aucuneDisponible), findsOneWidget);
      final Finder proposer = find.text(t.classes.foyer.proposerCreneau);
      await tester.ensureVisible(proposer);
      await tester.pumpAndSettle();
      await tester.tap(proposer);
      await tester.pumpAndSettle();

      expect(
        find.text(t.classes.foyer.proposerCreneauTitre(prenom: 'Amina')),
        findsOneWidget,
      );
      expect(find.byType(GrilleSemaine), findsOneWidget);
      // Rien ne part sans case choisie.
      final ActionPrincipale envoi = tester.widget<ActionPrincipale>(
        find.widgetWithText(ActionPrincipale, t.classes.foyer.proposerEnvoyer),
      );
      expect(envoi.onPress, isNull);

      final Finder jeudi18 = _caseLibre(4, 18);
      await tester.ensureVisible(jeudi18);
      await tester.pumpAndSettle();
      await tester.tap(jeudi18);
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ActionPrincipale, t.classes.foyer.proposerEnvoyer),
      );
      await tester.pumpAndSettle();

      expect(marche.propositions, hasLength(1));
      expect(marche.propositions.single.membreId, 'e1');
      expect(marche.propositions.single.creneau.jourIso, 4);
      expect(marche.propositions.single.creneau.heure, 18);
      expect(find.text(t.classes.foyer.propositionEnvoyee), findsOneWidget);
    });
  });

  testWidgets('une capacite serveur absente se dit, et le creneau reste', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _monter(
        tester,
        marche: FauxPortMarketplace()
          ..erreurDisponibles = const EchecDomaine(MotifEchec.capaciteAbsente),
      );
      expect(find.text(t.classes.commun.capaciteAbsente), findsOneWidget);
      expect(find.text(t.classes.foyer.proposerCreneau), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Le planning montre l etat de presence du serveur', () {
    testWidgets('un etat rendu se lit, mot pour mot', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        final DateTime demain = _maintenant.add(const Duration(days: 1));
        await _monter(
          tester,
          seances: <Seance>[_seance(id: 's1', eleveId: 'e1', debut: demain)],
          presences: const <PresenceParticipant>[
            PresenceParticipant(
              seanceId: 's1',
              profilId: 'e1',
              role: 'student',
              prenom: 'Amina',
              identifiantImmuable: 'STUD-e1',
              etat: EtatPresence.planifiee,
              consolide: false,
            ),
          ],
        );

        expect(
          find.text(t.classes.foyer.planning(prenom: 'Amina')),
          findsOneWidget,
        );
        expect(find.text(t.presence.planifiee), findsOneWidget);
        expect(find.text(t.classes.presence.source), findsOneWidget);
      });
    });

    testWidgets('sans reponse du serveur : inconnu, jamais absence', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        final DateTime demain = _maintenant.add(const Duration(days: 1));
        await _monter(
          tester,
          seances: <Seance>[_seance(id: 's1', eleveId: 'e1', debut: demain)],
          presences: null,
        );
        expect(find.text(t.presence.inconnu), findsOneWidget);
        expect(find.text(t.presence.absente), findsNothing);
      });
    });

    testWidgets('une seance passee ne figure plus au planning', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _monter(
          tester,
          seances: <Seance>[
            _seance(
              id: 's0',
              eleveId: 'e1',
              debut: _maintenant.subtract(const Duration(days: 2)),
            ),
          ],
        );
        expect(
          find.text(t.classes.foyer.planningVide(prenom: 'Amina')),
          findsOneWidget,
        );
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
          marche: FauxPortMarketplace(
            miennes: <ClasseVM>[classeDeTest(id: 'm', libelle: 'Mienne')],
            disponiblesParMembre: _disponibles(<String?, List<ClasseVM>>{
              'e1': <ClasseVM>[
                classeDeTest(id: 'a', libelle: 'A'),
                classeDeTest(id: 'b', libelle: 'B'),
              ],
            }),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$largeur');
        expect(find.byType(CarteClasse), findsNWidgets(3), reason: '$largeur');
      });
    }
  });

  group('Le rappel de la piece d identite : propose, jamais impose', () {
    testWidgets('KYC facultatif et pas commence : le rappel, avec le depot', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await tester.pumpWidget(
          hoteRoutant(
            depart: CheminsCore24.tuteurClasses,
            routes: <RouteBase>[
              GoRoute(
                path: CheminsCore24.tuteurClasses,
                builder: (BuildContext _, GoRouterState _) =>
                    ClassesFoyerPage(horloge: () => _maintenant),
              ),
              GoRoute(
                path: Routes.attentePiece,
                builder: (BuildContext _, GoRouterState _) =>
                    const Text('piece'),
              ),
            ],
            surcharges: <Override>[
              serviceAppairageProvider.overrideWithValue(
                FauxServiceAppairage()
                  ..elevesRendus = <EleveDuFoyer>[
                    _membre(id: 'e1', prenom: 'Amina'),
                  ],
              ),
              portMarketplaceProvider.overrideWithValue(FauxPortMarketplace()),
              portConformiteProvider.overrideWithValue(
                FauxPortConformite(
                  mienne: const ConformiteCompte(
                    exigence: ExigenceKyc.optionnelle,
                    etat: EtatKyc.nonCommence,
                    contratAccepte: true,
                  ),
                ),
              ),
              servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
              serviceSuiviProvider.overrideWithValue(FauxServiceSuivi()),
              serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(t.classes.kyc.rappelTitre), findsOneWidget);
        // Aucun vocabulaire menacant, et la page reste entierement utilisable.
        expect(find.text(t.classes.foyer.classesDuFoyer), findsOneWidget);
        await tester.tap(find.text(t.classes.kyc.rappelAction));
        await tester.pumpAndSettle();
        expect(find.text('piece'), findsOneWidget);
      });
    });

    testWidgets('sans lecture de conformite, aucun rappel : l ecran est le meme', (
      WidgetTester tester,
    ) async {
      await avecLargeur(tester, largeurMobile, () async {
        await _monter(tester);
        expect(find.text(t.classes.kyc.rappelTitre), findsNothing);
      });
    });
  });

  testWidgets('un foyer sans membre invite a en ajouter un', (
    WidgetTester tester,
  ) async {
    await avecLargeur(tester, largeurMobile, () async {
      await _monter(tester, membres: const <EleveDuFoyer>[]);
      expect(find.text(t.classes.foyer.aucunMembre), findsOneWidget);
      await tester.tap(find.text(t.classes.foyer.ajouterMembre));
      await tester.pumpAndSettle();
      expect(find.text('ajout'), findsOneWidget);
    });
  });
}
