// MUSHAF-DIR-1 et MA-CORAN-X2-1 (05/10/2026) : les etats sans texte du
// lecteur du Coran (page non chargee, page vide), dans le VRAI lecteur du
// Mode Accessibilite, a 320 x2 et a 390 x2.
//
// - MUSHAF-DIR-1 : les phrases francaises (titre, invitation vouvoyee,
//   notice « Composition approchee ») sont posees de gauche a droite. Avant,
//   le feuilletage du mushaf leur imposait la droite a gauche, et le point
//   final passait en tete (« .votre page se rouvre ici »).
// - MA-CORAN-X2-1 : l'etat ne passe jamais sous les commandes. Avant, il
//   etait pose dans toute la hauteur, commandes par-dessus : titre coupe a
//   « Le texte n'a pas », « Reessayer » cache dessous.
//
// Les deux groupes echouent sur l'ancien code (base 8cb178b9).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/accessibilite/commandes_masquables.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/preferences/preferences_locales.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/empty_state.dart';
import 'package:rewayah_academy/features/demo/accessibilite_demo.dart';
import 'package:rewayah_academy/features/demo/demo_accessibilite_page.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../core/accessibilite/coran_tutoiement_ma_test.dart'
    show EtatSansTexte, surchargesSansTexte;
import '../../teaching_core/c/goldens/corpus_reference.dart';

void main() {
  late CorpusReference reference;
  setUpAll(() async {
    await chargerPolicesDuDepot();
    reference = CorpusReference.charger();
  });

  Future<void> ouvrir(
    WidgetTester tester, {
    required EtatSansTexte etat,
    required Size taille,
    required bool grande,
  }) async {
    tester.view.physicalSize = taille;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ProviderContainer racine = ProviderContainer();
    addTearDown(racine.dispose);
    racine.read(preferencesLocalesProvider.notifier).lectureGrande(grande);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: racine,
        child: TranslationProvider(
          child: MaterialApp(
            theme: AppTheme.pour(InterfaceMode.enfant, Brightness.light),
            locale: AppLocale.fr.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: EcranAccessibiliteDemo(
              eleve: EleveDemoAccessibilite.idriss,
              destinationInitiale: EcranAccessibiliteDemo.indexCoran,
              surchargesCoran: surchargesSansTexte(reference, etat),
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.tap(find.byKey(const ValueKey<String>('coran-ma-principale')));
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  String invitation(EtatSansTexte etat) => etat == EtatSansTexte.absent
      ? t.accessibilite.coran.absentDetailVous
      : t.accessibilite.coran.indisponibleDetailVous;

  String titre(EtatSansTexte etat) => etat == EtatSansTexte.absent
      ? t.eleve.coran.absent
      : t.eleve.coran.indisponible;

  for (final EtatSansTexte etat in EtatSansTexte.values) {
    for (final bool grande in <bool>[false, true]) {
      final String rendu = grande ? 'verset agrandi' : 'page';
      testWidgets('MUSHAF-DIR-1 : ${etat.name}, $rendu : les phrases '
          'francaises se lisent de gauche a droite', (
        WidgetTester tester,
      ) async {
        await ouvrir(
          tester,
          etat: etat,
          taille: const Size(390, 844),
          grande: grande,
        );
        for (final String phrase in <String>[
          titre(etat),
          invitation(etat),
          if (etat == EtatSansTexte.indisponible) t.eleve.coran.reessayer,
          if (!grande) ...<String>[
            t.tc.coran.fidelite.approchee,
            t.tc.coran.fidelite.approcheeDetail,
          ],
        ]) {
          final Finder texte = find.text(phrase);
          expect(texte, findsOneWidget, reason: phrase);
          expect(
            Directionality.of(tester.element(texte)),
            TextDirection.ltr,
            reason: '« $phrase » doit garder son point final a la fin',
          );
        }
        expect(tester.takeException(), isNull);
      });

      for (final Size taille in <Size>[
        const Size(320, 700),
        const Size(390, 844),
      ]) {
        final String format = '${taille.width.toInt()} x2';
        testWidgets('MA-CORAN-X2-1 : ${etat.name}, $rendu, $format : '
            "l'etat ne passe jamais sous les commandes", (
          WidgetTester tester,
        ) async {
          await ouvrir(tester, etat: etat, taille: taille, grande: grande);
          final Rect commandes = tester.getRect(
            find.byKey(CommandesMasquables.commandesKey),
          );
          final Finder etatVide = find.byType(EmptyState);
          expect(etatVide, findsOneWidget);
          // La zone de lecture de l'etat s'arrete au-dessus des commandes.
          final Finder zone = find
              .ancestor(of: etatVide, matching: find.byType(Scrollable))
              .first;
          final Rect lecture = grande
              ? tester.getRect(etatVide)
              : tester.getRect(zone);
          expect(
            lecture.bottom,
            lessThanOrEqualTo(commandes.top + 0.5),
            reason: 'la zone de lecture passe sous les commandes',
          );
          // Chaque texte, amene a l'ecran par le defilement, finit au-dessus
          // des commandes : le titre, la phrase vouvoyee, et le BOUTON
          // « Reessayer » entier (pas seulement son libelle).
          for (final String phrase in <String>[
            titre(etat),
            invitation(etat),
            if (etat == EtatSansTexte.indisponible) t.eleve.coran.reessayer,
          ]) {
            Finder cible = find.text(phrase);
            if (phrase == t.eleve.coran.reessayer) {
              cible = find
                  .ancestor(of: cible, matching: find.byType(ActionPrincipale))
                  .first;
            }
            await Scrollable.ensureVisible(tester.element(cible), alignment: 1);
            await tester.pump();
            final Rect r = tester.getRect(cible);
            expect(
              r.bottom,
              lessThanOrEqualTo(commandes.top + 0.5),
              reason: '« $phrase » est sous les commandes',
            );
            expect(
              r.bottom,
              lessThanOrEqualTo(lecture.bottom + 0.5),
              reason: '« $phrase » ne peut pas etre amene a l\'ecran',
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
