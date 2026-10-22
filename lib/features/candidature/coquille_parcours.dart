// La coquille d'une etape du parcours du candidat (CAND-01) : la rangee
// d'etape en haut (progression continue, « n sur N »), la question, son
// explication, le corps ; en bas « Continuer » (le seul bouton plein) et
// « Retour ». Posee sur le gabarit partage [PageEtape], comme l'inscription
// (`CoquilleEtape`) : meme barre, meme colonne bornee, memes boutons.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/page_etape.dart';

/// Une etape du parcours, en bas « Retour » et le bouton plein.
class CoquilleParcours extends StatelessWidget {
  /// Cree la coquille.
  const CoquilleParcours({
    required this.numero,
    required this.total,
    required this.titre,
    required this.enfant,
    required this.onRetour,
    super.key,
    this.explication,
    this.libelleAction,
    this.onAction,
    this.enCours = false,
    this.souscription,
    this.entete,
    this.choix = false,
    this.fleche = true,
  });

  /// Le rang de l'etape, a partir de 1.
  final int numero;

  /// Le nombre d'etapes du parcours.
  final int total;

  /// La question, en une phrase.
  final String titre;

  /// L'explication de la question.
  final String? explication;

  /// Un bloc au-dessus de la question (« L'academie vous demande... »).
  final Widget? entete;

  /// Le corps de l'etape.
  final Widget enfant;

  /// Le libelle du bouton plein ; `null` : aucun bouton plein.
  final String? libelleAction;

  /// Ce que fait le bouton plein.
  final VoidCallback? onAction;

  /// Vrai pendant un envoi.
  final bool enCours;

  /// Une ligne au-dessus du bouton (consigne manquante, erreur, precision).
  final Widget? souscription;

  /// Le retour : etape precedente, ou sortie du parcours a la premiere.
  final VoidCallback onRetour;

  /// Vrai pour une etape de choix entre des cartes : la colonne large, ou les
  /// cartes passent en bento sur grand ecran.
  final bool choix;

  /// Vrai : une fleche suit le libelle du bouton plein.
  final bool fleche;

  /// La cle du bouton « Retour ».
  static const Key retourKey = ValueKey<String>('parcours-retour');

  /// La cle du bouton plein.
  static const Key actionKey = ValueKey<String>('parcours-action');

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool telephone = AppGabarit.de(context) == Gabarit.mobile;

    return PageEtape(
      numero: numero,
      total: total,
      // Le retour est en bas, avec « Continuer » : pas de disque en haut.
      colonneLarge: choix,
      action: Column(
        crossAxisAlignment: telephone
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (souscription != null) ...<Widget>[souscription!, Ecart.vMd],
          if (libelleAction != null)
            ActionPrincipale(
              key: actionKey,
              libelle: libelleAction!,
              onPress: enCours ? null : onAction,
              enCours: enCours,
              pilule: true,
              fleche: fleche,
              // Demande du directeur du 22/10 : « Continuer » ne doit pas
              // paraitre desactive. Il est toujours actif (aucun bouton grise,
              // K-56) : l'aplat plein le dit, la lavande douce le cachait.
              affirmee: true,
            ),
          Ecart.vXs,
          Center(
            child: ActionPrincipale(
              key: retourKey,
              libelle: t.commun.retour,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: enCours ? null : onRetour,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (entete != null) ...<Widget>[entete!, Ecart.vLg],
          TexteSansCoupure(
            titre,
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
          Ecart.vXl,
          enfant,
        ],
      ),
    );
  }
}

/// Une ligne d'indication sous la question : ce qui manque pour continuer
/// (K-59), annoncee au lecteur d'ecran.
class IndicationParcours extends StatelessWidget {
  /// Cree la ligne.
  const IndicationParcours({required this.message, super.key});

  /// Le message.
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: AppPalette.of(context).inkAlert
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    ),
  );
}
