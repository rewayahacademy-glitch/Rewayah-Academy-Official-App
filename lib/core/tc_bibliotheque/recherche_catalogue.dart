import '../tc_telechargement/port_etat_offline.dart';
import 'content_position.dart';
import 'library_resource.dart';
import 'port_catalogue.dart';

/// La recherche et les filtres du catalogue, en fonctions pures.
///
/// Pures et hors widget pour trois raisons : le meme code sert la Bibliotheque
/// hors classe et le `ClassLibraryPicker` en classe, un test peut mesurer le
/// comportement sur plusieurs centaines de ressources sans monter d'arbre de
/// widgets, et une implementation serveur du catalogue pourra plus tard
/// deleguer a la base **exactement** les memes regles.
abstract final class RechercheCatalogue {
  /// Les lettres accentuees du francais et leur equivalent sans accent.
  ///
  /// Une table et non une normalisation Unicode : `dart:core` n'expose pas de
  /// normalisation NFD, et aucune dependance ne peut etre ajoutee (D-11).
  /// Chercher « coran » doit trouver « Le Coran », et chercher « recitation »
  /// doit trouver « Recitation » accentuee. Seules les formes precomposees
  /// sont traitees : ce sont celles qu'un clavier produit.
  static const Map<int, String> _tableSimple = <int, String>{
    0xE0: 'a',
    0xE2: 'a',
    0xE4: 'a',
    0xE7: 'c',
    0xE8: 'e',
    0xE9: 'e',
    0xEA: 'e',
    0xEB: 'e',
    0xEE: 'i',
    0xEF: 'i',
    0xF4: 'o',
    0xF6: 'o',
    0xF9: 'u',
    0xFB: 'u',
    0xFC: 'u',
    0xFF: 'y',
    0x153: 'oe',
    0xE6: 'ae',
  };

  /// Met un texte sous la forme qui se compare : minuscules, sans accent.
  static String normaliser(String texte) {
    final StringBuffer sortie = StringBuffer();
    for (final int unite in texte.toLowerCase().runes) {
      sortie.write(_tableSimple[unite] ?? String.fromCharCode(unite));
    }
    return sortie.toString();
  }

  /// Applique un filtre a une liste de ressources.
  ///
  /// [etats] fournit l'etat hors ligne de chaque ressource ; il n'est consulte
  /// que si le filtre porte sur cet axe. Une ressource dont l'etat est inconnu
  /// n'est **jamais** retenue par un filtre d'etat : une absence de mesure ne
  /// vaut pas une mesure.
  static List<LibraryResource> filtrer(
    List<LibraryResource> source,
    FiltreCatalogue? filtre, {
    Map<String, EtatOffline> etats = const <String, EtatOffline>{},
  }) {
    if (filtre == null || filtre.vide) return source;

    return source
        .where((LibraryResource r) {
          final Set<TypeRessource>? types = filtre.types;
          if (types != null &&
              types.isNotEmpty &&
              !types.contains(r.resourceType)) {
            return false;
          }
          if (filtre.langue != null && r.language != filtre.langue) {
            return false;
          }
          if (filtre.categorie != null && r.category != filtre.categorie) {
            return false;
          }
          if (filtre.niveau != null && !r.levelScope.contains(filtre.niveau)) {
            return false;
          }
          if (filtre.etatOffline != null && etats[r.id] != filtre.etatOffline) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  /// Cherche [requete] dans une liste de ressources.
  ///
  /// Les axes cherches sont ceux de la spec section 6.1 : titre, type, niveau,
  /// et sourate ou page « lorsque applicable ». La categorie et l'edition sont
  /// ajoutees parce qu'elles sont ce que l'operateur tape en pratique
  /// (« hafs », « tajwid »).
  ///
  /// Une requete vide rend la liste inchangee : c'est l'absence de recherche,
  /// pas une recherche sans resultat.
  static List<LibraryResource> chercher(
    List<LibraryResource> source,
    String requete,
  ) {
    final String q = normaliser(requete).trim();
    if (q.isEmpty) return source;

    return source
        .where((LibraryResource r) => _correspond(r, q))
        .toList(growable: false);
  }

  static bool _correspond(LibraryResource r, String q) {
    bool dans(String? valeur) =>
        valeur != null && normaliser(valeur).contains(q);

    if (dans(r.title) || dans(r.shortTitle)) return true;
    if (dans(r.category) || dans(r.edition)) return true;
    if (r.levelScope.any(dans)) return true;
    if (dans(r.resourceType.valeurSql)) return true;
    // « Sourate / page lorsque applicable » : une requete chiffree ne vaut que
    // pour un support qui sait accueillir ce repere-la. Chercher « 255 » dans
    // un catalogue de lecons ne doit pas rendre toutes les lecons.
    final ReperePositionne? repere = reperePositionne(q);
    return repere != null && _accepteLeRepere(r, repere);
  }

  /// Vrai quand la ressource sait accueillir **ce** repere.
  ///
  /// La distinction compte : « 2:255 » designe un verset, donc le Coran seul ;
  /// « 40 » designe une page, donc tout support pagine. Les confondre ferait
  /// remonter un livret de tajwid sur une recherche de verset.
  static bool _accepteLeRepere(LibraryResource r, ReperePositionne repere) {
    if (repere.sourate != null) return r.resourceType == TypeRessource.quran;
    return r.resourceType == TypeRessource.quran ||
        r.peut(CapaciteRessource.pageable);
  }

  /// Le repere chiffre contenu dans une requete, s'il y en a un.
  ///
  /// Deux formes seulement, celles qu'on ecrit reellement : `255` pour une
  /// page, `2:255` pour une sourate et un verset. Le reste n'est pas devine.
  static ReperePositionne? reperePositionne(String requete) {
    final String q = requete.trim();
    final RegExpMatch? verset = RegExp(r'^(\d{1,3})\s*[:.]\s*(\d{1,3})$')
        .firstMatch(q);
    if (verset != null) {
      return ReperePositionne(
        sourate: int.parse(verset.group(1)!),
        ayah: int.parse(verset.group(2)!),
      );
    }
    final RegExpMatch? page = RegExp(r'^(\d{1,4})$').firstMatch(q);
    if (page != null) {
      return ReperePositionne(page: int.parse(page.group(1)!));
    }
    return null;
  }

  /// La position que la requete designe dans une ressource donnee.
  ///
  /// `null` quand la requete ne porte aucun repere, ou quand la ressource
  /// n'accepte pas ce genre d'ancrage. **Cette fonction n'ouvre rien et ne
  /// valide aucun numero** : borner une page a 604 ou un verset a sa sourate
  /// appartient au moteur Coran d'Agent C, pas au catalogue.
  static ContentPosition? positionDemandee(
    String requete,
    LibraryResource ressource,
  ) {
    final ReperePositionne? repere = reperePositionne(normaliser(requete));
    if (repere == null || !_accepteLeRepere(ressource, repere)) return null;

    if (repere.sourate != null && repere.ayah != null) {
      return ContentPosition.ayah(
        resourceId: ressource.id,
        sourate: repere.sourate!,
        ayah: repere.ayah!,
        resourceVersionId: ressource.currentVersionId,
      );
    }
    if (repere.page != null && ressource.peut(CapaciteRessource.pageable)) {
      return ContentPosition.page(
        resourceId: ressource.id,
        page: repere.page!,
        resourceVersionId: ressource.currentVersionId,
      );
    }
    return null;
  }
}

/// Un repere chiffre tire d'une requete de recherche.
class ReperePositionne {
  /// Cree un repere.
  const ReperePositionne({this.page, this.sourate, this.ayah});

  /// Le numero de page demande.
  final int? page;

  /// Le numero de sourate demande.
  final int? sourate;

  /// Le numero de verset demande.
  final int? ayah;
}
