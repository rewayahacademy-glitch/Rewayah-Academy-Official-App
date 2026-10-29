// Appareil de Hakim (27/10/2026) : l'accueil de l'eleve en Interface guidee se
// relit a chaque signal de la veille temps reel et, en secours, toutes les
// AppDelais.relectureAccueil ; une seance creee apres l'ouverture y apparait.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/port_accueil_accessibilite.dart';
import 'package:rewayah_academy/core/fraicheur/generation_veille.dart';
import 'package:rewayah_academy/core/fraicheur/relecture_reguliere.dart';
import 'package:rewayah_academy/core/theme/app_delais.dart';

class _AccueilCompte implements PortAccueilAccessibilite {
  int lectures = 0;

  @override
  Future<DonneesAccueilAccessibilite> lire() async {
    lectures++;
    return const DonneesAccueilAccessibilite(
      prenom: 'Fixture',
      tutoiement: true,
      espace: null,
    );
  }
}

void main() {
  testWidgets('RelectureReguliere relit toutes les AppDelais.relectureAccueil, '
      'puis plus une fois l ecran quitte', (WidgetTester tester) async {
    var relectures = 0;
    await tester.pumpWidget(
      RelectureReguliere(
        relire: () => relectures++,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pump(AppDelais.relectureAccueil);
    expect(relectures, 1);
    await tester.pump(AppDelais.relectureAccueil);
    expect(relectures, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(AppDelais.relectureAccueil * 3);
    expect(relectures, 2);
  });

  test('un signal de la veille la relit', () async {
    final _AccueilCompte accueil = _AccueilCompte();
    final ProviderContainer conteneur = ProviderContainer(
      overrides: <Override>[
        portAccueilAccessibiliteProvider.overrideWithValue(accueil),
      ],
    );
    addTearDown(conteneur.dispose);
    conteneur.listen(donneesAccueilAccessibiliteProvider, (_, _) {});
    await pumpEventQueue();
    expect(accueil.lectures, 1);

    conteneur.read(generationVeilleProvider.notifier).avancer();
    await pumpEventQueue();
    expect(accueil.lectures, 2);
  });
}
