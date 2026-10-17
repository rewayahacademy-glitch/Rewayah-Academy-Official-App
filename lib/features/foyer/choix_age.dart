import 'package:flutter/material.dart';

import '../../core/accessibilite/signaler_manque.dart';
import '../../core/foyer/profil_eleve_brouillon.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/filter_pill.dart';

/// L'age d'un eleve, **une seule forme dans toute l'app** : en annees, choisi
/// dans une liste de puces bornees, jamais tape, jamais en tranche
/// (DECISION-ENTREE-2026-10-17, « Questions de l'onboarding »).
///
/// Pourquoi l'annee et non la tranche : le serveur recoit l'age exact a la
/// creation du profil (`creer_profil_enfant`, `p_age`) et en deduit trois
/// choses, dont deux sur des seuils qui ne tombent pas sur les bornes des
/// tranches (affichage simplifie jusqu'a 9 ans, camera a partir de 11 ans,
/// ADR-009) ; la tranche d'age du parcours en decoule aussi. Une tranche ne
/// permettrait pas ces deductions.
///
/// Le meme composant sert a l'ajout du profil (Foyer) et, si le serveur ne
/// connait pas encore la tranche, au parcours : meme titre, memes puces.
class ChoixAge extends StatelessWidget {
  /// Cree le choix de l'age.
  const ChoixAge({
    required this.choisi,
    required this.aide,
    required this.onChoisir,
    required this.clePuce,
    super.key,
    this.bornes = BornesAge.clientActuelle,
    this.erreur,
    this.figee = false,
  });

  /// L'age retenu, ou `null`.
  final int? choisi;

  /// La phrase sous le titre : pourquoi l'age est demande, ici. Une unite
  /// (« 6 ans ») y est deja rendue insecable par l'appelant.
  final String aide;

  /// Appele avec l'age touche.
  final ValueChanged<int> onChoisir;

  /// La cle de la puce d'un age (chaque ecran garde ses cles de test).
  final Key Function(int age) clePuce;

  /// Les ages proposes, bornes incluses.
  final BornesAge bornes;

  /// Le message d'erreur sous les puces, ou `null`.
  final String? erreur;

  /// Vrai pendant l'envoi : le choix est fige le temps de la reponse.
  final bool figee;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.foyer.ajout.identite.age,
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(
          aide,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        // Choix de formulaire, pas un filtre : l'age du profil.
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (int age = bornes.min; age <= bornes.max; age++)
              FilterPill(
                key: clePuce(age),
                libelle: '$age',
                retenue: age == choisi,
                // Jamais grisee (BOUTONS-GRISES-1) : pendant l'envoi, le
                // choix est fige le temps de la reponse, et l'appui le dit
                // au lecteur d'ecran au lieu de rester muet.
                onPress: figee
                    ? () => signalerManque(
                        context,
                        t.foyer.ajout.identite.ageFige,
                      )
                    : () => onChoisir(age),
              ),
          ],
        ),
        if (erreur case final String message) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: palette.inkAlert.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
