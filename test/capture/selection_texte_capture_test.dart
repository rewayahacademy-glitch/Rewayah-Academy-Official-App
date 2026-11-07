// Captures du lot SELECTION-TEXTE (directeur, 07/11/2026) : un texte ordinaire
// selectionne par appui long avec le menu « Copier » visible, puis la meme
// scene ou l'appui long tombe sur un code d'appairage et sur une destination
// de versement masquee : rien ne se selectionne, aucun menu.
//
// Scene composee avec les VRAIS composants (`CodeEnClair`,
// `LigneDestinationMasquee`) sous le VRAI `SelectionRacine` ; ce n'est pas un
// ecran de l'application. Saute sans CAPTURE_DIR (test/capture/LISEZ-MOI.md).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/comptable/modeles_comptable.dart';
import 'package:rewayah_academy/core/comptable/statuts_comptable.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/ligne_destination_masquee.dart';
import 'package:rewayah_academy/features/appareils/emetteur_qr.dart';

import '../support/hote_selection.dart';
import 'outil_capture.dart';

const Key _paragraphe = ValueKey<String>('scene-paragraphe');
const Key _code = ValueKey<String>('scene-code');
const Key _versement = ValueKey<String>('scene-versement');

Widget _scene() => Padding(
  padding: const EdgeInsets.all(AppSpacing.lg),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      const SizedBox(height: AppSpacing.respiration),
      Text(t.kyc.intro, key: _paragraphe),
      const SizedBox(height: AppSpacing.lg),
      Text(t.kyc.confidentialite),
      const SizedBox(height: AppSpacing.xl),
      const Center(
        child: CodeEnClair(code: 'K7QX2M', key: _code),
      ),
      const SizedBox(height: AppSpacing.xl),
      const LigneDestinationMasquee(
        key: _versement,
        destination: DestinationMasquee(
          type: 'Compte bancaire',
          suffixe: '9087',
          pays: 'France',
          devise: 'EUR',
          verification: EtatProfilPaiement.verifie,
        ),
      ),
    ],
  ),
);

void main() {
  group('Capture : selection du texte', skip: sautSansCapture, () {
    setUpAll(chargerPolicesDuDepot);

    for (final (String nom, AppLocale langue) in <(String, AppLocale)>[
      ('fr', AppLocale.fr),
      ('ar', AppLocale.ar),
    ]) {
      for (final (String taille, Size vue, double densite)
          in <(String, Size, double)>[
            ('390', const Size(390, 844), 2),
            ('1440', const Size(1440, 900), 1),
          ]) {
        testWidgets('$nom $taille : texte ordinaire, menu Copier', (
          WidgetTester tester,
        ) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, vue, densite);
          await tester.pumpWidget(hoteSelection(_scene()));
          await tester.pump();
          await tester.longPress(find.byKey(_paragraphe));
          // Le menu apparait en fondu : on attend qu'il soit opaque.
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 700));
          expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
          debugPrint(
            'PNG ${await capturer(tester, 'selection-texte_${nom}_${taille}_ordinaire-menu-copier')}',
          );
        });

        testWidgets('$nom $taille : tout selectionner, code et IBAN masque '
            'restent hors de la selection', (WidgetTester tester) async {
          await tester.runAsync(() => LocaleSettings.setLocale(langue));
          addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));
          fixerVueCapture(tester, vue, densite);
          await tester.pumpWidget(hoteSelection(_scene()));
          await tester.pump();
          tester
              .state<SelectableRegionState>(find.byType(SelectableRegion))
              .selectAll(SelectionChangedCause.toolbar);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump(const Duration(milliseconds: 700));
          debugPrint(
            'PNG ${await capturer(tester, 'selection-texte_${nom}_${taille}_tout-selectionne-code-et-iban-exclus')}',
          );
        });
      }
    }
  });
}
