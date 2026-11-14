// AGE-17 (14/11/2026, directeur) : « le formulaire élèves (famille) permet
// encore d'enregistrer un enfant de 18 ans ». Aucune voie du client ne
// l'accepte ; ce test le fige : la borne est 17 dans les trois endroits ou une
// famille donne l'age d'un enfant (formulaire du foyer, grille d'age,
// questionnaire d'inscription), et 18 est refuse comme « hors bornes ».
// Cote serveur : creer_profil_enfant (20261110340000) et la fonction Edge
// creer-profil-enfant refusent deja `age >= 18` (tests Deno et SQL existants).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/foyer/profil_eleve_brouillon.dart';
import 'package:rewayah_academy/features/foyer/choix_age.dart';
import 'package:rewayah_academy/features/inscription/questionnaire/questionnaire_inscription.dart';

import '../../support/harnais.dart';

void main() {
  test('le formulaire du foyer refuse 18 ans et plus, accepte 6 a 17', () {
    for (final int age in <int>[18, 19, 35, 99]) {
      expect(
        const BrouillonProfilEleve()
            .copyWith(prenom: 'A', nom: 'B', age: age)
            .valider(BornesAge.clientActuelle)[ChampProfilEleve.age],
        ErreurChamp.horsBornes,
        reason: '$age ans',
      );
    }
    for (final int age in <int>[6, 17]) {
      expect(
        const BrouillonProfilEleve()
            .copyWith(prenom: 'A', nom: 'B', age: age)
            .valider(BornesAge.clientActuelle)
            .containsKey(ChampProfilEleve.age),
        isFalse,
        reason: '$age ans',
      );
    }
  });

  test('le questionnaire d\'inscription s\'arrete a 17 ans', () {
    expect(ageMaximum, 17);
    expect(ageMaximum, BornesAge.clientActuelle.max);
  });

  testWidgets('la grille d\'age propose 6 a 17, jamais 18', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      hote(
        SingleChildScrollView(
          child: ChoixAge(
            choisi: null,
            aide: 'aide',
            onChoisir: (int _) {},
            clePuce: (int age) => ValueKey<String>('age-$age'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('age-17')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('age-6')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('age-18')), findsNothing);
  });
}
