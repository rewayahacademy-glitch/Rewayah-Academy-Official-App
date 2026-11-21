// PERSONNES-UNE-PAGE, etape (a) (directeur, 20/11/2026) : dans Comptes, la
// ligne entiere s'ouvre, et le menu « ... » reste. Un eleve, une famille ou un
// membre de la direction n'a pas de fiche : la ligne ouvre l'apercu (les
// informations de la vue, les gestes du menu). Un enseignant qui a un dossier
// ouvre son dossier. Toucher « ... » ouvre le menu, jamais la ligne.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/features/admin_candidature/references_dossiers.dart';
import 'package:rewayah_academy/features/admin_comptes/apercu_compte.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';

import '../../support/harnais.dart';

class _Comptes implements ServiceComptes {
  const _Comptes(this._liste);

  final List<CompteAdmin> _liste;

  @override
  Future<List<CompteAdmin>> comptes() async => _liste;
}

class _References implements PortReferencesDossiers {
  const _References(this._table);

  final Map<String, String> _table;

  @override
  Future<Map<String, String>> references(List<String> profils) async =>
      <String, String>{
        for (final String p in profils)
          if (_table[p] case final String r) p: r,
      };
}

CompteAdmin _compte(
  String id,
  String prenom, {
  required AppRole role,
  bool admission = false,
}) => CompteAdmin(
  profilId: id,
  identifiant: 'RA-26-4${id.codeUnitAt(0)}',
  prenom: prenom,
  nom: 'Essai',
  role: role,
  etat: admission ? AccountStatus.pendingKyc : AccountStatus.active,
  inscritLe: DateTime.now().subtract(const Duration(days: 12)),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 0,
  aEnseignant: false,
  enfantsDuFoyer: 0,
  detailsServis: true,
  tranche: role == AppRole.student ? TrancheAge.enfant : null,
  admissionATraiter: admission,
);

const String _dossier = '/dossier';
const String _demandes = '/admin/personnes/demandes';

Future<List<String>> _monter(
  WidgetTester tester, {
  required List<CompteAdmin> comptes,
  required String vue,
  Size taille = const Size(1440, 900),
  Map<String, String> references = const <String, String>{},
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.reset);
  final List<String> ouverts = <String>[];
  Widget temoin(String nom, GoRouterState etat) {
    ouverts.add(etat.uri.path);
    return Text('page $nom');
  }

  await tester.pumpWidget(
    hoteRoutant(
      depart: '/comptes',
      routes: <RouteBase>[
        GoRoute(
          path: '/comptes',
          builder: (BuildContext _, GoRouterState _) =>
              ComptesPage(requete: <String, String>{'vue': vue}),
        ),
        GoRoute(
          path: '/admin/personnes/candidatures/:reference',
          builder: (BuildContext _, GoRouterState e) => temoin(_dossier, e),
        ),
        GoRoute(
          path: _demandes,
          builder: (BuildContext _, GoRouterState e) => temoin(_demandes, e),
        ),
      ],
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(_Comptes(comptes)),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
        portReferencesDossiersProvider.overrideWithValue(
          _References(references),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return ouverts;
}

Finder _menuDe(String nom) => find.byWidgetPredicate(
  (Widget w) => w is MenuActions && w.objet == '$nom Essai',
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  for (final (String nom, Size taille) in <(String, Size)>[
    ('ordinateur', const Size(1440, 900)),
    ('telephone', const Size(390, 844)),
  ]) {
    testWidgets('$nom : la ligne d\'un eleve ouvre l\'apercu, avec ses '
        'informations et les gestes du menu qui n\'effacent rien', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        vue: 'eleves',
        taille: taille,
        comptes: <CompteAdmin>[
          _compte('a', 'Amina', role: AppRole.student, admission: true),
          _compte('b', 'Bilal', role: AppRole.student),
        ],
      );
      expect(find.byKey(cleApercuCompte), findsNothing);

      await tester.tap(find.text('Amina Essai').first);
      await tester.pumpAndSettle();

      final Finder apercu = find.byKey(cleApercuCompte);
      expect(apercu, findsOneWidget);
      // Les informations de la vue : l'age, la classe, l'anciennete.
      expect(
        find.descendant(of: apercu, matching: find.text('Enfant')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: apercu,
          matching: find.text(t.admin.comptes.classeAucune),
        ),
        findsOneWidget,
      );
      // Les gestes du menu de la ligne, les memes.
      expect(
        find.descendant(
          of: apercu,
          matching: find.text(t.admin.comptes.actionVoirDemande),
        ),
        findsOneWidget,
      );
      // Le geste qui efface n'est pas dans l'apercu : il reste dans le menu.
      expect(
        find.descendant(
          of: apercu,
          matching: find.text(t.admin.comptes.retrait.actionLigne),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('un geste de l\'apercu le ferme, puis se lance', (
    WidgetTester tester,
  ) async {
    final List<String> ouverts = await _monter(
      tester,
      vue: 'eleves',
      comptes: <CompteAdmin>[
        _compte('a', 'Amina', role: AppRole.student, admission: true),
      ],
    );
    await tester.tap(find.text('Amina Essai').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(cleGesteApercuCompte(0)));
    await tester.pumpAndSettle();

    expect(find.byKey(cleApercuCompte), findsNothing);
    expect(ouverts, <String>[_demandes]);
  });

  testWidgets(
    'le menu « ... » reste : le toucher ouvre le menu, pas la ligne',
    (WidgetTester tester) async {
      await _monter(
        tester,
        vue: 'eleves',
        comptes: <CompteAdmin>[
          _compte('a', 'Amina', role: AppRole.student, admission: true),
        ],
      );
      expect(_menuDe('Amina'), findsOneWidget);
      await tester.tap(_menuDe('Amina'));
      await tester.pumpAndSettle();

      expect(find.byKey(cleApercuCompte), findsNothing);
      expect(find.text(t.admin.comptes.actionVoirDemande), findsOneWidget);
    },
  );

  testWidgets('la ligne d\'un enseignant qui a un dossier ouvre son dossier, '
      'sans apercu', (WidgetTester tester) async {
    final List<String> ouverts = await _monter(
      tester,
      vue: 'enseignants',
      comptes: <CompteAdmin>[_compte('e', 'Esma', role: AppRole.teacher)],
      references: const <String, String>{'e': 'CAND-00042'},
    );
    await tester.tap(find.text('Esma Essai').first);
    await tester.pumpAndSettle();

    expect(find.byKey(cleApercuCompte), findsNothing);
    expect(ouverts, <String>['/admin/personnes/candidatures/CAND-00042']);
  });

  testWidgets('la ligne d\'un membre de la direction, sans geste : l\'apercu '
      'dit ses informations, sans bouton', (WidgetTester tester) async {
    await _monter(
      tester,
      vue: 'direction',
      comptes: <CompteAdmin>[_compte('d', 'Driss', role: AppRole.admin)],
    );
    await tester.tap(find.text('Driss Essai').first);
    await tester.pumpAndSettle();

    expect(find.byKey(cleApercuCompte), findsOneWidget);
    expect(find.byKey(cleGesteApercuCompte(0)), findsNothing);
  });
}
