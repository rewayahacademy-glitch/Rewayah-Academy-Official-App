// FORM-L8 (recensement FORM-AUTO-1, E6) : le pays et les langues de
// l'enseignant se CHOISISSENT. Le pays dans une liste preselectionnee d'apres
// le fuseau, les langues en choix multiple sur `referentielLanguesProvider`.
// Le contrat `declarer(pays:, langues:)` ne change pas de forme ; les langues
// y partent en CODES de `langues_cours` et s'affichent par leur nom
// (CAND-Q15, lot langue).

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
        <String>['Arabe', 'francais'],
      );
      // On enregistre le code, on affiche le nom.
      expect(options.map((OptionChoix o) => o.valeur), <String>[
        'poular',
        'francais',
        'english',
        'Arabe',
      ]);
      expect(options.map((OptionChoix o) => o.libelle), <String>[
        'Poular',
        'Français',
        'English',
        'Arabe',
      ]);
      // La cle d'une carte suit toujours le nom affiche.
      expect(options[1].cle, FeuilleLangues.carteKey('Français'));
      expect(options.last.description, t.enseignant.profil.langueDejaDeclaree);
    });

    test('un nom ou un code deja declare ne cree pas de seconde carte', () {
      // Un ancien client enregistrait le nom ; une saisie peut varier en
      // casse et en espaces. Toutes retrouvent la carte du referentiel.
      final List<OptionChoix> options = optionsLangues(
        DonneesEnseignantDemo.languesCours,
        <String>['Français', ' francais ', 'FRANCAIS', 'english', 'Arabe'],
      );
      expect(options.map((OptionChoix o) => o.valeur), <String>[
        'poular',
        'francais',
        'english',
        'Arabe',
      ]);
      expect(
        options.map((OptionChoix o) => o.cle).toSet(),
        hasLength(options.length),
      );
      expect(
        languesPreselectionnees(<String>[
          'Français',
          ' francais ',
          'Arabe',
          '',
        ], DonneesEnseignantDemo.languesCours).valeurs,
        <String>{'francais', 'Arabe'},
      );
    });

    test('une langue retiree reste une carte cochee, nommee', () {
      const List<LangueCours> referentiel = <LangueCours>[
        LangueCours(code: 'poular', nom: 'Poular', actif: false),
        LangueCours(code: 'francais', nom: 'Français'),
      ];
      final List<OptionChoix> options = optionsLangues(referentiel, <String>[
        'poular',
      ]);
      expect(options.map((OptionChoix o) => o.valeur), <String>[
        'francais',
        'poular',
      ]);
      expect(options.last.libelle, 'Poular');
      expect(options.last.description, t.enseignant.profil.langueDejaDeclaree);
    });

    test(
      'nomLangueCours : le nom pour un code, la saisie libre telle quelle',
      () {
        const List<LangueCours> referentiel = <LangueCours>[
          LangueCours(code: 'poular', nom: 'Poular', actif: false),
          LangueCours(code: 'francais', nom: 'Français'),
        ];
        expect(nomLangueCours('francais', referentiel), 'Français');
        // Retiree de l'onboarding, toujours lisible sur un profil.
        expect(nomLangueCours('poular', referentiel), 'Poular');
        // Un nom stocke avant la correction.
        expect(nomLangueCours('Français', referentiel), 'Français');
        expect(nomLangueCours(' Wolof ', referentiel), 'Wolof');
      },
    );

    test('codeLangueCours : un code exact passe avant un nom homonyme', () {
      // Meme regle que le declencheur serveur (relecture) : « Soninke »
      // designe le code `soninke`, pas la langue d'ordre plus petit qui
      // porte ce nom.
      const List<LangueCours> referentiel = <LangueCours>[
        LangueCours(code: 'snk', nom: 'Soninke'),
        LangueCours(code: 'soninke', nom: 'Sarakole'),
      ];
      expect(codeLangueCours('Soninke', referentiel), 'soninke');
      expect(codeLangueCours('sarakole', referentiel), 'soninke');
      expect(codeLangueCours('SNK', referentiel), 'snk');
      expect(codeLangueCours(' Wolof ', referentiel), 'Wolof');
    });

    test('reponse : les codes coches, puis « Autre »', () {
      expect(
        languesDeLaReponse(
          const ReponseChoix(
            valeurs: <String>{'francais', ChoiceCardGroup.valeurAutre},
            saisieLibre: 'Wolof',
          ),
        ),
        <String>['francais', 'Wolof'],
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
          referentielLanguesProvider.overrideWith(
            (Ref _) => Future<List<LangueCours>>.error(StateError('panne')),
          ),
        ],
      ),
    );
    await stabiliser(tester);
    expect(find.text(t.enseignant.profil.languesErreur), findsOneWidget);
    expect(find.byKey(FeuilleLangues.enregistrerKey), findsNothing);
  });

  testWidgets('un nom deja declare coche la carte de sa langue, une seule', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    List<String>? enregistrees;
    await tester.pumpWidget(
      hoteCapture(
        Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: TextButton(
                onPressed: () async {
                  enregistrees = await Navigator.of(context).push(
                    MaterialPageRoute<List<String>>(
                      builder: (BuildContext _) => const Scaffold(
                        body: SingleChildScrollView(
                          child: FeuilleLangues(
                            declarees: <String>['Français', ' francais '],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
        surcharges: <Override>[
          referentielLanguesProvider.overrideWith(
            (Ref _) async => DonneesEnseignantDemo.languesCours,
          ),
        ],
      ),
    );
    await stabiliser(tester);
    await _toucher(tester, find.text('ouvrir'));

    expect(find.byKey(FeuilleLangues.carteKey('Français')), findsOneWidget);
    expect(find.text(t.enseignant.profil.langueDejaDeclaree), findsNothing);
    expect(tester.takeException(), isNull);

    await _toucher(tester, find.byKey(FeuilleLangues.enregistrerKey));
    expect(enregistrees, <String>['francais']);
  });

  // Revue CAND-Q15 (lot langue) : les phrases de la feuille des langues
  // n'avaient pas de traduction arabe, et slang retombait sur le francais
  // (`fallback_strategy: base_locale`). Chaque cas cherche la phrase arabe
  // ET l'absence de la phrase francaise : sans traduction, les deux sont la
  // meme chaine et le second `findsNothing` echoue.
  group('Langues, en arabe : aucune phrase francaise', () {
    // L'arabe est une bibliotheque differee : `setLocale` la charge.
    setUp(() => LocaleSettings.setLocale(AppLocale.ar));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    Future<void> monterFeuille(
      WidgetTester tester,
      Future<List<LangueCours>> Function() referentiel,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        hoteCapture(
          const Scaffold(
            body: SingleChildScrollView(
              child: FeuilleLangues(declarees: <String>['Arabe', 'francais']),
            ),
          ),
          surcharges: <Override>[
            referentielLanguesProvider.overrideWith((Ref _) => referentiel()),
          ],
        ),
      );
      await stabiliser(tester);
    }

    testWidgets('feuille lue : consigne, langue declaree, langue requise', (
      WidgetTester tester,
    ) async {
      final Traductions$enseignant$profil$fr fr = AppLocale.fr
          .buildSync()
          .enseignant
          .profil;
      await monterFeuille(
        tester,
        () async => DonneesEnseignantDemo.languesCours,
      );
      expect(
        Directionality.of(tester.element(find.byType(FeuilleLangues))),
        TextDirection.rtl,
      );

      expect(find.text(t.enseignant.profil.languesConsigne), findsOneWidget);
      expect(find.text(fr.languesConsigne), findsNothing);
      // « Arabe » est hors du referentiel : sa carte porte la mention.
      expect(find.text(t.enseignant.profil.langueDejaDeclaree), findsOneWidget);
      expect(find.text(fr.langueDejaDeclaree), findsNothing);

      await _toucher(tester, find.byKey(FeuilleLangues.carteKey('Arabe')));
      await _toucher(tester, find.byKey(FeuilleLangues.carteKey('Français')));
      await _toucher(tester, find.byKey(FeuilleLangues.enregistrerKey));

      expect(find.text(t.enseignant.profil.languesRequises), findsOneWidget);
      expect(find.text(fr.languesRequises), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('liste illisible : titre et phrase de l echec', (
      WidgetTester tester,
    ) async {
      final Traductions$enseignant$profil$fr fr = AppLocale.fr
          .buildSync()
          .enseignant
          .profil;
      await monterFeuille(
        tester,
        () => Future<List<LangueCours>>.error(StateError('panne')),
      );

      expect(find.text(t.enseignant.profil.languesErreur), findsOneWidget);
      expect(find.text(fr.languesErreur), findsNothing);
      expect(
        find.text(t.enseignant.profil.languesErreurDetail),
        findsOneWidget,
      );
      expect(find.text(fr.languesErreurDetail), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
