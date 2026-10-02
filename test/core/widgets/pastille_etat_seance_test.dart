import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/seance_famille/seance_famille.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/pastille_etat_seance.dart';

import '../../support/hote_theme.dart';
import '../../theme/support/contraste.dart';

/// ON-AIR-1 et ANNUL-VIS-1 (revue du directeur, 01-02/10/2026) : la pastille
/// d'etat de seance, ses deux etats, le mouvement reduit, 320 px, texte x2,
/// le contraste mesure sur la pastille, clair et sombre.

Widget _hote(
  Widget enfant, {
  Brightness luminosite = Brightness.light,
  double echelle = 1,
  bool mouvementReduit = false,
}) => hoteTheme(
  Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: mouvementReduit),
      child: enfant,
    ),
  ),
  luminosite: luminosite,
  echelleTexte: echelle,
);

Finder get _halo => find.byKey(const ValueKey<String>('pastille-direct-halo'));

/// Le fond et l'encre de la pastille, tels que rendus.
({Color fond, Color encre}) _couleursPastille(WidgetTester tester, String mot) {
  final Finder pastille = find.ancestor(
    of: find.text(mot),
    matching: find.byType(Container),
  );
  final Container conteneur = tester.widget<Container>(pastille.first);
  final BoxDecoration decoration = conteneur.decoration! as BoxDecoration;
  final Color encre = tester.widget<Text>(find.text(mot)).style!.color!;
  return (fond: decoration.color!, encre: encre);
}

void main() {
  group('En direct', () {
    testWidgets('dit le mot et bat doucement, puis reste fixe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect)),
      );
      expect(find.text(t.etat.enDirect), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('pastille-direct-point')),
        findsOneWidget,
      );

      // Un cycle dure environ 1,5 s : au milieu, le halo est la.
      await tester.pump(const Duration(milliseconds: 750));
      expect(_halo, findsOneWidget);

      // Trois cycles, 4,5 s (sous les 5 s de WCAG 2.2.2) : puis plus rien ne
      // bouge. pumpAndSettle aboutit, preuve que le battement est borne.
      await tester.pumpAndSettle();
      expect(_halo, findsNothing);
      expect(
        find.byKey(const ValueKey<String>('pastille-direct-point')),
        findsOneWidget,
      );
      expect(find.text(t.etat.enDirect), findsOneWidget);
    });

    testWidgets('mouvement reduit : point fixe, aucun halo, le mot reste', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect),
          mouvementReduit: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 750));
      expect(_halo, findsNothing);
      expect(
        find.byKey(const ValueKey<String>('pastille-direct-point')),
        findsOneWidget,
      );
      expect(find.text(t.etat.enDirect), findsOneWidget);
      // Rien ne tourne : aucun cadre en attente.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('lit « En direct » au lecteur d\'ecran', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await tester.pumpWidget(
        _hote(const PastilleEtatSeance(etat: EtatPastilleSeance.enDirect)),
      );
      expect(find.bySemanticsLabel(t.etat.enDirect), findsOneWidget);
      poignee.dispose();
    });
  });

  group('Annulee', () {
    testWidgets('dit le mot avec l\'icone d\'annulation, sans battement', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(const PastilleEtatSeance(etat: EtatPastilleSeance.annulee)),
      );
      expect(find.text(t.etat.seanceAnnulee), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('pastille-annulee-icone')),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 750));
      expect(_halo, findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('l\'heure est barree et dite au lecteur d\'ecran', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle poignee = tester.ensureSemantics();
      await tester.pumpWidget(
        _hote(
          const Column(
            children: <Widget>[
              TexteHeureSeance(heure: '10:00', annulee: true),
              TexteHeureSeance(heure: '11:00', annulee: false),
            ],
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('10:00')).style!.decoration,
        TextDecoration.lineThrough,
      );
      expect(
        tester.widget<Text>(find.text('11:00')).style?.decoration,
        isNot(TextDecoration.lineThrough),
      );
      expect(
        find.bySemanticsLabel(t.etat.heureAnnulee(heure: '10:00')),
        findsOneWidget,
      );
      poignee.dispose();
    });

    testWidgets('la ligne dit pourquoi et la suite, quand elle existe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hote(
          const Column(
            children: <Widget>[
              LigneRaisonSeance(
                raison: 'Aucun remplacant trouve',
                suite: 'seance non facturee',
              ),
              LigneRaisonSeance(raison: 'Cette seance n\'aura pas lieu'),
            ],
          ),
        ),
      );
      expect(
        find.text('Aucun remplacant trouve · seance non facturee'),
        findsOneWidget,
      );
      expect(find.text('Cette seance n\'aura pas lieu'), findsOneWidget);
    });

    testWidgets('la carte annulee s\'attenue par sa surface, sans opacite', (
      WidgetTester tester,
    ) async {
      late AppPalette palette;
      await tester.pumpWidget(
        _hote(
          Builder(
            builder: (BuildContext context) {
              palette = AppPalette.of(context);
              return AppCard(
                surface: surfaceCarteSeance(palette, annulee: true),
                child: const Text('Carte'),
              );
            },
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(AppCard),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
      expect(surfaceCarteSeance(palette, annulee: true), palette.surfaceSunken);
      expect(
        surfaceCarteSeance(palette, annulee: false),
        palette.surfaceRaised,
      );
    });
  });

  group('Contraste mesure sur la pastille (clair et sombre)', () {
    for (final Brightness luminosite in Brightness.values) {
      for (final EtatPastilleSeance etat in EtatPastilleSeance.values) {
        testWidgets('${etat.name} en ${luminosite.name} : >= 4,5:1', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            _hote(PastilleEtatSeance(etat: etat), luminosite: luminosite),
          );
          final String mot = PastilleEtatSeance.libelleDe(etat);
          final ({Color fond, Color encre}) c = _couleursPastille(tester, mot);
          expect(
            contraste(c.encre, c.fond),
            greaterThanOrEqualTo(seuilTexte),
            reason: 'mot ${etat.name} ${luminosite.name}',
          );
          if (etat == EtatPastilleSeance.annulee) {
            final Icon icone = tester.widget<Icon>(
              find.byKey(const ValueKey<String>('pastille-annulee-icone')),
            );
            expect(
              contraste(icone.color!, c.fond),
              greaterThanOrEqualTo(seuilComposant),
              reason: 'icone d\'annulation ${luminosite.name}',
            );
          } else {
            final BoxDecoration point =
                tester
                        .widget<DecoratedBox>(
                          find.descendant(
                            of: find.byKey(
                              const ValueKey<String>('pastille-direct-point'),
                            ),
                            matching: find.byType(DecoratedBox),
                          ),
                        )
                        .decoration
                    as BoxDecoration;
            expect(
              contraste(point.color!, c.fond),
              greaterThanOrEqualTo(seuilComposant),
              reason: 'point ${luminosite.name}',
            );
          }
        });
      }

      testWidgets('heure barree sur carte annulee en ${luminosite.name}', (
        WidgetTester tester,
      ) async {
        late AppPalette palette;
        await tester.pumpWidget(
          _hote(
            Builder(
              builder: (BuildContext context) {
                palette = AppPalette.of(context);
                return const SizedBox();
              },
            ),
            luminosite: luminosite,
          ),
        );
        final AppPalette p = palette;
        expect(
          contraste(
            p
                .encreSecondaireSur(p.surfaceSunken)
                .applyTo(const TextStyle())
                .color!,
            p.surfaceSunken.background,
          ),
          greaterThanOrEqualTo(seuilTexte),
        );
      });
    }
  });

  group('Geometrie', () {
    for (final double echelle in <double>[1, 2]) {
      for (final double largeur in <double>[320, 1440]) {
        for (final EtatPastilleSeance etat in EtatPastilleSeance.values) {
          testWidgets(
            '${etat.name} a $largeur px, texte x$echelle : ne deborde pas',
            (WidgetTester tester) async {
              fixerVue(tester, Size(largeur, 800));
              await tester.pumpWidget(
                _hote(
                  PastilleEtatSeance(
                    etat: etat,
                    libelle:
                        'Seance du lundi, ${PastilleEtatSeance.libelleDe(etat)}'
                        ' (reportee au prochain creneau libre)',
                  ),
                  echelle: echelle,
                ),
              );
              await tester.pump(const Duration(milliseconds: 750));
              expect(tester.takeException(), isNull);
              final Rect pastille = tester.getRect(
                find.byType(PastilleEtatSeance),
              );
              expect(pastille.left, greaterThanOrEqualTo(0));
              expect(pastille.right, lessThanOrEqualTo(largeur));
            },
          );
        }
      }
    }
  });

  group('Table etat de famille', () {
    test('en direct et prolongee = en direct, annulees = annulee', () {
      expect(
        etatPastilleDe(EtatSeanceFamille.enDirect),
        EtatPastilleSeance.enDirect,
      );
      expect(
        etatPastilleDe(EtatSeanceFamille.prolongee),
        EtatPastilleSeance.enDirect,
      );
      expect(
        etatPastilleDe(EtatSeanceFamille.annulee),
        EtatPastilleSeance.annulee,
      );
      expect(
        etatPastilleDe(EtatSeanceFamille.annuleeTardive),
        EtatPastilleSeance.annulee,
      );
      expect(etatPastilleDe(EtatSeanceFamille.aVenir), isNull);
      expect(etatPastilleDe(EtatSeanceFamille.terminee), isNull);
      expect(etatPastilleDe(EtatSeanceFamille.nonTenue), isNull);
    });
  });
}
