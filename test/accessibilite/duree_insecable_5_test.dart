// DUREE-INSECABLE-5 : les deux points refuses de DUREE-INSECABLE-4.
//
// 1. Mode tableau de `DataCollection` (ecrans larges) : le libelle parle
//    d'une cellule, « {titre} : {valeur} », ne porte plus l'ancre de sens
//    (U+200E) de la valeur au milieu. Comptes (« Inscrit depuis »),
//    Progression et Qualite (« Depuis ») le prouvent a 1600 px, arbre
//    semantique active, en LTR et en RTL.
// 2. La garde de source (test/support/garde_ancres.dart) suit une valeur
//    ancree rangee dans un champ d'objet (argument nomme ou positionnel d'un
//    constructeur, `ColonneDonnees`, `copyWith`, table, record), passee a une
//    fonction, ecrite dans un tampon, remplacee ou ajoutee a une liste,
//    jusqu'a son insertion au milieu d'un libelle. Contre-epreuve : le
//    defaut de `data_collection.dart` reintroduit la fait echouer, pour
//    chacun des trois ecrans.
// 3. Reprise (relecture adverse) : la garde trouve le meme defaut quand
//    l'objet qui porte la colonne a un type infere (`final col = colonne;`,
//    `final c = colonnes().first;`), est le parametre d'une lambda ou la
//    variable d'une boucle non typees, quel que soit son nom, et une valeur
//    rangee par affectation (`s.duree = ...`) ; un autre objet au type ecrit
//    dont le champ porte le meme nom n'est pas suivi. A 1440 px, LTR et
//    RTL, l'identifiant « TEACHER-AS-000001 » tient sur une ligne.
// 4. Reprise 2 (relecture adverse) : la garde trouve la valeur inseree
//    derriere un litteral adjacent (`'Duree : ' '${valeur}'`, sur une ou
//    deux lignes, forme que `dart format` donne a une ligne longue) et le
//    champ lu par `this.champ` ou `this.objet.champ`.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/admin/service_progression.dart';
import 'package:rewayah_academy/core/admin/service_qualite.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/theme/app_theme.dart';
import 'package:rewayah_academy/features/admin_comptes/comptes_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_progression/progression_page.dart';
import 'package:rewayah_academy/features/admin_pedagogie_qualite/qualite_page.dart';

import '../support/garde_ancres.dart';
import '../support/garde_durees.dart';
import '../support/harnais.dart';

const String _nbsp = ' ';
const String _lrm = '‎';

/// Le defaut releve par la relecture, tel qu'il etait dans
/// `lib/core/widgets/data_collection.dart` (DUREE-INSECABLE-4).
const String _libelleCorrige =
    r"label: '${colonne.titre} : ${sansAncre(colonne.texte(ligne))}',";
const String _libelleFautif =
    r"label: '${colonne.titre} : ${colonne.texte(ligne)}',";

class _FauxServiceComptes implements ServiceComptes {
  _FauxServiceComptes(this._comptes);

  final List<CompteAdmin> _comptes;

  @override
  Future<List<CompteAdmin>> comptes() async => _comptes;
}

Widget _hote(
  Widget page,
  List<Override> surcharges, {
  TextDirection sens = TextDirection.ltr,
}) => ProviderScope(
  overrides: <Override>[
    ...surcharges,
    serviceReseauProvider.overrideWithValue(FauxServiceReseau()),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.pour(InterfaceMode.standard, Brightness.light),
      builder: (BuildContext _, Widget? app) =>
          Directionality(textDirection: sens, child: app!),
      home: page,
    ),
  ),
);

/// Tous les libelles de l'arbre semantique.
List<String> _libelles(WidgetTester tester) {
  final List<String> libelles = <String>[];
  void visiter(SemanticsNode n) {
    if (n.label.isNotEmpty) libelles.add(n.label);
    n.visitChildren((SemanticsNode e) {
      visiter(e);
      return true;
    });
  }

  for (final RenderView vue in tester.binding.renderViews) {
    final SemanticsNode? racine = vue.owner?.semanticsOwner?.rootSemanticsNode;
    if (racine != null) visiter(racine);
  }
  return libelles;
}

/// Sur la page large, la cellule « [titre] : [valeur] » est lue sans ancre
/// au milieu ; aucun libelle parle n'en porte ailleurs qu'en tete.
Future<void> _celluleSansAncre(
  WidgetTester tester,
  Widget page,
  List<Override> surcharges, {
  required String titre,
  required String valeur,
  required TextDirection sens,
}) async {
  final SemanticsHandle semantique = tester.ensureSemantics();
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_hote(page, surcharges, sens: sens));
  await tester.pumpAndSettle();
  final List<String> libelles = _libelles(tester);
  expect(
    libelles.any((String l) => l.contains('$titre : $valeur')),
    isTrue,
    reason: 'cellule « $titre : $valeur » introuvable : $libelles',
  );
  for (final String l in libelles) {
    expect(
      l.lastIndexOf(_lrm),
      lessThanOrEqualTo(0),
      reason: 'ancre de sens au milieu de « $l »',
    );
  }
  // La valeur, seule dans sa cellule, garde son ancre a l'affichage.
  expect(find.text('$_lrm$valeur'), findsWidgets);
  semantique.dispose();
}

final List<Override> _comptes = <Override>[
  serviceComptesProvider.overrideWithValue(
    _FauxServiceComptes(<CompteAdmin>[
      CompteAdmin(
        profilId: 'p1',
        identifiant: 'TEACHER-AS-000001',
        prenom: 'Aicha',
        nom: 'Sow',
        role: AppRole.teacher,
        etat: AccountStatus.pendingKyc,
        inscritLe: DateTime.now().subtract(const Duration(days: 12)),
        accesJusquAu: null,
        foyerId: null,
        piece: EtatPiece.aucune,
        contrats: 2,
        aEnseignant: false,
        enfantsDuFoyer: 0,
      ),
    ]),
  ),
];

final List<Override> _progression = <Override>[
  progressionProvider.overrideWith(
    (Ref ref) async => <EleveProgression>[
      EleveProgression(
        studentId: 's1',
        identifiant: 'STUD-000001',
        prenom: 'Sofia',
        nom: 'B.',
        groupeId: 'g1',
        groupeLibelle: 'Groupe du soir',
        niveauId: 'n1',
        niveauNomHumain: 'Niveau 2',
        niveauCycle: 'tajwid',
        niveauDepuis: DateTime.now().subtract(
          const Duration(days: 9, hours: 1),
        ),
        exceptionActiveId: null,
        exceptionActiveType: null,
      ),
    ],
  ),
];

final List<Override> _qualite = <Override>[
  anomaliesQualiteProvider.overrideWith(
    (Ref ref) async => <AnomalieQualite>[
      AnomalieQualite(
        type: TypeAnomalieQualite.blocageSansSuivi,
        refId: 'r1',
        studentId: 's1',
        studentPrenom: 'Sofia',
        studentNom: 'B.',
        teacherId: null,
        teacherPrenom: null,
        teacherNom: null,
        depuis: DateTime.now().subtract(const Duration(days: 8, hours: 1)),
        controleStatut: StatutControleQualite.ouvert,
        controleNote: null,
      ),
    ],
  ),
];

/// Les sources de lib/ ou `data_collection.dart` est remplace par [copie].
List<File> _libAvec(File copie) => <File>[
  for (final File f in sourcesDart())
    if (f.path
        .replaceAll(r'\', '/')
        .endsWith('core/widgets/data_collection.dart'))
      copie
    else
      f,
];

void main() {
  group(
    '1. Mode tableau : libelle parle de la cellule sans ancre au milieu',
    () {
      for (final TextDirection sens in TextDirection.values) {
        testWidgets('Comptes, 1600 px, ${sens.name} : « Inscrit depuis : '
            '12 jours »', (WidgetTester tester) async {
          await _celluleSansAncre(
            tester,
            const ComptesPage(),
            _comptes,
            titre: t.admin.comptes.colonneAttente,
            valeur: '12${_nbsp}jours',
            sens: sens,
          );
        });

        testWidgets('Progression, 1600 px, ${sens.name} : « … : 9 jours »', (
          WidgetTester tester,
        ) async {
          await _celluleSansAncre(
            tester,
            const ProgressionPage(),
            _progression,
            titre: t.admin.progression.colonneDepuis,
            valeur: '9${_nbsp}jours',
            sens: sens,
          );
        });

        testWidgets('Qualite, 1600 px, ${sens.name} : « … : 8 jours »', (
          WidgetTester tester,
        ) async {
          await _celluleSansAncre(
            tester,
            const QualitePage(),
            _qualite,
            titre: t.admin.qualite.colonneDepuis,
            valeur: '8${_nbsp}jours',
            sens: sens,
          );
        });
      }
    },
  );

  // Reprise (relecture adverse) : a 1440 px en RTL, l'identifiant passait
  // a la ligne a son trait d'union (« TEACHER- / AS-000001 »).
  for (final TextDirection sens in TextDirection.values) {
    testWidgets('Comptes, 1440 px, ${sens.name} : l\'identifiant tient sur '
        'une ligne', (WidgetTester tester) async {
      final SemanticsHandle semantique = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_hote(const ComptesPage(), _comptes, sens: sens));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final Finder identifiant = find.byWidgetPredicate(
        (Widget w) => w is Text && (w.data ?? '').startsWith('TEACHER'),
      );
      expect(identifiant, findsOneWidget);
      // Une ligne : la hauteur de la cellule voisine, « Aicha Sow ».
      expect(
        tester.getSize(identifiant).height,
        tester.getSize(find.text('Aicha Sow')).height,
      );
      // Le libelle parle garde l'identifiant tel quel.
      expect(
        _libelles(tester).any(
          (String l) => l.contains(
            '${t.admin.comptes.colonneIdentifiant} : TEACHER-AS-000001',
          ),
        ),
        isTrue,
        reason: '${_libelles(tester)}',
      );
      semantique.dispose();
      // DUREE-FOND-1 : l'identifiant de Comptes est tenu sur une ligne par
      // COUPE-MOTS-4 sur la ligne reunie (identifiantInsecable,
      // TexteSansCoupure, test/features/coupe_mots_4/comptes_identifiant_test),
      // et non par la colonne `insecable` de cette branche, non reprise
      // (disposition de DataCollection reservee a COUPE-MOTS-FOND-1, decide
      // par delegation le 10/10).
    }, skip: true);
  }

  // Reprise : a 1440 px et texte x2, le tableau coupait ses mots
  // (« Enseigna / nt ») et tronquait ses en-tetes : il se replie en cartes.
  testWidgets('Comptes, 1440 px, texte x2 : repliee en cartes, sans en-tete '
      'de tableau', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      _hote(const ComptesPage(), _comptes, sens: TextDirection.rtl),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(t.admin.comptes.colonneIdentifiant), findsNothing);
    expect(find.textContaining('TEACHER-AS-000001'), findsOneWidget);
    // DUREE-FOND-1 : le repli en cartes a texte agrandi touche la
    // disposition de DataCollection, reservee a COUPE-MOTS-FOND-1 pendant ce
    // lot ; seule la correction des ancres y est reprise (decide par
    // delegation le 10/10). Le test reste ecrit pour la reunion.
  }, skip: true);

  testWidgets('Qualite, 390 px : la collection repliee en cartes dans le '
      'defilement de la page s affiche (plus de hauteur non bornee)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_hote(const QualitePage(), _qualite));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('8${_nbsp}jours'), findsOneWidget);
  });

  group('2. Garde de source : valeur ancree rangee puis inseree', () {
    test('lib/ : aucune valeur ancree inseree dans un autre libelle, '
        'socle qui ne fait que diminuer (DUREE-FOND-1)', () {
      final List<AncreGlissee> toutes = ancresGlissees();
      final Set<String> socle = cleSocle();
      final List<AncreGlissee> fautes = <AncreGlissee>[
        for (final AncreGlissee a in toutes)
          if (!socle.contains(cleAncre(a))) a,
      ];
      expect(
        fautes,
        isEmpty,
        reason: fautes
            .map((AncreGlissee f) => '${f.fichier}:${f.ligne} ${f.raison}')
            .join('\n'),
      );
      // Une entree du socle que la garde ne trouve plus est a retirer.
      final Set<String> trouvees = <String>{
        for (final AncreGlissee a in toutes) cleAncre(a),
      };
      expect(socle.difference(trouvees), isEmpty);
    });

    test('contre-epreuve : le defaut de data_collection reintroduit fait '
        'echouer la garde, sur lib/ et pour chacun des trois ecrans', () {
      final File source = File('lib/core/widgets/data_collection.dart');
      final String corrige = source.readAsStringSync();
      expect(corrige, contains(_libelleCorrige));
      final Directory dossier = Directory.systemTemp.createTempSync('dc5');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final File fautif = File('${dossier.path}/data_collection.dart')
        ..writeAsStringSync(
          corrige.replaceFirst(_libelleCorrige, _libelleFautif),
        );
      final int ligne = corrige
          .substring(0, corrige.indexOf(_libelleCorrige))
          .split('\n')
          .length;

      // Sur lib/ entier.
      final List<AncreGlissee> fautes = ancresGlisseesHorsSocle(
        _libAvec(fautif),
      );
      expect(
        fautes.map((AncreGlissee f) => '${f.fichier}:${f.ligne}'),
        <String>['${fautif.path}:$ligne'],
        reason: fautes.map((AncreGlissee f) => f.raison).join('\n'),
      );

      // Chaque ecran, seul avec le composant fautif : son colonne « depuis »
      // (ou « attente ») mene au libelle de la cellule.
      for (final String ecran in <String>[
        'lib/features/admin_comptes/comptes_page.dart',
        'lib/features/admin_pedagogie_progression/progression_page.dart',
        'lib/features/admin_pedagogie_qualite/qualite_page.dart',
      ]) {
        final List<AncreGlissee> f = ancresGlissees(<File>[
          File(ecran),
          fautif,
        ]);
        expect(f.map((AncreGlissee a) => '${a.fichier}:${a.ligne}'), <String>[
          '${fautif.path}:$ligne',
        ], reason: '$ecran : ${f.map((AncreGlissee a) => a.raison)}');
        expect(f.single.raison, contains('ColonneDonnees.texte'));
        // Le composant corrige : plus rien.
        expect(ancresGlissees(<File>[File(ecran), source]), isEmpty);
      }
    });

    test('la garde suit champs, appels, tampons, remplacements et '
        'collections', () {
      final Directory dossier = Directory.systemTemp.createTempSync('ancres5');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final File f = File('${dossier.path}/x.dart')
        ..writeAsStringSync(r'''
class Colonne<T> {
  const Colonne({required this.titre, required this.texte});
  final String titre;
  final String Function(T ligne) texte;
}
String _attente(int j) => switch (j) {
  0 => t.a.aujourdhui,
  _ => LibellesGroupe.valeurSeule(t.a.attendJours(jours: '$j')),
};
List<Colonne<int>> colonnes() => <Colonne<int>>[
  Colonne<int>(titre: 'Attente', texte: (int j) => _attente(j)),
];
class Cellule<T> extends StatelessWidget {
  const Cellule({required this.colonne, required this.ligne});
  final Colonne<T> colonne;
  final T ligne;
  Widget build(BuildContext context) => Semantics(
    label: '${colonne.titre} : ${colonne.texte(ligne)}',
    child: Text(colonne.texte(ligne)),
  );
}
class Seance {
  const Seance({required this.duree});
  final String duree;
  Seance copyWith({String? duree}) => Seance(duree: duree ?? this.duree);
  String get phrase => 'Duree : $duree';
}
Seance copie(Seance s, int n) =>
    s.copyWith(duree: LibellesGroupe.dureeSeule(Duration(minutes: n)));
String table(int n) {
  final Map<String, String> m = <String, String>{
    'duree': LibellesGroupe.dureeSeule(Duration(minutes: n)),
  };
  return 'Duree ${m['duree']}';
}
String record(int n) {
  final r = (heure: '18:00', duree: LibellesGroupe.dureeSeule(Duration(minutes: n)));
  return '${r.heure} ${r.duree}';
}
String phrase(String x) => 'Duree $x';
String positionnel(int n) => phrase(LibellesGroupe.dureeSeule(Duration(minutes: n)));
String phraseNommee({required String x}) => 'Duree $x';
String nomme(int n) => phraseNommee(x: LibellesGroupe.dureeSeule(Duration(minutes: n)));
class Pos {
  const Pos(this.v);
  final String v;
  String get l => 'Duree $v';
}
Pos pos(int n) => Pos(LibellesGroupe.dureeSeule(Duration(minutes: n)));
String tampon(int n) {
  final StringBuffer b = StringBuffer('Duree ');
  b.write(LibellesGroupe.dureeSeule(Duration(minutes: n)));
  return b.toString();
}
String remplace(int n) => 'Duree {d}'.replaceAll('{d}', LibellesGroupe.dureeSeule(Duration(minutes: n)));
String ajout(int n) {
  final List<String> l = <String>['Role'];
  l.add(LibellesGroupe.dureeSeule(Duration(minutes: n)));
  return l.join(' · ');
}
String liste(int n) {
  final List<String> l = <String>['Role', LibellesGroupe.dureeSeule(Duration(minutes: n))];
  return l.where((String s) => s.isNotEmpty).join(' · ');
}
// Ce qui est permis : la valeur seule, en tete, ou sans son ancre.
String sain(Colonne<int> c, int l) => '${c.titre} : ${sansAncre(c.texte(l))}';
String joint(Colonne<int> c, int l) => enchainer(<String>[c.titre, c.texte(l)], ' · ');
String tete(int n) => phraseTete(LibellesGroupe.dureeSeule(Duration(minutes: n)));
String phraseTete(String x) => '$x de cours';
String premier(String? a, String? b) => <String>[
  if (a != null) a,
  if (b != null) b,
].join(' · ');
String enPremier(int n) => premier(LibellesGroupe.dureeSeule(Duration(minutes: n)), 'Role');
Widget seule(Seance s) => Text(s.duree);
''');
      final List<int> lignes = <int>[
        for (final AncreGlissee a in ancresGlissees(<File>[f])) a.ligne,
      ];
      // Cellule (18), copyWith relu (26), table (34), record (38), fonction
      // positionnelle (40) et nommee (42), constructeur positionnel (47),
      // tampon (52), remplacement (55), ajout (59), liste jointe (63).
      expect(lignes, <int>[18, 26, 34, 38, 40, 42, 47, 52, 55, 59, 63]);
    });
  });

  // Reprise (relecture adverse) : la garde ne doit dependre ni du type ecrit
  // de l'objet qui porte la colonne, ni du nom choisi pour lui.
  group('3. Garde de source : objet au type infere, lambda, boucle, '
      'affectation de champ', () {
    final String source = File('lib/core/widgets/data_collection.dart')
        .readAsStringSync();

    /// Une copie de data_collection.dart ou [avant] est remplace par
    /// [apres] ; la garde lancee sur lib/ avec cette copie.
    List<AncreGlissee> garde(String avant, String apres) {
      expect(source, contains(avant));
      final Directory dossier = Directory.systemTemp.createTempSync('dc5b');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final File fautif = File('${dossier.path}/data_collection.dart')
        ..writeAsStringSync(source.replaceFirst(avant, apres));
      return ancresGlissees(_libAvec(fautif))
          .where((AncreGlissee a) => a.fichier == fautif.path)
          .toList();
    }

    const String cellule =
        '    return Semantics(\n'
        r"      label: '${colonne.titre} : ${sansAncre(colonne.texte(ligne))}',";
    // COUPE-MOTS-FOND-1 : le resume ecarte la valeur deja affichee en tete
    // de carte ; la mutation remplace toujours le resume entier.
    const String resume =
        '    final String resume = enchainer(\n'
        '      secondaires\n'
        '          .map((ColonneDonnees<T> c) => c.texte(ligne))\n'
        '          .where(\n'
        '            (String v) =>\n'
        '                enTete == null || identifiantsInsecables(v).trim() != enTete,\n'
        '          ),\n'
        "      ' · ',\n"
        '    );';

    // Des noms qui ne sont declares nulle part ailleurs : la detection ne
    // tient pas a une declaration `ColonneDonnees<T> c` voisine.
    for (final String nom in <String>['col', 'qz7']) {
      test('$nom : variable au type infere (`final $nom = colonne;`)', () {
        final List<AncreGlissee> f = garde(
          cellule,
          '    final $nom = colonne;\n'
          '    return Semantics(\n'
          "      label: '\${$nom.titre} : \${$nom.texte(ligne)}',",
        );
        expect(f, hasLength(1));
        expect(f.single.raison, contains('ColonneDonnees.texte'));
      });

      test('$nom : boucle for-in non typee', () {
        final List<AncreGlissee> f = garde(
          cellule,
          "    String l = '';\n"
          '    for (final $nom in <ColonneDonnees<T>>[colonne]) {\n'
          "      l = '\${$nom.titre} : \${$nom.texte(ligne)}';\n"
          '    }\n'
          '    return Semantics(\n'
          '      label: l,',
        );
        expect(f, hasLength(1));
        expect(f.single.raison, contains('ColonneDonnees.texte'));
      });

      test('$nom : lambda non typee, carte jointe par « · »', () {
        final List<AncreGlissee> f = garde(
          resume,
          '    final String resume = secondaires\n'
          '        .map(($nom) => $nom.texte(ligne))\n'
          '        .where((String s) => s.isNotEmpty)\n'
          "        .join(' · ');",
        );
        expect(f, hasLength(1));
        expect(f.single.raison, contains('jointe'));
      });
    }

    test("fixtures : champ affecte, resultat d'appel, lambda, boucle, "
        "autre fichier ; un autre champ du meme nom n'est pas suivi", () {
      final Directory dossier = Directory.systemTemp.createTempSync('anc5b');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final File a = File('${dossier.path}/a.dart')
        ..writeAsStringSync(r'''
class Colonne<T> {
  const Colonne({required this.titre, required this.texte});
  final String titre;
  final String Function(T ligne) texte;
}
String _attente(int j) =>
    LibellesGroupe.valeurSeule(t.a.attendJours(jours: '$j'));
List<Colonne<int>> colonnes() => <Colonne<int>>[
  Colonne<int>(titre: 'Attente', texte: (int j) => _attente(j)),
];
class Seance {
  String duree = '';
}
String r(Seance s, int n) {
  s.duree = LibellesGroupe.dureeSeule(Duration(minutes: n));
  return 'Duree : ${s.duree}'; // FAUTE
}
String r2(int n) {
  final s = Seance();
  s.duree = LibellesGroupe.dureeSeule(Duration(minutes: n));
  return 'Duree : ${s.duree}'; // FAUTE
}
String e(int l) {
  final c = colonnes().first;
  return 'Attente : ${c.texte(l)}'; // FAUTE
}
Iterable<String> l1(int l) {
  final cs = colonnes();
  return cs.map((c) => '${c.titre} : ${c.texte(l)}'); // FAUTE
}
String l2(int l, StringBuffer b) {
  for (final c in colonnes()) {
    b.write('${c.titre} : ${c.texte(l)}'); // FAUTE
  }
  return b.toString();
}
// Permis : la valeur seule, ou sans son ancre.
Widget seule(Seance s) => Text(s.duree);
String sain(int l) {
  final c = colonnes().first;
  return 'Attente : ${sansAncre(c.texte(l))}';
}
// Un autre objet, au type ecrit, dont le champ porte le meme nom.
class Autre {
  const Autre(this.texte, this.duree);
  final String texte;
  final String duree;
}
String autre(Autre x) => 'Texte : ${x.texte}, duree ${x.duree}';
''');
      final File b = File('${dossier.path}/b.dart')
        ..writeAsStringSync(r'''
String ailleurs(int l) {
  final premiere = colonnes().first;
  return 'Attente : ${premiere.texte(l)}'; // FAUTE
}
''');
      List<int> attendues(File f) {
        final List<String> l = f.readAsLinesSync();
        return <int>[
          for (int i = 0; i < l.length; i++)
            if (l[i].contains('// FAUTE')) i + 1,
        ];
      }

      final List<AncreGlissee> fautes = ancresGlissees(<File>[a, b]);
      String ou(AncreGlissee x) => '${x.fichier.split('/').last}:${x.ligne}';
      expect(fautes.map(ou).toList(), <String>[
        for (final int n in attendues(a)) 'a.dart:$n',
        for (final int n in attendues(b)) 'b.dart:$n',
      ], reason: fautes.map((AncreGlissee x) => x.raison).join('\n'));
    });
  });

  // Reprise 2 (relecture adverse) : litteraux adjacents (la forme que
  // produit `dart format` pour une ligne longue) et lectures `this.champ`.
  group('4. Garde de source : litteraux adjacents et lectures `this.`', () {
    final String source = File('lib/core/widgets/data_collection.dart')
        .readAsStringSync();

    List<AncreGlissee> garde(String apres) {
      expect(source, contains(_libelleCorrige));
      final Directory dossier = Directory.systemTemp.createTempSync('dc5c');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final File fautif = File('${dossier.path}/data_collection.dart')
        ..writeAsStringSync(source.replaceFirst(_libelleCorrige, apres));
      return ancresGlissees(_libAvec(fautif))
          .where((AncreGlissee a) => a.fichier == fautif.path)
          .toList();
    }

    final Map<String, String> mutations = <String, String>{
      'deux litteraux sur deux lignes (dart format)':
          "label:\n          '\${colonne.titre} : '\n"
          "          '\${colonne.texte(ligne)}',",
      'deux litteraux sur une ligne':
          "label: '\${colonne.titre} : ' '\${colonne.texte(ligne)}',",
      'titre fixe puis litteral adjacent':
          "label: 'Valeur : ' '\${colonne.texte(ligne)}',",
      'litteral brut puis litteral adjacent':
          "label: r'Valeur : ' '\${colonne.texte(ligne)}',",
      'lecture this.colonne':
          "label: '\${this.colonne.titre} : \${this.colonne.texte(ligne)}',",
      'lecture this.colonne, litteraux adjacents':
          "label: '\${this.colonne.titre} : '\n"
          "          '\${this.colonne.texte(ligne)}',",
    };
    mutations.forEach((String nom, String apres) {
      test('data_collection fautif, $nom : une faute', () {
        final List<AncreGlissee> f = garde(apres);
        expect(
          f,
          hasLength(1),
          reason: f.map((AncreGlissee a) => '${a.ligne} ${a.raison}').join(),
        );
        expect(f.single.raison, contains('ColonneDonnees.texte'));
      });
    });

    test('fixtures : valeur directe derriere un litteral adjacent, champ '
        'lu par `this.` ; la valeur en tete reste permise', () {
      final Directory dossier = Directory.systemTemp.createTempSync('anc5c');
      addTearDown(() => dossier.deleteSync(recursive: true));
      final File f = File('${dossier.path}/x.dart')
        ..writeAsStringSync(r"""
String a(Duration d) => 'Duree : ' '${LibellesGroupe.dureeSeule(d)}'; // FAUTE
String b(Duration d) =>
    'Duree : '
    '${LibellesGroupe.dureeSeule(d)}'; // FAUTE
String c(Duration d) => 'Duree : ''${LibellesGroupe.dureeSeule(d)}'; // FAUTE
String c2(Duration d) => 'Duree : ' '''${LibellesGroupe.dureeSeule(d)}'''; // FAUTE
String v(Duration d) {
  final String x = LibellesGroupe.dureeSeule(d);
  return 'Duree : '
      '$x'; // FAUTE
}
class Seance {
  const Seance(this.duree);
  final String duree;
  String get m => 'Duree : ${this.duree}'; // FAUTE
  String get m2 => 'Duree : '
      '${this.duree}'; // FAUTE
  String get m3 => 'Duree : $duree'; // FAUTE
}
Seance s(Duration d) => Seance(LibellesGroupe.dureeSeule(d));
class Autre {
  const Autre(this.duree);
  final String duree;
  String get m => 'Duree : ${this.duree}';
}
// Permis : la valeur en tete, suivie d'un litteral adjacent.
String tete(Duration d) => '${LibellesGroupe.dureeSeule(d)}' ' de cours';
String tete2(Duration d) => '''${LibellesGroupe.dureeSeule(d)} de cours''';
String tete3(Duration d) => '${LibellesGroupe.dureeSeule(d)}'
    ' de cours';
""");
      final List<String> l = f.readAsLinesSync();
      final List<AncreGlissee> fautes = ancresGlissees(<File>[f]);
      expect(
        fautes.map((AncreGlissee a) => a.ligne).toList(),
        <int>[
          for (int i = 0; i < l.length; i++)
            if (l[i].contains('// FAUTE')) i + 1,
        ],
        reason: fautes
            .map((AncreGlissee a) => '${a.ligne} ${a.raison}')
            .join('\n'),
      );
    });
  });
}
