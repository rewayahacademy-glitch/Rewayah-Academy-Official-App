// OFFRES-ADM-1 : la file des demandes reunies cote administration.
//
// Ce que le test prouve :
// - les etats : chargement, contenu, vide, erreur (et sa relecture), hors
//   ligne avec et sans donnees, port absent (« disponible au branchement
//   serveur ») ;
// - le tri : prets d'abord, puis le plus grand nombre d'eleves ;
// - le quota vient du port, jamais d'une valeur ecrite dans l'ecran ;
// - la creation integre les eleves, puis enchaine sur la proposition
//   d'enseignant (premier choix preselectionne, genre compatible), puis
//   « Les familles ont ete prevenues » ;
// - avant le quota, aucun bouton (le serveur refuse) : la phrase dit ce qui
//   manque, sans promettre d'ouverture (ECHELLE-CORR-ECRANS-1) ;
// - creation concurrente par deux membres de la direction : message clair,
//   rien en double ; double appui : un seul envoi ; reponse perdue : « non
//   confirmee », et la meme cle reprend la meme creation ;
// - capacite absente : pas de bouton, une phrase ;
// - 320 px, texte a 200 %, LTR et RTL : aucun debordement, aucun mot coupe,
//   un seul bouton plein par contexte.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/enseignants_classe.dart'
    show enseignantsDuPortProvider;
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/offre_horaire.dart';
import 'package:rewayah_academy/core/offres/port_regroupements_admin.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart';
import 'package:rewayah_academy/core/reseau/etat_sans_donnees.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/selecteur_personne.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_regroupements/regroupements_libelles.dart';
import 'package:rewayah_academy/features/admin_regroupements/regroupements_page.dart';
import 'package:rewayah_academy/features/demo/regroupements_demo.dart';

import '../../capture/outil_capture.dart' show chargerPolicesDuDepot;
import '../../support/aucun_mot_coupe.dart';
import '../../support/garde_interface.dart';
import '../../support/hors_ligne_une_fois.dart';

const String _paris = 'Europe/Paris';

/// Trois enseignants dont la source dit tout : genre, creneaux libres,
/// charge. Pour une classe de filles le lundi, mardi et jeudi a 18 h :
/// Maryam est le premier choix (compatible, libre aux trois jours), Salma
/// n'est libre que le lundi, Yusuf est incompatible.
class _Enseignants implements PortEnseignantsClasse {
  /// Nombre de lectures de la source depuis le dernier remise a zero.
  static int lectures = 0;

  @override
  Future<List<EnseignantPropose>> pourClasse({
    required TypePublicGroupe public,
  }) async {
    lectures++;
    return _liste;
  }

  static const List<EnseignantPropose> _liste = <EnseignantPropose>[
    EnseignantPropose(
      id: 'ens-yusuf',
      libelle: 'Yusuf Exemple',
      identifiant: 'TEACHER-YE-000001',
      genre: GenreEnseignant.homme,
      classesActives: 0,
      creneauxLibres: <Creneau>[
        Creneau(jour: 1, heure: 18, fuseau: _paris),
        Creneau(jour: 2, heure: 18, fuseau: _paris),
        Creneau(jour: 4, heure: 18, fuseau: _paris),
      ],
      fuseauIana: _paris,
    ),
    EnseignantPropose(
      id: 'ens-maryam',
      libelle: 'Maryam Fictive',
      identifiant: 'TEACHER-MF-000002',
      genre: GenreEnseignant.femme,
      classesActives: 2,
      creneauxLibres: <Creneau>[
        Creneau(jour: 1, heure: 18, fuseau: _paris),
        Creneau(jour: 2, heure: 18, fuseau: _paris),
        Creneau(jour: 4, heure: 18, fuseau: _paris),
      ],
      fuseauIana: _paris,
    ),
    EnseignantPropose(
      id: 'ens-salma',
      libelle: 'Salma Modele',
      identifiant: 'TEACHER-SM-000003',
      genre: GenreEnseignant.femme,
      classesActives: 0,
      creneauxLibres: <Creneau>[Creneau(jour: 1, heure: 18, fuseau: _paris)],
      fuseauIana: _paris,
    ),
  ];
}

/// Un port dont les lectures sont fournies par le test.
class _PortLecture implements PortRegroupementsAdmin {
  _PortLecture(this._lire);

  final Future<List<RegroupementDemandes>> Function() _lire;
  int lectures = 0;

  @override
  Future<List<RegroupementDemandes>> regroupements() {
    lectures++;
    return _lire();
  }

  @override
  Future<ResultatCreationClasse> creerClasse({
    required String regroupementId,
    required GenreClasse genre,
    required String libelle,
    required String cleEnvoi,
  }) async => const CreationRefusee('non teste');

  @override
  Future<ResultatAffectation> affecterEnseignant({
    required String classeId,
    required String enseignantId,
  }) async => ResultatAffectation.affecte;
}

RegroupementDemandes _reg(
  String id, {
  int eleves = 5,
  int quota = 5,
  List<int> jours = const <int>[1, 2, 4],
  int heure = 18,
  PublicOffre public = PublicOffre.enfants,
  bool peutCreer = true,
}) => RegroupementDemandes(
  id: id,
  public: public,
  langueCode: 'fr',
  langueNom: 'Français',
  fuseau: _paris,
  occurrences: <OccurrenceCreneau>[
    for (final int j in jours) OccurrenceCreneau(jourIso: j, heure: heure),
  ],
  autresFuseaux: const <HeureDansFuseau>[
    HeureDansFuseau(fuseau: 'America/Toronto', heure: 12),
  ],
  nombreEleves: eleves,
  quota: quota,
  peutCreerClasse: peutCreer,
);

const String _pret = 'demo-reg-enfants-fr-lmj-18';
const String _incomplet = 'demo-reg-enfants-ar-mer-17';

Future<void> _monter(
  WidgetTester tester, {
  PortRegroupementsAdmin? port,
  bool horsLigne = false,
  double largeur = 390,
  double hauteur = 4000,
  double echelle = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(largeur, hauteur);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        portRegroupementsAdminProvider.overrideWithValue(port),
        portEnseignantsClasseProvider.overrideWithValue(_Enseignants()),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(horsLigne),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (BuildContext contexte, Widget? app) => Directionality(
            textDirection: direction,
            child: MediaQuery(
              data: MediaQuery.of(contexte)
                  .copyWith(textScaler: TextScaler.linear(echelle)),
              child: app!,
            ),
          ),
          home: const RegroupementsPage(),
        ),
      ),
    ),
  );
  await _laisser(tester);
}

Future<void> _laisser(WidgetTester tester, {int fois = 6}) async {
  for (int i = 0; i < fois; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _demonter(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

Finder _carte(String id) => find.byKey(ValueKey<String>('regroupement-$id'));
Finder _action(String id) =>
    find.byKey(ValueKey<String>('regroupement-action-$id'));
Finder _parCle(String cle) => find.byKey(ValueKey<String>(cle));

/// Le bouton d'un `BasDeFeuille` de la feuille.
Finder _boutonFeuille(String cle) =>
    find.descendant(of: _parCle(cle), matching: find.byType(ActionPrincipale));

Future<void> _ouvrir(WidgetTester tester, String id) async {
  await tester.ensureVisible(_action(id));
  await tester.tap(_action(id));
  await _laisser(tester);
}

Future<void> _choisirGenre(WidgetTester tester, GenreClasse genre) async {
  final Finder carte = _parCle('regroupement-genre-${genre.name}');
  await tester.ensureVisible(carte);
  await tester.tap(carte);
  await tester.pump();
}

Future<void> _presser(WidgetTester tester, String cle) async {
  final Finder bouton = _boutonFeuille(cle);
  await tester.ensureVisible(bouton);
  await tester.tap(bouton);
}

/// L'etiquette et l'indication de `ChampRecherche` (composant partage,
/// inchange) : au-dela de 130 % de texte elles restent dans le champ, hors
/// de `TexteSansCoupure` (meme exception que classes_echelle_test).
Set<String> get _exceptionsRecherche => <String>{
  t.admin.regroupements.liste.rechercheLibelle,
  t.admin.regroupements.liste.rechercheAide,
};

void main() {
  group('Les etats', () {
    testWidgets('chargement : le squelette, rien d invente', (
      WidgetTester tester,
    ) async {
      final Completer<List<RegroupementDemandes>> jamais =
          Completer<List<RegroupementDemandes>>();
      await _monter(tester, port: _PortLecture(() => jamais.future));
      expect(find.byType(Skeleton), findsOneWidget);
      expect(find.byType(ActionPrincipale), findsNothing);
      await _demonter(tester);
    });

    testWidgets('contenu : jours, heure, fuseaux, public, langue, eleves', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: RegroupementsDemo());
      expect(_carte(_pret), findsOneWidget);
      expect(find.text('Lundi, mardi, jeudi · 18\u00a0h'), findsOneWidget);
      expect(find.text('18\u00a0h, heure de Paris'), findsOneWidget);
      expect(
        find.text('17\u00a0h à London · 12\u00a0h à Toronto'),
        findsOneWidget,
      );
      // Le passage de minuit se dit (« le lendemain »).
      // C-11 bis : jour par jour quand les heures different.
      // Le titre de la carte et sa ligne « Jours et heures ».
      expect(
        find.text('Mardi 20\u00a0h, jeudi 20\u00a0h\u00a030'),
        findsNWidgets(2),
      );
      expect(
        find.text(
          'Mardi\u00a0: 5\u00a0h le lendemain à Paris · '
          'Jeudi\u00a0: 5\u00a0h\u00a030 le lendemain à Paris',
        ),
        findsOneWidget,
      );
      expect(find.text('5 demandes → 1 classe possible'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
      verifierUnSeulBoutonPlein(tester);
      await _demonter(tester);
    });

    testWidgets('vide : une phrase, pas une page blanche', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: RegroupementsDemo(depart: const <RegroupementDemandes>[]),
      );
      expect(_parCle('regroupements-vide'), findsOneWidget);
      expect(find.text(t.admin.regroupements.vide), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('erreur : ce qui manque, et la relecture', (
      WidgetTester tester,
    ) async {
      bool echoue = true;
      final _PortLecture port = _PortLecture(
        () async => echoue
            ? throw StateError('serveur')
            : <RegroupementDemandes>[_reg('r1')],
      );
      await _monter(tester, port: port);
      expect(_parCle('regroupements-erreur'), findsOneWidget);
      expect(find.text(t.admin.regroupements.erreur), findsOneWidget);
      echoue = false;
      await tester.tap(find.text(t.commun.reessayer));
      await _laisser(tester);
      expect(port.lectures, 2);
      expect(_carte('r1'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('hors ligne sans donnees : ce qui manque, une seule fois', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: _PortLecture(() async => throw StateError('reseau')),
        horsLigne: true,
      );
      expectSansDonnees(t.admin.regroupements.sansDonnees);
      expect(
        tester.widget<EtatSansDonnees>(find.byType(EtatSansDonnees)).onAction,
        isNotNull,
      );
      await _demonter(tester);
    });

    testWidgets('hors ligne avec donnees : le bandeau seul, la file lue', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: RegroupementsDemo(), horsLigne: true);
      expectAvecDonnees();
      expect(_carte(_pret), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('port absent : disponible au branchement serveur', (
      WidgetTester tester,
    ) async {
      await _monter(tester);
      final Finder etat = _parCle('regroupements-indisponible');
      expect(etat, findsOneWidget);
      expect(tester.widget<EtatSysteme>(etat).nature, NatureEtat.indisponible);
      expect(
        find.text(t.admin.regroupements.indisponibleTitre),
        findsOneWidget,
      );
      expect(find.byType(ActionPrincipale), findsNothing);
      await _demonter(tester);
    });
  });

  group('Tri et quota', () {
    test('prets d abord, puis le plus grand nombre', () {
      final List<String> ordre = trierRegroupements(<RegroupementDemandes>[
        _reg('a', eleves: 2),
        _reg('b', eleves: 6, quota: 6, public: PublicOffre.adultes),
        _reg('c', eleves: 4),
        _reg('d', eleves: 5),
        _reg('e', eleves: 4, quota: 6, jours: const <int>[6]),
        // Prete avec moins d'eleves qu'une incomplete : elle passe devant.
        _reg('f', eleves: 3, quota: 3),
      ]).map((RegroupementDemandes r) => r.id).toList();
      expect(ordre, <String>['b', 'd', 'f', 'c', 'e', 'a']);
    });

    testWidgets('a l ecran, dans le meme ordre', (WidgetTester tester) async {
      await _monter(tester, port: RegroupementsDemo());
      final List<String> attendus = <String>[
        'demo-reg-adultes-en-mj-20',
        _pret,
        'demo-reg-adultes-fr-sam-10',
        _incomplet,
      ];
      final List<double> hauts = <double>[
        for (final String id in attendus) tester.getTopLeft(_carte(id)).dy,
      ];
      expect(hauts, orderedEquals(<double>[...hauts]..sort()));
      // Le seul bouton plein est sur la premiere carte.
      expect(
        tester.widget<ActionPrincipale>(_action(attendus.first)).niveau,
        NiveauAction.principale,
      );
      expect(
        tester.widget<ActionPrincipale>(_action(_pret)).niveau,
        NiveauAction.secondaire,
      );
      await _demonter(tester);
    });

    testWidgets('le quota vient du port, jamais d une valeur ecrite ici', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: RegroupementsDemo(
          depart: <RegroupementDemandes>[
            _reg('trois', eleves: 3, quota: 3),
            _reg('six', eleves: 6, quota: 7, public: PublicOffre.adultes),
          ],
        ),
      );
      expect(_parCle('regroupement-pret-trois'), findsOneWidget);
      expect(_parCle('regroupement-incomplet-six'), findsOneWidget);
      expect(find.text('6 demandes → aucune classe possible'), findsOneWidget);
      expect(find.text(t.admin.regroupements.manquent(n: 1)), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('capacite absente : pas de bouton, une phrase', (
      WidgetTester tester,
    ) async {
      await _monter(
        tester,
        port: RegroupementsDemo(
          depart: <RegroupementDemandes>[_reg('ferme', peutCreer: false)],
        ),
      );
      expect(_action('ferme'), findsNothing);
      expect(_parCle('regroupement-ferme-ferme'), findsOneWidget);
      expect(find.text(t.admin.regroupements.nonOuvert), findsOneWidget);
      await _demonter(tester);
    });
  });

  group('Creer la classe, puis l enseignant', () {
    testWidgets('creation : eleves integres, premier choix, familles '
        'prevenues', (WidgetTester tester) async {
      final RegroupementsDemo port = RegroupementsDemo();
      await _monter(tester, port: port);
      await _ouvrir(tester, _pret);
      expect(_parCle('regroupement-feuille-creation'), findsOneWidget);

      // Bouton jamais grise : sans genre, il dit ce qui manque.
      await _presser(tester, 'regroupement-creer');
      await tester.pump();
      expect(find.text(t.admin.groupes.formulaire.manqueGenre), findsOneWidget);
      expect(port.creationsRecues, 0);

      await _choisirGenre(tester, GenreClasse.femmes);
      // R16 : le nom deduit et le numero que le serveur donnera a la classe
      // parmi les classes paralleles de meme cle (4 dans la demonstration).
      expect(
        find.text('Filles, lundi, mardi, jeudi 18\u00a0h · n°\u00a04'),
        findsWidgets,
      );
      await _presser(tester, 'regroupement-creer');
      await _laisser(tester);

      expect(port.creationsRecues, 1);
      expect(_parCle('regroupement-feuille-enseignant'), findsOneWidget);
      expect(
        find.text(
          t.admin.regroupements.creee(
            n: 5,
            libelle: 'Filles, lundi, mardi, jeudi 18\u00a0h · n°\u00a04',
          ),
        ),
        findsOneWidget,
      );

      // Le premier choix est preselectionne, avec sa raison ; l'enseignant
      // incompatible reste visible, avec la sienne.
      final SelecteurPersonne selecteur = tester.widget<SelecteurPersonne>(
        find.byType(SelecteurPersonne),
      );
      expect(selecteur.choisie, 'ens-maryam');
      final List<PersonneProposee> proposees = selecteur.personnes.requireValue;
      expect(proposees.first.id, 'ens-maryam');
      expect(proposees.first.mention, startsWith('Premier choix'));
      expect(
        proposees
            .firstWhere((PersonneProposee p) => p.id == 'ens-yusuf')
            .raisonIndisponible,
        t.admin.groupes.formulaire.raisonFilles,
      );

      await _presser(tester, 'regroupement-confirmer');
      await _laisser(tester);
      expect(port.affectationsRecues, 1);
      expect(port.enseignantDe.values, <String>['ens-maryam']);
      expect(_parCle('regroupement-familles-prevenues'), findsOneWidget);
      expect(
        find.text(t.admin.regroupements.famillesPrevenues),
        findsOneWidget,
      );
      // La file s'est relue : le regroupement n'y est plus.
      await tester.tap(_parCle('regroupement-terminer'));
      await _laisser(tester);
      expect(_carte(_pret), findsNothing);
      await _demonter(tester);
    });

    testWidgets(
      'apres l affectation, la source des enseignants est relue (charge '
      'et creneaux pris a jour)',
      (WidgetTester tester) async {
        _Enseignants.lectures = 0;
        await _monter(tester, port: RegroupementsDemo());
        await _ouvrir(tester, _pret);
        await _choisirGenre(tester, GenreClasse.femmes);
        await _presser(tester, 'regroupement-creer');
        await _laisser(tester);
        expect(_parCle('regroupement-feuille-enseignant'), findsOneWidget);
        expect(_Enseignants.lectures, 1);

        await _presser(tester, 'regroupement-confirmer');
        await _laisser(tester);
        expect(_parCle('regroupement-familles-prevenues'), findsOneWidget);

        // Une relecture de la famille repart de la source : le cache n'a pas
        // survecu a l'affectation.
        final ProviderContainer conteneur = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
        );
        await conteneur.read(
          enseignantsDuPortProvider(TypePublicGroupe.enfant).future,
        );
        expect(_Enseignants.lectures, 2);
        await _demonter(tester);
      },
    );

    testWidgets('classe d hommes : le premier choix suit le genre', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: RegroupementsDemo());
      await _ouvrir(tester, _pret);
      await _choisirGenre(tester, GenreClasse.hommes);
      await _presser(tester, 'regroupement-creer');
      await _laisser(tester);
      expect(
        tester
            .widget<SelecteurPersonne>(find.byType(SelecteurPersonne))
            .choisie,
        'ens-yusuf',
      );
      await _demonter(tester);
    });

    testWidgets('avant le quota : pas de bouton, la phrase dit ce qui '
        'manque, sans rien promettre', (WidgetTester tester) async {
      final RegroupementsDemo port = RegroupementsDemo();
      await _monter(tester, port: port);
      expect(_parCle('regroupement-incomplet-$_incomplet'), findsOneWidget);
      // Le serveur refuse un regroupement qui n'est pas pret : aucun bouton
      // qui ne pourrait pas aboutir, et aucune phrase « vous pouvez quand
      // meme » ni « d'autres eleves pourront la rejoindre ».
      expect(_action(_incomplet), findsNothing);
      expect(_parCle('regroupement-ferme-$_incomplet'), findsNothing);
      expect(find.text(t.admin.regroupements.manquent(n: 3)), findsOneWidget);
      expect(find.textContaining('quand même'), findsNothing);
      expect(find.textContaining('rejoindre'), findsNothing);
      expect(port.creationsRecues, 0);
      await _demonter(tester);
    });

    testWidgets('feuille fermee avant l enseignant : la classe attend en '
        'tete, et se reprend', (WidgetTester tester) async {
      final RegroupementsDemo port = RegroupementsDemo();
      await _monter(tester, port: port);
      await _ouvrir(tester, _pret);
      await _choisirGenre(tester, GenreClasse.femmes);
      await _presser(tester, 'regroupement-creer');
      await _laisser(tester);
      Navigator.of(tester.element(find.byType(SelecteurPersonne))).pop();
      await _laisser(tester);
      expect(_parCle('regroupements-a-finir'), findsOneWidget);
      final ActionPrincipale reprendre = tester.widget<ActionPrincipale>(
        _action(_pret),
      );
      expect(reprendre.libelle, t.admin.regroupements.choisirEnseignant);
      expect(reprendre.niveau, NiveauAction.principale);
      await _ouvrir(tester, _pret);
      expect(_parCle('regroupement-feuille-enseignant'), findsOneWidget);
      expect(
        tester
            .widget<SelecteurPersonne>(find.byType(SelecteurPersonne))
            .choisie,
        'ens-maryam',
      );
      await _demonter(tester);
    });
  });

  group('Concurrence, double appui, reponse perdue', () {
    testWidgets('deux membres de la direction : message clair, rien en '
        'double', (WidgetTester tester) async {
      final RegroupementsDemo port = RegroupementsDemo();
      await _monter(tester, port: port);
      await _ouvrir(tester, _pret);
      await _choisirGenre(tester, GenreClasse.femmes);
      // Un autre membre de la direction cree la classe juste avant.
      port.creerParUnAutre(_pret);
      await _presser(tester, 'regroupement-creer');
      await _laisser(tester);
      expect(_parCle('regroupement-deja-creee'), findsOneWidget);
      expect(find.text(t.admin.regroupements.dejaCreee), findsOneWidget);
      expect(_parCle('regroupement-feuille-enseignant'), findsNothing);
      expect(_parCle('regroupement-creer'), findsNothing);
      verifierUnSeulBoutonPlein(tester, maximum: 2);
      await _demonter(tester);
    });

    testWidgets('double appui : un seul envoi', (WidgetTester tester) async {
      final RegroupementsDemo port = RegroupementsDemo(
        latence: const Duration(milliseconds: 300),
      );
      await _monter(tester, port: port);
      await _ouvrir(tester, _pret);
      await _choisirGenre(tester, GenreClasse.femmes);
      await _presser(tester, 'regroupement-creer');
      await tester.pump();
      expect(
        tester
            .widget<ActionPrincipale>(_boutonFeuille('regroupement-creer'))
            .enCours,
        isTrue,
      );
      await tester.tap(
        _boutonFeuille('regroupement-creer'),
        warnIfMissed: false,
      );
      await tester.pump();
      await _laisser(tester, fois: 8);
      expect(port.creationsRecues, 1);
      expect(_parCle('regroupement-feuille-enseignant'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('reponse perdue : non confirmee, puis reprise sans double', (
      WidgetTester tester,
    ) async {
      final RegroupementsDemo port = RegroupementsDemo();
      await _monter(tester, port: port);
      await _ouvrir(tester, _pret);
      await _choisirGenre(tester, GenreClasse.femmes);
      // La reponse se perd.
      port.horsLigne = true;
      await _presser(tester, 'regroupement-creer');
      await _laisser(tester);
      expect(find.text(t.admin.regroupements.nonConfirmee), findsOneWidget);
      expect(_parCle('regroupement-feuille-creation'), findsOneWidget);
      port.horsLigne = false;
      await _presser(tester, 'regroupement-creer');
      await _laisser(tester);
      expect(_parCle('regroupement-feuille-enseignant'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('enseignant deja confirme par un autre : rien ne change', (
      WidgetTester tester,
    ) async {
      final RegroupementsDemo port = RegroupementsDemo();
      await _monter(tester, port: port);
      await _ouvrir(tester, _pret);
      await _choisirGenre(tester, GenreClasse.femmes);
      await _presser(tester, 'regroupement-creer');
      await _laisser(tester);
      // L'autre membre confirme un enseignant avant nous.
      await port.affecterEnseignant(
        classeId: 'demo-classe-regroupee-1',
        enseignantId: 'ens-salma',
      );
      await _presser(tester, 'regroupement-confirmer');
      await _laisser(tester);
      expect(_parCle('regroupement-deja-affecte'), findsOneWidget);
      expect(port.enseignantDe.values, <String>['ens-salma']);
      await _demonter(tester);
    });
  });

  group('Reserves de la verification (OFFRES-1B)', () {
    setUpAll(chargerPolicesDuDepot);

    testWidgets('ADM 2 : a la creation, les familles sont prevenues que leur '
        'classe est validee ; apres l affectation, prevenues', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: RegroupementsDemo());
      await _ouvrir(tester, _pret);
      await _choisirGenre(tester, GenreClasse.femmes);
      await _presser(tester, 'regroupement-creer');
      await _laisser(tester);
      expect(_parCle('regroupement-feuille-enseignant'), findsOneWidget);
      expect(
        find.text(
          'Les familles ont été prévenues que leur classe est validée.',
        ),
        findsOneWidget,
      );
      expect(find.text(t.admin.regroupements.famillesPrevenues), findsNothing);
      await _presser(tester, 'regroupement-confirmer');
      await _laisser(tester);
      expect(find.text('Les familles ont été prévenues.'), findsOneWidget);
      await _demonter(tester);
    });

    for (final TextDirection direction in TextDirection.values) {
      testWidgets('ADM 3 : deja affecte par un autre, une seule phrase claire '
          '(320 px, texte a 200 %, ${direction.name})', (
        WidgetTester tester,
      ) async {
        final RegroupementsDemo port = RegroupementsDemo();
        await _monter(
          tester,
          port: port,
          largeur: 320,
          hauteur: 2400,
          echelle: 2,
          direction: direction,
        );
        await _ouvrir(tester, _pret);
        await _choisirGenre(tester, GenreClasse.femmes);
        await _presser(tester, 'regroupement-creer');
        await _laisser(tester);
        await port.affecterEnseignant(
          classeId: 'demo-classe-regroupee-1',
          enseignantId: 'ens-salma',
        );
        await _presser(tester, 'regroupement-confirmer');
        await _laisser(tester);
        expect(
          find.text(
            'Un autre membre de la direction a déjà confirmé l\'enseignant '
            'de cette classe\u00a0: votre choix ne remplace pas le sien.',
          ),
          findsOneWidget,
        );
        // Pas de « Les familles ont ete prevenues » a cote de « rien n'a
        // change » : ce choix-ci n'a rien provoque.
        expect(_parCle('regroupement-familles-prevenues'), findsNothing);
        expect(
          find.textContaining('prévenues', findRichText: true),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester, exceptions: _exceptionsRecherche);
        verifierUnSeulBoutonPlein(tester, maximum: 2);
        await _demonter(tester);
      });
    }

    testWidgets('ADM 1 : le texte de proposition ne promet pas une '
        'comparaison dans le meme fuseau', (WidgetTester tester) async {
      await _monter(tester, port: RegroupementsDemo());
      await _ouvrir(tester, _pret);
      await _choisirGenre(tester, GenreClasse.femmes);
      await _presser(tester, 'regroupement-creer');
      await _laisser(tester);
      final String contexte = t.admin.regroupements.enseignantContexte;
      expect(find.text(contexte), findsOneWidget);
      expect(contexte, contains('sans conversion de fuseau'));
      expect(contexte, isNot(contains('à ces jours et à cette heure')));
      await _demonter(tester);
    });
  });

  group('C-11 bis : une heure par jour', () {
    setUpAll(chargerPolicesDuDepot);
    const String differentes = 'demo-reg-adultes-en-mj-20';

    RegroupementDemandes regAvec(
      List<(int, int, int)> occurrences, {
      List<HeureDansFuseau> ailleurs = const <HeureDansFuseau>[],
    }) => RegroupementDemandes(
      id: 'c11',
      public: PublicOffre.enfants,
      langueCode: 'fr',
      langueNom: 'Français',
      fuseau: _paris,
      occurrences: <OccurrenceCreneau>[
        for (final (int j, int h, int m) in occurrences)
          OccurrenceCreneau(jourIso: j, heure: h, minute: m),
      ],
      autresFuseaux: ailleurs,
      nombreEleves: 3,
      quota: 5,
    );

    test('le modele trie par jour et garde l heure de chaque jour', () {
      final RegroupementDemandes g = regAvec(<(int, int, int)>[
        (3, 19, 30),
        (1, 18, 0),
      ]);
      expect(g.occurrences, const <OccurrenceCreneau>[
        OccurrenceCreneau(jourIso: 1, heure: 18),
        OccurrenceCreneau(jourIso: 3, heure: 19, minute: 30),
      ]);
      expect(g.jours, <int>[1, 3]);
      expect(g.heuresToutesEgales, isFalse);
      // Chaque seance proposee a l'enseignant garde l'heure de son jour.
      expect(
        creneauxDe(g).map((Creneau c) => (c.jour, c.heure)).toList(),
        <(int, int)>[(1, 18), (3, 19)],
      );
    });

    test('doublon de jour, liste vide, autre fuseau sans jour : refuses', () {
      expect(
        () => regAvec(<(int, int, int)>[(1, 18, 0), (1, 19, 0)]),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => regAvec(const <(int, int, int)>[]),
        throwsA(isA<AssertionError>()),
      );
      // Heures differentes : une heure d'ailleurs qui ne dit pas son jour
      // mentirait pour l'autre jour.
      expect(
        () => regAvec(
          <(int, int, int)>[(1, 18, 0), (3, 19, 30)],
          ailleurs: const <HeureDansFuseau>[
            HeureDansFuseau(fuseau: 'America/Toronto', heure: 12),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
      // Heures egales : une heure d'ailleurs commune reste permise.
      expect(
        regAvec(
          <(int, int, int)>[(1, 18, 0), (3, 18, 0)],
          ailleurs: const <HeureDansFuseau>[
            HeureDansFuseau(fuseau: 'America/Toronto', heure: 12),
          ],
        ).autresFuseaux,
        hasLength(1),
      );
    });

    test('libelles : heure commune une fois, sinon chaque jour la sienne', () {
      final RegroupementDemandes egales = regAvec(<(int, int, int)>[
        (4, 18, 0),
        (1, 18, 0),
        (2, 18, 0),
      ]);
      expect(libelleCreneau(egales), 'Lundi, mardi, jeudi · 18 h');
      expect(libelleReference(egales), '18 h, heure de Paris');
      expect(
        nomDeduit(egales, null),
        t.admin.groupes.formulaire.nomPropose(
          base: 'Enfants',
          creneau: 'lundi, mardi, jeudi 18 h',
        ),
      );

      final RegroupementDemandes autres = regAvec(
        <(int, int, int)>[(3, 19, 30), (1, 18, 0)],
        ailleurs: const <HeureDansFuseau>[
          HeureDansFuseau(
            fuseau: 'Europe/London',
            heure: 18,
            minute: 30,
            jourIso: 3,
          ),
          HeureDansFuseau(fuseau: 'Europe/London', heure: 17, jourIso: 1),
        ],
      );
      // Jamais l'heure du premier jour prise pour celle des autres.
      expect(libelleHeureCommune(autres), isNull);
      expect(libelleReference(autres), isNull);
      expect(libelleCreneau(autres), 'Lundi 18 h, mercredi 19 h 30');
      expect(libelleFuseau(autres), 'Heure de Paris');
      expect(
        libelleAutresFuseaux(autres),
        'Lundi\u00a0: 17 h à London · Mercredi\u00a0: 18 h 30 à London',
      );
      expect(
        nomDeduit(autres, null),
        t.admin.groupes.formulaire.nomPropose(
          base: 'Enfants',
          creneau: 'lundi 18 h, mercredi 19 h 30',
        ),
      );
    });

    testWidgets('heures egales : la ligne actuelle, inchangee', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: RegroupementsDemo());
      expect(find.text(t.admin.regroupements.cleJours), findsNWidgets(3));
      expect(find.text(t.admin.regroupements.cleHeure), findsNWidgets(3));
      expect(find.text('Lundi, mardi, jeudi'), findsOneWidget);
      await _demonter(tester);
    });

    testWidgets('heures differentes : jours et heures, puis le fuseau', (
      WidgetTester tester,
    ) async {
      await _monter(tester, port: RegroupementsDemo());
      final Finder ligne = find.byKey(
        const ValueKey<String>('regroupement-jours-heures-$differentes'),
      );
      expect(ligne, findsOneWidget);
      expect(
        find.descendant(
          of: ligne,
          matching: find.text('Mardi 20 h, jeudi 20 h 30'),
        ),
        findsOneWidget,
      );
      expect(find.text(t.admin.regroupements.cleFuseau), findsOneWidget);
      expect(find.text('Heure de Los Angeles'), findsOneWidget);
      expect(find.text('20 h, heure de Los Angeles'), findsNothing);
      await _demonter(tester);
    });

    for (final TextDirection direction in TextDirection.values) {
      testWidgets('320 px, texte a 200 %, feuille a heures differentes '
          '(${direction.name})', (WidgetTester tester) async {
        await _monter(
          tester,
          port: RegroupementsDemo(),
          largeur: 320,
          hauteur: 2400,
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester, exceptions: _exceptionsRecherche);
        await _ouvrir(tester, differentes);
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(
            const ValueKey<String>('regroupement-jours-heures-$differentes'),
          ),
          findsWidgets,
        );
        verifierEcranSansMotCoupe(tester, exceptions: _exceptionsRecherche);
        verifierUnSeulBoutonPlein(tester, maximum: 2);
        await _demonter(tester);
      });
    }
  });

  group('320 px, texte a 200 %', () {
    setUpAll(chargerPolicesDuDepot);
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('page et feuille sans debordement (${direction.name})', (
        WidgetTester tester,
      ) async {
        final RegroupementsDemo port = RegroupementsDemo();
        await _monter(
          tester,
          port: port,
          largeur: 320,
          hauteur: 2400,
          echelle: 2,
          direction: direction,
        );
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester, exceptions: _exceptionsRecherche);
        verifierUnSeulBoutonPlein(tester);

        // La feuille de creation, avec son message (genre manquant).
        await _ouvrir(tester, _pret);
        await _presser(tester, 'regroupement-creer');
        await tester.pump();
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester, exceptions: _exceptionsRecherche);
        verifierUnSeulBoutonPlein(tester, maximum: 2);

        // La proposition d'enseignant.
        await _choisirGenre(tester, GenreClasse.femmes);
        await _presser(tester, 'regroupement-creer');
        await _laisser(tester);
        expect(_parCle('regroupement-feuille-enseignant'), findsOneWidget);
        expect(tester.takeException(), isNull);
        verifierEcranSansMotCoupe(tester, exceptions: _exceptionsRecherche);
        verifierUnSeulBoutonPlein(tester, maximum: 2);
        await _demonter(tester);
      });
    }
  });
}
