import 'package:flutter/widgets.dart';

/// L'emplacement de la ligne « Communaute enseignants » sur Aujourd'hui
/// (`ENS-02`, `JourneePage`) : **pose une fois par le socle (COM-F, complements
/// COM-0b, 02_DEC-10), rempli par la voie COM-COMU** dans ce fichier, sans
/// rouvrir `journee_page.dart` (`02_DECOUPAGE`, regle des fichiers 3).
///
/// La Communaute est un raccourci, jamais une destination de la barre
/// (QUESTIONS Q2 : l'enseignant a deja quatre destinations sur quatre). Elle
/// mene a `Routes.enseignantCommunaute`, dont le retour ramene a Aujourd'hui.
///
/// **Pas un cinquieme bloc** (K-42, « Quatre blocs, pas un de plus ») : la
/// page le pose a la fin de « Ma journee », bloc toujours rendu, et jamais
/// dans « Alertes utiles », qui n'est rendu que s'il n'est pas vide.
///
/// **Vide tant que la voie ne le remplit pas** : il ne rend rien, n'occupe
/// aucune place et ne change pas le rendu de la page hote.
///
/// **Contrat d'ecart, fixe par le socle** : la page dit, des COM-F-b, l'ecart
/// a poser avant le contenu ([ecartAvant], celui qui separe les lignes de
/// « Ma journee ») ; la voie COM-COMU le rend devant son contenu, et seulement
/// quand elle rend quelque chose.
class EntreeCommunaute extends StatelessWidget {
  /// Cree l'emplacement.
  const EntreeCommunaute({super.key, this.ecartAvant});

  /// L'ecart a poser avant le contenu, ou `null`. Jamais rendu tant que
  /// l'emplacement est vide.
  final Widget? ecartAvant;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
