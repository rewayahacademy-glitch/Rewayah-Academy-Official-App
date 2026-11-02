// ECHELLE-ADM-LISTES-1 : listes a grande echelle, decoupage R3 et classes
// paralleles (DECISION-CLASSES-SIMULTANEES-2026-10-10, R1, R3, R16, R17).
//
// Ce que le test prouve :
// - R3 : « 2 classes de 5, 2 eleves en attente » (12 demandes, maximum 5,
//   minimum 3), dit avant la confirmation, jamais une classe sous le
//   minimum ;
// - R1, R16 : la feuille dit que la classe s'ajoute aux classes deja
//   ouvertes sur la meme cle ;
// - R17 : 10 000 demandes simulees, paginees par le port (25 par page, une
//   page demandee a la fois), filtrees par public, etat, jour, heure et
//   fuseau, recherche posee 300 ms apres la derniere frappe ;
// - R17 : la liste des classes se filtre par remplissage ;
// - 320 px, texte a 200 %, RTL.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_classes_admin.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/page_regroupements.dart';
import 'package:rewayah_academy/core/offres/port_regroupements_admin.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_regroupements/regroupements_libelles.dart';
import 'package:rewayah_academy/features/admin_regroupements/regroupements_page.dart';
import 'package:rewayah_academy/features/demo/regroupements_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;

import '../../support/aucun_mot_coupe.dart';
import '../../support/rangee_plus.dart';

class _SansEnseignants implements PortEnseignantsClasse {
  @override
  Future<List<EnseignantPropose>> pourClasse({
    required TypePublicGroupe public,
  }) async => const <EnseignantPropose>[];
}

RegroupementDemandes _reg(
  String id, {
  int eleves = 5,
  int quota = 5,
  int? minimum,
  int? classesExistantes,
  PublicOffre public = PublicOffre.enfants,
}) => RegroupementDemandes(
  id: id,
  public: public,
  langueCode: 'fr',
  langueNom: 'Français',
  fuseau: 'Europe/Paris',
  occurrences: const <OccurrenceCreneau>[
    OccurrenceCreneau(jourIso: 1, heure: 18),
  ],
  nombreEleves: eleves,
  quota: quota,
  minimum: minimum,
  classesExistantes: classesExistantes,
  peutCreerClasse: true,
);

Future<void> _monter(
  WidgetTester tester,
  RegroupementsDemo port, {
  Size taille = const Size(1440, 6000),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  bool pages = true,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portRegroupementsAdminProvider.overrideWithValue(port),
        if (pages) portRegroupementsPagesProvider.overrideWithValue(port),
        portEnseignantsClasseProvider.overrideWithValue(_SansEnseignants()),
        horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(false)),
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
          home: const RegroupementsPage(),
        ),
      ),
    ),
  );
  await _laisser(tester);
  // L3 : au bureau, recherche et filtres sont en panneau, derriere l'icone.
  final Finder bascule = find.byKey(
    const ValueKey<String>('regroupements-bascule-filtres'),
  );
  if (bascule.evaluate().isNotEmpty) {
    await tester.tap(bascule);
    await _laisser(tester);
  }
}

Future<void> _laisser(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

/// Le nombre de cartes de regroupement a l'ecran.
int _cartes() => find
    .byWidgetPredicate(
      (Widget w) =>
          w.key is ValueKey<String> &&
          RegExp(r'^regroupement-demo-reg-volume-\d+$')
              .hasMatch((w.key! as ValueKey<String>).value),
    )
    .evaluate()
    .length;

void main() {
  group('R3 : le decoupage', () {
    test('12 demandes, maximum 5, minimum 3 : 2 classes, 2 en attente', () {
      final DecoupageClasses d = decouperDemandes(
        demandes: 12,
        maximum: 5,
        minimum: 3,
      );
      expect(d.pleines, 2);
      expect(d.derniere, isNull);
      expect(d.enAttente, 2);
      expect(d.classes, 2);
      expect(libelleDecoupage(d), '2 classes de 5, 2 élèves en attente');
    });

    test('le reste qui atteint le minimum ouvre une derniere classe', () {
      final DecoupageClasses d = decouperDemandes(
        demandes: 14,
        maximum: 5,
        minimum: 3,
      );
      expect(d.classes, 3);
      expect(d.derniere, 4);
      expect(d.enAttente, 0);
      expect(libelleDecoupage(d), '2 classes de 5, une dernière classe de 4');
    });

    test(
      'jamais une classe sous le minimum ; sans minimum le reste attend',
      () {
        expect(
          decouperDemandes(demandes: 7, maximum: 5, minimum: 3).enAttente,
          2,
        );
        expect(decouperDemandes(demandes: 7, maximum: 5).enAttente, 2);
        final DecoupageClasses seul = decouperDemandes(
          demandes: 2,
          maximum: 5,
          minimum: 3,
        );
        expect(seul.classes, 0);
        expect(libelleDecoupage(seul), 'aucune classe, 2 élèves en attente');
        expect(
          libelleDecoupage(decouperDemandes(demandes: 5, maximum: 5)),
          '1 classe de 5',
        );
      },
    );
  });

  // L3 (01/11/2026) : avec le port de pages (la production), la liste se
  // relit apres une creation ; la ligne restait « Prete » jusqu'au
  // rechargement (vu par le robot sur la pile locale).
  testWidgets('port de pages : apres la creation, la ligne attend son '
      'enseignant sans rechargement', (WidgetTester tester) async {
    final RegroupementsDemo port = RegroupementsDemo(
      depart: <RegroupementDemandes>[_reg('r1')],
    );
    await _monter(tester, port);
    expect(
      find.byKey(const ValueKey<String>('regroupement-pret-r1')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('regroupement-action-r1')),
    );
    await _laisser(tester);
    final Finder garcons = find.byKey(
      const ValueKey<String>('regroupement-genre-hommes'),
    );
    await tester.ensureVisible(garcons);
    await tester.tap(garcons);
    await tester.pump();
    final Finder creer = find.descendant(
      of: find.byKey(const ValueKey<String>('regroupement-creer')),
      matching: find.byType(ActionPrincipale),
    );
    await tester.ensureVisible(creer);
    await tester.tap(creer);
    await _laisser(tester);
    expect(port.creationsRecues, 1);
    Navigator.of(
      tester.element(
        find.byKey(const ValueKey<String>('regroupement-feuille-enseignant')),
      ),
    ).pop();
    await _laisser(tester);
    expect(
      find.byKey(const ValueKey<String>('regroupement-a-finir-r1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('regroupement-pret-r1')),
      findsNothing,
    );
  });

  group('R17 : 10 000 demandes simulees, paginees', () {
    final List<RegroupementDemandes> volume = regroupementsVolumeDemo();

    test('le volume simule porte bien 10 000 eleves', () {
      expect(
        volume.fold<int>(
          0,
          (int n, RegroupementDemandes g) => n + g.nombreEleves,
        ),
        elevesVolumeDemo,
      );
      expect(volume.length, greaterThan(500));
    });

    test('chaque regroupement parait sur une seule page, sans trou', () {
      final PageRegroupements premiere = paginerRegroupements(
        volume,
        const FiltreRegroupements(),
        page: 1,
        taille: 25,
      );
      expect(premiere.lignes, hasLength(25));
      expect(premiere.demandesSansFiltre, elevesVolumeDemo);
      final Set<String> ids = <String>{};
      for (int p = 1; p <= premiere.pages; p++) {
        final PageRegroupements page = paginerRegroupements(
          volume,
          const FiltreRegroupements(),
          page: p,
          taille: 25,
        );
        expect(page.lignes.length, lessThanOrEqualTo(25));
        ids.addAll(page.lignes.map((RegroupementDemandes g) => g.id));
      }
      expect(ids, hasLength(volume.length));
    });

    test('filtres : public, etat, jour, heure, fuseau, texte', () {
      PageRegroupements page(FiltreRegroupements f) =>
          paginerRegroupements(volume, f, page: 1, taille: 25);
      final PageRegroupements tout = page(const FiltreRegroupements());
      final PageRegroupements enfants = page(
        const FiltreRegroupements(public: PublicOffre.enfants),
      );
      expect(enfants.total, lessThan(tout.total));
      expect(
        enfants.lignes.every(
          (RegroupementDemandes g) => g.public == PublicOffre.enfants,
        ),
        isTrue,
      );
      final PageRegroupements prets = page(
        const FiltreRegroupements(etat: EtatRegroupement.pret),
      );
      expect(prets.lignes.every((RegroupementDemandes g) => g.pret), isTrue);
      expect(
        prets.total,
        tout.compteurs[EtatRegroupement.pret],
        reason: 'les compteurs suivent les autres axes du filtre',
      );
      expect(
        page(const FiltreRegroupements(jour: 3)).lignes
            .every((RegroupementDemandes g) => g.jours.contains(3)),
        isTrue,
      );
      expect(
        page(const FiltreRegroupements(heure: 10)).lignes.every(
          (RegroupementDemandes g) =>
              g.occurrences.any((OccurrenceCreneau o) => o.heure == 10),
        ),
        isTrue,
      );
      expect(
        page(const FiltreRegroupements(fuseau: 'America/Toronto')).lignes
            .every((RegroupementDemandes g) => g.fuseau == 'America/Toronto'),
        isTrue,
      );
      expect(
        page(const FiltreRegroupements(texte: 'english')).total,
        greaterThan(0),
      );
      expect(page(const FiltreRegroupements(texte: 'zzz')).total, 0);
    });

    test(
      'la classe a creer est dite avant la confirmation (R3 sur le volume)',
      () {
        final RegroupementDemandes g = volume.firstWhere(
          (RegroupementDemandes g) => g.nombreEleves == 23,
        );
        final DecoupageClasses d = g.decoupage;
        expect(
          d.pleines * g.quota + (d.derniere ?? 0) + d.enAttente,
          g.nombreEleves,
          reason: 'aucun eleve perdu ni compte deux fois',
        );
      },
    );

    testWidgets('l ecran lit une page a la fois : 25 cartes, une requete par '
        'page', (WidgetTester tester) async {
      final RegroupementsDemo port = RegroupementsDemo(depart: volume);
      await _monter(tester, port);
      expect(_cartes(), 25);
      expect(port.pagesDemandees, 1);
      final int pages = (volume.length / 25).ceil();
      // L3 : le pied commun dit la tranche, et le nombre de pages en lecture.
      expect(pages, greaterThan(1));
      expect(
        find.text(
          t.commun.listes.tranche(
            debut: '1',
            fin: '25',
            total: '${volume.length}',
          ),
        ),
        findsOneWidget,
      );
      expect(_cle('nav-precedent'), findsNothing);

      final Finder suivante = _cle('nav-suivant');
      await tester.ensureVisible(suivante.first);
      await tester.tap(suivante.first);
      await _laisser(tester);
      expect(port.pagesDemandees, 2, reason: 'une seule page de plus lue');
      expect(
        find.text(
          t.commun.listes.tranche(
            debut: '26',
            fin: '50',
            total: '${volume.length}',
          ),
        ),
        findsOneWidget,
      );
      expect(_cartes(), 25);
    });

    testWidgets('un filtre revient a la page 1 et reduit le total', (
      WidgetTester tester,
    ) async {
      final RegroupementsDemo port = RegroupementsDemo(depart: volume);
      await _monter(tester, port);
      final Finder suivante = _cle('nav-suivant');
      await tester.ensureVisible(suivante.first);
      await tester.tap(suivante.first);
      await _laisser(tester);

      final Finder prets = _cle('regroupements-filtre-prets');
      // L4-07 : selon la place, la puce est dans la rangee ou sous « Plus ».
      await toucherFiltre(tester, prets);
      await _laisser(tester);
      final int nombrePrets = volume
          .where((RegroupementDemandes g) => g.pret)
          .length;
      expect(
        find.text(
          t.commun.listes.tranche(debut: '1', fin: '25', total: '$nombrePrets'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('recherche : une seule requete, 300 ms apres la derniere '
        'frappe', (WidgetTester tester) async {
      final RegroupementsDemo port = RegroupementsDemo(depart: volume);
      await _monter(tester, port);
      final int avant = port.pagesDemandees;
      for (final String texte in <String>['e', 'en', 'eng']) {
        await tester.enterText(_cle('regroupements-recherche'), texte);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 199));
      expect(port.pagesDemandees, avant, reason: 'rien avant 300 ms');
      await tester.pump(const Duration(milliseconds: 1));
      await _laisser(tester);
      expect(port.pagesDemandees, avant + 1, reason: 'une seule requete');
    });

    testWidgets('aucun resultat : un etat vide propre au filtre', (
      WidgetTester tester,
    ) async {
      final RegroupementsDemo port = RegroupementsDemo(depart: volume);
      await _monter(tester, port);
      await tester.enterText(_cle('regroupements-recherche'), 'zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await _laisser(tester);
      expect(_cle('regroupements-aucun-filtre'), findsOneWidget);
      expect(
        find.text(t.admin.regroupements.liste.aucunAvecCeFiltre),
        findsOneWidget,
      );
    });

    testWidgets('sans port de pages : la meme liste, paginee en memoire', (
      WidgetTester tester,
    ) async {
      final RegroupementsDemo port = RegroupementsDemo(depart: volume);
      await _monter(tester, port, pages: false);
      expect(_cartes(), 25);
      expect(port.pagesDemandees, 0);
    });

    group('320 px, texte a 200 %', () {
      setUpAll(chargerPolicesDuDepot);
      for (final TextDirection direction in TextDirection.values) {
        testWidgets(
          'liste a grande echelle sans debordement (${direction.name})',
          (WidgetTester tester) async {
            await _monter(
              tester,
              RegroupementsDemo(depart: volume),
              taille: const Size(320, 2400),
              echelle: 2,
              direction: direction,
            );
            expect(tester.takeException(), isNull);
            verifierEcranSansMotCoupe(
              tester,
              exceptions: <String>{
                t.admin.regroupements.liste.rechercheLibelle,
                t.admin.regroupements.liste.rechercheAide,
              },
            );
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    });
  });

  group('La feuille « Creer la classe » : decoupage et classes existantes', () {
    Future<void> ouvrir(WidgetTester tester, String id) async {
      final Finder action = _cle('regroupement-action-$id');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await _laisser(tester);
    }

    testWidgets('12 demandes : « 2 classes de 5, 2 eleves en attente » avant '
        'de confirmer', (WidgetTester tester) async {
      await _monter(
        tester,
        RegroupementsDemo(
          depart: <RegroupementDemandes>[
            _reg('r', eleves: 12, minimum: 3, classesExistantes: 3),
          ],
        ),
        taille: const Size(390, 4000),
      );
      await ouvrir(tester, 'r');
      expect(
        find.text(
          t.admin.regroupements.decoupage(
            detail: '2 classes de 5, 2 élèves en attente',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(t.admin.regroupements.contexteReparti),
        findsOneWidget,
        reason: 'plus d une classe : les eleves sont repartis',
      );
      // R1, R16 : la classe s'ajoute, aucune n'est ecrasee.
      expect(
        find.text(t.admin.regroupements.classesExistantes(n: 3)),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('une classe : la phrase habituelle, sans classes existantes', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        RegroupementsDemo(depart: <RegroupementDemandes>[_reg('r', eleves: 5)]),
        taille: const Size(390, 4000),
      );
      await ouvrir(tester, 'r');
      expect(
        find.text(t.admin.regroupements.decoupage(detail: '1 classe de 5')),
        findsOneWidget,
      );
      expect(find.text(t.admin.regroupements.contexte(n: 5)), findsOneWidget);
      expect(_cle('regroupement-classes-existantes'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('R17 : le remplissage des classes', () {
    GroupeAdmin groupe(String id, int membres, {int seuil = 5}) => GroupeAdmin(
      id: id,
      libelle: 'Garçons',
      type: TypePublicGroupe.enfant,
      seuilMax: seuil,
      teacherId: 't',
      teacherIdentifiant: 'T-1',
      teacherPrenom: 'Sayyid',
      teacherNom: 'Exemple',
      creneau: const Creneau(jour: 1, heure: 18, fuseau: 'Europe/Paris'),
      nombreMembres: membres,
      actif: true,
    );

    test('pleine : l effectif atteint le plafond ; avec places sinon', () {
      final List<ClasseListee> classes = <ClasseListee>[
        for (int i = 0; i < 40; i++) ClasseListee(groupe: groupe('g$i', i % 7)),
      ];
      PageClasses page(RemplissageClasse? r) => paginerClasses(
        classes,
        FiltreClasses(remplissage: r),
        page: 1,
        taille: 100,
      );
      final PageClasses pleines = page(RemplissageClasse.pleine);
      final PageClasses places = page(RemplissageClasse.avecPlaces);
      expect(pleines.total + places.total, 40);
      expect(
        pleines.lignes.every(
          (ClasseListee c) => c.groupe.nombreMembres >= c.groupe.seuilMax,
        ),
        isTrue,
      );
      expect(
        places.lignes.every(
          (ClasseListee c) => c.groupe.nombreMembres < c.groupe.seuilMax,
        ),
        isTrue,
      );
      expect(page(null).total, 40);
    });
  });
}
