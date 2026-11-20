// LETTRE-CANDIDATS (directeur, 20/11/2026) : la lettre aux candidats
// enseignants, page interne partageable par lien, un seul Praxis en tete.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/redirection.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/features/candidature/lettre/lettre_candidats_page.dart';
import 'package:rewayah_academy/features/candidature/lettre/port_lettre.dart';
import 'package:rewayah_academy/features/candidature/lettre/praxis_lettre.dart';
import 'package:rewayah_academy/features/candidature/lettre/texte_lettre.dart';
import 'package:rewayah_academy/features/candidature/praxis_candidat.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';
import 'faux_port_lettre.dart';
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

Future<void> _monter(
  WidgetTester tester, {
  LectureLettre? reponse,
  Exception? erreur,
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
          etat: etatCandidat(candidature: candidatureAFaire()),
        ),
        sessionProvider.overrideWith(_Candidat.new),
        portLettreProvider.overrideWithValue(
          FauxPortLettre(reponse: reponse, erreur: erreur),
        ),
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

    testWidgets(
      'le serveur refuse (accords) : le verrou, sans Praxis ni lettre',
      (WidgetTester tester) async {
        await _monter(
          tester,
          reponse: const LectureLettre.refusee(
            raison: RaisonRefusLettre.accords,
            manques: <AccordManquant>[AccordManquant.contrat],
          ),
        );
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
      },
    );

    testWidgets('le serveur refuse (role) : une phrase, aucun texte', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        reponse: const LectureLettre.refusee(raison: RaisonRefusLettre.role),
      );
      expect(find.byKey(LettreCandidatsPage.cleReservee), findsOneWidget);
      expect(find.byKey(ContenuLettre.cleSommaire), findsNothing);
    });

    testWidgets('serveur pas encore branche : aucune lettre', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        erreur: const CapaciteIndisponible('LETTRE-SERVEUR'),
      );
      expect(find.byKey(ContenuLettre.cleSommaire), findsNothing);
      expect(find.byType(PraxisLettre), findsNothing);
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
    test('aucun texte de la lettre dans l\'application compilee', () {
      // Une phrase propre a la lettre, par langue : elle ne vient que du
      // serveur.
      const Map<String, String> phrases = <String, String>{
        'fr': 'Douze élèves s',
        'en': 'Twelve students sign up',
        'ar': 'اثنا عشر طالبًا',
      };
      for (final MapEntry<String, String> e in phrases.entries) {
        final String brut = File('assets/i18n/${e.key}.i18n.json')
            .readAsStringSync();
        expect(brut.contains(e.value), isFalse, reason: e.key);
        expect(
          File('docs/current/CANDIDATURES/LETTRE-CANDIDATS/LETTRE-${e.key}.md')
              .readAsStringSync()
              .contains(e.value),
          isTrue,
          reason: 'la phrase temoin existe dans le texte du depot',
        );
      }
    });

    test('les quatorze parties existent dans les trois langues du depot', () {
      for (final String l in <String>['fr', 'en', 'ar']) {
        final List<PartieLettre> p = partiesDuDepot(l);
        expect(p, hasLength(14), reason: l);
        expect(p.every((PartieLettre x) => x.titre.isNotEmpty), isTrue);
        expect(p.every((PartieLettre x) => x.corps.isNotEmpty), isTrue);
      }
    });

    test('la reponse du serveur se lit, et une forme inconnue est refusee', () {
      final LectureLettre ouverte = LectureLettre.depuisJson(<String, dynamic>{
        'acces': true,
        'version': '2026-11-20',
        'langue': 'fr',
        'parties': <Map<String, dynamic>>[
          <String, dynamic>{'code': 'p1', 'titre': 'T', 'corps': 'C'},
        ],
      });
      expect(ouverte.acces, isTrue);
      expect(ouverte.parties.single.code, 'p1');
      final LectureLettre refusee = LectureLettre.depuisJson(<String, dynamic>{
        'acces': false,
        'raison': 'accords',
        'manques': <String>['contrat', 'cadre'],
      });
      expect(refusee.parties, isEmpty);
      expect(refusee.manques, <AccordManquant>[
        AccordManquant.contrat,
        AccordManquant.cadre,
      ]);
      expect(
        () => LectureLettre.depuisJson(<String, dynamic>{
          'acces': false,
          'raison': 'autre',
        }),
        throwsFormatException,
      );
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

    test('le tableau de la paie se lit dans chaque langue', () {
      for (final String l in <String>['fr', 'en', 'ar']) {
        final TableauLettre tab = lireCorps(partiesDuDepot(l)[3].corps)
            .whereType<TableauLettre>()
            .single;
        expect(tab.lignes, hasLength(8), reason: l);
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
