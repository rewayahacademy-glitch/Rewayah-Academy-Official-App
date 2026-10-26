import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_card.dart';
import 'package:rewayah_academy/core/widgets/avatar_tile.dart';
import 'package:rewayah_academy/core/widgets/bouton_couleur.dart';
import 'package:rewayah_academy/core/widgets/bouton_icone.dart';
import 'package:rewayah_academy/core/widgets/bouton_outil.dart';
import 'package:rewayah_academy/core/widgets/commande_salle.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';

import '../support/garde_interface.dart';
import '../support/hote_theme.dart';

/// Gardes de la revue du directeur des 01 et 02/10/2026 (K-54, K-55, K-56) sur les
/// composants partages : un defaut vu a l'ecran doit echouer ici.
void main() {
  const String court = 'Poser un creneau';
  const String long =
      'Declarer l\'absence de Yasmine pour la seance du mardi 14 octobre';

  group('K-54 : libelle de bouton centre', () {
    for (final double echelle in <double>[1, 2]) {
      for (final NiveauAction niveau in NiveauAction.values) {
        for (final bool pleine in <bool>[true, false]) {
          for (final String libelle in <String>[court, long]) {
            testWidgets(
              '${niveau.name}, pleine largeur $pleine, echelle $echelle, '
              '${libelle.length} car. a 320 px',
              (WidgetTester tester) async {
                fixerVue(tester, const Size(320, 640));
                await tester.pumpWidget(
                  hoteTheme(
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ActionPrincipale(
                          libelle: libelle,
                          onPress: () {},
                          niveau: niveau,
                          pleineLargeur: pleine,
                        ),
                      ),
                    ),
                    echelleTexte: echelle,
                  ),
                );
                verifierBoutonCentre(
                  tester,
                  find.byType(ActionPrincipale),
                  libelle,
                );
              },
            );
          }
        }
      }
    }
  });

  group('K-55 : cartes jamais collees', () {
    testWidgets('des cartes separees par Ecart passent la garde', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        hoteTheme(
          const Column(
            children: <Widget>[
              AppCard(child: Text('Une')),
              Ecart.vMd,
              AppCard(child: Text('Deux')),
              Ecart.vMd,
              AppCard(child: Text('Trois')),
            ],
          ),
        ),
      );
      verifierEcartCartes(tester, find.byType(AppCard), minimum: AppSpacing.md);
    });

    testWidgets('des cartes jointives font echouer la garde', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        hoteTheme(
          const Column(
            children: <Widget>[
              AppCard(child: Text('Une')),
              AppCard(child: Text('Deux')),
            ],
          ),
        ),
      );
      expect(
        () => verifierEcartCartes(
          tester,
          find.byType(AppCard),
          minimum: AppSpacing.md,
        ),
        throwsA(isA<TestFailure>()),
      );
    });
  });

  group('Avatar et nom', () {
    testWidgets('les centres sont alignes sur une ligne, a 320 px', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 640));
      await tester.pumpWidget(
        hoteTheme(
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                AvatarTile(prenom: 'Yasmine', diametre: 48),
                Ecart.hMd,
                Text('Yasmine'),
              ],
            ),
          ),
        ),
      );
      verifierAlignes(
        tester,
        find.byType(AvatarTile),
        find.text('Yasmine').last,
      );
    });

    testWidgets('les initiales sont centrees dans le cercle', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 640));
      await tester.pumpWidget(
        hoteTheme(
          const Align(
            alignment: Alignment.topLeft,
            child: AvatarTile(prenom: 'Yasmine', diametre: 48),
          ),
        ),
      );
      final Rect cercle = tester.getRect(find.byType(AvatarTile));
      final Rect initiale = tester.getRect(
        find.descendant(
          of: find.byType(AvatarTile),
          matching: find.byType(Text),
        ),
      );
      expect((initiale.center.dx - cercle.center.dx).abs(), lessThan(1.5));
      expect((initiale.center.dy - cercle.center.dy).abs(), lessThan(1.5));
    });
  });

  group('Aucun element ne recouvre un contenu', () {
    for (final double echelle in <double>[1, 2]) {
      testWidgets('carte, titre et bouton a 320 px, echelle $echelle', (
        WidgetTester tester,
      ) async {
        fixerVue(tester, const Size(320, 640));
        await tester.pumpWidget(
          hoteTheme(
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: <Widget>[
                  const Text('Seance du mardi 14 octobre', key: Key('titre')),
                  Ecart.vMd,
                  const AppCard(child: Text('Yasmine, Coran, 30 min')),
                  Ecart.vMd,
                  ActionPrincipale(libelle: court, onPress: () {}),
                ],
              ),
            ),
            echelleTexte: echelle,
          ),
        );
        verifierSansChevauchement(tester, <Finder>[
          find.byKey(const Key('titre')),
          find.byType(AppCard),
          find.byType(ActionPrincipale),
        ]);
      });
    }
  });

  // K-54 (BTN-CENTRE-1) : chaque composant partage qui peint un bouton centre
  // son contenu en largeur ET en hauteur, sans deborder, a 320 et 1440 px, en
  // texte normal et en texte x2, en clair et en sombre, que le parent l'etire
  // (Column stretch) ou le laisse a sa largeur naturelle.
  group('K-54 : composants partages, contenu centre', () {
    const String libelle = 'Tester';
    const String longLibelle =
        'Tester la camera et le micro avant la seance du mardi';

    final Map<String, ({Widget Function(String) cree, List<Finder> contenu})>
    composants =
        <String, ({Widget Function(String) cree, List<Finder> contenu})>{
          'FilterPill': (
            cree: (String l) =>
                FilterPill(libelle: l, onPress: () {}, retenue: true),
            // FILTERPILL-ETAT-1 : la coche fait partie du contenu centre.
            contenu: <Finder>[find.byType(Text), find.byType(Icon)],
          ),
          'LienFleche': (
            cree: (String l) => LienFleche(libelle: l, onPress: () {}),
            contenu: <Finder>[find.byType(Text), find.byType(Icon)],
          ),
          'LienFleche sans fleche': (
            cree: (String l) =>
                LienFleche(libelle: l, onPress: () {}, fleche: false),
            contenu: <Finder>[find.byType(Text)],
          ),
          'StatusPill': (
            cree: (String l) => StatusPill(libelle: l, ton: TonEtat.accent),
            contenu: <Finder>[
              find.byType(Text),
              find.byWidgetPredicate(
                (Widget w) =>
                    w is SizedBox && w.width == StatusPill.diametrePastille,
              ),
            ],
          ),
          'MenuFiltre': (
            cree: (String l) => MenuFiltre<int>(
              libelle: l,
              valeur: null,
              entrees: const <EntreeFiltre<int>>[],
              onChoix: (int? _) {},
            ),
            contenu: <Finder>[find.byType(Text), find.byType(Icon)],
          ),
          'ActionPrincipale doux': (
            cree: (String l) => ActionPrincipale(
              libelle: l,
              onPress: () {},
              niveau: NiveauAction.destructive,
              doux: true,
              prefixe: const Icon(Icons.circle, size: 20),
            ),
            contenu: <Finder>[find.byType(Text), find.byType(Icon)],
          ),
          'ActionPrincipale fleche': (
            cree: (String l) =>
                ActionPrincipale(libelle: l, onPress: () {}, fleche: true),
            contenu: <Finder>[find.byType(Text), find.byType(Icon)],
          ),
          'BoutonOutil nu': (
            cree: (String l) => BoutonOutil(
              icone: AppIcons.crayon,
              libelle: l,
              avecLibelle: true,
              retenu: true,
              onPress: () {},
            ),
            contenu: <Finder>[find.byType(Text), find.byType(Icon)],
          ),
          'BoutonOutil tuile': (
            cree: (String l) => BoutonOutil(
              icone: AppIcons.crayon,
              libelle: l,
              avecLibelle: true,
              forme: FormeBoutonOutil.tuile,
              onPress: () {},
            ),
            contenu: <Finder>[find.byType(Text), find.byType(Icon)],
          ),
        };

    for (final MapEntry<
          String,
          ({Widget Function(String) cree, List<Finder> contenu})
        >
        c
        in composants.entries) {
      for (final double largeur in <double>[320, 1440]) {
        for (final double echelle in <double>[1, 2]) {
          for (final Brightness lum in Brightness.values) {
            for (final bool etire in <bool>[true, false]) {
              for (final String l in <String>[
                libelle,
                if (!c.key.startsWith('Bouton')) longLibelle,
              ]) {
                testWidgets(
                  '${c.key} : ${l.length} car., ${largeur.toInt()} px, '
                  'texte x${echelle.toInt()}, ${lum.name}, '
                  '${etire ? 'etire' : 'naturel'}',
                  (WidgetTester tester) async {
                    fixerVue(tester, Size(largeur, 900));
                    await tester.pumpWidget(
                      hoteTheme(
                        Column(
                          crossAxisAlignment: etire
                              ? CrossAxisAlignment.stretch
                              : CrossAxisAlignment.center,
                          children: <Widget>[
                            if (c.key == 'BoutonOutil tuile')
                              SizedBox(height: 96, child: c.value.cree(l))
                            else
                              c.value.cree(l),
                          ],
                        ),
                        echelleTexte: echelle,
                        luminosite: lum,
                      ),
                    );
                    final Finder bouton = find
                        .byWidgetPredicate(
                          (Widget w) =>
                              w.runtimeType.toString() ==
                              c.value.cree(l).runtimeType.toString(),
                        )
                        .first;
                    verifierContenuCentre(tester, bouton, c.value.contenu);
                    expect(tester.takeException(), isNull);
                  },
                );
              }
            }
          }
        }
      }
    }

    testWidgets('un libelle qui passe a la ligne reste centre ligne a ligne', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(320, 900));
      await tester.pumpWidget(
        hoteTheme(
          Column(
            children: <Widget>[
              ActionPrincipale(libelle: longLibelle, onPress: () {}),
              FilterPill(libelle: longLibelle, onPress: () {}),
              const StatusPill(libelle: longLibelle, ton: TonEtat.neutre),
            ],
          ),
          echelleTexte: 2,
        ),
      );
      verifierLibelleCentreLigneALigne(
        tester,
        find.byType(ActionPrincipale),
        longLibelle,
      );
      verifierLibelleCentreLigneALigne(
        tester,
        find.byType(FilterPill),
        longLibelle,
      );
      verifierLibelleCentreLigneALigne(
        tester,
        find.byType(StatusPill),
        longLibelle,
      );
    });

    for (final double largeur in <double>[320, 1440]) {
      testWidgets(
        'ActionPrincipale pleineLargeur: false prend la largeur de son '
        'contenu, jamais celle de son parent, a ${largeur.toInt()} px',
        (WidgetTester tester) async {
          fixerVue(tester, Size(largeur, 900));
          await tester.pumpWidget(
            hoteTheme(
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ActionPrincipale(
                  libelle: libelle,
                  onPress: () {},
                  pleineLargeur: false,
                ),
              ),
            ),
          );
          final Rect bouton = tester.getRect(find.byType(ActionPrincipale));
          expect(
            bouton.width,
            lessThan(largeur / 2),
            reason: 'le bouton non pleine largeur s\'etire : $bouton',
          );
        },
      );
    }
  });

  group('K-54 : boutons icone et commandes rondes, contenu centre', () {
    for (final double largeur in <double>[320, 1440]) {
      for (final double echelle in <double>[1, 2]) {
        for (final FormeBoutonIcone forme in FormeBoutonIcone.values) {
          testWidgets(
            'BoutonIcone ${forme.name} : icone au centre de sa cible, '
            '${largeur.toInt()} px, texte x${echelle.toInt()}',
            (WidgetTester tester) async {
              fixerVue(tester, Size(largeur, 900));
              await tester.pumpWidget(
                hoteTheme(
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: BoutonIcone(
                      icone: AppIcons.zoomPlus,
                      libelle: 'Agrandir',
                      forme: forme,
                      onPress: () {},
                    ),
                  ),
                  echelleTexte: echelle,
                ),
              );
              verifierContenuCentre(tester, find.byType(BoutonIcone), <Finder>[
                find.byType(Icon),
              ]);
            },
          );
        }
        for (final FondCommande fond in FondCommande.values) {
          testWidgets(
            'CommandeSalle ${fond.name} : disque et mot centres l un sur '
            'l autre, ${largeur.toInt()} px, texte x${echelle.toInt()}',
            (WidgetTester tester) async {
              fixerVue(tester, Size(largeur, 900));
              await tester.pumpWidget(
                hoteTheme(
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: CommandeSalle(
                      icone: AppIcons.micro.repos,
                      libelle: 'Micro',
                      fond: fond,
                      onPress: () {},
                    ),
                  ),
                  echelleTexte: echelle,
                ),
              );
              final Rect disque = tester.getRect(
                find.byKey(const ValueKey<String>('disque-appel')),
              );
              final Rect mot = tester.getRect(find.text('Micro'));
              final Rect icone = tester.getRect(
                find.descendant(
                  of: find.byKey(const ValueKey<String>('disque-appel')),
                  matching: find.byType(Icon),
                ),
              );
              expect((mot.center.dx - disque.center.dx).abs(), lessThan(1.5));
              expect((icone.center.dx - disque.center.dx).abs(), lessThan(1.5));
              expect((icone.center.dy - disque.center.dy).abs(), lessThan(1.5));
              expect(disque.bottom, lessThanOrEqualTo(mot.top));
            },
          );
        }
        // Plan de la salle du 26/10/2026 (Q1, §3) : la commande nommee de
        // l'ordinateur (bouton rond, nom dessous) et la pastille de couleur.
        testWidgets(
          'CommandeSalleNommee : bouton et nom centres l un sur l autre, '
          '${largeur.toInt()} px, texte x${echelle.toInt()}',
          (WidgetTester tester) async {
            fixerVue(tester, Size(largeur, 900));
            await tester.pumpWidget(
              hoteTheme(
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CommandeSalleNommee(
                    nom: 'Bibliothèque',
                    bouton: BoutonIcone(
                      icone: AppIcons.bibliotheque,
                      libelle: 'Bibliothèque',
                      forme: FormeBoutonIcone.appel,
                      onPress: () {},
                    ),
                  ),
                ),
                echelleTexte: echelle,
              ),
            );
            final Rect bouton = tester.getRect(find.byType(BoutonIcone));
            final Rect nom = tester.getRect(find.text('Bibliothèque'));
            expect((nom.center.dx - bouton.center.dx).abs(), lessThan(1.5));
            expect(bouton.bottom, lessThanOrEqualTo(nom.top));
            verifierContenuCentre(tester, find.byType(BoutonIcone), <Finder>[
              find.byType(Icon),
            ]);
          },
        );
        for (final bool retenue in <bool>[false, true]) {
          testWidgets(
            'BoutonCouleur ${retenue ? 'retenue' : 'libre'} : disque au '
            'centre de sa cible, ${largeur.toInt()} px, texte '
            'x${echelle.toInt()}',
            (WidgetTester tester) async {
              fixerVue(tester, Size(largeur, 900));
              await tester.pumpWidget(
                hoteTheme(
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: BoutonCouleur(
                      encre: AppNuancierTrait.bleu,
                      libelle: 'Bleu',
                      retenue: retenue,
                      onPress: () {},
                    ),
                  ),
                  echelleTexte: echelle,
                ),
              );
              verifierContenuCentre(
                tester,
                find.byType(BoutonCouleur),
                <Finder>[find.byKey(const ValueKey<String>('disque-couleur'))],
              );
              expect(
                tester.getSize(find.byType(BoutonCouleur)).height,
                greaterThanOrEqualTo(48),
              );
              // L'etat ne se dit jamais par la couleur seule.
              expect(
                find.byType(Icon),
                retenue ? findsOneWidget : findsNothing,
              );
            },
          );
        }
      }
    }
  });

  group('K-56 : un seul bouton plein', () {
    testWidgets('la garde compte les boutons pleins, pas les autres niveaux', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        hoteTheme(
          Column(
            children: <Widget>[
              ActionPrincipale(libelle: 'Envoyer', onPress: () {}),
              ActionPrincipale(
                libelle: 'Revenir',
                onPress: () {},
                niveau: NiveauAction.secondaire,
              ),
              ActionPrincipale(
                libelle: 'Plus tard',
                onPress: () {},
                niveau: NiveauAction.tertiaire,
              ),
              LienFleche(libelle: 'Choisir une photo', onPress: () {}),
            ],
          ),
        ),
      );
      verifierUnSeulBoutonPlein(tester);
    });

    testWidgets('deux boutons pleins font echouer la garde', (
      WidgetTester tester,
    ) async {
      fixerVue(tester, const Size(390, 844));
      await tester.pumpWidget(
        hoteTheme(
          Column(
            children: <Widget>[
              ActionPrincipale(libelle: 'Envoyer', onPress: () {}),
              ActionPrincipale(libelle: 'Choisir une photo', onPress: () {}),
            ],
          ),
        ),
      );
      expect(
        () => verifierUnSeulBoutonPlein(tester),
        throwsA(isA<TestFailure>()),
      );
    });
  });
}
