// FI-6a (guide Finance V4 §5.2, §8 F3 ; maquettes 02 et 06) : la sous-page
// « Finances » de la fiche eleve. Atteinte depuis le Foyer puis la fiche,
// sur le vrai routeur ; les huit cas du lot F3 (aucune remise, 3e membre,
// 4e membre, prorata, avoir, taxe, periode financee a solde nul, solde
// positif sans periode financee) ; « Recharger Mariam » ouvre la recharge
// avec Mariam cochee ; etats chargement, contenu, vide, erreur, hors ligne
// et production ; 320 px texte x2 et 1440 px, clair et sombre, LTR et RTL.

import 'dart:async';

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
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/bandeau_attention.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/ligne_finance.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/pastille_financiere.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/fiche/finances_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/ligne_membre.dart';

import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

/// Le 4 octobre 2026 a midi, dans le mois de reference de la demonstration.
final DateTime _maintenant = DateTime(2026, 10, 4, 12);

const String _mariam = DonneesFinanceDemo.mariamId;

/// Un foyer dont les eleves ont les identifiants des finances [profils].
FauxServiceAppairage _foyer(List<FinancesProfil> profils) =>
    FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[
        for (final FinancesProfil p in profils)
          EleveDuFoyer(
            id: p.profilId,
            prenom: p.prenom,
            identifiantImmuable: 'STUD-FI-${p.profilId}',
            mode: InterfaceMode.standard,
            camera: CameraPolicy.allowed,
          ),
      ];

/// Un port des finances qui rend [lecture] : des donnees injectees, un
/// echec ou une attente sans fin. Aucun calcul : les montants sont ecrits.
class _PortFinances implements PortPaiementsFoyer {
  _PortFinances(this.lecture);

  final Future<FinancesFoyer> Function() lecture;

  @override
  Future<FinancesFoyer> finances() => lecture();

  @override
  Future<List<PaiementFoyer>> historique() async => <PaiementFoyer>[];

  @override
  Future<PaiementFoyer?> detail(String id) async => null;

  @override
  Future<SoldesFoyer> soldes() async =>
      const SoldesFoyer(beneficiaires: <SoldeBeneficiaire>[]);
}

/// Mariam avec des lignes injectees (prorata, avoir, taxe) : le total est
/// ecrit par la « source », jamais calcule par l'ecran.
FinancesFoyer _mariamAvec(List<LigneMensualite> lignes, int totalUsd) {
  final FinancesProfil base = DonneesFinanceDemo.profils(
    JeuFoyerFinance.unProfil,
  ).single;
  final FinancesProfil m = FinancesProfil(
    profilId: base.profilId,
    prenom: base.prenom,
    cleAccent: base.cleAccent,
    estAdulte: false,
    classe: base.classe,
    age: base.age,
    etat: base.etat,
    solde: base.solde,
    periode: base.periode,
    prochainDebit: ProchainDebit(
      date: DonneesFinanceDemo.moisSuivant,
      montant: DonneesFinanceDemo.usd(totalUsd),
    ),
    mensualite: DonneesFinanceDemo.usd(totalUsd),
    lignesMensualite: lignes,
  );
  return FinancesFoyer(
    synthese: DonneesFinanceDemo.finances(JeuFoyerFinance.unProfil).synthese,
    profils: <FinancesProfil>[m],
  );
}

Future<GoRouter> _monter(
  WidgetTester tester, {
  JeuFoyerFinance jeu = JeuFoyerFinance.unARegulariser,
  PortPaiementsFoyer? port,
  bool avecFinances = true,
  bool horsLigne = false,
  String? depart,
  Size taille = const Size(390, 2400),
  double echelle = 1,
  Brightness luminosite = Brightness.light,
  TextDirection sens = TextDirection.ltr,
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
          appairage: _foyer(DonneesFinanceDemo.profils(jeu)),
        ),
        horlogeFoyerProvider.overrideWithValue(() => _maintenant),
        if (horsLigne)
          horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
        if (avecFinances) ...<Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            port ?? PaiementsFoyerFinanceDemo(jeu),
          ),
          portPolitiquesCommercialesProvider.overrideWithValue(
            const PolitiquesCommercialesDemo(),
          ),
          portRechargeFoyerProvider.overrideWithValue(
            const RechargeFoyerFinanceDemo(),
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
                theme: AppTheme.pour(InterfaceMode.standard, luminosite),
                routerConfig: routeur,
                builder: (BuildContext _, Widget? enfant) =>
                    Directionality(textDirection: sens, child: enfant!),
              ),
            );
          },
        ),
      ),
    ),
  );
  await stabiliser(tester);
  routeur.go(depart ?? Routes.tuteurFoyer);
  await stabiliser(tester);
  return routeur;
}

String _chemin(String id) => Routes.ficheEleveSousPage(id, 'finances');

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

Finder _etat(NatureEtat nature) => find.byWidgetPredicate(
  (Widget w) => w is EtatSysteme && w.nature == nature,
);

/// Les libelles des lignes de la decomposition affichees, total compris.
List<String> _lignes(WidgetTester tester) => <String>[
  for (final LigneFinance l in tester.widgetList<LigneFinance>(
    find.byType(LigneFinance),
  ))
    l.libelle,
];

/// La ligne de decomposition [libelle] porte le montant [montant] ecrit.
void _attendreLigne(String libelle, String montant) {
  final Finder ligne = find.byWidgetPredicate(
    (Widget w) => w is LigneFinance && w.libelle == libelle,
  );
  expect(ligne, findsOneWidget, reason: libelle);
  expect(
    find.descendant(of: ligne, matching: find.text(montant)),
    findsOneWidget,
    reason: '$libelle : $montant',
  );
}

FinancesProfil _profil(JeuFoyerFinance jeu, String id) =>
    DonneesFinanceDemo.profils(jeu)
        .firstWhere((FinancesProfil p) => p.profilId == id);

void main() {
  group('Atteinte et recharge', () {
    testWidgets('Foyer -> fiche de Mariam -> Finances, onglet Foyer actif, '
        'retour a la fiche', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(tester);
      await _toucher(tester, find.text('Mariam').first);
      expect(lieu(routeur), Routes.ficheElevePour(_mariam));
      // La ligne « Finances » dit l'etat lu.
      expect(find.text(t.ficheEleve.lignes.finances), findsOneWidget);
      expect(
        find.text(PastilleFinanciere.libelleDe(EtatFinancier.finance)),
        findsOneWidget,
      );
      await _toucher(tester, find.text(t.ficheEleve.lignes.finances));
      expect(lieu(routeur), _chemin(_mariam));
      expect(find.byType(FinancesElevePage), findsOneWidget);
      expect(tester.widget<NavShell>(find.byType(NavShell)).indexActif, 1);
      verifierUnSeulBoutonPlein(tester);

      await _toucher(tester, find.byType(DisqueRetour));
      expect(lieu(routeur), Routes.ficheElevePour(_mariam));
      expect(tester.takeException(), isNull);
    });

    testWidgets('« Recharger Mariam » ouvre la recharge avec Mariam cochee', (
      WidgetTester tester,
    ) async {
      final GoRouter routeur = await _monter(tester, depart: _chemin(_mariam));
      final Finder bouton = find.byKey(FinancesElevePage.rechargerKey);
      expect(
        tester.widget<ActionPrincipale>(bouton).libelle,
        t.foyer.finances.rechargerPour(prenom: 'Mariam'),
      );
      await _toucher(tester, bouton);
      expect(routeur.state.uri.path, Routes.tuteurFoyerRecharge);
      expect(routeur.state.uri.queryParameters['profils'], _mariam);
      expect(
        tester
            .widget<RechargeFoyerPage>(find.byType(RechargeFoyerPage))
            .preselection,
        <String>{_mariam},
      );
    });

    testWidgets('aucun lien vers les mouvements tant que leur route manque '
        '(FI-6b)', (WidgetTester tester) async {
      await _monter(tester, depart: _chemin(_mariam));
      expect(find.textContaining('ouvements'), findsNothing);
    });

    testWidgets('sans source (production, second adulte) : aucune ligne '
        '« Finances » dans la fiche', (WidgetTester tester) async {
      await _monter(
        tester,
        avecFinances: false,
        depart: Routes.ficheElevePour(_mariam),
      );
      expect(find.byType(FicheElevePage), findsOneWidget);
      expect(find.text(t.ficheEleve.lignes.finances), findsNothing);
    });
  });

  group('Les huit cas du lot F3', () {
    testWidgets('1. aucune remise : Mariam, rang 1, tarif et total seuls', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: _chemin(_mariam));
      final FinancesProfil m = _profil(JeuFoyerFinance.unARegulariser, _mariam);
      expect(_lignes(tester), <String>[
        t.ficheEleve.finances.tarifEnfant,
        t.ficheEleve.finances.total,
      ]);
      expect(find.text(t.ficheEleve.finances.remiseRang), findsNothing);
      _attendreLigne(
        t.ficheEleve.finances.total,
        formaterMontant(m.mensualite),
      );
      expect(find.byKey(FinancesElevePage.bandeauKey), findsNothing);
    });

    testWidgets('2. 3e membre : la remise rendue, -5', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        jeu: JeuFoyerFinance.tousFinances,
        depart: _chemin(DonneesFinanceDemo.aichaId),
      );
      final FinancesProfil a = _profil(
        JeuFoyerFinance.tousFinances,
        DonneesFinanceDemo.aichaId,
      );
      final LigneMensualite remise = a.lignesMensualite.singleWhere(
        (LigneMensualite l) => l.nature == NatureLigneMensualite.remiseRang,
      );
      expect(remise.montant.mineur, -500);
      _attendreLigne(
        t.ficheEleve.finances.remiseRang,
        formaterMontant(remise.montant),
      );
      _attendreLigne(
        t.ficheEleve.finances.total,
        formaterMontant(a.mensualite),
      );
    });

    testWidgets('3. 4e membre : la remise rendue, -7', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        jeu: JeuFoyerFinance.cinqProfils,
        depart: _chemin(DonneesFinanceDemo.youssefId),
      );
      final FinancesProfil y = _profil(
        JeuFoyerFinance.cinqProfils,
        DonneesFinanceDemo.youssefId,
      );
      final LigneMensualite remise = y.lignesMensualite.singleWhere(
        (LigneMensualite l) => l.nature == NatureLigneMensualite.remiseRang,
      );
      expect(remise.montant.mineur, -700);
      _attendreLigne(
        t.ficheEleve.finances.remiseRang,
        formaterMontant(remise.montant),
      );
    });

    for (final (
          String nom,
          NatureLigneMensualite nature,
          String libelle,
          int usd,
          bool signe,
        )
        in <(String, NatureLigneMensualite, String, int, bool)>[
          (
            '4. prorata',
            NatureLigneMensualite.prorata,
            t.ficheEleve.finances.prorata,
            -20,
            false,
          ),
          (
            '5. avoir',
            NatureLigneMensualite.avoir,
            t.ficheEleve.finances.avoir,
            -5,
            false,
          ),
          (
            '6. taxe',
            NatureLigneMensualite.taxe,
            t.ficheEleve.finances.taxe,
            3,
            true,
          ),
        ]) {
      testWidgets('$nom : la ligne rendue, dans l ordre, total ecrit', (
        WidgetTester tester,
      ) async {
        final int total = 50 + usd;
        final FinancesFoyer donnees = _mariamAvec(<LigneMensualite>[
          LigneMensualite(
            nature: NatureLigneMensualite.tarif,
            montant: DonneesFinanceDemo.usd(50),
          ),
          LigneMensualite(nature: nature, montant: DonneesFinanceDemo.usd(usd)),
        ], total);
        await _monter(
          tester,
          jeu: JeuFoyerFinance.unProfil,
          port: _PortFinances(() async => donnees),
          depart: _chemin(_mariam),
        );
        expect(_lignes(tester), <String>[
          t.ficheEleve.finances.tarifEnfant,
          libelle,
          t.ficheEleve.finances.total,
        ]);
        _attendreLigne(
          libelle,
          formaterMontant(DonneesFinanceDemo.usd(usd), signe: signe),
        );
        _attendreLigne(
          t.ficheEleve.finances.total,
          formaterMontant(DonneesFinanceDemo.usd(total)),
        );
        expect(find.text(t.ficheEleve.finances.remiseRang), findsNothing);
      });
    }

    testWidgets('7. periode financee avec un solde nul : « Finance », aucun '
        'bandeau', (WidgetTester tester) async {
      await _monter(
        tester,
        jeu: JeuFoyerFinance.tousFinances,
        depart: _chemin(DonneesFinanceDemo.ibrahimId),
      );
      final FinancesProfil i = _profil(
        JeuFoyerFinance.tousFinances,
        DonneesFinanceDemo.ibrahimId,
      );
      expect(i.solde.mineur, 0);
      expect(find.text(formaterMontant(i.solde)), findsOneWidget);
      expect(
        find.text(PastilleFinanciere.libelleDe(EtatFinancier.finance)),
        findsOneWidget,
      );
      expect(find.byKey(FinancesElevePage.bandeauKey), findsNothing);
    });

    testWidgets('8. solde positif sans periode financee : a regulariser, '
        'manque exact et fin de conservation', (WidgetTester tester) async {
      await _monter(tester, depart: _chemin(DonneesFinanceDemo.ibrahimId));
      final FinancesProfil i = _profil(
        JeuFoyerFinance.unARegulariser,
        DonneesFinanceDemo.ibrahimId,
      );
      expect(i.solde.mineur, greaterThan(0));
      expect(i.periode, isNull);
      expect(find.text(formaterMontant(i.solde)), findsOneWidget);
      expect(
        find.text(PastilleFinanciere.libelleDe(EtatFinancier.aRegulariser)),
        findsOneWidget,
      );
      final BandeauAttention bandeau = tester.widget<BandeauAttention>(
        find.byKey(FinancesElevePage.bandeauKey),
      );
      expect(bandeau.titre, t.ficheEleve.finances.regulariserTitre);
      expect(
        bandeau.message,
        t.ficheEleve.finances.manqueEtConservation(
          montant: formaterMontant(i.manque!),
          date: dateEcheance(i.finConservation!),
        ),
      );
      expect(find.byKey(FinancesElevePage.rechargerKey), findsOneWidget);
    });
  });

  group('Etats', () {
    testWidgets('essai : ni mensualite ni detail, « n sur 2 »', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        jeu: JeuFoyerFinance.unEnEssai,
        depart: _chemin(DonneesFinanceDemo.aichaId),
      );
      expect(find.byKey(FinancesElevePage.detailKey), findsNothing);
      expect(find.text(t.ficheEleve.finances.mensualite), findsNothing);
      expect(
        find.text(
          t.foyer.finances.essai(
            n: 1,
            max: DonneesFinanceDemo.politiqueLancement.essaisMax,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('chargement : squelette, puis contenu', (
      WidgetTester tester,
    ) async {
      final Completer<FinancesFoyer> attente = Completer<FinancesFoyer>();
      await _monter(
        tester,
        port: _PortFinances(() => attente.future),
        depart: _chemin(_mariam),
      );
      expect(find.byKey(FinancesElevePage.vueKey), findsNothing);
      attente.complete(
        DonneesFinanceDemo.finances(JeuFoyerFinance.unARegulariser),
      );
      await stabiliser(tester);
      expect(find.byKey(FinancesElevePage.vueKey), findsOneWidget);
    });

    testWidgets('erreur : titre, « Reessayer » relit la source', (
      WidgetTester tester,
    ) async {
      // En echec tant que la reprise n'est pas demandee : les nouvelles
      // tentatives de Riverpod ne doivent pas masquer l'etat d'erreur.
      bool echoue = true;
      await _monter(
        tester,
        port: _PortFinances(() async {
          if (echoue) throw Exception('lecture refusee');
          return DonneesFinanceDemo.finances(JeuFoyerFinance.unARegulariser);
        }),
        depart: _chemin(_mariam),
      );
      expect(_etat(NatureEtat.echecServeur), findsOneWidget);
      expect(
        find.text(t.ficheEleve.finances.erreurTitre(prenom: 'Mariam')),
        findsOneWidget,
      );
      expect(find.byKey(FinancesElevePage.rechargerKey), findsNothing);
      // La source repond de nouveau au moment ou la personne reessaie.
      await tester.tap(find.text(t.commun.etats.actions.reessayer));
      echoue = false;
      await stabiliser(tester);
      expect(find.byKey(FinancesElevePage.vueKey), findsOneWidget);
    });

    testWidgets('hors ligne : dit hors ligne, pas echec du serveur', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _PortFinances(() async => throw Exception('reseau')),
        horsLigne: true,
        depart: _chemin(_mariam),
      );
      expect(_etat(NatureEtat.horsLigne), findsOneWidget);
      expect(_etat(NatureEtat.echecServeur), findsNothing);
    });

    testWidgets('production : « pas encore disponible », aucun montant ni '
        'bouton', (WidgetTester tester) async {
      await _monter(tester, avecFinances: false, depart: _chemin(_mariam));
      expect(_etat(NatureEtat.indisponible), findsOneWidget);
      expect(
        find.text(t.ficheEleve.finances.indisponibleTitre),
        findsOneWidget,
      );
      expect(find.byType(LigneFinance), findsNothing);
      expect(find.byKey(FinancesElevePage.rechargerKey), findsNothing);
    });

    testWidgets('vide : la source ne rend pas ce profil', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _PortFinances(
          () async => DonneesFinanceDemo.finances(JeuFoyerFinance.unProfil),
        ),
        depart: _chemin(DonneesFinanceDemo.ibrahimId),
      );
      expect(_etat(NatureEtat.aucunResultat), findsOneWidget);
      expect(
        find.text(t.ficheEleve.finances.videTitre(prenom: 'Ibrahim')),
        findsOneWidget,
      );
    });
  });

  group('Gabarits', () {
    for (final (double, double) cas in const <(double, double)>[
      (320, 2),
      (1440, 1),
    ]) {
      for (final Brightness luminosite in Brightness.values) {
        for (final TextDirection sens in TextDirection.values) {
          for (final String id in <String>[
            _mariam,
            DonneesFinanceDemo.ibrahimId,
          ]) {
            testWidgets('${cas.$1.toInt()} px, texte x${cas.$2.toInt()}, '
                '${luminosite.name}, ${sens.name}, $id : aucun debordement', (
              WidgetTester tester,
            ) async {
              await _monter(
                tester,
                depart: _chemin(id),
                taille: Size(cas.$1, 3000),
                echelle: cas.$2,
                luminosite: luminosite,
                sens: sens,
              );
              expect(tester.takeException(), isNull);
              expect(find.byKey(FinancesElevePage.vueKey), findsOneWidget);
              verifierUnSeulBoutonPlein(tester);
            });
          }
        }
      }
    }
  });
}
