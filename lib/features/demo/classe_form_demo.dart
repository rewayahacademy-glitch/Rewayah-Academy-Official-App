// Creation de classe du mode demonstration admin (CLASSE-FORM-1).
//
// Donnees fictives, jamais envoyees au serveur (`surchargesDemoAdmin`, garde
// compilee `environnementAutoriseDemo`). Les enseignants sont ceux des classes
// de `groupesDemo()` (memes identifiants), plus un enseignant dont le genre
// n'est pas connu, pour que la regle D3 se voie (CAND-Q15, 21/10 : visible,
// non choisissable, avec sa raison). Les disponibilites reprennent
// celles de `DonneesEnseignantDemo` (une seule source de demonstration).

import '../../core/admin/service_groupes.dart';
import '../../core/capacites/port_creation_classe.dart';
import '../../core/capacites/port_enseignants_classe.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import 'admin_x_demo.dart' show groupesDemo;
import 'enseignant_demo.dart' show DonneesEnseignantDemo;

/// Les classes creees pendant la demonstration, partagees par la creation,
/// la liste des classes et les enseignants proposes : une classe creee se
/// voit dans la liste et compte dans la charge de son enseignant.
class ClassesCreeesDemo {
  final List<GroupeAdmin> _groupes = <GroupeAdmin>[];
  final Map<String, GenreClasse> _genres = <String, GenreClasse>{};

  /// Les classes creees, la plus recente d'abord.
  List<GroupeAdmin> get groupes => List<GroupeAdmin>.unmodifiable(_groupes);

  /// Le genre retenu pour une classe creee (la demonstration le garde).
  GenreClasse? genreDe(String groupeId) => _genres[groupeId];

  /// Toutes les classes de la demonstration : creees, puis fictives.
  List<GroupeAdmin> toutes() => <GroupeAdmin>[..._groupes, ...groupesDemo()];
}

/// Un enseignant fictif : ses disponibilites declarees, sans ses classes.
typedef _EnseignantDemo = ({
  String id,
  String prenom,
  String nom,
  String identifiant,
  GenreEnseignant? genre,
  List<Creneau> disponibilites,
});

const String _fuseau = DonneesEnseignantDemo.fuseau;

const List<_EnseignantDemo> _enseignants = <_EnseignantDemo>[
  (
    id: 'demo-ens-1',
    prenom: 'Amina',
    nom: 'Exemple',
    identifiant: 'TEACHER-AE-000001',
    genre: GenreEnseignant.femme,
    disponibilites: DonneesEnseignantDemo.disponibilites,
  ),
  (
    id: 'demo-ens-2',
    prenom: 'Omar',
    nom: 'Fictif',
    identifiant: 'TEACHER-OF-000002',
    genre: GenreEnseignant.homme,
    disponibilites: <Creneau>[
      Creneau(jour: 2, heure: 18, fuseau: _fuseau),
      Creneau(jour: 4, heure: 18, fuseau: _fuseau),
      Creneau(jour: 6, heure: 10, fuseau: _fuseau),
      Creneau(jour: 6, heure: 11, fuseau: _fuseau),
    ],
  ),
  (
    id: 'demo-ens-3',
    prenom: 'Inès',
    nom: 'Modèle',
    identifiant: 'TEACHER-IE-000003',
    genre: GenreEnseignant.femme,
    disponibilites: <Creneau>[
      Creneau(jour: 1, heure: 17, fuseau: _fuseau),
      Creneau(jour: 1, heure: 18, fuseau: _fuseau),
      Creneau(jour: 5, heure: 18, fuseau: _fuseau),
    ],
  ),
  (
    id: 'demo-ens-4',
    prenom: 'Nour',
    nom: 'Démo',
    identifiant: 'TEACHER-ND-000004',
    // Genre non renseigne (D3 revue, CAND-Q15) : visible, non choisissable,
    // avec sa raison.
    genre: null,
    disponibilites: <Creneau>[
      Creneau(jour: 2, heure: 17, fuseau: _fuseau),
      Creneau(jour: 4, heure: 17, fuseau: _fuseau),
    ],
  ),
];

/// Un enseignant de la demonstration par son identifiant : son prenom, son
/// nom et son identifiant immuable. Un identifiant inconnu se dit tel quel.
({String identifiant, String nom, String prenom}) enseignantDemoParId(
  String id,
) {
  for (final _EnseignantDemo e in _enseignants) {
    if (e.id == id) {
      return (identifiant: e.identifiant, nom: e.nom, prenom: e.prenom);
    }
  }
  return (identifiant: id, nom: '', prenom: id);
}

/// Les enseignants proposes en demonstration : creneaux libres = leurs
/// disponibilites moins les creneaux de leurs classes actives.
class EnseignantsClasseDemo implements PortEnseignantsClasse {
  /// Cree la source.
  const EnseignantsClasseDemo(this._creees);

  final ClassesCreeesDemo _creees;

  @override
  Future<List<EnseignantPropose>> pourClasse({
    required TypePublicGroupe public,
  }) async {
    final List<GroupeAdmin> actives = _creees
        .toutes()
        .where((GroupeAdmin g) => g.actif)
        .toList();
    return <EnseignantPropose>[
      for (final _EnseignantDemo e in _enseignants)
        () {
          final List<Creneau> pris = <Creneau>[
            for (final GroupeAdmin g in actives)
              if (g.teacherId == e.id) g.creneau,
          ];
          return EnseignantPropose(
            id: e.id,
            libelle: '${e.prenom} ${e.nom}',
            identifiant: e.identifiant,
            genre: e.genre,
            classesActives: pris.length,
            creneauxPris: pris,
            creneauxLibres: <Creneau>[
              for (final Creneau c in e.disponibilites)
                if (!pris.any(
                  (Creneau p) => p.jour == c.jour && p.heure == c.heure,
                ))
                  c,
            ],
            fuseauIana: _fuseau,
          );
        }(),
    ];
  }
}

/// La creation en demonstration : retient tout, genre et fuseau compris,
/// sans rien envoyer.
class CreationClasseDemo implements PortCreationClasse {
  /// Cree l'adaptateur.
  const CreationClasseDemo(this._creees);

  final ClassesCreeesDemo _creees;

  @override
  bool get retientGenre => true;

  @override
  bool get retientFuseau => true;

  @override
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required GenreClasse genre,
    required String libelle,
    required Creneau creneau,
    required int seuilMax,
    List<Creneau> autresCreneaux = const <Creneau>[],
  }) async {
    final _EnseignantDemo e = _enseignants.firstWhere(
      (_EnseignantDemo e) => e.id == teacherId,
    );
    final String id = 'demo-classe-creee-${_creees._groupes.length + 1}';
    _creees._groupes.insert(
      0,
      GroupeAdmin(
        id: id,
        libelle: libelle,
        type: type,
        seuilMax: seuilMax,
        teacherId: e.id,
        teacherIdentifiant: e.identifiant,
        teacherPrenom: e.prenom,
        teacherNom: e.nom,
        creneau: creneau,
        nombreMembres: 0,
        actif: true,
      ),
    );
    _creees._genres[id] = genre;
    return id;
  }
}
