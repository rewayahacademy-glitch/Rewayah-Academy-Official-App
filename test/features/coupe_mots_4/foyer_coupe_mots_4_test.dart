// COUPE-MOTS-4 (1), appelants Foyer de `ChoiceCardGroup` : fiche eleve,
// Interface (« Acc / essibilité », « Présentat / ion »), profil eleve
// (« pour qui ? ») et recharge du foyer (offres). 320 px, texte x2, francais
// (LTR) et arabe (RTL), Interface standard et guidee.
// Contre-epreuve : sur l'ancien code (5a52ff30), la fiche Interface echoue en
// nommant « Accessibilité » et « Présentation ».

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/features/foyer/fiche/interface_page.dart';
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../../fixtures/tuteur/foyers.dart';
import '../../support/harnais.dart';
import 'support_coupe_mots_4.dart';

/// Des offres aux libelles longs, comme le serveur les redigera.
class _PortRecharge implements PortRechargeFoyer {
  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() async =>
      const <BeneficiaireRecharge>[
        BeneficiaireRecharge(
          id: 'b1',
          prenom: 'Yusuf',
          soldeRendu: '3 séances',
          offres: <OffreRecharge>[
            OffreRecharge(
              id: 'o1',
              libelle: 'Forfait mensuel, huit séances',
              detail: 'Renouvellement automatiquement proposé',
            ),
            OffreRecharge(
              id: 'o2',
              libelle: 'Accompagnement personnalisé',
              detail: 'Organisation administrative incluse',
            ),
          ],
        ),
      ];

  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) =>
      throw UnimplementedError();

  @override
  Future<String> payer({
    required String recapitulatifId,
    required String cle,
  }) => throw UnimplementedError();

  // FI-DIR-1 (reuni par JONCTION-LIGNES-1) : la recharge par montants et le
  // suivi du paiement, hors du champ de ce test.
  @override
  Future<RecapitulatifRecharge> verifierMontants(List<MontantRecharge> choix) =>
      throw UnimplementedError();

  @override
  Future<SuiviPaiement> suivre(String commandeId) => throw UnimplementedError();
}

List<Override> _horsLigneFaux() => <Override>[
  horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
  serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
];

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  preparerCoupeMots4();

  for (final AppLocale langue in languesCoupeMots4) {
    for (final InterfaceMode interface in interfacesCoupeMots4) {
      final String cas = '${langue.name} ${nomInterface(interface)} 320 x2';

      testWidgets('$cas : fiche eleve, Interface', (WidgetTester tester) async {
        await monterRouteCoupeMots4(
          tester,
          role: AppRole.guardian,
          depart: Routes.ficheEleveSousPage(FoyersFictifs.a1.id, 'interface'),
          langue: langue,
          interface: interface,
          appairage: FauxServiceAppairage()
            ..elevesRendus = List<EleveDuFoyer>.of(FoyersFictifs.foyerA),
        );
        expect(find.byKey(InterfaceElevePage.choixKey), findsOneWidget);
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : profil eleve, pour qui', (WidgetTester tester) async {
        await monterRouteCoupeMots4(
          tester,
          role: AppRole.guardian,
          depart: Routes.tuteurAccueil,
          langue: langue,
          interface: interface,
          appairage: FauxServiceAppairage()
            ..elevesRendus = List<EleveDuFoyer>.of(FoyersFictifs.foyerA),
        );
        await _toucher(
          tester,
          find.descendant(
            of: find.byKey(NavShell.barreBasseKey),
            matching: find.text(t.nav.tuteur.foyer),
          ),
        );
        await _toucher(tester, find.byKey(FoyerPage.ajouterKey));
        expect(find.byKey(FormulaireProfilEleve.choixKey), findsOneWidget);
        verifierCartesDeChoixEntieres(tester);
      });

      testWidgets('$cas : recharge du foyer, offres', (
        WidgetTester tester,
      ) async {
        await monterCoupeMots4(
          tester,
          () => RechargeFoyerPage(
            onAbandon: () {},
            onTerminee: () {},
            onPaye: (String _) {},
          ),
          langue: langue,
          interface: interface,
          surcharges: <Override>[
            ..._horsLigneFaux(),
            portRechargeFoyerProvider.overrideWithValue(_PortRecharge()),
          ],
        );
        await tester.pump();
        await tester.pump();
        // JONCTION-LIGNES-1 : la recharge de FI-DIR-1 rend des montants, plus
        // des offres a cocher, et un seul beneficiaire n'a rien a repartir
        // (pas de case). Le point du test reste : aucun mot coupe a 320 x2.
        verifierEcranEntierCoupeMots4(tester);
      });
    }
  }
}
