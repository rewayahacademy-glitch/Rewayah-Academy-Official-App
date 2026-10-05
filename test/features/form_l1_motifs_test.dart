// FORM-L1-7-13 : motifs en puces, phrases-types, valeurs proposees.
//
//   * le motif choisi part TEL QUEL (meme chaine, meme RPC) ;
//   * « Autre » ouvre la saisie libre et exige un texte ;
//   * aucun bouton grise : presse trop tot, il dit ce qui manque ;
//   * les puces d'une meme ligne ont la meme hauteur et ne debordent jamais,
//     y compris a 320 px en texte x2 (K-54) ;
//   * L13 : valeur proposee ecrite telle quelle, saisie libre bornee.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/config_edition.dart';
import 'package:rewayah_academy/core/admin/service_configuration.dart';
import 'package:rewayah_academy/core/formulaires/motifs_proposes.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/filter_pill.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';

import '../support/harnais.dart';
import 'support_form_l2.dart';

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

void _fenetre(WidgetTester tester, Size taille) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Un hote qui permet d'agrandir le texte.
Widget _hoteTexte(Widget enfant, {double echelle = 1}) => hote(
  Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(echelle)),
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: enfant,
        ),
      ),
    ),
  ),
);

/// Les classes : retient aussi les clotures.
class _Groupes extends FauxGroupesFormL2 {
  final List<String> clotures = <String>[];

  @override
  Future<void> cloturer({
    required String groupeId,
    required String motif,
  }) async => clotures.add(motif);
}

class _Configuration implements ServiceConfiguration {
  final List<(String, Object)> ecrits = <(String, Object)>[];

  @override
  Future<List<ValeurConfig>> lire(List<String> cles) async =>
      const <ValeurConfig>[];

  @override
  Future<void> ecrire(String cle, Object valeur) async =>
      ecrits.add((cle, valeur));
}

void main() {
  group('SelecteurMotif, seul', () {
    testWidgets('la puce choisie est ecrite telle quelle', (
      WidgetTester tester,
    ) async {
      final TextEditingController c = TextEditingController();
      addTearDown(c.dispose);
      final List<String> recus = <String>[];
      await tester.pumpWidget(
        _hoteTexte(
          SelecteurMotif(
            motifs: MotifsProposes.retraitEleve(),
            controleur: c,
            onChange: recus.add,
          ),
        ),
      );
      await tester.tap(find.byKey(SelecteurMotif.clePuce(1)));
      await tester.pumpAndSettle();
      expect(c.text, t.motifs.retraitEleve.transfert);
      expect(recus.last, t.motifs.retraitEleve.transfert);
      // Pas de champ libre tant que « Autre » n'est pas retenu.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('« Autre » ouvre la saisie et exige un texte', (
      WidgetTester tester,
    ) async {
      final TextEditingController c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _hoteTexte(
          SelecteurMotif(
            motifs: MotifsProposes.retraitEleve(),
            controleur: c,
            erreur: t.formulaire.motif.manque,
          ),
        ),
      );
      await tester.tap(find.byKey(SelecteurMotif.clePuce(0)));
      await tester.pumpAndSettle();
      expect(c.text, isNotEmpty);
      // « Autre » efface la puce : le motif est vide tant qu'on n'a rien ecrit.
      await tester.tap(find.byKey(SelecteurMotif.cleAutre));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(c.text, isEmpty);
      expect(find.text(t.formulaire.motif.autreVide), findsOneWidget);
      await tester.enterText(find.byType(TextField), '  Demenagement  ');
      await tester.pumpAndSettle();
      expect(c.text, 'Demenagement');
      expect(find.text(t.formulaire.motif.autreVide), findsNothing);
    });

    testWidgets('une valeur deja la est reconnue, une remise a zero relue', (
      WidgetTester tester,
    ) async {
      final TextEditingController c = TextEditingController(
        text: 'Texte ecrit avant',
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _hoteTexte(
          SelecteurMotif(motifs: MotifsProposes.ajoutEleve(), controleur: c),
        ),
      );
      expect(find.widgetWithText(TextField, 'Texte ecrit avant'), findsOneWidget);
      c.clear();
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('sans motif propose, le champ libre est seul', (
      WidgetTester tester,
    ) async {
      final TextEditingController c = TextEditingController();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        _hoteTexte(
          SelecteurMotif(
            motifs: MotifsProposes.signalement('autre'),
            controleur: c,
          ),
        ),
      );
      expect(find.byType(FilterPill), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    for (final (double largeur, double echelle) in <(double, double)>[
      (390, 1),
      (320, 2),
      (1440, 1),
    ]) {
      testWidgets(
        '$largeur px, texte x$echelle : meme hauteur par ligne, aucun '
        'debordement',
        (WidgetTester tester) async {
          _fenetre(tester, Size(largeur, 2000));
          final TextEditingController c = TextEditingController();
          addTearDown(c.dispose);
          // La liste aux phrases les plus longues.
          final List<String> motifs = MotifsProposes.signalement(
            'pedagogique',
          );
          await tester.pumpWidget(
            _hoteTexte(
              SelecteurMotif(motifs: motifs, controleur: c),
              echelle: echelle,
            ),
          );
          expect(tester.takeException(), isNull);
          final List<Rect> puces = <Rect>[
            for (int i = 0; i < motifs.length; i++)
              tester.getRect(find.byKey(SelecteurMotif.clePuce(i))),
            tester.getRect(find.byKey(SelecteurMotif.cleAutre)),
          ];
          for (final Rect r in puces) {
            expect(r.left, greaterThanOrEqualTo(16 - 0.01));
            expect(r.right, lessThanOrEqualTo(largeur - 16 + 0.01));
            expect(r.height, greaterThanOrEqualTo(48));
          }
          // Meme ligne (meme haut) => meme hauteur.
          for (final Rect a in puces) {
            for (final Rect b in puces) {
              if ((a.top - b.top).abs() < 0.5) {
                expect(a.height, closeTo(b.height, 0.5));
              }
            }
          }
          // « Autre » est la derniere puce.
          expect(
            puces.last.top,
            greaterThanOrEqualTo(puces[puces.length - 2].top),
          );
        },
      );
    }
  });

  group('SelecteurEntier', () {
    testWidgets('« Autre » disparait quand tout l intervalle est propose', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _hoteTexte(
          SelecteurEntier(
            proposees: const <int>[1, 2],
            min: 1,
            max: 2,
            affichage: (int n) => '$n',
            valeurInitiale: 2,
            onChange: (int? _) {},
          ),
        ),
      );
      expect(find.byKey(SelecteurEntier.cleAutre), findsNothing);
      expect(find.byKey(SelecteurEntier.clePuce(2)), findsOneWidget);
    });
  });

  group('Classes : motifs en puces, aucun bouton grise', () {
    Future<void> monter(WidgetTester tester, List<Override> s) async {
      _fenetre(tester, const Size(1440, 1600));
      await tester.pumpWidget(hote(const GroupesPage(), surcharges: s));
      await tester.pumpAndSettle();
    }

    testWidgets('ajouter : la puce part telle quelle vers la meme RPC', (
      WidgetTester tester,
    ) async {
      final FauxGroupesFormL2 groupes = FauxGroupesFormL2();
      await monter(
        tester,
        surchargesFormL2(
          comptes: FauxComptesFormL2(comptesFormL2),
          groupes: groupes,
        ),
      );
      await _presser(tester, find.byType(MenuActions).first);
      await _presser(tester, find.text(t.admin.groupes.actionAjouter).last);
      await _presser(tester, find.byKey(const ValueKey<String>('personne-e-ines')));

      final Finder envoyer = find.widgetWithText(
        ActionPrincipale,
        t.admin.groupes.ajouterEnvoyer,
      );
      expect(tester.widget<ActionPrincipale>(envoyer).onPress, isNotNull);
      // Sans motif : la raison, rien ne part.
      await _presser(tester, envoyer);
      expect(find.text(t.formulaire.motif.manque), findsOneWidget);
      expect(groupes.ajouts, isEmpty);

      await _presser(tester, find.text(t.motifs.ajoutEleve.attente));
      await _presser(tester, envoyer);
      expect(groupes.ajouts, <(String, String)>[
        ('e-ines', t.motifs.ajoutEleve.attente),
      ]);
    });

    testWidgets('clore : « Autre » vide n aboutit pas, son texte part', (
      WidgetTester tester,
    ) async {
      final _Groupes groupes = _Groupes();
      await monter(
        tester,
        surchargesFormL2(
          comptes: FauxComptesFormL2(comptesFormL2),
          groupes: groupes,
        ),
      );
      await _presser(tester, find.byType(MenuActions).first);
      await _presser(tester, find.text(t.admin.groupes.actionCloturer).last);
      final Finder envoyer = find.widgetWithText(
        ActionPrincipale,
        t.admin.groupes.cloturerEnvoyer,
      );
      expect(tester.widget<ActionPrincipale>(envoyer).onPress, isNotNull);
      for (final String m in MotifsProposes.clotureClasse()) {
        expect(find.text(m), findsOneWidget);
      }

      await _presser(tester, find.byKey(SelecteurMotif.cleAutre));
      await _presser(tester, envoyer);
      expect(find.text(t.formulaire.motif.autreVide), findsOneWidget);
      expect(groupes.clotures, isEmpty);

      await tester.enterText(find.byType(TextField).last, 'Fusion des deux');
      await _presser(tester, envoyer);
      expect(groupes.clotures, <String>['Fusion des deux']);
    });
  });

  group('L13 : valeurs proposees des reglages entiers', () {
    test('les treize cles ont une proposition coherente', () {
      expect(reglagesEntiersProposes, hasLength(13));
      for (final MapEntry<String, ReglageEntierPropose> e
          in reglagesEntiersProposes.entries) {
        expect(e.value.min, lessThanOrEqualTo(e.value.max), reason: e.key);
        for (final int v in e.value.proposees) {
          expect(v, inInclusiveRange(e.value.min, e.value.max), reason: e.key);
        }
      }
    });

    Future<void> monter(WidgetTester tester, _Configuration config) async {
      _fenetre(tester, const Size(390, 900));
      await tester.pumpWidget(
        hote(
          Scaffold(
            body: ConfigLigneEntiere(
              titre: 'Duree de seance',
              description: 'Detail',
              cle: 'session_duration_minutes',
              valeur: 60,
              affichage: (int n) => '$n min',
              champValeur: 'Valeur',
              envoyer: 'Enregistrer',
              valeurInvalide: 'Entrez un nombre valide.',
              erreurEcriture: (String m) => m,
              onEcrit: () {},
            ),
          ),
          surcharges: <Override>[
            serviceConfigurationProvider.overrideWithValue(config),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await _presser(tester, find.text('Duree de seance'));
    }

    testWidgets('la valeur choisie est ecrite telle quelle', (
      WidgetTester tester,
    ) async {
      final _Configuration config = _Configuration();
      await monter(tester, config);
      // La valeur courante est retenue d'office.
      expect(
        tester
            .widget<FilterPill>(
              find.descendant(
                of: find.byKey(SelecteurEntier.clePuce(60)),
                matching: find.byType(FilterPill),
              ),
            )
            .retenue,
        isTrue,
      );
      await _presser(tester, find.byKey(SelecteurEntier.clePuce(45)));
      await _presser(tester, find.text('Enregistrer').last);
      expect(config.ecrits, <(String, Object)>[
        ('session_duration_minutes', 45),
      ]);
    });

    testWidgets('« Autre » hors bornes est refuse, dans les bornes ecrit', (
      WidgetTester tester,
    ) async {
      final _Configuration config = _Configuration();
      await monter(tester, config);
      await _presser(tester, find.byKey(SelecteurEntier.cleAutre));
      await tester.enterText(find.byKey(SelecteurEntier.cleChamp), '200');
      await _presser(tester, find.text('Enregistrer').last);
      expect(
        find.text(t.formulaire.entier.horsBornes(min: '30 min', max: '90 min')),
        findsOneWidget,
      );
      expect(config.ecrits, isEmpty);
      await tester.enterText(find.byKey(SelecteurEntier.cleChamp), '75');
      await _presser(tester, find.text('Enregistrer').last);
      expect(config.ecrits, <(String, Object)>[
        ('session_duration_minutes', 75),
      ]);
    });
  });
}
