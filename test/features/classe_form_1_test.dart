// CLASSE-FORM-1 : le formulaire « Nouvelle classe » semi-automatique.
//
// Deux niveaux : le classement des enseignants en fonction pure (D2, D4, D5),
// puis la VRAIE feuille, ouverte par le vrai bouton de `GroupesPage` ; seuls
// les services et les ports sont des doubles (`support_form_l2.dart`). Les
// valeurs envoyees au port se mesurent champ par champ.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/creation_classe_refusee.dart';
import 'package:rewayah_academy/core/admin/enseignants_classe.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_groupes.dart';
import 'package:rewayah_academy/core/capacites/port_creation_classe.dart';
import 'package:rewayah_academy/core/capacites/port_enseignants_classe.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/offres/affectation_refusee.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show Creneau;
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/core/widgets/action_principale.dart';
import 'package:rewayah_academy/core/widgets/app_bottom_sheet.dart';
import 'package:rewayah_academy/core/widgets/menu_actions.dart';
import 'package:rewayah_academy/core/widgets/selecteur_motif.dart';
import 'package:rewayah_academy/core/widgets/selecteur_personne.dart';
import 'package:rewayah_academy/core/widgets/skeleton.dart';
import 'package:rewayah_academy/features/admin_groupes/duree_creneau.dart';
import 'package:rewayah_academy/features/admin_groupes/groupes_page.dart';
import 'package:rewayah_academy/features/demo/classe_form_demo.dart';

import '../support/aucun_mot_coupe.dart';
import '../support/garde_interface.dart';
import '../support/harnais.dart' show FauxServiceReseau;
import 'support_form_l2.dart';

const String _paris = 'Europe/Paris';
const String _casablanca = 'Africa/Casablanca';

Creneau _c(int jour, int heure, [String fuseau = _paris]) =>
    Creneau(jour: jour, heure: heure, fuseau: fuseau);

/// Deux enseignants, une enseignante, et une personne dont la source ne dit
/// ni le genre ni les disponibilites : la source dit le genre des autres,
/// donc le sien n'est pas renseigne (D3 revue, CAND-Q15).
final List<EnseignantPropose> _enseignants = <EnseignantPropose>[
  EnseignantPropose(
    id: 'h1',
    libelle: 'Bilal Haddou',
    identifiant: 'ENS-BH-101',
    genre: GenreEnseignant.homme,
    creneauxLibres: <Creneau>[_c(2, 17, _casablanca), _c(4, 18, _casablanca)],
    classesActives: 2,
    fuseauIana: _casablanca,
  ),
  EnseignantPropose(
    id: 'h2',
    libelle: 'Hamza Sow',
    identifiant: 'ENS-HS-102',
    genre: GenreEnseignant.homme,
    creneauxLibres: <Creneau>[_c(2, 17)],
    creneauxPris: <Creneau>[_c(3, 18)],
    classesActives: 1,
    fuseauIana: _paris,
  ),
  EnseignantPropose(
    id: 'f1',
    libelle: 'Fatima Diallo',
    identifiant: 'ENS-FD-103',
    genre: GenreEnseignant.femme,
    creneauxLibres: <Creneau>[_c(2, 17), _c(5, 10)],
    classesActives: 2,
    fuseauIana: _paris,
  ),
  const EnseignantPropose(
    id: 'x1',
    libelle: 'Nour Kane',
    identifiant: 'ENS-NK-104',
    classesActives: 0,
  ),
];

/// Une source qui repond pour les enfants et jamais pour les adultes : la
/// liste se recharge sans fin apres un changement de public.
class _PortParPublic implements PortEnseignantsClasse {
  final Completer<List<EnseignantPropose>> _jamais =
      Completer<List<EnseignantPropose>>();

  @override
  Future<List<EnseignantPropose>> pourClasse({
    required TypePublicGroupe public,
  }) => public == TypePublicGroupe.enfant
      ? Future<List<EnseignantPropose>>.value(_enseignants)
      : _jamais.future;
}

/// Une source en echec, autre que « indisponible » : aucun repli.
class _PortEnEchec implements PortEnseignantsClasse {
  @override
  Future<List<EnseignantPropose>> pourClasse({
    required TypePublicGroupe public,
  }) => Future<List<EnseignantPropose>>.error(Exception('reseau coupe'));
}

/// Une creation que le serveur refuse une fois, avec [motif], puis qui
/// aboutit (CAND-Q15 : `creer_groupe` passe par le predicat d'affectation).
class _CreationRefusee extends FauxCreationClasse {
  _CreationRefusee(this.motif);

  final MotifRefusCreationClasse motif;
  int refus = 1;

  @override
  Future<String> creer({
    required String teacherId,
    required TypePublicGroupe type,
    required GenreClasse genre,
    required String libelle,
    required Creneau creneau,
    required int seuilMax,
    List<Creneau> autresCreneaux = const <Creneau>[],
    List<int?> durees = const <int?>[],
  }) async {
    if (refus > 0) {
      refus--;
      throw CreationClasseRefusee(motif);
    }
    return super.creer(
      teacherId: teacherId,
      type: type,
      genre: genre,
      libelle: libelle,
      creneau: creneau,
      seuilMax: seuilMax,
      autresCreneaux: autresCreneaux,
      durees: durees,
    );
  }
}

List<String> _ids(List<EnseignantClasse> l) => <String>[
  for (final EnseignantClasse e in l) e.enseignant.id,
];

EnseignantClasse _de(List<EnseignantClasse> l, String id) =>
    l.firstWhere((EnseignantClasse e) => e.enseignant.id == id);

// ---------------------------------------------------------------------------
// Montage de la vraie feuille.

Widget _hote(
  List<Override> surcharges, {
  ThemeMode theme = ThemeMode.light,
  double echelle = 1,
}) => ProviderScope(
  overrides: surcharges,
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      darkTheme: AppTheme.pour(InterfaceMode.standard, Brightness.dark),
      themeMode: theme,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext context, Widget? app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(echelle)),
        child: app!,
      ),
      home: const GroupesPage(),
    ),
  ),
);

List<Override> _surcharges({
  FauxGroupesFormL2? groupes,
  FauxCreationClasse? creation,
  PortEnseignantsClasse? port,
  bool horsLigne = false,
}) => <Override>[
  ...surchargesFormL2(
    comptes: FauxComptesFormL2(comptesFormL2),
    groupes: groupes,
  ),
  portEnseignantsClasseProvider.overrideWithValue(
    port ?? FauxEnseignantsClasse(_enseignants),
  ),
  portCreationClasseProvider.overrideWithValue(
    creation ?? FauxCreationClasse(),
  ),
  serviceReseauProvider.overrideWithValue(
    FauxServiceReseau(horsLigneRendu: horsLigne),
  ),
];

Future<void> _presser(WidgetTester tester, Finder cible) async {
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Future<void> _ouvrir(
  WidgetTester tester,
  List<Override> surcharges, {
  Size vue = const Size(1440, 1600),
  ThemeMode theme = ThemeMode.light,
  double echelle = 1,
}) async {
  tester.view.physicalSize = vue;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_hote(surcharges, theme: theme, echelle: echelle));
  await tester.pumpAndSettle();
  await _presser(tester, find.text(t.admin.groupes.creer).first);
}

Finder _cle(String cle) => find.byKey(ValueKey<String>(cle));

/// Le texte tel qu'il se lit. Depuis le lot E2, une carte de choix garde
/// entiers les mots composes de toutes ses lignes, plus seulement du titre
/// (`nomsComposesEntiers` sur la description aussi) : quand la ligne se
/// coupait juste apres « vous- », un gluon invisible (U+2060) suit le trait
/// et « vous-meme » passe entier a la ligne. Le texte rendu differe donc de
/// la cle d'un caractere invisible ; ce qui se lit est le meme.
Finder _texteLu(String texte) => find.byWidgetPredicate(
  (Widget w) =>
      w is RichText && w.text.toPlainText().replaceAll('\u2060', '') == texte,
);

Finder get _champNom =>
    find.descendant(of: _cle('classe-nom'), matching: find.byType(TextField));

String _nom(WidgetTester tester) =>
    tester.widget<TextField>(_champNom).controller!.text;

Finder get _envoyer => find.text(t.admin.groupes.creerEnvoyer);

Future<void> _heure(WidgetTester tester, int heure) async {
  await _presser(tester, _cle('classe-heure'));
  await _presser(
    tester,
    find.text(t.admin.groupes.formulaire.heureValeur(heure: '$heure')).last,
  );
}

/// D2 (29/10/2026) : la feuille propose trois creneaux par defaut ; ces
/// tests creent une classe d'un seul creneau, et retirent les deux autres.
Future<void> _unSeulCreneau(WidgetTester tester) async {
  while (_cle('classe-autre-2-retirer').evaluate().isNotEmpty) {
    await _presser(tester, _cle('classe-autre-2-retirer'));
  }
}

void main() {
  group('Classement des enseignants (fonction pure, D2 D4 D5)', () {
    test('la regle de genre : hommes, femmes, non determine, inconnu', () {
      expect(genreCompatible(GenreClasse.hommes, GenreEnseignant.homme), true);
      expect(genreCompatible(GenreClasse.hommes, GenreEnseignant.femme), false);
      expect(genreCompatible(GenreClasse.femmes, GenreEnseignant.femme), true);
      expect(genreCompatible(GenreClasse.femmes, GenreEnseignant.homme), false);
      expect(
        genreCompatible(GenreClasse.indetermine, GenreEnseignant.homme),
        true,
      );
      // D3 : genre de l'enseignant inconnu, aucune conclusion.
      expect(genreCompatible(GenreClasse.femmes, null), isNull);
      // Genre de la classe pas encore choisi.
      expect(genreCompatible(null, GenreEnseignant.homme), isNull);
    });

    test('classe de femmes, mardi 17 h : l\'enseignante libre est la plus '
        'adaptee, les hommes restent visibles en fin de liste', () {
      final List<EnseignantClasse> l = classerEnseignants(
        _enseignants,
        genre: GenreClasse.femmes,
        creneau: _c(2, 17),
      );
      expect(_ids(l), <String>['f1', 'h2', 'h1', 'x1']);
      expect(_de(l, 'f1').plusAdapte, isTrue);
      expect(l.where((EnseignantClasse e) => e.plusAdapte), hasLength(1));
      expect(_de(l, 'h1').choisissable, isFalse);
      expect(_de(l, 'h1').genreCompatible, isFalse);
      // D3 revue (CAND-Q15) : genre non renseigne, visible mais non
      // choisissable ; la regle de genre elle-meme ne conclut rien.
      expect(_de(l, 'x1').genreCompatible, isNull);
      expect(_de(l, 'x1').genreInconnu, isTrue);
      expect(_de(l, 'x1').choisissable, isFalse);
      expect(_de(l, 'x1').libre, isNull);
      expect(_de(l, 'f1').genreInconnu, isFalse);
    });

    test('classe d\'hommes, mardi 17 h : a creneau libre egal, le moins '
        'charge passe devant', () {
      final List<EnseignantClasse> l = classerEnseignants(
        _enseignants,
        genre: GenreClasse.hommes,
        creneau: _c(2, 17),
      );
      expect(_ids(l), <String>['h2', 'h1', 'f1', 'x1']);
      expect(_de(l, 'h2').plusAdapte, isTrue);
      expect(_de(l, 'f1').choisissable, isFalse);
      expect(_de(l, 'x1').choisissable, isFalse);
    });

    test('collision : deja en classe a ce creneau, non choisissable ; '
        'personne de libre, aucune mention inventee', () {
      final List<EnseignantClasse> l = classerEnseignants(
        _enseignants,
        genre: GenreClasse.hommes,
        creneau: _c(3, 18),
      );
      expect(_de(l, 'h2').pris, isTrue);
      expect(_de(l, 'h2').choisissable, isFalse);
      expect(_de(l, 'h1').libre, isFalse);
      expect(_ids(l), <String>['h1', 'x1', 'h2', 'f1']);
      expect(l.any((EnseignantClasse e) => e.plusAdapte), isFalse);
    });

    test('sans creneau choisi : libre a au moins un creneau, puis le moins '
        'charge', () {
      final List<EnseignantClasse> l = classerEnseignants(
        _enseignants,
        genre: GenreClasse.indetermine,
      );
      // h1 et f1 ont autant de classes : le nom les departage.
      expect(_ids(l), <String>['h2', 'h1', 'f1', 'x1']);
      expect(_de(l, 'h2').plusAdapte, isTrue);
      expect(
        l.every((EnseignantClasse e) => e.genreCompatible ?? false),
        isTrue,
      );
      // Meme une classe sans genre ne va pas a une personne au genre non
      // renseigne : le serveur la refuse (CAND-Q15).
      expect(_de(l, 'x1').choisissable, isFalse);
    });

    test('genre de classe pas encore choisi : un genre non renseigne ferme '
        'deja le choix', () {
      final List<EnseignantClasse> l = classerEnseignants(_enseignants);
      expect(_de(l, 'x1').genreInconnu, isTrue);
      expect(_de(l, 'x1').choisissable, isFalse);
      expect(
        l
            .where((EnseignantClasse e) => e.choisissable)
            .map((EnseignantClasse e) => e.enseignant.id),
        unorderedEquals(<String>['h1', 'h2', 'f1']),
      );
    });

    test('repli : la source ne dit le genre de personne, rien n\'est conclu '
        'et tous restent choisissables (le serveur tranche)', () {
      final List<EnseignantClasse> l = classerEnseignants(
        enseignantsDepuisComptes(comptesFormL2, <GroupeAdmin>[]),
        genre: GenreClasse.femmes,
        creneau: _c(2, 17),
      );
      expect(l, isNotEmpty);
      expect(l.every((EnseignantClasse e) => !e.genreInconnu), isTrue);
      expect(l.every((EnseignantClasse e) => e.choisissable), isTrue);
    });

    test('repli sur les comptes : charge et creneaux pris lus dans les '
        'classes, ni genre ni disponibilites devines', () {
      final List<EnseignantPropose> l = enseignantsDepuisComptes(
        comptesFormL2,
        <GroupeAdmin>[groupeFormL2()],
      );
      expect(l.map((EnseignantPropose e) => e.id), <String>[
        't-amina',
        't-yacine',
      ]);
      final EnseignantPropose amina = l.first;
      expect(amina.classesActives, 1);
      expect(amina.creneauxPris.single.jour, 2);
      expect(amina.genre, isNull);
      expect(amina.creneauxLibres, isNull);
      expect(amina.fuseauIana, isNull);
    });
  });

  group('La feuille « Nouvelle classe »', () {
    testWidgets('genre obligatoire : presser sans genre le dit, rien ne part', (
      WidgetTester tester,
    ) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      await _ouvrir(tester, _surcharges(creation: creation));

      // Le bouton est actif (K-56) : il n'est jamais grise.
      final ActionPrincipale bouton = tester.widget<ActionPrincipale>(
        find.ancestor(of: _envoyer, matching: find.byType(ActionPrincipale)),
      );
      expect(bouton.onPress, isNotNull);

      await _unSeulCreneau(tester);

      await _presser(tester, _envoyer);
      expect(find.text(t.admin.groupes.formulaire.manqueGenre), findsOneWidget);
      expect(creation.creations, isEmpty);

      // Le genre choisi, le manque suivant est dit : l'enseignant.
      await _presser(tester, _cle('classe-genre-femmes'));
      expect(find.text(t.admin.groupes.formulaire.manqueGenre), findsNothing);
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(find.text(t.admin.groupes.manqueEnseignant), findsOneWidget);
      // Puis le creneau.
      await _presser(tester, _cle('personne-f1'));
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(
        find.text(t.admin.groupes.formulaire.manqueCreneau),
        findsOneWidget,
      );
      expect(creation.creations, isEmpty);
    });

    testWidgets('trois cartes de genre, chacune dit quand la choisir ; '
        'l\'accord suit le public', (WidgetTester tester) async {
      await _ouvrir(tester, _surcharges());
      final f = t.admin.groupes.formulaire;
      expect(find.text(f.contexte), findsOneWidget);
      expect(find.text(f.genreGarcons), findsOneWidget);
      expect(find.text(f.genreFilles), findsOneWidget);
      // D1 (29/10/2026) : « Mixte » remplace « Non determine » pour une
      // classe nouvelle.
      expect(find.text(f.genreMixte), findsOneWidget);
      expect(find.text(f.genreIndetermine), findsNothing);
      expect(find.text(f.genreFillesDetail), findsOneWidget);
      expect(find.text(f.genreMixteDetailEnfants), findsOneWidget);

      await _presser(tester, _cle('classe-public-adulte'));
      expect(find.text(f.genreHommes), findsOneWidget);
      expect(find.text(f.genreFemmes), findsOneWidget);
      expect(find.text(f.genreFemmesDetail), findsOneWidget);
      expect(find.text(f.genreGarcons), findsNothing);
    });

    testWidgets('ligne honnete D1 : dite quand le genre ne part pas, '
        'absente quand il est retenu', (WidgetTester tester) async {
      await _ouvrir(
        tester,
        _surcharges(creation: FauxCreationClasse(retientGenre: false)),
      );
      expect(
        find.text(t.admin.groupes.formulaire.genreNonEnregistre),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await _ouvrir(tester, _surcharges(creation: FauxCreationClasse()));
      expect(
        find.text(t.admin.groupes.formulaire.genreNonEnregistre),
        findsNothing,
      );
    });

    testWidgets('le plus adapte porte sa raison ; un enseignant du mauvais '
        'genre reste visible, avec sa raison, et ne se choisit pas', (
      WidgetTester tester,
    ) async {
      await _ouvrir(tester, _surcharges());
      final f = t.admin.groupes.formulaire;
      await _presser(tester, _cle('classe-public-adulte'));
      await _presser(tester, _cle('classe-genre-femmes'));
      await _presser(tester, _cle('classe-jour-2'));
      await _heure(tester, 17);

      expect(
        find.textContaining(
          f.plusAdapteCreneau(charge: f.classesEnCours(n: 2)),
        ),
        findsOneWidget,
      );
      expect(find.text(f.raisonFemmes), findsNWidgets(2));
      // Toucher un enseignant indisponible ne le retient pas.
      await _presser(tester, _cle('personne-h1'));
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(find.text(t.admin.groupes.manqueEnseignant), findsOneWidget);
    });

    testWidgets('preremplissages : seuil 5 puis 6 selon le public, nom deduit '
        'du genre et du creneau, creneaux libres mis en avant', (
      WidgetTester tester,
    ) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      await _ouvrir(tester, _surcharges(creation: creation));

      expect(_nom(tester), t.admin.groupes.typeEnfant);
      await _presser(tester, _cle('classe-genre-femmes'));
      expect(_nom(tester), t.admin.groupes.formulaire.genreFilles);
      await _presser(tester, _cle('classe-public-adulte'));
      expect(_nom(tester), t.admin.groupes.formulaire.genreFemmes);

      // L'enseignante choisie : ses creneaux libres en tete de la section.
      await _presser(tester, _cle('personne-f1'));
      expect(_cle('classe-libre-2-17'), findsOneWidget);
      expect(_cle('classe-libre-5-10'), findsOneWidget);
      await _presser(tester, _cle('classe-libre-5-10'));
      expect(_nom(tester), contains(t.admin.groupes.formulaire.genreFemmes));
      expect(_nom(tester), contains('vendredi'));

      final String nomPropose = _nom(tester);
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(creation.creations.single.seuilMax, 6);
      expect(creation.creations.single.libelle, nomPropose);
    });

    testWidgets('valeurs envoyees au port : enseignant, public, genre, nom, '
        'jour, heure, fuseau deduit, seuil choisi', (
      WidgetTester tester,
    ) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      await _ouvrir(tester, _surcharges(creation: creation));
      await _presser(tester, _cle('classe-public-adulte'));
      await _presser(tester, _cle('classe-genre-hommes'));
      await _presser(tester, _cle('personne-h1'));
      expect(
        find.text(
          t.admin.groupes.formulaire.fuseauEnseignant(fuseau: _casablanca),
        ),
        findsOneWidget,
      );
      await _presser(tester, _cle('classe-libre-4-18'));
      await _presser(tester, find.byKey(SelecteurEntier.clePuce(4)));
      await tester.enterText(_champNom, 'Al-Fajr');
      await tester.pumpAndSettle();
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);

      final CreationRecue c = creation.creations.single;
      expect(c.teacherId, 'h1');
      expect(c.type, TypePublicGroupe.adulte);
      expect(c.genre, GenreClasse.hommes);
      expect(c.libelle, 'Al-Fajr');
      expect(c.creneau.jour, 4);
      expect(c.creneau.heure, 18);
      expect(c.creneau.fuseau, _casablanca);
      expect(c.seuilMax, 4);
      // La feuille se ferme apres la creation.
      expect(_envoyer, findsNothing);
    });

    // D2 (29/10/2026) : trois creneaux par semaine par defaut, a des jours
    // fixes ; les deux suivants partent avec le premier.
    testWidgets('trois creneaux : les deux suivants partent au port, un '
        'creneau incomplet ou en double se dit', (WidgetTester tester) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      final f = t.admin.groupes.formulaire;
      await _ouvrir(tester, _surcharges(creation: creation));
      await _presser(tester, _cle('classe-public-adulte'));
      await _presser(tester, _cle('classe-genre-hommes'));
      await _presser(tester, _cle('personne-h1'));
      await _presser(tester, _cle('classe-libre-4-18'));
      expect(find.text(f.autresCreneauxTitre), findsOneWidget);
      // Les deux lignes vides : le creneau 2 manque.
      await _presser(tester, _envoyer);
      expect(find.text(f.manqueAutreCreneau(n: 2)), findsOneWidget);
      expect(creation.creations, isEmpty);

      Future<void> ligne(int numero, int jour, int heure) async {
        await _presser(tester, _cle('classe-autre-$numero-jour-$jour'));
        await _presser(tester, _cle('classe-autre-$numero-heure'));
        await _presser(tester, find.text(f.heureValeur(heure: '$heure')).last);
      }

      // Le creneau 2 au meme instant que le premier : en double.
      await ligne(2, 4, 18);
      await ligne(3, 6, 10);
      await _presser(tester, _envoyer);
      expect(find.text(f.creneauEnDouble), findsOneWidget);
      expect(creation.creations, isEmpty);

      await ligne(2, 1, 18);
      await _presser(tester, _envoyer);
      expect(creation.creations.single.creneau.jour, 4);
      final List<Creneau> autres = creation.autresCreneauxRecus.single;
      expect(
        autres.map((Creneau c) => (c.jour, c.heure, c.fuseau)).toList(),
        <(int, int, String)>[(1, 18, _casablanca), (6, 10, _casablanca)],
      );
    });

    // Duree par creneau (30/10/2026) : par defaut celle de la classe (nulle
    // au port) ; une autre duree vaut pour son creneau seulement.
    testWidgets('duree par creneau : la duree choisie part avec son creneau, '
        'les autres gardent celle de la classe', (WidgetTester tester) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      final f = t.admin.groupes.formulaire;
      await _ouvrir(tester, _surcharges(creation: creation));
      await _presser(tester, _cle('classe-public-adulte'));
      await _presser(tester, _cle('classe-genre-hommes'));
      await _presser(tester, _cle('personne-h1'));
      await _presser(tester, _cle('classe-libre-4-18'));
      expect(find.text(f.dureeContexte), findsOneWidget);
      await _presser(tester, _cle('classe-duree'));
      await _presser(tester, find.text(libelleDureeCreneau(45)).last);

      Future<void> ligne(int numero, int jour, int heure) async {
        await _presser(tester, _cle('classe-autre-$numero-jour-$jour'));
        await _presser(tester, _cle('classe-autre-$numero-heure'));
        await _presser(tester, find.text(f.heureValeur(heure: '$heure')).last);
      }

      await ligne(2, 1, 18);
      await ligne(3, 6, 10);
      await _presser(tester, _cle('classe-autre-3-duree'));
      await _presser(tester, find.text(libelleDureeCreneau(120)).last);
      await _presser(tester, _envoyer);
      expect(creation.dureesRecues.single, <int?>[45, null, 120]);
    });

    testWidgets('adaptateur reel : le fuseau affiche est celui que le serveur '
        'retient, et le service recoit les memes valeurs', (
      WidgetTester tester,
    ) async {
      final FauxGroupesFormL2 groupes = FauxGroupesFormL2();
      // Sans surcharge du port de creation : l'adaptateur par defaut
      // delegue a `ServiceGroupes.creer` (D1).
      await _ouvrir(tester, <Override>[
        ...surchargesFormL2(
          comptes: FauxComptesFormL2(comptesFormL2),
          groupes: groupes,
        ),
        portEnseignantsClasseProvider.overrideWithValue(
          FauxEnseignantsClasse(_enseignants),
        ),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ]);
      await _presser(tester, _cle('classe-genre-hommes'));
      await _presser(tester, _cle('personne-h1'));
      expect(
        find.text(
          t.admin.groupes.formulaire.fuseauNonTransmis(
            fuseau: fuseauServeurParDefaut,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(t.admin.groupes.formulaire.genreNonEnregistre),
        findsOneWidget,
      );
      await _presser(tester, _cle('classe-libre-2-17'));
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);

      final CreationRecue c = groupes.creations.single;
      expect(c.teacherId, 'h1');
      expect(c.type, TypePublicGroupe.enfant);
      expect(c.creneau.jour, 2);
      expect(c.creneau.heure, 17);
      expect(c.creneau.fuseau, fuseauServeurParDefaut);
      expect(c.seuilMax, 5);
      expect(c.libelle, isNotEmpty);
    });

    testWidgets('erreur de creation : la cause et quoi faire, la feuille '
        'reste ouverte avec les choix', (WidgetTester tester) async {
      final FauxCreationClasse creation = FauxCreationClasse(echecs: 1);
      await _ouvrir(tester, _surcharges(creation: creation));
      await _presser(tester, _cle('classe-genre-femmes'));
      await _presser(tester, _cle('personne-f1'));
      await _presser(tester, _cle('classe-libre-2-17'));
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);

      expect(
        find.text(
          t.admin.groupes.creerErreur(
            message: 'enseignant deja pris a ce creneau',
          ),
        ),
        findsOneWidget,
      );
      expect(creation.creations, isEmpty);
      expect(_envoyer, findsOneWidget);

      // Reessayer avec les memes choix aboutit.
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(creation.creations, hasLength(1));
    });

    testWidgets('hors ligne : pas de bouton qui ne peut aboutir, une phrase '
        'le dit ; les choix restent', (WidgetTester tester) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      await _ouvrir(tester, _surcharges(creation: creation, horsLigne: true));
      expect(find.text(t.admin.groupes.formulaire.horsLigne), findsOneWidget);
      expect(_envoyer, findsNothing);
      await _presser(tester, _cle('classe-genre-femmes'));
      expect(_nom(tester), t.admin.groupes.formulaire.genreFilles);
    });
  });

  group('Revue CLASSE-FORM-1 : choix gardes, collision, liste a jour', () {
    testWidgets('un nom tape n\'est jamais ecrase par un changement de '
        'genre, de public ou de creneau ; c\'est lui qui part', (
      WidgetTester tester,
    ) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      await _ouvrir(tester, _surcharges(creation: creation));
      await tester.enterText(_champNom, 'Al-Fajr');
      await tester.pumpAndSettle();
      await _presser(tester, _cle('classe-genre-femmes'));
      await _presser(tester, _cle('classe-public-adulte'));
      await _presser(tester, _cle('personne-f1'));
      await _presser(tester, _cle('classe-libre-5-10'));
      expect(_nom(tester), 'Al-Fajr');
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(creation.creations.single.libelle, 'Al-Fajr');
    });

    testWidgets('un seuil choisi n\'est jamais ecrase par un changement de '
        'public ; c\'est lui qui part', (WidgetTester tester) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      await _ouvrir(tester, _surcharges(creation: creation));
      await _presser(tester, find.byKey(SelecteurEntier.clePuce(3)));
      await _presser(tester, _cle('classe-public-adulte'));
      await _presser(tester, _cle('classe-genre-femmes'));
      await _presser(tester, _cle('personne-f1'));
      await _presser(tester, _cle('classe-libre-2-17'));
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(creation.creations.single.seuilMax, 3);
    });

    testWidgets('collision : un enseignant choisi puis deja en classe au '
        'creneau porte sa raison, et l\'envoi le dit par son nom', (
      WidgetTester tester,
    ) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      final f = t.admin.groupes.formulaire;
      await _ouvrir(tester, _surcharges(creation: creation));
      await _presser(tester, _cle('classe-genre-hommes'));
      await _presser(tester, _cle('personne-h2'));
      await _presser(tester, _cle('classe-jour-3'));
      await _heure(tester, 18);
      expect(
        find.descendant(
          of: _cle('personne-h2'),
          matching: find.text(f.raisonPris),
        ),
        findsOneWidget,
      );
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(
        find.text(f.manqueEnseignantPris(nom: 'Hamza Sow')),
        findsOneWidget,
      );
      expect(creation.creations, isEmpty);
    });

    testWidgets('genre change apres le choix : l\'envoi dit, par son nom, '
        'que l\'enseignante ne peut pas prendre une classe de garcons', (
      WidgetTester tester,
    ) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      await _ouvrir(tester, _surcharges(creation: creation));
      await _presser(tester, _cle('classe-genre-femmes'));
      await _presser(tester, _cle('personne-f1'));
      await _presser(tester, _cle('classe-libre-2-17'));
      await _presser(tester, _cle('classe-genre-hommes'));
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(
        find.text(
          t.admin.groupes.formulaire.manqueEnseignantGarcons(
            nom: 'Fatima Diallo',
          ),
        ),
        findsOneWidget,
      );
      expect(creation.creations, isEmpty);
    });

    testWidgets('liste qui se recharge apres un changement de public : '
        'rien ne part, le message le dit', (WidgetTester tester) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      final _PortParPublic port = _PortParPublic();
      await _ouvrir(tester, _surcharges(creation: creation, port: port));
      await _presser(tester, _cle('classe-genre-femmes'));
      await _presser(tester, _cle('personne-f1'));
      await _presser(tester, _cle('classe-libre-2-17'));
      // La source des adultes ne repond pas encore.
      await _presser(tester, _cle('classe-public-adulte'));
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(
        find.text(t.admin.groupes.formulaire.manqueListeEnseignants),
        findsOneWidget,
      );
      expect(creation.creations, isEmpty);
    });

    testWidgets('demonstration : la classe creee rend l\'enseignante prise '
        'a ce creneau a la reouverture, et le genre est retenu', (
      WidgetTester tester,
    ) async {
      final ClassesCreeesDemo creees = ClassesCreeesDemo();
      final EnseignantsClasseDemo port = EnseignantsClasseDemo(creees);
      int charge(List<EnseignantPropose> l) => l
          .firstWhere((EnseignantPropose e) => e.id == 'demo-ens-1')
          .classesActives;
      final int avant = charge(
        await port.pourClasse(public: TypePublicGroupe.enfant),
      );
      final f = t.admin.groupes.formulaire;
      await _ouvrir(tester, <Override>[
        ...surchargesFormL2(comptes: FauxComptesFormL2(comptesFormL2)),
        groupesProvider.overrideWith((Ref ref) async => creees.toutes()),
        portEnseignantsClasseProvider.overrideWithValue(port),
        portCreationClasseProvider.overrideWithValue(
          CreationClasseDemo(creees),
        ),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ]);
      await _presser(tester, _cle('classe-genre-femmes'));
      await _presser(tester, _cle('personne-demo-ens-1'));
      await _presser(tester, _cle('classe-libre-1-17'));
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(_envoyer, findsNothing);
      final String id = creees.groupes.single.id;
      expect(creees.genreDe(id), GenreClasse.femmes);

      // Reouverture : meme creneau, l'enseignante est prise.
      await _presser(tester, find.text(t.admin.groupes.creer).first);
      await _presser(tester, _cle('classe-genre-femmes'));
      await _presser(tester, _cle('classe-jour-1'));
      await _heure(tester, 17);
      expect(
        find.descendant(
          of: _cle('personne-demo-ens-1'),
          matching: find.text(f.raisonPris),
        ),
        findsOneWidget,
      );
      expect(
        charge(await port.pourClasse(public: TypePublicGroupe.enfant)),
        avant + 1,
      );
    });
  });

  group('CAND-Q15 : genre non renseigne et refus du serveur', () {
    testWidgets('genre non renseigne : visible, avec sa raison, et ne se '
        'choisit pas, meme pour une classe sans genre', (
      WidgetTester tester,
    ) async {
      final FauxCreationClasse creation = FauxCreationClasse();
      final f = t.admin.groupes.formulaire;
      await _ouvrir(tester, _surcharges(creation: creation));
      await _presser(tester, _cle('classe-genre-mixte'));
      await _presser(tester, _cle('classe-jour-2'));
      await _heure(tester, 17);
      expect(
        find.descendant(
          of: _cle('personne-x1'),
          matching: find.text(f.raisonGenreInconnu),
        ),
        findsOneWidget,
      );
      // Toucher la personne ne la retient pas : rien ne part.
      await _presser(tester, _cle('personne-x1'));
      await _unSeulCreneau(tester);
      await _presser(tester, _envoyer);
      expect(find.text(t.admin.groupes.manqueEnseignant), findsOneWidget);
      expect(creation.creations, isEmpty);
    });

    for (final MotifRefusCreationClasse motif in <MotifRefusCreationClasse>[
      MotifRefusCreationClasse.plafond,
      MotifRefusCreationClasse.chevauchementSeance,
      MotifRefusCreationClasse.inconnu,
    ]) {
      testWidgets('refus du serveur (${motif.name}) : sa phrase, jamais le '
          'texte SQL ; la feuille garde les choix et presser de nouveau '
          'renvoie', (WidgetTester tester) async {
        final _CreationRefusee creation = _CreationRefusee(motif);
        await _ouvrir(tester, _surcharges(creation: creation));
        await _presser(tester, _cle('classe-genre-femmes'));
        await _presser(tester, _cle('personne-f1'));
        await _presser(tester, _cle('classe-libre-2-17'));
        final String nom = _nom(tester);
        await _unSeulCreneau(tester);
        await _presser(tester, _envoyer);

        final String attendu = switch (motif) {
          MotifRefusCreationClasse.plafond =>
            t.admin.groupes.refusCreation.plafond,
          MotifRefusCreationClasse.chevauchementSeance =>
            t.admin.groupes.refusCreation.chevauchementSeance,
          _ => t.admin.groupes.refusCreation.inconnu,
        };
        expect(find.text(attendu), findsOneWidget);
        for (final String sql in <String>[
          'plafond horaire',
          'chevauchement avec',
          'CreationClasseRefusee',
          'MotifRefusCreationClasse',
        ]) {
          expect(find.textContaining(sql), findsNothing);
        }
        expect(creation.creations, isEmpty);
        expect(_envoyer, findsOneWidget);
        expect(_nom(tester), nom);

        await _unSeulCreneau(tester);

        await _presser(tester, _envoyer);
        expect(creation.creations, hasLength(1));
        expect(creation.creations.single.teacherId, 'f1');
      });
    }
  });

  group(
    'Chemin de production : source indisponible, repli sur les comptes',
    () {
      List<Override> production(FauxComptesFormL2 comptes) => <Override>[
        ...surchargesFormL2(comptes: comptes),
        serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
      ];

      testWidgets('repli : les enseignants actifs, sans « premier choix », et '
          'des textes qui ne promettent ni filtre de genre ni classement par '
          'creneau', (WidgetTester tester) async {
        final f = t.admin.groupes.formulaire;
        await _ouvrir(tester, production(FauxComptesFormL2(comptesFormL2)));
        expect(_cle('personne-t-amina'), findsOneWidget);
        expect(_cle('personne-t-yacine'), findsOneWidget);
        final String premierChoix = f
            .plusAdapteSansCreneau(libres: '\u0000', charge: '')
            .split('\u0000')
            .first;
        expect(find.textContaining(premierChoix), findsNothing);
        expect(_texteLu(f.aideEnseignantSansSource), findsOneWidget);
        expect(_texteLu(f.aideEnseignant), findsNothing);
        expect(_texteLu(f.genreFillesDetailSansSource), findsOneWidget);
        expect(_texteLu(f.genreFillesDetail), findsNothing);
      });

      testWidgets('aucun enseignant actif : etat vide', (
        WidgetTester tester,
      ) async {
        await _ouvrir(
          tester,
          production(FauxComptesFormL2(const <CompteAdmin>[])),
        );
        expect(
          find.text(t.commun.selecteurPersonne.videEnseignant),
          findsOneWidget,
        );
      });

      testWidgets('source qui ne repond pas encore : squelette', (
        WidgetTester tester,
      ) async {
        await _ouvrir(tester, <Override>[
          ...production(FauxComptesFormL2(comptesFormL2)),
          portEnseignantsClasseProvider.overrideWithValue(_PortParPublic()),
        ]);
        await _presser(tester, _cle('classe-public-adulte'));
        expect(
          find.descendant(
            of: find.byType(SelecteurPersonne),
            matching: find.byType(Skeleton),
          ),
          findsWidgets,
        );
      });

      testWidgets('echec de la source (autre que « indisponible ») : l\'echec '
          'se voit, sans repli silencieux', (WidgetTester tester) async {
        await _ouvrir(tester, <Override>[
          ...production(FauxComptesFormL2(comptesFormL2)),
          portEnseignantsClasseProvider.overrideWithValue(_PortEnEchec()),
        ]);
        expect(
          find.text(t.commun.selecteurPersonne.erreurEnseignantTitre),
          findsOneWidget,
        );
        expect(_cle('personne-t-amina'), findsNothing);
      });
    },
  );

  group('La feuille « Seuil maximal » (D7, K-56)', () {
    testWidgets('meme selecteur 1 a 6, valeur actuelle retenue, bouton actif', (
      WidgetTester tester,
    ) async {
      final FauxGroupesFormL2 groupes = FauxGroupesFormL2();
      tester.view.physicalSize = const Size(1440, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_hote(_surcharges(groupes: groupes)));
      await tester.pumpAndSettle();
      await _presser(tester, find.byType(MenuActions).first);
      await _presser(
        tester,
        find.text(t.admin.groupes.actionModifierSeuil).last,
      );

      for (int n = 1; n <= 6; n++) {
        expect(find.byKey(SelecteurEntier.clePuce(n)), findsOneWidget);
      }
      // 1 a 6 couvre tout : pas de saisie libre.
      expect(find.byKey(SelecteurEntier.cleAutre), findsNothing);
      await _presser(tester, find.byKey(SelecteurEntier.clePuce(3)));
      await _presser(
        tester,
        find.text(t.admin.groupes.modifierSeuilEnvoyer).last,
      );
      expect(groupes.seuilsModifies, <int>[3]);
    });

    // CLASSES-DUREE (23/10/2026) : la feuille renvoie l'horaire qu'elle a lu ;
    // si la classe a ete deplacee entre-temps, le serveur repasse le predicat
    // d'affectation et peut refuser. Une phrase par motif, jamais le SQL.
    for (final MotifRefusAffectation motif in <MotifRefusAffectation>[
      MotifRefusAffectation.nonDisponible,
      MotifRefusAffectation.chevauchementClasse,
      MotifRefusAffectation.chevauchementSeance,
      MotifRefusAffectation.plafond,
      MotifRefusAffectation.genreIncompatible,
      MotifRefusAffectation.enseignantIndisponible,
    ]) {
      testWidgets('refus de deplacement (${motif.name}) : sa phrase, la '
          'feuille reste ouverte, rien n\'est enregistre', (
        WidgetTester tester,
      ) async {
        final FauxGroupesFormL2 groupes = FauxGroupesFormL2()
          ..echecModification = AffectationRefusee(motif);
        tester.view.physicalSize = const Size(1440, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_hote(_surcharges(groupes: groupes)));
        await tester.pumpAndSettle();
        await _presser(tester, find.byType(MenuActions).first);
        await _presser(
          tester,
          find.text(t.admin.groupes.actionModifierSeuil).last,
        );
        await _presser(tester, find.byKey(SelecteurEntier.clePuce(3)));
        await _presser(
          tester,
          find.text(t.admin.groupes.modifierSeuilEnvoyer).last,
        );

        // La feuille ne change que le seuil : quel que soit le motif, sa phrase
        // le dit (jamais « l'horaire n'est pas change »).
        final String attendu = t.admin.groupes.refusDeplacement.seuil;
        expect(find.text(attendu), findsOneWidget);
        for (final String sql in <String>[
          'enseignant non disponible',
          'chevauchement avec',
          'AffectationRefusee',
          'MotifRefusAffectation',
        ]) {
          expect(find.textContaining(sql), findsNothing);
        }
        expect(groupes.seuilsModifies, isEmpty);
        expect(find.text(t.admin.groupes.modifierSeuilEnvoyer), findsWidgets);
      });
    }
  });

  group('CLASSE-FORM-1 : gardes de rendu', () {
    for (final (Size vue, String nom) in <(Size, String)>[
      (const Size(320, 800), '320'),
      (const Size(1440, 900), '1440'),
    ]) {
      for (final double echelle in <double>[1, 2]) {
        for (final ThemeMode theme in <ThemeMode>[
          ThemeMode.light,
          ThemeMode.dark,
        ]) {
          testWidgets('$nom x${echelle.toInt()} ${theme.name} : feuille '
              'lisible, sans debordement, un seul bouton plein par feuille', (
            WidgetTester tester,
          ) async {
            await _ouvrir(
              tester,
              _surcharges(),
              vue: echelle == 2 && nom == '320' ? const Size(320, 2400) : vue,
              theme: theme,
              echelle: echelle,
            );
            await _presser(tester, _cle('classe-genre-femmes'));
            await _presser(tester, _cle('personne-f1'));
            await _presser(tester, _cle('classe-libre-2-17'));

            expect(tester.takeException(), isNull);
            final Finder feuille = find.byType(AppBottomSheet);
            expect(feuille, findsOneWidget);
            expect(
              motsCoupes(
                tester,
                feuille,
                traitDUnionPermis: true,
                // L'indication du champ de recherche de `SelecteurPersonne`
                // (FORM-L2, inchangee) : `hintText` ne passe pas par
                // `TexteSansCoupure`, et la police de test est bien plus
                // large que la vraie ; les captures FORM-L2 la mesurent.
                exceptions: <String>{
                  t.commun.selecteurPersonne.rechercheEnseignant,
                },
              ),
              isEmpty,
            );
            // La feuille posee sur sa page : son bouton et celui de la page.
            verifierUnSeulBoutonPlein(tester, maximum: 2);
          });
        }
      }
    }
  });
}
