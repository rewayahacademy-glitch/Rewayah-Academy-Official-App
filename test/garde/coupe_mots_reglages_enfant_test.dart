// COUPE-MOTS-FOND-1, point (6) : les reglages de l'enfant (tuteur) passent
// par la garde du rendu, page ENTIERE puis feuille « demander un
// changement » ouverte, aux gabarits de la fiche (320 x 568 texte x2,
// 390 x 844, 1440 x 900 texte x2), en francais (LTR) et en arabe (RTL), en
// standard et en Interface guidee.
//
// Le titre « Pourquoi ce changement ? » de la feuille porte une espace
// insecable avant « ? » dans `fr.i18n.json`, mais le JSON ne prouve pas le
// rendu : c'est le paragraphe dessine qui est mesure (ponctuation seule a
// la ligne, mot coupe, texte rogne ou tronque).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/matching/service_matching.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/regles/service_regles.dart';
import 'package:rewayah_academy/features/reglages_enfant/reglages_enfant_page.dart';

import '../capture/outil_capture.dart';
import '../support/balayage_ecrans.dart';
import '../support/garde_coupe_mots_rendu.dart';
import '../support/harnais.dart';

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

/// L'ecran des reglages de l'enfant.
EcranBalayage reglagesEnfant() => (
  nom: 'tuteur reglages enfant',
  page: () => const ReglagesEnfantPage(),
  routeur: null,
  depart: null,
  surcharges: _surcharges,
);

/// Ouvre la feuille de demande dont le bouton porte [libelle].
Future<void> ouvrirDemande(WidgetTester tester, String libelle) async {
  final Finder bouton = find.text(libelle);
  await tester.ensureVisible(bouton);
  await stabiliser(tester);
  await tester.tap(bouton);
  await stabiliser(tester);
}

void main() {
  setUpAll(() async {
    await chargerPolicesDuDepot();
    await LocaleSettings.setLocale(AppLocale.ar);
    await LocaleSettings.setLocale(AppLocale.fr);
  });

  // Les gabarits de la fiche, plus deux largeurs de marge en Interface
  // guidee texte x2 (300 et 315 px) : a 320, « changement ? » ne tenait
  // qu'a 0,8 px pres ; un pixel de moins (une autre police de repli, une
  // marge de feuille) et le « ? » partait seul a la ligne.
  for (final ConfigBalayage c in <ConfigBalayage>[
    ...configsBalayage(),
    for (final double largeur in <double>[300, 315])
      for (final AppLocale langue in <AppLocale>[AppLocale.fr, AppLocale.ar])
        (
          gabarit: (
            nom: '${largeur.toInt()}x2',
            taille: Size(largeur, 568),
            echelle: 2,
          ),
          langue: langue,
          interface: InterfaceMode.enfant,
        ),
  ]) {
    testWidgets('reglages enfant ${nomConfig(c)} : page entiere, aucun mot '
        'coupe ni rogne', (WidgetTester tester) async {
      await monterEcranBalayage(tester, reglagesEnfant(), c);
      expect(await defautsEcranDefile(tester), isEmpty);
    });

    for (final String Function() libelle in <String Function()>[
      () => t.tuteur.reglages.demandeDuree,
      () => t.tuteur.reglages.demandeMinimum,
    ]) {
      testWidgets('reglages enfant ${nomConfig(c)} : feuille '
          '« ${libelle()} » ouverte, « Pourquoi ce changement ? » entier', (
        WidgetTester tester,
      ) async {
        await monterEcranBalayage(tester, reglagesEnfant(), c);
        await ouvrirDemande(tester, libelle());
        expect(find.byType(BottomSheet), findsOneWidget);
        // Le titre du motif est rendu, et mesure avec tout le reste.
        expect(find.text(t.tuteur.reglages.demandeMotif), findsWidgets);
        expect(await defautsEcranDefile(tester), isEmpty);
      });
    }
  }
}
