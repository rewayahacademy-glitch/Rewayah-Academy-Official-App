// Q-09 : Interface guidee -- les cibles tactiles respectent une taille
// minimale.
//
// Spec section 14.1 (« grandes cibles tactiles »), decision D-07
// (« Interface guidee », jamais « mode enfant »), invariant 10 de la Phase 6.
//
// DEUX CHOSES SONT VERIFIEES, ET ELLES SONT DISTINCTES.
// 1. Le JETON : le socle declare deja `AppTouchTarget.enfant` a 72 et
//    `.standard` a 48. Le Teaching Core les consomme, il n en pose pas un
//    troisieme.
// 2. LE RENDU : un bouton construit avec ce jeton mesure vraiment 72 a
//    l ecran. Un jeton juste et un rendu faux se ressemblent beaucoup dans un
//    fichier de theme, et pas du tout sous le doigt d un enfant de sept ans.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';

import 'support/lecture_sources.dart';

/// Le seuil d accessibilite communement admis pour une cible tactile.
const double _seuilAccessibilite = 48;

/// Un bouton dimensionne par le jeton de l interface demandee.
Widget _bouton({required InterfaceMode mode, required Key cle}) {
  final double cote = mode == InterfaceMode.enfant
      ? AppTouchTarget.enfant
      : AppTouchTarget.standard;
  return Center(
    child: SizedBox(key: cle, width: cote, height: cote),
  );
}

void main() {
  group('Q-09 : les jetons de cible tactile', () {
    test(
      'le socle declare deja les deux tailles, on n en pose pas une troisieme',
      () {
        expect(AppTouchTarget.standard, _seuilAccessibilite);
        expect(AppTouchTarget.enfant, 72);
        expect(AppTouchTarget.enfant, greaterThan(AppTouchTarget.standard));
        expect(
          AppTouchTarget.standard,
          greaterThanOrEqualTo(_seuilAccessibilite),
        );
      },
    );
  });

  group('Q-09 : le rendu respecte le jeton', () {
    testWidgets('une cible d interface guidee mesure au moins 72', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: _bouton(
            mode: InterfaceMode.enfant,
            cle: const Key('cible-guidee'),
          ),
        ),
      );

      final Size taille = tester.getSize(find.byKey(const Key('cible-guidee')));
      expect(taille.width, greaterThanOrEqualTo(AppTouchTarget.enfant));
      expect(taille.height, greaterThanOrEqualTo(AppTouchTarget.enfant));
    });

    testWidgets('une cible standard mesure au moins 48', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: _bouton(
            mode: InterfaceMode.standard,
            cle: const Key('cible-standard'),
          ),
        ),
      );

      final Size taille = tester.getSize(
        find.byKey(const Key('cible-standard')),
      );
      expect(taille.width, greaterThanOrEqualTo(_seuilAccessibilite));
      expect(taille.height, greaterThanOrEqualTo(_seuilAccessibilite));
    });

    testWidgets('la cible guidee reste plus grande a fort grossissement', (
      WidgetTester tester,
    ) async {
      // Une cible fixee en dur ne suit pas le grossissement du texte, mais
      // elle ne doit surtout pas RETRECIR : le test verifie le plancher, qui
      // est ce qui compte pour la main.
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          // Le MediaQuery doit etre INTERIEUR a MaterialApp : celui-ci
          // reconstruit le sien depuis la vue et ecraserait un ancetre.
          home: Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: _bouton(
                mode: InterfaceMode.enfant,
                cle: const Key('cible-guidee-zoom'),
              ),
            ),
          ),
        ),
      );

      final Size taille = tester.getSize(
        find.byKey(const Key('cible-guidee-zoom')),
      );
      expect(taille.shortestSide, greaterThanOrEqualTo(AppTouchTarget.enfant));
    });
  });

  group('Q-09 : le nom visible n est jamais « mode enfant »', () {
    test('la valeur SQL reste child, et ce n est pas un libelle', () {
      // Decision D-07, arbitrage de portee : c est un renommage de LIBELLE,
      // pas de valeur ni d identifiant. `InterfaceMode.enfant` reste, la
      // valeur SQL 'child' reste, et l interface dit « Interface guidee ».
      expect(InterfaceMode.enfant.valeurSql, 'child');
      expect(InterfaceMode.depuisSql('child'), InterfaceMode.enfant);
      expect(InterfaceMode.depuisSql('standard'), InterfaceMode.standard);
    });

    test('aucun libelle des fixtures Teaching Core ne dit « mode enfant »', () {
      // La recherche porte sur l EXPRESSION interdite, pas sur le mot
      // « enfant » seul : `TypePublicGroupeVM.enfant` porte legitimement la
      // valeur SQL 'enfant', qui designe le public d un groupe et n a rien a
      // voir avec le mode d interface.
      final List<String> fautifs = <String>[];
      for (final File f in fichiersDart(CheminsDoubles.repertoireFixtures)) {
        final List<String> trouves = motsTrouves(
          f.readAsStringSync(),
          const <String>['mode enfant', 'modeenfant', 'mode-enfant'],
        );
        if (trouves.isNotEmpty) fautifs.add('${f.path} -> $trouves');
      }
      expect(fautifs, isEmpty);
    });
  });
}
