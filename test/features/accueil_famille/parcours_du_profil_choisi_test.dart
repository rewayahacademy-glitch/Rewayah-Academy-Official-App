import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/features/accueil_famille/parcours_du_profil_choisi.dart';

import '../../parcours/faux_service_offres.dart';
import '../../support/harnais.dart';

/// Non-regression (11/11/2026) : avec un profil ajoute puis choisi, l'accueil
/// ne montrait pas son parcours mais celui de TOUS les apprentis du foyer
/// (« Le parcours de Dyna », trois enfants deja en classe dans « Horaire a
/// choisir »).
void main() {
  final DateTime fait = DateTime(2026, 9, 20, 10);

  ParcoursApprenant sansPreference(String id, String prenom) => apprenantDeTest(
    eleveId: id,
    prenom: prenom,
    cohorte: 'enfant_8_10',
    langue: 'francais',
    onboardingFaitLe: fait,
    fuseauFoyer: 'Europe/Paris',
  );

  final List<ParcoursApprenant> foyer = <ParcoursApprenant>[
    sansPreference('dyna', 'Dyna'),
    sansPreference('yanis', 'Yanis'),
    sansPreference('lina', 'Lina'),
    apprenantDeTest(eleveId: 'salam', prenom: 'Salam'),
  ];

  Future<void> monter(WidgetTester tester, String eleveId) async {
    await tester.pumpWidget(
      hote(
        Scaffold(
          body: SingleChildScrollView(
            child: ParcoursDuProfilChoisi(eleveId: eleveId),
          ),
        ),
        surcharges: <Override>[
          serviceOffresProvider.overrideWithValue(
            FauxServiceOffres(parcoursRendu: foyer),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  test('le jeu de donnees est celui du defaut : 3 horaire a choisir, 1 a '
      'personnaliser', () {
    expect(foyer.map(etapeParcours).toList(), <EtapeParcours>[
      EtapeParcours.horaireAChoisir,
      EtapeParcours.horaireAChoisir,
      EtapeParcours.horaireAChoisir,
      EtapeParcours.aPersonnaliser,
    ]);
  });

  testWidgets('le profil choisi n a que sa carte, titree de son prenom', (
    WidgetTester tester,
  ) async {
    await monter(tester, 'salam');
    expect(
      find.text(t.parcours.titre(dePrenom: deDevant('Salam'))),
      findsOneWidget,
    );
    expect(find.text(t.parcours.etatAPersonnaliser), findsOneWidget);
    expect(find.text(t.parcours.etatHoraireAChoisir), findsNothing);
    for (final String autre in <String>['Dyna', 'Yanis', 'Lina']) {
      expect(find.textContaining(autre), findsNothing);
    }
  });

  testWidgets('un autre profil choisi n a que la sienne', (
    WidgetTester tester,
  ) async {
    await monter(tester, 'yanis');
    expect(
      find.text(t.parcours.titre(dePrenom: deDevant('Yanis'))),
      findsOneWidget,
    );
    expect(find.text(t.parcours.etatHoraireAChoisir), findsOneWidget);
    expect(find.textContaining('Salam'), findsNothing);
    expect(find.textContaining('Dyna'), findsNothing);
  });
}
