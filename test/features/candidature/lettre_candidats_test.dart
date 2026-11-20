// LETTRE-CANDIDATS (directeur, 20/11/2026) : la lettre aux candidats
// enseignants, page interne partageable par lien, un seul Praxis en tete.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/candidature/lettre/lettre_candidats_page.dart';
import 'package:rewayah_academy/features/candidature/lettre/praxis_lettre.dart';
import 'package:rewayah_academy/features/candidature/lettre/texte_lettre.dart';
import 'package:rewayah_academy/features/candidature/praxis_candidat.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';
import 'hote_candidature.dart';

SessionState _session(AccountStatus statut, {AppRole role = AppRole.teacher}) =>
    SessionState(
      resolue: true,
      profileId: 'p1',
      role: role,
      accountStatus: statut,
      lectureProfil: LectureProfil.presente,
    );

class _Candidat extends SessionControleur {
  @override
  SessionState build() => _session(AccountStatus.pendingKyc);
}

class _Actif extends SessionControleur {
  @override
  SessionState build() => _session(AccountStatus.active);
}

Future<void> _monter(
  WidgetTester tester, {
  bool candidat = true,
  bool accordsFaits = true,
  Size taille = const Size(390, 844),
  double echelle = 1,
  TextDirection? direction,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.lettreEnseignants,
      echelle: echelle,
      direction: direction,
      routes: <RouteBase>[
        GoRoute(
          path: Routes.lettreEnseignants,
          builder: (BuildContext _, GoRouterState _) =>
              const LettreCandidatsPage(),
        ),
        ...routesCandidature(),
      ],
      surcharges: <Override>[
        ...surchargesCandidature(
          port: FauxMaCandidature(),
          etat: etatCandidat(
            candidature: candidatureAFaire(),
            accordsFaits: accordsFaits,
          ),
        ),
        sessionProvider.overrideWith(candidat ? _Candidat.new : _Actif.new),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('la page', () {
    testWidgets('accords acceptes : la lettre, son sommaire, UN seul Praxis', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      expect(find.byKey(ContenuLettre.cleSommaire), findsOneWidget);
      expect(find.byKey(LettreCandidatsPage.cleVerrou), findsNothing);
      expect(find.byType(PraxisLettre), findsOneWidget);
      expect(find.byType(AvatarPraxisCandidat), findsOneWidget);
      expect(find.text(t.recrutement.lettre.praxis.accueil), findsOneWidget);
    });

    testWidgets('Praxis suit la partie lue et reste seul', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      await tester.scrollUntilVisible(
        find.byKey(ContenuLettre.clePartie(4)),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text(t.recrutement.lettre.praxis.paie), findsOneWidget);
      expect(find.byType(AvatarPraxisCandidat), findsOneWidget);
    });

    testWidgets('accords manquants : le verrou, sans Praxis ni lettre', (
      WidgetTester tester,
    ) async {
      await _monter(tester, accordsFaits: false);
      expect(find.byKey(LettreCandidatsPage.cleVerrou), findsOneWidget);
      expect(find.byKey(ContenuLettre.cleSommaire), findsNothing);
      expect(find.byType(PraxisLettre), findsNothing);
      expect(
        find.textContaining(t.recrutement.lettre.manqueContrat),
        findsOneWidget,
      );
      await tester.tap(find.text(t.recrutement.lettre.completer));
      await tester.pumpAndSettle();
      expect(find.text('PAGE DES ACCORDS'), findsOneWidget);
    });

    testWidgets('un compte actif lit la lettre sans condition', (
      WidgetTester tester,
    ) async {
      await _monter(tester, candidat: false, accordsFaits: false);
      expect(find.byKey(ContenuLettre.cleSommaire), findsOneWidget);
      expect(find.byKey(LettreCandidatsPage.cleVerrou), findsNothing);
    });

    testWidgets('320 points, texte x2 : rien ne deborde', (
      WidgetTester tester,
    ) async {
      await _monter(tester, taille: const Size(320, 640), echelle: 2);
      expect(tester.takeException(), isNull);
      expect(find.byType(PraxisLettre), findsOneWidget);
    });

    testWidgets('en arabe, de droite a gauche', (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      await _monter(tester, direction: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      expect(find.text(t.recrutement.lettre.sommaire), findsOneWidget);
    });
  });

  group('le texte', () {
    test('les quatorze parties existent dans les trois langues', () async {
      for (final AppLocale l in <AppLocale>[
        AppLocale.fr,
        AppLocale.en,
        AppLocale.ar,
      ]) {
        await LocaleSettings.setLocale(l);
        final List<(String, String)> p = partiesLettre();
        expect(p, hasLength(14));
        expect(p.every(((String, String) x) => x.$1.isNotEmpty), isTrue);
        expect(p.every(((String, String) x) => x.$2.isNotEmpty), isTrue);
      }
    });

    test('lireCorps reconnait sous-titre, listes, tableau et paragraphe', () {
      final List<BlocLettre> b = lireCorps(
        'Un **gras**.\n\n### Titre\n\n- a\n- b\n\n1. un\n2. deux\n\n'
        '| | A | B |\n| --- | --- | --- |\n| X | 1 | 2 |',
      );
      expect(b[0], isA<ParagrapheLettre>());
      expect(b[1], isA<SousTitreLettre>());
      expect((b[2] as ListeLettre).numerotee, isFalse);
      expect((b[3] as ListeLettre).elements, <String>['un', 'deux']);
      final TableauLettre tab = b[4] as TableauLettre;
      expect(tab.entete, <String>['', 'A', 'B']);
      expect(tab.lignes.single, <String>['X', '1', '2']);
    });

    test('le tableau de la paie se lit dans chaque langue', () async {
      for (final AppLocale l in <AppLocale>[
        AppLocale.fr,
        AppLocale.en,
        AppLocale.ar,
      ]) {
        await LocaleSettings.setLocale(l);
        final TableauLettre tab = lireCorps(partiesLettre()[3].$2)
            .whereType<TableauLettre>()
            .single;
        expect(tab.lignes, hasLength(8));
        expect(tab.lignes.every((List<String> r) => r.length == 3), isTrue);
      }
    });

    test('Praxis : le moment de chaque partie', () {
      expect(MomentLettre.pourPartie(1), MomentLettre.accueil);
      expect(MomentLettre.pourPartie(3), MomentLettre.accueil);
      expect(MomentLettre.pourPartie(5), MomentLettre.paie);
      expect(MomentLettre.pourPartie(6), MomentLettre.retard);
      expect(MomentLettre.pourPartie(10), MomentLettre.piece);
      expect(MomentLettre.pourPartie(13), MomentLettre.moi);
      expect(MomentLettre.pourPartie(14), MomentLettre.fin);
    });
  });

  group('le lien partage', () {
    final DateTime maintenant = DateTime(2026, 11, 20);
    String? decider(SessionState s, String chemin, {String? retour}) =>
        deciderRedirection(
          session: s,
          cheminDemande: chemin,
          maintenant: maintenant,
          retour: retour,
        );

    test('sans connexion : la connexion, qui garde la destination', () {
      expect(
        decider(const SessionState.deconnecte(), Routes.lettreEnseignants),
        Uri(
          path: Routes.connexion,
          queryParameters: <String, String>{'retour': Routes.lettreEnseignants},
        ).toString(),
      );
    });

    test('un candidat en attente l\'ouvre, et y revient apres connexion', () {
      final SessionState s = _session(AccountStatus.pendingKyc);
      expect(decider(s, Routes.lettreEnseignants), isNull);
      expect(
        decider(s, Routes.connexion, retour: Routes.lettreEnseignants),
        Routes.lettreEnseignants,
      );
    });

    test('un compte suspendu ne l\'ouvre pas', () {
      expect(
        decider(_session(AccountStatus.disabled), Routes.lettreEnseignants),
        Routes.attente,
      );
    });

    test('seul l\'enseignant actif l\'ouvre ; famille et direction non', () {
      expect(
        decider(_session(AccountStatus.active), Routes.lettreEnseignants),
        isNull,
      );
      for (final AppRole r in <AppRole>[AppRole.guardian, AppRole.admin]) {
        expect(
          decider(
            _session(AccountStatus.active, role: r),
            Routes.lettreEnseignants,
          ),
          isNotNull,
          reason: r.name,
        );
      }
    });

    test('une famille en attente ne l\'ouvre pas', () {
      expect(
        decider(
          _session(AccountStatus.pendingKyc, role: AppRole.guardian),
          Routes.lettreEnseignants,
        ),
        Routes.attente,
      );
    });
  });
}
