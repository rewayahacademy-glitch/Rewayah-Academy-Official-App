// FORM-L8 (recensement FORM-AUTO-1, E6) : le pays et les langues de
// l'enseignant se CHOISISSENT. Le pays dans une liste preselectionnee d'apres
// le fuseau, les langues en choix multiple sur `languesCoursProvider`. Le
// contrat `declarer(pays:, langues:)` ne change pas : du texte en clair, comme
// avant.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/service_offres.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/features/demo/demo_enseignant_page.dart';
import 'package:rewayah_academy/features/demo/enseignant_demo.dart';
import 'package:rewayah_academy/features/parcours_offres/libelles_parcours.dart';
import 'package:rewayah_academy/features/profil_enseignant/declaration_choix.dart';

import '../../capture/outil_capture.dart';

Future<void> _monterProfil(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    hoteCapture(
      const CoquilleEnseignantDemo(ecran: EcranDemoEnseignant.profil),
    ),
  );
  await stabiliser(tester);
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await stabiliser(tester);
  await tester.tap(cible);
  await stabiliser(tester);
}

void main() {
  group('Pays proposes', () {
    test('chaque pays vient du libelle de son fuseau (aucun pays invente)', () {
      for (final PaysPropose p in paysProposes) {
        expect(p.fuseaux, isNotEmpty, reason: p.nom);
        for (final String iana in p.fuseaux) {
          final FuseauPropose f = fuseauxProposes.firstWhere(
            (FuseauPropose f) => f.iana == iana,
          );
          expect(f.libelle, contains(p.nom), reason: '${p.nom} / $iana');
        }
      }
      expect(paysProposes.map((PaysPropose p) => p.nom).toSet().length, 19);
    });

    test('les pays du fuseau passent en tete, l ordre reste stable', () {
      final List<String> conakry = paysOrdonnes('Africa/Conakry')
          .map((PaysPropose p) => p.nom)
          .toList();
      expect(conakry.take(4), <String>[
        'Guinée',
        'Sénégal',
        'Mali',
        'Mauritanie',
      ]);
      expect(conakry[4], 'France');
      expect(paysOrdonnes(null).first.nom, 'France');
    });

    test('preselection : declare > fuseau > rien', () {
      expect(
        paysPreselectionne(
          paysDeclare: 'Maroc',
          fuseau: 'Europe/Paris',
        )!.valeurs,
        <String>{'Maroc'},
      );
      final ReponseChoix libre = paysPreselectionne(
        paysDeclare: 'Qatar',
        fuseau: 'Europe/Paris',
      )!;
      expect(libre.valeurs, <String>{ChoiceCardGroup.valeurAutre});
      expect(libre.saisieLibre, 'Qatar');
      expect(paysPreselectionne(fuseau: 'Africa/Conakry')!.valeurs, <String>{
        'Guinée',
      });
      expect(paysPreselectionne(fuseau: 'Asia/Tokyo'), isNull);
    });

    test('reponse : la carte, ou le texte de « Autre »', () {
      expect(
        paysDeLaReponse(const ReponseChoix(valeurs: <String>{'Mali'})),
        'Mali',
      );
      expect(
        paysDeLaReponse(
          const ReponseChoix(
            valeurs: <String>{ChoiceCardGroup.valeurAutre},
            saisieLibre: '  Qatar ',
          ),
        ),
        'Qatar',
      );
      expect(
        paysDeLaReponse(
          const ReponseChoix(valeurs: <String>{ChoiceCardGroup.valeurAutre}),
        ),
        isNull,
      );
    });
  });

  group('Langues', () {
    test('publiees d abord, puis les declarees hors liste, sans doublon', () {
      final List<OptionChoix> options = optionsLangues(
        DonneesEnseignantDemo.languesCours,
        <String>['Arabe', 'Français'],
      );
      expect(options.map((OptionChoix o) => o.valeur), <String>[
        'Poular',
        'Français',
        'English',
        'Arabe',
      ]);
      expect(options.last.description, t.enseignant.profil.langueDejaDeclaree);
    });

    test('reponse : les noms coches, puis « Autre »', () {
      expect(
        languesDeLaReponse(
          const ReponseChoix(
            valeurs: <String>{'Français', ChoiceCardGroup.valeurAutre},
            saisieLibre: 'Wolof',
          ),
        ),
        <String>['Français', 'Wolof'],
      );
    });
  });

  group('Ecran ENS-05 (demonstration)', () {
    testWidgets('le pays se choisit : France pre-coche, Maroc enregistre', (
      WidgetTester tester,
    ) async {
      await _monterProfil(tester);
      await _toucher(tester, find.text(t.enseignant.profil.pays));

      expect(find.text(t.enseignant.profil.paysConsigne), findsOneWidget);
      // Aucun champ de saisie tant que « Autre » n'est pas choisi.
      expect(find.byType(TextField), findsNothing);
      // Le fuseau de la demonstration est Europe/Paris : ses trois pays sont
      // en tete et dits « d'apres votre fuseau ».
      expect(find.text(t.enseignant.profil.paysDuFuseau), findsNWidgets(3));

      await _toucher(tester, find.byKey(FeuillePays.carteKey('Maroc')));
      await _toucher(tester, find.byKey(FeuillePays.enregistrerKey));

      expect(find.text('Maroc'), findsOneWidget);
      expect(find.text(t.enseignant.profil.enregistre), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('les langues se cochent, la langue hors liste est gardee', (
      WidgetTester tester,
    ) async {
      await _monterProfil(tester);
      expect(find.text('Arabe, Français'), findsOneWidget);
      await _toucher(tester, find.text(t.enseignant.profil.langues));

      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(FeuilleLangues.carteKey('Arabe')), findsOneWidget);
      expect(find.text(t.enseignant.profil.langueDejaDeclaree), findsOneWidget);

      await _toucher(tester, find.byKey(FeuilleLangues.carteKey('Poular')));
      await _toucher(tester, find.byKey(FeuilleLangues.enregistrerKey));

      expect(find.text('Arabe, Français, Poular'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('aucune langue cochee : un message, rien n est envoye', (
      WidgetTester tester,
    ) async {
      await _monterProfil(tester);
      await _toucher(tester, find.text(t.enseignant.profil.langues));
      await _toucher(tester, find.byKey(FeuilleLangues.carteKey('Arabe')));
      await _toucher(tester, find.byKey(FeuilleLangues.carteKey('Français')));
      await _toucher(tester, find.byKey(FeuilleLangues.enregistrerKey));

      expect(find.text(t.enseignant.profil.languesRequises), findsOneWidget);
    });
  });

  testWidgets('liste des langues illisible : etat d echec, pas de bouton', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      hoteCapture(
        const Scaffold(
          body: SingleChildScrollView(
            child: FeuilleLangues(declarees: <String>['Arabe']),
          ),
        ),
        surcharges: <Override>[
          languesCoursProvider.overrideWith(
            (Ref _) => Future<List<LangueCours>>.error(StateError('panne')),
          ),
        ],
      ),
    );
    await stabiliser(tester);
    expect(find.text(t.enseignant.profil.languesErreur), findsOneWidget);
    expect(find.byKey(FeuilleLangues.enregistrerKey), findsNothing);
  });
}
