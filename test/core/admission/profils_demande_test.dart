// Admission, lot C : apres l'acceptation, les enfants de la demande recoivent
// leur profil. Ce que le test prouve : le titulaire et un enfant deja lie ne
// sont jamais recrees ; un profil probable (reponse perdue) est lie sans
// creation ; un echec arrete la boucle sans lever ; une ligne illisible est
// ignoree.
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admission/profils_demande.dart';

class _Port implements PortProfilsDemande {
  _Port(this.enfants);

  final List<EnfantDemande> enfants;
  final List<String> creations = <String>[];
  final List<String> liaisons = <String>[];
  Set<String> echecs = <String>{};

  @override
  Future<List<EnfantDemande>> lire() async => enfants;

  @override
  Future<String?> creer({
    required String prenom,
    required String nom,
    required int age,
  }) async {
    if (echecs.contains(prenom)) {
      throw Exception('coupure');
    }
    creations.add('$prenom $nom $age');
    return 'profil-$prenom';
  }

  @override
  Future<void> lier(String apprenantId, String profilEleveId) async =>
      liaisons.add('$apprenantId>$profilEleveId');
}

EnfantDemande _e(
  String id,
  String prenom, {
  int? age = 9,
  bool titulaire = false,
  String? lie,
  String? probable,
}) => (
  id: id,
  prenom: prenom,
  age: age,
  titulaire: titulaire,
  profilEleveId: lie,
  profilProbable: probable,
  nomFamille: 'Bah',
);

void main() {
  test('cree et lie les enfants qui manquent, jamais le titulaire', () async {
    final _Port p = _Port(<EnfantDemande>[
      _e('a0', 'Awa', age: null, titulaire: true),
      _e('a1', 'Yasmine'),
      _e('a2', 'Ilyas', age: 12, lie: 'deja'),
      _e('a3', 'Sara', probable: 'profil-existant'),
    ]);
    expect(await creerProfilsDemande(p), 2);
    expect(p.creations, <String>['Yasmine Bah 9']);
    expect(p.liaisons, <String>['a1>profil-Yasmine', 'a3>profil-existant']);
  });

  test('un echec arrete la boucle sans lever', () async {
    final _Port p = _Port(<EnfantDemande>[
      _e('a1', 'Yasmine'),
      _e('a2', 'Ilyas'),
    ])..echecs = <String>{'Yasmine'};
    expect(await creerProfilsDemande(p), 0);
    expect(p.liaisons, isEmpty);
  });

  test('une ligne illisible est ignoree', () {
    expect(enfantDepuisJson(<String, dynamic>{'prenom': 'X'}), isNull);
    expect(enfantDepuisJson('x'), isNull);
    final EnfantDemande? e = enfantDepuisJson(<String, dynamic>{
      'id': 'a1',
      'prenom': 'Yasmine',
      'age': 9,
      'est_titulaire': false,
      'profil_probable': 'p1',
      'nom_famille': 'Bah',
    });
    expect(e?.profilProbable, 'p1');
    expect(e?.nomFamille, 'Bah');
  });
}
