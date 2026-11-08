// RECHERCHE-LIVRAISON (directeur, 08/11/2026) : la recherche est servie en
// production. Avant : `moteursRechercheProvider` vide, aucun domaine servi, la
// loupe et Ctrl/Cmd + K masquees, `/recherche` « indisponible ». Ce fichier
// prouve, sur le VRAI branchement de production (`moteursRechercheProduction`),
// avec des ports qui rendent exactement ce qu'on leur donne :
//
//   1. aucun double de demonstration dans le branchement (controle lexical) ;
//   2. les domaines servis par espace ; le comptable n'en a aucun ;
//   3. une erreur d'un port est une PANNE, jamais un « vide confirme » ;
//   4. sur le vrai routeur : la loupe apparait quand un domaine est servi, un
//      resultat s'ouvre ; un port en echec dit « Impossible d'effectuer la
//      recherche », jamais « Aucun resultat ».
//
// Sans le branchement (la ligne de `lib/main.dart`), les points 2 et 4 sont
// rouges.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/enseignant/modeles_enseignant.dart';
import 'package:rewayah_academy/core/enseignant/port_remplacements.dart';
import 'package:rewayah_academy/core/enseignant/service_enseignant.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/recherche/etat_recherche.dart';
import 'package:rewayah_academy/core/recherche/modeles_recherche.dart';
import 'package:rewayah_academy/core/recherche/port_recherche.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/catalogue_local.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/donnees_catalogue.dart';
import 'package:rewayah_academy/core/tc_bibliotheque/library_resource.dart';
import 'package:rewayah_academy/core/tc_classe/roster_enseignant.dart';
import 'package:rewayah_academy/core/tc_classe/teacher_student_projection.dart';
import 'package:rewayah_academy/core/tc_groupe/demonstration_groupes.dart';
import 'package:rewayah_academy/core/tc_groupe/group_summary_vm.dart';
import 'package:rewayah_academy/core/tc_groupe/port_groupes.dart';
import 'package:rewayah_academy/features/controleur/mission_controle.dart';
import 'package:rewayah_academy/features/recherche/domaines/familles_eleves/port_resolution_ra.dart';
import 'package:rewayah_academy/features/recherche/ecran/ecran_recherche.dart'
    show cleChampRecherche;
import 'package:rewayah_academy/features/recherche/entree_recherche.dart';
import 'package:rewayah_academy/features/recherche/moteurs_production.dart';
import 'package:rewayah_academy/features/recherche/resolveur_cible.dart';

import '../../router/support_routeur.dart';
import '../../support/demo/enseignant_demo.dart' show DonneesEnseignantDemo;
import '../../support/harnais.dart';
import '../../teaching_core/a/faux/faux_groupes.dart';
import '../../teaching_core/b/faux/faux_ports_b.dart' show CatalogueEnEchec;
import '../../teaching_core/fixtures/fixtures_ressources.dart'
    show ressourceCoran;
import '../../teaching_core/h/faux/faux_ports_externes.dart' show FauxRoster;

/// Un port des classes que l'enseignant ne doit jamais lire.
class _GroupesInterdits implements PortGroupes {
  const _GroupesInterdits();

  @override
  Future<List<GroupSummaryVM>> mesGroupes() =>
      throw StateError('PortGroupes lu pour un enseignant');

  @override
  Future<GroupSummaryVM?> groupe(String groupeId) =>
      throw StateError('PortGroupes lu pour un enseignant');
}

/// Une resolution de matricule qui rend ce qu'on lui donne (le serveur).
class _RaFixe implements PortResolutionRa {
  const _RaFixe(this.parRa);

  final Map<String, ElevePourRa> parRa;

  @override
  Future<ElevePourRa?> resoudre(String identifiantExact) async =>
      parRa[identifiantExact];
}

/// Une resolution de matricule en panne.
class _RaEnPanneProd implements PortResolutionRa {
  const _RaEnPanneProd();

  @override
  Future<ElevePourRa?> resoudre(String identifiantExact) =>
      Future<ElevePourRa?>.error(StateError('serveur indisponible'));
}

/// Une mission de controle qui echoue : la panne doit rester une panne.
class _MissionEnEchec implements PortMissionControle {
  @override
  Future<MissionControle?> maMission() =>
      Future<MissionControle?>.error(StateError('lecture refusee'));

  @override
  Future<void> demarrer(String missionId) async {}
}

/// Des offres de remplacement dont la premiere lecture echoue.
class _RemplacementsEnEchec implements PortRemplacements {
  @override
  Stream<List<OffreCommune>> suivre() =>
      Stream<List<OffreCommune>>.error(StateError('lecture refusee'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<List<GroupSummaryVM>> _classes() =>
    GroupesDemonstrationLocale().mesGroupes();

/// Les surcharges de production : le branchement reel + des ports qui rendent
/// ce qu'on leur donne.
Future<List<Override>> _production({
  bool groupesEnEchec = false,
  bool catalogueEnEchec = false,
  bool avecGroupes = true,
  bool avecCatalogue = false,
}) async => <Override>[
  moteursRechercheProvider.overrideWith(moteursRechercheProduction),
  if (avecGroupes)
    portGroupesProvider.overrideWithValue(
      FauxPortGroupes(groupes: await _classes(), echoue: groupesEnEchec),
    ),
  if (catalogueEnEchec)
    portCatalogueProvider.overrideWithValue(CatalogueEnEchec())
  else if (avecCatalogue)
    portCatalogueProvider.overrideWithValue(
      CatalogueLocal(ressources: <LibraryResource>[ressourceCoran]),
    ),
  portRosterEnseignantProvider.overrideWithValue(FauxRoster()),
];

Future<ProviderContainer> _conteneur(List<Override> surcharges) async {
  final ProviderContainer c = ProviderContainer(overrides: surcharges);
  addTearDown(c.dispose);
  return c;
}

Future<GoRouter> _monter(
  WidgetTester tester,
  AppRole role,
  String depart,
  List<Override> surcharges,
) => monterRouteur(
  tester,
  depart,
  source: FausseSourceSession(sessionActive(role)),
  surcharges: surcharges,
);

Future<void> _chercher(WidgetTester tester, String texte) async {
  await tester.enterText(find.byKey(cleChampRecherche), texte);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

/// Le code d'un fichier, commentaires retires.
String _code(String chemin) =>
    File(chemin)
        .readAsLinesSync()
        .where((String l) => !l.trimLeft().startsWith('//'))
        .join('\n');

void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

  group('1. aucun double de demonstration dans le branchement', () {
    test('moteurs_production.dart ne cite aucun port ni moteur de demo', () {
      final String code = _code(
        'lib/features/recherche/moteurs_production.dart',
      );
      final RegExp interdit = RegExp(
        r'Faux\w*|\w*Demonstration\w*|\w*Memoire|\w*Local\b|moteursDemo|corpus|MoteurRechercheDemo|mode_demonstration',
        caseSensitive: false,
      );
      expect(interdit.allMatches(code).map((RegExpMatch m) => m[0]), isEmpty);
      expect(
        code,
        contains('moteursClassesSupports(ref, sourcesReelles: true)'),
      );
      expect(
        code,
        contains(
          'moteursEnseignantsPedagogieControle(ref, sourcesReelles: true)',
        ),
      );
    });

    test('main.dart branche la production, jamais la demo, dans les '
        'surcharges de l\'application reelle', () {
      final String main = File('lib/main.dart').readAsStringSync();
      final int debut = main.indexOf('List<Override> _surchargesAppReelle()');
      expect(debut, greaterThan(0));
      final int ligne = main.indexOf(
        'moteursRechercheProvider.overrideWith(moteursRechercheProduction)',
      );
      expect(ligne, greaterThan(debut), reason: 'le raccord manque');
      expect(main.contains('moteursDemoRecherche'), isFalse);
    });
  });

  group('2. les domaines servis par espace', () {
    test(
      'sans le branchement : rien n\'est servi (l\'etat d\'avant)',
      () async {
        final ProviderContainer c = await _conteneur(const <Override>[]);
        for (final EspaceRecherche espace in EspaceRecherche.values) {
          expect(await c.read(rechercheServieProvider(espace).future), isFalse);
        }
      },
    );

    test('avec le branchement : famille, eleve, eleve guide, enseignant, '
        'direction et comptable (ses fils) sont servis', () async {
      final ProviderContainer c = await _conteneur(await _production());
      for (final EspaceRecherche espace in <EspaceRecherche>[
        EspaceRecherche.famille,
        EspaceRecherche.eleve,
        EspaceRecherche.eleveGuide,
        EspaceRecherche.enseignant,
        // RECH-D2 : la direction resout un matricule exact.
        EspaceRecherche.administration,
        // RECHERCHE D4 : le comptable cherche ses fils « Profil de paiement ».
        EspaceRecherche.comptable,
      ]) {
        expect(
          await c.read(rechercheServieProvider(espace).future),
          isTrue,
          reason: espace.name,
        );
      }
    });

    test('chaque espace ne voit que ses domaines ; le controle n\'est '
        'servi qu\'au controleur ; un domaine interdit est absent', () async {
      final ProviderContainer c = await _conteneur(await _production());
      final PortRecherche port = c.read(portRechercheProvider);
      Future<Set<DomaineRecherche>> servis(EspaceRecherche e) async =>
          (await port.portees(ContexteRecherche(espace: e))).toSet();
      final Set<DomaineRecherche> famille = await servis(
        EspaceRecherche.famille,
      );
      final Set<DomaineRecherche> enseignant = await servis(
        EspaceRecherche.enseignant,
      );
      final Set<DomaineRecherche> controleur = await servis(
        EspaceRecherche.controleur,
      );
      expect(
        famille,
        containsAll(<DomaineRecherche>[
          DomaineRecherche.classes,
          DomaineRecherche.supports,
        ]),
      );
      expect(
        enseignant,
        containsAll(<DomaineRecherche>[
          DomaineRecherche.classes,
          DomaineRecherche.supports,
        ]),
      );
      expect(famille, isNot(contains(DomaineRecherche.controle)));
      expect(enseignant, isNot(contains(DomaineRecherche.controle)));
      expect(controleur, contains(DomaineRecherche.controle));
      expect(controleur, isNot(contains(DomaineRecherche.classes)));
      // D4 : le comptable n'a que ses fils ; ni finance, ni encaissements.
      final Set<DomaineRecherche> comptable = await servis(
        EspaceRecherche.comptable,
      );
      expect(comptable, <DomaineRecherche>{DomaineRecherche.fils});
      expect(comptable, isNot(contains(DomaineRecherche.finances)));
      // Les autres espaces ne gagnent pas de domaine « fils ».
      expect(famille, isNot(contains(DomaineRecherche.fils)));
      expect(enseignant, isNot(contains(DomaineRecherche.fils)));
      expect(
        await servis(EspaceRecherche.administration),
        isNot(contains(DomaineRecherche.fils)),
      );
    });
  });

  group('3. une erreur est une panne, jamais un vide confirme', () {
    test('un resultat est trouve ; une requete sans resultat est un vide '
        'confirme (ReponseOk), distinct d\'une panne', () async {
      final ProviderContainer c = await _conteneur(await _production());
      final PortRecherche port = c.read(portRechercheProvider);
      const ContexteRecherche contexte = ContexteRecherche(
        espace: EspaceRecherche.famille,
      );
      final ReponseDomaine trouve = await port.rechercher(
        domaine: DomaineRecherche.classes,
        requete: 'Fatiha',
        contexte: contexte,
      );
      expect(trouve, isA<ReponseOk>());
      expect((trouve as ReponseOk).elements, isNotEmpty);
      final ReponseDomaine vide = await port.rechercher(
        domaine: DomaineRecherche.classes,
        requete: 'zzzzzz',
        contexte: contexte,
      );
      expect(vide, isA<ReponseOk>());
      expect((vide as ReponseOk).elements, isEmpty);
    });

    test(
      'classes : le port des classes echoue, la reponse est un echec',
      () async {
        final ProviderContainer c = await _conteneur(
          await _production(groupesEnEchec: true),
        );
        final ReponseDomaine r = await c
            .read(portRechercheProvider)
            .rechercher(
              domaine: DomaineRecherche.classes,
              requete: 'Fatiha',
              contexte: const ContexteRecherche(
                espace: EspaceRecherche.famille,
              ),
            );
        expect(r, isA<ReponseEchec>());
        expect((r as ReponseEchec).statut, StatutRecherche.indisponible);
      },
    );

    test('supports : le catalogue echoue, la reponse est un echec', () async {
      final ProviderContainer c = await _conteneur(
        await _production(catalogueEnEchec: true),
      );
      final ReponseDomaine r = await c
          .read(portRechercheProvider)
          .rechercher(
            domaine: DomaineRecherche.supports,
            requete: 'coran',
            contexte: const ContexteRecherche(espace: EspaceRecherche.famille),
          );
      expect(r, isA<ReponseEchec>());
    });

    test(
      'remplacements : la lecture echoue, la reponse est un echec',
      () async {
        final ProviderContainer c = await _conteneur(<Override>[
          ...await _production(),
          portRemplacementsProvider.overrideWithValue(_RemplacementsEnEchec()),
        ]);
        final ReponseDomaine r = await c
            .read(portRechercheProvider)
            .rechercher(
              domaine: DomaineRecherche.remplacements,
              requete: 'classe',
              contexte: const ContexteRecherche(
                espace: EspaceRecherche.enseignant,
              ),
            );
        expect(r, isA<ReponseEchec>());
      },
    );

    test('controle : la lecture de la mission echoue, la reponse est un '
        'echec', () async {
      final ProviderContainer c = await _conteneur(<Override>[
        ...await _production(),
        portMissionControleProvider.overrideWithValue(_MissionEnEchec()),
      ]);
      final ReponseDomaine r = await c
          .read(portRechercheProvider)
          .rechercher(
            domaine: DomaineRecherche.controle,
            requete: 'classe',
            contexte: const ContexteRecherche(
              espace: EspaceRecherche.controleur,
            ),
          );
      expect(r, isA<ReponseEchec>());
    });
  });

  group('4. sur le vrai routeur', () {
    testWidgets('enseignant : la loupe apparait, la recherche trouve un '
        'support et l\'ouvre', (WidgetTester tester) async {
      final GoRouter routeur = await _monter(
        tester,
        AppRole.teacher,
        Routes.enseignantJournee,
        await _production(avecGroupes: false, avecCatalogue: true),
      );
      expect(find.byKey(cleLoupeRecherche), findsOneWidget);
      await tester.tap(find.byKey(cleLoupeRecherche));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        routeur
            .routerDelegate
            .currentConfiguration
            .matches
            .last
            .matchedLocation,
        Routes.recherche,
      );
      await _chercher(tester, 'Coran');
      expect(find.textContaining('Mushaf'), findsWidgets);
      expect(find.text(t.recherche.etats.vide.titre), findsNothing);
    });

    testWidgets('sans le branchement : la loupe est masquee (l\'etat '
        'd\'avant)', (WidgetTester tester) async {
      await _monter(
        tester,
        AppRole.teacher,
        Routes.enseignantJournee,
        const <Override>[],
      );
      expect(find.byKey(cleLoupeRecherche), findsNothing);
    });

    testWidgets('catalogue en echec : la page dit la panne, jamais « Aucun '
        'resultat »', (WidgetTester tester) async {
      await _monter(
        tester,
        AppRole.teacher,
        Routes.recherche,
        await _production(avecGroupes: false, catalogueEnEchec: true),
      );
      await _chercher(tester, 'Coran');
      expect(find.text(t.recherche.etats.vide.titre), findsNothing);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text &&
              <String?>[
                t.recherche.etats.domaineIndisponible.titre,
                t.recherche.etats.erreur.titre,
              ].contains(w.data),
        ),
        findsWidgets,
      );
    });

    testWidgets('hors ligne : la page le dit, aucun resultat', (
      WidgetTester tester,
    ) async {
      await _monter(tester, AppRole.teacher, Routes.recherche, <Override>[
        ...await _production(avecGroupes: false, avecCatalogue: true),
        horsLigneProvider.overrideWith((Ref ref) => Stream<bool>.value(true)),
      ]);
      await _chercher(tester, 'Coran');
      expect(find.text(t.recherche.etats.horsLigne.titre), findsOneWidget);
    });
  });

  // Directeur, 08/11/2026 : « groupe » est banni (mots-rewayah : « Classe »,
  // jamais « groupe », hors identifiants du code). Aucun texte visible de la
  // recherche ne le dit : intitules, resultats, vide, panne.
  group('5. aucun « groupe » visible dans la recherche (D1 compris)', () {
    final RegExp groupe = RegExp('groupe|مجموعة', caseSensitive: false);

    void textes(Object? noeud, String chemin, List<String> trouves) {
      if (noeud is Map) {
        noeud.forEach(
          (Object? k, Object? v) => textes(v, '$chemin.$k', trouves),
        );
      } else if (noeud is String && groupe.hasMatch(noeud)) {
        trouves.add('$chemin : $noeud');
      }
    }

    test('contre-epreuve : le detecteur voit « groupe » (et « Groupe »)', () {
      final List<String> trouves = <String>[];
      textes(
        <String, Object?>{
          'a': <String, Object?>{'b': 'Mes groupes', 'c': 'Mes classes'},
          'd': 'Groupe ouvert',
        },
        'x',
        trouves,
      );
      expect(trouves, hasLength(2));
    });

    for (final String langue in <String>['fr', 'ar']) {
      test('les textes recherche.* ($langue) ne disent pas « groupe »', () {
        final Object? json = jsonDecode(
          File('assets/i18n/$langue.i18n.json').readAsStringSync(),
        );
        final List<String> trouves = <String>[];
        textes(
          (json! as Map<String, dynamic>)['recherche'],
          'recherche',
          trouves,
        );
        expect(trouves, isEmpty, reason: trouves.join('\n'));
      });
    }

    test(
      'les resultats D1 (classes et supports) ne disent pas « groupe »',
      () async {
        final ProviderContainer c = await _conteneur(<Override>[
          ...await _production(avecCatalogue: true),
        ]);
        final PortRecherche port = c.read(portRechercheProvider);
        const ContexteRecherche contexte = ContexteRecherche(
          espace: EspaceRecherche.famille,
        );
        final List<String> visibles = <String>[];
        for (final (DomaineRecherche d, String requete)
            in <(DomaineRecherche, String)>[
              (DomaineRecherche.classes, 'Classe'),
              (DomaineRecherche.supports, 'Coran'),
            ]) {
          final ReponseDomaine r = await port.rechercher(
            domaine: d,
            requete: requete,
            contexte: contexte,
          );
          expect(r, isA<ReponseOk>());
          for (final ResultatRecherche e in (r as ReponseOk).elements) {
            visibles.addAll(<String>[e.titre, ?e.contexte]);
          }
          expect(r.elements, isNotEmpty, reason: d.name);
        }
        expect(
          visibles.where(groupe.hasMatch),
          isEmpty,
          reason: visibles.join(' | '),
        );
      },
    );

    for (final (String etat, String requete, bool panne)
        in <(String, String, bool)>[
          ('resultats', 'Coran', false),
          ('vide', 'zzzzzz', false),
          ('panne', 'Coran', true),
        ]) {
      testWidgets('page de recherche, $etat : aucun « groupe » a l\'ecran', (
        WidgetTester tester,
      ) async {
        await _monter(
          tester,
          AppRole.teacher,
          Routes.recherche,
          await _production(
            avecGroupes: false,
            avecCatalogue: !panne,
            catalogueEnEchec: panne,
          ),
        );
        await _chercher(tester, requete);
        final List<String> visibles = <String>[
          for (final Element e in find.byType(Text).evaluate())
            if ((e.widget as Text).data case final String d) d,
          for (final Element e in find.byType(RichText).evaluate())
            (e.widget as RichText).text.toPlainText(),
        ];
        expect(
          visibles.where(groupe.hasMatch),
          isEmpty,
          reason: visibles.join(' | '),
        );
      });
    }
  });

  // Verdict du garde-cap sur la PR 347 : en production `PortGroupes` lit
  // `mes_groupes_famille_v`, qui ne filtre que l'eleve et le foyer et ne rend
  // AUCUNE ligne a un enseignant. Branchee dessus, la recherche de l'enseignant
  // aurait repondu « aucun resultat » (un vide presente comme confirme alors
  // qu'il est faux). Ces tests reproduisent la vue (un `PortGroupes` vide pour
  // l'enseignant) : ils etaient rouges avant la correction.
  group('6. enseignant : une source qui couvre son role', () {
    final List<GroupeEnseignant> sesClasses = DonneesEnseignantDemo.groupes();
    final String nom = sesClasses.first.libelle;
    const TeacherStudentProjection eleve = TeacherStudentProjection(
      firstName: 'Yanis',
      academyId: 'RA-26-0001',
      liveStatus: EtatPresenceProjete.attendu,
      interfaceGuidee: false,
      level: 'Niveau 1',
      activeGoals: <String>[],
      authorizedPedagogicalNotes: <String>[],
    );

    /// La production, avec la vue qui ne rend rien a l'enseignant (`PortGroupes`
    /// vide) et la source de « Mes classes » qui rend ses classes.
    List<Override> production({
      Object? erreurClasses,
      PortGroupes groupes = const FauxPortGroupes(),
    }) => <Override>[
      moteursRechercheProvider.overrideWith(moteursRechercheProduction),
      portGroupesProvider.overrideWithValue(groupes),
      serviceEnseignantProvider.overrideWithValue(
        FauxServiceEnseignant()
          ..groupesRendus = sesClasses
          ..erreurLecture = erreurClasses,
      ),
      portRosterEnseignantProvider.overrideWithValue(
        FauxRoster(eleves: <TeacherStudentProjection>[eleve]),
      ),
      portCatalogueProvider.overrideWithValue(CatalogueLocal()),
    ];

    const ContexteRecherche enseignant = ContexteRecherche(
      espace: EspaceRecherche.enseignant,
    );

    test('chercher une de ses classes la trouve, malgre la vue vide pour '
        'l\'enseignant', () async {
      final ProviderContainer c = await _conteneur(production());
      final ReponseDomaine r = await c
          .read(portRechercheProvider)
          .rechercher(
            domaine: DomaineRecherche.classes,
            requete: nom,
            contexte: enseignant,
          );
      expect(r, isA<ReponseOk>());
      expect(
        (r as ReponseOk).elements.map((ResultatRecherche e) => e.titre),
        contains(nom),
      );
    });

    test('chercher un de ses eleves le trouve, malgre la vue vide', () async {
      final ProviderContainer c = await _conteneur(production());
      final ReponseDomaine r = await c
          .read(portRechercheProvider)
          .rechercher(
            domaine: DomaineRecherche.pedagogie,
            requete: 'Yanis',
            contexte: enseignant,
          );
      expect(r, isA<ReponseOk>());
      expect((r as ReponseOk).elements, hasLength(sesClasses.length));
    });

    test(
      'l\'enseignant ne lit jamais PortGroupes (la vue de la famille)',
      () async {
        final ProviderContainer c = await _conteneur(
          production(groupes: const _GroupesInterdits()),
        );
        final PortRecherche port = c.read(portRechercheProvider);
        for (final DomaineRecherche d in <DomaineRecherche>[
          DomaineRecherche.classes,
          DomaineRecherche.pedagogie,
        ]) {
          final ReponseDomaine r = await port.rechercher(
            domaine: d,
            requete: 'a',
            contexte: enseignant,
          );
          expect(r, isA<ReponseOk>(), reason: d.name);
        }
      },
    );

    test(
      'la lecture de ses classes echoue : une panne, jamais un vide',
      () async {
        final ProviderContainer c = await _conteneur(
          production(erreurClasses: StateError('lecture refusee')),
        );
        final PortRecherche port = c.read(portRechercheProvider);
        for (final DomaineRecherche d in <DomaineRecherche>[
          DomaineRecherche.classes,
          DomaineRecherche.pedagogie,
        ]) {
          final ReponseDomaine r = await port.rechercher(
            domaine: d,
            requete: nom,
            contexte: enseignant,
          );
          expect(r, isA<ReponseEchec>(), reason: d.name);
        }
      },
    );

    test(
      'la famille garde PortGroupes : l\'enseignant n\'y change rien',
      () async {
        final ProviderContainer c = await _conteneur(
          production(groupes: FauxPortGroupes(groupes: await _classes())),
        );
        final ReponseDomaine r = await c
            .read(portRechercheProvider)
            .rechercher(
              domaine: DomaineRecherche.classes,
              requete: 'Fatiha',
              contexte: const ContexteRecherche(
                espace: EspaceRecherche.famille,
              ),
            );
        expect(r, isA<ReponseOk>());
        expect((r as ReponseOk).elements, isNotEmpty);
      },
    );
  });

  // RECH-D2 (RECHERCHE-LIVRAISON) : la resolution d'un matricule exact, sur le
  // branchement de production. Le serveur decide (quota, perimetre, role) ; la
  // direction n'a que cette entree ; une panne est une panne.
  group('7. matricule exact (D2) en production', () {
    const ContexteRecherche direction = ContexteRecherche(
      espace: EspaceRecherche.administration,
    );

    List<Override> production(PortResolutionRa ra) => <Override>[
      moteursRechercheProvider.overrideWith(moteursRechercheProduction),
      portGroupesProvider.overrideWithValue(const FauxPortGroupes()),
      portRosterEnseignantProvider.overrideWithValue(FauxRoster()),
      portResolutionRaProvider.overrideWithValue(ra),
    ];

    test('la direction trouve un eleve par son matricule complet', () async {
      final ProviderContainer c = await _conteneur(
        production(
          const _RaFixe(<String, ElevePourRa>{
            'RA-26-4817': ElevePourRa(eleveId: 'e-1', prenom: 'Yanis'),
          }),
        ),
      );
      final ReponseDomaine r = await c
          .read(portRechercheProvider)
          .rechercher(
            domaine: DomaineRecherche.personnes,
            requete: 'ra 26 4817',
            contexte: direction,
          );
      expect(r, isA<ReponseOk>());
      expect((r as ReponseOk).elements.single.titre, 'Yanis');
    });

    test('un matricule bien forme mais inconnu garde le vide normal '
        '(non-enumeration)', () async {
      final ProviderContainer c = await _conteneur(
        production(const _RaFixe(<String, ElevePourRa>{})),
      );
      final ReponseDomaine r = await c
          .read(portRechercheProvider)
          .rechercher(
            domaine: DomaineRecherche.personnes,
            requete: 'RA-26-0000',
            contexte: direction,
          );
      expect(r, isA<ReponseOk>());
      expect((r as ReponseOk).elements, isEmpty);
    });

    test(
      'arbitrage (b) : un nom ou un debut de matricule tape par la '
      'direction n\'est pas un vide, c\'est une question mal posee',
      () async {
        final ProviderContainer c = await _conteneur(
          production(const _RaFixe(<String, ElevePourRa>{})),
        );
        for (final String requete in <String>['Yanis', 'RA-26']) {
          final ReponseDomaine r = await c
              .read(portRechercheProvider)
              .rechercher(
                domaine: DomaineRecherche.personnes,
                requete: requete,
                contexte: direction,
              );
          expect(r, isA<ReponseEchec>(), reason: requete);
          expect(
            (r as ReponseEchec).statut,
            StatutRecherche.requeteInvalide,
            reason: requete,
          );
        }
      },
    );

    test('arbitrage (a) : le resultat de la direction ouvre la liste des '
        'comptes (vue Eleves) filtree sur le matricule', () async {
      final ProviderContainer c = await _conteneur(
        production(
          const _RaFixe(<String, ElevePourRa>{
            'RA-26-4817': ElevePourRa(eleveId: 'e-1', prenom: 'Yanis'),
          }),
        ),
      );
      final ReponseOk r =
          await c
                  .read(portRechercheProvider)
                  .rechercher(
                    domaine: DomaineRecherche.personnes,
                    requete: 'RA-26-4817',
                    contexte: direction,
                  )
              as ReponseOk;
      final ResultatRecherche trouve = r.elements.single;
      expect(trouve.titre, 'Yanis');
      expect(trouve.contexte, 'RA-26-4817');
      expect(
        cheminPourCible(trouve.cible, EspaceRecherche.administration),
        '${Routes.adminPersonnesComptes}?vue=eleves&q=RA-26-4817',
      );
      // Les autres espaces gardent leur regle : pas de fiche pour eux.
      expect(cheminPourCible(trouve.cible, EspaceRecherche.comptable), isNull);
    });

    test('la phase : une indication n\'est ni un vide ni une panne', () {
      EtatDomaine d(AvancementDomaine a, {StatutRecherche? echec}) =>
          EtatDomaine(
            domaine: DomaineRecherche.personnes,
            avancement: a,
            echec: echec,
          );
      expect(
        phaseDesDomaines(<EtatDomaine>[
          d(AvancementDomaine.enEchec, echec: StatutRecherche.requeteInvalide),
        ]),
        PhaseRecherche.formeAttendue,
      );
      expect(
        phaseDesDomaines(<EtatDomaine>[d(AvancementDomaine.termine)]),
        PhaseRecherche.vide,
      );
      expect(
        phaseDesDomaines(<EtatDomaine>[
          d(AvancementDomaine.enEchec, echec: StatutRecherche.indisponible),
        ]),
        PhaseRecherche.erreur,
      );
    });

    test('une panne de la resolution est une panne, jamais un vide', () async {
      final ProviderContainer c = await _conteneur(
        production(const _RaEnPanneProd()),
      );
      final ReponseDomaine r = await c
          .read(portRechercheProvider)
          .rechercher(
            domaine: DomaineRecherche.personnes,
            requete: 'RA-26-4817',
            contexte: direction,
          );
      expect(r, isA<ReponseEchec>());
    });

    test('un matricule complet n\'est reconnu qu\'a la forme RA-AA-NNNN', () {
      expect(identifiantRaExact('RA-26-4817'), 'RA-26-4817');
      expect(identifiantRaExact('ra 26 48170'), 'RA-26-48170');
      expect(identifiantRaExact('RA-AB0012'), isNull, reason: 'ancien code');
      expect(identifiantRaExact('RA-26-481'), isNull, reason: 'debut');
    });

    test('main.dart branche la resolution Supabase, jamais la demo, dans '
        'les surcharges de l\'application reelle', () {
      final String main = File('lib/main.dart').readAsStringSync();
      final int debut = main.indexOf('List<Override> _surchargesAppReelle()');
      final int ligne = main.indexOf(
        'portResolutionRaProvider.overrideWithValue(\n    ResolutionRaSupabase(',
      );
      expect(debut, greaterThan(0));
      expect(ligne, greaterThan(debut), reason: 'le raccord D2 manque');
      expect(main.contains('ResolutionRaDemo'), isFalse);
      expect(main.contains('ResolutionRaIndisponible'), isFalse);
    });

    testWidgets('sur l\'ecran : un nom tape par la direction affiche '
        'l\'indication, jamais « Aucun resultat » ; un matricule inconnu '
        'garde le vide', (WidgetTester tester) async {
      await _monter(tester, AppRole.admin, Routes.recherche, <Override>[
        moteursRechercheProvider.overrideWith(moteursRechercheProduction),
        portRosterEnseignantProvider.overrideWithValue(FauxRoster()),
        portResolutionRaProvider.overrideWithValue(
          const _RaFixe(<String, ElevePourRa>{}),
        ),
      ]);
      await _chercher(tester, 'Yanis');
      expect(find.text(t.recherche.formeAttendue), findsOneWidget);
      expect(find.text(t.recherche.etats.vide.titre), findsNothing);
      await _chercher(tester, 'RA-26-0000');
      expect(find.text(t.recherche.etats.vide.titre), findsOneWidget);
      expect(find.text(t.recherche.formeAttendue), findsNothing);
    });
  });
}
