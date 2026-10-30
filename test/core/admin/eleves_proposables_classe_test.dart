// D5 (30/10/2026) : « Ajouter un eleve » lit `eleves_proposables_classe` pour
// la classe ouverte, qui propose aussi l'adulte titulaire d'une classe adulte
// de son genre (filtre serveur, scenarios_d5_titulaire_adulte_en_classe.sql).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/personnes_proposables.dart';
import 'package:rewayah_academy/core/widgets/selecteur_personne.dart';

class _Lecteur implements LecteurElevesProposables {
  _Lecteur(this.reponse, {this.echoue = false});

  final List<Map<String, dynamic>> reponse;
  final bool echoue;
  final List<String> classes = <String>[];

  @override
  Future<List<PersonneProposee>> pourClasse(String groupeId) async {
    classes.add(groupeId);
    if (echoue) throw Exception('reseau coupe');
    return reponse.map(personneProposeeDepuisJson).toList();
  }
}

void main() {
  test(
    'une ligne serveur devient une personne, nom replie sur le matricule',
    () {
      final PersonneProposee adulte = personneProposeeDepuisJson(
        <String, dynamic>{
          'profile_id': 'p1',
          'immutable_id': 'RA-26-4817',
          'prenom': 'Karim',
          'nom': 'Benali',
          'adulte_titulaire': true,
        },
      );
      expect(adulte.id, 'p1');
      expect(adulte.nom, 'Karim Benali');
      expect(adulte.identifiant, 'RA-26-4817');

      final PersonneProposee masque = personneProposeeDepuisJson(
        <String, dynamic>{
          'profile_id': 'p2',
          'immutable_id': 'RA-26-1111',
          'prenom': null,
          'nom': null,
          'adulte_titulaire': false,
        },
      );
      expect(masque.nom, 'RA-26-1111');
    },
  );

  test('la liste est lue pour la classe donnee et triee par nom', () async {
    final _Lecteur lecteur = _Lecteur(<Map<String, dynamic>>[
      <String, dynamic>{
        'profile_id': 'b',
        'immutable_id': 'B',
        'prenom': 'Zayd',
        'nom': null,
      },
      <String, dynamic>{
        'profile_id': 'a',
        'immutable_id': 'A',
        'prenom': 'Élias',
        'nom': null,
      },
    ]);
    final ProviderContainer conteneur = ProviderContainer(
      overrides: <Override>[
        lecteurElevesProposablesProvider.overrideWithValue(lecteur),
      ],
    );
    addTearDown(conteneur.dispose);
    final ProviderSubscription<AsyncValue<List<PersonneProposee>>> abonnement =
        conteneur.listen(
          elevesProposablesClasseProvider('classe-1'),
          (_, _) {},
        );
    addTearDown(abonnement.close);

    final List<PersonneProposee> personnes = await conteneur.read(
      elevesProposablesClasseProvider('classe-1').future,
    );
    expect(lecteur.classes, <String>['classe-1']);
    expect(personnes.map((PersonneProposee p) => p.id), <String>['a', 'b']);
  });

  test('un echec se voit tout de suite, sans relance automatique', () async {
    final _Lecteur lecteur = _Lecteur(
      const <Map<String, dynamic>>[],
      echoue: true,
    );
    final ProviderContainer conteneur = ProviderContainer(
      overrides: <Override>[
        lecteurElevesProposablesProvider.overrideWithValue(lecteur),
      ],
    );
    addTearDown(conteneur.dispose);
    final ProviderSubscription<AsyncValue<List<PersonneProposee>>> abonnement =
        conteneur.listen(
          elevesProposablesClasseProvider('classe-1'),
          (_, _) {},
        );
    addTearDown(abonnement.close);

    await expectLater(
      conteneur.read(elevesProposablesClasseProvider('classe-1').future),
      throwsException,
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(lecteur.classes, hasLength(1));
    expect(abonnement.read().hasError, isTrue);
  });
}
