// Lot E6 (decision du directeur du 17/10/2026, DECISION-ENTREE) : une seule
// page des accords, qui defile.
//
// Ce que le test prouve : chaque texte a sa case (carte entiere cliquable) ;
// le bouton « Suivant » est inactif tant qu'une case manque, actif quand tout
// est coche ; un appui sur le bouton inactif n'envoie rien et ne renvoie
// nulle part ; apres l'envoi, aucune page de case ne s'ouvre ; le texte A3
// n'apparait qu'une fois ; l'accuse a sa case ; un echec d'envoi laisse la
// page en place, cases gardees, et la reprise ne renvoie pas ce qui est deja
// enregistre ; l'enseignant y trouve son contrat (application ou serveur) ;
// les anciennes adresses menent a la page. CAND-Q15 conduite : l'enseignant
// dont le serveur dit le code de conduite a accepter y trouve le texte et sa
// case ; le code part apres le contrat, a sa version requise ; seul, il ne
// montre que sa section ; un tuteur ne le voit jamais. Captures 390x844 et
// 1440x900 avec CAPTURE_DIR.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:rewayah_academy/core/recrutement/port_signature_contrat.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/code_conduite/code_conduite.dart';
import 'package:rewayah_academy/features/consentements/texte_observation.dart';
import 'package:rewayah_academy/features/demo/recrutement_demo.dart';
import 'package:rewayah_academy/features/dossier/accords_page.dart';
import 'package:rewayah_academy/features/dossier/signature_page.dart';

import '../capture/outil_capture.dart';
import '../support/harnais.dart';

/// Un service qui echoue a l'appel numero [echecAu] de `accepterContrat`
/// (1 pour le premier), une seule fois.
class _ServiceEchecUneFois extends FauxServiceDossier {
  _ServiceEchecUneFois(this.echecAu);

  final int echecAu;
  int appels = 0;

  @override
  Future<void> accepterContrat(SorteContrat sorte, String version) async {
    appels++;
    if (appels == echecAu) {
      throw Exception('panne');
    }
    await super.accepterContrat(sorte, version);
  }
}

EtatDossier _etat(
  AppRole role, {
  bool accuse = false,
  bool contrat = false,
  bool code = true,
  bool piece = false,
}) => EtatDossier(
  profilExiste: true,
  role: role,
  statutCompte: AccountStatus.pendingKyc,
  accuseSigne: accuse,
  contratSigne: contrat,
  codeConduiteSigne: code,
  pieceDeposee: piece,
  statutPiece: piece ? StatutPiece.enAttente : null,
);

List<RouteBase> _routes() => <RouteBase>[
  GoRoute(
    path: Routes.attenteAccords,
    builder: (BuildContext _, GoRouterState _) => const AccordsPage(),
  ),
  GoRoute(
    path: Routes.attenteAccuse,
    redirect: (BuildContext _, GoRouterState e) => versLesAccords(e.uri),
  ),
  GoRoute(
    path: Routes.attenteContrat,
    redirect: (BuildContext _, GoRouterState e) => versLesAccords(e.uri),
  ),
  GoRoute(
    path: Routes.attente,
    builder: (BuildContext _, GoRouterState _) =>
        const Scaffold(body: Text('portail')),
  ),
  GoRoute(
    path: Routes.attentePiece,
    builder: (BuildContext _, GoRouterState _) =>
        const Scaffold(body: Text('route-piece')),
  ),
];

List<Override> _surcharges(
  ServiceDossier dossier, {
  PortSignatureContrat? port,
}) => <Override>[
  serviceDossierProvider.overrideWithValue(dossier),
  resignatureContratEnseignantProvider.overrideWithValue(false),
  portSignatureContratProvider.overrideWithValue(port),
];

Future<void> _monter(
  WidgetTester tester,
  ServiceDossier dossier, {
  String depart = Routes.attenteAccords,
  PortSignatureContrat? port,
}) async {
  await tester.pumpWidget(
    hoteRoutant(
      depart: depart,
      routes: _routes(),
      surcharges: _surcharges(dossier, port: port),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _suivant => find.byKey(const ValueKey<String>('accords-suivant'));

bool _actif(WidgetTester tester) =>
    tester.widget<ActionPrincipale>(_suivant).onPress != null;

Future<void> _cocher(WidgetTester tester, String libelle) async {
  await tester.ensureVisible(find.text(libelle));
  await tester.pumpAndSettle();
  await tester.tap(find.text(libelle));
  await tester.pumpAndSettle();
}

Future<void> _appuyerSuivant(WidgetTester tester) async {
  await tester.ensureVisible(_suivant);
  await tester.pumpAndSettle();
  await tester.tap(_suivant, warnIfMissed: false);
  await tester.pumpAndSettle();
}

void main() {
  group('Tuteur : une page, une case par texte, un bouton', () {
    testWidgets('inactif tant qu une case manque, actif quand tout est coche', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.guardian);
      await _monter(tester, dossier);

      expect(find.byType(CaseAccordTexte), findsNWidgets(2));
      expect(_actif(tester), isFalse);
      expect(find.text(t.accords.reste(n: 2)), findsOneWidget);

      await _cocher(tester, t.accords.caseSavoir);
      expect(_actif(tester), isFalse);
      expect(find.text(t.accords.reste(n: 1)), findsOneWidget);

      await _cocher(tester, t.consentement.texte.caseResponsable);
      expect(_actif(tester), isTrue);
      expect(find.text(t.accords.toutCoche), findsOneWidget);

      // Decocher rend le bouton inactif de nouveau.
      await _cocher(tester, t.accords.caseSavoir);
      expect(_actif(tester), isFalse);
    });

    testWidgets('un appui sur le bouton inactif n envoie rien et ne renvoie '
        'nulle part', (WidgetTester tester) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.guardian);
      await _monter(tester, dossier);

      await _cocher(tester, t.accords.caseSavoir);
      await _appuyerSuivant(tester);

      expect(dossier.contratsAcceptes, isEmpty);
      expect(find.byType(AccordsPage), findsOneWidget);
      expect(find.text('portail'), findsNothing);
      // Plus de reproche apres coup (ancien « Il manque votre accord »).
      expect(find.text(t.formulaire.manqueAccord), findsNothing);
    });

    testWidgets('tout coche : les deux accords partent dans l ordre, puis le '
        'portail, sans page de case apres coup', (WidgetTester tester) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.guardian);
      await _monter(tester, dossier);

      await _cocher(tester, t.accords.caseSavoir);
      await _cocher(tester, t.consentement.texte.caseResponsable);
      await _appuyerSuivant(tester);

      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
        SorteContrat.conditionsTuteur,
      ]);
      expect(dossier.versionsAcceptees, <String>[
        VersionsContrat.textesJuridiques,
        VersionsContrat.avecObservation,
      ]);
      expect(find.text('portail'), findsOneWidget);
      expect(find.byType(AccordsPage), findsNothing);
      expect(find.byType(CaseAccordTexte), findsNothing);
    });

    testWidgets('le texte A3 n apparait qu une fois, et l accuse a sa case', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.guardian);
      await _monter(tester, dossier);

      for (final ParagrapheTexte p in paragraphesA3()) {
        expect(find.text(p.titre), findsOneWidget);
        expect(find.text(p.corps!), findsOneWidget);
      }
      expect(find.text(t.accords.caseSavoir), findsOneWidget);
      expect(find.text(t.contrat.a3.jaiLu), findsNothing);
      // Le texte des visites des parents suit, avec sa propre case.
      expect(find.text(t.consentement.texte.titre), findsOneWidget);
    });

    testWidgets('accuse deja enregistre : A3 une fois, sa case cochee et '
        'figee ; seul le contrat reste', (WidgetTester tester) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.guardian, accuse: true);
      await _monter(tester, dossier);

      for (final ParagrapheTexte p in paragraphesA3()) {
        expect(find.text(p.corps!), findsOneWidget);
      }
      final CaseAccordTexte savoir = tester.widget<CaseAccordTexte>(
        find.widgetWithText(CaseAccordTexte, t.accords.caseSavoir),
      );
      expect(savoir.cochee, isTrue);
      expect(savoir.onChanged, isNull);
      expect(find.text(t.accords.reste(n: 1)), findsOneWidget);

      await _cocher(tester, t.consentement.texte.caseResponsable);
      await _appuyerSuivant(tester);
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.conditionsTuteur,
      ]);
    });

    testWidgets('?pour=moi : la variante eleve adulte', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.guardian);
      await _monter(
        tester,
        dossier,
        depart: '${Routes.attenteAccords}?pour=moi',
      );

      expect(find.text(t.consentement.texte.caseAdulte), findsOneWidget);
      expect(find.text(t.consentement.texte.caseResponsable), findsNothing);
    });

    testWidgets('un echec garde la page et les cases ; la reprise ne renvoie '
        'pas ce qui est deja enregistre', (WidgetTester tester) async {
      final _ServiceEchecUneFois dossier = _ServiceEchecUneFois(2)
        ..etatRendu = _etat(AppRole.guardian);
      await _monter(tester, dossier);

      await _cocher(tester, t.accords.caseSavoir);
      await _cocher(tester, t.consentement.texte.caseResponsable);
      await _appuyerSuivant(tester);

      // L'accuse est parti, le contrat a echoue : la page reste, cases
      // cochees, et le message le dit.
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
      ]);
      expect(find.byType(AccordsPage), findsOneWidget);
      expect(find.text(t.contrat.erreur), findsOneWidget);
      expect(
        tester
            .widgetList<CaseAccordTexte>(find.byType(CaseAccordTexte))
            .every((CaseAccordTexte c) => c.cochee),
        isTrue,
      );
      expect(_actif(tester), isTrue);

      await _appuyerSuivant(tester);
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
        SorteContrat.conditionsTuteur,
      ]);
      expect(find.text('portail'), findsOneWidget);
    });

    testWidgets('tout est deja accepte : la page le dit, Continuer mene au '
        'portail', (WidgetTester tester) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.guardian, accuse: true, contrat: true);
      await _monter(tester, dossier);

      expect(find.text(t.accords.dejaAcceptes), findsOneWidget);
      expect(find.byType(CaseAccordTexte), findsNothing);
      await _appuyerSuivant(tester);
      expect(find.text('portail'), findsOneWidget);
      expect(dossier.contratsAcceptes, isEmpty);
    });
  });

  group('Les anciennes adresses menent a la page unique', () {
    test('versLesAccords garde pour, rien d autre', () {
      expect(
        versLesAccords(Uri.parse(Routes.attenteAccuse)),
        Routes.attenteAccords,
      );
      expect(
        versLesAccords(Uri.parse('${Routes.attenteContrat}?pour=moi&x=1')),
        '${Routes.attenteAccords}?pour=moi',
      );
    });

    testWidgets('/attente/contrat?pour=moi ouvre les accords, eleve adulte', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.guardian);
      await _monter(
        tester,
        dossier,
        depart: '${Routes.attenteContrat}?pour=moi',
      );
      expect(find.byType(AccordsPage), findsOneWidget);
      expect(find.text(t.consentement.texte.caseAdulte), findsOneWidget);
    });
  });

  group('Enseignant', () {
    testWidgets('sans port serveur : E1, contrat et article 9, chacun sa '
        'case ; la piece suit', (WidgetTester tester) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..demonstration = true
        ..etatRendu = _etat(AppRole.teacher);
      await _monter(tester, dossier);

      expect(find.text(t.contrat.e1.quoi), findsOneWidget);
      expect(find.text(t.contrat.a3.quoi), findsNothing);
      expect(find.text(t.contrat.clauseControle.texte), findsOneWidget);
      expect(find.text(t.contrat.politique.lien), findsOneWidget);
      expect(find.byType(CaseAccordTexte), findsNWidgets(3));
      expect(find.text(t.accords.reste(n: 3)), findsOneWidget);

      await _cocher(tester, t.accords.caseSavoir);
      await _cocher(tester, t.accords.caseContrat);
      expect(_actif(tester), isFalse);
      await _cocher(tester, t.contrat.clauseControle.caseReligion);
      expect(_actif(tester), isTrue);

      await _appuyerSuivant(tester);
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
        SorteContrat.contratEnseignant,
      ]);
      expect(dossier.versionsAcceptees, <String>[
        VersionsContrat.textesJuridiques,
        VersionsContrat.textesJuridiques,
      ]);
      // La piece demande un fichier : elle reste une etape, et vient ensuite.
      expect(find.text('route-piece'), findsOneWidget);
    });

    testWidgets('port serveur branche : le contrat servi, le nom tape et sa '
        'case ; l accuse puis la signature probante', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.teacher);
      final SignatureContratDemo port = SignatureContratDemo();
      await _monter(tester, dossier, port: port);

      expect(
        find.byKey(const ValueKey<String>('accords-contrat-texte')),
        findsOneWidget,
      );
      expect(find.byType(CaseAccordTexte), findsNWidgets(2));

      await _cocher(tester, t.accords.caseSavoir);
      await _cocher(tester, t.recrutement.signature.accuse);
      // Toutes les cases sont cochees, mais le nom manque : inactif, et la
      // ligne au-dessus du bouton le dit.
      expect(_actif(tester), isFalse);
      expect(find.text(t.recrutement.signature.nomVide), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('accords-nom')),
        'Yasmine Haddad',
      );
      await tester.pumpAndSettle();
      expect(_actif(tester), isTrue);

      await _appuyerSuivant(tester);
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
      ]);
      final Signature? signee = await port.maSignature(
        SorteContrat.contratEnseignant,
      );
      expect(signee?.nomSaisi, 'Yasmine Haddad');
      expect(find.text('route-piece'), findsOneWidget);
    });
  });

  // CAND-Q15 conduite : le code de conduite se signe sur cette page, avant
  // l'activation que la garde serveur lui subordonne.
  group('Enseignant : le code de conduite avant l activation', () {
    testWidgets('sans port serveur : sa section et sa case apres le contrat ; '
        'Suivant inactif tant qu elle manque ; envoi accuse, contrat, code', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..demonstration = true
        ..etatRendu = _etat(AppRole.teacher, code: false);
      await _monter(tester, dossier);

      expect(find.text(t.codeConduite.titre), findsOneWidget);
      expect(find.byType(TexteCodeConduite), findsOneWidget);
      expect(find.text(t.codeConduite.intro), findsOneWidget);
      for (final String regle in t.codeConduite.regles) {
        expect(find.text(regle), findsOneWidget);
      }
      expect(find.byType(CaseAccordTexte), findsNWidgets(4));
      expect(find.text(t.accords.reste(n: 4)), findsOneWidget);
      // La section du code suit celle du contrat.
      expect(
        tester.getTopLeft(find.text(t.codeConduite.titre)).dy,
        greaterThan(tester.getTopLeft(find.text(t.accords.caseContrat)).dy),
      );

      await _cocher(tester, t.accords.caseSavoir);
      await _cocher(tester, t.accords.caseContrat);
      await _cocher(tester, t.contrat.clauseControle.caseReligion);
      // Tout est coche sauf le code : inactif, et la ligne le dit.
      expect(_actif(tester), isFalse);
      expect(find.text(t.accords.reste(n: 1)), findsOneWidget);
      await _appuyerSuivant(tester);
      expect(dossier.contratsAcceptes, isEmpty);

      await _cocher(tester, t.codeConduite.caseAccord);
      expect(_actif(tester), isTrue);
      await _appuyerSuivant(tester);
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
        SorteContrat.contratEnseignant,
        SorteContrat.codeConduiteEnseignant,
      ]);
      expect(dossier.versionsAcceptees, <String>[
        VersionsContrat.textesJuridiques,
        VersionsContrat.textesJuridiques,
        VersionsContrat.codeConduite,
      ]);
      expect(VersionsContrat.codeConduite, '2026-10-19');
      expect(find.text('route-piece'), findsOneWidget);
    });

    testWidgets('seul le code manque : sa seule section a cocher, puis le '
        'portail', (WidgetTester tester) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(
          AppRole.teacher,
          accuse: true,
          contrat: true,
          code: false,
          piece: true,
        );
      await _monter(tester, dossier);

      expect(find.text(t.accords.dejaAcceptes), findsNothing);
      expect(find.text(t.codeConduite.titre), findsOneWidget);
      expect(find.text(t.accords.sectionContrat), findsNothing);
      // La case de l'accuse reste affichee, cochee et figee ; seule celle du
      // code est a cocher.
      expect(find.byType(CaseAccordTexte), findsNWidgets(2));
      final CaseAccordTexte savoir = tester.widget<CaseAccordTexte>(
        find.widgetWithText(CaseAccordTexte, t.accords.caseSavoir),
      );
      expect(savoir.cochee, isTrue);
      expect(savoir.onChanged, isNull);
      expect(find.text(t.accords.reste(n: 1)), findsOneWidget);
      expect(_actif(tester), isFalse);

      await _cocher(tester, t.codeConduite.caseAccord);
      expect(_actif(tester), isTrue);
      await _appuyerSuivant(tester);
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.codeConduiteEnseignant,
      ]);
      expect(dossier.versionsAcceptees, <String>[VersionsContrat.codeConduite]);
      expect(find.text('portail'), findsOneWidget);
    });

    testWidgets('port serveur branche : l accuse, la signature probante, '
        'puis le code', (WidgetTester tester) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.teacher, code: false);
      final SignatureContratDemo port = SignatureContratDemo();
      await _monter(tester, dossier, port: port);

      expect(find.byType(CaseAccordTexte), findsNWidgets(3));
      await _cocher(tester, t.accords.caseSavoir);
      await _cocher(tester, t.recrutement.signature.accuse);
      await tester.enterText(
        find.byKey(const ValueKey<String>('accords-nom')),
        'Yasmine Haddad',
      );
      await tester.pumpAndSettle();
      expect(_actif(tester), isFalse);
      await _cocher(tester, t.codeConduite.caseAccord);
      expect(_actif(tester), isTrue);

      await _appuyerSuivant(tester);
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
        SorteContrat.codeConduiteEnseignant,
      ]);
      final Signature? signee = await port.maSignature(
        SorteContrat.contratEnseignant,
      );
      expect(signee?.nomSaisi, 'Yasmine Haddad');
      expect(find.text('route-piece'), findsOneWidget);
    });

    testWidgets('un echec a l envoi du code garde la page ; la reprise '
        'n envoie que le code', (WidgetTester tester) async {
      final _ServiceEchecUneFois dossier = _ServiceEchecUneFois(3)
        ..demonstration = true
        ..etatRendu = _etat(AppRole.teacher, code: false);
      await _monter(tester, dossier);

      await _cocher(tester, t.accords.caseSavoir);
      await _cocher(tester, t.accords.caseContrat);
      await _cocher(tester, t.contrat.clauseControle.caseReligion);
      await _cocher(tester, t.codeConduite.caseAccord);
      await _appuyerSuivant(tester);

      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
        SorteContrat.contratEnseignant,
      ]);
      expect(find.byType(AccordsPage), findsOneWidget);
      expect(find.text(t.contrat.erreur), findsOneWidget);
      expect(_actif(tester), isTrue);

      await _appuyerSuivant(tester);
      expect(dossier.contratsAcceptes, <SorteContrat>[
        SorteContrat.accuseEnregistrementControle,
        SorteContrat.contratEnseignant,
        SorteContrat.codeConduiteEnseignant,
      ]);
      expect(find.text('route-piece'), findsOneWidget);
    });

    testWidgets('code deja accepte (ou serveur d avant) : aucune section du '
        'code', (WidgetTester tester) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..demonstration = true
        ..etatRendu = _etat(AppRole.teacher);
      await _monter(tester, dossier);

      expect(find.text(t.codeConduite.titre), findsNothing);
      expect(find.byType(TexteCodeConduite), findsNothing);
      expect(find.byType(CaseAccordTexte), findsNWidgets(3));
    });

    testWidgets('un tuteur ne voit jamais le code de conduite', (
      WidgetTester tester,
    ) async {
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..etatRendu = _etat(AppRole.guardian);
      await _monter(tester, dossier);

      expect(find.text(t.codeConduite.titre), findsNothing);
      expect(find.text(t.codeConduite.caseAccord), findsNothing);
    });
  });

  group('Capture E6', skip: sautSansCapture, () {
    setUpAll(() async {
      await chargerPolicesDuDepot();
    });

    Future<void> monterCapture(
      WidgetTester tester,
      Size taille, {
      required AppRole role,
      String depart = Routes.attenteAccords,
      bool code = true,
    }) async {
      fixerVueCapture(tester, taille, 1);
      final FauxServiceDossier dossier = FauxServiceDossier()
        ..demonstration = true
        ..etatRendu = _etat(role, code: code);
      final GoRouter routeur = GoRouter(
        initialLocation: depart,
        routes: _routes(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: _surcharges(dossier),
          child: TranslationProvider(
            child: RepaintBoundary(
              key: cadreCapture,
              child: Builder(
                builder: (BuildContext context) => MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.pour(
                    InterfaceMode.standard,
                    Brightness.light,
                  ),
                  locale: TranslationProvider.of(context).flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  routerConfig: routeur,
                ),
              ),
            ),
          ),
        ),
      );
      await stabiliser(tester);
    }

    for (final (String, Size) format in <(String, Size)>[
      ('390x844', const Size(390, 844)),
      ('1440x900', const Size(1440, 900)),
    ]) {
      for (final AppRole role in <AppRole>[AppRole.guardian, AppRole.teacher]) {
        final String nom = role == AppRole.teacher ? 'enseignant' : 'tuteur';
        testWidgets('accords $nom ${format.$1}', (WidgetTester tester) async {
          await monterCapture(tester, format.$2, role: role);
          debugPrint(
            'PNG ${await capturer(tester, 'e6_accords_${nom}_${format.$1}_haut')}',
          );
          // Tout coche, en bas de page : le bouton actif.
          for (final CaseAccordTexte c
              in tester
                  .widgetList<CaseAccordTexte>(find.byType(CaseAccordTexte))
                  .toList()) {
            await tester.ensureVisible(find.text(c.libelle));
            await stabiliser(tester);
            await tester.tap(find.text(c.libelle));
            await stabiliser(tester);
          }
          debugPrint(
            'PNG ${await capturer(tester, 'e6_accords_${nom}_${format.$1}_coche')}',
          );
        });
      }
    }

    // CAND-Q15 conduite : la section du code de conduite, a l'ecran puis
    // cochee.
    for (final (String, Size) format in <(String, Size)>[
      ('390x844', const Size(390, 844)),
      ('1440x900', const Size(1440, 900)),
    ]) {
      testWidgets('accords enseignant, code de conduite ${format.$1}', (
        WidgetTester tester,
      ) async {
        await monterCapture(
          tester,
          format.$2,
          role: AppRole.teacher,
          code: false,
        );
        await tester.ensureVisible(find.text(t.codeConduite.titre));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'pe_conduite_accords_${format.$1}_section')}',
        );
        await tester.ensureVisible(find.text(t.codeConduite.caseAccord));
        await stabiliser(tester);
        await tester.tap(find.text(t.codeConduite.caseAccord));
        await stabiliser(tester);
        debugPrint(
          'PNG ${await capturer(tester, 'pe_conduite_accords_${format.$1}_case')}',
        );
      });
    }

    testWidgets('accords tuteur 390x2600 (page entiere)', (
      WidgetTester tester,
    ) async {
      await monterCapture(
        tester,
        const Size(390, 2600),
        role: AppRole.guardian,
      );
      debugPrint(
        'PNG ${await capturer(tester, 'e6_accords_tuteur_390_entiere')}',
      );
    });
  });
}
