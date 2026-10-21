import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../tc_groupe/libelles_tc_groupe.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'page_etape.dart';

/// La coquille d'une page de parcours : une question, une action.
///
/// **Pages courtes, jamais un formulaire qui empile les champs** (ADR-013). La
/// coquille tient ce qui se repete d'une page a l'autre : ou l'on en est,
/// combien de temps il reste, comment revenir, et l'unique bouton qui avance.
///
/// L'estimation de temps restant n'est pas un ornement : sur ce type d'ecran,
/// l'incertitude coute plus cher que la longueur
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`, `TUT-00c`).
///
/// **Le lot C l'a remontee de `lib/features/inscription/` vers ici**, et posee
/// sur `PageShell` : c'est un composant partage, employe par l'inscription
/// comme par l'ajout d'un enfant, pas un detail de l'inscription
/// (`docs/archive/2026-09-pre-remise-a-plat/design/07-catalogue-composants.md` section 1). Elle avait son propre
/// `Scaffold`, sa propre gouttiere et son propre bandeau hors ligne : trois
/// choses que le gabarit de page tient desormais pour tout le produit.
///
/// **Lot E3 (audit d'entree du 17/10, L3) : un seul gabarit d'etape.** Elle
/// garde son API (les parcours qui l'emploient ne changent pas) mais delegue
/// a [PageEtape] : meme rangee d'etape (disque retour, progression continue,
/// « n sur N »), meme colonne bornee sur grand ecran, meme action en pilule,
/// pleine largeur sur telephone, a largeur de contenu au bord de fin
/// ailleurs. Il n'y a plus qu'une facon de compter les etapes.
class PageParcours extends StatelessWidget {
  /// Cree une page de parcours.
  const PageParcours({
    required this.numero,
    required this.total,
    required this.question,
    required this.enfant,
    required this.libelleAction,
    required this.onAction,
    super.key,
    this.explication,
    this.onRetour,
    this.enCours = false,
    this.minutesRestantes,
    this.souscription,
  });

  /// Le rang de cette page, a partir de 1.
  final int numero;

  /// Le nombre de pages du parcours.
  final int total;

  /// La question posee, en une phrase.
  final String question;

  /// Ce qui explique la question, quand elle en a besoin.
  final String? explication;

  /// Le corps de la page.
  final Widget enfant;

  /// Le libelle de l'unique action.
  final String libelleAction;

  /// L'action. `null` tant que la reponse ne permet pas d'avancer.
  final VoidCallback? onAction;

  /// Le retour a la page precedente. `null` sur la premiere.
  final VoidCallback? onRetour;

  /// Vrai pendant un envoi.
  final bool enCours;

  /// Le temps restant estime, en minutes.
  final int? minutesRestantes;

  /// Une ligne sous le bouton, pour un refus ou une precision.
  final Widget? souscription;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool telephone = AppGabarit.de(context) == Gabarit.mobile;

    return PageEtape(
      numero: numero,
      total: total,
      onRetour: onRetour,
      action: Column(
        // Telephone : le bouton prend la bande du pouce. Ailleurs : chaque
        // ligne garde sa largeur, rangee au bord de fin (voir [PageEtape]).
        crossAxisAlignment: telephone
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (souscription != null) ...<Widget>[souscription!, Ecart.vMd],
          ActionPrincipale(
            libelle: libelleAction,
            onPress: onAction,
            enCours: enCours,
            pilule: true,
            fleche: true,
          ),
          if (minutesRestantes != null) ...<Widget>[
            Ecart.vSm,
            Text(
              LibellesGroupe.insecable(
                t.inscription.tempsRestant(minutes: minutesRestantes!),
              ),
              textAlign: telephone ? TextAlign.center : TextAlign.end,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // La question et son explication passent a la ligne entre les
          // mots, jamais dans un mot : « Vérifiez votre obse / rvation » a
          // 320 px, texte x2 (COUPE-MOTS-3, revue CTRL-ROSTER-C7-1b-R).
          TexteSansCoupure(
            question,
            style: textes.headlineSmall ?? const TextStyle(),
          ),
          if (explication != null) ...<Widget>[
            Ecart.vSm,
            TexteSansCoupure(
              explication!,
              style: palette.inkMuted.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
          Ecart.vXxl,
          enfant,
        ],
      ),
    );
  }
}
