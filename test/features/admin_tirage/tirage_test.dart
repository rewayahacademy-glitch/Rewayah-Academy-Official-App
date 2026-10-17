// ECHELLE-CTRL-DIRECT-1, cote direction : les regles du tirage et l'historique
// audite des tirages et des missions non controlees (R18, BR-CT-15,
// DECISION-CLASSES-SIMULTANEES-2026-10-10).
//
// Ce que le test prouve :
// - les regles (frequence, ponderation, cibles) se lisent, se modifient et
//   s'enregistrent par une seule cle d'envoi (double appui : un seul
//   enregistrement ; reponse perdue : meme cle reprise, « non confirme ») ;
// - l'historique est pagine (25) et filtrable par statut, une mission non
//   controlee montre son rapport envoye a l'administration (BR-CT-15) ;
// - l'ecran lit des capacites, jamais un role : sans `peutLire`, ni regles ni
//   historique ; sans `peutModifier`, aucun bouton d'enregistrement ni de
//   cible, une phrase le dit ;
// - les 5 etats (chargement, contenu, vide, erreur, hors ligne) et le port
//   absent ;
// - 320 px, texte a 200 %, RTL.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/controle/port_tirage_controle.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/status_pill.dart';
import 'package:rewayah_academy/features/admin_tirage/tirage_libelles.dart';
import 'package:rewayah_academy/features/admin_tirage/tirage_page.dart';
import 'package:rewayah_academy/features/demo/tirage_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/rangee_plus.dart';

Future<void> _monter(
  WidgetTester tester,
  TirageDemo? port, {
  Size taille = const Size(1440, 8000),
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
        if (port != null) portTirageControleProvider.overrideWithValue(port),
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
          home: const TiragePage(),
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

int _cartes() => find
    .byWidgetPredicate(
      (Widget w) =>
          w.key is ValueKey<String> &&
          RegExp(r'^tirage-tirage-\d+-demo-ctrl-\d$')
              .hasMatch((w.key! as ValueKey<String>).value),
    )
    .evaluate()
    .length;

void main() {
  final List<TirageAudite> historique = historiqueDemo();

  group('L historique simule', () {
    test('douze semaines, trois controleurs, de quoi paginer', () {
      expect(historique, hasLength(36));
      expect(historique.map((TirageAudite t) => t.id).toSet(), hasLength(36));
    });

    test('chaque semaine : trois controleurs, trois classes differentes', () {
      for (int semaine = 0; semaine < 12; semaine++) {
        final List<TirageAudite> lignes = <TirageAudite>[
          for (final TirageAudite t in historique)
            if (t.id.startsWith('tirage-$semaine-')) t,
        ];
        expect(lignes, hasLength(3));
        expect(
          lignes.map((TirageAudite t) => t.classe).toSet(),
          hasLength(3),
          reason: 'deux controleurs sur une classe, semaine $semaine',
        );
      }
    });

    test('pagination et filtre en memoire', () {
      final PageTirages p1 = paginerTirages(
        historique,
        const FiltreTirages(),
        page: 1,
        taille: 25,
      );
      expect(p1.lignes, hasLength(25));
      expect(p1.pages, 2);
      expect(p1.compteurs.values.fold<int>(0, (int a, int b) => a + b), 36);
      final PageTirages non = paginerTirages(
        historique,
        const FiltreTirages(statut: StatutTirage.nonControlee),
        page: 1,
        taille: 25,
      );
      expect(
        non.lignes.every(
          (TirageAudite t) =>
              t.statut == StatutTirage.nonControlee && t.rapportEnvoye,
        ),
        isTrue,
      );
      // Le plus recent d'abord.
      for (int i = 1; i < p1.lignes.length; i++) {
        expect(p1.lignes[i - 1].quand.isBefore(p1.lignes[i].quand), isFalse);
      }
    });
  });

  group('Contenu', () {
    testWidgets('regles lues, historique pagine par 25', (
      WidgetTester tester,
    ) async {
      final TirageDemo port = TirageDemo();
      await _monter(tester, port);
      expect(_cle('tirage-regles'), findsOneWidget);
      expect(_cle('tirage-aucune-cible'), findsOneWidget);
      expect(_cartes(), 25);
      expect(port.pagesDemandees, 1);
      expect(
        find.text(t.admin.tirage.resume(debut: '1', fin: '25', total: '36')),
        findsOneWidget,
      );
      final Finder suivante = _cle('nav-suivant');
      await _toucher(tester, suivante.first);
      expect(_cartes(), 11);
      expect(port.pagesDemandees, 2);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('une mission non controlee : son rapport est parti a '
        'l administration (BR-CT-15)', (WidgetTester tester) async {
      await _monter(tester, TirageDemo());
      await toucherFiltre(tester, _cle('tirage-filtre-nonControlee'));
      await _laisser(tester);
      final int attendues = historique
          .where((TirageAudite t) => t.statut == StatutTirage.nonControlee)
          .length;
      expect(attendues, greaterThan(0));
      expect(_cartes(), attendues);
      expect(find.text(t.admin.tirage.rapportEnvoye), findsNWidgets(attendues));
      // Le statut se dit par un mot, jamais la couleur seule.
      final Iterable<StatusPill> pastilles = tester.widgetList<StatusPill>(
        find.byType(StatusPill),
      );
      expect(
        pastilles.where(
          (StatusPill p) =>
              p.libelle == libelleStatutTirage(StatutTirage.nonControlee),
        ),
        hasLength(attendues),
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('recherche : une seule requete, 300 ms apres la derniere '
        'frappe', (WidgetTester tester) async {
      final TirageDemo port = TirageDemo();
      await _monter(tester, port);
      final int avant = port.pagesDemandees;
      for (final String texte in <String>['C', 'Co', 'Contrôleur 2']) {
        await tester.enterText(_cle('tirage-recherche'), texte);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 199));
      expect(port.pagesDemandees, avant);
      await tester.pump(const Duration(milliseconds: 1));
      await _laisser(tester);
      expect(port.pagesDemandees, avant + 1);
      expect(
        find.text(t.admin.tirage.resume(debut: '1', fin: '12', total: '12')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Les regles', () {
    testWidgets('modifier la frequence puis enregistrer : un double appui '
        'pendant l envoi ne part qu une fois', (WidgetTester tester) async {
      final TirageDemo port = TirageDemo(
        latence: const Duration(milliseconds: 400),
      );
      await _monter(tester, port);
      // Les lectures prennent 400 ms chacune.
      await tester.pump(const Duration(seconds: 2));
      await _toucher(tester, _cle('tirage-frequence-2'));
      final Finder bouton = _bouton('tirage-enregistrer');
      await tester.ensureVisible(bouton);
      await tester.tap(bouton);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(bouton, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 2));
      expect(
        port.clesRecues,
        hasLength(1),
        reason: 'le second appui est retenu',
      );
      expect(port.enregistrementsFaits, 1);
      expect(port.reglesCourantes.missionsParSemaine, 2);
      expect(_cle('tirage-enregistrees'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ponderation : le poids choisi est celui qui part', (
      WidgetTester tester,
    ) async {
      final TirageDemo port = TirageDemo();
      await _monter(tester, port);
      await _toucher(
        tester,
        _cle(
          'tirage-poids-${CriterePonderation.heuresDePointe.name}-'
          '${NiveauPonderation.fort.name}',
        ),
      );
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(
        port.reglesCourantes.poids(CriterePonderation.heuresDePointe),
        NiveauPonderation.fort,
      );
      // Les autres poids ne bougent pas.
      expect(
        port.reglesCourantes.poids(CriterePonderation.classesSignalees),
        NiveauPonderation.fort,
      );
      expect(
        port.reglesCourantes.poids(CriterePonderation.enseignantsRecents),
        NiveauPonderation.normal,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('reponse perdue : « non confirme », la meme cle est reprise', (
      WidgetTester tester,
    ) async {
      final TirageDemo port = TirageDemo();
      await _monter(tester, port);
      await _toucher(tester, _cle('tirage-frequence-3'));
      port.ecritureEnPanne = true;
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(find.text(t.admin.tirage.nonConfirmees), findsOneWidget);
      expect(port.enregistrementsFaits, 0);
      port.ecritureEnPanne = false;
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(port.enregistrementsFaits, 1);
      expect(port.clesRecues, hasLength(2));
      expect(port.clesRecues.toSet(), hasLength(1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ajouter puis retirer une cible', (WidgetTester tester) async {
      final TirageDemo port = TirageDemo();
      await _monter(tester, port);
      await _toucher(tester, _cle('tirage-ajouter-cible'));
      expect(_cle('tirage-feuille-cible'), findsOneWidget);
      // Sans choix : « Il manque la cible », la feuille reste ouverte.
      await _toucher(tester, _bouton('tirage-ajouter-confirmer'));
      expect(find.text(t.admin.tirage.manqueCible), findsOneWidget);
      await _toucher(
        tester,
        _cle('tirage-candidat-${TypeCible.classe.name}-demo-seance-1'),
      );
      await _toucher(tester, _bouton('tirage-ajouter-confirmer'));
      expect(_cle('tirage-feuille-cible'), findsNothing);
      expect(
        _cle('tirage-cible-${TypeCible.classe.name}-demo-seance-1'),
        findsOneWidget,
      );
      expect(_cle('tirage-aucune-cible'), findsNothing);
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(port.reglesCourantes.cibles, hasLength(1));
      // Retirer.
      await _toucher(
        tester,
        _cle('tirage-retirer-${TypeCible.classe.name}-demo-seance-1'),
      );
      expect(_cle('tirage-aucune-cible'), findsOneWidget);
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(port.reglesCourantes.cibles, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Capacites : la capacite decide, jamais un role', () {
    testWidgets('sans peutModifier : lecture seule, aucun bouton, aucune '
        'cible a ajouter', (WidgetTester tester) async {
      await _monter(
        tester,
        TirageDemo(
          acces$: const AccesTirage(peutLire: true, peutModifier: false),
        ),
      );
      expect(_cle('tirage-lecture-seule'), findsOneWidget);
      expect(_cle('tirage-enregistrer'), findsNothing);
      expect(_cle('tirage-ajouter-cible'), findsNothing);
      expect(_cartes(), 25);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sans peutLire : ni regles ni historique, une phrase dit '
        'pourquoi', (WidgetTester tester) async {
      final TirageDemo port = TirageDemo(
        acces$: const AccesTirage(peutLire: false, peutModifier: false),
      );
      await _monter(tester, port);
      expect(_cle('tirage-reserve'), findsOneWidget);
      expect(find.text(t.admin.tirage.reserveTitre), findsOneWidget);
      expect(_cle('tirage-regles'), findsNothing);
      expect(_cle('tirage-historique'), findsNothing);
      expect(port.pagesDemandees, 0, reason: 'aucune lecture sans capacite');
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('TIRAGE-REGLES-1 : le nombre de 0 a 50, les versions', () {
    Future<void> saisirAutre(WidgetTester tester, String texte) async {
      await _toucher(tester, find.text(t.choix.autre));
      final Finder champ = find.descendant(
        of: _cle('tirage-regles'),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(champ.first);
      await tester.enterText(champ.first, texte);
      await _laisser(tester);
    }

    test(
      'lireMissions : chiffres arabo-indiens et persans lus comme ASCII',
      () {
        expect(lireMissions('٣٧'), 37);
        expect(lireMissions('۳۷'), 37);
        expect(lireMissions('٠'), 0);
        expect(lireMissions('٥٠'), 50);
        expect(lireMissions('٥١'), isNull);
        expect(lireMissions('۵۱'), isNull);
        expect(lireMissions('٣a'), isNull);
      },
    );

    testWidgets('« ٣٧ » part comme 37', (WidgetTester tester) async {
      final TirageDemo port = TirageDemo();
      await _monter(tester, port, direction: TextDirection.rtl);
      await saisirAutre(tester, '٣٧');
      expect(_cle('tirage-nombre-invalide'), findsNothing);
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(port.reglesCourantes.missionsParSemaine, 37);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('« ٥١ » refusé : rien ne part', (WidgetTester tester) async {
      final TirageDemo port = TirageDemo();
      await _monter(tester, port, direction: TextDirection.rtl);
      await saisirAutre(tester, '٥١');
      expect(_cle('tirage-nombre-invalide'), findsOneWidget);
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(port.clesRecues, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('lecture : la version en vigueur est dite', (
      WidgetTester tester,
    ) async {
      await _monter(tester, TirageDemo());
      expect(find.text(t.admin.tirage.versionEnVigueur(n: 1)), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('version 0 : aucune regle enregistree, une phrase le dit', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        TirageDemo(
          regles: const ReglesTirage(
            missionsParSemaine: 0,
            ponderations: <CriterePonderation, NiveauPonderation>{},
            cibles: <CibleTirage>[],
          ),
        ),
      );
      expect(find.text(t.admin.tirage.aucuneVersion), findsOneWidget);
      expect(_cle('tirage-zero'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('« Autre » : 37 part tel quel, une nouvelle version naît', (
      WidgetTester tester,
    ) async {
      final TirageDemo port = TirageDemo();
      await _monter(tester, port);
      await saisirAutre(tester, '37');
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(port.reglesCourantes.missionsParSemaine, 37);
      expect(port.reglesCourantes.version, 2);
      expect(
        find.text(t.admin.tirage.enregistreesVersion(n: 2)),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('0 puis 50 sont acceptes, 51 et « abc » ne partent pas', (
      WidgetTester tester,
    ) async {
      final TirageDemo port = TirageDemo();
      await _monter(tester, port);
      await saisirAutre(tester, '51');
      expect(_cle('tirage-nombre-invalide'), findsOneWidget);
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(port.clesRecues, isEmpty, reason: 'rien ne part');
      expect(find.text(t.admin.tirage.nombreInvalide), findsWidgets);
      await saisirAutre(tester, 'abc');
      expect(_cle('tirage-nombre-invalide'), findsOneWidget);
      await saisirAutre(tester, '50');
      expect(_cle('tirage-nombre-invalide'), findsNothing);
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(port.reglesCourantes.missionsParSemaine, 50);
      await _toucher(tester, _cle('tirage-frequence-0'));
      expect(_cle('tirage-zero'), findsOneWidget);
      await _toucher(tester, _bouton('tirage-enregistrer'));
      expect(port.reglesCourantes.missionsParSemaine, 0);
      expect(port.reglesCourantes.version, 3);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('une valeur lue hors des cartes ouvre « Autre » dessus', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        TirageDemo(
          regles: ReglesTirage(
            version: 4,
            missionsParSemaine: 12,
            ponderations: reglesParDefautDemo().ponderations,
            cibles: const <CibleTirage>[],
          ),
        ),
      );
      expect(find.text(t.admin.tirage.versionEnVigueur(n: 4)), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('sans peutModifier (ex. sans MFA) : aucun bouton, aucune '
        'cle ne part', (WidgetTester tester) async {
      final TirageDemo port = TirageDemo(
        acces$: const AccesTirage(peutLire: true, peutModifier: false),
      );
      await _monter(tester, port);
      expect(_cle('tirage-enregistrer'), findsNothing);
      expect(port.clesRecues, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('Les cinq etats', () {
    testWidgets('vide : aucun tirage', (WidgetTester tester) async {
      await _monter(tester, TirageDemo(historique: const <TirageAudite>[]));
      expect(_cle('tirage-vide'), findsOneWidget);
      expect(_cle('tirage-recherche'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('chargement : un squelette', (WidgetTester tester) async {
      await _monter(
        tester,
        TirageDemo(latence: const Duration(milliseconds: 1500)),
      );
      expect(_cle('tirage-regles'), findsNothing);
      expect(_cle('tirage-historique'), findsNothing);
      expect(_cle('tirage-vide'), findsNothing);
      // Les trois lectures (acces, regles, historique) se terminent.
      await tester.pump(const Duration(seconds: 5));
      expect(_cle('tirage-regles'), findsOneWidget);
      // Les delais de perte de reponse des blocs, s'il en reste.
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('erreur : un message et « Reessayer » ; hors ligne : le bloc '
        'dit ce qui manque', (WidgetTester tester) async {
      await _monter(tester, TirageDemo(horsLigne: true));
      expect(_cle('tirage-erreur'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await _monter(tester, TirageDemo(horsLigne: true), horsLigneReseau: true);
      expect(_cle('tirage-sans-donnees'), findsOneWidget);
      expect(find.textContaining('hors ligne'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('port absent : « disponible au branchement serveur »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, null);
      expect(_cle('tirage-indisponible'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('320 px, texte a 200 %', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('regles, historique et feuille (${direction.name})', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          TirageDemo(),
          taille: const Size(320, 4000),
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(
          tester,
          // `ChampRecherche` (composant partage, inchange) garde son
          // etiquette et son aide dans le champ au-dela de 130 %.
          exceptions: <String>{
            t.admin.tirage.rechercheLibelle,
            t.admin.tirage.rechercheAide,
          },
        );
        await _toucher(tester, find.text(t.choix.autre));
        await tester.enterText(
          find
              .descendant(
                of: _cle('tirage-regles'),
                matching: find.byType(TextField),
              )
              .first,
          '99',
        );
        await _laisser(tester);
        expect(_cle('tirage-nombre-invalide'), findsOneWidget);
        verifierEcranSansMotCoupe(
          tester,
          exceptions: <String>{
            t.admin.tirage.rechercheLibelle,
            t.admin.tirage.rechercheAide,
          },
        );
        await _toucher(tester, _cle('tirage-ajouter-cible'));
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(
          tester,
          exceptions: <String>{
            t.admin.tirage.rechercheLibelle,
            t.admin.tirage.rechercheAide,
          },
        );
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
