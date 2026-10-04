// FI-4 (guide Finance V4 §4, §5.1, §8 F2 ; maquette 03) : le Foyer du tuteur
// porte la synthese des soldes et, dans la carte de chaque enfant, son etat,
// son solde et son prochain debit ; « Recharger Ibrahim » ouvre la recharge
// avec Ibrahim coche ; un seul bouton plein ; sans source (production),
// aucun bloc d'argent ni bouton de recharge. L'invariant « jamais rendu au
// second adulte » est porte par le port serveur (FI-BR-03), pas par l'ecran :
// ce fichier ne le prouve pas.

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
  PortPaiementsFoyer? paiements,
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
            paiements ?? PaiementsFoyerFinanceDemo(jeu),
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

/// Les finances de la demonstration, en comptant chaque lecture.
class _PaiementsComptes extends PaiementsFoyerFinanceDemo {
  _PaiementsComptes(super.jeu);

  int lectures = 0;

  @override
  Future<FinancesFoyer> finances() {
    lectures++;
    return super.finances();
  }
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
    // Ibrahim : le manque exact, ecrit par le formateur, jamais calcule,
    // pour le mois que son debit attendu finance (R1-05).
    final FinancesProfil ibrahim = profils.firstWhere(
      (FinancesProfil p) => p.etat == EtatFinancier.aRegulariser,
    );
    expect(
      find.text(
        t.ficheEleve.finances.manquePourMois(
          montant: formaterMontant(ibrahim.manque!),
          mois: t.commun.dates.mois[ibrahim.prochainDebit!.date.month - 1],
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a regulariser (R1-05) : la carte dit « Période à financer », '
      'jamais un « Prochain débit » deja echu, comme la fiche Finances', (
    WidgetTester tester,
  ) async {
    await _monter(tester, jeu: JeuFoyerFinance.unARegulariser);
    final FinancesProfil ibrahim = DonneesFinanceDemo.profils(
      JeuFoyerFinance.unARegulariser,
    ).firstWhere((FinancesProfil p) => p.etat == EtatFinancier.aRegulariser);
    final ProchainDebit debit = ibrahim.prochainDebit!;
    // Le debit attendu est deja passe au jour de reference.
    expect(debit.date.isBefore(_maintenant), isTrue);
    final Finder carte = find.ancestor(
      of: find.text(ibrahim.prenom).first,
      matching: find.byType(CarteMembre),
    );
    Finder dans(String texte) =>
        find.descendant(of: carte, matching: find.text(texte));
    expect(dans(t.ficheEleve.finances.periodeAFinancer), findsOneWidget);
    expect(
      dans(
        t.ficheEleve.finances.periodeAFinancerValeur(
          mois: t.commun.dates.mois[debit.date.month - 1],
          annee: debit.date.year.toString(),
          montant: formaterMontant(debit.montant),
        ),
      ),
      findsOneWidget,
    );
    expect(dans(t.foyer.finances.prochainDebit), findsNothing);
    expect(
      dans(t.foyer.finances.manque(montant: formaterMontant(ibrahim.manque!))),
      findsNothing,
    );
  });

  testWidgets('une seule date d echeance par carte (R1-11)', (
    WidgetTester tester,
  ) async {
    await _monter(tester, jeu: JeuFoyerFinance.tousFinances);
    for (final FinancesProfil p in DonneesFinanceDemo.profils(
      JeuFoyerFinance.tousFinances,
    )) {
      final Finder carte = find.ancestor(
        of: find.text(p.prenom).first,
        matching: find.byType(CarteMembre),
      );
      final String fin = dateEcheance(p.periode!.fin);
      expect(
        find.descendant(
          of: carte,
          matching: find.text(t.argent.periode.jusquau(date: fin)),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: carte, matching: find.textContaining(fin)),
        findsOneWidget,
        reason: '${p.prenom} : la date ne se dit qu une fois',
      );
    }
  });

  testWidgets('libelles de la fiche (R1-09) : « Soldes et paiements », '
      '« Enfants du foyer », « Total des soldes (lecture) », « À payer ce '
      'mois »', (WidgetTester tester) async {
    await _monter(tester, jeu: JeuFoyerFinance.tousFinances);
    expect(find.text('Soldes et paiements'), findsOneWidget);
    expect(find.text('Enfants du foyer'), findsOneWidget);
    expect(find.text('Total des soldes (lecture)'), findsOneWidget);
    expect(find.text('À payer ce mois'), findsWidgets);
    expect(find.text(t.foyer.sousTitre), findsNothing);
  });

  testWidgets('« Voir le détail » (R1-08) : la fiche Finances de l enfant '
      'finance, en un geste, son prenom dans le nom lu', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      jeu: JeuFoyerFinance.unARegulariser,
    );
    final List<FinancesProfil> profils = DonneesFinanceDemo.profils(
      JeuFoyerFinance.unARegulariser,
    );
    // Une action par carte : « Voir le détail » ou « Recharger ».
    for (final FinancesProfil p in profils) {
      expect(
        find.byKey(FoyerPage.voirDetailKey(p.profilId)),
        aRecharger(p) ? findsNothing : findsOneWidget,
      );
      expect(
        find.byKey(FoyerPage.rechargerPourKey(p.profilId)),
        aRecharger(p) ? findsOneWidget : findsNothing,
      );
    }
    final FinancesProfil mariam = profils.firstWhere(
      (FinancesProfil p) => !aRecharger(p),
    );
    final Finder lien = find.byKey(FoyerPage.voirDetailKey(mariam.profilId));
    final SemanticsHandle semantique = tester.ensureSemantics();
    expect(
      tester.getSemantics(lien).label,
      t.foyer.finances.voirDetailSemantique(prenom: mariam.prenom),
    );
    semantique.dispose();
    expect(
      find.descendant(
        of: lien,
        matching: find.text(t.foyer.finances.voirDetail),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(lien);
    await tester.tap(lien);
    await stabiliser(tester);
    expect(
      routeur.state.uri.path,
      Routes.ficheEleveSousPage(mariam.profilId, 'finances'),
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
    // R1-10 : « Recharger » a l'ecran, « Recharger Ibrahim » au lecteur.
    expect(
      find.descendant(
        of: lien,
        matching: find.text(t.foyer.finances.recharger),
      ),
      findsOneWidget,
    );
    final SemanticsHandle semantique = tester.ensureSemantics();
    expect(
      tester.getSemantics(lien).label,
      t.foyer.finances.rechargerPour(prenom: ibrahim.prenom),
    );
    semantique.dispose();
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

  testWidgets('apres la recharge (onTerminee), le Foyer relit ses finances', (
    WidgetTester tester,
  ) async {
    final _PaiementsComptes paiements = _PaiementsComptes(
      JeuFoyerFinance.unARegulariser,
    );
    final GoRouter routeur = await _monter(
      tester,
      jeu: JeuFoyerFinance.unARegulariser,
      paiements: paiements,
    );
    routeur.go(Routes.tuteurFoyerRecharge);
    await stabiliser(tester);
    final int avant = paiements.lectures;
    expect(avant, greaterThan(0));
    tester
        .widget<RechargeFoyerPage>(find.byType(RechargeFoyerPage))
        .onTerminee();
    await stabiliser(tester);
    expect(routeur.state.uri.path, Routes.tuteurFoyer);
    expect(paiements.lectures, greaterThan(avant));
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

  for (final double largeur in <double>[390, 1440]) {
    testWidgets(
      '${largeur.toInt()} : un seul bouton plein, « Recharger '
      'plusieurs profils » ; « Ajouter un profil élève » secondaire (R1-01)',
      (WidgetTester tester) async {
        await _monter(
          tester,
          jeu: JeuFoyerFinance.unARegulariser,
          taille: Size(largeur, 2400),
        );
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
          NiveauAction.principale,
        );
        expect(
          tester
              .widget<ActionPrincipale>(find.byKey(FoyerPage.ajouterKey))
              .niveau,
          NiveauAction.secondaire,
        );
      },
    );
  }

  testWidgets('sans source (production) : « Ajouter un profil élève » reste '
      'le seul bouton plein (question 1 au directeur, comportement garde)', (
    WidgetTester tester,
  ) async {
    await _monter(
      tester,
      jeu: JeuFoyerFinance.unARegulariser,
      avecFinances: false,
    );
    expect(
      tester.widget<ActionPrincipale>(find.byKey(FoyerPage.ajouterKey)).niveau,
      NiveauAction.principale,
    );
    expect(find.text(t.foyer.sousTitre), findsOneWidget);
  });

  // L'invariant « jamais rendu au second adulte » est porte par le port
  // serveur (FI-BR-03), pas par l'ecran : ce test ne prouve que l'absence de
  // source (production).
  testWidgets('sans source (production) : aucun bloc d argent, aucun bouton '
      'de recharge', (WidgetTester tester) async {
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

  testWidgets(
    'essai : « Essai : n/2 » dans la pastille, le maximum lu dans la politique',
    (WidgetTester tester) async {
      await _monter(tester, jeu: JeuFoyerFinance.unEnEssai);
      final FinancesProfil essai = DonneesFinanceDemo.profils(
        JeuFoyerFinance.unEnEssai,
      ).firstWhere((FinancesProfil p) => p.etat == EtatFinancier.essai);
      expect(
        find.text(
          t.argent.etat.essaiCompte(
            n: essai.essaisUtilises!,
            max: DonneesFinanceDemo.politiqueLancement.essaisMax,
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('1440 (FI-5, R1-03) : quatre blocs cote a cote, le 4e = le '
      'bouton puis la note', (WidgetTester tester) async {
    await _monter(
      tester,
      jeu: JeuFoyerFinance.unARegulariser,
      taille: const Size(1440, 2400),
    );
    final Finder synthese = find.byKey(SyntheseSoldesFoyer.cle);
    Finder dans(String texte) =>
        find.descendant(of: synthese, matching: find.text(texte));
    final double haut = tester.getTopLeft(dans(t.argent.soldes.total)).dy;
    for (final String cle in <String>[
      t.argent.soldes.aPayer,
      t.argent.soldes.profilsFinances,
    ]) {
      expect(tester.getTopLeft(dans(cle)).dy, moreOrLessEquals(haut));
    }
    final Rect bouton = tester.getRect(
      find.byKey(SyntheseSoldesFoyer.rechargerKey),
    );
    expect(bouton.top, moreOrLessEquals(haut, epsilon: 1));
    final Rect profils = tester.getRect(dans(t.argent.soldes.profilsFinances));
    expect(bouton.left, greaterThan(profils.right));
    // La note sous le bouton, dans le meme bloc.
    final Rect note = tester.getRect(dans(t.foyer.finances.noteSoldes));
    expect(note.top, greaterThan(bouton.bottom));
    expect(note.left, moreOrLessEquals(bouton.left, epsilon: 1));
    // « Paiements du mois » cede sa place : il est dans la vue financiere.
    expect(dans(t.argent.soldes.paiements), findsNothing);
    final Rect blocSynthese = tester.getRect(synthese);
    expect(bouton.width, lessThan(blocSynthese.width * 0.3));
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
