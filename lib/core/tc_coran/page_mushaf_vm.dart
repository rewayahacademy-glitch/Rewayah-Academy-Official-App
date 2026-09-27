import 'package:flutter/foundation.dart';

import '../coran/service_coran.dart';
import '../coran/vue_lecteur.dart';
import 'port_corpus_coran.dart';
import 'port_layout_mushaf.dart';

/// Les trois rendus du moteur, sur la meme source canonique.
enum ModeRenduCoran {
  /// La page du mushaf : reperes spatiaux, memorisation, lecture courante.
  mushaf,

  /// Le verset agrandi : reflow responsive, zoom fort, ligne pedagogique.
  versetAgrandi,

  /// Le focus dirige : une plage au centre, chrome reduit.
  focus,
}

/// De quel cote d'une double page une page se pose.
///
/// **Ce n'est pas une preference de presentation, c'est la reliure.** Un
/// mushaf se relie a droite : la page que l'on lit en premier dans une
/// ouverture est celle de droite, et le regard passe ensuite a gauche. Les
/// pages impaires sont a droite, les paires a gauche, et une ouverture montre
/// donc le couple (impair, pair) : c'est ce qui met Al-Fatiha (page 1) en face
/// du debut d'Al-Baqara (page 2), comme sur l'edition imprimee.
enum CoteDePage {
  /// Page de droite : la premiere lue de l'ouverture. Numero impair.
  droite,

  /// Page de gauche : la seconde lue de l'ouverture. Numero pair.
  gauche,
}

/// La geometrie de l'edition `madina-hafs-604`.
///
/// Deux constantes, et toutes les deux **declarees**, pas mesurees sur le
/// corpus : le corpus ne porte aucune metadonnee de mise en page. Elles
/// fixent le **cadre** de la page, jamais sa composition interne, et une
/// source de layout reelle les remplace par celles qu'elle porte
/// ([LayoutPage.nombreLignes], [LayoutPage.ratioLargeurSurHauteur]).
abstract final class GeometrieMushaf {
  /// Quinze lignes par page.
  ///
  /// Fixe par `docs/archive/2026-09-pre-remise-a-plat/architecture/etape-5-salle-coran-presence.md` section 3.1,
  /// avec la riwaya et les 604 pages. Les pages 1 et 2 font exception sur
  /// l'edition imprimee ; sans donnees de ligne, l'exception ne se rend pas.
  static const int lignesParPage = 15;

  /// La proportion du cadre de texte : largeur sur hauteur.
  ///
  /// **C'est le seul nombre de presentation de ce moteur.** Il tient la
  /// promesse mesurable de la specification section 7.2 -- « sur telephone :
  /// une page a la fois, ajustee sans deformer » -- en rendant la page
  /// homothetique a elle-meme quel que soit l'appareil. Il ne pretend pas
  /// reproduire la composition, seulement le format.
  static const double ratioCadreTexte = 2 / 3;

  /// Le cote d'une page dans une ouverture.
  static CoteDePage coteDe(int page) =>
      page.isOdd ? CoteDePage.droite : CoteDePage.gauche;

  /// La page de droite de l'ouverture qui contient [page].
  static int pageDeDroiteDe(int page) => page.isOdd ? page : page - 1;

  /// La page de gauche de l'ouverture qui contient [page], si elle existe.
  ///
  /// `null` a la toute fin d'un mushaf dont la derniere page est impaire : il
  /// n'y a alors rien en face. Les 604 pages du Mushaf de Medine se terminent
  /// sur une page paire, donc le cas ne se presente pas ici -- il est traite
  /// parce que [nombrePages] est un parametre et non une constante.
  static int? pageDeGaucheDe(int page, {int nombrePages = pagesMushafMedine}) {
    final int gauche = page.isOdd ? page + 1 : page;
    return gauche > nombrePages ? null : gauche;
  }
}

/// Une page du mushaf, prete a rendre.
///
/// **Elle se pose au-dessus de [VueLecteur], elle ne le remplace pas.** Les
/// quatre etats, le decoupage par sourate et les bornes de navigation sont
/// deja ecrits, testes et en production : les recopier aurait produit une
/// deuxieme verite. Ce que cette vue ajoute est ce qui manquait : le cote de
/// page, le cadre, et **le degre de fidelite de la composition**.
@immutable
class PageMushafVM {
  const PageMushafVM._({
    required this.lecteur,
    required this.numero,
    required this.cote,
    required this.fidelite,
    required this.lignes,
    required this.nombreLignes,
    required this.ratioLargeurSurHauteur,
  });

  /// Calcule ce qu'une page doit montrer.
  ///
  /// [fidelite] et [layout] viennent de [PortLayoutMushaf]. Tant que la
  /// premiere ne vaut pas [DisponibiliteLayout.fidele], [lignes] reste vide :
  /// **le moteur ne fabrique aucune ligne**.
  factory PageMushafVM.depuis({
    required int pageDemandee,
    required PageCorpus? page,
    required bool chargementEnCours,
    required List<SourateVM>? sourates,
    required DisponibiliteLayout fidelite,
    LayoutPage? layout,
    int nombrePages = pagesMushafMedine,
  }) {
    final int bornee = pageDemandee.clamp(1, nombrePages);
    final VueLecteur lecteur = VueLecteur.depuis(
      pageDemandee: bornee,
      page: page == null ? null : _versPageCoran(page),
      chargementEnCours: chargementEnCours,
      sourates: sourates == null ? null : _versSourates(sourates),
      position: null,
      nombrePages: nombrePages,
    );

    // Une source qui se dit fidele mais ne rend aucune ligne pour cette page
    // n'est pas fidele POUR CETTE PAGE : on le dit plutot que de l'arrondir.
    final bool lignesReelles =
        fidelite == DisponibiliteLayout.fidele &&
        layout != null &&
        layout.lignes.isNotEmpty;

    return PageMushafVM._(
      lecteur: lecteur,
      numero: bornee,
      cote: GeometrieMushaf.coteDe(bornee),
      fidelite: lignesReelles ? fidelite : DisponibiliteLayout.indisponible,
      lignes: lignesReelles
          ? List<SectionLigne>.unmodifiable(layout.lignes)
          : const <SectionLigne>[],
      nombreLignes: layout?.nombreLignes ?? GeometrieMushaf.lignesParPage,
      ratioLargeurSurHauteur:
          layout?.ratioLargeurSurHauteur ?? GeometrieMushaf.ratioCadreTexte,
    );
  }

  /// L'etat, le decoupage par sourate et les bornes, calcules par l'existant.
  final VueLecteur lecteur;

  /// Le numero de la page, borne a l'edition.
  final int numero;

  /// Le cote ou cette page se pose dans une ouverture.
  final CoteDePage cote;

  /// Ce que la composition interne vaut reellement.
  final DisponibiliteLayout fidelite;

  /// Les lignes de l'edition. **Vide tant qu'aucune source ne les fournit.**
  final List<SectionLigne> lignes;

  /// Le nombre de lignes du cadre.
  final int nombreLignes;

  /// La proportion du cadre de texte.
  final double ratioLargeurSurHauteur;

  /// L'etat du lecteur : chargement, lecture, corpus absent, indisponible.
  EtatLecteur get etat => lecteur.etat;

  /// Le contenu de la page, decoupe par sourate.
  List<SectionSourate> get sections => lecteur.sections;

  /// Le juz de la page, quand il est connu.
  int? get juzNumero => lecteur.juzNumero;

  /// Le nombre de pages de l'edition.
  int get nombrePages => lecteur.nombrePages;

  /// La page precedente au sens du mushaf, ou `null` au debut.
  int? get pagePrecedente => lecteur.pagePrecedente;

  /// La page suivante au sens du mushaf, ou `null` a la fin.
  int? get pageSuivante => lecteur.pageSuivante;

  /// Vrai quand il y a du texte a l'ecran.
  bool get aDuTexte => lecteur.aDuTexte;

  /// Vrai quand la repartition des mots sur les lignes est **approximee**.
  ///
  /// L'ecran doit le dire. Une page approximee ne se fait jamais passer pour
  /// une page fidele : ni dans le code, ni a l'ecran, ni dans le rapport.
  bool get compositionApprochee => fidelite != DisponibiliteLayout.fidele;

  /// Les versets de la page, dans l'ordre du texte.
  ///
  /// Reconstitue depuis les sections : c'est ce que l'on compare aux versets
  /// que `verset.page_numero` attribue a cette page.
  List<VersetCoran> get versets => <VersetCoran>[
    for (final SectionSourate section in sections) ...section.versets,
  ];

  static PageCoran _versPageCoran(PageCorpus page) => PageCoran(
    numero: page.numero,
    juzNumero: page.juzNumero,
    versets: page.versets
        .map(
          (VersetCorpus v) => VersetCoran(
            sourateNumero: v.sourate,
            numero: v.numero,
            texte: v.texte,
            pageNumero: v.pageNumero,
          ),
        )
        .toList(growable: false),
  );

  static List<Sourate> _versSourates(List<SourateVM> sourates) => sourates
      .map(
        (SourateVM s) => Sourate(
          numero: s.numero,
          nomArabe: s.nomArabe,
          nomTranslittere: s.nomTranslittere,
          lieuRevelation: s.mecquoise ? 'mecque' : 'medine',
          nombreVersets: s.nombreVersets,
        ),
      )
      .toList(growable: false);
}

/// Ce qu'une ouverture montre : une page seule, ou deux pages en vis-a-vis.
///
/// **Le cote est explicite** (exigence de la specification section 7.2). Une
/// double page qui inverserait droite et gauche serait immediatement vue par
/// un lecteur de mushaf, et ferait lire les pages a l'envers.
@immutable
class PlancheMushafVM {
  const PlancheMushafVM._({required this.droite, required this.gauche});

  /// Une ouverture a une seule page.
  const PlancheMushafVM.simple(PageMushafVM page)
    : this._(droite: page, gauche: null);

  /// Une ouverture a deux pages.
  ///
  /// Les assertions ne sont pas decoratives : ce sont les seules choses qui
  /// empechent un appelant de composer une planche dont les deux pages
  /// seraient du meme cote, ou ne se suivraient pas.
  factory PlancheMushafVM.doublePage({
    required PageMushafVM droite,
    required PageMushafVM gauche,
  }) {
    assert(
      droite.cote == CoteDePage.droite && gauche.cote == CoteDePage.gauche,
      'une ouverture pose une page impaire a droite et une paire a gauche',
    );
    assert(
      gauche.numero == droite.numero + 1,
      'les deux pages d une ouverture se suivent',
    );
    return PlancheMushafVM._(droite: droite, gauche: gauche);
  }

  /// La page de droite, lue en premier.
  final PageMushafVM droite;

  /// La page de gauche, ou `null` quand l'ouverture n'en a qu'une.
  final PageMushafVM? gauche;

  /// Vrai quand deux pages sont montrees en vis-a-vis.
  bool get estDouble => gauche != null;

  /// Les pages de l'ouverture, dans l'ordre de lecture : droite puis gauche.
  List<PageMushafVM> get pages => <PageMushafVM>[droite, ?gauche];

  /// Vrai quand la place disponible tient deux cadres de page entiers.
  ///
  /// **Decide par la geometrie, pas par un seuil de largeur.** Deux pages
  /// tiennent quand la largeur disponible loge deux cadres a la hauteur
  /// disponible, plus la gouttiere entre eux. Le telephone est exclu par
  /// [gabaritLarge], comme la specification section 7.2 le demande, et non par
  /// un nombre pose ici : `AppGabarit` reste le seul fichier a comparer une
  /// largeur d'ecran a une constante.
  static bool tientEnDoublePage({
    required double largeurDisponible,
    required double hauteurDisponible,
    required double ecartEntrePages,
    required bool gabaritLarge,
    double ratioLargeurSurHauteur = GeometrieMushaf.ratioCadreTexte,
  }) {
    if (!gabaritLarge) {
      return false;
    }
    if (hauteurDisponible <= 0 || largeurDisponible <= 0) {
      return false;
    }
    final double largeurCadre = hauteurDisponible * ratioLargeurSurHauteur;
    return largeurDisponible >= largeurCadre * 2 + ecartEntrePages;
  }
}
