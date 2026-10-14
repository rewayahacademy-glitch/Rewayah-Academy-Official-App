// COUPE-MOTS-4 (1), les autres appelants de `ChoiceCardGroup` : inscription
// (usage, genre), cahier de l'enseignant (performance, faiblesses, point
// phonetique), feuille d'une carte de classe, entree et reglages de
// l'observation, feuille de choix du dock, micro-feedback et signalement.
// 320 px, texte x2, francais (LTR) et arabe (RTL), Interface standard et
// guidee : aucun mot coupe dans les cartes de choix rendues.
//
// La galerie de developpement (`catalogue_galerie.dart`, forcee a `false` en
// production) n'est pas un ecran du produit : elle est couverte par le test
// du composant (`test/core/widgets/choice_card_group_coupe_mots_test.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/tc_groupe/cartes_classe.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_parcours/feedback_memoire.dart';
import 'package:rewayah_academy/core/tc_parcours/port_feedback.dart';
import 'package:rewayah_academy/core/tc_parcours/port_signalement.dart';
import 'package:rewayah_academy/features/demo/cartes_classe_demo.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/inscription/etapes/genre_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/identite_etape.dart';
import 'package:rewayah_academy/features/inscription/etapes/usage_etape.dart';
import 'package:rewayah_academy/features/tc_dock/feuille_choix.dart';
import 'package:rewayah_academy/features/tc_espace_groupe/bloc_cartes_classe.dart';
import 'package:rewayah_academy/features/tc_flux_academique/carte_feedback_seance.dart';
import 'package:rewayah_academy/features/tc_flux_academique/feuille_signalement.dart';
import 'package:rewayah_academy/features/tc_observation_ui/choix_entree_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/module_reglages_observation.dart';
import 'package:rewayah_academy/features/tc_observation_ui/options_entree_observation.dart';

import '../../capture/outil_capture.dart' show stabiliser;
import '../../support/harnais.dart';
import 'support_coupe_mots_4.dart';

/// Un bouton qui ouvre une feuille, pour les feuilles sans ecran propre.
class _Ouvreur extends StatelessWidget {
  const _Ouvreur(this.ouvrir);

  final void Function(BuildContext context) ouvrir;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => ouvrir(context),
        child: const Text('ouvrir'),
      ),
    ),
  );
}

List<Override> _inscription() => <Override>[
  serviceDossierProvider.overrideWithValue(FauxServiceDossier()),
  sourceSessionProvider.overrideWithValue(FausseSourceSession()),
  serviceAuthProvider.overrideWithValue(FauxServiceAuth()),
];

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  preparerCoupeMots4();

  for (final AppLocale langue in languesCoupeMots4) {
    for (final InterfaceMode interface in interfacesCoupeMots4) {
      final String cas = '${langue.name} ${nomInterface(interface)} 320 x2';

      testWidgets('$cas : inscription, usage', (WidgetTester tester) async {
        await monterCoupeMots4(
          tester,
          () => const UsageEtape(),
          langue: langue,
          interface: interface,
          surcharges: _inscription(),
        );
        await tester.pumpAndSettle();
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : inscription, genre', (WidgetTester tester) async {
        await monterCoupeMots4(
          tester,
          () => Router.withConfig(
            config: GoRouter(
              initialLocation: Routes.inscriptionUsage,
              routes: <RouteBase>[
                GoRoute(
                  path: Routes.inscriptionUsage,
                  builder: (BuildContext _, GoRouterState _) =>
                      const UsageEtape(),
                ),
                GoRoute(
                  path: Routes.inscriptionIdentite,
                  builder: (BuildContext _, GoRouterState _) =>
                      const IdentiteEtape(),
                ),
                GoRoute(
                  path: Routes.inscriptionGenre,
                  builder: (BuildContext _, GoRouterState _) =>
                      const GenreEtape(),
                ),
                GoRoute(
                  path: Routes.inscriptionRecapitulatif,
                  builder: (BuildContext _, GoRouterState _) =>
                      const Scaffold(body: Text('recapitulatif')),
                ),
              ],
            ),
          ),
          langue: langue,
          interface: interface,
          surcharges: _inscription(),
        );
        await tester.pumpAndSettle();
        await _toucher(tester, find.text(t.inscription.usage.moiTitre));
        await _toucher(tester, find.text(t.commun.continuer));
        await tester.enterText(
          find.byKey(const Key('inscription-prenom')),
          'Amina',
        );
        await tester.enterText(
          find.byKey(const Key('inscription-nom')),
          'Diallo',
        );
        await _toucher(tester, find.text(t.commun.continuer));
        expect(find.byType(GenreEtape), findsOneWidget);
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : cahier de l enseignant', (WidgetTester tester) async {
        await monterCoupeMots4(
          tester,
          () => const CoquilleEnseignantDemo(
            ecran: EcranDemoEnseignant.cahier,
            etat: EtatDemoEnseignant.nominal,
          ),
          langue: langue,
          interface: interface,
          surcharges: <Override>[
            depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
          ],
        );
        final Finder eleve = find.text('Nour');
        await tester.ensureVisible(eleve);
        await stabiliser(tester);
        await tester.tap(eleve);
        await stabiliser(tester);
        await tester.pump(const Duration(milliseconds: 700));
        await stabiliser(tester);
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : feuille d une carte de classe', (
        WidgetTester tester,
      ) async {
        await monterCoupeMots4(
          tester,
          () => const Scaffold(
            body: SingleChildScrollView(
              child: BlocCartesClasse(groupeId: 'classe-test'),
            ),
          ),
          langue: langue,
          interface: interface,
          surcharges: <Override>[
            serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
            portCartesClasseProvider.overrideWithValue(
              PortCartesClasseDemo(peutModifier: true),
            ),
          ],
        );
        await tester.pumpAndSettle();
        await _toucher(tester, find.byKey(BlocCartesClasse.ajouterKey));
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : entree en observation (admin)', (
        WidgetTester tester,
      ) async {
        await monterCoupeMots4(
          tester,
          () => Scaffold(
            body: SingleChildScrollView(
              child: ChoixEntreeObservation(
                options: OptionsEntreeObservation.depuis(
                  const SessionState(resolue: true, role: AppRole.admin),
                ),
                onMode: (_) {},
                onEntrer: () {},
              ),
            ),
          ),
          langue: langue,
          interface: interface,
        );
        await tester.pumpAndSettle();
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : reglages de l observation', (
        WidgetTester tester,
      ) async {
        const GuardianObservationPolicy academie =
            GuardianObservationPolicy.defautsNormatifs(policyVersion: 'a1');
        await monterCoupeMots4(
          tester,
          () => Scaffold(
            body: SingleChildScrollView(
              child: ModuleReglagesObservation(
                politiqueAcademie: academie,
                politiqueGroupe: academie,
                onEnregistrer: (_) {},
              ),
            ),
          ),
          langue: langue,
          interface: interface,
        );
        await tester.pumpAndSettle();
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : feuille de choix du dock', (
        WidgetTester tester,
      ) async {
        await monterCoupeMots4(
          tester,
          () => _Ouvreur(
            (BuildContext c) => FeuilleChoix.ouvrirIntention(
              c,
              titre: t.tc.outils.marquer.titre,
              aide: t.tc.outils.marquer.aide,
            ),
          ),
          langue: langue,
          interface: interface,
        );
        await _toucher(tester, find.text('ouvrir'));
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : micro-feedback de la seance', (
        WidgetTester tester,
      ) async {
        await monterCoupeMots4(
          tester,
          () => const Scaffold(
            body: SingleChildScrollView(
              child: CarteFeedbackSeance(sessionId: 's1'),
            ),
          ),
          langue: langue,
          interface: interface,
          surcharges: <Override>[
            portFeedbackProvider.overrideWithValue(
              FeedbackMemoire(
                cadence: 1,
                seances: <String, ContexteSeanceFeedback>{
                  's1': const ContexteSeanceFeedback(
                    groupeId: 'g1',
                    rangSeance: 1,
                  ),
                },
              ),
            ),
          ],
        );
        await tester.pumpAndSettle();
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : feuille de signalement', (WidgetTester tester) async {
        await monterCoupeMots4(
          tester,
          () => _Ouvreur(
            (BuildContext c) => FeuilleSignalement.ouvrir(
              c,
              groupeId: 'g1',
              academyId: 'RA-AB0012',
              prenomEleve: 'Amina',
              sessionId: 's1',
            ),
          ),
          langue: langue,
          interface: interface,
          surcharges: <Override>[
            portSignalementProvider.overrideWithValue(
              SignalementMemoire('ens-1'),
            ),
          ],
        );
        await _toucher(tester, find.text('ouvrir'));
        verifierCartesDeChoixEntieres(tester);
      });
    }
  }
}
