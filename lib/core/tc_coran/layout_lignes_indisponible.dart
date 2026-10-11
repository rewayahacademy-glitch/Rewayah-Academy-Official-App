import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'layout_madina_15.dart';
import 'port_layout_mushaf.dart';

/// La source de layout du depot : **il n'y en a pas**.
///
/// Elle existe pour le dire explicitement, et c'est tout son role. La clause
/// STOP de la specification section 7.2 est formelle : « si les donnees
/// disponibles ne permettent pas une fidelite suffisante, l'agent doit STOP et
/// documenter le manque. Il ne doit pas improviser une composition. »
///
/// **Trois manques mesures, chacun suffisant** (chiffres dans
/// `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_C.md`) :
///
/// 1. `verset.ligne` est NULL sur les 6236 versets. La colonne existe depuis
///    `0007`, l'index `verset_page_idx (mushaf_id, page_numero, ligne)` la
///    prevoit, et `0013` refuse de la remplir : le layout QPC v2 compte
///    83 668 mots contre 77 881 pour Tanzil, et la migration ne veut pas
///    deviner une correspondance sur un texte sacre.
/// 2. Aucune granularite sub-verset. Pas de table `mot`, pas de segment, et
///    `verset.page_numero` designe la page ou le verset **commence** : un
///    verset a cheval sur deux pages est attribue a une seule, donc on ne sait
///    pas couper une page au bon mot.
/// 3. Aucune police glyphe-par-page ni asset de coordonnees.
///    `UthmanTahaNaskh-Regular.otf` est une police de texte courant : la
///    largeur des lignes depend du moteur de texte, pas de l'edition.
///
/// Ce que cette implementation **ne fait pas**, et qui serait le piege : poser
/// quinze lignes reglees et y repartir le texte au juge. Le resultat
/// ressemblerait a une page du Mushaf de Medine sans en etre une, et plus rien
/// ensuite ne permettrait de distinguer une page fidele d'une page devinee.
/// Elle rend donc [DisponibiliteLayout.indisponible] et `null` : le moteur
/// affiche alors les versets exacts de la page dans le cadre exact de la page,
/// **et l'ecrit a l'usager**.
class LayoutLignesIndisponible implements PortLayoutMushaf {
  /// Cree la source vide.
  const LayoutLignesIndisponible();

  @override
  Future<DisponibiliteLayout> disponibilite() async =>
      DisponibiliteLayout.indisponible;

  @override
  Future<LayoutPage?> layoutDe(int numeroPage) async => null;
}

/// La source de layout employee par l'application.
///
/// **C'est le seul point a surcharger** : ni le moteur, ni l'ecran, ni les
/// tests ne connaissent l'implementation. Derriere le drapeau `MUSHAF_15L`
/// (`Env.mushaf15LActif`, actif en developpement et en galerie), la source est
/// la mise en page de Medine en 15 lignes ([LayoutMadina15]) ; sinon, elle
/// n'existe pas ([LayoutLignesIndisponible]) et la page dit sa composition
/// approchee.
final Provider<PortLayoutMushaf> portLayoutMushafProvider =
    Provider<PortLayoutMushaf>(
      (Ref ref) => Env.mushaf15LActif
          ? LayoutMadina15()
          : const LayoutLignesIndisponible(),
    );
