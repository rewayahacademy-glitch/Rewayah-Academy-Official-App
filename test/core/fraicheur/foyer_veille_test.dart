// Dette D2 (garde-cap, journaux de production du 07/11) : la direction
// retire un profil ; dans une session deja ouverte, le foyer du tuteur le
// montre encore, jusqu'a la reconnexion. La liste du foyer suit desormais la
// veille de fraicheur : relue au retour sur un onglet, au retour dans
// l'application, a « tirer pour rafraichir », et quand le profil quitte ses
// classes (signal `groupe_membres`). ROUGE sans la ligne de
// `lecturesVeillees`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/fraicheur/port_veille.dart';
import 'package:rewayah_academy/core/fraicheur/veille_fraicheur.dart';

void main() {
  test('la famille des classes relit les eleves du foyer', () async {
    int lectures = 0;
    final Provider<void Function()> relire = Provider<void Function()>(
      (Ref ref) =>
          () => invaliderFamille(ref, FamilleLecture.classes),
    );
    final ProviderContainer c = ProviderContainer(
      overrides: <Override>[
        elevesDuFoyerProvider.overrideWith((Ref _) async {
          lectures++;
          return const <EleveDuFoyer>[];
        }),
      ],
    );
    addTearDown(c.dispose);
    await c.read(elevesDuFoyerProvider.future);
    expect(lectures, 1);
    c.read(relire)();
    await c.read(elevesDuFoyerProvider.future);
    expect(lectures, 2);
  });
}
