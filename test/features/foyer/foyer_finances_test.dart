// FI-4 (guide Finance V4 §4, §5.1, §8 F2 ; maquette 03) : le Foyer du tuteur
// porte la synthese des soldes et, dans la carte de chaque enfant, son etat,
// son solde et son prochain debit ; « Recharger Ibrahim » ouvre la recharge
// avec Ibrahim coche ; un seul bouton plein ; sans source (production, ou le
// second adulte), aucun bloc d'argent ni bouton de recharge.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/pastille_financiere.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/finances_foyer.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';

import '../../router/support_routeur.dart';
import '../../support/harnais.dart';

/// Le 4 octobre 2026 a midi, dans le mois de reference de la demonstration.
final DateTime _maintenant = DateTime(2026, 10, 4, 12);

/// Le foyer du jeu [jeu] : les memes identifiants que ses finances.
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
  required JeuFoyerFinance jeu,
  bool avecFinances = true,
  Size taille = const Size(390, 2400),
  double echelle = 1,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesRouteur(
          FausseSourceSession(sessionActive(AppRole.guardian)),
          appairage: _foyer(jeu),
        ),
        horlogeFoyerProvider.overrideWithValue(() => _maintenant),
        if (avecFinances) ...<Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            PaiementsFoyerFinanceDemo(jeu),
          ),
          portPolitiquesCommercialesProvider.overrideWithValue(
            const PolitiquesCommercialesDemo(),
          ),
          portRechargeFoyerProvider.overrideWithValue(
            RechargeFoyerFinanceDemo(jeu),
          ),
        ],
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MediaQuery(
              data: MediaQueryData(
                size: taille,
                textScaler: TextScaler.linear(echelle),
              ),
              child: MaterialApp.router(
                theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
                routerConfig: routeur,
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

/// Les liens « Recharger {prenom} » poses sous les cartes.
final Finder _liensRecharger = find.byWidgetPredicate(
  (Widget w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith(
        'foyer.finances.recharger.',
      ),
);

void main() {
  testWidgets('la synthese des soldes, rendue telle quelle', (
    WidgetTester tester,
  ) async {
    await _monter(tester, jeu: JeuFoyerFinance.unARegulariser);
    final SyntheseFoyer s = DonneesFinanceDemo.finances(
      JeuFoyerFinance.unARegulariser,
    ).synthese;
    expect(find.byKey(SyntheseSoldesFoyer.cle), findsOneWidget);
    expect(find.text(formaterMontant(s.totalSoldes)), findsOneWidget);
    expect(find.text(t.argent.soldes.totalDetail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chaque carte porte l etat, le solde et le prochain debit', (
    WidgetTester tester,
  ) async {
    await _monter(tester, jeu: JeuFoyerFinance.unARegulariser);
    final List<FinancesProfil> profils = DonneesFinanceDemo.profils(
      JeuFoyerFinance.unARegulariser,
    );
    expect(find.byType(CarteMembre), findsNWidgets(profils.length));
    for (final FinancesProfil p in profils) {
      final Finder carte = find.ancestor(
        of: find.text(p.prenom).first,
        matching: find.byType(CarteMembre),
      );
      expect(
        find.descendant(
          of: carte,
          matching: find.text(PastilleFinanciere.libelleDe(p.etat)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.foyer.finances.soldeActuel),
        ),
        findsOneWidget,
      );
    }
    // Ibrahim : le manque exact, ecrit par le formateur, jamais calcule.
    final FinancesProfil ibrahim = profils.firstWhere(
      (FinancesProfil p) => p.etat == EtatFinancier.aRegulariser,
    );
    expect(
      find.text(
        t.foyer.finances.manque(montant: formaterMontant(ibrahim.manque!)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('« Recharger Ibrahim » ouvre la recharge avec Ibrahim coche', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      jeu: JeuFoyerFinance.unARegulariser,
    );
    final FinancesProfil ibrahim = DonneesFinanceDemo.profils(
      JeuFoyerFinance.unARegulariser,
    ).firstWhere((FinancesProfil p) => p.etat == EtatFinancier.aRegulariser);
    // Seul le profil qui en a besoin porte le lien.
    expect(
      find.byKey(FoyerPage.rechargerPourKey(ibrahim.profilId)),
      findsOneWidget,
    );
    expect(_liensRecharger, findsOneWidget);
    final Finder lien = find.byKey(
      FoyerPage.rechargerPourKey(ibrahim.profilId),
    );
    await tester.ensureVisible(lien);
    await tester.tap(lien);
    await stabiliser(tester);
    expect(routeur.state.uri.path, Routes.tuteurFoyerRecharge);
    expect(routeur.state.uri.queryParameters['profils'], ibrahim.profilId);
    final RechargeFoyerPage page = tester.widget<RechargeFoyerPage>(
      find.byType(RechargeFoyerPage),
    );
    expect(page.preselection, <String>{ibrahim.profilId});
  });

  testWidgets('« Recharger plusieurs profils » ouvre la meme recharge, rien '
      'de coche', (WidgetTester tester) async {
    final GoRouter routeur = await _monter(
      tester,
      jeu: JeuFoyerFinance.tousFinances,
    );
    // Tout est finance : aucun lien par enfant.
    expect(_liensRecharger, findsNothing);
    final Finder bouton = find.byKey(SyntheseSoldesFoyer.rechargerKey);
    await tester.ensureVisible(bouton);
    await tester.tap(bouton);
    await stabiliser(tester);
    expect(routeur.state.uri.path, Routes.tuteurFoyerRecharge);
    expect(
      tester
          .widget<RechargeFoyerPage>(find.byType(RechargeFoyerPage))
          .preselection,
      isEmpty,
    );
  });

  testWidgets('un seul bouton plein : « Recharger plusieurs profils » est '
      'secondaire', (WidgetTester tester) async {
    await _monter(tester, jeu: JeuFoyerFinance.unARegulariser);
    final Iterable<ActionPrincipale> pleins = tester
        .widgetList<ActionPrincipale>(find.byType(ActionPrincipale))
        .where((ActionPrincipale a) => a.niveau == NiveauAction.principale);
    expect(pleins, hasLength(1));
    expect(
      tester
          .widget<ActionPrincipale>(
            find.byKey(SyntheseSoldesFoyer.rechargerKey),
          )
          .niveau,
      NiveauAction.secondaire,
    );
  });

  testWidgets('sans source (production, ou le second adulte) : aucun bloc '
      'd argent, aucun bouton de recharge', (WidgetTester tester) async {
    await _monter(
      tester,
      jeu: JeuFoyerFinance.unARegulariser,
      avecFinances: false,
    );
    expect(find.byType(CarteMembre), findsWidgets);
    expect(find.byKey(SyntheseSoldesFoyer.cle), findsNothing);
    expect(find.byType(BlocFinanceMembre), findsNothing);
    expect(find.byKey(SyntheseSoldesFoyer.rechargerKey), findsNothing);
    expect(_liensRecharger, findsNothing);
  });

  testWidgets('essai : « n sur 2 », le maximum lu dans la politique', (
    WidgetTester tester,
  ) async {
    await _monter(tester, jeu: JeuFoyerFinance.unEnEssai);
    final FinancesProfil essai = DonneesFinanceDemo.profils(
      JeuFoyerFinance.unEnEssai,
    ).firstWhere((FinancesProfil p) => p.etat == EtatFinancier.essai);
    expect(
      find.text(
        t.foyer.finances.essai(
          n: essai.essaisUtilises!,
          max: DonneesFinanceDemo.politiqueLancement.essaisMax,
        ),
      ),
      findsOneWidget,
    );
  });

  for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
    for (final (double, double) cas in const <(double, double)>[
      (320, 2),
      (390, 1),
      (1440, 1),
    ]) {
      testWidgets('${jeu.name}, ${cas.$1.toInt()} px, texte '
          'x${cas.$2.toInt()} : aucun debordement', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          jeu: jeu,
          taille: Size(cas.$1, 4000),
          echelle: cas.$2,
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byType(CarteMembre),
          findsNWidgets(DonneesFinanceDemo.profils(jeu).length),
        );
      });
    }
  }
}
