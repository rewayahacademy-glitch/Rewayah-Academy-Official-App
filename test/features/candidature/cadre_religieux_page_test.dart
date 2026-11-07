// CADRE-ECRAN (pilote, 07/11/2026) : le candidat lit et accepte le cadre
// religieux et pedagogique publie ; plus de boucle vers la page des accords.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/candidature/modeles_candidature.dart';
import 'package:rewayah_academy/core/candidature/texte_cadre.dart';
import 'package:rewayah_academy/core/capacites/port_consentements.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/features/candidature/cadre_religieux_page.dart';
import 'package:rewayah_academy/features/candidature/portail_candidature.dart';

import '../../fixtures/candidature/faux_ma_candidature.dart';
import '../../support/harnais.dart';
import 'hote_candidature.dart';

/// Un texte de TEST, jamais le texte du cadre : l'ecran ne connait aucun mot
/// du cadre, il affiche ce que le serveur publie.
const String _texteTest =
    'Titre de test\n\nParagraphe de test.\n\n• premier point\n• second point';

class _FauxTexte implements PortTexteCadre {
  _FauxTexte(this.rendu, {this.echec = false});

  final Map<String, TexteCadre?> rendu;
  bool echec;
  final List<String> langues = <String>[];

  @override
  Future<TexteCadre?> lire({required String langue}) async {
    langues.add(langue);
    if (echec) throw Exception('lecture impossible');
    return rendu[langue] ?? rendu['fr'];
  }
}

class _FauxConsentements implements PortConsentements {
  _FauxConsentements(this.dossier);

  final FauxServiceDossier dossier;
  final List<(SorteContrat, String)> acceptes = <(SorteContrat, String)>[];
  Exception? echec;

  @override
  Future<void> accepter({
    required SorteContrat sorte,
    required String version,
  }) async {
    if (echec != null) throw echec!;
    acceptes.add((sorte, version));
    // Le serveur : la candidature a maintenant le cadre accepte.
    dossier.etatRendu = etatCandidat(
      candidature: candidatureAFaire(cadreAccepte: true),
    );
  }

  @override
  Future<List<Acceptation>> signees() async => const <Acceptation>[];

  @override
  Future<List<ConsentementRequis>> aRenouveler() async =>
      const <ConsentementRequis>[];
}

Future<(_FauxTexte, _FauxConsentements)> _monter(
  WidgetTester tester, {
  CandidatureDossier? candidature,
  _FauxTexte? texte,
  Size taille = const Size(390, 844),
  TextDirection? direction,
}) async {
  final FauxServiceDossier dossier = FauxServiceDossier()
    ..etatRendu = etatCandidat(
      candidature: candidature ?? candidatureAFaire(cadreAccepte: false),
    );
  final _FauxTexte t0 =
      texte ??
      _FauxTexte(<String, TexteCadre?>{
        'fr': const TexteCadre(
          version: 'cadre-1',
          texte: _texteTest,
          langue: 'fr',
        ),
      });
  final _FauxConsentements consentements = _FauxConsentements(dossier);
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteRoutant(
      depart: Routes.attenteCadre,
      direction: direction,
      // La vraie page d'abord : le harnais en declare une pastille.
      routes: <RouteBase>[
        GoRoute(
          path: Routes.attenteCadre,
          builder: (BuildContext _, GoRouterState _) =>
              const CadreReligieuxPage(),
        ),
        ...routesCandidature(),
      ],
      surcharges: <Override>[
        ...surchargesCandidature(
          port: FauxMaCandidature(),
          etat: dossier.etatRendu,
          dossier: dossier,
        ),
        portTexteCadreProvider.overrideWithValue(t0),
        portConsentementsProvider.overrideWithValue(consentements),
      ],
    ),
  );
  await tester.pumpAndSettle();
  return (t0, consentements);
}

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  _rendu();

  test('le portail mene au cadre, jamais a la page des accords', () {
    final ({String libelle, String chemin})? suite = prochaineCandidature(
      candidatureAFaire(cadreAccepte: false),
    );
    expect(suite?.chemin, Routes.attenteCadre);
    expect(
      prochaineCandidature(candidatureAFaire())?.libelle,
      t.recrutement.portail.completer,
    );
  });

  testWidgets('contenu : le texte publie, la case, le bouton ; accepter passe '
      'par les consentements a la version publiee, puis « Completer »', (
    WidgetTester tester,
  ) async {
    final (_, _FauxConsentements c) = await _monter(tester);
    expect(find.byKey(ContenuCadre.texteKey), findsOneWidget);
    expect(find.text('Titre de test'), findsOneWidget);
    expect(find.text('• premier point\n• second point'), findsOneWidget);

    // Sans case : rien n'est envoye.
    await tester.ensureVisible(find.byKey(ContenuCadre.accepterKey));
    await tester.tap(find.byKey(ContenuCadre.accepterKey));
    await tester.pumpAndSettle();
    expect(c.acceptes, isEmpty);
    expect(find.text(t.contrat.caseRequise), findsOneWidget);

    await tester.ensureVisible(find.byKey(ContenuCadre.caseKey));
    await tester.tap(find.byKey(ContenuCadre.caseKey));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(ContenuCadre.accepterKey));
    await tester.tap(find.byKey(ContenuCadre.accepterKey));
    await tester.pumpAndSettle();
    expect(c.acceptes, <(SorteContrat, String)>[
      (SorteContrat.cadreReligieuxEnseignant, 'cadre-1'),
    ]);
    // Le dossier relu dit « accepte » : la suite est « Completer ma
    // candidature », plus jamais la page des accords.
    expect(find.byKey(ContenuCadre.accepteKey), findsOneWidget);
    expect(find.text(t.recrutement.portail.completer), findsOneWidget);
    await tester.tap(find.byKey(ContenuCadre.completerKey));
    await tester.pumpAndSettle();
    expect(find.text('PAGE DES ACCORDS'), findsNothing);
  });

  testWidgets('vide : rien de publie, une phrase et aucun bouton', (
    WidgetTester tester,
  ) async {
    await _monter(tester, candidature: candidatureAFaire(cadrePublie: false));
    expect(find.byKey(ContenuCadre.nonPublieKey), findsOneWidget);
    expect(find.text(t.accords.cadreNonPublie), findsOneWidget);
    expect(find.byKey(ContenuCadre.accepterKey), findsNothing);
  });

  testWidgets('vide : un texte d\'une autre version que celle exigee ne '
      's\'affiche pas et ne s\'accepte pas', (WidgetTester tester) async {
    await _monter(
      tester,
      texte: _FauxTexte(<String, TexteCadre?>{
        'fr': const TexteCadre(
          version: 'autre',
          texte: _texteTest,
          langue: 'fr',
        ),
      }),
    );
    expect(find.byKey(ContenuCadre.nonPublieKey), findsOneWidget);
    expect(find.byKey(ContenuCadre.accepterKey), findsNothing);
    expect(find.text('Titre de test'), findsNothing);
  });

  testWidgets('vide : aucune ligne publiee', (WidgetTester tester) async {
    await _monter(tester, texte: _FauxTexte(<String, TexteCadre?>{}));
    expect(find.byKey(ContenuCadre.nonPublieKey), findsOneWidget);
    expect(find.byKey(ContenuCadre.accepterKey), findsNothing);
  });

  testWidgets('erreur : lecture impossible, puis Reessayer relit', (
    WidgetTester tester,
  ) async {
    final _FauxTexte texte = _FauxTexte(<String, TexteCadre?>{
      'fr': const TexteCadre(
        version: 'cadre-1',
        texte: _texteTest,
        langue: 'fr',
      ),
    }, echec: true);
    await _monter(tester, texte: texte);
    expect(find.byKey(ContenuCadre.erreurLectureKey), findsOneWidget);
    expect(find.text(t.recrutement.cadre.erreurLecture), findsOneWidget);
    texte.echec = false;
    await tester.tap(find.text(t.commun.reessayer));
    await tester.pumpAndSettle();
    expect(find.byKey(ContenuCadre.texteKey), findsOneWidget);
  });

  testWidgets('refus du serveur : le message le dit, la case reste', (
    WidgetTester tester,
  ) async {
    final (_, _FauxConsentements c) = await _monter(tester);
    c.echec = Exception('refus');
    await tester.ensureVisible(find.byKey(ContenuCadre.caseKey));
    await tester.tap(find.byKey(ContenuCadre.caseKey));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(ContenuCadre.accepterKey));
    await tester.tap(find.byKey(ContenuCadre.accepterKey));
    await tester.pumpAndSettle();
    expect(find.text(t.recrutement.cadre.erreurAccord), findsOneWidget);
    expect(find.byKey(ContenuCadre.accepteKey), findsNothing);
  });

  testWidgets('deja accepte : la page propose Completer ma candidature', (
    WidgetTester tester,
  ) async {
    await _monter(tester, candidature: candidatureAFaire());
    expect(find.byKey(ContenuCadre.accepteKey), findsOneWidget);
    expect(find.byKey(ContenuCadre.completerKey), findsOneWidget);
    expect(find.byKey(ContenuCadre.accepterKey), findsNothing);
  });

  testWidgets(
    'arabe : le texte lu est celui de la langue, de droite a gauche',
    (WidgetTester tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
      final _FauxTexte texte = _FauxTexte(<String, TexteCadre?>{
        'fr': const TexteCadre(
          version: 'cadre-1',
          texte: _texteTest,
          langue: 'fr',
        ),
        'ar': const TexteCadre(
          version: 'cadre-1',
          texte: 'نص تجريبي',
          langue: 'ar',
        ),
      });
      await _monter(tester, texte: texte, direction: TextDirection.rtl);
      expect(texte.langues, contains('ar'));
      expect(find.text('نص تجريبي'), findsOneWidget);
      expect(find.text(t.recrutement.cadre.accepter), findsOneWidget);
    },
  );
}

/// Arbitrage du garde-cap (07/11/2026) : texte brut, affiche tel quel.
void _rendu() {
  testWidgets('le texte brut publie s\'affiche tel quel : un paragraphe par '
      'bloc, le premier en en-tete, les puces du texte gardees', (
    WidgetTester tester,
  ) async {
    const String brut =
        'Engagement de test\n\nPremier paragraphe,\nsur deux lignes.\n\n'
        '• un\n• deux\n• trois\n\nDernier ** paragraphe, sans Markdown.';
    final SemanticsHandle semantique = tester.ensureSemantics();
    await tester.pumpWidget(
      hote(
        const Scaffold(
          body: SingleChildScrollView(child: TexteCadrePublie(texte: brut)),
        ),
      ),
    );
    final List<String> rendus = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text w) => w.data ?? '')
        .toList();
    expect(rendus, <String>[
      'Engagement de test',
      'Premier paragraphe,\nsur deux lignes.',
      '• un\n• deux\n• trois',
      'Dernier ** paragraphe, sans Markdown.',
    ]);
    expect(
      tester.getSemantics(find.text('Engagement de test')),
      matchesSemantics(label: 'Engagement de test', isHeader: true),
    );
    semantique.dispose();
  });
}
