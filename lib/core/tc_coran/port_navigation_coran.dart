import '../coran/service_coran.dart';
import '../tc_bibliotheque/content_position.dart';
import 'port_corpus_coran.dart';

/// L'identifiant de ressource du Coran dans la Bibliotheque.
///
/// **Double local declare.** `LibraryResource` et sa table sont neuves et
/// appartiennent a Agent B : aucun identifiant reel n'existe encore. Le moteur
/// a pourtant besoin d'un identifiant pour construire une [ContentPosition]
/// partageable. Cette constante sert de pont jusqu'a l'integration ; la demande
/// est ecrite dans `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_C.md`.
///
/// Elle reprend le **code** de l'edition, jamais un uuid : l'identifiant de la
/// ligne `mushaf` est genere par la base et differe d'un environnement a
/// l'autre.
const String identifiantRessourceCoran = 'quran:$codeMushafReference';

/// Ce vers quoi le lecteur veut aller.
sealed class CibleCoran {
  /// Cree une cible.
  const CibleCoran();
}

/// Aller a une page du mushaf.
final class CiblePage extends CibleCoran {
  /// Cree la cible.
  const CiblePage(this.page);

  /// Le numero de page vise.
  final int page;
}

/// Aller au debut d'une sourate.
final class CibleSourate extends CibleCoran {
  /// Cree la cible.
  const CibleSourate(this.sourate);

  /// Le rang de la sourate.
  final int sourate;
}

/// Aller au debut d'un juz.
final class CibleJuz extends CibleCoran {
  /// Cree la cible.
  const CibleJuz(this.juz);

  /// Le rang du juz.
  final int juz;
}

/// Aller a un verset precis.
final class CibleAyah extends CibleCoran {
  /// Cree la cible.
  const CibleAyah({required this.sourate, required this.ayah});

  /// La sourate.
  final int sourate;

  /// Le verset.
  final int ayah;
}

/// D'ou vient un changement de page.
///
/// **Ce n'est pas une trace, c'est une barriere.** L'invariant J2 de la
/// migration `0007` est ecrit en toutes lettres : « une page tournee par
/// l'enseignant pour toute la classe ne doit jamais ecrire
/// `student_reading_position` ». Le seul moyen de le tenir est de savoir, au
/// moment d'ecrire, qui a tourne la page.
enum OrigineNavigation {
  /// Le lecteur a navigue lui-meme. Sa position personnelle s'enregistre.
  personnelle,

  /// L'etat partage de la classe a bouge. **Rien ne s'enregistre.**
  groupe,

  /// Le moteur a ouvert la page de depart. Rien ne s'enregistre non plus :
  /// ouvrir le Coran ne doit pas ecraser le marque-page par la page d'accueil.
  ouverture,
}

/// La navigation dans le mushaf et les positions de reprise.
abstract class PortNavigationCoran {
  /// La page correspondant a une cible, ou `null` si la cible n'existe pas.
  Future<int?> pageDe(CibleCoran cible);

  /// La derniere position personnelle du lecteur, ou `null` s'il n'en a pas.
  Future<PositionLecture?> dernierePositionPersonnelle();

  /// Enregistre la position personnelle.
  ///
  /// [origine] doit valoir [OrigineNavigation.personnelle] : toute autre
  /// valeur rend `false` **sans ecrire**. Voir [OrigineNavigation].
  Future<bool> memoriserPositionPersonnelle(
    PositionLecture position, {
    required OrigineNavigation origine,
  });

  /// La position ou le groupe reprend le cours, ou `null`.
  ///
  /// Lue dans l'etat partage de la seance, **jamais** dans la position
  /// personnelle de qui que ce soit.
  Future<PositionLecture?> positionDeGroupe(String sessionId);

  /// Les resultats d'une recherche rapide.
  Future<List<ResultatRechercheCoran>> rechercheRapide(String requete);
}

/// Traductions entre la position du mushaf et la position canonique partagee.
extension PontContentPosition on PositionLecture {
  /// La meme position, dans le vocabulaire de la Bibliotheque.
  ///
  /// **Ancrage semantique, jamais la page** : la page depend de l'edition, le
  /// couple sourate/verset n'en depend pas. C'est l'invariant 3 du contrat
  /// `ContentPosition`, et il compte d'autant plus que le mode verset est
  /// reflowable.
  ContentPosition versContentPosition({
    String resourceId = identifiantRessourceCoran,
    String? resourceVersionId,
  }) => ContentPosition.ayah(
    resourceId: resourceId,
    sourate: sourate,
    ayah: verset,
    resourceVersionId: resourceVersionId,
  );
}
