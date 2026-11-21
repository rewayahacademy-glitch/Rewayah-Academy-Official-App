// PERSONNES-UNE-PAGE, etape (c) : les filtres de la page, en fonctions pures.
// Chaque type garde les comptes voulus ; l'adresse ne pose que des filtres
// que l'onglet connait ; le filtre des enseignants part au serveur.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidatures_direction.dart'
    show FiltreCandidatures, RequeteCandidatures;
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignants/modeles_enseignants.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/features/admin_candidatures/adresse_candidatures.dart';
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
        filtresDeLAdresse(
          typesDeFiltre(OngletPersonnes.eleves),
          <String, String>{
            'etat': 'actif',
            'age': 'vieux',
            'role': 'admin',
            'phase': 'accueil',
          },
        ),
        <String, String>{'etat': 'actif'},
      );
      expect(
        filtresDeLAdresse(
          typesDeFiltre(
            OngletPersonnes.enseignants,
            vue: VueEnseignants.actifs,
          ),
          <String, String>{'etat': 'actif', 'phase': 'en_poste'},
        ),
        <String, String>{'phase': 'en_poste'},
      );
    },
  );

  test('enseignants : chaque vue impose sa phase au serveur ; « Actifs » ne '
      'propose que ses phases', () {
    final FiltreEnseignants f = filtreEnseignantsDe(
      VueEnseignants.actifs,
      <String, String>{'phase': 'en_poste'},
      'far',
    );
    expect(f.phase, PhaseEnseignant.enPoste);
    expect(f.recherche, 'far');
    expect(
      filtreEnseignantsDe(
        VueEnseignants.actifs,
        const <String, String>{},
        '',
      ).phase,
      isNull,
    );
    expect(
      filtreEnseignantsDe(
        VueEnseignants.accueil,
        const <String, String>{},
        '',
      ).phase,
      PhaseEnseignant.accueil,
    );
    final FiltreEnseignants partis = filtreEnseignantsDe(
      VueEnseignants.partis,
      const <String, String>{},
      '',
    );
    expect(partis.phase, PhaseEnseignant.parti);
    expect(partis.partis, isTrue);
    expect(
      typesDeFiltre(
        OngletPersonnes.enseignants,
        vue: VueEnseignants.actifs,
      ).single.valeurs.map((ValeurFiltre v) => v.code),
      <String>[for (final PhaseEnseignant p in phasesActives) p.valeurSql],
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

  group('vue « Candidats » (etape d)', () {
    final List<TypeFiltrePersonnes> types = typesDeFiltre(
      OngletPersonnes.enseignants,
    );

    test('les 26 filtres de la file, ranges en familles, aux cles d\'adresse '
        'de l\'ancienne liste', () {
      expect(types, hasLength(26));
      for (final TypeFiltrePersonnes x in types) {
        expect(clesAdresseCandidatures, contains(x.cle), reason: x.cle);
        expect(x.famille, isNotNull, reason: x.cle);
        // Le domaine vient du catalogue : sans lui, les familles seules.
        expect(x.valeurs, isNotEmpty, reason: x.cle);
      }
      expect(
        types.map((TypeFiltrePersonnes x) => x.famille).toSet(),
        hasLength(6),
      );
    });

    test('chaque valeur proposee se lit par `requeteDepuisAdresse` et se '
        'reecrit a l\'identique : le serveur recoit ce que la puce dit', () {
      for (final TypeFiltrePersonnes x in types) {
        for (final ValeurFiltre v in x.valeurs) {
          final Map<String, String> adresse = <String, String>{x.cle: v.code};
          final FiltreCandidatures f = filtreCandidatsDe(adresse, '');
          expect(f.estVide, isFalse, reason: '${x.cle}=${v.code}');
          expect(
            requeteEnAdresse(RequeteCandidatures(filtre: f)),
            adresse,
            reason: '${x.cle}=${v.code}',
          );
        }
      }
    });

    test('les jours se cumulent et se retirent, dans l\'ordre', () {
      final TypeFiltrePersonnes jours = types.firstWhere(
        (TypeFiltrePersonnes x) => x.cle == 'jours',
      );
      expect(jours.apresChoix(null, '3'), '3');
      expect(jours.apresChoix('3', '1'), '1,3');
      expect(jours.apresChoix('1,3', '3'), '1');
      expect(jours.apresChoix('1', '1'), isNull);
      expect(jours.libelleDe('1,3'), contains(', '));
      expect(jours.libelleDe('1,9'), isNull);
      expect(
        filtreCandidatsDe(<String, String>{'jours': '1,3'}, '').jours,
        <int>[1, 3],
      );
    });

    test('la recherche part avec le filtre', () {
      final FiltreCandidatures f = filtreCandidatsDe(<String, String>{
        'ijaza': 'oui',
      }, 'far');
      expect(f.recherche, 'far');
      expect(f.ijaza, 'oui');
    });
  });

  test('la file donnee au dossier : celle de la vue, jamais un nom', () {
    expect(
      fileDeLaVue(VueEnseignants.candidats, <String, String>{
        'etat': 'enExamen',
      }),
      <String, String>{'vue': 'candidats', 'etat': 'enExamen'},
    );
    expect(
      fileDeLaVue(VueEnseignants.accueil, const <String, String>{}),
      <String, String>{
        'file': 'enseignants',
        'vue': 'accueil',
        'phase_file': 'accueil',
      },
    );
    expect(
      fileDeLaVue(VueEnseignants.partis, const <String, String>{}),
      <String, String>{
        'file': 'enseignants',
        'vue': 'partis',
        'phase_file': 'parti',
        'partis': 'oui',
      },
    );
    // « Actifs » sans phase choisie : la file est celle de la phase de la
    // personne ; avec une phase choisie, celle du filtre.
    expect(
      fileDeLaVue(
        VueEnseignants.actifs,
        const <String, String>{},
        phaseDeLaLigne: PhaseEnseignant.absent,
      ),
      <String, String>{
        'file': 'enseignants',
        'vue': 'actifs',
        'phase_file': 'absent',
      },
    );
    expect(
      fileDeLaVue(VueEnseignants.actifs, <String, String>{
        'phase': 'en_poste',
      }, phaseDeLaLigne: PhaseEnseignant.enPoste),
      <String, String>{
        'file': 'enseignants',
        'vue': 'actifs',
        'phase': 'en_poste',
      },
    );
  });
}
