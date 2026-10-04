import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_catalogue_classes.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politique_revue_kyc.dart';
import 'package:rewayah_academy/core/capacites/port_revue_dossiers.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/suivi/service_suivi.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/core/tc_observation/activation_observation.dart';
import 'package:rewayah_academy/core/tc_observation/guardian_session_visit.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/core/tc_observation/port_politique_observation.dart';
import 'package:rewayah_academy/core/tc_observation/port_visite_observation.dart';
import 'package:rewayah_academy/features/demo/dossiers_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/services_admin_demo.dart';

void main() {
  final Uri avecDemo = Uri.parse('https://apercu.example/?demo=tuteur');
  final Uri sansDemo = Uri.parse('https://apercu.example/');

  group('garde du mode demonstration', () {
    test('impossible en production, meme demandee', () {
      for (final String env in <String>[
        'production',
        'Production',
        ' PRODUCTION ',
        'prod',
      ]) {
        expect(
          demoTuteurActive(adresse: avecDemo, environnement: env),
          isFalse,
          reason: env,
        );
        expect(
          () => surchargesDemoTuteur(environnement: env),
          throwsStateError,
          reason: env,
        );
      }
    });

    test('environnement vide : fermee', () {
      expect(demoTuteurActive(adresse: avecDemo, environnement: ''), isFalse);
    });

    test('apercu et local : ouverte seulement si demandee', () {
      for (final String env in <String>['staging', 'developpement']) {
        expect(demoTuteurActive(adresse: avecDemo, environnement: env), isTrue);
        expect(
          demoTuteurActive(adresse: sansDemo, environnement: env),
          isFalse,
        );
        expect(
          demoTuteurActive(
            adresse: Uri.parse('https://x/?demo=admin'),
            environnement: env,
          ),
          isFalse,
        );
      }
    });

    test('demo=enseignant : ouverte seulement avec un dossier (alias, n1)', () {
      expect(
        demoTuteurActive(
          adresse: Uri.parse('https://x/?demo=enseignant&dossier=refuse'),
          environnement: 'staging',
        ),
        isTrue,
      );
      for (final String adresse in <String>[
        'https://x/?demo=enseignant',
        'https://x/?demo=enseignant&dossier=',
      ]) {
        expect(
          demoTuteurActive(
            adresse: Uri.parse(adresse),
            environnement: 'staging',
          ),
          isFalse,
          reason: adresse,
        );
      }
      expect(
        demoTuteurActive(
          adresse: Uri.parse('https://x/?demo=enseignant&dossier=refuse'),
          environnement: 'production',
        ),
        isFalse,
      );
    });

    test('la compilation de test (developpement) sans adresse : fermee', () {
      expect(demoTuteurActiveIci, isFalse);
    });

    // DEMO-ENV-1 (AD-R m13) : une publication sans ENVIRONNEMENT declare
    // vaudrait « developpement » par defaut ; elle ferme toutes les demos.
    test('publication sans environnement declare : fermee', () {
      for (final String env in <String>['developpement', 'staging']) {
        expect(
          environnementAutoriseDemo(env, declare: false, publication: true),
          isFalse,
          reason: env,
        );
        // Declaree, la publication d'apercu reste ouverte ; en debogage,
        // l'environnement par defaut aussi (postes et tests).
        expect(
          environnementAutoriseDemo(env, declare: true, publication: true),
          isTrue,
          reason: env,
        );
        expect(
          environnementAutoriseDemo(env, declare: false, publication: false),
          isTrue,
          reason: env,
        );
      }
      expect(
        environnementAutoriseDemo(
          'production',
          declare: true,
          publication: true,
        ),
        isFalse,
      );
    });
  });

  group('garde de la demonstration admin', () {
    final Uri avecAdmin = Uri.parse('https://apercu.example/?demo=admin');

    test('fermee en production et sans environnement', () {
      for (final String env in <String>['production', 'prod', '']) {
        expect(
          demoAdminActive(adresse: avecAdmin, environnement: env),
          isFalse,
          reason: env,
        );
      }
      expect(
        () => surchargesDemoAdmin(environnement: 'production'),
        throwsStateError,
      );
    });

    test('ouverte en apercu, seulement sur ?demo=admin', () {
      expect(
        demoAdminActive(adresse: avecAdmin, environnement: 'staging'),
        isTrue,
      );
      expect(
        demoAdminActive(adresse: avecDemo, environnement: 'staging'),
        isFalse,
      );
      expect(
        demoAdminActive(adresse: sansDemo, environnement: 'staging'),
        isFalse,
      );
      expect(demoAdminActiveIci, isFalse);
    });
  });

  group('doubles admin', () {
    late ProviderContainer conteneur;

    setUp(() {
      conteneur = ProviderContainer(
        overrides: surchargesDemoAdmin(environnement: 'staging'),
      );
    });
    tearDown(() => conteneur.dispose());

    test('session admin et doubles de revue', () async {
      final SessionState etat = await conteneur
          .read(sourceSessionProvider)
          .etats()
          .first;
      expect(etat.role, AppRole.admin);
      expect(
        conteneur.read(portRevueDossiersProvider),
        isA<RevueDossiersDemo>(),
      );
      expect(
        conteneur.read(portPolitiqueRevueKycProvider),
        isA<PolitiqueRevueKycDemo>(),
      );
      expect(
        conteneur.read(serviceValidationProvider),
        isA<ServiceValidationDemo>(),
      );
      expect(
        (await conteneur.read(indicateursProvider.future)).dossiersEnAttente,
        // K-47 (HL-A-6) : D03 (famille dispensee, un tuteur) est retire.
        9,
      );
      expect(await conteneur.read(demandesProvider.future), isEmpty);
    });

    test('aucun service admin ne resout un adaptateur Supabase', () async {
      for (final Provider<Object> p in providersServicesAdmin) {
        final Object service = conteneur.read(p);
        expect(
          service.runtimeType.toString(),
          isNot(contains('Supabase')),
          reason: '$p',
        );
      }
      await expectLater(
        conteneur.read(serviceComptesProvider).comptes(),
        throwsA(isA<CapaciteIndisponible>()),
      );
      await expectLater(
        conteneur.read(serviceGroupesProvider).groupes(),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    test('variante profil a completer par adresse', () {
      expect(
        etatRevueDemoPour(
          Uri.parse('https://apercu.example/?demo=admin&profil=a-completer'),
        ).genreRelecteurRenseigne,
        isFalse,
      );
      expect(
        etatRevueDemoPour(Uri.parse('https://apercu.example/?demo=admin'))
            .genreRelecteurRenseigne,
        isTrue,
      );
    });
  });

  group('doubles fictifs', () {
    late ProviderContainer conteneur;

    setUp(() {
      conteneur = ProviderContainer(
        overrides: surchargesDemoTuteur(environnement: 'staging'),
      );
    });
    tearDown(() => conteneur.dispose());

    test('session tuteur fictive, foyer de deux eleves', () async {
      final SessionState etat = await conteneur
          .read(sourceSessionProvider)
          .etats()
          .first;
      expect(etat.role, AppRole.guardian);
      expect(etat.resolue, isTrue);
      final List<EleveDuFoyer> eleves = await conteneur.read(
        elevesDuFoyerProvider.future,
      );
      expect(eleves, hasLength(2));
    });

    test('classes et seances sans serveur', () async {
      final PortClassesFoyer classes = conteneur.read(portClassesFoyerProvider);
      final PortSeancesFamille seances = conteneur.read(
        portSeancesFamilleProvider,
      );
      for (final String id in <String>[
        DonneesDemo.aichaId,
        DonneesDemo.yusufId,
      ]) {
        expect(await classes.classesDe(id), hasLength(1));
        expect(await seances.historique(eleveId: id), hasLength(3));
        expect(await seances.prochaine(id), isNotNull);
      }
    });

    test('catalogue fictif : seances, fuseau et parcours (C-14)', () async {
      final PortCatalogueClasses catalogue = conteneur.read(
        portCatalogueClassesProvider,
      );
      final List<ClasseOuverte> classes = await catalogue.compatibles(
        eleveId: DonneesDemo.aichaId,
        fuseauIana: 'Europe/Paris',
      );
      expect(classes, hasLength(3));
      for (final ClasseOuverte c in classes) {
        expect(c.seances, isNotEmpty);
        expect(c.fuseauIana, 'Europe/Paris');
        expect(c.cours, isNotNull);
      }
      expect(
        (await catalogue.inscrire(
          classeId: classes.first.classeId,
          eleveId: DonneesDemo.aichaId,
          cleIdempotence: 'demo',
        )).statut,
        StatutInscription.enAttenteValidation,
      );
    });

    test('lectures tuteur hors serveur', () async {
      expect(await conteneur.read(appareilsDuFoyerProvider.future), isEmpty);
      expect(await conteneur.read(parcoursFoyerProvider.future), isEmpty);
      expect(await conteneur.read(monFuseauProvider.future), 'Europe/Paris');
      expect(await conteneur.read(seancesDuSuiviProvider.future), isEmpty);
      expect(await conteneur.read(mesGroupesProvider.future), hasLength(2));
    });

    test('observation simulee, salle video jamais ouverte', () async {
      expect(conteneur.read(observationTuteurReelleProvider), isFalse);
      final PortPolitiqueObservation politique = conteneur.read(
        portPolitiqueObservationProvider,
      );
      expect(
        (await politique.politiqueEffective(groupeId: 'x')).observationActivee,
        isTrue,
      );
      expect((await politique.budget(sessionId: 'x')).visitesMax, 2);
      final PortVisiteObservation visite = conteneur.read(
        portVisiteObservationProvider,
      );
      final ResultatEntreeObservation entree = await visite.entrer(
        sessionId: 'x',
        role: RoleObservateur.values.first,
      );
      expect(entree.autorise, isFalse);
      final PortHistoriqueObservations historique = conteneur.read(
        portHistoriqueObservationsProvider,
      );
      expect(await historique.mesObservations(), hasLength(2));
      expect(
        await historique.mesObservations(enfantId: DonneesDemo.aichaId),
        hasLength(1),
      );
    });
  });
}
