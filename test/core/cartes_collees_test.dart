import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_admin.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/dossier/service_validation.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/bento_tile.dart';
import 'package:rewayah_academy/core/widgets/carte_groupee.dart';
import 'package:rewayah_academy/core/widgets/carte_lignes.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/core/widgets/groupe_reglages.dart';
import 'package:rewayah_academy/core/widgets/pile_cartes.dart';
import 'package:rewayah_academy/core/widgets/setting_row.dart';
import 'package:rewayah_academy/core/widgets/stat_tile.dart';
import 'package:rewayah_academy/features/admin_tableau/tableau_de_bord_page.dart';
import 'package:rewayah_academy/features/compte/compte_page.dart';

import '../support/garde_interface.dart';
import '../support/harnais.dart';
import '../support/hote_theme.dart';

/// K-55, revue du directeur du 01/10 : jamais de cartes collees. Les gardes
/// mesurent la geometrie rendue : composants partages, puis ecrans reels, a
/// 320 px et 1440 px, texte x1 et x2, clair et sombre.

bool _estCarte(Widget w) =>
    w is AppCard ||
    w is BentoTile ||
    w is StatTile ||
    w is GroupeReglages ||
    w is CarteLignes ||
    w is CarteGroupee ||
    w is SettingRow;

bool _estPastille(Widget w) =>
    w is AppCard && w.marge != null && w.marge! < AppSpacing.lg;

const List<Size> _vues = <Size>[Size(320, 4000), Size(1440, 4000)];

Future<void> _balayer(
  WidgetTester tester,
  Widget Function() ecran,
  Future<void> Function() attendre, {
  List<Override> surcharges = const <Override>[],
  int minimumSurfaces = 2,
}) async {
  for (final Size vue in _vues) {
    for (final double echelle in <double>[1, 2]) {
      for (final Brightness lumiere in Brightness.values) {
        fixerVue(tester, vue);
        await tester.pumpWidget(
          hoteTheme(
            ecran(),
            echelleTexte: echelle,
            luminosite: lumiere,
            surcharges: surcharges,
            defilant: false,
          ),
        );
        await attendre();
        final int n = verifierAucuneCarteCollee(
          tester,
          estCarte: _estCarte,
          estPastille: _estPastille,
        );
        expect(
          n,
          greaterThanOrEqualTo(minimumSurfaces),
          reason:
              'l\'ecran doit montrer des cartes (${vue.width} px, x$echelle)',
        );
      }
    }
  }
}

Widget _carte(String texte) => AppCard(child: Text(texte));

void main() {
  group('PileCartes', () {
    testWidgets('separe les cartes de 16 au moins, partout', (
      WidgetTester tester,
    ) async {
      await _balayer(
        tester,
        () => PileCartes(
          children: <Widget>[_carte('un'), _carte('deux'), _carte('trois')],
        ),
        () => tester.pump(),
        minimumSurfaces: 3,
      );
    });

    testWidgets('mesure l\'ecart entre deux cartes consecutives', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 800));
      await tester.pumpWidget(
        hoteTheme(
          PileCartes(
            children: <Widget>[_carte('un'), _carte('deux'), _carte('trois')],
          ),
          defilant: false,
        ),
      );

      verifierEcartCartes(tester, find.byType(AppCard), minimum: AppSpacing.lg);
    });

    test('refuse un ecart inferieur a 16', () {
      expect(
        () => PileCartes(ecart: AppSpacing.sm, children: const <Widget>[]),
        throwsAssertionError,
      );
    });

    testWidgets('le garde voit des cartes collees quand on les colle', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 800));
      await tester.pumpWidget(
        hoteTheme(
          Column(children: <Widget>[_carte('un'), _carte('deux')]),
          defilant: false,
        ),
      );

      expect(
        () => verifierAucuneCarteCollee(tester, estCarte: _estCarte),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('CarteGroupee', () {
    testWidgets('est une seule carte a filets entre les sections', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 800));
      await tester.pumpWidget(
        hoteTheme(
          const CarteGroupee(
            sections: <Widget>[Text('a'), Text('b'), Text('c')],
          ),
          defilant: false,
        ),
      );

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(FiletCarte), findsNWidgets(2));
      expect(verifierAucuneCarteCollee(tester, estCarte: _estCarte), 1);
    });
  });

  group('CarteLignes', () {
    testWidgets('porte une seule surface pour toutes ses lignes', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 800));
      await tester.pumpWidget(
        hoteTheme(
          const CarteLignes(
            lignes: <Widget>[
              SettingRow(title: 'Un', icon: AppIcons.reglages),
              SettingRow(title: 'Deux', icon: AppIcons.reglages),
              SettingRow(title: 'Trois', icon: AppIcons.reglages),
            ],
          ),
          defilant: false,
        ),
      );

      expect(find.byType(FiletCarte), findsNWidgets(2));
      // Une surface : les lignes a plat ne sont pas des cartes.
      expect(verifierAucuneCarteCollee(tester, estCarte: _estCarte), 1);
    });

    testWidgets('une ligne seule reste une carte, deux collees sont vues', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 800));
      await tester.pumpWidget(
        hoteTheme(
          const Column(
            children: <Widget>[
              SettingRow(title: 'Un', icon: AppIcons.reglages),
              SettingRow(title: 'Deux', icon: AppIcons.reglages),
            ],
          ),
          defilant: false,
        ),
      );

      expect(
        () => verifierAucuneCarteCollee(tester, estCarte: _estCarte),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('ChoiceCardGroup', () {
    const List<Key> cles = <Key>[
      ValueKey<String>('option-a'),
      ValueKey<String>('option-b'),
      ValueKey<String>('option-c'),
    ];

    testWidgets('separe ses cartes de 16 au moins, en liste et cote a cote', (
      WidgetTester tester,
    ) async {
      for (final bool coteACote in <bool>[false, true]) {
        for (final Size vue in <Size>[
          const Size(320, 1200),
          const Size(1440, 900),
        ]) {
          fixerVue(tester, vue);
          await tester.pumpWidget(
            hoteTheme(
              ChoiceCardGroup(
                coteACote: coteACote,
                autoriserSaisieLibre: false,
                options: <OptionChoix>[
                  OptionChoix(
                    valeur: 'a',
                    libelle: 'Premiere option',
                    cle: cles[0],
                  ),
                  OptionChoix(
                    valeur: 'b',
                    libelle: 'Deuxieme option',
                    cle: cles[1],
                  ),
                  OptionChoix(
                    valeur: 'c',
                    libelle: 'Troisieme option',
                    cle: cles[2],
                  ),
                ],
                onChange: (ReponseChoix _) {},
              ),
              defilant: false,
            ),
          );

          for (int i = 1; i < cles.length; i++) {
            final Rect avant = tester.getRect(find.byKey(cles[i - 1]));
            final Rect apres = tester.getRect(find.byKey(cles[i]));
            // SUPERPOS-1 : cote a cote, les cartes s'empilent quand un mot
            // ne tient pas dans une carte (320 px) ; l'ecart se mesure sur
            // l'axe reellement pris. Lot E2 : a 1440, les options passent en
            // bento, liste comprise ; deux cartes d'une meme bande se
            // mesurent aussi a l'horizontale (deux cartes de liste qui se
            // recouvriraient donnent toujours un ecart negatif).
            final bool enLigne = apres.top < avant.bottom;
            final double ecart = enLigne
                ? apres.left - avant.right
                : apres.top - avant.bottom;
            expect(
              ecart,
              greaterThanOrEqualTo(AppSpacing.lg - toleranceGarde),
              reason:
                  'options $i-1 et $i collees (coteACote $coteACote, '
                  '${vue.width} px) : ecart $ecart',
            );
          }
        }
      }
    });
  });

  group('ecrans reels', () {
    testWidgets('le tableau de bord de la direction', (
      WidgetTester tester,
    ) async {
      final FauxServiceAdmin admin = FauxServiceAdmin()
        ..indicateursRendus = const IndicateursAdmin(
          dossiersEnAttente: 3,
          foyersSansEnseignant: 2,
          rapportsManquants: 1,
          incidents24h: 0,
          comptesEchus: 0,
          demandesEnAttente: 4,
        );
      final FauxServiceValidation validation = FauxServiceValidation()
        ..file = <DossierAValider>[
          for (int i = 0; i < 3; i++)
            DossierAValider(
              documentId: 'doc$i',
              profilId: 'p$i',
              type: TypePiece.carteIdentite,
              cleObjet: 'p/$i.webp',
              deposeLe: DateTime(2026, 9, 5 + i),
              prenom: 'Moussa$i',
              nom: 'Barry',
              identifiantImmuable: 'TEACHER-MB-00000$i',
              role: AppRole.teacher,
            ),
        ];
      await _balayer(
        tester,
        () => TableauDeBordPage(horloge: () => DateTime(2026, 9, 8, 17)),
        () => tester.pumpAndSettle(),
        surcharges: <Override>[
          serviceAdminProvider.overrideWithValue(admin),
          serviceValidationProvider.overrideWithValue(validation),
        ],
        // DASH-ADM-1 : les cinq tuiles et la carte des raccourcis ; la liste
        // « A traiter en premier » (trois lignes-cartes) a quitte l'ecran.
        minimumSurfaces: 6,
      );
    });

    testWidgets('les reglages du compte', (WidgetTester tester) async {
      await _balayer(
        tester,
        () => const ReglagesComptePage(),
        () => tester.pump(),
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        ],
        minimumSurfaces: 5,
      );
    });

    testWidgets('le portail du compte', (WidgetTester tester) async {
      await _balayer(
        tester,
        () => const ComptePage(),
        () => tester.pump(),
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        ],
        minimumSurfaces: 2,
      );
    });

    testWidgets('le profil personnel', (WidgetTester tester) async {
      await _balayer(
        tester,
        () => const ProfilPersonnelPage(),
        () => tester.pump(),
        surcharges: <Override>[
          sourceSessionProvider.overrideWithValue(FausseSourceSession()),
        ],
        minimumSurfaces: 2,
      );
    });
  });
}
