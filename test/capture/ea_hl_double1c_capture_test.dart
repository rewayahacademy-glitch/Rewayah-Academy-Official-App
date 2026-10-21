// EA-HL-DOUBLE-1c : captures de preuve de « hors ligne dit une seule fois »
// sur les soldes du foyer (Paiements du foyer) et la recharge, les deux
// ecrans modifies que la reprise n'avait pas captures (revue
// EA-HL-DOUBLE-1-R, m4). Sans donnees, le bloc dit ce qui manque ; avec
// donnees deja lues puis relues en echec, le bandeau seul.
//
// Saute sans CAPTURE_DIR : la CI ne l'execute jamais et n'ecrit rien.
// Chaque capture verifie aussi qu'aucun mot n'est coupe ni tronque, et que
// « hors ligne » n'est dit qu'une fois, en mots et en icone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderOrFamily;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/demo/adulte_demo.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';

import '../support/aucun_mot_coupe.dart';
import '../support/hors_ligne_une_fois.dart';
import 'outil_capture.dart';

/// Un cas de capture : nom, taille, theme, echelle, sens, interface.
typedef _Cas = (String, Size, ThemeMode, double, TextDirection, InterfaceMode);

const List<_Cas> _cas = <_Cas>[
  (
    '390_clair',
    Size(390, 844),
    ThemeMode.light,
    1,
    TextDirection.ltr,
    InterfaceMode.standard,
  ),
  (
    '390_sombre',
    Size(390, 844),
    ThemeMode.dark,
    1,
    TextDirection.ltr,
    InterfaceMode.standard,
  ),
  (
    '390_guidee',
    Size(390, 844),
    ThemeMode.light,
    1,
    TextDirection.ltr,
    InterfaceMode.enfant,
  ),
  (
    '320x2_clair',
    Size(320, 1800),
    ThemeMode.light,
    2,
    TextDirection.ltr,
    InterfaceMode.standard,
  ),
  (
    '320x2_rtl_clair',
    Size(320, 1800),
    ThemeMode.light,
    2,
    TextDirection.rtl,
    InterfaceMode.standard,
  ),
  (
    '1440_clair',
    Size(1440, 900),
    ThemeMode.light,
    1,
    TextDirection.ltr,
    InterfaceMode.standard,
  ),
];

/// Monte [page] hors ligne, relit [fournisseur] une fois si [relire], verifie
/// et capture.
Future<void> _capturer(
  WidgetTester tester,
  String nom,
  _Cas cas, {
  required Widget page,
  required List<Override> lectures,
  required ProviderOrFamily fournisseur,
  required bool relire,
  required String quoi,
}) async {
  fixerVueCapture(tester, cas.$2, 1);
  await tester.pumpWidget(
    hoteCapture(
      Directionality(textDirection: cas.$5, child: page),
      surcharges: <Override>[
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
        ...lectures,
      ],
      themeMode: cas.$3,
      echelleTexte: cas.$4,
      interfaceMode: cas.$6,
    ),
  );
  await stabiliser(tester);
  if (relire) {
    ProviderScope.containerOf(tester.element(find.byType(page.runtimeType)))
        .invalidate(fournisseur);
    await stabiliser(tester);
  }
  expect(tester.takeException(), isNull);
  if (relire) {
    expectAvecDonnees();
    expect(find.text(quoi), findsNothing);
  } else {
    expectSansDonnees(quoi);
    verifierAucunMotCoupe(tester, find.byType(EtatSansDonnees));
  }
  verifierAucunMotCoupe(tester, find.byType(PageShell));
  debugPrint('PNG ${await capturer(tester, 'ea_hl_double1_$nom')}');
}

void main() {
  group('Capture : EA-HL-DOUBLE-1c', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    final List<BeneficiaireRecharge> beneficiaires =
        DonneesAdulteDemo.beneficiairesRecharge(
          EtatDemoAdulte.conjointActif,
          GenreTitulaireDemo.homme,
        );

    /// Une lecture qui rend [valeur] la premiere fois si [dabord], puis
    /// echoue.
    Future<T> Function() lecture<T>(T valeur, {required bool dabord}) {
      int n = 0;
      return () => dabord && ++n == 1
          ? Future<T>.value(valeur)
          : Future<T>.error(StateError('reseau'));
    }

    for (final _Cas cas in _cas) {
      for (final bool avec in <bool>[false, true]) {
        final String etat = avec ? 'avec_donnees' : 'sans_donnees';

        // L11 : les soldes ne sont plus sur Paiements du foyer (FI-VAGUE-R
        // R1-06 : la synthese et les cartes de Ma famille les portent) ; la
        // capture des soldes sur cette page n'a plus d'objet.
        testWidgets('recharge $etat ${cas.$1}', (WidgetTester tester) async {
          final Future<List<BeneficiaireRecharge>> Function() lire = lecture(
            beneficiaires,
            dabord: avec,
          );
          await _capturer(
            tester,
            'recharge_${etat}_${cas.$1}',
            cas,
            page: RechargeFoyerPage(
              onAbandon: () {},
              onTerminee: () {},
              onPaye: (String _) {},
            ),
            lectures: <Override>[
              beneficiairesRechargeProvider.overrideWith((Ref _) => lire()),
            ],
            fournisseur: beneficiairesRechargeProvider,
            relire: avec,
            quoi: t.adulte.recharge.sansDonnees,
          );
        });
      }
    }
  });
}
