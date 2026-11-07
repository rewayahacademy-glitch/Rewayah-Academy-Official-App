// SUPPRIMER (garde-cap, 03/11/2026, PLAN-LOTS §12) : dans Comptes, la
// direction choisit des comptes de la page, confirme avec leur nombre, et lit
// le resultat de chaque compte. Une seule action pleine ; aucun geste sur une
// ligne qu'on ne voit pas ; la liste est relue apres chaque suppression.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/capacites/permission_insuffisante.dart';
import 'package:rewayah_academy/core/capacites/port_retraits_comptes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/widgets/barre_selection.dart';
import 'package:rewayah_academy/core/widgets/case_a_cocher.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/mfa_controleur/double_verification.dart';
import 'package:rewayah_academy/features/mfa_controleur/port_mfa.dart';

import '../support/garde_interface.dart';
import '../support/harnais.dart';

class _Service implements ServiceComptes {
  _Service(this.lus);
  List<CompteAdmin> lus;
  int lectures = 0;

  @override
  Future<List<CompteAdmin>> comptes() async {
    lectures++;
    return lus;
  }
}

class _Port implements PortRetraitsComptes {
  _Port(this.reponse);
  final Future<List<ResultatRetrait>> Function(List<String>) reponse;
  final List<List<String>> envois = <List<String>>[];

  @override
  Future<List<ResultatRetrait>> retirer(
    List<String> ids, {
    String? motif,
    bool anonymiserMaintenant = false,
  }) {
    envois.add(ids);
    return reponse(ids);
  }

  @override
  Future<PageRetraits> lister({
    EtatRetraits etat = EtatRetraits.enCours,
    CurseurRetraits? apres,
  }) => throw UnimplementedError();

  @override
  Future<List<ResultatRestauration>> restaurer(List<String> ids) =>
      throw UnimplementedError();

  @override
  Future<ResultatSuppressionEnfant> supprimerProfilEnfant(String eleveId) =>
      throw UnimplementedError();
}

CompteAdmin _eleve(String id, String prenom, String nom) => CompteAdmin(
  profilId: 'p-$id',
  identifiant: id,
  prenom: prenom,
  nom: nom,
  role: AppRole.student,
  etat: AccountStatus.active,
  inscritLe: DateTime.now().subtract(const Duration(days: 10)),
  accesJusquAu: null,
  foyerId: null,
  piece: EtatPiece.aucune,
  contrats: 0,
  aEnseignant: false,
  enfantsDuFoyer: 0,
  detailsServis: true,
);

final List<CompteAdmin> _trois = <CompteAdmin>[
  _eleve('STUDENT-AA-000001', 'Lina', 'Diallo'),
  _eleve('STUDENT-AA-000002', 'Yacine', 'Kane'),
  _eleve('STUDENT-AA-000003', 'Sara', 'Ba'),
];

Future<(_Service, _Port)> _monter(
  WidgetTester tester,
  Future<List<ResultatRetrait>> Function(List<String>) reponse, {
  Size taille = const Size(1440, 900),
  bool horsLigne = false,
  List<CompteAdmin>? comptes,
  InterfaceMode mode = InterfaceMode.standard,
  List<Override> plus = const <Override>[],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = taille;
  addTearDown(tester.view.reset);
  final _Service service = _Service(comptes ?? _trois);
  final _Port port = _Port(reponse);
  await tester.pumpWidget(
    hote(
      MediaQuery(
        data: MediaQueryData(size: taille),
        child: const ComptesPage(requete: <String, String>{'vue': 'eleves'}),
      ),
      surcharges: <Override>[
        serviceComptesProvider.overrideWithValue(service),
        portRetraitsComptesProvider.overrideWithValue(port),
        serviceReseauProvider.overrideWithValue(
          FauxServiceReseau(horsLigneRendu: horsLigne),
        ),
        ...plus,
      ],
      mode: mode,
    ),
  );
  await tester.pumpAndSettle();
  return (service, port);
}

Future<void> _cocher(WidgetTester tester, String nom) async {
  final Finder f = find
      .byWidgetPredicate(
        (Widget w) => w is CaseACocher && w.libelle.startsWith('Cocher $nom'),
      )
      .first;
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  // SANS-BARRE-FIXE (decision du garde-cap, 07/11) : la barre des comptes
  // choisis est la seule chose collee en bas, et seulement pendant une
  // selection : une ligne de 56 dp au plus, absente sans selection, sans
  // jamais cacher le dernier compte de la liste.
  // Option (A) du garde-cap (07/11) : sur telephone (< 640 px), la barre
  // vient dans le fil, en tete de la liste ; rien n'est colle en bas.
  testWidgets('SANS-BARRE-FIXE 390 px : la barre de selection est dans le '
      'fil, en tete de la liste, rien de colle', (tester) async {
    await _monter(
      tester,
      (List<String> _) async => <ResultatRetrait>[],
      taille: const Size(390, 844),
      // Assez de lignes pour que la liste defile sous la barre.
      comptes: <CompteAdmin>[
        ..._trois,
        for (int i = 1; i <= 12; i++) _eleve('x$i', 'Prenom', 'Eleve $i'),
      ],
    );
    await _cocher(tester, 'Lina Diallo');
    expect(find.byKey(ComptesPage.barreSuppressionKey), findsOneWidget);
    expect(find.byKey(PageShell.zoneActionKey), findsNothing);
    // En tete de la liste : au-dessus du premier compte.
    expect(
      tester.getRect(find.byKey(ComptesPage.barreSuppressionKey)).bottom,
      lessThanOrEqualTo(tester.getRect(find.textContaining('Lina').first).top),
    );
    // Rien d'epingle (garde-cap, 07/11) : la barre defile avec la liste, et
    // reste au-dessus de sa premiere ligne ; elle n'en cache aucune.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    // Partie avec la liste : hors de l'arbre (lignes construites a la
    // demande) ou au-dessus de la vue ; jamais restee en place.
    final Finder barre = find.byKey(ComptesPage.barreSuppressionKey);
    expect(
      barre.evaluate().isEmpty ||
          tester.getRect(barre).bottom <=
              tester.getTopLeft(find.byType(Scrollable).first).dy,
      isTrue,
      reason: 'la barre defile avec la liste, elle n est pas epinglee',
    );
    // La premiere ligne encore visible n'est sous aucune barre.
    expect(barre.hitTestable(), findsNothing);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(ComptesPage.barreSuppressionKey),
        matching: find.byKey(BarreSelection.cleRelacher),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(ComptesPage.barreSuppressionKey), findsNothing);
  });

  for (final Size taille in <Size>[const Size(1440, 900)]) {
    testWidgets('SANS-BARRE-FIXE ${taille.width.toInt()} px : la barre de '
        'selection, une ligne, seulement pendant la selection', (tester) async {
      await _monter(
        tester,
        (List<String> _) async => <ResultatRetrait>[],
        taille: taille,
      );
      expect(find.byKey(PageShell.zoneActionKey), findsNothing);
      await _cocher(tester, 'Lina Diallo');
      final Finder zone = find.byKey(PageShell.zoneActionKey);
      expect(zone, findsOneWidget);
      final Rect barre = tester.getRect(zone);
      expect(barre.height, lessThanOrEqualTo(56), reason: 'une ligne, 56 dp');
      // Le dernier compte, amene au bas de la liste, reste au-dessus de la
      // barre : elle ne le cache jamais.
      final Finder dernier = find.textContaining('Sara').last;
      await tester.ensureVisible(dernier);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(dernier).bottom,
        lessThanOrEqualTo(tester.getRect(zone).top + 0.5),
      );
      // Rien de choisi : la barre disparait.
      await tester.tap(
        find.descendant(
          of: find.byKey(ComptesPage.barreSuppressionKey),
          matching: find.byKey(BarreSelection.cleRelacher),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ComptesPage.barreSuppressionKey), findsNothing);
      expect(find.byKey(PageShell.zoneActionKey), findsNothing);
    });
  }

  for (final Size taille in <Size>[
    const Size(1440, 900),
    const Size(390, 844),
  ]) {
    group('${taille.width.toInt()} px', () {
      testWidgets('choisir deux comptes, confirmer, lire le resultat', (
        tester,
      ) async {
        final (_Service service, _Port port) = await _monter(
          tester,
          (List<String> ids) async => <ResultatRetrait>[
            ResultatRetrait(
              id: ids[0],
              retire: true,
              anonymiserLe: DateTime(2026, 12, 3),
            ),
            ResultatRetrait(
              id: ids[1],
              retire: false,
              raison: RaisonRefusRetrait.erreur,
            ),
          ],
          taille: taille,
        );
        expect(find.byKey(ComptesPage.barreSuppressionKey), findsNothing);
        await _cocher(tester, 'Lina Diallo');
        await _cocher(tester, 'Yacine Kane');
        expect(find.text('2 comptes choisis'), findsOneWidget);
        verifierUnSeulBoutonPlein(tester);

        await tester.tap(find.byKey(ComptesPage.supprimerSelectionKey));
        await tester.pumpAndSettle();
        expect(find.text('Supprimer ces 2 comptes ?'), findsWidgets);
        // Renoncer : rien ne part.
        await tester.tap(find.text('Ne rien changer'));
        await tester.pumpAndSettle();
        expect(port.envois, isEmpty);

        await tester.tap(find.byKey(ComptesPage.supprimerSelectionKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer 2 comptes').last);
        await tester.pumpAndSettle();
        expect(port.envois.single, <String>[
          'p-STUDENT-AA-000001',
          'p-STUDENT-AA-000002',
        ]);
        expect(
          find.text(
            '1 compte est supprimé. Il est dans Personnes, Suppressions.',
          ),
          findsOneWidget,
        );
        expect(find.text("1 compte n'est pas supprimé"), findsOneWidget);
        expect(find.textContaining('Yacine Kane'), findsWidgets);
        // La liste est relue, la selection videe.
        expect(service.lectures, 2);
        expect(find.byKey(ComptesPage.barreSuppressionKey), findsNothing);
      });

      testWidgets('le menu d une ligne supprime ce seul compte', (
        tester,
      ) async {
        final (_, _Port port) = await _monter(
          tester,
          (List<String> ids) async => <ResultatRetrait>[
            ResultatRetrait(
              id: ids.single,
              retire: true,
              anonymiserLe: DateTime(2026, 12, 3),
            ),
          ],
          taille: taille,
        );
        await tester.tap(find.byType(MenuActions).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer ce compte'));
        await tester.pumpAndSettle();
        expect(find.text('Supprimer le compte de Lina Diallo ?'), findsWidgets);
        await tester.tap(find.text('Supprimer le compte').last);
        await tester.pumpAndSettle();
        expect(port.envois.single, <String>['p-STUDENT-AA-000001']);
      });
    });
  }

  testWidgets('cocher la page : seulement les comptes visibles', (
    tester,
  ) async {
    await _monter(tester, (List<String> ids) async => <ResultatRetrait>[]);
    // La case d'en-tete, puis la barre dit les trois de la page.
    await tester.tap(find.byType(CaseACocher).first);
    await tester.pumpAndSettle();
    expect(find.text('3 comptes choisis'), findsOneWidget);
  });

  testWidgets('refus de droit : la phrase dit quoi faire', (tester) async {
    await _monter(
      tester,
      (List<String> _) async => throw const PermissionInsuffisante('SUPPRIMER'),
    );
    await _cocher(tester, 'Lina Diallo');
    await tester.tap(find.byKey(ComptesPage.supprimerSelectionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer le compte').last);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Activez-la dans Compte > Sécurité'),
      findsOneWidget,
    );
  });

  testWidgets('hors ligne : rien ne part', (tester) async {
    final (_, _Port port) = await _monter(
      tester,
      (List<String> _) async => <ResultatRetrait>[],
      horsLigne: true,
    );
    await _cocher(tester, 'Lina Diallo');
    await tester.tap(find.byKey(ComptesPage.supprimerSelectionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer le compte').last);
    await tester.pumpAndSettle();
    expect(port.envois, isEmpty);
    expect(find.textContaining('le réseau est absent'), findsOneWidget);
  });

  group('DECISION-LISTES §6', () {
    final List<CompteAdmin> beaucoup = <CompteAdmin>[
      for (int i = 0; i < 30; i++)
        _eleve(
          'STUDENT-BB-${i.toString().padLeft(6, '0')}',
          'Eleve',
          'N${i.toString().padLeft(2, '0')}',
        ),
    ];

    testWidgets('une autre page garde la selection, et le compteur le dit', (
      tester,
    ) async {
      await _monter(
        tester,
        (List<String> _) async => <ResultatRetrait>[],
        comptes: beaucoup,
      );
      final SemanticsHandle voix = tester.ensureSemantics();
      await _cocher(tester, 'Eleve N');
      expect(find.text('1 compte choisi'), findsOneWidget);
      final Finder suivante = find.bySemanticsLabel('Page suivante');
      await tester.scrollUntilVisible(
        suivante,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(suivante);
      await tester.pumpAndSettle();
      expect(
        find.text('1 compte choisi, dont 0 sur cette page'),
        findsOneWidget,
      );
      voix.dispose();
    });

    testWidgets('une recherche qui change retire la selection, et le dit', (
      tester,
    ) async {
      await _monter(
        tester,
        (List<String> _) async => <ResultatRetrait>[],
        comptes: beaucoup,
      );
      await _cocher(tester, 'Eleve N');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pumpAndSettle();
      final Finder bascule = find.byKey(
        const ValueKey<String>('comptes-bascule-filtres'),
      );
      if (bascule.evaluate().isNotEmpty) {
        await tester.tap(bascule);
        await tester.pumpAndSettle();
      }
      final Finder champ = find.byKey(
        const ValueKey<String>('comptes-recherche'),
      );
      await tester.enterText(champ, 'N01');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(ComptesPage.barreSuppressionKey), findsNothing);
      expect(find.textContaining('La sélection est retirée'), findsOneWidget);
    });
  });

  testWidgets(
    'telephone en Interface guidee : ni case ni suppression (coupe-mots)',
    (tester) async {
      await _monter(
        tester,
        (List<String> _) async => <ResultatRetrait>[],
        taille: const Size(390, 844),
        mode: InterfaceMode.enfant,
      );
      expect(find.byType(CaseACocher), findsNothing);
      expect(find.byType(MenuActions), findsNothing);
    },
  );

  // MFA-DIRECTION : la direction en aal1 ; refus du serveur, feuille du code,
  // code accepte, suppression rejouee une fois.
  testWidgets(
    'direction en aal1 : le code est demande, la suppression rejouee',
    (tester) async {
      int appels = 0;
      final _Mfa mfa = _Mfa();
      final (_, _Port port) = await _monter(
        tester,
        (List<String> ids) async {
          appels++;
          if (appels == 1) throw const PermissionInsuffisante('SUPPRIMER');
          return <ResultatRetrait>[
            ResultatRetrait(
              id: ids.single,
              retire: true,
              anonymiserLe: DateTime(2026, 12, 3),
            ),
          ];
        },
        plus: <Override>[
          portMfaProvider.overrideWithValue(mfa),
          sessionProvider.overrideWith(_Direction.new),
        ],
      );
      await _cocher(tester, 'Lina Diallo');
      await tester.tap(find.byKey(ComptesPage.supprimerSelectionKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer le compte').last);
      await tester.pumpAndSettle();
      expect(find.text('Code de vérification'), findsWidgets);
      await tester.enterText(find.byKey(CleDoubleVerification.champ), '123456');
      await tester.tap(find.byKey(CleDoubleVerification.confirmer));
      await tester.pumpAndSettle();
      expect(mfa.codes, <String>['123456']);
      expect(port.envois.length, 2);
      expect(find.textContaining('1 compte est supprimé'), findsOneWidget);
    },
  );
}

class _Mfa implements PortMfa {
  final List<String> codes = <String>[];

  @override
  Future<SituationMfa> situation() async => const MfaAVerifier('f1');

  @override
  Future<EnrolementTotp> enroler() => throw UnimplementedError();

  @override
  Future<void> verifier({
    required String facteurId,
    required String code,
  }) async => codes.add(code);
}

class _Direction extends SessionControleur {
  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.admin,
    profileId: 'p-direction',
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );
}
