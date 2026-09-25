import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_acces_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_catalogue_classes.dart';
import 'package:rewayah_academy/core/capacites/port_classes_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_consentements.dart';
import 'package:rewayah_academy/core/capacites/port_identite_titulaire.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_preferences_persistantes.dart';
import 'package:rewayah_academy/core/capacites/port_profil_eleve_titulaire.dart';
import 'package:rewayah_academy/core/capacites/port_progression_famille.dart';
import 'package:rewayah_academy/core/capacites/port_resume_seance_famille.dart';
import 'package:rewayah_academy/core/capacites/port_support.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';

import '../fixtures/tuteur/faux_capacites.dart';
import '../fixtures/tuteur/faux_classes_foyer.dart';
import '../fixtures/tuteur/faux_identite_titulaire.dart';
import '../fixtures/tuteur/foyers.dart';

/// Les deux familles d'identifiants admises : registre backend, ou lot qui
/// ecrit l'adaptateur.
final RegExp _dependanceValide = RegExp(r'^(DB-[A-Z]{3}-\d{2}|LOT-[A-E])$');

Matcher _indisponible(String dependance) => throwsA(
  isA<CapaciteIndisponible>().having(
    (CapaciteIndisponible c) => c.dependance,
    'dependance',
    dependance,
  ),
);

void main() {
  group('K6 : chaque port de production sans source dit ce qui manque', () {
    late ProviderContainer conteneur;

    setUp(() {
      // Aucune surcharge : ce sont les providers de PRODUCTION qui sont lus.
      conteneur = ProviderContainer();
    });
    tearDown(() => conteneur.dispose());

    final List<(String, Future<Object?> Function(ProviderContainer), String)>
    cas = <(String, Future<Object?> Function(ProviderContainer), String)>[
      // Les classes du foyer ont leur adaptateur reel depuis le 25/09
      // (revue C, M2) : le double indisponible est teste a part ci-dessous.
      (
        'classes du foyer (double indisponible)',
        (ProviderContainer _) =>
            const ClassesFoyerIndisponible().classesDe('e1'),
        'DB-TRV-07',
      ),
      (
        'classe d un eleve (double indisponible)',
        (ProviderContainer _) => const ClassesFoyerIndisponible().classe(
          groupeId: 'g1',
          eleveId: 'e1',
        ),
        'DB-TRV-07',
      ),
      (
        'catalogue',
        (ProviderContainer c) => c
            .read(portCatalogueClassesProvider)
            .compatibles(eleveId: 'e1', fuseauIana: 'Europe/Paris'),
        'DB-CRS-07',
      ),
      (
        'inscription',
        (ProviderContainer c) => c
            .read(portCatalogueClassesProvider)
            .inscrire(classeId: 'c1', eleveId: 'e1', cleIdempotence: 'k1'),
        'DB-CRS-08',
      ),
      (
        'progression',
        (ProviderContainer c) =>
            c.read(portProgressionFamilleProvider).progression('e1'),
        'DB-CRS-11',
      ),
      (
        'resume de seance',
        (ProviderContainer c) => c
            .read(portResumeSeanceFamilleProvider)
            .resume(seanceId: 's1', eleveId: 'e1'),
        'DB-CRS-12',
      ),
      (
        'identite du titulaire',
        (ProviderContainer c) => c.read(portIdentiteTitulaireProvider).lire(),
        'LOT-E',
      ),
      (
        'modification de l identite',
        (ProviderContainer c) =>
            c.read(portIdentiteTitulaireProvider).modifier(prenom: 'x'),
        'DB-CPT-01',
      ),
      (
        'acces du foyer',
        (ProviderContainer c) => c.read(portAccesFoyerProvider).acces(),
        'LOT-E',
      ),
      (
        'paiements',
        (ProviderContainer c) =>
            c.read(portPaiementsFoyerProvider).historique(),
        'DB-CPT-03',
      ),
      (
        'detail de paiement',
        (ProviderContainer c) =>
            c.read(portPaiementsFoyerProvider).detail('p1'),
        'DB-CPT-03',
      ),
      (
        'notifications',
        (ProviderContainer c) => c.read(portNotificationsProvider).liste(),
        'DB-CPT-04',
      ),
      (
        'detail de notification',
        (ProviderContainer c) => c.read(portNotificationsProvider).detail('n1'),
        'DB-CPT-04',
      ),
      (
        'canal d aide',
        (ProviderContainer c) => c.read(portSupportProvider).canal(),
        'DB-CPT-07',
      ),
      (
        'consentements signes',
        (ProviderContainer c) => c.read(portConsentementsProvider).signees(),
        'LOT-A',
      ),
      (
        'consentements a renouveler',
        (ProviderContainer c) =>
            c.read(portConsentementsProvider).aRenouveler(),
        'DB-ADM-03',
      ),
      (
        'acceptation d une version',
        (ProviderContainer c) => c
            .read(portConsentementsProvider)
            .accepter(sorte: SorteContrat.conditionsTuteur, version: 'v'),
        'DB-ADM-02',
      ),
      (
        'profil eleve du titulaire',
        (ProviderContainer c) =>
            c.read(portProfilEleveTitulaireProvider).existe(),
        'DB-FOY-01',
      ),
      (
        'creation du profil eleve du titulaire',
        (ProviderContainer c) =>
            c.read(portProfilEleveTitulaireProvider).creer(),
        'DB-FOY-01',
      ),
      (
        'espace eleve du titulaire',
        (ProviderContainer c) =>
            c.read(portProfilEleveTitulaireProvider).ouvrirEspaceEleve(),
        'DB-FOY-01',
      ),
      (
        'preferences persistantes',
        (ProviderContainer c) =>
            c.read(portPreferencesPersistantesProvider).charger(),
        'DB-CPT-09',
      ),
      (
        'enregistrement des preferences',
        (ProviderContainer c) => c
            .read(portPreferencesPersistantesProvider)
            .enregistrer(const PreferencesLocales()),
        'DB-CPT-09',
      ),
    ];

    for (final (
          String nom,
          Future<Object?> Function(ProviderContainer) appel,
          String dependance,
        )
        in cas) {
      test('$nom : $dependance, jamais un faux succes', () async {
        expect(_dependanceValide.hasMatch(dependance), isTrue);
        await expectLater(appel(conteneur), _indisponible(dependance));
      });
    }
  });

  group('K6 : acces par eleve, calcul d affichage', () {
    final DateTime maintenant = DateTime.utc(2026, 9, 21, 16);

    test('sans echeance, a venir, passee', () {
      expect(
        etatAccesAffiche(finAcces: null, maintenantUtc: maintenant),
        EtatAccesAffiche.sansEcheance,
      );
      expect(
        etatAccesAffiche(
          finAcces: maintenant.add(const Duration(days: 1)),
          maintenantUtc: maintenant,
        ),
        EtatAccesAffiche.actif,
      );
      // Une date passee n'est jamais affichee comme valide (DB-FOY-05).
      expect(
        etatAccesAffiche(
          finAcces: maintenant.subtract(const Duration(days: 1)),
          maintenantUtc: maintenant,
        ),
        EtatAccesAffiche.expire,
      );
      expect(
        etatAccesAffiche(finAcces: maintenant, maintenantUtc: maintenant),
        EtatAccesAffiche.expire,
      );
    });
  });

  group('K6 : une notification ne mene qu a un chemin interne', () {
    test('une destination externe ou interdite est retiree', () {
      NotificationTuteur avec(String? destination) => NotificationTuteur(
        id: 'n1',
        titre: 'Titre',
        date: DateTime.utc(2026, 9, 21),
        destination: destination,
      );

      expect(avec('/tuteur/foyer').destination, '/tuteur/foyer');
      expect(avec('https://exemple.test').destination, isNull);
      expect(avec('/salle').destination, isNull);
      expect(avec(null).destination, isNull);
    });
  });

  group('K6 : les doubles de test rejouent les ports', () {
    test('classes par eleve, sans croisement de foyers', () async {
      final FauxClassesFoyer faux = FauxClassesFoyer(
        classes: <ClasseFoyer>[
          ClasseFoyer(eleveId: FoyersFictifs.a1.id, classe: classeFictive()),
          ClasseFoyer(
            eleveId: FoyersFictifs.b1.id,
            classe: classeFictive(groupeId: 'classe-b', libelle: 'Classe B'),
          ),
        ],
      );

      final List<ClasseFoyer> deA1 = await faux.classesDe(FoyersFictifs.a1.id);
      expect(deA1.single.classe.groupeId, 'classe-a');
      expect(
        await faux.classe(groupeId: 'classe-b', eleveId: FoyersFictifs.a1.id),
        isNull,
      );
    });

    test(
      'identite lisible, modification indisponible comme en production',
      () async {
        final FauxIdentiteTitulaire faux = FauxIdentiteTitulaire();

        expect((await faux.lire()).prenom, titulaireFoyerA.prenom);
        await expectLater(faux.modifier(nom: 'x'), _indisponible('DB-CPT-01'));
      },
    );

    test('une version signee ne se signe qu une fois', () async {
      final FauxConsentements faux = FauxConsentements();

      await faux.accepter(sorte: SorteContrat.conditionsTuteur, version: 'v2');
      await faux.accepter(sorte: SorteContrat.conditionsTuteur, version: 'v2');

      expect(await faux.signees(), hasLength(1));
    });

    test('les autres doubles rendent ce qu on leur donne', () async {
      final FauxCatalogueClasses catalogue = FauxCatalogueClasses();
      await catalogue.inscrire(
        classeId: 'c',
        eleveId: 'e',
        cleIdempotence: 'k',
      );
      final FauxPreferencesPersistantes preferences =
          FauxPreferencesPersistantes();
      await preferences.enregistrer(
        const PreferencesLocales(theme: PreferenceTheme.sombre),
      );
      final FauxProfilEleveTitulaire titulaire = FauxProfilEleveTitulaire();
      await titulaire.creer();

      expect(catalogue.cles, <String>['k']);
      expect((await preferences.charger())?.theme, PreferenceTheme.sombre);
      expect(await titulaire.existe(), isTrue);
      expect(await FauxSupport().canal(), isNull);
      expect(await FauxAccesFoyer().acces(), isEmpty);
      expect(await FauxPaiementsFoyer().detail('p'), isNull);
      expect(await FauxNotifications().liste(), isEmpty);
      expect(
        (await FauxProgressionFamille().progression('e')).niveauHumain,
        isNull,
      );
      expect(
        await FauxResumeSeanceFamille().resume(seanceId: 's', eleveId: 'e'),
        isNull,
      );
    });
  });
}
