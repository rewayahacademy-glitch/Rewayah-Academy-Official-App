// FI-12 : recette transverse de la voie Finance (guide Finance V4 §10, §13,
// §14), depuis la VRAIE coquille et le VRAI routeur (`routeurProvider`,
// `RewayahApp`) branches sur les demonstrations (`surchargesDemoTuteur`,
// `surchargesDemoAdmin`, `/demo/finance`).
//
// Ce fichier n'ajoute que ce qui manquait. Ce qui est deja tenu ailleurs est
// cite au debut de chaque groupe, avec son fichier et son test, et n'est pas
// rejoue ici.
//
// (a) Un test par bouton ou lien d'action d'un ecran Finance : on appuie,
//     on verifie la destination ou l'effet.
// (b) Un test par refus du guide §13.
// (c) Les points du §14 que l'on peut mesurer par un test.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/app.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/accent_profil.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/admin_shell.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/identite_profil.dart';
import 'package:rewayah_academy/core/widgets/ligne_moyen_paiement.dart';
import 'package:rewayah_academy/core/widgets/pastille_financiere.dart';
import 'package:rewayah_academy/core/widgets/pressable.dart';
import 'package:rewayah_academy/features/admin_finance/finance_page.dart';
import 'package:rewayah_academy/features/admin_finance/politiques_commerciales.dart';
import 'package:rewayah_academy/features/admin_finance/vue_globale_finance.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/demo/demo_finance_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/demo/repere_demonstration.dart';
import 'package:rewayah_academy/features/foyer/fiche/finances_page.dart';
import 'package:rewayah_academy/features/foyer/finances_foyer.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';
import 'package:rewayah_academy/features/foyer/photo_eleve.dart';
import 'package:rewayah_academy/features/foyer/transactions_foyer.dart';

import '../../router/support_routeur.dart' show stabiliser;
import '../../support/selecteur_section.dart';

/// Le 4 octobre 2026 a midi, le mois de reference de la demonstration.
final DateTime _maintenant = DateTime(2026, 10, 4, 12);

const String _mariam = DonneesFinanceDemo.mariamId;
const String _ibrahim = DonneesFinanceDemo.ibrahimId;

/// Les couleurs de profil que le tuteur de la demonstration a choisies
/// (`surchargesDemoTuteur`) : la reference de chaque ecran.
const Map<String, AccentProfil> _accentsAttendus = <String, AccentProfil>{
  'Mariam': AccentProfil.rose,
  'Ibrahim': AccentProfil.ciel,
  'Aïcha': AccentProfil.lavande,
  'Youssef': AccentProfil.peche,
  'Khadija': AccentProfil.sable,
};

/// Le foyer du jeu [jeu], dans l'ordre inverse de la demonstration.
List<EleveDuFoyer> _foyerInverse(JeuFoyerFinance jeu) => <EleveDuFoyer>[
  for (final FinancesProfil p in DonneesFinanceDemo.profils(jeu).reversed)
    EleveDuFoyer(
      id: p.profilId,
      prenom: p.prenom,
      identifiantImmuable: 'STUD-FI-${p.profilId}',
      mode: InterfaceMode.standard,
      camera: CameraPolicy.allowed,
    ),
];

/// Monte l'application du tuteur de la demonstration Finance sur le VRAI
/// routeur, puis va a [depart]. [surcharges] ne touche que des lectures que
/// la demonstration ne surcharge pas (pannes, politique injectee).
/// [sansRetentative] coupe les nouvelles tentatives silencieuses de
/// Riverpod 3 : seul « Reessayer » peut alors relire.
Future<GoRouter> _monterTuteur(
  WidgetTester tester, {
  JeuFoyerFinance jeu = JeuFoyerFinance.unARegulariser,
  String depart = Routes.tuteurFoyer,
  List<EleveDuFoyer>? eleves,
  List<Override> surcharges = const <Override>[],
  bool sansRetentative = false,
  Size taille = const Size(390, 2400),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // Un nouveau conteneur a chaque montage : un ProviderScope reconstruit au
  // meme endroit garderait les surcharges du montage precedent.
  await tester.pumpWidget(const SizedBox.shrink());
  late GoRouter routeur;
  await tester.pumpWidget(
    ProviderScope(
      retry: sansRetentative ? (int _, Object _) => null : null,
      overrides: <Override>[
        ...surchargesDemoTuteur(
          environnement: 'staging',
          finances: jeu,
          eleves: eleves,
        ),
        horlogeFoyerProvider.overrideWithValue(() => _maintenant),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: Consumer(
          builder: (BuildContext _, WidgetRef ref, Widget? _) {
            routeur = ref.read(routeurProvider);
            return MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

/// Monte la VRAIE application de la direction en demonstration
/// (`?demo=admin`), puis va a [depart].
Future<GoRouter> _monterAdmin(
  WidgetTester tester, {
  String depart = Routes.adminFinancePolitiques,
  List<Override> surcharges = const <Override>[],
  Size taille = const Size(1440, 3200),
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...surchargesDemoAdmin(environnement: 'staging'),
        ...surcharges,
      ],
      child: TranslationProvider(
        child: RewayahApp(
          builder: (BuildContext context, Widget? child) =>
              RepereDemonstration(child: child),
        ),
      ),
    ),
  );
  await stabiliser(tester);
  final GoRouter routeur = ProviderScope.containerOf(
    tester.element(find.byType(RewayahApp)),
  ).read(routeurProvider);
  routeur.go(depart);
  await stabiliser(tester);
  return routeur;
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await stabiliser(tester);
}

String _chemin(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri.path;

Uri _adresse(GoRouter routeur) =>
    routeur.routerDelegate.currentConfiguration.uri;

Finder _dans(Finder parent, Finder cible) =>
    find.descendant(of: parent, matching: cible);

Finder _etat(NatureEtat nature) => find.byWidgetPredicate(
  (Widget w) => w is EtatSysteme && w.nature == nature,
);

bool _coche(WidgetTester tester, String id) =>
    tester.widget<Checkbox>(find.byKey(RechargeFoyerPage.caseDe(id))).value ??
    false;

/// Les couleurs de profil rendues a l'ecran, par prenom : l'identite d'un
/// profil (`IdentiteProfil`), et chaque bandeau d'identite (`BandeauProfil`)
/// autour d'une photo ou d'une vignette d'eleve.
Map<String, Set<AccentProfil?>> _accentsRendus(WidgetTester tester) {
  final Map<String, Set<AccentProfil?>> vus = <String, Set<AccentProfil?>>{};
  void noter(String prenom, AccentProfil? accent) =>
      vus.putIfAbsent(prenom, () => <AccentProfil?>{}).add(accent);
  for (final IdentiteProfil i in tester.widgetList<IdentiteProfil>(
    find.byType(IdentiteProfil),
  )) {
    noter(i.prenom, i.accent);
  }
  for (final Element e in find.byType(BandeauProfil).evaluate()) {
    final AccentProfil? accent = (e.widget as BandeauProfil).accent;
    final Finder dedans = find.descendant(
      of: find.byWidget(e.widget),
      matching: find.byWidgetPredicate(
        (Widget w) => w is PhotoEleve || w is AvatarTile,
      ),
    );
    for (final Widget w in tester.widgetList(dedans)) {
      noter(switch (w) {
        final PhotoEleve p => p.prenom,
        final AvatarTile a => a.prenom,
        _ => '',
      }, accent);
    }
  }
  return vus;
}

/// Coche Mariam, prend le premier montant propose et passe a l'etape 2.
Future<void> _versEtape2(WidgetTester tester) async {
  await _toucher(tester, find.byKey(RechargeFoyerPage.caseDe(_mariam)));
  await _toucher(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
  await _toucher(tester, find.byKey(RechargeFoyerPage.verifierKey));
  expect(find.byKey(RechargeFoyerPage.recapitulatifKey), findsOneWidget);
}

/// Les fichiers Dart de [dossier], hors code genere.
Iterable<File> _sources(String dossier) => Directory(dossier)
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

/// Les lignes de code de [f] (commentaires exclus), avec leur numero.
Iterable<(int, String)> _lignesDeCode(File f) sync* {
  final List<String> lignes = f.readAsLinesSync();
  for (int i = 0; i < lignes.length; i++) {
    if (lignes[i].trimLeft().startsWith('//')) continue;
    yield (i + 1, lignes[i]);
  }
}

/// Un tarif, un montant ou une devise ecrit en dur dans un ecran : un
/// `Montant` construit avec un nombre non nul, `usd(...)`, « 50 USD »,
/// « 50 $ » (ecrit `\$` en Dart).
final RegExp _tarifEnDur = RegExp(
  r'Montant\(\s*-?[1-9][0-9]*\s*[,*)]'
  r'|\busd\('
  r'|\b[0-9]+(\s|\\u00A0)?(USD|EUR|GBP|XOF|GNF)\b'
  r'|[0-9](\s|\\u00A0)?\\\$',
);

/// Les anciens montants du guide (§1.4, §2, §12) : la paie 20/26 USD par
/// eleve, le bonus 10/20, les remises 5/10 sur tous les membres. Une date
/// « 5/10/2026 » n'est pas un montant.
final RegExp _ancienMontant = RegExp(
  r'(?<![\d/])(20|26)(\s|\\u00A0)?(USD|\\?\$)'
  r'|(?<![\d/])(20\s*/\s*26|10\s*/\s*20|5\s*/\s*10)(?![\d/])'
  r'|\busd\(\s*(20|26)\s*\)'
  r'|Montant\(\s*(2000|2600)\s*,',
);

/// La base de la voie Finance (branche `ui/finance-v1`).
const String _baseFinance = 'aebd21a5';

/// Vrai quand le depot local connait la base (un clone superficiel ne la
/// connait pas toujours).
final bool _baseConnue =
    Process.runSync('git', <String>[
      'cat-file',
      '-e',
      '$_baseFinance^{commit}',
    ]).exitCode ==
    0;

void main() {
  // ---------------------------------------------------------------------
  // (a) Les actions de chaque ecran Finance
  // ---------------------------------------------------------------------

  // Deja tenu, sur le vrai routeur :
  // - Foyer, « Recharger plusieurs profils » et « Recharger Ibrahim » :
  //   test/features/foyer/foyer_finances_test.dart (« Recharger Ibrahim »
  //   ouvre la recharge..., « Recharger plusieurs profils » ouvre la meme
  //   recharge...) ;
  // - Foyer 1440, « Voir tout » des transactions :
  //   test/features/foyer/foyer_bureau_test.dart (1440 : trois dernieres
  //   transactions...) ;
  // - Foyer, carte d'un enfant -> fiche -> Finances, et le retour :
  //   test/features/foyer/fiche_eleve_finances_test.dart (Foyer -> fiche de
  //   Mariam -> Finances...).
  group('(a) Foyer', () {
    testWidgets('synthese en echec : « Reessayer » relit les finances', (
      WidgetTester tester,
    ) async {
      bool panne = true;
      int lectures = 0;
      await _monterTuteur(
        tester,
        sansRetentative: true,
        surcharges: <Override>[
          financesFoyerProvider.overrideWith((Ref _) async {
            lectures++;
            if (panne) throw StateError('lecture refusee');
            return DonneesFinanceDemo.finances(JeuFoyerFinance.unARegulariser);
          }),
        ],
      );
      final Finder synthese = find.byKey(SyntheseSoldesFoyer.cle);
      expect(_dans(synthese, _etat(NatureEtat.echecServeur)), findsOneWidget);
      expect(find.byKey(SyntheseSoldesFoyer.rechargerKey), findsNothing);
      panne = false;
      await stabiliser(tester);
      // Sans geste, rien ne relit en silence.
      expect(_dans(synthese, _etat(NatureEtat.echecServeur)), findsOneWidget);
      final int avant = lectures;
      await _toucher(
        tester,
        _dans(
          synthese,
          find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
        ),
      );
      expect(lectures, avant + 1);
      expect(find.byKey(SyntheseSoldesFoyer.rechargerKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440, transactions en echec : « Reessayer » les relit', (
      WidgetTester tester,
    ) async {
      bool panne = true;
      await _monterTuteur(
        tester,
        taille: const Size(1440, 2400),
        sansRetentative: true,
        surcharges: <Override>[
          derniersMouvementsFoyerProvider.overrideWith((Ref _) async {
            if (panne) throw StateError('lecture refusee');
            return DonneesFinanceDemo.derniersMouvements(
              JeuFoyerFinance.unARegulariser,
              limite: nombreDernieresTransactions,
            );
          }),
        ],
      );
      final Finder bloc = find.byKey(DernieresTransactionsFoyer.cle);
      expect(_dans(bloc, _etat(NatureEtat.echecServeur)), findsOneWidget);
      expect(find.byKey(DernieresTransactionsFoyer.voirToutKey), findsNothing);
      panne = false;
      await _toucher(
        tester,
        _dans(
          bloc,
          find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
        ),
      );
      expect(
        find.byKey(DernieresTransactionsFoyer.voirToutKey),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  // Deja tenu, sur le vrai routeur :
  // - Fiche > Finances, « Recharger Mariam », « Mouvements », retour,
  //   « Reessayer » : test/features/foyer/fiche_eleve_finances_test.dart ;
  // - Mouvements, retour, filtre par personne, « Voir le recu » et sa
  //   fermeture, « Reessayer » :
  //   test/features/foyer/fiche_eleve_mouvements_test.dart.

  // Deja tenu, sur le vrai routeur (test/features/foyer/
  // recharge_multi_profils_test.dart) : cases, plus et moins, « Tout
  // selectionner », « Verifier », « Modifier », l'abandon vers le Foyer ou
  // vers Compte > Paiements ; (resultat_recharge_test.dart) « Payer »,
  // « Suivre le paiement », « Revenir aux paiements » d'un paiement
  // indisponible (recharge_foyer_adulte_test.dart).
  group('(a) Recharge', () {
    testWidgets('etape 2 : le retour ramene a l etape 1, les choix gardes', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterTuteur(
        tester,
        depart: Routes.tuteurFoyerRecharge,
      );
      await _versEtape2(tester);
      await _toucher(
        tester,
        _dans(find.byType(RechargeFoyerPage), find.byType(DisqueRetour)),
      );
      expect(_chemin(routeur), Routes.tuteurFoyerRecharge);
      expect(find.byKey(RechargeFoyerPage.recapitulatifKey), findsNothing);
      expect(find.byKey(RechargeFoyerPage.verifierKey), findsOneWidget);
      expect(_coche(tester, _mariam), isTrue);
      expect(_coche(tester, _ibrahim), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('etape 2 : le moyen de paiement se choisit, sans payer ni '
        'quitter la page', (WidgetTester tester) async {
      final GoRouter routeur = await _monterTuteur(
        tester,
        depart: Routes.tuteurFoyerRecharge,
      );
      await _versEtape2(tester);
      final Finder ligne = find.byType(LigneMoyenPaiement);
      expect(ligne, findsOneWidget);
      await _toucher(tester, ligne);
      final LigneMoyenPaiement lue = tester.widget<LigneMoyenPaiement>(ligne);
      expect(lue.rail, RailPaiement.webStripe);
      expect(lue.retenu, isTrue);
      expect(_chemin(routeur), Routes.tuteurFoyerRecharge);
      expect(find.byKey(RechargeFoyerPage.payerKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // Deja tenu, sur le vrai routeur (test/features/foyer/
  // resultat_recharge_test.dart) : « Actualiser » jusqu'a termine, « Retour
  // aux soldes » vers le Foyer, « Reessayer » et « Recommencer » vers
  // l'etape 1, « Changer de moyen » et « Verifier » vers l'etape 2,
  // « Revenir aux paiements » d'une adresse sans commande, « Reessayer »
  // d'une lecture en echec.
  //
  // Deja tenu, acces enfant, tuteur et adulte : « Rejoindre » present et
  // actif selon la periode financee
  // (test/features/acces_finance/acces_finance_test.dart, vrai routeur au
  // groupe tuteur).
  //
  // Deja tenu, Mes finances de l'adulte depuis la VRAIE coquille adulte
  // (/demo/adulte) : « Recharger », « Mouvements », retours, « Reessayer »
  // (test/features/mon_espace_adulte/mes_finances_test.dart).
  //
  // Deja tenu, Revenus enseignant depuis la vraie coquille et la
  // demonstration : la ligne « Mes revenus » du Profil, le retour,
  // « Reessayer » (test/features/revenus_enseignant/revenus_enseignant_test
  // .dart).
  //
  // Deja tenu, Admin : « Finance » dans la barre et le tiroir, l'onglet
  // Politiques commerciales (test/features/admin_finance/finance_domaine
  // _test.dart).
  group('(a) Admin Finance, vraie application', () {
    testWidgets('Vue globale en echec : « Reessayer » relit', (
      WidgetTester tester,
    ) async {
      int lectures = 0;
      await _monterAdmin(
        tester,
        depart: Routes.adminFinance,
        surcharges: <Override>[
          vueGlobaleFinanceProvider.overrideWith((Ref _) async {
            lectures++;
            throw StateError('panne');
          }),
        ],
      );
      expect(find.byType(FinancePage), findsOneWidget);
      expect(_etat(NatureEtat.echecServeur), findsOneWidget);
      await _toucher(
        tester,
        find.text(EtatSysteme.libelleActionPar(NatureEtat.echecServeur)),
      );
      expect(lectures, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Politiques : le nombre d enfants relit l apercu sur le port', (
      WidgetTester tester,
    ) async {
      await _monterAdmin(tester);
      expect(find.byType(PolitiquesCommercialesContenu), findsOneWidget);
      final pol = t.admin.finance.pol;
      final Finder total = find.byKey(
        PolitiquesCommercialesContenu.apercuTotalKey,
      );
      await _toucher(tester, find.text(pol.apercuEnfants(n: 5)));
      final ApercuFamille cinq = DonneesFinanceDemo.apercuFamille(
        DonneesFinanceDemo.politiqueBrouillon,
        5,
      );
      expect(_dans(total, find.text(formaterMontant(cinq.total))), findsOne);
      expect(
        find.byKey(PolitiquesCommercialesContenu.apercuEnfantKey(5)),
        findsOneWidget,
      );
      await _toucher(tester, find.text(pol.apercuEnfants(n: 1)));
      expect(
        find.byKey(PolitiquesCommercialesContenu.apercuEnfantKey(2)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Politiques : « un siege de moins » et le type de classe '
        'relisent le taux', (WidgetTester tester) async {
      await _monterAdmin(tester);
      final pol = t.admin.finance.pol;
      final Finder taux = find.byKey(
        PolitiquesCommercialesContenu.apercuTauxKey,
      );
      String parHeure(ApercuEnseignant a) =>
          pol.parHeure(montant: formaterMontant(a.tauxHoraire));
      final PolitiqueCommerciale b = DonneesFinanceDemo.politiqueBrouillon;
      await _toucher(
        tester,
        find.byWidgetPredicate(
          (Widget w) =>
              w is BoutonIcone && w.libelle == pol.apercuEligiblesMoins,
        ),
      );
      expect(
        _dans(
          taux,
          find.text(
            parHeure(
              DonneesFinanceDemo.apercuEnseignant(
                b,
                capacite: b.capaciteEnfant,
                eligibles: b.capaciteEnfant - 1,
              ),
            ),
          ),
        ),
        findsOneWidget,
      );
      await _toucher(tester, find.text(pol.apercuClasseAdultes));
      expect(
        _dans(
          taux,
          find.text(
            parHeure(
              DonneesFinanceDemo.apercuEnseignant(
                b,
                capacite: b.capaciteAdulte,
                eligibles: b.capaciteAdulte,
              ),
            ),
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Politiques : « Publier » dit l etat honnete, rien n est '
        'publie', (WidgetTester tester) async {
      final GoRouter routeur = await _monterAdmin(tester);
      final pol = t.admin.finance.pol;
      await _toucher(tester, find.text(pol.publier));
      expect(find.text(pol.publicationIndisponible), findsOneWidget);
      // Aucun succes, la meme page, la version active toujours en place.
      expect(_chemin(routeur), Routes.adminFinancePolitiques);
      expect(
        find.text(
          pol.versionActive(
            version: DonneesFinanceDemo.politiqueLancement.version,
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('(a) /demo/finance', () {
    testWidgets('Politiques -> « Vue globale », puis « Finance » de la barre : '
        'la demonstration ne la quitte jamais', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final GoRouter routeur = GoRouter(
        initialLocation: adresseDemoFinance(OngletFinance.politiques),
        routes: routesDemoFinance('staging'),
      );
      addTearDown(routeur.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp.router(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              locale: AppLocale.fr.flutterLocale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              routerConfig: routeur,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PolitiquesCommercialesContenu), findsOneWidget);
      await choisirSection(tester, t.admin.finance.vueGlobale);
      await tester.pumpAndSettle();
      expect(_adresse(routeur).path, Routes.demoFinance);
      expect(
        _adresse(routeur).queryParameters['ecran'],
        OngletFinance.vueGlobale.name,
      );
      expect(find.byType(VueGlobaleFinanceContenu), findsOneWidget);

      routeur.go(adresseDemoFinance(OngletFinance.politiques));
      await tester.pumpAndSettle();
      await tester.tap(
        _dans(
          find.byKey(AdminShell.barreLateraleKey),
          find.text(t.nav.admin.finance),
        ),
      );
      await tester.pumpAndSettle();
      expect(_adresse(routeur).path, Routes.demoFinance);
      expect(
        _adresse(routeur).queryParameters['ecran'],
        OngletFinance.vueGlobale.name,
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------
  // (b) Les refus du guide §13
  // ---------------------------------------------------------------------
  group('(b) refus §13', () {
    testWidgets('1. une action a deux endroits : toute recharge ouvre LE '
        'meme moteur, sur la meme route', (WidgetTester tester) async {
      final GoRouter routeur = await _monterTuteur(tester);
      Future<void> depuis(
        String depart,
        Finder bouton,
        Set<String> coches,
      ) async {
        routeur.go(depart);
        await stabiliser(tester);
        await _toucher(tester, bouton);
        expect(_chemin(routeur), Routes.tuteurFoyerRecharge, reason: depart);
        expect(find.byType(RechargeFoyerPage), findsOneWidget, reason: depart);
        expect(
          tester
              .widget<RechargeFoyerPage>(find.byType(RechargeFoyerPage))
              .preselection,
          coches,
          reason: depart,
        );
      }

      await depuis(
        Routes.tuteurFoyer,
        find.byKey(SyntheseSoldesFoyer.rechargerKey),
        <String>{},
      );
      await depuis(
        Routes.tuteurFoyer,
        find.byKey(FoyerPage.rechargerPourKey(_ibrahim)),
        <String>{_ibrahim},
      );
      await depuis(
        Routes.ficheEleveSousPage(_ibrahim, 'finances'),
        find.byKey(FinancesElevePage.rechargerKey),
        <String>{_ibrahim},
      );
      await depuis(
        Routes.compteTuteurSousPage('paiements'),
        find.byKey(PaiementsComptePage.rechargerKey),
        <String>{},
      );

      // Dans les sources : un seul ecran de recharge, construit par le
      // routeur et par la demonstration adulte (la meme page), et un seul
      // appel au paiement.
      final List<String> constructions = <String>[];
      final List<String> paiements = <String>[];
      final List<String> pagesRecharge = <String>[];
      for (final File f in _sources('lib')) {
        for (final (int n, String l) in _lignesDeCode(f)) {
          if (l.contains('RechargeFoyerPage(') && !l.contains('const ')) {
            constructions.add(f.path);
          }
          if (RegExp(r'\.payer\(\s*$|\.payer\(recapitulatifId').hasMatch(l)) {
            paiements.add('${f.path}:$n');
          }
          if (RegExp(r'^class \w*Recharge\w*Page\b').hasMatch(l)) {
            pagesRecharge.add(l.split(' ')[1]);
          }
        }
      }
      expect(constructions.toSet(), <String>{
        'lib/core/router/app_router.dart',
        'lib/features/demo/demo_adulte_page.dart',
      });
      expect(paiements, hasLength(1));
      expect(paiements.single, startsWith('lib/features/foyer/recharge_foyer'));
      expect(pagesRecharge.toSet(), <String>{
        'RechargeFoyerPage',
        'ResultatRechargePage',
      });
    });

    testWidgets('2. un enfant ne consomme pas le solde d un autre : Ibrahim '
        'reste a regulariser malgre le solde d Aicha', (
      WidgetTester tester,
    ) async {
      final FinancesFoyer foyer = DonneesFinanceDemo.finances(
        JeuFoyerFinance.unARegulariser,
      );
      final FinancesProfil ibrahim = foyer.profils.firstWhere(
        (FinancesProfil p) => p.profilId == _ibrahim,
      );
      // Le cas du refus : un autre profil a de quoi couvrir le manque.
      expect(
        foyer.profils.any(
          (FinancesProfil p) =>
              p.profilId != _ibrahim &&
              p.solde.mineur >= ibrahim.manque!.mineur,
        ),
        isTrue,
      );
      await _monterTuteur(tester);
      final Finder carte = find.ancestor(
        of: find.text('Ibrahim').first,
        matching: find.byType(CarteMembre),
      );
      expect(
        _dans(
          carte,
          find.text(PastilleFinanciere.libelleDe(EtatFinancier.aRegulariser)),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          t.foyer.finances.manque(montant: formaterMontant(ibrahim.manque!)),
        ),
        findsOneWidget,
      );
      expect(find.byKey(FoyerPage.rechargerPourKey(_ibrahim)), findsOneWidget);
      // Les mouvements de chaque profil ne citent que lui : aucun transfert.
      for (final FinancesProfil p in foyer.profils) {
        for (final MouvementProfil m in DonneesFinanceDemo.mouvements(
          JeuFoyerFinance.unARegulariser,
          p.profilId,
        )) {
          for (final FinancesProfil autre in foyer.profils) {
            if (autre.profilId == p.profilId) continue;
            expect(m.id.contains(autre.profilId), isFalse, reason: m.id);
          }
        }
      }
    });

    testWidgets('3. le total foyer n est pas un wallet : une lecture, aucun '
        'moyen « solde du foyer » a la recharge', (WidgetTester tester) async {
      final GoRouter routeur = await _monterTuteur(tester);
      final SyntheseFoyer s = DonneesFinanceDemo.finances(
        JeuFoyerFinance.unARegulariser,
      ).synthese;
      final Finder total = find.text(formaterMontant(s.totalSoldes));
      expect(total, findsOneWidget);
      // Le total ne se touche pas et dit qu'il est une somme.
      expect(
        find.ancestor(of: total, matching: find.byType(Pressable)),
        findsNothing,
      );
      expect(find.text(t.argent.soldes.totalDetail), findsOneWidget);
      // La recharge : un seul paiement reparti, chaque part au solde de son
      // profil ; le seul moyen est le paiement web.
      routeur.go(Routes.tuteurFoyerRecharge);
      await stabiliser(tester);
      expect(find.byKey(RechargeFoyerPage.repartitionKey), findsOneWidget);
      await _versEtape2(tester);
      expect(
        tester
            .widgetList<LigneMoyenPaiement>(find.byType(LigneMoyenPaiement))
            .map((LigneMoyenPaiement l) => l.rail),
        <RailPaiement>[RailPaiement.webStripe],
      );
      expect(RailPaiement.values, hasLength(3));
      expect(find.text(formaterMontant(s.totalSoldes)), findsNothing);
    });

    testWidgets('4. un avatar garde sa couleur d un ecran a l autre', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterTuteur(tester);
      final Map<String, Set<AccentProfil?>> vus =
          <String, Set<AccentProfil?>>{};
      final Map<String, int> ecrans = <String, int>{};
      void relever(String ecran) {
        final Map<String, Set<AccentProfil?>> ici = _accentsRendus(tester);
        expect(ici, isNotEmpty, reason: ecran);
        for (final MapEntry<String, Set<AccentProfil?>> e in ici.entries) {
          vus.putIfAbsent(e.key, () => {}).addAll(e.value);
          ecrans[e.key] = (ecrans[e.key] ?? 0) + 1;
        }
      }

      relever('Foyer');
      for (final String chemin in <String>[
        Routes.ficheEleveSousPage(_ibrahim, 'finances'),
        Routes.ficheEleveSousPage(_ibrahim, 'mouvements'),
        Routes.tuteurFoyerRecharge,
      ]) {
        routeur.go(chemin);
        await stabiliser(tester);
        if (chemin.endsWith('mouvements')) {
          // L'historique n'a pas d'avatar : le recu ouvert montre la
          // repartition, profil par profil.
          await _toucher(
            tester,
            find
                .byWidgetPredicate(
                  (Widget w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith(
                        'ficheEleve.mouvements.recu.',
                      ),
                )
                .first,
          );
          relever(chemin);
          await _toucher(tester, find.byType(DisqueRetour).last);
          continue;
        }
        relever(chemin);
      }
      await _versEtape2(tester);
      relever('recapitulatif');
      for (final MapEntry<String, Set<AccentProfil?>> e in vus.entries) {
        expect(e.value, <AccentProfil?>{
          _accentsAttendus[e.key],
        }, reason: e.key);
      }
      expect(ecrans['Ibrahim'], greaterThanOrEqualTo(4));
      expect(ecrans['Mariam'], greaterThanOrEqualTo(3));
    });

    testWidgets('5. la couleur de profil ne depend pas de la place dans la '
        'liste : a l envers ou en partie, chaque profil garde sa couleur', (
      WidgetTester tester,
    ) async {
      const JeuFoyerFinance jeu = JeuFoyerFinance.cinqProfils;
      final List<EleveDuFoyer> inverse = _foyerInverse(jeu);
      final Set<int> placesKhadija = <int>{};
      for (final List<EleveDuFoyer>? eleves in <List<EleveDuFoyer>?>[
        null,
        inverse,
        // Youssef et Khadija seuls : ils changent de place a l'ecran.
        inverse.take(2).toList(),
      ]) {
        await _monterTuteur(
          tester,
          jeu: jeu,
          eleves: eleves,
          taille: const Size(390, 6000),
        );
        final List<CarteMembre> cartes = tester
            .widgetList<CarteMembre>(find.byType(CarteMembre))
            .toList();
        expect(
          cartes,
          hasLength(eleves?.length ?? DonneesFinanceDemo.profils(jeu).length),
        );
        for (final (int i, CarteMembre c) in cartes.indexed) {
          if (c.profil.prenom == 'Khadija') placesKhadija.add(i);
          expect(
            c.accent,
            _accentsAttendus[c.profil.prenom],
            reason: c.profil.prenom,
          );
        }
        for (final MapEntry<String, Set<AccentProfil?>> e in _accentsRendus(
          tester,
        ).entries) {
          expect(e.value, <AccentProfil?>{
            _accentsAttendus[e.key],
          }, reason: e.key);
        }
      }
      expect(placesKhadija.length, greaterThan(1));
    });

    testWidgets('6. aucun statut financier par la couleur seule : chaque '
        'pastille porte son mot, deux etats d un meme ton ont deux mots', (
      WidgetTester tester,
    ) async {
      // Deux etats qui partagent un ton se distinguent par leur mot.
      final Map<Object, Set<String>> parTon = <Object, Set<String>>{};
      for (final EtatFinancier e in EtatFinancier.values) {
        final String mot = PastilleFinanciere.libelleDe(e);
        expect(mot.trim(), isNotEmpty, reason: e.name);
        parTon.putIfAbsent(PastilleFinanciere.tonDe(e), () => <String>{});
        expect(parTon[PastilleFinanciere.tonDe(e)]!.add(mot), isTrue);
      }
      expect(
        EtatFinancier.values.map(PastilleFinanciere.libelleDe).toSet(),
        hasLength(EtatFinancier.values.length),
      );
      // A l'ecran, chaque pastille de chaque jeu se lit en mots.
      for (final JeuFoyerFinance jeu in JeuFoyerFinance.values) {
        await _monterTuteur(tester, jeu: jeu, taille: const Size(390, 6000));
        final Iterable<PastilleFinanciere> pastilles = tester
            .widgetList<PastilleFinanciere>(find.byType(PastilleFinanciere));
        expect(
          pastilles,
          hasLength(DonneesFinanceDemo.profils(jeu).length),
          reason: jeu.name,
        );
        for (final Element e in find.byType(PastilleFinanciere).evaluate()) {
          final Iterable<Text> textes = tester.widgetList<Text>(
            find.descendant(
              of: find.byWidget(e.widget),
              matching: find.byType(Text),
            ),
          );
          expect(
            textes.any((Text x) => (x.data ?? '').trim().isNotEmpty),
            isTrue,
            reason: '${jeu.name} ${(e.widget as PastilleFinanciere).etat}',
          );
        }
      }
    });

    test('7. aucun tarif code dans un ecran (garde de source sur '
        'lib/features)', () {
      // Contre-epreuve : le garde voit chaque ecriture d'un tarif.
      for (final String ligne in <String>[
        "const Montant(5000, 'USD')",
        'Montant(50 * 100, devise)',
        'tarif: usd(50),',
        "Text('50 USD')",
        "Text('50 \\\$')",
      ]) {
        expect(_tarifEnDur.hasMatch(ligne), isTrue, reason: ligne);
      }
      for (final String ligne in <String>[
        'formaterMontant(finance.solde)',
        'Montant(0, devise)',
        'Montant(-l.montant.mineur, devise)',
        "'\${a.prenom}'",
      ]) {
        expect(_tarifEnDur.hasMatch(ligne), isFalse, reason: ligne);
      }
      // Hors demonstration (K-09) et galerie de developpement.
      final List<String> fautes = <String>[
        for (final File f in _sources('lib/features'))
          if (!f.path.startsWith('lib/features/demo/') &&
              !f.path.startsWith('lib/features/_dev/'))
            for (final (int n, String l) in _lignesDeCode(f))
              if (_tarifEnDur.hasMatch(l)) '${f.path}:$n',
      ];
      expect(fautes, isEmpty);
    });

    testWidgets('8. le mobile n est pas etire sur bureau : a 1440, recharge '
        'et resultat restent dans leur colonne', (WidgetTester tester) async {
      final GoRouter routeur = await _monterTuteur(
        tester,
        depart: Routes.tuteurFoyerRecharge,
        taille: const Size(1440, 1600),
      );
      const double colonne = AppPage.largeurDialogue + 0.5;
      expect(
        tester.getSize(find.byKey(RechargeFoyerPage.profilsKey)).width,
        lessThanOrEqualTo(colonne),
      );
      expect(
        tester.getSize(find.byKey(RechargeFoyerPage.verifierKey)).width,
        lessThan(AppPage.largeurDialogue),
      );
      routeur.go(
        Routes.resultatRechargePour(
          DonneesFinanceDemo.commandeDemo(EtatPaiement.termine),
        ),
      );
      await stabiliser(tester);
      final Finder etat = find.byKey(
        ResultatRechargePage.etatKey(EtatPaiement.termine),
      );
      expect(etat, findsOneWidget);
      expect(tester.getSize(etat).width, lessThanOrEqualTo(colonne));
      expect(
        tester.getSize(find.byKey(ResultatRechargePage.revenirKey)).width,
        lessThan(AppPage.largeurDialogue),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. un impaye ne ferme pas le compte : chaque espace du '
        'tuteur reste ouvert, l acces a regulariser se dit', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monterTuteur(tester);
      for (final String chemin in <String>[
        Routes.tuteurAccueil,
        Routes.tuteurFoyer,
        Routes.tuteurClasses,
        Routes.tuteurCompte,
        Routes.ficheElevePour(_ibrahim),
        Routes.ficheEleveSousPage(_ibrahim, 'finances'),
        Routes.ficheEleveSousPage(_ibrahim, 'mouvements'),
        Routes.ficheEleveSousPage(_ibrahim, 'acces'),
        Routes.compteTuteurSousPage('paiements'),
      ]) {
        routeur.go(chemin);
        await stabiliser(tester);
        expect(_chemin(routeur), chemin, reason: chemin);
        expect(tester.takeException(), isNull, reason: chemin);
      }
      // La fiche Finances d'Ibrahim le dit, et propose la recharge.
      routeur.go(Routes.ficheEleveSousPage(_ibrahim, 'finances'));
      await stabiliser(tester);
      expect(find.byKey(FinancesElevePage.bandeauKey), findsOneWidget);
      expect(find.byKey(FinancesElevePage.rechargerKey), findsOneWidget);
    });

    test('10. Rejoindre ne depend pas du solde (garde de source ; le '
        'comportement : acces_finance_test.dart, « Rejoindre suit la periode '
        'financee, jamais le solde »)', () {
      final File acces = File('lib/features/acces_finance/acces_finance.dart');
      final List<String> lectures = <String>[
        for (final (int n, String l) in _lignesDeCode(acces))
          if (RegExp(r'\bsolde|balance', caseSensitive: false).hasMatch(l))
            '${acces.path}:$n',
      ];
      expect(lectures, isEmpty);
      final RegExp comparaison = RegExp(
        r'(solde|balance)\w*(\.mineur)?\s*(>|>=)\s*0',
        caseSensitive: false,
      );
      final List<String> fautes = <String>[
        for (final File f in _sources('lib'))
          for (final (int n, String l) in _lignesDeCode(f))
            if (comparaison.hasMatch(l)) '${f.path}:$n',
      ];
      expect(fautes, isEmpty);
    });

    test('11. aucune confirmation de paiement simulee (garde de source ; le '
        'parcours : resultat_recharge_test.dart, « parcours de '
        'demonstration... le succes vient du port »)', () {
      final List<String> suivis = <String>[];
      for (final File f in _sources('lib')) {
        for (final (int n, String l) in _lignesDeCode(f)) {
          if (l.contains('SuiviPaiement(') &&
              !l.contains('const SuiviPaiement({')) {
            suivis.add('${f.path}:$n');
          }
        }
      }
      // Seule la demonstration rend un suivi ; aucun ecran n'en fabrique.
      expect(
        suivis.where((String s) => !s.startsWith('lib/features/demo/')),
        isEmpty,
      );
      // La recharge ne conclut rien : elle ne lit ni n'ecrit un etat final.
      final String recharge = <String>[
        for (final (int _, String l) in _lignesDeCode(
          File('lib/features/foyer/recharge_foyer.dart'),
        ))
          l,
      ].join('\n');
      expect(recharge.contains('EtatPaiement.'), isFalse);
      expect(recharge.contains('termine'), isFalse);
    });

    test('12. aucun ancien montant 20/26, 10/20 ou 5/10 (garde de source)', () {
      for (final String ligne in <String>[
        "Text('20 USD')",
        "'26 \\\$'",
        "'paie 20/26'",
        "'bonus 10/20'",
        "'remise 5/10'",
        'usd(26)',
        "Montant(2000, 'USD')",
      ]) {
        expect(_ancienMontant.hasMatch(ligne), isTrue, reason: ligne);
      }
      for (final String ligne in <String>[
        "'le 5/10/2026'",
        "'120 USD'",
        "'20,00 € (démonstration)'",
        'usd(-5)',
      ]) {
        expect(_ancienMontant.hasMatch(ligne), isFalse, reason: ligne);
      }
      final List<String> fautes = <String>[
        for (final File f in _sources('lib'))
          for (final (int n, String l) in _lignesDeCode(f))
            if (_ancienMontant.hasMatch(l)) '${f.path}:$n',
        for (final File f in Directory(
          'assets/i18n',
        ).listSync().whereType<File>())
          for (final (int n, String l) in _lignesDeCode(f))
            if (_ancienMontant.hasMatch(l)) '${f.path}:$n',
      ];
      expect(fautes, isEmpty);
    });

    test(
      '13. FRONTEND ONLY : aucun fichier sous supabase/ modifie depuis la base '
      'ui/finance-v1 ($_baseFinance)',
      skip: _baseConnue ? false : 'base $_baseFinance absente du clone',
      () {
        final ProcessResult diff = Process.runSync('git', <String>[
          'diff',
          '--name-only',
          _baseFinance,
          '--',
          'supabase/',
        ]);
        expect(diff.exitCode, 0, reason: '${diff.stderr}');
        expect((diff.stdout as String).trim(), isEmpty);
        final ProcessResult nouveaux = Process.runSync('git', <String>[
          'ls-files',
          '--others',
          '--exclude-standard',
          '--',
          'supabase/',
        ]);
        expect((nouveaux.stdout as String).trim(), isEmpty);
      },
    );
  });

  // ---------------------------------------------------------------------
  // (c) La definition of done, §14, quand un test peut la mesurer
  // ---------------------------------------------------------------------
  //
  // Deja tenu ailleurs :
  // - recharge de un ou plusieurs profils dans le meme flux :
  //   recharge_multi_profils_test.dart (un profil, plusieurs, tous) ;
  // - resultat et etats intermediaires : resultat_recharge_test.dart (les
  //   huit etats) ;
  // - essai visible : foyer_finances_test.dart (« Essai : n/2 »),
  //   acces_finance_test.dart ;
  // - Revenus enseignant : revenus_enseignant_test.dart ; Admin Finance et
  //   Politiques : finance_domaine_test.dart, vue_globale_finance_test.dart,
  //   politiques_commerciales_test.dart ;
  // - responsive, clair et sombre, LTR et RTL, texte 200 % : les balayages
  //   de chaque fichier d'ecran ci-dessus ;
  // - « acces impaye visible sans desactiver le compte » : refus 9 ;
  // - « aucune valeur critique dans les widgets » : refus 7 et 12, et
  //   test/features/finance/finance_demo_test.dart (aucune valeur
  //   commerciale de la politique hors finance_demo.dart) ;
  // - « aucune fonction dupliquee » : refus 1.
  group('(c) definition of done §14', () {
    testWidgets('chaque ecran Finance du tuteur a sa route dans le routeur '
        'unique', (WidgetTester tester) async {
      final GoRouter routeur = await _monterTuteur(tester);
      for (final (String chemin, Type ecran) in <(String, Type)>[
        (Routes.tuteurFoyer, FoyerPage),
        (Routes.ficheEleveSousPage(_mariam, 'finances'), FinancesElevePage),
        (Routes.tuteurFoyerRecharge, RechargeFoyerPage),
        (
          Routes.resultatRechargePour(
            DonneesFinanceDemo.commandeDemo(EtatPaiement.attenteConfirmation),
          ),
          ResultatRechargePage,
        ),
      ]) {
        routeur.go(chemin);
        await stabiliser(tester);
        expect(find.byType(ecran), findsOneWidget, reason: chemin);
      }
    });

    testWidgets('parametres commerciaux injectables : une politique a trois '
        'essais se lit « Essai : 1/3 » sans toucher a l ecran', (
      WidgetTester tester,
    ) async {
      final PolitiqueCommerciale l = DonneesFinanceDemo.politiqueLancement;
      final PolitiqueCommerciale troisEssais = PolitiqueCommerciale(
        version: 'recette-3-essais',
        statut: l.statut,
        dateEffet: l.dateEffet,
        tarifEnfant: l.tarifEnfant,
        tarifAdulte: l.tarifAdulte,
        essaisMax: 3,
        remisesParRang: l.remisesParRang,
        baseHoraire: l.baseHoraire,
        plafondHoraire: l.plafondHoraire,
        capaciteEnfant: l.capaciteEnfant,
        capaciteAdulte: l.capaciteAdulte,
        capaciteDebutant: l.capaciteDebutant,
        minimumOuverture: l.minimumOuverture,
        groupesObjectif: l.groupesObjectif,
        groupesMax: l.groupesMax,
        joursConservationPlace: l.joursConservationPlace,
        margeReferencePourMille: l.margeReferencePourMille,
        railsActifs: l.railsActifs,
        allocationInternet: l.allocationInternet,
      );
      await _monterTuteur(
        tester,
        jeu: JeuFoyerFinance.unEnEssai,
        surcharges: <Override>[
          politiqueActiveProvider.overrideWith((Ref _) async => troisEssais),
        ],
      );
      final FinancesProfil essai = DonneesFinanceDemo.profils(
        JeuFoyerFinance.unEnEssai,
      ).firstWhere((FinancesProfil p) => p.etat == EtatFinancier.essai);
      expect(
        find.text(t.argent.etat.essaiCompte(n: essai.essaisUtilises!, max: 3)),
        findsOneWidget,
      );
      expect(
        find.text(
          t.argent.etat.essaiCompte(n: essai.essaisUtilises!, max: l.essaisMax),
        ),
        findsNothing,
      );
    });
  });
}
