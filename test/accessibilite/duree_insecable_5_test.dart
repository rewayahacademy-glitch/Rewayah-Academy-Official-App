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
    test('lib/ : aucune valeur ancree inseree dans un autre libelle', () {
      final List<AncreGlissee> fautes = ancresGlissees();
      expect(
        fautes,
        isEmpty,
        reason: fautes
            .map((AncreGlissee f) => '${f.fichier}:${f.ligne} ${f.raison}')
            .join('\n'),
      );
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
      final List<AncreGlissee> fautes = ancresGlissees(_libAvec(fautif));
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
}
