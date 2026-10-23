// ECHELLE-ADM-FUSION-1 : fusion de classes paralleles, transfert d'un eleve,
// historique (R5, R9, R10, DECISION-CLASSES-SIMULTANEES-2026-10-10).
//
// Ce que le test prouve :
// - les classes cibles sont les classes paralleles (meme horaire, meme
//   categorie, meme genre) qui ont de la place pour tous les eleves (fusion)
//   ou pour un seul (transfert) ;
// - la fusion montre l'apercu des effets (eleves deplaces, effectif apres,
//   enseignant libere, familles prevenues) avant la confirmation, est
//   atomique et idempotente (double appui : une seule fusion ; reponse
//   perdue : meme cle reprise) ;
// - un transfert qui chevauche une autre classe de l'eleve est refuse en
//   clair (R5), une classe pleine aussi ;
// - l'historique des deux classes garde la fusion et le transfert ;
// - une action n'existe que si le serveur dit que la personne peut la faire ;
// - les 5 etats de chaque feuille, 320 px texte x2, RTL.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_classes_admin.dart';
import 'package:rewayah_academy/core/admin/port_fusion_classes.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_fusion/feuilles_fusion.dart';
import 'package:rewayah_academy/features/admin_fusion/fusion_libelles.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';
import 'package:rewayah_academy/features/demo/classes_admin_demo.dart';
import 'package:rewayah_academy/features/demo/fusion_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';

final DateTime _maintenant = DateTime(2026, 10, 10, 18, 5);

/// La famille de 30 classes paralleles : n° 11 compte 1 eleve, n° 12 en
/// compte 2 (sous le minimum), les autres de 3 a 5 sur 5.
String _id(int n) => 'demo-famille-lun18-$n';

class _Banc {
  _Banc({List<ClasseListee>? classes}) {
    classesDemo = ClassesAdminDemo(
      classes: classes ?? familleDemo(),
      ajuster: (ClasseListee c) => fusion.ajuster(c),
    );
    fusion = FusionDemo(
      classes: classesDemo.toutesBrutes,
      horloge: () => _maintenant,
    );
  }

  late final ClassesAdminDemo classesDemo;
  late final FusionDemo fusion;

  ClasseListee classe(int n) =>
      classesDemo.toutes().firstWhere((ClasseListee c) => c.id == _id(n));
}

Future<void> _monter(
  WidgetTester tester,
  _Banc banc,
  Widget Function(_Banc banc) feuille, {
  Size taille = const Size(390, 6000),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  bool horsLigneReseau = false,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portFusionClassesProvider.overrideWithValue(banc.fusion),
        portClassesAdminProvider.overrideWithValue(banc.classesDemo),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigneReseau),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext context, Widget? enfant) => Directionality(
            textDirection: direction,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: enfant!,
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: feuille(banc),
            ),
          ),
        ),
      ),
    ),
  );
  await _laisser(tester);
}

Future<void> _laisser(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

Future<void> _toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await _laisser(tester);
}

Finder _bouton(String cle) =>
    find.descendant(of: _cle(cle), matching: find.byType(ActionPrincipale));

void main() {
  group('Le port de demonstration', () {
    test('cibles de fusion : meme famille, assez de place pour tous', () async {
      final _Banc banc = _Banc();
      final List<ClasseCible> cibles = await banc.fusion.classesCibles(_id(12));
      expect(cibles, isNotEmpty);
      expect(cibles.every((ClasseCible c) => c.places >= 2), isTrue);
      expect(cibles.any((ClasseCible c) => c.classeId == _id(12)), isFalse);
      // Toutes portent un numero distinct (R16).
      expect(
        cibles.map((ClasseCible c) => c.nom).toSet(),
        hasLength(cibles.length),
      );
      // Pour un seul eleve, plus de classes conviennent.
      final List<ClasseCible> pourUn = await banc.fusion.classesCibles(
        _id(12),
        eleves: 1,
      );
      expect(pourUn.length, greaterThan(cibles.length));
    });

    test(
      'apercu : eleves deplaces, effectif apres, enseignant libere',
      () async {
        final _Banc banc = _Banc();
        final ApercuFusion a = await banc.fusion.apercu(
          sourceId: _id(12),
          cibleId: _id(3),
        );
        expect(a.membresDeplaces, 2);
        expect(a.membresApres, a.cible.membres + 2);
        expect(a.enseignantLibere, isNotNull);
        expect(a.famillesNotifiees, inInclusiveRange(1, 2));
      },
    );

    test('fusion : atomique, la source est close, l effectif suit', () async {
      final _Banc banc = _Banc();
      final int avant = banc.classe(3).groupe.nombreMembres;
      final ResultatFusion r = await banc.fusion.fusionner(
        sourceId: _id(12),
        cibleId: _id(3),
        cleEnvoi: 'k1',
      );
      expect(r, isA<FusionFaite>());
      expect((r as FusionFaite).elevesDeplaces, 2);
      expect(banc.classe(12).groupe.actif, isFalse);
      expect(banc.classe(12).groupe.nombreMembres, 0);
      expect(banc.classe(3).groupe.nombreMembres, avant + 2);
      expect(banc.fusion.membresDe(_id(3)), hasLength(avant + 2));
    });

    test('la meme cle rend la meme reponse ; une autre fusion de la meme '
        'source est « deja faite »', () async {
      final _Banc banc = _Banc();
      await banc.fusion.fusionner(
        sourceId: _id(12),
        cibleId: _id(3),
        cleEnvoi: 'k1',
      );
      final ResultatFusion rejeu = await banc.fusion.fusionner(
        sourceId: _id(12),
        cibleId: _id(3),
        cleEnvoi: 'k1',
      );
      expect(rejeu, isA<FusionFaite>());
      expect(banc.fusion.fusionsFaites, 1);
      final ResultatFusion autre = await banc.fusion.fusionner(
        sourceId: _id(12),
        cibleId: _id(6),
        cleEnvoi: 'k2',
      );
      expect(autre, isA<FusionDejaFaite>());
      expect(banc.fusion.fusionsFaites, 1);
    });

    test(
      'transfert : refus R5 (chevauchement), refus classe pleine, fait',
      () async {
        final _Banc banc = _Banc();
        // L'eleve n° 4 suit un autre cours au meme moment (simule).
        final ResultatTransfert chevauche = await banc.fusion.transferer(
          eleveId: '${_id(4)}-e3',
          sourceId: _id(4),
          cibleId: _id(6),
          cleEnvoi: 'a',
        );
        expect(
          chevauche,
          isA<TransfertRefuse>().having(
            (TransfertRefuse r) => r.raison,
            'raison',
            RaisonRefusTransfert.chevauchement,
          ),
        );
        // n° 5 est pleine (5 sur 5).
        final ResultatTransfert pleine = await banc.fusion.transferer(
          eleveId: '${_id(4)}-e0',
          sourceId: _id(4),
          cibleId: _id(5),
          cleEnvoi: 'b',
        );
        expect(
          pleine,
          isA<TransfertRefuse>().having(
            (TransfertRefuse r) => r.raison,
            'raison',
            RaisonRefusTransfert.classePleine,
          ),
        );
        final ResultatTransfert fait = await banc.fusion.transferer(
          eleveId: '${_id(4)}-e0',
          sourceId: _id(4),
          cibleId: _id(11),
          cleEnvoi: 'c',
        );
        expect(fait, isA<TransfertFait>());
        expect(banc.fusion.transfertsFaits, 1);
        expect(banc.classe(11).groupe.nombreMembres, 2);
        expect(banc.classe(4).groupe.nombreMembres, 3);
      },
    );

    test('historique : la fusion et le transfert, des deux cotes, le plus '
        'recent d abord', () async {
      final _Banc banc = _Banc();
      await banc.fusion.transferer(
        eleveId: '${_id(3)}-e0',
        sourceId: _id(3),
        cibleId: _id(11),
        cleEnvoi: 'c',
      );
      await banc.fusion.fusionner(
        sourceId: _id(12),
        cibleId: _id(11),
        cleEnvoi: 'f',
      );
      final List<EvenementClasse> cible = await banc.fusion.historique(_id(11));
      expect(
        cible.map((EvenementClasse e) => e.type).toList(),
        <TypeEvenementClasse>[
          TypeEvenementClasse.fusionEntrante,
          TypeEvenementClasse.transfertEntrant,
        ],
      );
      final List<EvenementClasse> source = await banc.fusion.historique(
        _id(12),
      );
      expect(source.single.type, TypeEvenementClasse.fusionSortante);
      expect(source.single.nombre, 2);
      expect(libelleQuand(source.single.quand), '10/10/2026 à 18:05');
    });
  });

  group('Feuille de fusion', () {
    testWidgets('choisir la classe, lire l apercu, confirmer', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(
        tester,
        banc,
        (_Banc b) => FeuilleFusion(classe: b.classe(12)),
      );
      expect(_cle('fusion-feuille'), findsOneWidget);
      // Aucun apercu avant le choix.
      expect(_cle('fusion-apercu-membres'), findsNothing);
      await _toucher(tester, _cle('fusion-cible-${_id(3)}'));
      expect(_cle('fusion-apercu-membres'), findsOneWidget);
      final ClasseListee cible = banc.classe(3);
      expect(
        find.text(t.admin.fusion.apercuMembres(n: 2, cible: cible.nom)),
        findsOneWidget,
      );
      expect(
        find.text(
          t.admin.fusion.apercuEffectif(
            cible: cible.nom,
            apres: '${cible.groupe.nombreMembres + 2}',
            capacite: '5',
          ),
        ),
        findsOneWidget,
      );
      expect(_cle('fusion-apercu-enseignant'), findsOneWidget);
      expect(find.text(t.admin.fusion.apercuIrreversible), findsOneWidget);

      await _toucher(tester, _bouton('fusion-confirmer'));
      expect(banc.fusion.fusionsFaites, 1);
      expect(_cle('fusion-faite'), findsOneWidget);
      expect(find.text(t.admin.fusion.famillesPrevenues), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sans choix : « Il manque la classe », rien n est envoye', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(
        tester,
        banc,
        (_Banc b) => FeuilleFusion(classe: b.classe(12)),
      );
      await _toucher(tester, _bouton('fusion-confirmer'));
      expect(find.text(t.admin.fusion.manqueCible), findsOneWidget);
      expect(banc.fusion.ecrituresRecues, 0);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('double appui : une seule fusion', (WidgetTester tester) async {
      final _Banc banc = _Banc();
      await _monter(
        tester,
        banc,
        (_Banc b) => FeuilleFusion(classe: b.classe(12)),
      );
      await _toucher(tester, _cle('fusion-cible-${_id(3)}'));
      final Finder bouton = _bouton('fusion-confirmer');
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.tap(bouton, warnIfMissed: false);
      await _laisser(tester);
      expect(banc.fusion.fusionsFaites, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reponse perdue : « non confirmee », la meme cle est reprise', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(
        tester,
        banc,
        (_Banc b) => FeuilleFusion(classe: b.classe(12)),
      );
      await _toucher(tester, _cle('fusion-cible-${_id(3)}'));
      banc.fusion.ecritureEnPanne = true;
      await _toucher(tester, _bouton('fusion-confirmer'));
      expect(find.text(t.admin.fusion.fusionNonConfirmee), findsOneWidget);
      expect(banc.fusion.fusionsFaites, 0);
      banc.fusion.ecritureEnPanne = false;
      await _toucher(tester, _bouton('fusion-confirmer'));
      expect(banc.fusion.fusionsFaites, 1);
      expect(banc.fusion.clesRecues, hasLength(2));
      expect(banc.fusion.clesRecues.toSet(), hasLength(1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('aucune classe parallele avec assez de place : etat vide', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(classes: <ClasseListee>[familleDemo()[11]]);
      await _monter(
        tester,
        banc,
        (_Banc b) => FeuilleFusion(classe: b.classe(12)),
      );
      expect(_cle('fusion-aucune-cible'), findsOneWidget);
      expect(_cle('fusion-confirmer'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('lecture en echec : erreur et « Reessayer » ; hors ligne : '
        'le bloc dit ce qui manque', (WidgetTester tester) async {
      final _Banc banc = _Banc();
      banc.fusion.horsLigne = true;
      await _monter(
        tester,
        banc,
        (_Banc b) => FeuilleFusion(classe: b.classe(12)),
      );
      expect(_cle('fusion-cibles-erreur'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await _monter(
        tester,
        banc,
        (_Banc b) => FeuilleFusion(classe: b.classe(12)),
        horsLigneReseau: true,
      );
      expect(_cle('fusion-cibles-sans-donnees'), findsOneWidget);
      expect(find.textContaining('hors ligne'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('chargement : un squelette, aucun choix', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      final FusionDemo lent = FusionDemo(
        classes: banc.classesDemo.toutesBrutes,
        latence: const Duration(seconds: 5),
      );
      tester.view.physicalSize = const Size(390, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            portFusionClassesProvider.overrideWithValue(lent),
            horsLigneProvider.overrideWith(
              (Ref _) => Stream<bool>.value(false),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              home: Scaffold(body: FeuilleFusion(classe: banc.classe(12))),
            ),
          ),
        ),
      );
      await _laisser(tester);
      expect(_cle('fusion-cible'), findsNothing);
      expect(_cle('fusion-aucune-cible'), findsNothing);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Feuille de transfert', () {
    testWidgets('chevauchement : refus en clair, puis un autre eleve passe', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(
        tester,
        banc,
        (_Banc b) => FeuilleTransfert(classe: b.classe(4)),
      );
      await _toucher(tester, _cle('transfert-eleve-${_id(4)}-e3'));
      await _toucher(tester, _cle('transfert-cible-${_id(11)}'));
      await _toucher(tester, _bouton('transfert-confirmer'));
      expect(
        find.text(
          t.admin.fusion.refusChevauchement(
            prenom: prenomDemo(3),
            cible: banc.classe(11).nom,
          ),
        ),
        findsOneWidget,
      );
      expect(banc.fusion.transfertsFaits, 0);

      await _toucher(tester, _cle('transfert-eleve-${_id(4)}-e0'));
      await _toucher(tester, _bouton('transfert-confirmer'));
      expect(banc.fusion.transfertsFaits, 1);
      expect(_cle('transfert-fait'), findsOneWidget);
      expect(
        find.text(
          t.admin.fusion.transfertFait(
            prenom: prenomDemo(0),
            cible: banc.classe(11).nom,
          ),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sans eleve ni classe choisis : « Il manque l eleve »', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(
        tester,
        banc,
        (_Banc b) => FeuilleTransfert(classe: b.classe(4)),
      );
      await _toucher(tester, _bouton('transfert-confirmer'));
      expect(find.text(t.admin.fusion.manqueEleve), findsOneWidget);
      await _toucher(tester, _cle('transfert-eleve-${_id(4)}-e0'));
      await _toucher(tester, _bouton('transfert-confirmer'));
      expect(find.text(t.admin.fusion.manqueCible), findsOneWidget);
      expect(banc.fusion.ecrituresRecues, 0);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('classe sans eleve : etat vide', (WidgetTester tester) async {
      final _Banc banc = _Banc();
      await banc.fusion.fusionner(
        sourceId: _id(12),
        cibleId: _id(3),
        cleEnvoi: 'f',
      );
      await _monter(
        tester,
        banc,
        (_Banc b) => FeuilleTransfert(classe: b.classe(12)),
      );
      expect(_cle('transfert-aucun-eleve'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Historique', () {
    testWidgets('la fusion et sa date, lisibles', (WidgetTester tester) async {
      final _Banc banc = _Banc();
      await banc.fusion.fusionner(
        sourceId: _id(12),
        cibleId: _id(3),
        cleEnvoi: 'f',
      );
      await _monter(
        tester,
        banc,
        (_Banc b) => HistoriqueClasse(classe: b.classe(3)),
      );
      expect(_cle('historique-liste'), findsOneWidget);
      expect(
        find.text(
          t.admin.fusion.evenementFusionEntrante(
            n: 2,
            autre: banc.classe(12).nom,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('10/10/2026 à 18:05'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('vide : aucun mouvement', (WidgetTester tester) async {
      final _Banc banc = _Banc();
      await _monter(
        tester,
        banc,
        (_Banc b) => HistoriqueClasse(classe: b.classe(3)),
      );
      expect(_cle('historique-vide'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('320 px, texte a 200 %', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('fusion, apercu compris (${direction.name})', (
        WidgetTester tester,
      ) async {
        final _Banc banc = _Banc();
        await _monter(
          tester,
          banc,
          (_Banc b) => FeuilleFusion(classe: b.classe(12)),
          taille: const Size(320, 4000),
          echelle: 2,
          direction: direction,
        );
        await _toucher(tester, _cle('fusion-cible-${_id(3)}'));
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        await tester.pumpWidget(const SizedBox());
      });
      testWidgets('transfert avec refus (${direction.name})', (
        WidgetTester tester,
      ) async {
        final _Banc banc = _Banc();
        await _monter(
          tester,
          banc,
          (_Banc b) => FeuilleTransfert(classe: b.classe(4)),
          taille: const Size(320, 4000),
          echelle: 2,
          direction: direction,
        );
        await _toucher(tester, _cle('transfert-eleve-${_id(4)}-e3'));
        await _toucher(tester, _cle('transfert-cible-${_id(11)}'));
        await _toucher(tester, _bouton('transfert-confirmer'));
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        await tester.pumpWidget(const SizedBox());
      });
      testWidgets('historique (${direction.name})', (
        WidgetTester tester,
      ) async {
        final _Banc banc = _Banc();
        await banc.fusion.fusionner(
          sourceId: _id(12),
          cibleId: _id(3),
          cleEnvoi: 'f',
        );
        await _monter(
          tester,
          banc,
          (_Banc b) => HistoriqueClasse(classe: b.classe(3)),
          taille: const Size(320, 4000),
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('Capacites : une action n existe que si le serveur l ouvre', () {
    Future<void> monterPage(WidgetTester tester, _Banc banc) async {
      tester.view.physicalSize = const Size(1440, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            portFusionClassesProvider.overrideWithValue(banc.fusion),
            portClassesAdminProvider.overrideWithValue(banc.classesDemo),
            horsLigneProvider.overrideWith(
              (Ref _) => Stream<bool>.value(false),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp(
              theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: const GroupesPage(),
            ),
          ),
        ),
      );
      await _laisser(tester);
    }

    testWidgets('capacites ouvertes : fusion, transfert, historique au menu', (
      WidgetTester tester,
    ) async {
      await monterPage(tester, _Banc());
      await tester.tap(find.byTooltip(RegExp('Garçons débutants')).first);
      await tester.pumpAndSettle();
      expect(find.text(t.admin.fusion.actionFusionner), findsOneWidget);
      expect(find.text(t.admin.fusion.actionTransferer), findsOneWidget);
      expect(find.text(t.admin.fusion.actionHistorique), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('capacites fermees : aucune de ces actions', (
      WidgetTester tester,
    ) async {
      final List<ClasseListee> fermees = <ClasseListee>[
        for (final ClasseListee c in familleDemo())
          ClasseListee(
            groupe: c.groupe,
            numeroDansFamille: c.numeroDansFamille,
            genre: c.genre,
            sansEnseignant: c.sansEnseignant,
          ),
      ];
      await monterPage(tester, _Banc(classes: fermees));
      await tester.tap(find.byTooltip(RegExp('Garçons débutants')).first);
      await tester.pumpAndSettle();
      expect(find.text(t.admin.fusion.actionFusionner), findsNothing);
      expect(find.text(t.admin.fusion.actionTransferer), findsNothing);
      expect(find.text(t.admin.fusion.actionHistorique), findsNothing);
      expect(find.text(t.admin.groupes.actionAjouter), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
