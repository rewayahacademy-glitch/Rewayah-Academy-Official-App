// PERSONNES-UNE-PAGE, etape (c) : les filtres de la page, en fonctions pures.
// Chaque type garde les comptes voulus ; l'adresse ne pose que des filtres
// que l'onglet connait ; le filtre des enseignants part au serveur.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_personnes/filtres_personnes.dart';
import 'package:rewayah_academy/features/admin_personnes/personnes_page.dart';

CompteAdmin _c(
  String id, {
  AppRole role = AppRole.student,
  String? classe,
  TrancheAge? tranche,
  bool demande = false,
}) => CompteAdmin(
  profilId: id,
  identifiant: 'RA-26-41$id',
  prenom: 'Personne$id',
  nom: 'Essai',
  role: role,
  etat: AccountStatus.active,
  inscritLe: DateTime(2026, 11),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 0,
  aEnseignant: false,
  enfantsDuFoyer: 0,
  detailsServis: true,
  tranche: tranche,
  classeLibelle: classe,
  admissionATraiter: demande,
);

List<String> _ids(List<CompteAdmin> comptes) => <String>[
  for (final CompteAdmin c in comptes) c.profilId,
];

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
  final DateTime maintenant = DateTime(2026, 11, 21);

  List<CompteAdmin> filtrer(
    List<CompteAdmin> tous,
    Map<String, String> filtres, {
    String recherche = '',
  }) => filtrerComptes(
    tous,
    filtres: filtres,
    recherche: recherche,
    maintenant: maintenant,
  );

  test('classe : avec ou sans', () {
    final List<CompteAdmin> tous = <CompteAdmin>[
      _c('1', classe: 'Lecture'),
      _c('2'),
    ];
    expect(_ids(filtrer(tous, <String, String>{'classe': 'avec'})), <String>[
      '1',
    ]);
    expect(_ids(filtrer(tous, <String, String>{'classe': 'sans'})), <String>[
      '2',
    ]);
  });

  test('age, role, demande a traiter, et leur cumul avec la recherche', () {
    final List<CompteAdmin> tous = <CompteAdmin>[
      _c('1', tranche: TrancheAge.enfant),
      _c('2', tranche: TrancheAge.adulte),
      _c('3', role: AppRole.accountant),
      _c('4', role: AppRole.guardian, demande: true),
    ];
    expect(_ids(filtrer(tous, <String, String>{'age': 'adulte'})), <String>[
      '2',
    ]);
    expect(
      _ids(filtrer(tous, <String, String>{'role': 'accountant'})),
      <String>['3'],
    );
    expect(
      _ids(filtrer(tous, <String, String>{'demande': 'a_traiter'})),
      <String>['4'],
    );
    expect(
      filtrer(tous, <String, String>{'age': 'adulte'}, recherche: 'personne1'),
      isEmpty,
    );
    expect(_ids(filtrer(tous, const <String, String>{})), hasLength(4));
  });

  test(
    'l\'adresse ne pose que les filtres de l\'onglet, aux valeurs connues',
    () {
      expect(
        filtresDeLAdresse(OngletPersonnes.eleves, <String, String>{
          'etat': 'actif',
          'age': 'vieux',
          'role': 'admin',
          'phase': 'accueil',
        }),
        <String, String>{'etat': 'actif'},
      );
      expect(
        filtresDeLAdresse(OngletPersonnes.enseignants, <String, String>{
          'etat': 'actif',
          'phase': 'accueil',
        }),
        <String, String>{'phase': 'accueil'},
      );
    },
  );

  test('enseignants : la phase et la recherche partent au serveur ; « parti » '
      'ne se choisit pas ici', () {
    final FiltreEnseignants f = filtreEnseignantsDe(<String, String>{
      'phase': 'en_poste',
    }, 'far');
    expect(f.phase, PhaseEnseignant.enPoste);
    expect(f.recherche, 'far');
    expect(
      typesDeFiltre(OngletPersonnes.enseignants).single.valeurs
          .map((ValeurFiltre v) => v.code),
      isNot(contains(PhaseEnseignant.parti.valeurSql)),
    );
  });

  test('chaque onglet a au moins un type, et chaque type des valeurs', () {
    for (final OngletPersonnes o in OngletPersonnes.values) {
      final List<TypeFiltrePersonnes> types = typesDeFiltre(o);
      expect(types, isNotEmpty);
      expect(
        types.map((TypeFiltrePersonnes x) => x.cle).toSet(),
        hasLength(types.length),
      );
      for (final TypeFiltrePersonnes x in types) {
        expect(x.valeurs, isNotEmpty);
        expect(x.libelle.trim(), isNotEmpty);
      }
    }
  });
}
