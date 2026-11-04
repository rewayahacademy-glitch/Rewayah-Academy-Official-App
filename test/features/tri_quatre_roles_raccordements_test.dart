// Tri des quatre roles (31/10/2026) : les raccordements simples de la PR B.
//
// Ce que le test prouve :
// - « Signaler un besoin » part au serveur quand la fiche connait la Classe
//   (`portSignalementProvider`, `deposer_student_concern`), avec l'identifiant
//   immuable de l'eleve et la categorie choisie ; sans Classe ou sans serveur,
//   aucun envoi n'est fourni (l'ecran le dit, K-28) ;
// - le nom public de l'enseignant porte son titre Sayyid ou Sayyida, lu dans
//   son profil ; sans titre, nul (l'en-tete garde le prenom) ;
// - le catalogue des classes est dit ouvert seulement quand il repond.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_catalogue_classes.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_profil_enseignant.dart';
import 'package:rewayah_academy/core/tc_parcours/port_signalement.dart';
import 'package:rewayah_academy/core/tc_parcours/student_concern.dart';
import 'package:rewayah_academy/features/fiche_groupe/fiche_eleve_enseignant.dart';
import 'package:rewayah_academy/features/profil_enseignant/profil_enseignant_page.dart';

const MembreSeance _mariam = MembreSeance(
  studentId: 'e1',
  identifiantImmuable: 'RA-26-4817',
  prenom: 'Mariam',
);

/// Lit l'envoi fourni a la feuille, dans un vrai contexte Riverpod.
Future<Future<void> Function(SignalementBesoin)?> _envoi(
  WidgetTester tester,
  EleveFiche eleve, {
  List<Override> surcharges = const <Override>[],
}) async {
  Future<void> Function(SignalementBesoin)? lu;
  await tester.pumpWidget(
    ProviderScope(
      overrides: surcharges,
      child: Builder(
        builder: (BuildContext contexte) {
          lu = envoiSignalement(contexte, eleve);
          return const SizedBox();
        },
      ),
    ),
  );
  return lu;
}

void main() {
  group('Signaler un besoin', () {
    testWidgets('avec la Classe et le serveur : le signalement part', (
      WidgetTester tester,
    ) async {
      final SignalementMemoire memoire = SignalementMemoire('ens-1');
      final Future<void> Function(SignalementBesoin)? envoi = await _envoi(
        tester,
        const EleveFiche(membre: _mariam, classe: 'Alif', groupeId: 'g-1'),
        surcharges: <Override>[
          portSignalementProvider.overrideWithValue(memoire),
        ],
      );
      expect(envoi, isNotNull);
      await envoi!(
        SignalementBesoin(
          studentId: 'e1',
          categorie: CategorieBesoin.presence,
          detailsInternes: 'Absente deux fois',
          resumePartageable: '  ',
          classe: 'Alif',
          horodatage: DateTime.utc(2026, 10, 31),
        ),
      );
      final List<StudentConcern> deposes = await memoire.mesSignalements();
      expect(deposes, hasLength(1));
      expect(deposes.single.groupeId, 'g-1');
      expect(deposes.single.academyId, 'RA-26-4817');
      expect(deposes.single.categorie, CategorieSignalement.presence);
    });

    testWidgets('sans Classe : aucun envoi', (WidgetTester tester) async {
      final Future<void> Function(SignalementBesoin)? envoi = await _envoi(
        tester,
        const EleveFiche(membre: _mariam, classe: 'Alif'),
        surcharges: <Override>[
          portSignalementProvider.overrideWithValue(
            SignalementMemoire('ens-1'),
          ),
        ],
      );
      expect(envoi, isNull);
    });

    testWidgets('sans serveur : aucun envoi', (WidgetTester tester) async {
      final Future<void> Function(SignalementBesoin)? envoi = await _envoi(
        tester,
        const EleveFiche(membre: _mariam, classe: 'Alif', groupeId: 'g-1'),
      );
      expect(envoi, isNull);
    });
  });

  group('Nom public de l enseignant', () {
    ProviderContainer conteneur(String? titre) {
      final ProviderContainer c = ProviderContainer(
        overrides: <Override>[
          profilEnseignantProvider.overrideWith(
            (Ref _) async => ProfilEnseignant(
              prenom: 'Aïcha',
              identifiant: 'RA-26-1111',
              titre: titre,
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('Sayyida, lu dans le profil', () async {
      final ProviderContainer c = conteneur('sayyida');
      await c.read(profilEnseignantProvider.future);
      expect(
        c.read(nomPublicEnseignantProvider),
        '${t.tc.groupe.enseignant.sayyida} Aïcha',
      );
    });

    test('sans titre : nul, l en-tete garde le prenom', () async {
      final ProviderContainer c = conteneur(null);
      await c.read(profilEnseignantProvider.future);
      expect(c.read(nomPublicEnseignantProvider), isNull);
    });
  });

  test('catalogue : ouvert seulement quand il repond', () {
    expect(
      catalogueClassesOuvert(const CatalogueClassesIndisponible()),
      isFalse,
    );
  });
}
