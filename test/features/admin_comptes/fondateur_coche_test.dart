// V2-e (04/11/2026) : la coche « fondateur » dans le menu de ligne des Comptes
// (ADM-08), vues Direction et Enseignants, pour un membre du personnel au
// compte actif. Le libelle dit l'etat ; le geste passe par le port ; le retour
// local suit la reponse du serveur ; sans port ou sans lecture, rien n'est
// propose.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/fondateurs_supabase.dart';
import 'package:rewayah_academy/core/admin/port_fondateurs.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';

import '../../support/harnais.dart';

class _Comptes implements ServiceComptes {
  const _Comptes(this._liste);

  final List<CompteAdmin> _liste;

  @override
  Future<List<CompteAdmin>> comptes() async => _liste;
}

class _Fondateurs implements PortFondateurs {
  _Fondateurs(this.ids, {this.refus});

  final Set<String> ids;

  /// Un refus a lever au prochain geste.
  final MotifFondateurRefuse? refus;

  final List<(String, bool)> poses = <(String, bool)>[];

  @override
  Future<Set<String>> lire() async => <String>{...ids};

  @override
  Future<bool> poser(String profilId, {required bool fondateur}) async {
    poses.add((profilId, fondateur));
    if (refus case final MotifFondateurRefuse m) throw FondateurRefuse(m);
    if (fondateur) {
      ids.add(profilId);
    } else {
      ids.remove(profilId);
    }
    return fondateur;
  }
}

CompteAdmin _compte(
  String id,
  String prenom, {
  AppRole role = AppRole.teacher,
  AccountStatus etat = AccountStatus.active,
}) => CompteAdmin(
  profilId: id,
  identifiant: 'RA-26-${id.hashCode.abs() % 9000 + 1000}',
  prenom: prenom,
  nom: 'Test',
  role: role,
  etat: etat,
  inscritLe: DateTime.now().subtract(const Duration(days: 30)),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 2,
  aEnseignant: false,
  enfantsDuFoyer: 0,
);

Future<void> _monter(
  WidgetTester tester, {
  required List<CompteAdmin> comptes,
  required String vue,
  PortFondateurs? port,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hote(
      ComptesPage(requete: <String, String>{'vue': vue}),
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(_Comptes(comptes)),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        if (port != null) portFondateursProvider.overrideWithValue(port),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

/// Aucune coche « fondateur » sur la ligne de [nom]. Depuis la suppression de
/// comptes (PR 210), une ligne d'eleve, de tuteur ou d'enseignant porte un
/// menu (« Supprimer ce compte ») : on ouvre ce menu et on n'y trouve aucune
/// entree de fondateur. Sans menu, rien a ouvrir.
Future<void> _sansCoche(WidgetTester tester, String nom) async {
  final Finder menu = find.byWidgetPredicate(
    (Widget w) => w is MenuActions && w.objet == '$nom Test',
  );
  if (menu.evaluate().isNotEmpty) {
    await _ouvrirMenu(tester, nom);
    expect(find.text('Supprimer ce compte'), findsOneWidget);
  }
  expect(find.text('Marquer comme fondateur'), findsNothing);
  expect(find.text('Retirer des fondateurs'), findsNothing);
}

Future<void> _ouvrirMenu(WidgetTester tester, String nom) async {
  await tester.tap(
    find.byWidgetPredicate(
      (Widget w) => w is MenuActions && w.objet == '$nom Test',
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('Adaptateur', () {
    test('les identifiants rendus, en liste ou en lignes', () {
      expect(fondateursDepuisJson(<Object?>['a', 'b', '']), <String>{'a', 'b'});
      expect(
        fondateursDepuisJson(<Object?>[
          <String, Object?>{'fondateurs_personnel': 'c'},
        ]),
        <String>{'c'},
      );
      expect(fondateursDepuisJson(null), isEmpty);
    });

    test('les refus du serveur', () {
      expect(motifFondateurRefuse('42501'), MotifFondateurRefuse.nonAutorise);
      expect(
        motifFondateurRefuse('22023'),
        MotifFondateurRefuse.personnelInactif,
      );
      expect(motifFondateurRefuse('XX000'), MotifFondateurRefuse.inconnu);
    });
  });

  group('Menu de ligne, bureau 1440', () {
    testWidgets('vue Enseignants : le libelle suit la coche', (tester) async {
      final _Fondateurs port = _Fondateurs(<String>{'p-hafsa'});
      await _monter(
        tester,
        comptes: <CompteAdmin>[
          _compte('p-hafsa', 'Hafsa'),
          _compte('p-yusuf', 'Yusuf'),
        ],
        vue: 'enseignants',
        port: port,
      );
      await _ouvrirMenu(tester, 'Hafsa');
      expect(find.text('Retirer des fondateurs'), findsOneWidget);
      expect(find.text('Marquer comme fondateur'), findsNothing);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      await _ouvrirMenu(tester, 'Yusuf');
      expect(find.text('Marquer comme fondateur'), findsOneWidget);
      await tester.tap(find.text('Marquer comme fondateur'));
      await tester.pumpAndSettle();
      expect(port.poses, <(String, bool)>[('p-yusuf', true)]);
      expect(
        find.text(
          '\u2068Yusuf Test\u2069 compte désormais parmi les fondateurs.',
        ),
        findsOneWidget,
      );

      // Relue apres le geste : la ligne propose maintenant de retirer.
      await _ouvrirMenu(tester, 'Yusuf');
      expect(find.text('Retirer des fondateurs'), findsOneWidget);
    });

    testWidgets('vue Direction : retirer, puis le retour local', (
      tester,
    ) async {
      final _Fondateurs port = _Fondateurs(<String>{'p-asma'});
      await _monter(
        tester,
        comptes: <CompteAdmin>[_compte('p-asma', 'Asma', role: AppRole.admin)],
        vue: 'direction',
        port: port,
      );
      await _ouvrirMenu(tester, 'Asma');
      await tester.tap(find.text('Retirer des fondateurs'));
      await tester.pumpAndSettle();
      expect(port.poses, <(String, bool)>[('p-asma', false)]);
      expect(
        find.text('\u2068Asma Test\u2069 ne compte plus parmi les fondateurs.'),
        findsOneWidget,
      );
    });

    testWidgets('un refus du serveur est dit, rien ne change', (tester) async {
      final _Fondateurs port = _Fondateurs(
        <String>{},
        refus: MotifFondateurRefuse.personnelInactif,
      );
      await _monter(
        tester,
        comptes: <CompteAdmin>[_compte('p-hafsa', 'Hafsa')],
        vue: 'enseignants',
        port: port,
      );
      await _ouvrirMenu(tester, 'Hafsa');
      await tester.tap(find.text('Marquer comme fondateur'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Seul un membre du personnel au compte actif peut être fondateur.',
        ),
        findsOneWidget,
      );
      expect(port.ids, isEmpty);
    });

    testWidgets('pas de coche pour un compte qui n est pas actif', (
      tester,
    ) async {
      await _monter(
        tester,
        comptes: <CompteAdmin>[
          _compte('p-maryam', 'Maryam', etat: AccountStatus.provisionalActive),
        ],
        vue: 'enseignants',
        port: _Fondateurs(<String>{}),
      );
      await _sansCoche(tester, 'Maryam');
    });

    testWidgets('sans port branche : aucune coche, aucun menu vide', (
      tester,
    ) async {
      await _monter(
        tester,
        comptes: <CompteAdmin>[_compte('p-hafsa', 'Hafsa')],
        vue: 'enseignants',
      );
      await _sansCoche(tester, 'Hafsa');
    });

    testWidgets('vue Eleves : jamais de coche', (tester) async {
      await _monter(
        tester,
        comptes: <CompteAdmin>[
          _compte('p-eleve', 'Hakim', role: AppRole.student),
        ],
        vue: 'eleves',
        port: _Fondateurs(<String>{}),
      );
      await _sansCoche(tester, 'Hakim');
    });
  });
}
