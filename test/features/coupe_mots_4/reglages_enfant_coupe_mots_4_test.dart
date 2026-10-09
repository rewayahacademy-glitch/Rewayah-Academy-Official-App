// COUPE-MOTS-4, ecran des reglages de l'enfant (tuteur), appelant de
// `ChoiceCardGroup` :
//
// (1) la feuille de demande de duree pose ses durees en cartes de choix :
//     aucun mot coupe a 320 px en texte x2 ;
// (4) « Pourquoi ce changement ? » : le point d'interrogation ne part plus
//     seul a la ligne (espace insecable avant « ? ! : ; », typographie
//     francaise, `assets/i18n/fr.i18n.json`).
//
// Francais (LTR) et arabe (RTL), Interface standard et guidee.
// Contre-epreuve : sur l'ancien code (5a52ff30), la feuille francaise echoue
// en nommant le « ? » isole et les mots coupes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/features/reglages_enfant/reglages_enfant_page.dart';

import '../../support/aucun_mot_coupe.dart';
import '../../support/harnais.dart';
import 'support_coupe_mots_4.dart';

List<Override> _surcharges() => <Override>[
  serviceAppairageProvider.overrideWithValue(
    FauxServiceAppairage()
      ..elevesRendus = <EleveDuFoyer>[
        const EleveDuFoyer(
          id: 'e1',
          prenom: 'Amina',
          identifiantImmuable: 'STUD-AD-000001',
          mode: InterfaceMode.enfant,
          camera: CameraPolicy.forbidden,
        ),
      ],
  ),
  servicePlanningProvider.overrideWithValue(FauxServicePlanning()),
  serviceMatchingProvider.overrideWithValue(FauxServiceMatching()),
  serviceReglesProvider.overrideWithValue(FauxServiceRegles()),
];

void main() {
  preparerCoupeMots4();

  for (final AppLocale langue in languesCoupeMots4) {
    for (final InterfaceMode interface in interfacesCoupeMots4) {
      testWidgets('${langue.name} ${nomInterface(interface)} 320 x2 : feuille '
          'de demande de duree, aucun mot coupe, aucune ponctuation seule', (
        WidgetTester tester,
      ) async {
        await monterCoupeMots4(
          tester,
          () => const ReglagesEnfantPage(),
          langue: langue,
          interface: interface,
          hauteur: 3000,
          surcharges: _surcharges(),
        );
        final Finder demande = find.text(t.tuteur.reglages.demandeDuree);
        await tester.ensureVisible(demande);
        await tester.pumpAndSettle();
        await tester.tap(demande);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ChoiceCardGroup), findsOneWidget);
        expect(motsCoupes(tester, find.byType(ChoiceCardGroup)), isEmpty);
        final Finder motif = find.text(t.tuteur.reglages.demandeMotif);
        expect(motif, findsWidgets);
        expect(motsCoupes(tester, motif), isEmpty);
        expect(ponctuationsIsolees(tester, find.byType(BottomSheet)), isEmpty);
        // Et l'ecran entier, sous la feuille comme dans la feuille.
        verifierEcranEntierCoupeMots4(tester);
      });
    }
  }
}
