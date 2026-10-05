// EN-7c : l'evaluation par eleve du cahier (N1 du directeur, 27/09), tapee
// depuis la vraie coquille enseignant : echelle de performance a choix
// unique, faiblesses a choix multiple, preremplies depuis la seance
// precedente ; « Ajustez la suggestion » absente quand le devoir est vide ;
// l'identifiant de l'eleve une seule fois dans la feuille.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/enseignant/depot_cahiers.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/i18n/elision.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/features/cahier/cahier_page.dart';
import 'package:rewayah_academy/features/cahier/makharij.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';

import '../../capture/outil_capture.dart';
import '../../support/harnais.dart';

Future<void> _monter(WidgetTester tester) async {
  fixerVueCapture(tester, const Size(390, 2400), 1);
  await tester.pumpWidget(
    hoteCapture(
      const CoquilleEnseignantDemo(
        ecran: EcranDemoEnseignant.cahier,
        etat: EtatDemoEnseignant.nominal,
      ),
      surcharges: <Override>[
        depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
      ],
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
  await tester.pump(const Duration(milliseconds: 700));
  await stabiliser(tester);
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Set<String> _retenues(WidgetTester tester, String cle) => tester
    .widget<ChoiceCardGroup>(
      find.descendant(of: _cle(cle), matching: find.byType(ChoiceCardGroup)),
    )
    .valeurInitiale!
    .valeurs;

void main() {
  testWidgets('niveau et faiblesse choisis, prerempli, puis valide', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _toucher(tester, find.text('Nour'));

    // Les mots du directeur, tels quels.
    for (final String mot in <String>[
      'À revoir',
      'En progrès',
      'Acquis',
      'Maîtrisé',
      'Makharij',
      'Madd',
      'Ghunna',
      'Waqf',
      'Fluidité',
      'Mémorisation',
    ]) {
      expect(find.text(mot), findsOneWidget, reason: mot);
    }

    // Prerempli depuis la seance precedente.
    expect(_retenues(tester, 'cahier-emplacement-performance'), <String>{
      'enProgres',
    });
    expect(_retenues(tester, 'cahier-emplacement-faiblesses'), <String>{
      'madd',
    });

    // Le devoir est vide : pas de « suggestion » a ajuster.
    expect(find.text(t.enseignant.cahier.travailMaisonDetail), findsNothing);
    expect(_cle('cahier-devoir-suggestion'), findsNothing);

    // L'identifiant de l'eleve, une seule fois.
    expect(find.text('RA-NOUR'), findsOneWidget);

    await _toucher(tester, _cle('cahier-performance-acquis'));
    await _toucher(tester, _cle('cahier-faiblesse-waqf'));
    await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));

    // Le niveau retenu se relit sur la ligne avant de valider.
    expect(find.text(t.enseignant.cahier.niveauAcquis), findsOneWidget);

    // Rouverte, la feuille garde le choix.
    await _toucher(tester, find.text('Nour'));
    expect(_retenues(tester, 'cahier-emplacement-performance'), <String>{
      'acquis',
    });
    expect(_retenues(tester, 'cahier-emplacement-faiblesses'), <String>{
      'madd',
      'waqf',
    });
    await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));

    await _toucher(tester, _cle('cahier-valider'));
    expect(find.text(t.enseignant.cahier.depose), findsOneWidget);
  });

  // EN-7c-200 (K-61) : la feuille « Ajuster » de Nour, ouverte depuis la vraie
  // coquille, a 200 % de texte, sur 390 et sur 320 de large. Un debordement
  // leve une exception de rendu et fait echouer le test de lui-meme ; on
  // verifie en plus que le bouton du bas s'atteint en defilant, et qu'il
  // enregistre.
  for (final double largeur in <double>[390, 320]) {
    testWidgets(
      'feuille Ajuster a 200 % de texte, ${largeur.toInt()} de large',
      (WidgetTester tester) async {
        fixerVueCapture(tester, Size(largeur, 844), 1);
        await tester.pumpWidget(
          hoteCapture(
            const CoquilleEnseignantDemo(
              ecran: EcranDemoEnseignant.cahier,
              etat: EtatDemoEnseignant.nominal,
            ),
            surcharges: <Override>[
              depotRapportsProvider.overrideWithValue(FauxDepotRapports()),
            ],
            echelleTexte: 2,
          ),
        );
        await stabiliser(tester);
        expect(tester.takeException(), isNull);

        await _toucher(tester, find.text('Nour'));
        expect(tester.takeException(), isNull);
        expect(
          find.text(t.enseignant.cahier.ajusterPour(eleve: 'Nour')),
          findsOneWidget,
        );
        expect(_cle('cahier-emplacement-performance'), findsOneWidget);
        expect(_cle('cahier-emplacement-faiblesses'), findsOneWidget);

        // Aucun texte de la feuille n'est tronque (ellipse ou lignes
        // coupees) : la feuille entiere est mise en page dans son defilement,
        // chaque paragraphe se controle, meme hors de l'ecran.
        void aucunTexteTronque() {
          final List<RenderParagraph> paragraphes = tester
              .renderObjectList<RenderParagraph>(
                find.descendant(
                  of: find.byType(FeuilleAjusterCahier),
                  matching: find.byType(RichText),
                ),
              )
              .toList();
          expect(paragraphes, isNotEmpty);
          for (final RenderParagraph p in paragraphes) {
            expect(
              p.didExceedMaxLines,
              isFalse,
              reason: 'tronque : ${p.text.toPlainText()}',
            );
          }
        }

        aucunTexteTronque();

        // Le bouton du bas : atteint en defilant le corps de la feuille, puis
        // tape ; la feuille se referme sur la decision.
        final Finder enregistrer = find.text(
          t.enseignant.cahier.ajusterValider,
        );
        expect(enregistrer, findsOneWidget);
        // Le titre nomme chaque champ une seule fois : pas de label flottant
        // repete, qui se coupait a 320 (« Objectif de No… »).
        expect(
          find.text(t.enseignant.cahier.objectif(deEleve: deDevant('Nour'))),
          findsOneWidget,
        );
        expect(
          find.text(
            t.enseignant.cahier.travailMaison(deEleve: deDevant('Nour')),
          ),
          findsOneWidget,
        );
        // Le devoir saisi se lit en entier : le champ grandit avec son texte
        // au lieu de le faire defiler dans deux lignes fixes.
        await tester.ensureVisible(_cle('cahier-devoir'));
        await stabiliser(tester);
        await tester.enterText(
          _cle('cahier-devoir'),
          DonneesEnseignantDemo.brouillonCahier()
              .participants
              .first
              .devoirPrecedent!,
        );
        await stabiliser(tester);
        // EN-7c-MINEURS : le meme controle apres la saisie du long devoir.
        aucunTexteTronque();
        expect(
          tester
              .state<ScrollableState>(
                find.descendant(
                  of: _cle('cahier-devoir'),
                  matching: find.byType(Scrollable),
                ),
              )
              .position
              .maxScrollExtent,
          0,
        );
        await _toucher(tester, _cle('cahier-performance-acquis'));
        await _toucher(tester, enregistrer);
        expect(tester.takeException(), isNull);
        expect(enregistrer, findsNothing);
        expect(find.text(t.enseignant.cahier.niveauAcquis), findsOneWidget);
      },
    );
  }

  // EN-7c-SUGG-T, cas negatif, depuis la vraie coquille : aucune source ne
  // suggere de devoir, donc ni « Ajustez la suggestion » a l'ouverture, ni
  // apres que l'enseignant a saisi le sien ; rouverte, la feuille dit que le
  // devoir est deja note.
  testWidgets('devoir saisi par l enseignant : jamais dit « suggestion »', (
    WidgetTester tester,
  ) async {
    await _monter(tester);
    await _toucher(tester, find.text('Nour'));
    expect(_cle('cahier-devoir-suggestion'), findsNothing);
    expect(_cle('cahier-devoir-saisi'), findsNothing);

    // Une donnee de la demonstration : le devoir precedent de Nour.
    final String devoir = DonneesEnseignantDemo.brouillonCahier()
        .participants
        .first
        .devoirPrecedent!;
    await tester.ensureVisible(_cle('cahier-devoir'));
    await stabiliser(tester);
    await tester.enterText(_cle('cahier-devoir'), devoir);
    await stabiliser(tester);
    // Toujours pas une suggestion pendant la saisie.
    expect(_cle('cahier-devoir-suggestion'), findsNothing);
    await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));

    await _toucher(tester, find.text('Nour'));
    expect(_cle('cahier-devoir-suggestion'), findsNothing);
    expect(find.text(t.enseignant.cahier.travailMaisonDetail), findsNothing);
    expect(_cle('cahier-devoir-saisi'), findsOneWidget);
    expect(find.text(t.enseignant.cahier.travailMaisonSaisi), findsOneWidget);
    expect(
      tester.widget<TextField>(_cle('cahier-devoir')).controller!.text,
      devoir,
    );
  });

  // EN-7c-SUGG-T, cas positif : une vraie suggestion (decision marquee
  // `devoirSuggere`) affiche « Ajustez la suggestion » ; gardee telle quelle,
  // elle reste une suggestion, modifiee, elle devient le devoir de
  // l'enseignant. Aucune source ne l'alimente encore, la coquille ne peut donc
  // pas l'atteindre (K-07 hors de portee) : la feuille est ouverte comme le
  // cahier l'ouvre, par `AppBottomSheet.ouvrir`, avec une decision suggeree.
  // Le jour ou une source existera, ce test devra passer par la coquille.
  for (final bool modifier in <bool>[false, true]) {
    testWidgets('devoir suggere : « Ajustez la suggestion », '
        '${modifier ? 'modifie' : 'garde'}', (WidgetTester tester) async {
      fixerVueCapture(tester, const Size(390, 2400), 1);
      final BrouillonCahier brouillon = DonneesEnseignantDemo.brouillonCahier();
      final ParticipantBrouillon nour = brouillon.participants.first;
      final String suggestion = nour.devoirPrecedent!;
      DecisionEleve? rendue;
      await tester.pumpWidget(
        hoteCapture(
          Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    rendue = await AppBottomSheet.ouvrir<DecisionEleve>(
                      context,
                      titre: t.enseignant.cahier.ajusterPour(eleve: 'Nour'),
                      constructeur: (BuildContext _) => FeuilleAjusterCahier(
                        participant: nour,
                        brouillon: brouillon,
                        decision: DecisionEleve(
                          studentId: nour.membre.studentId,
                          travailMaison: suggestion,
                          devoirSuggere: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await _toucher(tester, find.text('ouvrir'));

      expect(_cle('cahier-devoir-suggestion'), findsOneWidget);
      expect(
        find.text(t.enseignant.cahier.travailMaisonDetail),
        findsOneWidget,
      );
      expect(_cle('cahier-devoir-saisi'), findsNothing);
      expect(
        tester.widget<TextField>(_cle('cahier-devoir')).controller!.text,
        suggestion,
      );

      if (modifier) {
        await tester.enterText(_cle('cahier-devoir'), '$suggestion !');
        await stabiliser(tester);
      }
      await _toucher(tester, find.text(t.enseignant.cahier.ajusterValider));
      expect(rendue, isNotNull);
      expect(rendue!.devoirSuggere, !modifier);
      expect(rendue!.travailMaison, modifier ? '$suggestion !' : suggestion);
      // La provenance reste a l'ecran : elle ne part pas dans le cahier.
      expect(rendue!.versJson().containsKey('devoir_suggere'), isFalse);
    });
  }

  // EN-7c-200 : les titres visibles des deux champs sont exclus de la
  // semantique ; le nom doit donc etre porte par le noeud du champ editable
  // lui-meme, pas par un noeud voisin.
  testWidgets('objectif et devoir : le champ editable porte son nom', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantique = tester.ensureSemantics();
    await _monter(tester);
    await _toucher(tester, find.text('Nour'));
    for (final (String cle, String nom) in <(String, String)>[
      (
        'cahier-objectif',
        t.enseignant.cahier.objectif(deEleve: deDevant('Nour')),
      ),
      (
        'cahier-devoir',
        t.enseignant.cahier.travailMaison(deEleve: deDevant('Nour')),
      ),
    ]) {
      final SemanticsNode noeud = tester.getSemantics(
        find.descendant(of: _cle(cle), matching: find.byType(EditableText)),
      );
      expect(noeud, isSemantics(isTextField: true), reason: cle);
      expect(noeud.getSemanticsData().label, contains(nom), reason: cle);
    }
    semantique.dispose();
  });

  test('la paire arabe d un makhraj est isolee et insecable', () {
    final String sinSad = referentielMakharij().first.libelle;
    expect(sinSad, 'Sîn / Sâd (\u2067س\u00A0/\u00A0ص\u2069)');
    for (final OptionChoix o in referentielMakharij()) {
      expect(o.libelle, contains('(\u2067'), reason: o.valeur);
      expect(o.libelle, contains('\u2069)'), reason: o.valeur);
    }
  });

  test('la decision preremplie ne suggere aucun devoir (pas de source)', () {
    final ParticipantBrouillon nour =
        DonneesEnseignantDemo.brouillonCahier().participants.first;
    final DecisionEleve d = DecisionEleve.preremplie(nour);
    expect(d.travailMaison, isNull);
    expect(d.devoirSuggere, isFalse);
  });

  test('l echec reseau ne dit jamais « n a pas ete envoye » (D5)', () {
    expect(
      t.enseignant.cahier.echecEnvoi,
      "L'envoi n'a pas été confirmé. Vérifiez avant de réessayer.",
    );
  });

  test('la decision preremplie part avec performance et faiblesses', () {
    final ParticipantBrouillon nour =
        DonneesEnseignantDemo.brouillonCahier().participants.first;
    final Map<String, dynamic> json = DecisionEleve.preremplie(nour).versJson();
    expect(json['performance'], 'enProgres');
    expect(json['faiblesses'], <String>['madd']);
  });
}
