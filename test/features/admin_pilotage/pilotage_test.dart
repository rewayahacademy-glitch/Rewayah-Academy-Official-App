// ECHELLE-ADM-PILOTAGE-1 : le tableau de pilotage par horaire, la penurie
// d'enseignants et l'offre contre la demande (R7, R9, R17, R19,
// DECISION-CLASSES-SIMULTANEES-2026-10-10).
//
// Ce que le test prouve :
// - le tableau se calcule de la demonstration a 30 classes paralleles sur la
//   meme cle et 10 000 demandes : classes, remplissage, demandes en attente,
//   enseignants libres et manquants par genre, classes sous le minimum ;
// - les horaires en penurie viennent d'abord ; la liste est paginee par le
//   port (25 par page, une page a la fois) et filtrable (signal, public,
//   jour, heure, fuseau) ;
// - les classes en attente d'enseignant sont mises en avant, avec l'action
//   « Choisir l'enseignant » ; apres confirmation elles n'attendent plus ;
// - les 5 etats : chargement, contenu, vide, erreur, hors ligne (et port
//   absent) ;
// - 320 px, texte a 200 %, RTL.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/port_classes_admin.dart';
import 'package:rewayah_academy/core/admin/port_pilotage.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/port_regroupements_admin.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/tc_groupe/libelles_tc_groupe.dart'
    show LibellesGroupe;
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/features/admin_pilotage/pilotage_libelles.dart';
import 'package:rewayah_academy/features/admin_pilotage/pilotage_page.dart';
import 'package:rewayah_academy/features/demo/classes_admin_demo.dart';
import 'package:rewayah_academy/features/demo/pilotage_demo.dart';
import 'package:rewayah_academy/features/demo/regroupements_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart' show verifierUnSeulBoutonPlein;

const String _paris = 'Europe/Paris';

/// Un enseignant et une enseignante, dont les creneaux libres ne sont pas
/// rendus : l'un ou l'autre est choisissable selon le genre de la classe.
class _Enseignants implements PortEnseignantsClasse {
  @override
  Future<List<EnseignantPropose>> pourClasse({
    required TypePublicGroupe public,
  }) async => const <EnseignantPropose>[
    EnseignantPropose(
      id: 'ens-yusuf',
      libelle: 'Yusuf Exemple',
      identifiant: 'TEACHER-YE-000001',
      genre: GenreEnseignant.homme,
      classesActives: 0,
      creneauxLibres: <Creneau>[Creneau(jour: 1, heure: 18, fuseau: _paris)],
      fuseauIana: _paris,
    ),
    EnseignantPropose(
      id: 'ens-maryam',
      libelle: 'Maryam Fictive',
      identifiant: 'TEACHER-MF-000002',
      genre: GenreEnseignant.femme,
      classesActives: 0,
    ),
  ];
}

class _Banc {
  _Banc({
    List<ClasseListee>? classes,
    List<RegroupementDemandes>? demandes,
    Duration latence = Duration.zero,
  }) {
    regroupements = RegroupementsDemo(
      depart: demandes ?? regroupementsVolumeDemo(),
    );
    classesDemo = ClassesAdminDemo(
      classes: classes ?? <ClasseListee>[...familleDemo(), ...volumeDemo()],
      enseignantAffecte: (String id) => regroupements.enseignantDe[id],
    );
    pilotage = PilotageDemo(
      classes: classesDemo.toutes,
      regroupements: regroupements.regroupements,
      latence: latence,
    );
  }

  late final RegroupementsDemo regroupements;
  late final ClassesAdminDemo classesDemo;
  late final PilotageDemo pilotage;
}

Future<void> _monter(
  WidgetTester tester,
  _Banc? banc, {
  Size taille = const Size(1440, 6000),
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
  bool horsLigne = false,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        if (banc != null) ...<Override>[
          portPilotageProvider.overrideWithValue(banc.pilotage),
          portClassesAdminProvider.overrideWithValue(banc.classesDemo),
          portRegroupementsAdminProvider.overrideWithValue(banc.regroupements),
        ],
        portEnseignantsClasseProvider.overrideWithValue(_Enseignants()),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
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
          home: const PilotagePage(),
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

void main() {
  final List<ClasseListee> classes = <ClasseListee>[
    ...familleDemo(),
    ...volumeDemo(),
  ];
  final List<RegroupementDemandes> demandes = regroupementsVolumeDemo();
  final List<LignePilotage> lignes = lignesPilotageDemo(
    classes: classes,
    regroupements: demandes,
  );

  group('Le calcul de la demonstration', () {
    test('la famille de 30 classes : lundi 18 h, Paris, enfants', () {
      final LignePilotage ligne = lignes.firstWhere(
        (LignePilotage l) =>
            l.creneau.jour == 1 &&
            l.creneau.heure == 18 &&
            l.creneau.fuseau == _paris &&
            l.type == TypePublicGroupe.enfant,
      );
      expect(ligne.classes, greaterThanOrEqualTo(30));
      expect(ligne.classesAttenteEnseignant, greaterThanOrEqualTo(3));
      expect(ligne.capacite, ligne.classes * 5);
      expect(ligne.tauxRemplissage, isNotNull);
      expect(ligne.aSignaler, isTrue);
    });

    test('les 10 000 demandes se retrouvent dans le tableau', () {
      expect(
        lignes.fold<int>(
          0,
          (int n, LignePilotage l) => n + l.demandesEnAttente,
        ),
        elevesVolumeDemo,
      );
    });

    test('les enseignants manquants se disent par genre', () {
      final LignePilotage enPenurie = lignes.firstWhere(
        (LignePilotage l) => l.penurie,
      );
      expect(
        enPenurie.enseignantsManquants,
        enPenurie.parGenre.fold<int>(
          0,
          (int n, EnseignantsGenre g) => n + g.manquants,
        ),
      );
      expect(
        libelleCompteParGenre(const <EnseignantsGenre>[
          EnseignantsGenre(genre: GenreClasse.femmes, libres: 2, manquants: 0),
          EnseignantsGenre(genre: GenreClasse.hommes, libres: 1, manquants: 0),
        ], (EnseignantsGenre g) => g.libres),
        '3 (2 enseignantes, 1 enseignant)',
      );
      expect(
        libelleCompteParGenre(const <EnseignantsGenre>[
          EnseignantsGenre(genre: GenreClasse.hommes, libres: 0, manquants: 0),
        ], (EnseignantsGenre g) => g.manquants),
        'Aucun',
      );
    });

    test('le taux de remplissage vient de l effectif et du plafond', () {
      const LignePilotage l = LignePilotage(
        id: 'x',
        creneau: Creneau(jour: 1, heure: 18, fuseau: _paris),
        type: TypePublicGroupe.enfant,
        classes: 2,
        effectif: 8,
        capacite: 10,
      );
      expect(l.tauxRemplissage, 80);
      // DUREE-INSECABLE : le libelle ne se coupe pas entre le chiffre et l'unite.
      expect(
        libelleRemplissage(l),
        LibellesGroupe.insecable('80 % (8 sur 10)'),
      );
      expect(
        libelleRemplissage(
          const LignePilotage(
            id: 'y',
            creneau: Creneau(jour: 1, heure: 18, fuseau: _paris),
            type: TypePublicGroupe.enfant,
            classes: 0,
            effectif: 0,
            capacite: 0,
          ),
        ),
        t.admin.pilotage.remplissageInconnu,
      );
    });

    test('pagination : les penuries d abord, aucune ligne perdue', () {
      final PagePilotage premiere = paginerPilotage(
        lignes,
        const FiltrePilotage(),
        page: 1,
        taille: 25,
      );
      expect(premiere.lignes, hasLength(25));
      expect(premiere.lignes.first.penurie, isTrue);
      final Set<String> ids = <String>{};
      for (int p = 1; p <= premiere.pages; p++) {
        ids.addAll(
          paginerPilotage(
            lignes,
            const FiltrePilotage(),
            page: p,
            taille: 25,
          ).lignes.map((LignePilotage l) => l.id),
        );
      }
      expect(ids, hasLength(lignes.length));
    });

    test('filtres : signal, public, jour, heure, fuseau', () {
      PagePilotage page(FiltrePilotage f) =>
          paginerPilotage(lignes, f, page: 1, taille: 1000);
      expect(
        page(const FiltrePilotage(signal: SignalPilotage.penurie)).lignes
            .every((LignePilotage l) => l.penurie),
        isTrue,
      );
      expect(
        page(const FiltrePilotage(signal: SignalPilotage.sousMinimum)).lignes
            .every((LignePilotage l) => l.classesSousMinimum > 0),
        isTrue,
      );
      expect(
        page(const FiltrePilotage(type: TypePublicGroupe.adulte)).lignes
            .every((LignePilotage l) => l.type == TypePublicGroupe.adulte),
        isTrue,
      );
      expect(
        page(const FiltrePilotage(jour: 2)).lignes
            .every((LignePilotage l) => l.creneau.jour == 2),
        isTrue,
      );
      expect(
        page(const FiltrePilotage(heure: 10)).lignes
            .every((LignePilotage l) => l.creneau.heure == 10),
        isTrue,
      );
      expect(
        page(const FiltrePilotage(fuseau: 'America/Toronto')).lignes
            .every((LignePilotage l) => l.creneau.fuseau == 'America/Toronto'),
        isTrue,
      );
      // Le resume suit le jeu filtre.
      final PagePilotage tout = page(const FiltrePilotage());
      expect(
        tout.resume.enseignantsManquants,
        lignes.fold<int>(
          0,
          (int n, LignePilotage l) => n + l.enseignantsManquants,
        ),
      );
    });
  });

  group('Ecran', () {
    testWidgets('contenu : vue d ensemble, classes en attente, horaires '
        'pagines', (WidgetTester tester) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc);
      expect(_cle('pilotage-ensemble'), findsOneWidget);
      expect(_cle('pilotage-attente'), findsOneWidget);
      // R7 : les classes en attente sont mises en avant (5 premieres).
      expect(
        find
            .byWidgetPredicate(
              (Widget w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(
                    'pilotage-classe-',
                  ),
            )
            .evaluate()
            .length,
        classesEnAvant,
      );
      expect(_cle('pilotage-voir-toutes'), findsOneWidget);
      // R17 : une page de 25 lignes, une requete.
      expect(banc.pilotage.pagesDemandees, 1);
      final int pages = (lignes.length / 25).ceil();
      expect(
        find.text(t.commun.formats.pageSur(page: '1', total: '$pages')),
        findsOneWidget,
      );
      expect(
        find.text(
          t.admin.pilotage.resume(
            debut: '1',
            fin: '25',
            total: '${lignes.length}',
          ),
        ),
        findsOneWidget,
      );
      // K-56 : un seul bouton plein.
      verifierUnSeulBoutonPlein(tester, maximum: 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('page suivante : une seule page de plus lue', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc);
      final Finder suivante = _cle('nav-suivant');
      await tester.ensureVisible(suivante.first);
      await tester.tap(suivante.first);
      await _laisser(tester);
      expect(banc.pilotage.pagesDemandees, 2);
      expect(
        find.text(
          t.admin.pilotage.resume(
            debut: '26',
            fin: '50',
            total: '${lignes.length}',
          ),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('filtre « Penurie » : revient a la page 1, ne garde que les '
        'penuries', (WidgetTester tester) async {
      final _Banc banc = _Banc();
      await _monter(tester, banc);
      final Finder penurie = _cle('pilotage-filtre-penurie');
      await tester.ensureVisible(penurie);
      await tester.tap(penurie);
      await _laisser(tester);
      final int attendues = lignes.where((LignePilotage l) => l.penurie).length;
      expect(
        find.text(
          t.admin.pilotage.resume(
            debut: '1',
            fin: '${attendues < 25 ? attendues : 25}',
            total: '$attendues',
          ),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('vide : aucun horaire a piloter', (WidgetTester tester) async {
      final _Banc banc = _Banc(
        classes: const <ClasseListee>[],
        demandes: const <RegroupementDemandes>[],
      );
      await _monter(tester, banc);
      expect(_cle('pilotage-vide'), findsOneWidget);
      expect(_cle('pilotage-attente'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('chargement : un squelette, pas de contenu', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc(latence: const Duration(seconds: 5));
      tester.view.physicalSize = const Size(1440, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _monter(tester, banc);
      expect(_cle('pilotage-liste'), findsNothing);
      expect(_cle('pilotage-vide'), findsNothing);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('erreur : un message et « Reessayer »', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      banc.pilotage.horsLigne = true;
      await _monter(tester, banc);
      expect(_cle('pilotage-erreur'), findsOneWidget);
      expect(find.text(t.admin.pilotage.erreur), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('hors ligne, sans donnees : le bloc dit ce qui manque', (
      WidgetTester tester,
    ) async {
      final _Banc banc = _Banc();
      banc.pilotage.horsLigne = true;
      await _monter(tester, banc, horsLigne: true);
      expect(_cle('pilotage-sans-donnees'), findsOneWidget);
      expect(find.text(t.admin.pilotage.sansDonnees), findsOneWidget);
      // EA-HL-DOUBLE-1 : le bloc ne dit jamais « hors ligne ».
      expect(find.textContaining('hors ligne'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('port absent : « disponible au branchement serveur »', (
      WidgetTester tester,
    ) async {
      await _monter(tester, null);
      expect(_cle('pilotage-indisponible'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('« Choisir l enseignant » : la classe n attend plus apres la '
        'confirmation', (WidgetTester tester) async {
      // La famille de 30 classes de garcons, le lundi a 18 h a Paris : trois
      // attendent leur enseignant, que l'enseignant libre ce jour-la couvre.
      final _Banc banc = _Banc(classes: familleDemo());
      await _monter(tester, banc);
      final int avant = banc.classesDemo
          .toutes()
          .where((ClasseListee c) => c.sansEnseignant)
          .length;
      final ClasseListee premiere = banc.classesDemo
          .toutes()
          .where((ClasseListee c) => c.sansEnseignant)
          .toList()
          .firstWhere(
            (ClasseListee c) =>
                _cle('pilotage-affecter-${c.id}').evaluate().isNotEmpty,
          );
      final Finder action = _cle('pilotage-affecter-${premiere.id}');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await _laisser(tester);
      expect(_cle('regroupement-feuille-enseignant'), findsOneWidget);
      final Finder confirmer = find.descendant(
        of: _cle('regroupement-confirmer'),
        matching: find.byType(ActionPrincipale),
      );
      await tester.ensureVisible(confirmer);
      await tester.tap(confirmer);
      await _laisser(tester);
      expect(banc.regroupements.affectationsRecues, 1);
      expect(banc.regroupements.enseignantDe[premiere.id], 'ens-yusuf');
      final int apres = banc.classesDemo
          .toutes()
          .where((ClasseListee c) => c.sansEnseignant)
          .length;
      expect(apres, avant - 1);
      await tester.pumpWidget(const SizedBox());
    });

    group('320 px, texte a 200 %', () {
      setUpAll(chargerPolicesDuDepot);
      for (final TextDirection direction in TextDirection.values) {
        testWidgets('aucun debordement (${direction.name})', (
          WidgetTester tester,
        ) async {
          await _monter(
            tester,
            _Banc(),
            taille: const Size(320, 2400),
            echelle: 2,
            direction: direction,
          );
          expect(tester.takeException(), isNull);
          verifierEcranSansMotCoupe(tester);
          await tester.pumpWidget(const SizedBox());
        });
      }
    });
  });
}
