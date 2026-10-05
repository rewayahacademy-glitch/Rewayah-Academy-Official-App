// DUREE-INSECABLE-4 (reserve 4 de DUREE-INSECABLE-2) : un libelle en ecriture
// latine, pose dans une interface de droite a gauche, garde sa ponctuation a
// sa place.
//
// Sans isolement, l'algorithme bidirectionnel lit « Salle ouverte. » dans un
// paragraphe de droite a gauche : le point, neutre, rejoint le sens du
// paragraphe et s'affiche a GAUCHE du premier mot (« .Salle ouverte »).
// Isole dans son propre sens (celui de sa premiere lettre forte), le libelle
// se lit dans l'ordre de sa langue ; il reste aligne au bord de DEBUT de
// l'interface (a droite en arabe).
import 'package:flutter/widgets.dart';

/// Les lettres d'ecriture de droite a gauche (hebreu, arabe et leurs formes
/// de presentation).
final RegExp _lettreDroiteAGauche = RegExp(
  '[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF\u200F]',
);

/// Une lettre forte de gauche a droite : toute lettre hors des ecritures de
/// droite a gauche, et la marque gauche-a-droite (U+200E).
final RegExp _lettreGaucheADroite = RegExp(r'[\p{L}\u200E]', unicode: true);

/// Le sens de [texte] d'apres sa premiere lettre forte, ou `null` s'il n'en
/// a aucune (chiffres et ponctuation seuls : ils suivent l'interface).
TextDirection? sensDuContenu(String texte) {
  for (final int rune in texte.runes) {
    final String c = String.fromCharCode(rune);
    if (_lettreDroiteAGauche.hasMatch(c)) return TextDirection.rtl;
    if (_lettreGaucheADroite.hasMatch(c)) return TextDirection.ltr;
  }
  return null;
}

/// Pose [child], qui affiche [texte], dans le sens de son contenu quand il
/// differe de celui de l'interface ; le texte reste aligne au bord de debut
/// de l'interface. Dans le meme sens, [child] est rendu tel quel.
///
/// A n'envelopper qu'autour d'un texte seul (une `Row` enveloppee verrait
/// l'ordre de ses enfants inverse).
class SensDuContenu extends StatelessWidget {
  /// Isole [child] dans le sens de [texte].
  const SensDuContenu({required this.texte, required this.child, super.key});

  /// Le texte que [child] affiche.
  final String texte;

  /// Le texte rendu (`Text`, `TexteSansCoupure`).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final TextDirection interface = Directionality.of(context);
    final TextDirection? contenu = sensDuContenu(texte);
    if (contenu == null || contenu == interface) return child;
    // Le bord de debut de l'interface est le bord de FIN du contenu.
    return DefaultTextStyle.merge(
      textAlign: TextAlign.end,
      child: Directionality(textDirection: contenu, child: child),
    );
  }
}
