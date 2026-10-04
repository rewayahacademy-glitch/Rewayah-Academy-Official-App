// CPT-BEN-1 (FIN-L4a) : les beneficiaires vus par le Comptable, W07 liste et
// profil de paiement. R-FIN-11 (aucun « Modifier les coordonnees »), R-FIN-19
// cote personnel (infos manquantes filtrees, relance), R-FIN-21 (la relance
// passe par le port de relance, aucune messagerie Finance) ; cinq etats ;
// un seul bouton plein ; aucune carte collee ; 320 a texte x2 sans mot
// coupe, 1440 sombre, RTL.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_beneficiaires_paiement.dart';
import 'package:rewayah_academy/core/capacites/port_relance_paiement.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/montant_sensible.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/beneficiaires_page.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/etat_beneficiaires.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/feuille_suspension.dart';
import 'package:rewayah_academy/features/comptable/beneficiaires/profil_paiement_page.dart';
import 'package:rewayah_academy/features/demo/comptable/beneficiaires_demo.dart';
import 'package:rewayah_academy/features/demo/comptable/socle_comptable_demo.dart';

import '../../../capture/outil_capture.dart';
import '../../../router/support_routeur.dart' show sessionActive;
import '../../../support/garde_interface.dart';
import '../../../support/harnais.dart';
import '../../../support/mots_coupes.dart';

/// Une relance qui compte ses appels (R-FIN-21) et peut rendre une route.
class _RelanceEspion implements PortRelancePaiement {
  _RelanceEspion({this.route});

  final String? route;
  final List<String> appels = <String>[];

  @override
  Future<RelancePreparee> relancer(String beneficiaireId) async {
    appels.add(beneficiaireId);
    return RelancePreparee(
      filId: 'fil-$beneficiaireId',
      beneficiaireId: beneficiaireId,
      messageModele: t.comptable.beneficiaires.profil.messageModele,
      route: route,
    );
  }
}

/// Une source qui echoue (reseau) ou qui ne repond jamais.
class _SourceEnEchec extends BeneficiairesPaiementDemo {
  const _SourceEnEchec({this.jamais = false, this.vide = false});

  final bool jamais;
  final bool vide;

  @override
  Future<List<ProfilPaiementBeneficiaire>> liste(FiltreBeneficiaires f) {
    if (vide) return Future<List<ProfilPaiementBeneficiaire>>.value(const []);
    if (jamais) return Completer<List<ProfilPaiementBeneficiaire>>().future;
    return Future<List<ProfilPaiementBeneficiaire>>.error(StateError('reseau'));
  }

  @override
  Future<ProfilPaiementBeneficiaire> profil(String id) =>
      Future<ProfilPaiementBeneficiaire>.error(StateError('reseau'));

  @override
  Future<ProfilPaiementBeneficiaire> demanderMiseAJour(String id) =>
      Future<ProfilPaiementBeneficiaire>.error(
        const CapaciteIndisponible('CPT-BR-06'),
      );
}

/// Les actions de la demo, sauf « Demander une mise a jour », indisponible.
class _MiseAJourIndisponible extends BeneficiairesPaiementDemo {
  const _MiseAJourIndisponible();

  @override
  Future<ProfilPaiementBeneficiaire> demanderMiseAJour(String id) =>
      Future<ProfilPaiementBeneficiaire>.error(
        const CapaciteIndisponible('CPT-BR-06'),
      );
}

List<Override> _surcharges({
  PortBeneficiairesPaiement? port,
  PortRelancePaiement? relance,
  bool horsLigne = false,
}) => <Override>[
  sourceSessionProvider.overrideWithValue(
    FausseSourceSession(sessionActive(AppRole.accountant)),
  ),
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(horsLigne)),
  // Une seule surcharge par port : la demo, sauf si le test la remplace.
  portBeneficiairesPaiementProvider.overrideWithValue(
    port ?? const BeneficiairesPaiementDemo(),
  ),
  portRelancePaiementProvider.overrideWithValue(
    relance ?? const RelancePaiementDemo(),
  ),
];

Future<void> _monter(
  WidgetTester tester,
  Widget page, {
  List<Override>? surcharges,
  Size taille = const Size(390, 1800),
  double texte = 1,
  ThemeMode theme = ThemeMode.light,
  TextDirection sens = TextDirection.ltr,
}) async {
  fixerVueCapture(tester, taille, 1);
  // Un nouveau conteneur a chaque montage : un ProviderScope garde sinon
  // les surcharges du montage precedent (hors ligne, source).
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    hoteCapture(
      Directionality(textDirection: sens, child: page),
      surcharges: surcharges ?? _surcharges(),
      echelleTexte: texte,
      themeMode: theme,
    ),
  );
  await stabiliser(tester);
}

const String _ens01 = ProfilsBeneficiairesDemo.modifieRecemment;

void main() {
  group('W07 liste des beneficiaires', () {
    testWidgets('les 20 beneficiaires, destinations masquees par la source', (
      WidgetTester tester,
    ) async {
      // Tableau large et haut : la collection construit les 20 lignes.
      await _monter(
        tester,
        const BeneficiairesPage(),
        taille: const Size(1440, 2400),
      );
      expect(find.byKey(BeneficiairesPage.collectionKey), findsOneWidget);
      for (final IdentiteBeneficiaire p in <IdentiteBeneficiaire>[
        ...SocleComptableDemo.enseignants,
        ...SocleComptableDemo.contractuels,
      ]) {
        expect(
          find.byKey(ValueKey<String>('cpt-ben-ligne-${p.id}')),
          findsOneWidget,
          reason: p.nom,
        );
      }
      // « Mobile money · Operateur A •••• 4423 » : seul le suffixe rendu
      // par la source est visible.
      expect(
        find.text(texteDestination(SocleComptableDemo.destinationMobile)),
        findsOneWidget,
      );
      expect(find.text(t.comptable.commun.destinationAucune), findsWidgets);
    });

    testWidgets('R-FIN-11 : aucun « Modifier » sur la liste', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const BeneficiairesPage());
      expect(find.textContaining('Modifier'), findsNothing);
      expect(find.textContaining('modifier'), findsNothing);
    });

    testWidgets('?filtre=infos (Aujourd hui) : les 2 infos manquantes', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const BeneficiairesPage(filtre: 'infos'),
        taille: const Size(1440, 2400),
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'cpt-ben-ligne-${ProfilsBeneficiairesDemo.sansMethode}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'cpt-ben-ligne-${ProfilsBeneficiairesDemo.incomplet}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('cpt-ben-ligne-'),
        ),
        findsNWidgets(2),
      );
      // Toucher « Tous » rend la liste entiere.
      await tester.tap(
        find.byKey(const ValueKey<String>('cpt-ben-filtre-tous')),
      );
      await stabiliser(tester);
      expect(
        find.byKey(const ValueKey<String>('cpt-ben-ligne-ens-15')),
        findsOneWidget,
      );
    });

    testWidgets('filtre « Invitations envoyees » : l externe sans compte', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const BeneficiairesPage(filtre: 'invitations'),
        taille: const Size(1440, 2400),
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'cpt-ben-ligne-${ProfilsBeneficiairesDemo.externe}',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          libelleProfilPaiementTexte(EtatProfilPaiement.invitationEnvoyee),
        ),
        findsWidgets,
      );
    });

    testWidgets('toucher une ligne ouvre son profil (route W07)', (
      WidgetTester tester,
    ) async {
      fixerVueCapture(tester, const Size(390, 1800), 1);
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.comptableBeneficiaires,
          surcharges: _surcharges(),
          routes: <RouteBase>[
            GoRoute(
              path: Routes.comptableBeneficiaires,
              builder: (BuildContext _, GoRouterState _) =>
                  const BeneficiairesPage(),
              routes: <RouteBase>[
                GoRoute(
                  path: ':id',
                  builder: (BuildContext _, GoRouterState etat) =>
                      ProfilPaiementPage(
                        beneficiaireId: etat.pathParameters['id']!,
                      ),
                ),
              ],
            ),
          ],
        ),
      );
      await stabiliser(tester);
      await tester.tap(find.text(SocleComptableDemo.enseignants.first.nom));
      await stabiliser(tester);
      expect(find.byType(ProfilPaiementPage), findsOneWidget);
      expect(
        tester
            .widget<ProfilPaiementPage>(find.byType(ProfilPaiementPage))
            .beneficiaireId,
        _ens01,
      );
    });

    testWidgets('production (source absente) : en preparation, aucun chiffre', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const BeneficiairesPage(),
        surcharges: _surcharges(
          port: const BeneficiairesPaiementIndisponibles(),
        ),
      );
      expect(find.text(t.comptable.commun.enPreparationTitre), findsOneWidget);
      expect(find.byKey(BeneficiairesPage.collectionKey), findsNothing);
    });

    testWidgets('chargement : squelette', (WidgetTester tester) async {
      await _monter(
        tester,
        const BeneficiairesPage(),
        surcharges: _surcharges(port: const _SourceEnEchec(jamais: true)),
      );
      expect(find.byType(Skeleton), findsOneWidget);
    });

    testWidgets('vide : aucun beneficiaire', (WidgetTester tester) async {
      await _monter(
        tester,
        const BeneficiairesPage(),
        surcharges: _surcharges(port: const _SourceEnEchec(vide: true)),
      );
      expect(find.text(t.comptable.beneficiaires.vide), findsOneWidget);
    });

    testWidgets('erreur : echec avec « Reessayer »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const BeneficiairesPage(),
        surcharges: _surcharges(port: const _SourceEnEchec()),
      );
      final EtatSysteme etat = tester.widget<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(etat.nature, NatureEtat.echecServeur);
    });

    testWidgets('hors ligne : l echec se dit hors ligne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const BeneficiairesPage(),
        surcharges: _surcharges(port: const _SourceEnEchec(), horsLigne: true),
      );
      final EtatSysteme etat = tester.widget<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(etat.nature, NatureEtat.horsLigne);
    });
  });

  group('W07 profil de paiement', () {
    testWidgets('carte : methode masquee, historique masque, aucun Modifier', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const ProfilPaiementPage(beneficiaireId: _ens01));
      expect(find.text(SocleComptableDemo.enseignants.first.nom), findsWidgets);
      expect(
        find.text(t.comptable.beneficiaires.profil.derniereModification),
        findsOneWidget,
      );
      expect(find.text('4 octobre 2026'), findsNothing);
      expect(find.text('1 octobre 2026'), findsOneWidget);
      // Historique : trois paiements, montants masques par defaut.
      expect(find.byType(MontantSensible), findsNWidgets(3));
      expect(find.textContaining('205'), findsNothing);
      // R-FIN-11.
      expect(find.textContaining('Modifier'), findsNothing);
      expect(
        find.text(
          t.comptable.beneficiaires.profil.proprietaire(
            nom: SocleComptableDemo.enseignants.first.nom,
          ),
        ),
        findsOneWidget,
      );
      // Journal du profil (§48).
      expect(
        find.text(t.comptable.beneficiaires.profil.journalTitre),
        findsOneWidget,
      );
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('R-FIN-21 : Relancer passe par le port de relance, fil '
        '« Profil de paiement », message modele §27.3, jamais « envoye »', (
      WidgetTester tester,
    ) async {
      final _RelanceEspion espion = _RelanceEspion();
      await _monter(
        tester,
        const ProfilPaiementPage(beneficiaireId: _ens01),
        surcharges: _surcharges(relance: espion),
      );
      await tester.ensureVisible(find.byKey(ProfilPaiementPage.relancerKey));
      await tester.tap(find.byKey(ProfilPaiementPage.relancerKey));
      await stabiliser(tester);
      expect(espion.appels, <String>[_ens01]);
      expect(find.byKey(ProfilPaiementPage.relanceKey), findsOneWidget);
      expect(
        find.text(t.comptable.beneficiaires.profil.messageModele),
        findsOneWidget,
      );
      expect(
        find.text(t.comptable.beneficiaires.profil.relanceObjet),
        findsOneWidget,
      );
      expect(find.textContaining('envoy'), findsNothing);
      // Aucune route de fil rendue : pas de « Voir le fil ».
      expect(find.byKey(ProfilPaiementPage.voirFilKey), findsNothing);
    });

    testWidgets('« Voir le fil » quand la source rend la route du fil', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const ProfilPaiementPage(beneficiaireId: _ens01),
        surcharges: _surcharges(relance: _RelanceEspion(route: '/fil/x')),
      );
      await tester.ensureVisible(find.byKey(ProfilPaiementPage.relancerKey));
      await tester.tap(find.byKey(ProfilPaiementPage.relancerKey));
      await stabiliser(tester);
      expect(find.byKey(ProfilPaiementPage.voirFilKey), findsOneWidget);
    });

    testWidgets('Demander une mise a jour : le profil passe a « Action '
        'requise », retour en mots', (WidgetTester tester) async {
      await _monter(tester, const ProfilPaiementPage(beneficiaireId: _ens01));
      await tester.ensureVisible(find.byKey(ProfilPaiementPage.miseAJourKey));
      await tester.tap(find.byKey(ProfilPaiementPage.miseAJourKey));
      await stabiliser(tester);
      expect(
        find.text(
          t.comptable.beneficiaires.profil.miseAJourDemandee(
            nom: SocleComptableDemo.enseignants.first.nom,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(t.comptable.statuts.profil.actionRequise),
        findsOneWidget,
      );
      // La demande faite, le lien ne revient pas.
      expect(find.byKey(ProfilPaiementPage.miseAJourKey), findsNothing);
    });

    testWidgets('Suspendre : motif requis, choisi, puis « Reprendre »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, const ProfilPaiementPage(beneficiaireId: _ens01));
      await tester.ensureVisible(find.byKey(ProfilPaiementPage.suspendreKey));
      await tester.tap(find.byKey(ProfilPaiementPage.suspendreKey));
      await stabiliser(tester);
      expect(find.byType(CorpsSuspension), findsOneWidget);
      // Sans motif : la feuille le dit, rien n'est suspendu.
      await tester.ensureVisible(find.byKey(CorpsSuspension.confirmerKey));
      await tester.tap(find.byKey(CorpsSuspension.confirmerKey));
      await stabiliser(tester);
      expect(
        find.text(t.comptable.beneficiaires.profil.motifRequis),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('cpt-ben-motif-verifier')),
      );
      await stabiliser(tester);
      await tester.ensureVisible(find.byKey(CorpsSuspension.confirmerKey));
      await tester.tap(find.byKey(CorpsSuspension.confirmerKey));
      await stabiliser(tester);
      expect(find.byType(CorpsSuspension), findsNothing);
      expect(find.text(t.comptable.statuts.profil.suspendu), findsOneWidget);
      expect(find.byKey(ProfilPaiementPage.reprendreKey), findsOneWidget);
      expect(find.byKey(ProfilPaiementPage.suspendreKey), findsNothing);
      await tester.ensureVisible(find.byKey(ProfilPaiementPage.reprendreKey));
      await tester.tap(find.byKey(ProfilPaiementPage.reprendreKey));
      await stabiliser(tester);
      expect(find.text(t.comptable.statuts.profil.suspendu), findsNothing);
      expect(find.byKey(ProfilPaiementPage.suspendreKey), findsOneWidget);
    });

    testWidgets('une action indisponible le dit, avec quoi faire', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const ProfilPaiementPage(beneficiaireId: _ens01),
        surcharges: _surcharges(port: const _MiseAJourIndisponible()),
      );
      await tester.ensureVisible(find.byKey(ProfilPaiementPage.miseAJourKey));
      await tester.tap(find.byKey(ProfilPaiementPage.miseAJourKey));
      await stabiliser(tester);
      expect(
        find.text(t.comptable.beneficiaires.profil.erreurIndisponible),
        findsOneWidget,
      );
    });

    testWidgets(
      'externe sans compte : pas de fil, invitation par l obligation',
      (WidgetTester tester) async {
        final _RelanceEspion espion = _RelanceEspion();
        await _monter(
          tester,
          const ProfilPaiementPage(
            beneficiaireId: ProfilsBeneficiairesDemo.externe,
          ),
          surcharges: _surcharges(relance: espion),
        );
        expect(find.byKey(ProfilPaiementPage.relancerKey), findsNothing);
        expect(
          find.text(t.comptable.beneficiaires.profil.voirContractuels),
          findsOneWidget,
        );
        expect(
          find.text(t.comptable.statuts.profil.invitationEnvoyee),
          findsWidgets,
        );
        expect(find.text(t.comptable.commun.destinationAucune), findsOneWidget);
        expect(espion.appels, isEmpty);
      },
    );

    testWidgets('sans methode : « Aucune methode », Relancer seul ouvert', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const ProfilPaiementPage(
          beneficiaireId: ProfilsBeneficiairesDemo.sansMethode,
        ),
      );
      expect(find.text(t.comptable.commun.destinationAucune), findsOneWidget);
      expect(find.byKey(ProfilPaiementPage.relancerKey), findsOneWidget);
      expect(find.byKey(ProfilPaiementPage.miseAJourKey), findsNothing);
      expect(find.byKey(ProfilPaiementPage.suspendreKey), findsNothing);
      expect(
        find.text(t.comptable.beneficiaires.profil.historiqueVide),
        findsOneWidget,
      );
    });

    testWidgets('production : en preparation ; erreur : echec ; hors ligne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const ProfilPaiementPage(beneficiaireId: _ens01),
        surcharges: _surcharges(
          port: const BeneficiairesPaiementIndisponibles(),
        ),
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text(t.comptable.commun.enPreparationTitre), findsOneWidget);

      await _monter(
        tester,
        const ProfilPaiementPage(beneficiaireId: _ens01),
        surcharges: _surcharges(port: const _SourceEnEchec()),
      );
      expect(
        tester.widget<EtatSysteme>(find.byType(EtatSysteme)).nature,
        NatureEtat.echecServeur,
      );

      await _monter(
        tester,
        const ProfilPaiementPage(beneficiaireId: _ens01),
        surcharges: _surcharges(port: const _SourceEnEchec(), horsLigne: true),
      );
      expect(
        tester.widget<EtatSysteme>(find.byType(EtatSysteme)).nature,
        NatureEtat.horsLigne,
      );
    });
  });

  group('Garde d interface W07', () {
    // Les mesures de texte n'ont de sens qu'avec les vraies polices.
    setUpAll(chargerPolicesDuDepot);

    bool estCarte(Widget w) => w is AppCard;

    for (final ThemeMode theme in <ThemeMode>[
      ThemeMode.light,
      ThemeMode.dark,
    ]) {
      testWidgets('320 a texte x2, ${theme.name} : aucun mot coupe, '
          'aucune carte collee, un seul bouton plein', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          const ProfilPaiementPage(beneficiaireId: _ens01),
          taille: const Size(320, 4000),
          texte: 2,
          theme: theme,
        );
        expect(tester.takeException(), isNull);
        expect(motsCoupes(tester, find.byType(ProfilPaiementPage)), isEmpty);
        expect(
          verifierAucuneCarteCollee(tester, estCarte: estCarte),
          greaterThan(1),
        );
        verifierUnSeulBoutonPlein(tester);

        await _monter(
          tester,
          const BeneficiairesPage(),
          taille: const Size(320, 4000),
          texte: 2,
          theme: theme,
        );
        expect(tester.takeException(), isNull);
        expect(motsCoupes(tester, find.byType(BeneficiairesPage)), isEmpty);
      });
    }

    testWidgets('1440 sombre : deux colonnes, tableau, sans debordement', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const ProfilPaiementPage(beneficiaireId: _ens01),
        taille: const Size(1440, 1200),
        theme: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
      verifierUnSeulBoutonPlein(tester);
      await _monter(
        tester,
        const BeneficiairesPage(),
        taille: const Size(1440, 900),
        theme: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('RTL : liste et profil se rendent sans exception', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        const ProfilPaiementPage(beneficiaireId: _ens01),
        sens: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      await _monter(tester, const BeneficiairesPage(), sens: TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Le libelle d'un etat de profil, sans importer la pastille dans le test.
String libelleProfilPaiementTexte(EtatProfilPaiement etat) => switch (etat) {
  EtatProfilPaiement.invitationEnvoyee =>
    t.comptable.statuts.profil.invitationEnvoyee,
  _ => etat.name,
};
