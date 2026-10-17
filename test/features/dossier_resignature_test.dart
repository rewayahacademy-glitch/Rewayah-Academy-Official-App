// Q-2 = a (decision du directeur du 05/10/2026, JUR-LIEN-385-1) : quand la
// politique de controle est publiee, un enseignant qui a signe le contrat
// 2026-09 signe la nouvelle version 2026-10-jur a sa prochaine entree, avec
// une phrase courte qui dit pourquoi. Tant que l'interrupteur reste faux,
// rien ne change.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/etat_dossier.dart';
import 'package:rewayah_academy/core/dossier/resignature_contrat.dart';
import 'package:rewayah_academy/core/dossier/service_dossier.dart';
import 'package:rewayah_academy/core/dossier/versions_contrat.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';

import '../support/harnais.dart';

Acceptation _signee(SorteContrat sorte, String version) =>
    Acceptation(sorte: sorte, version: version, accepteeLe: DateTime(2026, 9));

final List<Acceptation> _signe2026_09 = <Acceptation>[
  _signee(
    SorteContrat.accuseEnregistrementControle,
    VersionsContrat.textesJuridiques,
  ),
  _signee(SorteContrat.contratEnseignant, VersionsContrat.courante),
];

SessionState _etat(AppRole role, AccountStatus statut) => SessionState(
  resolue: true,
  role: role,
  profileId: 'p1',
  accountStatus: statut,
  lectureProfil: LectureProfil.presente,
);

class _Session extends SessionControleur {
  _Session(this._role, this._statut);

  final AppRole _role;
  final AccountStatus _statut;

  @override
  SessionState build() => _etat(_role, _statut);
}

List<Override> _surcharges({
  required bool publiee,
  required List<Acceptation> Function() lues,
  AppRole role = AppRole.teacher,
  AccountStatus statut = AccountStatus.active,
}) => <Override>[
  politiqueControlePublieeProvider.overrideWithValue(publiee),
  sessionProvider.overrideWith(() => _Session(role, statut)),
  acceptationsProvider.overrideWith((_) async => lues()),
];

void main() {
  group('Qui doit signer de nouveau', () {
    test('politique non publiee : personne, meme signataire de 2026-09', () {
      expect(
        contratEnseignantARessigner(_signe2026_09, politiquePubliee: false),
        isFalse,
      );
    });

    test('politique publiee : le signataire de 2026-09', () {
      expect(
        contratEnseignantARessigner(_signe2026_09, politiquePubliee: true),
        isTrue,
      );
    });

    test('politique publiee : pas celui qui a deja signe 2026-10-jur', () {
      expect(
        contratEnseignantARessigner(<Acceptation>[
          ..._signe2026_09,
          _signee(
            SorteContrat.contratEnseignant,
            VersionsContrat.textesJuridiques,
          ),
        ], politiquePubliee: true),
        isFalse,
      );
    });

    test('politique publiee : pas un compte sans contrat enseignant signe '
        '(il passe par le portail comme avant), ni un tuteur', () {
      expect(
        contratEnseignantARessigner(
          const <Acceptation>[],
          politiquePubliee: true,
        ),
        isFalse,
      );
      expect(
        contratEnseignantARessigner(<Acceptation>[
          _signee(SorteContrat.conditionsTuteur, VersionsContrat.courante),
        ], politiquePubliee: true),
        isFalse,
      );
    });

    test("l'interrupteur du depot est lu par le provider", () {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      expect(
        c.read(politiqueControlePublieeProvider),
        VersionsContrat.politiqueControlePubliee,
      );
    });

    for (final bool publiee in <bool>[false, true]) {
      test('provider, politique ${publiee ? '' : 'non '}publiee : '
          'enseignant signataire de 2026-09 -> $publiee', () async {
        int lectures = 0;
        final ProviderContainer c = ProviderContainer(
          overrides: _surcharges(
            publiee: publiee,
            lues: () {
              lectures++;
              return _signe2026_09;
            },
          ),
        );
        addTearDown(c.dispose);
        final ProviderSubscription<bool> abonnement = c.listen<bool>(
          resignatureContratEnseignantProvider,
          (bool? _, bool _) {},
        );
        addTearDown(abonnement.close);
        await c.read(acceptationsProvider.future);
        expect(c.read(resignatureContratEnseignantProvider), publiee);
        if (!publiee) {
          // Rien ne change : le provider ne demande meme pas les
          // acceptations (la lecture ci-dessus est celle du test).
          expect(lectures, 1);
        }
      });
    }

    test('provider : un tuteur avec les memes lignes -> faux', () async {
      final ProviderContainer c = ProviderContainer(
        overrides: _surcharges(
          publiee: true,
          role: AppRole.guardian,
          lues: () => _signe2026_09,
        ),
      );
      addTearDown(c.dispose);
      await c.read(acceptationsProvider.future);
      expect(c.read(resignatureContratEnseignantProvider), isFalse);
    });
  });

  group('La redirection : la signature a la prochaine entree', () {
    final DateTime maintenant = DateTime.utc(2026, 10, 6, 10);
    String? decider(
      String chemin, {
      required bool resignature,
      AppRole role = AppRole.teacher,
      AccountStatus statut = AccountStatus.active,
    }) => deciderRedirection(
      session: _etat(role, statut),
      cheminDemande: chemin,
      maintenant: maintenant,
      resignatureContrat: resignature,
    );

    test('enseignant actif a re-signer : tout chemin mene au contrat', () {
      for (final String chemin in <String>[
        Routes.enseignantJournee,
        Routes.enseignantClasses,
        Routes.compte,
        Routes.racine,
        Routes.connexion,
      ]) {
        expect(
          decider(chemin, resignature: true),
          Routes.enseignantContrat,
          reason: chemin,
        );
      }
      expect(decider(Routes.enseignantContrat, resignature: true), isNull);
    });

    test(
      'sans re-signature : rien ne change, la page du contrat est fermee',
      () {
        expect(decider(Routes.enseignantJournee, resignature: false), isNull);
        expect(
          decider(Routes.enseignantContrat, resignature: false),
          Routes.enseignantJournee,
        );
      },
    );

    // Lot E6 (decision du directeur du 17/10/2026) : la nouvelle signature se
    // fait sur la page unique des accords.
    test('enseignant en attente a re-signer : la page des accords', () {
      expect(
        decider(
          Routes.attente,
          resignature: true,
          statut: AccountStatus.pendingKyc,
        ),
        Routes.attenteAccords,
      );
      expect(
        decider(
          Routes.attenteAccords,
          resignature: true,
          statut: AccountStatus.pendingKyc,
        ),
        isNull,
      );
      expect(
        decider(
          Routes.attente,
          resignature: false,
          statut: AccountStatus.pendingKyc,
        ),
        isNull,
      );
    });

    test('un autre role n est jamais concerne', () {
      expect(
        decider(
          Routes.racinePour(AppRole.guardian),
          resignature: true,
          role: AppRole.guardian,
        ),
        isNot(Routes.enseignantContrat),
      );
    });
  });

  group("L'ecran de signature", () {
    Future<FauxServiceDossier> monter(
      WidgetTester tester, {
      required bool publiee,
      required List<Acceptation> Function() lues,
    }) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = const EtatDossier(
          profilExiste: true,
          role: AppRole.teacher,
          statutCompte: AccountStatus.active,
          accuseSigne: true,
          contratSigne: true,
        );
      await tester.pumpWidget(
        hoteRoutant(
          depart: Routes.enseignantContrat,
          routes: <RouteBase>[
            GoRoute(
              path: Routes.enseignantContrat,
              builder: (BuildContext _, GoRouterState _) => const ContratPage(),
            ),
            GoRoute(
              path: Routes.attente,
              builder: (BuildContext _, GoRouterState _) =>
                  const Scaffold(body: Text('suite')),
            ),
          ],
          surcharges: <Override>[
            serviceDossierProvider.overrideWithValue(dossier),
            ..._surcharges(publiee: publiee, lues: lues),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return dossier;
    }

    testWidgets('politique publiee, 2026-09 signe : la phrase dit pourquoi, '
        "l'enseignant signe 2026-10-jur", (WidgetTester tester) async {
      List<Acceptation> lignes = _signe2026_09;
      int lectures = 0;
      final FauxServiceDossier dossier = await monter(
        tester,
        publiee: true,
        lues: () {
          lectures++;
          return lignes;
        },
      );
      expect(find.text(t.contrat.resignature), findsOneWidget);
      expect(find.text(t.contrat.clauseControle.texte), findsOneWidget);

      final Finder caseReligion = find.text(
        t.contrat.clauseControle.caseReligion,
      );
      await tester.ensureVisible(caseReligion);
      await tester.tap(caseReligion);
      await tester.pumpAndSettle();
      final int avant = lectures;
      lignes = <Acceptation>[
        ..._signe2026_09,
        _signee(
          SorteContrat.contratEnseignant,
          VersionsContrat.textesJuridiques,
        ),
      ];
      await tester.tap(find.text(t.contrat.accepter));
      await tester.pumpAndSettle();
      expect(dossier.versionsAcceptees, <String>[
        VersionsContrat.textesJuridiques,
      ]);
      // Les acceptations sont relues avant de partir : la redirection ne
      // ramene pas sur le contrat.
      expect(lectures, greaterThan(avant));
      expect(find.text('suite'), findsOneWidget);
    });

    testWidgets('politique non publiee : aucune phrase, rien ne change '
        '(version 2026-09 hors demonstration)', (WidgetTester tester) async {
      final FauxServiceDossier dossier = await monter(
        tester,
        publiee: false,
        lues: () => _signe2026_09,
      );
      expect(find.text(t.contrat.resignature), findsNothing);
      expect(find.text(t.contrat.intro), findsOneWidget);
      await tester.tap(find.text(t.contrat.accepter));
      await tester.pumpAndSettle();
      expect(dossier.versionsAcceptees, <String>[VersionsContrat.courante]);
    });
  });
}
