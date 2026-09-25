// LT-10 : sur bureau (a partir de 1200), les ecrans finance passent en deux
// colonnes (planche « 06 Web sombre, soldes et operations ») par le composant
// partage `ColonnesFiche` ; sur telephone, rien ne change (empilement). La
// recharge n'a aucun recapitulatif rendu par le serveur : elle reste en une
// colonne, jamais un total invente. Aucun debordement a 200 % de texte.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/capacites/port_finance_foyer.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/resume_solde.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/compte/acces_page.dart';
import 'package:rewayah_academy/features/compte/arret_acces_page.dart';
import 'package:rewayah_academy/features/compte/soldes_page.dart';
import 'package:rewayah_academy/features/compte/verifier_recharge_page.dart';
import 'package:rewayah_academy/features/demo/finance_demo.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';

import '../../router/support_routeur.dart';
import 'support_compte.dart';

const Size _bureau = Size(1440, 900);
const Size _telephone = Size(390, 844);

final List<Override> _demo = <Override>[
  portFinanceFoyerProvider.overrideWithValue(const FinanceFoyerDemo()),
];

final DevisRecharge _devis = DevisRecharge(
  reference: 'test-devis',
  lignes: const <LigneDevis>[
    LigneDevis(
      profilId: DonneesDemo.aichaId,
      prixMineur: 1500,
      remiseMineure: 0,
      quantiteMineure: 1000,
    ),
  ],
  totalMineur: 1500,
  devise: FinanceFoyerDemo.devise,
  valableJusqua: DateTime.utc(2099, 1, 15, 12),
);

/// Cote a cote : [annexe] commence apres [principal] (sens de lecture LTR)
/// et les deux partagent une bande horizontale.
void _coteACote(WidgetTester tester, Finder principal, Finder annexe) {
  final Rect p = tester.getRect(principal);
  final Rect a = tester.getRect(annexe);
  expect(a.left, greaterThanOrEqualTo(p.right), reason: '$p / $a');
  expect(a.top, lessThan(p.bottom), reason: '$p / $a');
}

/// Empiles : [bas] sous [haut], sur la meme colonne.
void _empiles(WidgetTester tester, Finder haut, Finder bas) {
  final Rect h = tester.getRect(haut);
  final Rect b = tester.getRect(bas);
  expect(b.top, greaterThanOrEqualTo(h.bottom), reason: '$h / $b');
  expect(b.left, lessThan(h.right), reason: '$h / $b');
}

Future<void> _soldes(WidgetTester tester, Size taille) => monterCompte(
  tester,
  taille: taille,
  depart: Routes.tuteurCompteSoldes,
  eleves: DonneesDemo.eleves,
  surcharges: _demo,
);

Future<void> _acces(WidgetTester tester, Size taille) => monterCompte(
  tester,
  taille: taille,
  depart: Routes.tuteurCompteAcces,
  eleves: DonneesDemo.eleves,
  surcharges: _demo,
);

Future<void> _verifier(WidgetTester tester, Size taille) async {
  final GoRouter routeur = await monterCompte(
    tester,
    taille: taille,
    depart: Routes.tuteurCompteSoldes,
    eleves: DonneesDemo.eleves,
    surcharges: _demo,
  );
  routeur.go(Routes.tuteurCompteRechargeVerifier, extra: _devis);
  await stabiliser(tester);
}

Future<void> _s10(WidgetTester tester, Size taille) async {
  final GoRouter routeur = await monterCompte(
    tester,
    taille: taille,
    depart: Routes.tuteurCompteAcces,
    eleves: DonneesDemo.eleves,
    surcharges: _demo,
  );
  routeur.go(
    Uri(
      path: Routes.tuteurCompteArretAcces,
      queryParameters: <String, String>{'profil': DonneesDemo.aichaId},
    ).toString(),
  );
  await stabiliser(tester);
}

void main() {
  group('S01 soldes', () {
    testWidgets('1440 : liste a gauche, actions a droite', (
      WidgetTester tester,
    ) async {
      await _soldes(tester, _bureau);
      expect(find.byType(ColonnesFiche), findsOneWidget);
      // Le total du foyer, a gauche ; le panneau du profil a sa propre carte.
      final Finder total = find.byWidgetPredicate(
        (Widget w) => w is ResumeSolde && w.prenom == null,
      );
      final Finder panneau = find.byKey(SoldesComptePage.panneauKey);
      _coteACote(tester, total, panneau);
      // Les actions du foyer suivent le panneau, dans la meme colonne.
      _empiles(tester, panneau, find.byKey(SoldesComptePage.rechargerKey));
      _empiles(
        tester,
        find.byKey(SoldesComptePage.rechargerKey),
        find.byKey(SoldesComptePage.gererAccesKey),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : empilement inchange', (WidgetTester tester) async {
      await _soldes(tester, _telephone);
      expect(find.byType(ColonnesFiche), findsNothing);
      _empiles(
        tester,
        find.byType(ResumeSolde),
        find.byKey(SoldesComptePage.rechargerKey),
      );
      _empiles(
        tester,
        find.byKey(SoldesComptePage.rechargerKey),
        find.byKey(SoldesComptePage.gererAccesKey),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Acces', () {
    testWidgets('1440 : profils a gauche, arret a droite', (
      WidgetTester tester,
    ) async {
      await _acces(tester, _bureau);
      _coteACote(
        tester,
        find.byType(StatusPill).first,
        find.byKey(AccesComptePage.arreterKey),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : empilement inchange', (WidgetTester tester) async {
      await _acces(tester, _telephone);
      expect(find.byType(ColonnesFiche), findsNothing);
      _empiles(
        tester,
        find.byType(StatusPill).last,
        find.byKey(AccesComptePage.arreterKey),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('S05 verifier la recharge', () {
    testWidgets('1440 : lignes a gauche, recapitulatif serveur a droite', (
      WidgetTester tester,
    ) async {
      await _verifier(tester, _bureau);
      _coteACote(
        tester,
        find.byType(AppCard).first,
        find.byKey(VerifierRechargePage.recapitulatifKey),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : empilement inchange', (WidgetTester tester) async {
      await _verifier(tester, _telephone);
      expect(find.byType(ColonnesFiche), findsNothing);
      _empiles(
        tester,
        find.byType(AppCard).first,
        find.byKey(VerifierRechargePage.recapitulatifKey),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans devis : une seule colonne, aucun total invente', (
      WidgetTester tester,
    ) async {
      await monterCompte(
        tester,
        taille: _bureau,
        depart: Routes.tuteurCompteRechargeVerifier,
        eleves: DonneesDemo.eleves,
        surcharges: _demo,
      );
      expect(find.byType(ColonnesFiche), findsNothing);
      expect(find.byKey(VerifierRechargePage.recapitulatifKey), findsNothing);
    });
  });

  group('Recharge S03-S04', () {
    testWidgets('1440 : aucun recapitulatif serveur, une seule colonne', (
      WidgetTester tester,
    ) async {
      await monterCompte(
        tester,
        taille: _bureau,
        depart: Routes.tuteurCompteRecharge,
        eleves: DonneesDemo.eleves,
        surcharges: _demo,
      );
      expect(find.byType(ColonnesFiche), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('S10 consequences', () {
    testWidgets('1440 : profils concernes a gauche, consequences a droite', (
      WidgetTester tester,
    ) async {
      await _s10(tester, _bureau);
      _coteACote(
        tester,
        find.byKey(ArretAccesPage.profilsKey),
        find.byKey(ArretAccesPage.profilKey(DonneesDemo.aichaId)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('390 : consequences seules, empilees', (
      WidgetTester tester,
    ) async {
      await _s10(tester, _telephone);
      expect(find.byKey(ArretAccesPage.profilsKey), findsNothing);
      expect(
        find.byKey(ArretAccesPage.profilKey(DonneesDemo.aichaId)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('1440 a 200 % : aucun debordement', (WidgetTester tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _soldes(tester, _bureau);
    expect(tester.takeException(), isNull);
    await _acces(tester, _bureau);
    expect(tester.takeException(), isNull);
    await _verifier(tester, _bureau);
    expect(tester.takeException(), isNull);
    await _s10(tester, _bureau);
    expect(tester.takeException(), isNull);
  });

  // ponytail: a 390 et 200 %, ces ecrans debordent deja avant LT-10 (la tete
  // non defilante de `PageShell` depasse 753 points ; S07, non touche, aussi).
  // Le chemin telephone n'est pas modifie par ce lot ; dette du gabarit
  // partage signalee, a couvrir quand `PageShell` fera defiler sa tete.
}
