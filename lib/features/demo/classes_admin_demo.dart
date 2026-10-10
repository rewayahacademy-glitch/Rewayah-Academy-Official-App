// La liste des classes de la demonstration admin a grande echelle (R16, R17,
// `DECISION-CLASSES-SIMULTANEES-2026-10-10.md`).
//
// Donnees fictives, jamais envoyees au serveur (`surchargesDemoAdmin`, garde
// compilee `environnementAutoriseDemo`). Le numero dans la famille de classes
// paralleles, le genre, l'etat « en attente d'enseignant » et la pagination
// sont SIMULES ici ; le serveur les portera (ligne Contrats de
// ECHELLE-CORR-ECRANS-1). Aucun nom d'eleve.

import 'dart:async';

import '../../core/admin/port_classes_admin.dart';
import '../../core/admin/service_groupes.dart';
import '../../core/capacites/port_enseignants_classe.dart' show GenreClasse;
import '../../core/planning/service_planning.dart' show Creneau;
import 'classe_form_demo.dart';

/// Le nom commun des 30 classes paralleles de la demonstration.
const String libelleFamilleDemo = 'Garçons débutants';

/// Le nombre de classes paralleles de meme cle (lundi 18 h, Paris).
const int classesFamilleDemo = 30;

/// Les numeros de la famille qui attendent leur enseignant (R7).
const Set<int> numerosSansEnseignantDemo = <int>{7, 19, 28};

const List<({String id, String prenom, String nom})> _enseignants =
    <({String id, String prenom, String nom})>[
      (id: 'demo-ens-v-1', prenom: 'Sayyid Ibrahim', nom: 'Exemple'),
      (id: 'demo-ens-v-2', prenom: 'Sayyid Yusuf', nom: 'Fictif'),
      (id: 'demo-ens-v-3', prenom: 'Sayyida Maryam', nom: 'Modèle'),
      (id: 'demo-ens-v-4', prenom: 'Sayyid Bilal', nom: 'Essai'),
      (id: 'demo-ens-v-5', prenom: 'Sayyida Khadija', nom: 'Test'),
    ];

const List<String> _fuseaux = <String>[
  'Europe/Paris',
  'Europe/London',
  'America/Toronto',
];

GroupeAdmin _groupe({
  required String id,
  required String libelle,
  required TypePublicGroupe type,
  required Creneau creneau,
  required int enseignant,
  required bool sansEnseignant,
  required int membres,
  bool actif = true,
}) {
  final ({String id, String prenom, String nom}) e =
      _enseignants[enseignant % _enseignants.length];
  return GroupeAdmin(
    id: id,
    libelle: libelle,
    type: type,
    seuilMax: type == TypePublicGroupe.enfant ? 5 : 6,
    teacherId: sansEnseignant ? '' : e.id,
    teacherIdentifiant: sansEnseignant ? '' : 'TEACHER-DEMO-$enseignant',
    teacherPrenom: sansEnseignant ? null : e.prenom,
    teacherNom: sansEnseignant ? null : e.nom,
    creneau: creneau,
    nombreMembres: membres,
    actif: actif,
  );
}

/// Les 30 classes paralleles « Garcons debutants, lundi 18 h, Paris »,
/// numerotees de 1 a 30, dont trois sans enseignant.
List<ClasseListee> familleDemo() => <ClasseListee>[
  for (int n = 1; n <= classesFamilleDemo; n++)
    ClasseListee(
      groupe: _groupe(
        id: 'demo-famille-lun18-$n',
        libelle: libelleFamilleDemo,
        type: TypePublicGroupe.enfant,
        creneau: const Creneau(jour: 1, heure: 18, fuseau: 'Europe/Paris'),
        enseignant: n,
        sansEnseignant: numerosSansEnseignantDemo.contains(n),
        membres: 3 + n % 3,
      ),
      numeroDansFamille: n,
      genre: GenreClasse.hommes,
      sansEnseignant: numerosSansEnseignantDemo.contains(n),
    ),
];

/// Un grand volume simule : [nombre] classes reparties sur les jours, les
/// heures, trois fuseaux, deux publics et deux genres, numerotees dans leur
/// famille. Deterministe : la meme liste a chaque appel.
List<ClasseListee> volumeDemo({int nombre = 600}) {
  final Map<String, int> numeros = <String, int>{};
  return <ClasseListee>[
    for (int i = 0; i < nombre; i++)
      () {
        final int jour = i % 7 + 1;
        final int heure = 9 + (i ~/ 7) % 13;
        final String fuseau = _fuseaux[(i ~/ 91) % _fuseaux.length];
        final TypePublicGroupe type = i.isEven
            ? TypePublicGroupe.enfant
            : TypePublicGroupe.adulte;
        final GenreClasse genre = (i ~/ 2).isEven
            ? GenreClasse.hommes
            : GenreClasse.femmes;
        final String libelle = switch ((type, genre)) {
          (TypePublicGroupe.enfant, GenreClasse.hommes) => 'Garçons',
          (TypePublicGroupe.enfant, _) => 'Filles',
          (TypePublicGroupe.adulte, GenreClasse.hommes) => 'Hommes',
          (TypePublicGroupe.adulte, _) => 'Femmes',
        };
        final String cle = '$libelle|$jour|$heure|$fuseau';
        final int numero = numeros[cle] = (numeros[cle] ?? 0) + 1;
        final bool sansEnseignant = i % 37 == 0;
        return ClasseListee(
          groupe: _groupe(
            id: 'demo-volume-$i',
            libelle: libelle,
            type: type,
            creneau: Creneau(jour: jour, heure: heure, fuseau: fuseau),
            enseignant: i,
            sansEnseignant: sansEnseignant,
            membres: i % 6,
            actif: i % 23 != 0,
          ),
          numeroDansFamille: numero,
          genre: genre,
          sansEnseignant: sansEnseignant,
        );
      }(),
  ];
}

/// Le port de demonstration : la famille de 30 classes, le volume simule et
/// les classes creees pendant la demonstration (CLASSE-FORM-1), pagines en
/// memoire comme le serveur le fera en SQL.
class ClassesAdminDemo implements PortClassesAdmin {
  /// Cree le port.
  ClassesAdminDemo({
    this.creees,
    List<ClasseListee>? classes,
    this.latence = Duration.zero,
    this.horsLigne = false,
  }) : _classes = classes ?? <ClasseListee>[...familleDemo(), ...volumeDemo()];

  /// Les classes creees pendant la demonstration (CLASSE-FORM-1).
  final ClassesCreeesDemo? creees;
  final List<ClasseListee> _classes;

  /// Le delai de chaque reponse.
  final Duration latence;

  /// Vrai : aucune reponse n'arrive (l'appel echoue).
  bool horsLigne;

  /// Le nombre de pages reellement demandees.
  int pagesDemandees = 0;

  @override
  Future<PageClasses> page(
    FiltreClasses filtre, {
    required int page,
    required int taille,
  }) async {
    pagesDemandees++;
    if (latence > Duration.zero) await Future<void>.delayed(latence);
    if (horsLigne) throw StateError('Aucune reponse du serveur.');
    final ClassesCreeesDemo? creees = this.creees;
    return paginerClasses(
      <ClasseListee>[
        if (creees != null)
          for (final GroupeAdmin g in creees.groupes)
            ClasseListee(groupe: g, genre: creees.genreDe(g.id)),
        ..._classes,
      ],
      filtre,
      page: page,
      taille: taille,
    );
  }
}
