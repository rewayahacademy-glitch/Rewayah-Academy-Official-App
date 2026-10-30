// FI-5b (guide Finance V4 §5.1 « Desktop », maquette 05) : sur ordinateur,
// le Foyer du tuteur pose la synthese des soldes et les cartes des enfants
// sur toute la largeur utile, les cartes en grille (deux ou trois colonnes,
// moins a texte agrandi), puis « Dernieres transactions » (les trois
// derniers mouvements rendus par la source, montants signes) a cote des
// annexes. Le telephone reste une pile d'une colonne ; sans source
// (production), aucun bloc d'argent ni de transactions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politique_famille.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/ligne_transaction.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/finances_foyer.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';
import 'package:rewayah_academy/features/foyer/transactions_foyer.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// Le 4 octobre 2026 a midi, dans le mois de reference de la demonstration.
final DateTime _maintenant = DateTime(2026, 10, 4, 12);

/// Trois enfants : la maquette 05.
const JeuFoyerFinance _jeu = JeuFoyerFinance.unARegulariser;

FauxServiceAppairage _foyer(JeuFoyerFinance jeu) =>
    FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[
        for (final FinancesProfil p in DonneesFinanceDemo.profils(jeu))
          EleveDuFoyer(
            id: p.profilId,
            prenom: p.prenom,
            identifiantImmuable: 'STUD-FI-${p.profilId}',
            mode: InterfaceMode.standard,
            camera: CameraPolicy.allowed,
          ),
      ];

Future<GoRouter> _monter(
  WidgetTester tester, {
  required double largeur,
  bool avecFinances = true,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  final Size taille = Size(largeur, 3000);
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: _foyer(_jeu),
        ),
        horlogeFoyerProvider.overrideWithValue(() => _maintenant),
        if (avecFinances) ...<Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            const PaiementsFoyerFinanceDemo(_jeu),
          ),
          portPolitiquesCommercialesProvider.overrideWithValue(
            const PolitiquesCommercialesDemo(),
          ),
          portPolitiqueFamilleProvider.overrideWithValue(
            const PolitiqueFamilleDemo(),
          ),
        ],
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              routerConfig: routeur,
              builder: (BuildContext contexte, Widget? enfant) => MediaQuery(
                data: MediaQuery.of(contexte)
                    .copyWith(textScaler: TextScaler.linear(echelle)),
                child: Directionality(
                  textDirection: direction,
                  child: enfant ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(Routes.tuteurFoyer);
  await stabiliser(tester);
  return routeur;
}

/// Les rectangles des cartes d'enfants, dans l'ordre de l'arbre.
List<Rect> _cartes(WidgetTester tester) => <Rect>[
  for (int i = 0; i < find.byType(CarteMembre).evaluate().length; i++)
    tester.getRect(find.byType(CarteMembre).at(i)),
];

/// Le nombre de cartes sur la premiere rangee.
int _colonnes(List<Rect> cartes) =>
    cartes.where((Rect r) => (r.top - cartes.first.top).abs() < 1).length;

void main() {
  for (final double largeur in <double>[1200, 1440]) {
    testWidgets('${largeur.toInt()} : cartes en deux colonnes ou plus, '
        'synthese pleine largeur', (WidgetTester tester) async {
      await _monter(tester, largeur: largeur);
      expect(tester.takeException(), isNull);
      final List<Rect> cartes = _cartes(tester);
      expect(cartes, hasLength(DonneesFinanceDemo.profils(_jeu).length));
      final int colonnes = _colonnes(cartes);
      expect(colonnes, greaterThanOrEqualTo(2));
      // Cote a cote, separees de 16 au moins, jamais superposees.
      expect(cartes[1].left, greaterThanOrEqualTo(cartes[0].right + 16 - 1));
      // La synthese et la grille occupent la meme largeur utile, bien plus
      // large que l'ancienne colonne principale (~650).
      final Rect synthese = tester.getRect(find.byKey(SyntheseSoldesFoyer.cle));
      final Rect membres = tester.getRect(find.byKey(FoyerPage.membresKey));
      expect(synthese.width, moreOrLessEquals(membres.width, epsilon: 1));
      expect(synthese.width, greaterThan(800));
      final double gauche = cartes
          .map((Rect r) => r.left)
          .reduce((double a, double b) => a < b ? a : b);
      final double droite = cartes
          .map((Rect r) => r.right)
          .reduce((double a, double b) => a > b ? a : b);
      expect(gauche, moreOrLessEquals(synthese.left, epsilon: 1));
      expect(droite, moreOrLessEquals(synthese.right, epsilon: 1));
      debugPrint(
        'FI-5b ${largeur.toInt()} : $colonnes colonnes, synthese '
        '${synthese.width.toStringAsFixed(0)} px, carte '
        '${cartes.first.width.toStringAsFixed(0)} px',
      );
    });
  }

  testWidgets('1440 : trois dernieres transactions, montants signes, '
      '« Voir tout » vers l historique du foyer (R1-07, R1-12)', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(tester, largeur: 1440);
    final List<MouvementFoyer> attendus = DonneesFinanceDemo.derniersMouvements(
      _jeu,
    );
    expect(attendus, hasLength(3));
    final Finder bloc = find.byKey(DernieresTransactionsFoyer.cle);
    expect(bloc, findsOneWidget);
    expect(find.text(t.foyer.transactions.titre), findsOneWidget);
    final Finder lignes = find.descendant(
      of: bloc,
      matching: find.byType(LigneTransaction),
    );
    expect(lignes, findsNWidgets(3));
    for (final MouvementFoyer m in attendus) {
      expect(
        find.descendant(
          of: bloc,
          matching: find.text(
            formaterMontant(m.mouvement.montant, signe: true),
          ),
        ),
        findsWidgets,
      );
    }
    // A cote des annexes, sous la grille.
    final Rect transactions = tester.getRect(bloc);
    final Rect appareils = tester.getRect(find.byKey(FoyerPage.appareilsKey));
    expect(appareils.left, greaterThan(transactions.right));
    final Rect derniereCarte = _cartes(tester).last;
    expect(transactions.top, greaterThan(derniereCarte.bottom));

    final Finder voirTout = find.byKey(DernieresTransactionsFoyer.voirToutKey);
    // Le nom lu contient le libelle visible (WCAG 2.5.3, R1-12).
    final SemanticsHandle semantique = tester.ensureSemantics();
    final String lu = tester.getSemantics(voirTout).label;
    semantique.dispose();
    expect(lu, contains(t.foyer.transactions.voirTout));
    await tester.ensureVisible(voirTout);
    await tester.tap(voirTout);
    await stabiliser(tester);
    // L'historique du foyer entier, jamais les mouvements d'un seul enfant
    // (X-12, R1-07).
    expect(routeur.state.uri.path, Routes.compteTuteurSousPage('paiements'));
  });

  testWidgets('1440 : « Vue financière du foyer » sur le mois courant, a '
      'cote des transactions (R1-02, defaut Q-FI-8)', (
    WidgetTester tester,
  ) async {
    await _monter(tester, largeur: 1440);
    expect(tester.takeException(), isNull);
    final Finder vue = find.byKey(VueFinanciereFoyer.cle);
    expect(vue, findsOneWidget);
    final SyntheseFoyer s = DonneesFinanceDemo.finances(_jeu).synthese;
    for (final String texte in <String>[
      t.foyer.finances.vueFinanciere,
      t.foyer.finances.vueFinancierePeriode,
      t.argent.soldes.paiements,
      formaterMontant(s.totalSoldes),
      formaterMontant(s.aPayerCeMois),
      '${s.paiementsDuMois}',
    ]) {
      expect(
        find.descendant(of: vue, matching: find.text(texte)),
        findsOneWidget,
        reason: texte,
      );
    }
    final Rect panneau = tester.getRect(vue);
    final Rect transactions = tester.getRect(
      find.byKey(DernieresTransactionsFoyer.cle),
    );
    expect(transactions.left, greaterThan(panneau.right));
    expect(panneau.top, moreOrLessEquals(transactions.top, epsilon: 1));
  });

  testWidgets('768 (tablette, R1-04) : cartes en deux colonnes, synthese '
      'sur deux rangees, aucun debordement', (WidgetTester tester) async {
    await _monter(tester, largeur: 768);
    expect(tester.takeException(), isNull);
    final List<Rect> cartes = _cartes(tester);
    expect(_colonnes(cartes), 2);
    expect(cartes[1].left, greaterThanOrEqualTo(cartes[0].right + 16 - 1));
    // Total et « À payer » sur la premiere rangee ; « Profils financés » et
    // le bouton sur la seconde.
    final Finder synthese = find.byKey(SyntheseSoldesFoyer.cle);
    double haut(String texte) => tester
        .getTopLeft(find.descendant(of: synthese, matching: find.text(texte)))
        .dy;
    final double rangee1 = haut(t.argent.soldes.total);
    expect(haut(t.argent.soldes.aPayer), moreOrLessEquals(rangee1));
    final double rangee2 = haut(t.argent.soldes.profilsFinances);
    expect(rangee2, greaterThan(rangee1));
    expect(
      tester.getTopLeft(find.byKey(SyntheseSoldesFoyer.rechargerKey)).dy,
      moreOrLessEquals(rangee2, epsilon: 1),
    );
    // La vue financiere, puis les transactions, l'une sous l'autre.
    final Rect vue = tester.getRect(find.byKey(VueFinanciereFoyer.cle));
    final Rect transactions = tester.getRect(
      find.byKey(DernieresTransactionsFoyer.cle),
    );
    expect(transactions.top, greaterThan(vue.bottom));
  });

  testWidgets('390 : inchange, une colonne, aucune transaction ni vue '
      'financiere', (WidgetTester tester) async {
    await _monter(tester, largeur: 390);
    expect(tester.takeException(), isNull);
    final List<Rect> cartes = _cartes(tester);
    expect(_colonnes(cartes), 1);
    for (final Rect r in cartes.skip(1)) {
      expect(r.left, moreOrLessEquals(cartes.first.left, epsilon: 1));
      expect(r.width, moreOrLessEquals(cartes.first.width, epsilon: 1));
    }
    expect(find.byKey(SyntheseSoldesFoyer.cle), findsOneWidget);
    expect(find.byKey(DernieresTransactionsFoyer.cle), findsNothing);
    expect(find.byKey(VueFinanciereFoyer.cle), findsNothing);
  });

  testWidgets('1440 sans source (production) : aucun bloc d argent ni de '
      'transactions, la grille reste', (WidgetTester tester) async {
    await _monter(tester, largeur: 1440, avecFinances: false);
    expect(tester.takeException(), isNull);
    expect(find.byKey(SyntheseSoldesFoyer.cle), findsNothing);
    expect(find.byType(BlocFinanceMembre), findsNothing);
    expect(find.byKey(DernieresTransactionsFoyer.cle), findsNothing);
    expect(find.byKey(VueFinanciereFoyer.cle), findsNothing);
    expect(find.byType(LigneTransaction), findsNothing);
    expect(_colonnes(_cartes(tester)), greaterThanOrEqualTo(2));
    // Les annexes gardent leur largeur de colonne, jamais etirees.
    final Rect appareils = tester.getRect(find.byKey(FoyerPage.appareilsKey));
    final Rect membres = tester.getRect(find.byKey(FoyerPage.membresKey));
    expect(appareils.width, lessThan(membres.width * 0.5));
  });

  testWidgets('1440, texte x2 : moins de colonnes, aucun debordement', (
    WidgetTester tester,
  ) async {
    await _monter(tester, largeur: 1440);
    final int normal = _colonnes(_cartes(tester));
    await _monter(tester, largeur: 1440, echelle: 2);
    expect(tester.takeException(), isNull);
    final int agrandi = _colonnes(_cartes(tester));
    expect(agrandi, lessThan(normal));
    expect(
      find.descendant(
        of: find.byKey(DernieresTransactionsFoyer.cle),
        matching: find.byType(LigneTransaction),
      ),
      findsNWidgets(3),
    );
  });

  for (final TextDirection direction in TextDirection.values) {
    testWidgets('1440, ${direction.name} : la premiere carte au bord de '
        'debut', (WidgetTester tester) async {
      await _monter(tester, largeur: 1440, direction: direction);
      expect(tester.takeException(), isNull);
      final List<Rect> cartes = _cartes(tester);
      expect(_colonnes(cartes), greaterThanOrEqualTo(2));
      if (direction == TextDirection.ltr) {
        expect(cartes[0].left, lessThan(cartes[1].left));
      } else {
        expect(cartes[0].left, greaterThan(cartes[1].left));
      }
      final Rect transactions = tester.getRect(
        find.byKey(DernieresTransactionsFoyer.cle),
      );
      final Rect appareils = tester.getRect(find.byKey(FoyerPage.appareilsKey));
      expect(
        direction == TextDirection.ltr
            ? transactions.left < appareils.left
            : transactions.left > appareils.left,
        isTrue,
      );
    });
  }
}
