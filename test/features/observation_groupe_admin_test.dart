import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_configuration.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart' show Creneau;
import 'package:rewayah_academy/core/tc_observation/echec_observation.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_observation_policy.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_groupes/feuille_observation_groupe.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';

import '../support/harnais.dart';
import '../teaching_core/g/faux/faux_observation.dart';

const String _groupeId = 'g1';

/// Les quatre defauts d'Academie tels que la migration `0036` les pose.
///
/// Volontairement DIFFERENTS de ce que porte le groupe sous test : c'est la
/// seule facon de voir si l'ecran affiche bien ce dont on herite plutot que de
/// renvoyer au groupe ses propres valeurs.
const List<ValeurConfig> _defautsAcademie = <ValeurConfig>[
  ValeurConfig(cle: 'observation.policy_version', valeur: 'a2'),
  ValeurConfig(cle: 'observation.max_visits_per_session', valeur: 2),
  ValeurConfig(cle: 'observation.max_total_seconds', valeur: 240),
  ValeurConfig(cle: 'observation.max_seconds_per_visit', valeur: 120),
];

/// La politique que le serveur rend pour un groupe personnalise.
const GuardianObservationPolicy _politiqueGroupe = GuardianObservationPolicy(
  policyVersion: 'groupe:4',
  source: SourcePolitique.groupe,
  observationActivee: true,
  maxVisitsPerSession: 3,
  maxTotalObservationTime: Duration(seconds: 300),
  maxParVisite: Duration(seconds: 90),
);

GroupeAdmin _groupe() => const GroupeAdmin(
  id: _groupeId,
  libelle: 'Perles du Coran',
  type: TypePublicGroupe.enfant,
  seuilMax: 5,
  teacherId: 't1',
  teacherIdentifiant: 'ENS-001',
  teacherPrenom: 'Amina',
  teacherNom: 'Diallo',
  creneau: Creneau(jour: 2, heure: 17, fuseau: 'Europe/Paris'),
  nombreMembres: 4,
  actif: true,
);

/// Une configuration en memoire.
class _FauxConfiguration implements ServiceConfiguration {
  @override
  Future<List<ValeurConfig>> lire(List<String> cles) async => _defautsAcademie;

  @override
  Future<void> ecrire(String cle, Object valeur) async {}
}

/// Un service de groupes qui ne rend qu'une ligne.
class _FauxGroupes implements ServiceGroupes {
  @override
  Future<List<GroupeAdmin>> groupes() async => <GroupeAdmin>[_groupe()];

  @override
  Future<List<MembreGroupe>> membres(String groupeId) async =>
      const <MembreGroupe>[];

  @override
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required String libelle,
    required Creneau creneau,
    int? seuilMax,
  }) async => _groupeId;

  @override
  Future<void> modifier({
    required String groupeId,
    required String libelle,
    required int seuilMax,
    required Creneau creneau,
  }) async {}

  @override
  Future<void> ajouterEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  }) async {}

  @override
  Future<void> retirerEleve({
    required String groupeId,
    required String studentId,
    required String motif,
  }) async {}

  @override
  Future<void> cloturer({
    required String groupeId,
    required String motif,
  }) async {}
}

List<Override> _surcharges(FauxPortPolitique port) => <Override>[
  serviceGroupesProvider.overrideWithValue(_FauxGroupes()),
  serviceConfigurationProvider.overrideWithValue(_FauxConfiguration()),
  portPolitiqueObservationProvider.overrideWithValue(port),
];

/// Amene la cible dans le cadre avant de la presser.
Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

/// Ouvre la feuille de reglage depuis la ligne du groupe.
Future<void> _ouvrirDepuisLaListe(
  WidgetTester tester,
  FauxPortPolitique port,
) async {
  // Le cadre est large a dessein : la colonne d'actions de `DataCollection`
  // n'existe qu'a partir du rendu tabulaire.
  tester.view.physicalSize = const Size(1400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    hote(const GroupesPage(), surcharges: _surcharges(port)),
  );
  await tester.pumpAndSettle();
  await _presser(tester, find.byType(MenuActions).first);
  await _presser(tester, find.text(t.admin.groupes.actionObservation).last);
}

void main() {
  group('Le reglage d\'observation a une route reelle, et elle est par groupe', () {
    testWidgets('la ligne du groupe porte l\'action, et elle ouvre le module', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique port = FauxPortPolitique(
        politique: _politiqueGroupe,
      );

      await _ouvrirDepuisLaListe(tester, port);

      expect(find.text(t.tc.observation.reglages.titre), findsOneWidget);
      expect(find.text(t.tc.observation.reglages.heriter), findsOneWidget);
      expect(find.text(t.tc.observation.reglages.personnaliser), findsOneWidget);
      expect(find.text(t.tc.observation.reglages.desactiver), findsOneWidget);
    });

    testWidgets('l\'heritage affiche montre l\'Academie, pas le groupe', (
      WidgetTester tester,
    ) async {
      // Le groupe porte 3 visites, l'Academie 2 : un ecran qui renverrait au
      // groupe ses propres valeurs ecrirait « Academie : 3 visites ».
      final FauxPortPolitique port = FauxPortPolitique(
        politique: _politiqueGroupe,
      );

      await _ouvrirDepuisLaListe(tester, port);

      expect(
        find.text(
          t.tc.observation.reglages.valeurHeritee(
            valeur: t.tc.observation.reglages.uniteVisites(n: 2),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          t.tc.observation.reglages.valeurHeritee(
            valeur: t.tc.observation.reglages.uniteSecondes(n: 240),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('enregistrer porte les cinq valeurs jusqu\'au serveur', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique port = FauxPortPolitique(
        politique: _politiqueGroupe,
      );

      await _ouvrirDepuisLaListe(tester, port);
      await _presser(tester, find.text(t.tc.observation.reglages.enregistrer));

      expect(port.ecrites, hasLength(1));
      expect(port.ecrites.single.groupeId, _groupeId);
      final GuardianObservationPolicy envoyee = port.ecrites.single.politique;
      expect(envoyee.source, SourcePolitique.groupe);
      expect(envoyee.maxVisitsPerSession, 3);
      expect(envoyee.maxTotalObservationTime, const Duration(seconds: 300));
      // Le cinquieme parametre part rempli : jamais nul sur un groupe
      // personnalise, sinon la premiere visite consomme tout le budget.
      expect(envoyee.maxParVisite, const Duration(seconds: 90));
    });

    testWidgets('le plafond par visite se regle, et se borne au total', (
      WidgetTester tester,
    ) async {
      final FauxPortPolitique port = FauxPortPolitique(
        politique: _politiqueGroupe,
      );

      await _ouvrirDepuisLaListe(tester, port);
      expect(find.text(t.tc.observation.reglages.plafondVisite), findsOneWidget);

      // Le troisieme « Augmenter » est celui du plafond par visite.
      await _presser(tester, find.text(t.tc.observation.reglages.augmenter).at(2));
      await _presser(tester, find.text(t.tc.observation.reglages.enregistrer));

      expect(
        port.ecrites.single.politique.maxParVisite,
        const Duration(seconds: 120),
      );
    });

    testWidgets('tant que la migration 0036 attend, l\'ecran le dit', (
      WidgetTester tester,
    ) async {
      // PostgREST resout une RPC par le nom de ses arguments : un appel a cinq
      // arguments contre la fonction a quatre revient en `PGRST202`, traduit en
      // `capaciteAbsente`. L'ecran ne doit pas faire croire a un
      // enregistrement.
      final FauxPortPolitique port = FauxPortPolitique(
        politique: _politiqueGroupe,
      )..echecEcriture = const EchecObservation(
        MotifEchecObservation.capaciteAbsente,
      );

      await _ouvrirDepuisLaListe(tester, port);
      await _presser(tester, find.text(t.tc.observation.reglages.enregistrer));

      expect(find.text(t.tc.observation.refus.capaciteAbsente), findsOneWidget);
    });
  });

  group('Le module se rend en arabe et a 200 pour cent', () {
    // **Pas une entree de plus dans `rtl_echelle_texte_ecrans_test.dart`** :
    // ce lot n'ajoute aucun ecran au catalogue, seulement une feuille sur
    // `ADM` > Operations > Groupes. Le compte gele de vingt-quatre ecrans de ce
    // fichier dirait le contraire. La preuve de rendu, elle, reste due : la
    // voici, sur la surface reellement ajoutee.
    for (final ({String nom, TextDirection direction, double echelle}) axe
        in <({String nom, TextDirection direction, double echelle})>[
          (nom: 'arabe', direction: TextDirection.rtl, echelle: 1),
          (nom: '200 pour cent', direction: TextDirection.ltr, echelle: 2),
        ]) {
      testWidgets('la feuille tient en ${axe.nom}', (WidgetTester tester) async {
        final FauxPortPolitique port = FauxPortPolitique(
          politique: _politiqueGroupe,
        );

        await tester.pumpWidget(
          hote(
            MediaQuery(
              data: MediaQueryData(
                size: const Size(390, 8000),
                textScaler: TextScaler.linear(axe.echelle),
                disableAnimations: true,
              ),
              child: Directionality(
                textDirection: axe.direction,
                child: SingleChildScrollView(
                  child: FeuilleObservationGroupe(
                    groupeId: _groupeId,
                    onEnregistre: () {},
                  ),
                ),
              ),
            ),
            surcharges: _surcharges(port),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(t.tc.observation.reglages.titre), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Les defauts d\'Academie se lisent a la source du serveur', () {
    test('les quatre cles d\'app_config donnent la politique d\'Academie', () {
      final GuardianObservationPolicy academie = politiqueAcademieDepuis(
        _defautsAcademie,
      );

      expect(academie.policyVersion, 'a2');
      expect(academie.source, SourcePolitique.academie);
      expect(academie.maxVisitsPerSession, 2);
      expect(academie.maxTotalObservationTime, const Duration(seconds: 240));
      expect(academie.maxParVisite, const Duration(seconds: 120));
    });

    test('une cle jamais seedee rend le repli du serveur, pas un zero', () {
      // Les memes replis que `politique_observation_effective` cle par cle
      // (`0033_tc_vues_rpc.sql`) : 1 visite, 120 secondes, aucun plafond par
      // visite, version « a1 ».
      final GuardianObservationPolicy academie = politiqueAcademieDepuis(
        const <ValeurConfig>[
          ValeurConfig(cle: 'observation.policy_version', valeur: null),
          ValeurConfig(cle: 'observation.max_visits_per_session', valeur: null),
          ValeurConfig(cle: 'observation.max_total_seconds', valeur: null),
          ValeurConfig(cle: 'observation.max_seconds_per_visit', valeur: null),
        ],
      );

      expect(academie.policyVersion, 'a1');
      expect(academie.maxVisitsPerSession, 1);
      expect(academie.maxTotalObservationTime, const Duration(seconds: 120));
      expect(academie.maxParVisite, isNull);
    });
  });
}
