// PERSONNES-UNE-PAGE, etape (d) : `FileDuDossier` connait la file des
// enseignants. Ouvert depuis une vue de la page « Personnes », le dossier
// demande ses voisins a `voisins_enseignant`, au filtre de la vue.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature_detail.dart';
import 'package:rewayah_academy/core/candidature/port_candidatures_direction.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/enseignants/port_enseignants.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/admin_candidature/suivant_dossier.dart';

import '../../fixtures/candidature/faux_candidatures_direction.dart';

class _Port implements PortEnseignants, PortVoisinsEnseignant {
  final List<(String, FiltreEnseignants, TriEnseignants)> demandes =
      <(String, FiltreEnseignants, TriEnseignants)>[];

  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) => throw UnimplementedError();

  @override
  Future<VoisinsCandidature> voisins(
    String reference, {
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
  }) async {
    demandes.add((reference, filtre, tri));
    return const VoisinsCandidature(
      precedent: 'CAND-00001',
      suivant: 'CAND-00003',
      rang: 2,
      total: 3,
    );
  }
}

class _SansVoisins implements PortEnseignants {
  @override
  Future<PageEnseignants> lister({
    required FiltreEnseignants filtre,
    required TriEnseignants tri,
    required int page,
  }) => throw UnimplementedError();
}

Map<String, String> _requete(String chemin) =>
    Uri.parse(chemin).queryParameters;

void main() {
  test('la file des enseignants se lit dans l\'adresse du dossier : phase, '
      'partis, vue ; rien d\'autre', () {
    final FileDuDossier? accueil = FileDuDossier.depuis(
      _requete(
        Routes.adminPersonnesCandidaturePour(
          'CAND-00002',
          fileDeLaListe: const <String, String>{
            'file': 'enseignants',
            'vue': 'accueil',
            'phase_file': 'accueil',
            'q': 'un nom',
            'etat': 'enExamen',
          },
        ),
      ),
    );
    expect(accueil, isNotNull);
    expect(accueil!.enseignants, isTrue);
    expect(accueil.vuePersonnes, 'accueil');
    expect(accueil.filtreEnseignants.phase, PhaseEnseignant.accueil);
    expect(accueil.filtreEnseignants.partis, isFalse);
    expect(accueil.adresse.keys, isNot(contains('q')));
    expect(accueil.adresse.keys, isNot(contains('etat')));

    final FileDuDossier partis = FileDuDossier.depuis(const <String, String>{
      'depuis': 'liste',
      'file': 'enseignants',
      'vue': 'partis',
      'phase_file': 'parti',
      'partis': 'oui',
    })!;
    expect(partis.filtreEnseignants.phase, PhaseEnseignant.parti);
    expect(partis.filtreEnseignants.partis, isTrue);

    // Le filtre pose dans la page (« Actifs » par phase) prevaut.
    final FileDuDossier actifs = FileDuDossier.depuis(const <String, String>{
      'depuis': 'liste',
      'file': 'enseignants',
      'vue': 'actifs',
      'phase': 'en_poste',
    })!;
    expect(actifs.filtreEnseignants.phase, PhaseEnseignant.enPoste);
  });

  test('la file des candidats garde la vue de la page, et ses filtres', () {
    final FileDuDossier file = FileDuDossier.depuis(const <String, String>{
      'depuis': 'liste',
      'vue': 'candidats',
      'ijaza': 'oui',
      'q': 'un nom',
    })!;
    expect(file.enseignants, isFalse);
    expect(file.vuePersonnes, 'candidats');
    expect(file.requete.filtre.ijaza, 'oui');
    expect(file.adresse.keys, isNot(contains('q')));
  });

  test(
    'les voisins d\'un enseignant viennent de `voisins_enseignant`, au '
    'filtre de la vue ; la file des candidatures n\'est pas interrogee',
    () async {
      final _Port port = _Port();
      final FauxCandidaturesDirection candidatures =
          FauxCandidaturesDirection();
      final ProviderContainer conteneur = ProviderContainer(
        overrides: [
          portEnseignantsProvider.overrideWithValue(port),
          portCandidaturesDirectionProvider.overrideWithValue(candidatures),
        ],
      );
      addTearDown(conteneur.dispose);
      final FileDuDossier file = FileDuDossier.depuis(const <String, String>{
        'depuis': 'liste',
        'file': 'enseignants',
        'vue': 'accueil',
        'phase_file': 'accueil',
      })!;
      final VoisinsCandidature? v = await conteneur.read(
        voisinsDuDossierProvider(DemandeVoisins('CAND-00002', file)).future,
      );
      expect(v?.suivant, 'CAND-00003');
      expect(v?.rang, 2);
      expect(port.demandes.single.$1, 'CAND-00002');
      expect(port.demandes.single.$2.phase, PhaseEnseignant.accueil);
      expect(port.demandes.single.$3, TriEnseignants.activite);
    },
  );

  test('un port sans voisins (fonction pas encore servie) : rien, jamais un '
      'rang invente', () async {
    final ProviderContainer conteneur = ProviderContainer(
      overrides: [portEnseignantsProvider.overrideWithValue(_SansVoisins())],
    );
    addTearDown(conteneur.dispose);
    final FileDuDossier file = FileDuDossier.depuis(const <String, String>{
      'depuis': 'liste',
      'file': 'enseignants',
      'vue': 'accueil',
      'phase_file': 'accueil',
    })!;
    expect(
      await conteneur.read(
        voisinsDuDossierProvider(DemandeVoisins('CAND-00002', file)).future,
      ),
      isNull,
    );
  });
}
