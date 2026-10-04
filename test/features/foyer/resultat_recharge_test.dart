// FI-8 (guide Finance V4 §1.6 et §5.4, maquette 01, K-59, D5) : le resultat
// d'une recharge sur `/tuteur/foyer/recharge/result?commande=`. Les huit
// etats rendus par un port de test ; le parcours de demonstration Payer ->
// resultat -> Actualiser jusqu'a `termine` ; double confirmation = un seul
// credit ; ecran rouvert en attente ; l'echec garde la selection ; aucun
// succes sans `termine` ; production, hors ligne, erreur, vide ; 320 px a
// 200 % et 1440 px, LTR et RTL, clair et sombre.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/format_montant.dart';
import 'package:rewayah_academy/core/finance/montant.dart';
import 'package:rewayah_academy/core/finance/politique_commerciale.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/identite_profil.dart';
import 'package:rewayah_academy/core/widgets/ligne_allocation.dart';
import 'package:rewayah_academy/core/widgets/ligne_cle_valeur.dart';
import 'package:rewayah_academy/core/widgets/ligne_moyen_paiement.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../router/support_routeur.dart';
import '../../support/garde_interface.dart';
import '../../support/harnais.dart';

const String _mariam = DonneesFinanceDemo.mariamId;
const String _ibrahim = DonneesFinanceDemo.ibrahimId;
const JeuFoyerFinance _jeu = JeuFoyerFinance.tousFinances;

FauxServiceAppairage _foyer() =>
    FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[
        for (final FinancesProfil p in DonneesFinanceDemo.profils(_jeu))
          EleveDuFoyer(
            id: p.profilId,
            prenom: p.prenom,
            identifiantImmuable: 'STUD-FI-${p.profilId}',
            mode: InterfaceMode.standard,
            camera: CameraPolicy.allowed,
          ),
      ];

/// Un port qui rend l'etat que le test choisit (et compte les lectures).
class _PortEtat extends RechargeFoyerFinanceDemo {
  _PortEtat(this.etat, {this.motif, this.erreur}) : super(_jeu);

  EtatPaiement etat;
  final String? motif;
  final Error? erreur;
  int lectures = 0;

  @override
  Future<SuiviPaiement> suivre(String commandeId) async {
    lectures++;
    if (erreur case final Error e) throw e;
    final bool termine = etat == EtatPaiement.termine;
    return SuiviPaiement(
      commandeId: commandeId,
      etat: etat,
      total: DonneesFinanceDemo.usd(50),
      reference: 'REF-TEST',
      date: DonneesFinanceDemo.aujourdhui,
      moyen: RailPaiement.webStripe,
      motif: motif,
      allocations: <AllocationProfil>[
        AllocationProfil(
          profilId: _mariam,
          prenom: 'Mariam',
          montant: DonneesFinanceDemo.usd(10),
          nouveauSolde: termine ? DonneesFinanceDemo.usd(38) : null,
        ),
        AllocationProfil(
          profilId: _ibrahim,
          prenom: 'Ibrahim',
          montant: DonneesFinanceDemo.usd(40),
          nouveauSolde: termine ? DonneesFinanceDemo.usd(62) : null,
        ),
      ],
    );
  }
}

Future<GoRouter> _monter(
  WidgetTester tester, {
  required String depart,
  PortRechargeFoyer? port,
  bool avecFinances = true,
  bool horsLigne = false,
  Size taille = const Size(390, 2400),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  Brightness luminosite = Brightness.light,
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
          appairage: _foyer(),
        ),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
        if (avecFinances) ...<Override>[
          portPaiementsFoyerProvider.overrideWithValue(
            const PaiementsFoyerFinanceDemo(_jeu),
          ),
          portPolitiquesCommercialesProvider.overrideWithValue(
            const PolitiquesCommercialesDemo(),
          ),
          portRechargeFoyerProvider.overrideWithValue(
            port ?? const RechargeFoyerFinanceDemo(_jeu),
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
                    Directionality(textDirection: direction, child: enfant!),
              ),
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

Future<void> _taper(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await stabiliser(tester);
}

Uri _lieu(GoRouter routeur) => routeur.routerDelegate.currentConfiguration.uri;

/// Ce qui n'apparait JAMAIS hors de `termine` (FI9).
void _aucunSucces() {
  expect(find.text(t.adulte.recharge.resultat.soldesTitre), findsNothing);
  expect(find.textContaining('Nouveau solde'), findsNothing);
  // Ni coche « Credite » ni « + » (R3-04).
  expect(find.byKey(LigneAllocation.crediteKey), findsNothing);
  expect(find.textContaining('+'), findsNothing);
  expect(
    find.byKey(ResultatRechargePage.etatKey(EtatPaiement.termine)),
    findsNothing,
  );
}

void main() {
  final String c1 = Routes.resultatRechargePour('c1');

  group('les huit etats, tels que le port les rend', () {
    for (final EtatPaiement etat in EtatPaiement.values) {
      testWidgets(etat.name, (WidgetTester tester) async {
        await _monter(
          tester,
          depart: c1,
          port: _PortEtat(
            etat,
            motif: etat == EtatPaiement.echec ? 'motif rendu' : null,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(ResultatRechargePage.etatKey(etat)), findsOneWidget);
        // Jamais de « Payer » sur le resultat.
        expect(find.byKey(RechargeFoyerPage.payerKey), findsNothing);
        // La repartition : on voit a qui va chaque montant.
        expect(
          find.byKey(ResultatRechargePage.allocationDe(_mariam)),
          findsOneWidget,
        );
        expect(
          find.byKey(ResultatRechargePage.allocationDe(_ibrahim)),
          findsOneWidget,
        );
        verifierUnSeulBoutonPlein(tester);
        final r = t.adulte.recharge.resultat;
        // R3-04 : chaque part creditee porte la coche lue « Credite » et
        // son « + », a `termine` seulement.
        final bool termine = etat == EtatPaiement.termine;
        expect(
          find.byKey(LigneAllocation.crediteKey),
          termine ? findsNWidgets(2) : findsNothing,
        );
        expect(
          find.bySemanticsLabel(
            RegExp(RegExp.escape(t.argent.allocation.credite)),
          ),
          termine ? findsNWidgets(2) : findsNothing,
        );
        for (final int part in <int>[10, 40]) {
          expect(
            find.text(
              formaterMontant(DonneesFinanceDemo.usd(part), signe: true),
            ),
            termine ? findsOneWidget : findsNothing,
          );
          expect(
            find.text(formaterMontant(DonneesFinanceDemo.usd(part))),
            termine ? findsNothing : findsOneWidget,
          );
        }
        // R3-06 : « Retour aux soldes » dans tous les etats, jamais
        // « Revenir aux paiements du foyer » pour la meme cible.
        expect(find.text(t.adulte.recharge.revenirPaiements), findsNothing);
        if (find.byKey(ResultatRechargePage.revenirKey).evaluate().isNotEmpty) {
          expect(find.text(r.retourSoldes), findsOneWidget);
        }
        // R3-03 (FI12-E07) : dans la carte, la ligne garde la marge de la
        // carte des deux cotes, et le bandeau remonte dans la marge de la
        // ligne : l'avatar a cote du prenom, jamais sous lui.
        final Rect carte = tester.getRect(
          find.byKey(ResultatRechargePage.repartitionKey),
        );
        for (final String profil in <String>[_mariam, _ibrahim]) {
          final Rect ligne = tester.getRect(
            find.descendant(
              of: find.byKey(ResultatRechargePage.allocationDe(profil)),
              matching: find.byType(LigneCleValeur),
            ),
          );
          expect(ligne.left - carte.left, greaterThanOrEqualTo(AppSpacing.lg));
          expect(
            carte.right - ligne.right,
            greaterThanOrEqualTo(AppSpacing.lg),
          );
          expect(
            tester
                .widget<BandeauProfil>(
                  find.descendant(
                    of: find.byKey(ResultatRechargePage.allocationDe(profil)),
                    matching: find.byType(BandeauProfil),
                  ),
                )
                .remontee,
            LigneCleValeur.margeVerticale,
          );
        }
        switch (etat) {
          case EtatPaiement.preparation:
            expect(find.text(r.preparationPhrase), findsOneWidget);
            // La phrase demande de verifier : le geste y mene (K-59).
            expect(
              find.byKey(ResultatRechargePage.verifierKey),
              findsOneWidget,
            );
            expect(find.byKey(ResultatRechargePage.revenirKey), findsOneWidget);
            expect(
              find.byKey(ResultatRechargePage.actualiserKey),
              findsOneWidget,
            );
            _aucunSucces();
          case EtatPaiement.attenteConfirmation:
            expect(find.text(r.attenteTitre), findsOneWidget);
            expect(find.text(r.attenteBandeauTitre), findsOneWidget);
            expect(
              find.byKey(ResultatRechargePage.actualiserKey),
              findsOneWidget,
            );
            _aucunSucces();
          case EtatPaiement.confirme:
            expect(find.text(r.confirmeTitre), findsOneWidget);
            expect(find.text(r.confirmePhrase), findsOneWidget);
            _aucunSucces();
          case EtatPaiement.allocationEnCours:
            expect(find.text(r.confirmeTitre), findsOneWidget);
            expect(find.text(r.allocationPhrase), findsOneWidget);
            _aucunSucces();
          case EtatPaiement.termine:
            // Maquette 01 : total, reference, moyen, date, repartition,
            // nouveau solde par profil, soldes mis a jour.
            expect(
              find.text(
                r.terminePhrase(
                  montant: formaterMontant(DonneesFinanceDemo.usd(50)),
                ),
              ),
              findsOneWidget,
            );
            expect(find.text('REF-TEST'), findsOneWidget);
            expect(find.byType(LigneMoyenPaiement), findsOneWidget);
            expect(
              find.text(
                r.nouveauSolde(
                  montant: formaterMontant(DonneesFinanceDemo.usd(38)),
                ),
              ),
              findsOneWidget,
            );
            expect(
              find.text(
                r.nouveauSolde(
                  montant: formaterMontant(DonneesFinanceDemo.usd(62)),
                ),
              ),
              findsOneWidget,
            );
            expect(find.text(r.soldesTitre), findsOneWidget);
            expect(
              find.byKey(ResultatRechargePage.actualiserKey),
              findsNothing,
            );
          case EtatPaiement.echec:
            expect(find.text(r.echecTitre), findsOneWidget);
            expect(find.text('motif rendu'), findsOneWidget);
            expect(
              find.byKey(ResultatRechargePage.reessayerKey),
              findsOneWidget,
            );
            expect(
              find.byKey(ResultatRechargePage.changerMoyenKey),
              findsOneWidget,
            );
            expect(find.byKey(ResultatRechargePage.revenirKey), findsOneWidget);
            _aucunSucces();
          case EtatPaiement.annule:
            expect(find.text(r.annuleTitre), findsOneWidget);
            expect(
              find.byKey(ResultatRechargePage.recommencerKey),
              findsOneWidget,
            );
            _aucunSucces();
          case EtatPaiement.perime:
            expect(find.text(r.perimeTitre), findsOneWidget);
            expect(
              find.byKey(ResultatRechargePage.recommencerKey),
              findsOneWidget,
            );
            _aucunSucces();
        }
      });
    }
  });

  testWidgets('parcours de demonstration : Payer ouvre le resultat, qui '
      'avance par Actualiser jusqu a termine, et le succes vient du port', (
    WidgetTester tester,
  ) async {
    final GoRouter routeur = await _monter(
      tester,
      depart: Routes.tuteurFoyerRecharge,
    );
    await _taper(tester, find.byKey(RechargeFoyerPage.caseDe(_mariam)));
    await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
    await _taper(tester, find.byKey(RechargeFoyerPage.payerKey));
    expect(_lieu(routeur).path, Routes.tuteurFoyerRechargeResultat);
    final String commande = _lieu(routeur).queryParameters['commande']!;
    expect(commande, startsWith('demo-fi-paye-'));
    // Premier etat rendu : en attente de confirmation, jamais « confirme ».
    expect(
      find.byKey(
        ResultatRechargePage.etatKey(EtatPaiement.attenteConfirmation),
      ),
      findsOneWidget,
    );
    expect(
      find.text(t.adulte.recharge.resultat.attenteBandeauTitre),
      findsOneWidget,
    );
    _aucunSucces();
    for (final EtatPaiement suivant in <EtatPaiement>[
      EtatPaiement.confirme,
      EtatPaiement.allocationEnCours,
    ]) {
      await _taper(tester, find.byKey(ResultatRechargePage.actualiserKey));
      expect(find.byKey(ResultatRechargePage.etatKey(suivant)), findsOneWidget);
      _aucunSucces();
    }
    await _taper(tester, find.byKey(ResultatRechargePage.actualiserKey));
    expect(
      find.byKey(ResultatRechargePage.etatKey(EtatPaiement.termine)),
      findsOneWidget,
    );
    // Le nouveau solde de Mariam : son solde plus SA part, une fois.
    final Montant solde = DonneesFinanceDemo.profils(_jeu)
        .firstWhere((FinancesProfil p) => p.profilId == _mariam)
        .solde;
    final Montant part = DonneesFinanceDemo.paliersRecharge.first;
    expect(
      find.text(
        t.adulte.recharge.resultat.nouveauSolde(
          montant: formaterMontant(
            Montant(solde.mineur + part.mineur, solde.devise),
          ),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(ResultatRechargePage.allocationDe(_ibrahim)),
      findsNothing,
    );
    verifierUnSeulBoutonPlein(tester);
    await _taper(tester, find.byKey(ResultatRechargePage.revenirKey));
    expect(find.byType(FoyerPage), findsOneWidget);
  });

  group('double confirmation = un seul credit (demonstration)', () {
    test('la meme cle rend la meme commande, et des montants figes au '
        'premier paiement', () async {
      const RechargeFoyerFinanceDemo port = RechargeFoyerFinanceDemo(_jeu);
      final List<Montant> paliers = DonneesFinanceDemo.paliersRecharge;
      final RecapitulatifRecharge r = await port.verifierMontants(
        <MontantRecharge>[
          MontantRecharge(beneficiaireId: _mariam, montant: paliers[0]),
        ],
      );
      const String cle = 'cle-double-confirmation';
      final String a = await port.payer(recapitulatifId: r.id, cle: cle);
      // Une autre verification, puis la MEME cle : la meme commande, les
      // montants du premier paiement.
      await port.verifierMontants(<MontantRecharge>[
        MontantRecharge(beneficiaireId: _mariam, montant: paliers[4]),
      ]);
      final String b = await port.payer(recapitulatifId: r.id, cle: cle);
      // Un double qui serait recree (portee reconstruite) aussi.
      final String c = await const RechargeFoyerFinanceDemo(_jeu)
          .payer(recapitulatifId: r.id, cle: cle);
      expect(<String>{a, b, c}, hasLength(1));
      SuiviPaiement s = await port.suivre(a);
      while (s.etat != EtatPaiement.termine) {
        s = await port.suivre(a);
      }
      expect(s.allocations, hasLength(1));
      expect(s.allocations.single.montant, paliers[0]);
      expect(s.total, paliers[0]);
      final Montant solde = DonneesFinanceDemo.profils(_jeu)
          .firstWhere((FinancesProfil p) => p.profilId == _mariam)
          .solde;
      expect(
        s.allocations.single.nouveauSolde,
        Montant(solde.mineur + paliers[0].mineur, solde.devise),
      );
      // Une autre cle : une autre commande.
      final String d = await port.payer(
        recapitulatifId: r.id,
        cle: 'autre-cle',
      );
      expect(d, isNot(a));
      // Chaque commande a SA reference, tiree de son identifiant (revue
      // FI-8) : jamais la meme pour deux paiements.
      final String? refD = (await port.suivre(d)).reference;
      expect(s.reference, isNotNull);
      expect(refD, isNot(s.reference));
      expect(s.reference!.length, lessThanOrEqualTo('RWY-'.length + 8));
    });

    testWidgets('deux pressions sur Payer : un seul paiement, une seule '
        'commande', (WidgetTester tester) async {
      final _PortCompteur port = _PortCompteur();
      final GoRouter routeur = await _monter(
        tester,
        depart: Routes.tuteurFoyerRecharge,
        port: port,
      );
      await _taper(tester, find.byKey(RechargeFoyerPage.caseDe(_mariam)));
      await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
      await tester.ensureVisible(find.byKey(RechargeFoyerPage.payerKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(RechargeFoyerPage.payerKey));
      await tester.tap(
        find.byKey(RechargeFoyerPage.payerKey),
        warnIfMissed: false,
      );
      await stabiliser(tester);
      expect(port.cles, hasLength(1));
      expect(_lieu(routeur).path, Routes.tuteurFoyerRechargeResultat);
    });
  });

  testWidgets('ecran rouvert en attente : « Ne payez pas une seconde fois », '
      'aucun bouton Payer, l etat relu a chaque ouverture', (
    WidgetTester tester,
  ) async {
    final _PortEtat port = _PortEtat(EtatPaiement.attenteConfirmation);
    final GoRouter routeur = await _monter(tester, depart: c1, port: port);
    expect(
      find.text(t.adulte.recharge.resultat.attenteBandeauTitre),
      findsOneWidget,
    );
    expect(find.byKey(RechargeFoyerPage.payerKey), findsNothing);
    expect(
      find.textContaining(t.adulte.recharge.payer(montant: '')),
      findsNothing,
    );
    final int avant = port.lectures;
    routeur.go(Routes.tuteurFoyer);
    await stabiliser(tester);
    routeur.go(c1);
    await stabiliser(tester);
    expect(port.lectures, greaterThan(avant));
    expect(
      find.text(t.adulte.recharge.resultat.attenteBandeauTitre),
      findsOneWidget,
    );
    expect(find.byKey(RechargeFoyerPage.payerKey), findsNothing);
    _aucunSucces();
  });

  group('la selection est gardee (echec, annule, perime, preparation)', () {
    bool coche(WidgetTester tester, String id) =>
        tester
            .widget<Checkbox>(find.byKey(RechargeFoyerPage.caseDe(id)))
            .value ??
        false;
    String montant(WidgetTester tester, String id) => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(RechargeFoyerPage.montantDe(id)),
            matching: find.byType(Text),
          ),
        )
        .data!;

    // « Reessayer » et « Recommencer » : la recharge, profils et montants
    // repris.
    for (final (EtatPaiement etat, Key bouton) in <(EtatPaiement, Key)>[
      (EtatPaiement.echec, ResultatRechargePage.reessayerKey),
      (EtatPaiement.annule, ResultatRechargePage.recommencerKey),
      (EtatPaiement.perime, ResultatRechargePage.recommencerKey),
    ]) {
      testWidgets('${etat.name} : $bouton revient a la recharge, profils et '
          'montants repris', (WidgetTester tester) async {
        final GoRouter routeur = await _monter(
          tester,
          depart: Routes.resultatRechargePour(
            DonneesFinanceDemo.commandeDemo(etat),
          ),
        );
        if (etat == EtatPaiement.echec) {
          expect(find.text(DonneesFinanceDemo.motifEchecDemo), findsOneWidget);
        }
        _aucunSucces();
        await _taper(tester, find.byKey(bouton));
        expect(_lieu(routeur).path, Routes.tuteurFoyerRecharge);
        expect(_lieu(routeur).queryParameters['etape'], isNull);
        expect(find.byType(RechargeFoyerPage), findsOneWidget);
        // La recharge, une seule page : la selection reprise, son
        // recapitulatif rendu et « Payer » sur place (R3-01).
        expect(find.byKey(RechargeFoyerPage.payerKey), findsOneWidget);
        expect(find.byKey(RechargeFoyerPage.ligneDe(_mariam)), findsOneWidget);
        expect(coche(tester, _mariam), isTrue);
        expect(coche(tester, _ibrahim), isTrue);
        expect(
          montant(tester, _mariam),
          formaterMontant(DonneesFinanceDemo.usd(10)),
        );
        expect(
          montant(tester, _ibrahim),
          formaterMontant(DonneesFinanceDemo.usd(40)),
        );
      });
    }

    // « Changer de moyen de paiement » et la preparation : la recharge, une
    // seule page (R3-01), ou le moyen se choisit et le recapitulatif se lit,
    // avec la meme selection.
    for (final (EtatPaiement etat, Key bouton) in <(EtatPaiement, Key)>[
      (EtatPaiement.echec, ResultatRechargePage.changerMoyenKey),
      (EtatPaiement.preparation, ResultatRechargePage.verifierKey),
    ]) {
      testWidgets('${etat.name} : $bouton ouvre la recharge, moyen et '
          'recapitulatif de la meme selection', (WidgetTester tester) async {
        final GoRouter routeur = await _monter(
          tester,
          depart: Routes.resultatRechargePour(
            DonneesFinanceDemo.commandeDemo(etat),
          ),
        );
        await _taper(tester, find.byKey(bouton));
        expect(_lieu(routeur).path, Routes.tuteurFoyerRecharge);
        expect(_lieu(routeur).queryParameters['etape'], isNull);
        expect(find.byKey(RechargeFoyerPage.moyenKey), findsOneWidget);
        expect(find.byType(LigneMoyenPaiement), findsOneWidget);
        expect(find.byKey(RechargeFoyerPage.payerKey), findsOneWidget);
        expect(find.byKey(RechargeFoyerPage.ligneDe(_mariam)), findsOneWidget);
        expect(find.byKey(RechargeFoyerPage.ligneDe(_ibrahim)), findsOneWidget);
        expect(coche(tester, _mariam), isTrue);
        expect(coche(tester, _ibrahim), isTrue);
        expect(
          montant(tester, _ibrahim),
          formaterMontant(DonneesFinanceDemo.usd(40)),
        );
      });
    }

    test('l adresse de reprise se relit', () {
      expect(
        Routes.montantsDe('a:1000:USD,b:x:USD,:5:USD,c:200'),
        <String, Montant>{'a': const Montant(1000, 'USD')},
      );
      expect(
        Routes.montantsDe(
          Uri.parse(
            Routes.rechargeReprise(<String, Montant>{
              'a': const Montant(1000, 'USD'),
              'b': const Montant(4000, 'USD'),
            }),
          ).queryParameters['montants'],
        ),
        <String, Montant>{
          'a': const Montant(1000, 'USD'),
          'b': const Montant(4000, 'USD'),
        },
      );
    });

    // Le filtrage de l'ecran : un montant rappele n'est retenu que s'il est
    // propose ; sinon le montant suggere par la source (le manque de 8 $
    // d'Ibrahim) s'applique.
    for (final (int rappele, int attendu) in <(int, int)>[
      (123, 800),
      (2000, 2000),
    ]) {
      testWidgets('montant rappele $rappele : $attendu affiche', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          port: const RechargeFoyerFinanceDemo(JeuFoyerFinance.unARegulariser),
          depart: Routes.rechargeReprise(<String, Montant>{
            _ibrahim: Montant(rappele, DonneesFinanceDemo.devise),
          }),
        );
        expect(coche(tester, _ibrahim), isTrue);
        expect(
          montant(tester, _ibrahim),
          formaterMontant(Montant(attendu, DonneesFinanceDemo.devise)),
        );
      });
    }
  });

  testWidgets('apres le paiement, la recharge rouverte (retour du '
      'navigateur) garde sa commande : « Suivre le paiement », jamais un '
      'second « Payer » (revue FI-8)', (WidgetTester tester) async {
    final String recharge = Routes.rechargePour(<String>[_mariam]);
    final GoRouter routeur = await _monter(tester, depart: recharge);
    await _taper(tester, find.byKey(RechargeFoyerPage.plusDe(_mariam)));
    await _taper(tester, find.byKey(RechargeFoyerPage.payerKey));
    expect(_lieu(routeur).path, Routes.tuteurFoyerRechargeResultat);
    final String commande = _lieu(routeur).queryParameters['commande']!;
    expect(_lieu(routeur).queryParameters['profils'], _mariam);
    routeur.go(recharge);
    await stabiliser(tester);
    expect(find.byType(RechargeFoyerPage), findsOneWidget);
    expect(find.byKey(RechargeFoyerPage.payerKey), findsNothing);
    expect(find.byKey(RechargeFoyerPage.suivreKey), findsOneWidget);
    await _taper(tester, find.byKey(RechargeFoyerPage.suivreKey));
    expect(_lieu(routeur).queryParameters['commande'], commande);
  });

  group('production, hors ligne, erreur, vide', () {
    testWidgets('production : le suivi se dit indisponible', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: c1, avecFinances: false);
      final EtatSysteme e = tester.widget<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(e.nature, NatureEtat.indisponible);
      expect(e.dependance, 'FI-BR-06');
      _aucunSucces();
    });

    test('production : payer reste CapaciteIndisponible', () async {
      await expectLater(
        const RechargeFoyerIndisponible().payer(recapitulatifId: 'r', cle: 'c'),
        throwsA(isA<CapaciteIndisponible>()),
      );
    });

    testWidgets('hors ligne, lecture manquee : l etat hors ligne', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: c1,
        horsLigne: true,
        port: _PortEtat(EtatPaiement.termine, erreur: StateError('coupure')),
      );
      final EtatSysteme e = tester.widget<EtatSysteme>(
        find.byType(EtatSysteme),
      );
      expect(e.nature, NatureEtat.horsLigne);
      _aucunSucces();
    });

    testWidgets('hors ligne, etat deja lu : dit, sans Actualiser', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: c1,
        horsLigne: true,
        port: _PortEtat(EtatPaiement.attenteConfirmation),
      );
      expect(find.text(t.adulte.recharge.resultat.horsLigne), findsOneWidget);
      expect(find.byKey(ResultatRechargePage.actualiserKey), findsNothing);
    });

    testWidgets('erreur de lecture : jamais « non paye » (D5), Reessayer', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        depart: c1,
        port: _PortEtat(EtatPaiement.termine, erreur: StateError('coupure')),
      );
      expect(
        find.text(t.adulte.recharge.resultat.lectureEchecTitre),
        findsOneWidget,
      );
      expect(
        find.text(t.adulte.recharge.resultat.lectureEchecPhrase),
        findsOneWidget,
      );
      _aucunSucces();
    });

    testWidgets('sans commande : le vide, et le retour', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: Routes.tuteurFoyerRechargeResultat);
      expect(find.text(t.adulte.recharge.resultat.videTitre), findsOneWidget);
      await _taper(tester, find.text(t.adulte.recharge.resultat.retourSoldes));
      expect(find.byType(FoyerPage), findsOneWidget);
    });

    testWidgets('chargement : un squelette, aucun etat invente', (
      WidgetTester tester,
    ) async {
      await _monter(tester, depart: c1, port: _PortLent());
      expect(find.byType(ResultatRechargePage), findsOneWidget);
      expect(
        find.byKey(
          ResultatRechargePage.etatKey(EtatPaiement.attenteConfirmation),
        ),
        findsNothing,
      );
      _aucunSucces();
    });
  });

  group('responsive : 320 a 200 % et 1440, LTR et RTL, clair et sombre', () {
    for (final (Size taille, double echelle) in <(Size, double)>[
      (const Size(320, 5000), 2),
      (const Size(1440, 2000), 1),
    ]) {
      for (final TextDirection direction in TextDirection.values) {
        for (final Brightness luminosite in Brightness.values) {
          for (final EtatPaiement etat in <EtatPaiement>[
            EtatPaiement.termine,
            EtatPaiement.echec,
            EtatPaiement.attenteConfirmation,
          ]) {
            testWidgets('${etat.name}, ${taille.width.toInt()} px x$echelle, '
                '${direction.name}, ${luminosite.name}', (
              WidgetTester tester,
            ) async {
              await _monter(
                tester,
                depart: c1,
                port: _PortEtat(etat, motif: 'motif rendu'),
                taille: taille,
                echelle: echelle,
                direction: direction,
                luminosite: luminosite,
              );
              expect(tester.takeException(), isNull);
              expect(
                find.byKey(ResultatRechargePage.etatKey(etat)),
                findsOneWidget,
              );
              verifierUnSeulBoutonPlein(tester);
              expect(
                verifierAucuneCarteCollee(
                  tester,
                  estCarte: (Widget w) => w is AppCard,
                ),
                greaterThan(0),
              );
            });
          }
        }
      }
    }
  });
}

/// Le port de la demonstration, qui compte les paiements envoyes.
class _PortCompteur extends RechargeFoyerFinanceDemo {
  _PortCompteur() : super(_jeu);

  final List<String> cles = <String>[];

  @override
  Future<String> payer({required String recapitulatifId, required String cle}) {
    cles.add(cle);
    return super.payer(recapitulatifId: recapitulatifId, cle: cle);
  }
}

/// Un port dont la lecture ne repond pas pendant le test.
class _PortLent extends RechargeFoyerFinanceDemo {
  _PortLent() : super(_jeu);

  @override
  Future<SuiviPaiement> suivre(String commandeId) =>
      Completer<SuiviPaiement>().future;
}
