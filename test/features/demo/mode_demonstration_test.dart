import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_catalogue_classes.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
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
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

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

    test('la compilation de test (developpement) sans adresse : fermee', () {
      expect(demoTuteurActiveIci, isFalse);
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
