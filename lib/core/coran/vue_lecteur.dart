import 'package:flutter/foundation.dart';

import 'service_coran.dart';

/// Ce que le lecteur est en train de montrer.
///
/// Quatre etats, et surtout **deux facons distinctes de ne rien montrer**.
/// [indisponible] dit que la lecture a echoue -- reseau coupe, refus, reponse
/// illisible ; [corpusAbsent] dit que la lecture a reussi et que la page est
/// vide, ce qui ne peut signifier qu'une chose : le corpus n'a pas ete importe
/// dans cette base. Les confondre couterait cher le jour ou ce sera le cas :
/// l'un se resout en attendant le reseau, l'autre en appliquant une migration.
enum EtatLecteur {
  /// La page n'est pas encore arrivee.
  chargement,

  /// Il y a du texte a lire.
  lecture,

  /// La page est vide : aucun verset importe pour cette edition.
  corpusAbsent,

  /// La lecture a echoue.
  indisponible,
}

/// Un bloc de page : une sourate, et les versets qu'elle occupe ici.
///
/// **Une page du mushaf porte souvent deux sourates**, la fin de l'une et le
/// debut de l'autre. Un seul titre en haut de page mentirait sur la seconde,
/// et c'est le genre d'erreur qu'un lecteur de Coran voit immediatement.
@immutable
class SectionSourate {
  /// Cree une section.
  const SectionSourate({
    required this.sourateNumero,
    required this.versets,
    required this.commenceLaSourate,
    this.sourate,
  });

  /// Le rang de la sourate.
  final int sourateNumero;

  /// Sa fiche, quand la liste des sourates a pu etre lue.
  ///
  /// `null` n'empeche pas de lire : le texte s'affiche sans son titre plutot
  /// que pas du tout.
  final Sourate? sourate;

  /// Les versets de cette sourate presents sur la page.
  final List<VersetCoran> versets;

  /// Vrai quand la sourate **commence** ici.
  ///
  /// C'est ce qui distingue un titre d'un simple rappel : la basmala et le nom
  /// ne se posent qu'au debut d'une sourate, pas en haut de chaque page qui la
  /// continue.
  final bool commenceLaSourate;
}

/// Ce qu'un ecran doit montrer du lecteur de Coran, a un instant donne.
///
/// **Fonction pure, comme `VueSalle.depuis` et `VuePresence.depuis`** : les
/// quatre etats, le decoupage en sections, les bornes de navigation et l'offre
/// de reprise se verifient sans monter d'ecran, sans base et sans reseau.
///
/// Elle ne traduit rien : les libelles vivent dans `strings.g.dart`, et l'ecran
/// les choisit d'apres [etat].
@immutable
class VueLecteur {
  const VueLecteur._({
    required this.etat,
    required this.pageAffichee,
    required this.nombrePages,
    required this.sections,
    required this.repriseProposee,
    this.juzNumero,
    this.position,
  });

  /// Calcule ce que le lecteur doit montrer.
  ///
  /// [page] vaut `null` tant qu'elle n'est pas arrivee **et** quand la lecture
  /// a echoue : c'est [chargementEnCours] qui separe les deux, et c'est
  /// volontairement le seul role de ce parametre.
  factory VueLecteur.depuis({
    required int pageDemandee,
    required PageCoran? page,
    required bool chargementEnCours,
    required List<Sourate>? sourates,
    required PositionLecture? position,
    int nombrePages = pagesMushafMedine,
  }) {
    final int bornee = pageDemandee.clamp(1, nombrePages);

    final EtatLecteur etat;
    if (page == null) {
      etat = chargementEnCours
          ? EtatLecteur.chargement
          : EtatLecteur.indisponible;
    } else if (page.versets.isEmpty) {
      etat = EtatLecteur.corpusAbsent;
    } else {
      etat = EtatLecteur.lecture;
    }

    return VueLecteur._(
      etat: etat,
      pageAffichee: bornee,
      nombrePages: nombrePages,
      juzNumero: page?.juzNumero,
      sections: page == null
          ? const <SectionSourate>[]
          : _decouper(page, sourates),
      position: position,
      // La reprise ne se propose que si elle mene ailleurs. Un bouton
      // « Reprendre » qui ramene a la page deja ouverte est une promesse vide,
      // et il occuperait la place la plus visible de l'ecran pour rien.
      repriseProposee: position != null && position.page != bornee,
    );
  }

  /// L'etat courant.
  final EtatLecteur etat;

  /// La page reellement affichee, bornee a l'edition.
  final int pageAffichee;

  /// Le nombre de pages de l'edition.
  final int nombrePages;

  /// Le juz de la page, quand il est connu.
  final int? juzNumero;

  /// Le contenu de la page, decoupe par sourate.
  final List<SectionSourate> sections;

  /// La position enregistree, qu'elle soit proposee ou non.
  final PositionLecture? position;

  /// Vrai quand une reprise a un sens : elle existe et elle mene ailleurs.
  final bool repriseProposee;

  /// La page precedente, ou `null` au debut du mushaf.
  ///
  /// **Precedente au sens du mushaf, pas au sens de l'ecran.** En arabe on
  /// tourne les pages dans l'autre sens ; c'est au rendu de placer le geste du
  /// bon cote, pas au modele de renumeroter.
  int? get pagePrecedente => pageAffichee > 1 ? pageAffichee - 1 : null;

  /// La page suivante, ou `null` a la fin du mushaf.
  int? get pageSuivante =>
      pageAffichee < nombrePages ? pageAffichee + 1 : null;

  /// Les sourates presentes sur la page, dans l'ordre du texte.
  List<int> get souratesPresentes =>
      sections.map((SectionSourate s) => s.sourateNumero).toList();

  /// Vrai quand il y a du texte a l'ecran.
  bool get aDuTexte => etat == EtatLecteur.lecture;

  /// Decoupe la page en sections consecutives, une par sourate rencontree.
  static List<SectionSourate> _decouper(
    PageCoran page,
    List<Sourate>? sourates,
  ) {
    final Map<int, Sourate> parNumero = <int, Sourate>{
      if (sourates != null)
        for (final Sourate s in sourates) s.numero: s,
    };

    final List<SectionSourate> sections = <SectionSourate>[];
    List<VersetCoran> courants = <VersetCoran>[];
    int? numeroCourant;

    void fermer() {
      if (numeroCourant == null || courants.isEmpty) {
        return;
      }
      sections.add(
        SectionSourate(
          sourateNumero: numeroCourant,
          sourate: parNumero[numeroCourant],
          versets: List<VersetCoran>.unmodifiable(courants),
          // At-Tawba (9) est la seule sourate qui ne s'ouvre pas par la
          // basmala ; l'ecran s'en sert, la vue se contente de dire qu'un
          // debut de sourate est ici.
          commenceLaSourate: courants.first.numero == 1,
        ),
      );
    }

    for (final VersetCoran verset in page.versets) {
      if (numeroCourant != verset.sourateNumero) {
        fermer();
        numeroCourant = verset.sourateNumero;
        courants = <VersetCoran>[];
      }
      courants.add(verset);
    }
    fermer();

    return List<SectionSourate>.unmodifiable(sections);
  }
}
