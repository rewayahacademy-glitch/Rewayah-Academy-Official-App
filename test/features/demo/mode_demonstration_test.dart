import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/seance_famille/port_seances_famille.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
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
  });
}
