// Golden de pagination du Mushaf : ce qu'une page contient, exactement.
//
// PROPRIETE : Agent Q (test/teaching_core/fixtures/). Aucune ligne de
// production.
//
// PROVENANCE DES DONNEES -- A LIRE AVANT DE LES MODIFIER.
// Ces plages ne sont **ni inventees, ni memorisees, ni recopiees d'un site**.
// Elles ont ete extraites de `supabase/migrations/0013_corpus_coranique.sql`,
// qui est la source canonique du depot : 6236 lignes `(sourate, verset, texte,
// page)`, dont l'import echoue si le compte n'est pas 114 / 30 / 604 / 6236.
// Seuls les numeros ont ete extraits ; **aucun texte coranique n'est recopie
// ici**, ce qui evite d'avoir a reproduire le bloc de licence Tanzil.
//
// CE QUE CE GOLDEN N'EST PAS. Ce n'est pas un golden d'image : rendre une page
// de Mushaf demanderait une police glyphe-par-page que le depot n'a pas
// (decision D-23). C'est un golden de **contrat de donnees** : la page N porte
// ces versets-la, et le moteur d'Agent C devra rendre exactement ceux-la.
//
// LIMITE CONNUE, HERITEE DE LA BASE. `verset.page_numero` designe la page ou
// un verset **commence**. Un verset a cheval sur deux pages est donc attribue
// a une seule. Le golden reproduit fidelement cette convention ; il ne la
// corrige pas, et il ne peut pas servir a couper une page au bon mot.

/// Une suite contigue de versets d'une meme sourate, sur une page.
class SegmentPage {
  /// Cree un segment.
  const SegmentPage({
    required this.sourate,
    required this.ayahDebut,
    required this.ayahFin,
  }) : assert(ayahDebut <= ayahFin, 'un segment va du debut vers la fin');

  /// Le numero de sourate.
  final int sourate;

  /// Le premier verset du segment, inclus.
  final int ayahDebut;

  /// Le dernier verset du segment, inclus.
  final int ayahFin;

  /// Le nombre de versets du segment.
  int get nombreVersets => ayahFin - ayahDebut + 1;

  @override
  String toString() => '$sourate:$ayahDebut-$ayahFin';
}

/// Le nombre de pages du Mushaf de Medine, tel que le depot le fixe.
///
/// La constante existe deja en production sous le nom `pagesMushafMedine` ;
/// elle est reprise ici pour que le golden soit lisible seul.
const int pagesMushafGolden = 604;

/// Le nombre de versets du corpus, verifie par la migration elle-meme.
const int versetsMushafGolden = 6236;

/// Le code d'edition. **Jamais un uuid** : l'identifiant de `mushaf` est
/// genere par la base et differe d'un environnement a l'autre.
const String editionMushafGolden = 'madina-hafs-604';

/// Dix pages echantillonnees, et ce qu'elles contiennent exactement.
///
/// Le choix des dix n'est pas decoratif :
/// - **1** : une sourate complete, seule sur sa page.
/// - **2, 3** : le debut d'une longue sourate, sur deux pages.
/// - **42** : la page d'ayat al-Kursi (2:255), la plus citee en classe.
/// - **48** : **un seul verset occupe toute la page** (2:282, le verset de la
///   dette). Une interface qui supposerait « une page = plusieurs versets »
///   casse ici.
/// - **49, 50** : une sourate finit, la suivante commence a la page d'apres.
/// - **599, 600** : trois sourates par page, et la sourate 100 **traverse** la
///   coupure. Une page n'est donc pas une unite de sens.
/// - **604** : la derniere page, trois sourates.
const Map<int, List<SegmentPage>> goldenPagesMushaf = <int, List<SegmentPage>>{
  1: <SegmentPage>[SegmentPage(sourate: 1, ayahDebut: 1, ayahFin: 7)],
  2: <SegmentPage>[SegmentPage(sourate: 2, ayahDebut: 1, ayahFin: 5)],
  3: <SegmentPage>[SegmentPage(sourate: 2, ayahDebut: 6, ayahFin: 16)],
  42: <SegmentPage>[SegmentPage(sourate: 2, ayahDebut: 253, ayahFin: 256)],
  48: <SegmentPage>[SegmentPage(sourate: 2, ayahDebut: 282, ayahFin: 282)],
  49: <SegmentPage>[SegmentPage(sourate: 2, ayahDebut: 283, ayahFin: 286)],
  50: <SegmentPage>[SegmentPage(sourate: 3, ayahDebut: 1, ayahFin: 9)],
  599: <SegmentPage>[
    SegmentPage(sourate: 98, ayahDebut: 8, ayahFin: 8),
    SegmentPage(sourate: 99, ayahDebut: 1, ayahFin: 8),
    SegmentPage(sourate: 100, ayahDebut: 1, ayahFin: 9),
  ],
  600: <SegmentPage>[
    SegmentPage(sourate: 100, ayahDebut: 10, ayahFin: 11),
    SegmentPage(sourate: 101, ayahDebut: 1, ayahFin: 11),
    SegmentPage(sourate: 102, ayahDebut: 1, ayahFin: 8),
  ],
  604: <SegmentPage>[
    SegmentPage(sourate: 112, ayahDebut: 1, ayahFin: 4),
    SegmentPage(sourate: 113, ayahDebut: 1, ayahFin: 5),
    SegmentPage(sourate: 114, ayahDebut: 1, ayahFin: 6),
  ],
};

/// Le nombre total de versets de quelques sourates, pour les recoupements.
///
/// Extrait du meme fichier de migration, par comptage des lignes inserees.
const Map<int, int> goldenVersetsParSourate = <int, int>{
  1: 7,
  2: 286,
  98: 8,
  99: 8,
  100: 11,
  101: 11,
  102: 8,
  112: 4,
  113: 5,
  114: 6,
};

/// Le nombre de versets porte par une page du golden.
int versetsDePage(int page) {
  final List<SegmentPage>? segments = goldenPagesMushaf[page];
  if (segments == null) return 0;
  return segments.fold<int>(0, (int n, SegmentPage s) => n + s.nombreVersets);
}

/// La disponibilite d'un layout Mushaf fidele, deduite des donnees reelles.
///
/// Forme executable de la decision D-23. Tant que `verset.ligne` est NULL sur
/// les 6236 lignes et qu'aucun asset de layout n'est fourni, la reponse est
/// `indisponible` -- **jamais** `fidele`, et jamais une page approximative.
DisponibiliteLayoutGolden disponibiliteLayout({
  required bool lignesPeuplees,
  required bool assetsLayoutFournis,
}) {
  if (lignesPeuplees && assetsLayoutFournis) {
    return DisponibiliteLayoutGolden.fidele;
  }
  if (lignesPeuplees || assetsLayoutFournis) {
    return DisponibiliteLayoutGolden.degrade;
  }
  return DisponibiliteLayoutGolden.indisponible;
}

/// L'etat du layout, miroir de `DisponibiliteLayout` d'Agent C.
enum DisponibiliteLayoutGolden { fidele, degrade, indisponible }

/// L'etat reel du depot a la baseline `0071557` : aucune ligne, aucun asset.
const bool lignesVersetPeupleesDansLaBaseline = false;

/// L'etat reel du depot a la baseline `0071557` : aucun asset de layout.
const bool assetsLayoutFournisDansLaBaseline = false;

/// La double page qui contient [page], selon une convention **donnee**.
///
/// [pageRecto] dit quelle parite est une page de droite dans l'edition. Le
/// depot ne porte **aucune** notion de recto / verso ni de double page : la
/// convention est donc un parametre, pas une constante. Un moteur qui la
/// coderait en dur se tromperait a la premiere edition differente.
///
/// Rend une paire ordonnee, eventuellement incomplete aux deux extremites du
/// Mushaf.
List<int> doublePageDe(
  int page, {
  required int pageRecto,
  int pages = pagesMushafGolden,
}) {
  assert(pageRecto == 0 || pageRecto == 1, 'la parite vaut 0 ou 1');
  assert(page >= 1 && page <= pages, 'la page est dans le Mushaf');
  final bool estRecto = page % 2 == pageRecto;
  final int gauche = estRecto ? page - 1 : page;
  final int droite = estRecto ? page : page + 1;
  return <int>[
    if (gauche >= 1) gauche,
    if (droite <= pages) droite,
  ];
}
