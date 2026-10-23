// ECHELLE-CTRL-DIRECT-1, cote controleur (R18, BR-CT-02, BR-CT-03, BR-CT-18,
// DECISION-CLASSES-SIMULTANEES-2026-10-10).
//
// **Le controleur ne choisit jamais sa classe**, pour empecher toute
// connivence ou corruption. Ce que le test prouve :
// - rien dans `lib/features/controleur` ne lui laisse choisir une classe ou
//   une seance : aucune lecture de planning, de catalogue ou de liste de
//   classes, aucun choix de seance sur son ecran ;
// - son ecran montre zero ou une mission, dans chacune de ses situations ;
// - le tirage simule (30 seances simultanees, 3 controleurs) donne a chaque
//   controleur au plus une mission, jamais sa propre classe (BR-CT-02),
//   jamais deux controleurs sur la meme seance, jamais une seance dont le
//   controle est deja ouvert (BR-CT-18), sans motif previsible ;
// - « deja controlee » est un message, sans bouton d'entree.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/choice_card_group.dart';
import 'package:rewayah_academy/core/widgets/menu_filtre.dart';
import 'package:rewayah_academy/core/widgets/selecteur_personne.dart';
import 'package:rewayah_academy/features/controleur/controle_page.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/demo/tirage_demo.dart';

final DateTime _debut = DateTime(2026, 10, 12, 18);

Future<void> _monter(WidgetTester tester, MissionControle? mission) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        missionControleProvider.overrideWith((Ref _) async => mission),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: ControleControleurPage(onCommencer: (MissionControle _) {}),
        ),
      ),
    ),
  );
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Le code du controleur ne laisse rien choisir', () {
    final List<File> sources = Directory('lib/features/controleur')
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .toList();

    test('les sources existent', () {
      expect(sources, isNotEmpty);
    });

    test('aucune lecture de planning, de catalogue ni de liste de classes', () {
      final RegExp interdits = RegExp(
        r'service_planning|service_controle|planningGlobal|'
        r'port_catalogue_classes|PortCatalogueClasses|port_classes_admin|'
        r'PortClassesAdmin|ClasseListee|PageClasses|service_groupes|'
        r'groupesProvider|seancesProvider|mesSeances|mes_seances',
      );
      for (final File f in sources) {
        final String code = f.readAsStringSync();
        expect(
          interdits.hasMatch(code),
          isFalse,
          reason: '${f.path} lit une liste de seances ou de classes',
        );
      }
    });

    test('la mission vient du seul fournisseur missionControleProvider', () {
      final RegExp lecture = RegExp(r'ref\.(?:watch|read)\(\s*missionControle');
      final List<String> lisent = <String>[
        for (final File f in sources)
          if (lecture.hasMatch(f.readAsStringSync())) f.path,
      ];
      expect(lisent, isNotEmpty);
      // Aucun fournisseur de liste de missions : zero ou une mission.
      for (final File f in sources) {
        expect(
          f.readAsStringSync().contains('List<MissionControle>'),
          isFalse,
          reason: '${f.path} porte une liste de missions',
        );
      }
    });
  });

  group('L ecran montre zero ou une mission', () {
    for (final EtatMissionControle etat in EtatMissionControle.values) {
      testWidgets('${etat.name} : aucun choix de seance ni de classe', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          missionVueParLeControleur(
            seancesSimultaneesDemo().first,
            debut: _debut,
            etat: etat,
          ),
        );
        expect(find.byType(ChoiceCardGroup), findsNothing);
        expect(find.byType(MenuFiltre<String>), findsNothing);
        expect(find.byType(SelecteurPersonne), findsNothing);
        expect(find.byType(DropdownMenu<String>), findsNothing);
        expect(find.byType(PopupMenuButton<String>), findsNothing);
        expect(find.byType(ListView), findsNothing);
        // Une seule seance se lit sur l'ecran : la sienne.
        expect(find.textContaining('n°').evaluate().length, lessThan(2));
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('aucune mission : le texte vide, aucun bouton', (
      WidgetTester tester,
    ) async {
      await _monter(tester, null);
      expect(find.text(t.controleur.controle.vide), findsOneWidget);
      expect(find.byKey(ControleControleurPage.commencerKey), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Le tirage simule : 30 seances simultanees, 3 controleurs', () {
    final List<SeanceEnDirect> seances = seancesSimultaneesDemo();

    test('trente seances, de meme heure, nommees sans ambiguite', () {
      expect(seances, hasLength(30));
      expect(
        seances.map((SeanceEnDirect s) => s.classe).toSet(),
        hasLength(30),
      );
    });

    test('chaque controleur recoit au plus une mission, sur 300 tirages', () {
      for (int graine = 0; graine < 300; graine++) {
        final List<MissionTiree> missions = tirerMissions(
          seances: seances,
          controleurs: controleursDemo,
          hasard: math.Random(graine),
        );
        expect(missions, hasLength(3), reason: 'graine $graine');
        final Map<String, int> parControleur = <String, int>{};
        for (final MissionTiree m in missions) {
          parControleur[m.controleurId] =
              (parControleur[m.controleurId] ?? 0) + 1;
        }
        expect(parControleur.values.every((int n) => n == 1), isTrue);
      }
    });

    test('jamais sa propre classe (BR-CT-02), jamais deux controleurs sur la '
        'meme seance (BR-CT-18)', () {
      final ControleurDemo enseignant = controleursDemo.firstWhere(
        (ControleurDemo c) => c.enseigneId != null,
      );
      final Set<String> sesClasses = <String>{
        for (final SeanceEnDirect s in seances)
          if (s.enseignantId == enseignant.enseigneId) s.id,
      };
      expect(sesClasses, isNotEmpty);
      for (int graine = 0; graine < 300; graine++) {
        final List<MissionTiree> missions = tirerMissions(
          seances: seances,
          controleurs: controleursDemo,
          hasard: math.Random(graine),
        );
        expect(
          missions.map((MissionTiree m) => m.seanceId).toSet(),
          hasLength(missions.length),
          reason: 'deux controleurs sur une seance (graine $graine)',
        );
        for (final MissionTiree m in missions) {
          if (m.controleurId == enseignant.id) {
            expect(sesClasses.contains(m.seanceId), isFalse);
          }
        }
      }
    });

    test('une seance dont le controle est deja ouvert n est jamais tiree '
        '(BR-CT-18)', () {
      final Set<String> ouverts = <String>{
        for (final SeanceEnDirect s in seances.take(27)) s.id,
      };
      for (int graine = 0; graine < 100; graine++) {
        final List<MissionTiree> missions = tirerMissions(
          seances: seances,
          controleurs: controleursDemo,
          hasard: math.Random(graine),
          controlesOuverts: ouverts,
        );
        for (final MissionTiree m in missions) {
          expect(ouverts.contains(m.seanceId), isFalse);
        }
        // Trois seances libres pour trois controleurs : le tirage n'en
        // invente pas, et le controleur-enseignant garde sa propre classe
        // exclue (BR-CT-02), donc deux ou trois missions.
        expect(missions.length, inInclusiveRange(2, 3));
      }
    });

    test('zero mission quand la frequence est atteinte ou qu aucune seance '
        'n est eligible', () {
      final List<MissionTiree> atteint = tirerMissions(
        seances: seances,
        controleurs: controleursDemo,
        hasard: math.Random(1),
        missionsRecues: const <String, int>{'demo-ctrl-3': 1},
      );
      expect(atteint, hasLength(2));
      expect(
        atteint.any((MissionTiree m) => m.controleurId == 'demo-ctrl-3'),
        isFalse,
      );
      // Toutes les seances sont celles de l'enseignant-controleur.
      final List<MissionTiree> aucune = tirerMissions(
        seances: <SeanceEnDirect>[
          const SeanceEnDirect(
            id: 's',
            classe: 'C',
            enseignantId: 'demo-ens-5',
            enseignant: 'Sayyid X',
          ),
        ],
        controleurs: const <ControleurDemo>[
          ControleurDemo(id: 'c', libelle: 'C', enseigneId: 'demo-ens-5'),
        ],
        hasard: math.Random(2),
      );
      expect(aucune, isEmpty);
    });

    test('aucun motif previsible : le meme controleur ne tombe pas sur la '
        'meme seance d une semaine a l autre', () {
      final Set<String> vues = <String>{};
      for (int semaine = 0; semaine < 12; semaine++) {
        final List<MissionTiree> missions = tirerMissions(
          seances: seances,
          controleurs: controleursDemo,
          hasard: math.Random(1000 + semaine),
        );
        vues.add(
          missions
              .firstWhere((MissionTiree m) => m.controleurId == 'demo-ctrl-1')
              .seanceId,
        );
      }
      expect(vues.length, greaterThanOrEqualTo(6));
    });

    test('la ponderation oriente le tirage sans le rendre previsible', () {
      final List<SeanceEnDirect> ponderees = <SeanceEnDirect>[
        for (final SeanceEnDirect s in seances)
          SeanceEnDirect(
            id: s.id,
            classe: s.classe,
            numero: s.numero,
            enseignantId: s.enseignantId,
            enseignant: s.enseignant,
            poids: s.numero == 1 ? 15 : 1,
          ),
      ];
      int ciblee = 0;
      const int essais = 400;
      for (int graine = 0; graine < essais; graine++) {
        final List<MissionTiree> missions = tirerMissions(
          seances: ponderees,
          controleurs: const <ControleurDemo>[
            ControleurDemo(id: 'c', libelle: 'C'),
          ],
          hasard: math.Random(graine),
        );
        if (missions.single.seanceId == 'demo-seance-1') ciblee++;
      }
      // Environ 15 / 44 : bien plus que 1 / 30, jamais toujours.
      expect(ciblee, greaterThan(essais * 0.2));
      expect(ciblee, lessThan(essais * 0.5));
    });
  });

  group('Trois controleurs, trois situations sur leur ecran', () {
    testWidgets('un controle en direct, un autre deja ouvert, aucune mission '
        'pour le troisieme', (WidgetTester tester) async {
      final List<SeanceEnDirect> seances = seancesSimultaneesDemo();
      final List<MissionTiree> missions = tirerMissions(
        seances: seances,
        controleurs: controleursDemo,
        hasard: math.Random(7),
        missionsRecues: const <String, int>{'demo-ctrl-3': 1},
      );
      expect(missions, hasLength(2));
      SeanceEnDirect seanceDe(String controleur) => seances.firstWhere(
        (SeanceEnDirect s) =>
            s.id ==
            missions
                .firstWhere((MissionTiree m) => m.controleurId == controleur)
                .seanceId,
      );

      // Le premier : sa mission est en direct, le bouton d'entree existe.
      await _monter(
        tester,
        missionVueParLeControleur(seanceDe('demo-ctrl-1'), debut: _debut),
      );
      expect(find.byKey(ControleControleurPage.commencerKey), findsOneWidget);
      await tester.pumpWidget(const SizedBox());

      // Le deuxieme : un autre controle est deja ouvert sur sa classe
      // (BR-CT-18), un message, aucun bouton.
      await _monter(
        tester,
        missionVueParLeControleur(
          seanceDe('demo-ctrl-2'),
          debut: _debut,
          etat: EtatMissionControle.dejaControlee,
        ),
      );
      expect(
        find.byKey(ControleControleurPage.dejaControleeKey),
        findsOneWidget,
      );
      expect(find.byKey(ControleControleurPage.commencerKey), findsNothing);
      await tester.pumpWidget(const SizedBox());

      // Le troisieme : sa frequence est atteinte, zero mission.
      await _monter(tester, null);
      expect(find.text(t.controleur.controle.vide), findsOneWidget);
      expect(find.byKey(ControleControleurPage.commencerKey), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
