import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/content_position.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/port_catalogue.dart';

import 'faux/faux_ports_b.dart';

void main() {
  test('un groupe refuse ne vide que sa section, pas la Bibliotheque', () async {
    // Le groupe vient de l'adresse (`?groupe=`) : c'est une valeur que
    // n'importe qui peut ecrire. Cote serveur, `ressources_du_groupe` LEVE sur
    // un groupe etranger, elle ne rend pas une liste vide. Les quatre lectures
    // etant attendues dans le meme provider, sans garde ce refus emporterait
    // « Tous les supports », « Recents » et « Continuer » avec lui.
    final LibraryResource r1 = ressource(id: 'r1');
    final LibraryResource r2 = ressource(id: 'r2');

    final ProviderContainer conteneur = ProviderContainer(
      overrides: surchargesCatalogue(
        catalogue: CatalogueGroupeRefuse(
          ressources: <LibraryResource>[r1, r2],
          recents: <String>['r2'],
          reprise: ReprisLecture(
            ressource: r1,
            position: const ContentPosition.page(resourceId: 'r1', page: 12),
            vueLeUtc: DateTime.utc(2026, 9, 19, 18),
          ),
        ),
      ),
    );
    addTearDown(conteneur.dispose);

    final DonneesCatalogue donnees = await conteneur.read(
      donneesCatalogueProvider('groupe-etranger').future,
    );

    // La section refusee est vide, et une section vide disparait
    // (`surface_bibliotheque.dart`) : elle ne se remplit pas d'autre chose.
    expect(donnees.pourGroupe, isEmpty);

    // Le reste de la page tient debout.
    expect(
      donnees.tous.map((LibraryResource r) => r.id),
      unorderedEquals(<String>['r1', 'r2']),
    );
    expect(donnees.recents.single.id, 'r2');
    expect(donnees.reprise?.ressource.id, 'r1');
  });
}
