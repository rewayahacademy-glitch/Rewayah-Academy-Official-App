// ASSETS-DIR-1 : la politique de controle des enseignants (partie B de
// `POLITIQUE_CONTROLE_ENSEIGNANTS.md`, validee le 02/10/2026), portee mot
// pour mot avec les quatre valeurs de sa section 10 (pilotage
// `COORDONNEES_LEGALES.md`, decide par delegation le 05/10/2026).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/entete_page.dart'
    show DisqueRetour;
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/features/dossier/politique_controle.dart';
import 'package:rewayah_academy/features/salle_seance/information_controle.dart';

import '../capture/outil_capture.dart';
import '../support/aucun_mot_coupe.dart';

/// Un ecran minimal qui ouvre la politique, comme le contrat et le profil.
class _Ouvreur extends StatelessWidget {
  const _Ouvreur();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: LienFleche(
        libelle: t.contrat.politique.lien,
        onPress: () => unawaited(ouvrirPolitiqueControle(context)),
      ),
    ),
  );
}

void main() {
  group('Le texte valide, mot pour mot', () {
    test('dix sections, dans l ordre de la partie B', () {
      final List<SectionPolitique> sections = sectionsPolitiqueControle();
      expect(sections, hasLength(10));
      expect(sections.map((SectionPolitique s) => s.titre).toList(), <String>[
        '1. Pourquoi nous contrôlons',
        '2. Comment se passe une visite',
        '3. Ce qui est écrit',
        '4. Qui lit',
        '5. Combien de temps',
        '6. Contester un rapport (B7)',
        "7. Ce que l'académie peut décider",
        '8. Vos droits',
        '9. Base légale',
        '10. Contact',
      ]);
    });

    test('section 10 : les quatre valeurs, et le contact de la constante '
        'unique', () {
      final String contact = sectionsPolitiqueControle().last.blocs.single;
      expect(
        contact,
        'Responsable : Rewayah Academy Ltd, société n° 16624644 immatriculée '
        'en Angleterre et au pays de Galles, 71-75 Shelton Street, Covent '
        'Garden, Londres WC2H 9JQ, Royaume-Uni. Contact confidentialité : '
        'support@rewayahacademy.com. Représentant dans l\'UE : pas encore '
        'désigné ; l\'application ne s\'ouvre pas aux familles de l\'Union '
        'européenne avant sa désignation.',
      );
      expect(contact, contains(InformationControle.contactConfidentialite));
      // Aucun champ du modele laisse vide.
      for (final SectionPolitique s in sectionsPolitiqueControle()) {
        for (final String b in s.blocs) {
          expect(b, isNot(contains('{')), reason: b);
        }
      }
    });

    test('des phrases cles, sans marque de mise en forme a la lecture', () {
      final List<String> plats = <String>[
        for (final SectionPolitique s in sectionsPolitiqueControle())
          ...s.blocs.map(textePlatBloc),
      ];
      expect(
        plats,
        contains(
          'Vous n\'êtes pas prévenu du moment de la visite. Vous êtes prévenu '
          'à l\'avance qu\'elle peut avoir lieu : par ce texte, par votre '
          'contrat et par le bandeau permanent de la salle « visite de '
          'contrôle possible ».',
        ),
      );
      expect(plats, contains('protéger les élèves ;'));
      expect(
        plats,
        contains(
          'Vous avez 7 jours à partir du jour où vous recevez la synthèse '
          'mensuelle.',
        ),
      );
      for (final String p in plats) {
        expect(p, isNot(startsWith('- ')));
        expect(p, isNot(contains('**')));
      }
    });
  });

  group('La lecture : 320 et 1440, texte 100 et 200 %, clair et sombre', () {
    setUpAll(chargerPolicesDuDepot);

    for (final Size taille in <Size>[
      const Size(320, 690),
      const Size(1440, 900),
    ]) {
      for (final double echelle in <double>[1, 2]) {
        for (final ThemeMode mode in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          testWidgets('${taille.width.toInt()}, texte '
              '${(echelle * 100).toInt()} %, ${mode.name} : aucune erreur, '
              'aucun mot coupe, la derniere phrase est atteinte, la lecture '
              'se ferme', (WidgetTester tester) async {
            fixerVueCapture(tester, taille, 1);
            await tester.pumpWidget(
              hoteCapture(
                const _Ouvreur(),
                themeMode: mode,
                echelleTexte: echelle,
              ),
            );
            await stabiliser(tester);
            await tester.tap(find.text(t.contrat.politique.lien));
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            expect(find.text(t.contrat.politique.titre), findsOneWidget);
            verifierAucunMotCoupe(tester, find.byType(TextePolitiqueControle));

            // La derniere phrase (l'adresse y porte ses points de coupure
            // invisibles, `coupuresAdresse`).
            final Finder fin = find.textContaining(
              'Union européenne avant sa désignation.',
            );
            await tester.drag(
              find.byType(Scrollable).last,
              const Offset(0, -100000),
            );
            await stabiliser(tester);
            expect(tester.takeException(), isNull);
            final Rect derniere = tester.getRect(fin);
            // Le bas du dernier paragraphe est dans l'ecran (a 320 et 200 %,
            // ce paragraphe est a lui seul plus haut que l'ecran : seul son
            // bas compte, c'est la fin du texte).
            expect(derniere.bottom, lessThanOrEqualTo(taille.height));
            expect(derniere.bottom, greaterThan(0));
            verifierAucunMotCoupe(tester, find.byType(TextePolitiqueControle));

            // Plein ecran sous 840 : le disque retour ; au-dela, la croix
            // de la boite de dialogue.
            final Finder disque = find.byType(DisqueRetour);
            await tester.tap(
              disque.evaluate().isNotEmpty
                  ? disque.last
                  : find.byTooltip(t.commun.fermer),
            );
            await stabiliser(tester);
            expect(find.text(t.contrat.politique.titre), findsNothing);
          });
        }
      }
    }
  });
}
