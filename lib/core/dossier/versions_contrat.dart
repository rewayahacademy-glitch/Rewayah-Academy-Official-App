/// La version des textes que l'on fait signer.
///
/// Une acceptation est enregistree avec sa version, et l'unicite en base porte
/// sur le triplet profil, sorte, version. **Changer cette valeur redemande donc
/// la signature a tout le monde**, ce qui est le comportement voulu : un texte
/// modifie n'est plus le texte qui a ete accepte.
///
/// Ne la faire bouger qu'en meme temps que le contenu de `t.contrat` et de
/// `t.accuse`, jamais separement.
abstract final class VersionsContrat {
  /// La version courante des conditions, du contrat enseignant et de la carte
  /// d'accuse de l'ADR-011.
  static const String courante = '2026-09';
}
