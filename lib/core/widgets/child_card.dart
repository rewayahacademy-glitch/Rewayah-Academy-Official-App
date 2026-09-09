import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'app_card.dart';
import 'avatar_tile.dart';
import 'status_pill.dart';

/// Ce qu'un enfant du foyer est en train de vivre.
///
/// Une hierarchie scellee plutot qu'une enumeration plus des champs
/// facultatifs : chaque etat porte **exactement** les donnees dont il a besoin,
/// et il devient impossible de construire une carte « cours imminent » sans
/// heure, ou « seance annulee » sans motif.
sealed class EtatEnfant {
  const EtatEnfant();
}

/// Un prochain cours est prevu, et ce n'est pas pour tout de suite.
final class EnfantProchainCours extends EtatEnfant {
  /// Cree l'etat nominal.
  const EnfantProchainCours(this.quand);

  /// Quand a lieu le prochain cours, deja mis en phrase par l'ecran :
  /// « Aujourd'hui a 17:00, avec Youssef ».
  final String quand;
}

/// Aucun creneau n'est pose : sans eux, aucun enseignant ne peut prendre
/// l'enfant en charge.
final class EnfantSansPlanning extends EtatEnfant {
  /// Cree l'etat sans planning.
  const EnfantSansPlanning();
}

/// Le cours commence dans moins de cinq minutes.
final class EnfantImminent extends EtatEnfant {
  /// Cree l'etat imminent.
  const EnfantImminent({required this.heure, required this.minuteur});

  /// L'heure du cours.
  final String heure;

  /// Le temps restant, en clair : « Dans 4 min ».
  final String minuteur;
}

/// Le cours a commence.
final class EnfantEnCours extends EtatEnfant {
  /// Cree l'etat en direct.
  const EnfantEnCours({required this.enseignant, required this.depuis});

  /// Le prenom de l'enseignant.
  final String enseignant;

  /// Depuis combien de temps, en clair : « Commence il y a 12 min ».
  final String depuis;
}

/// Aucun enseignant n'a encore pris l'enfant en charge.
final class EnfantEnRecherche extends EtatEnfant {
  /// Cree l'etat de recherche.
  const EnfantEnRecherche(this.depuis);

  /// Depuis quand la demande est deposee, deja mis en phrase par l'ecran.
  final String depuis;
}

/// La seance n'aura pas lieu.
final class EnfantSeanceAnnulee extends EtatEnfant {
  /// Cree l'etat annule.
  const EnfantSeanceAnnulee({required this.motif, required this.propose});

  /// Le motif, en une phrase. Jamais un code.
  final String motif;

  /// Ce qui est propose a la place.
  final String propose;
}

/// La carte d'un enfant du foyer, avec ses sept etats.
///
/// **C'est elle qui porte la valeur de `TUT-01`** : un parent y lit d'un coup
/// d'oeil comment va chacun de ses enfants, et ce qu'il doit confirmer
/// (`docs/design/07-catalogue-composants.md` section 3).
///
/// Deux regles qui ne se devinent pas :
///
/// - **la carte imminente ne pulse pas.** Une seule zone pulse par ecran, et
///   c'est celle d'`ELV-02`, sur l'ecran de l'enfant. Quatre cartes qui
///   battraient ensemble sur l'ecran du parent annuleraient le sens des
///   quatre (`04-systeme-mouvement.md` section 4) ;
/// - **le bouton « Assister » est la fonction de confiance la plus forte du
///   produit.** Il entre en observateur muet, et l'enseignant le voit arriver.
class ChildCard extends StatelessWidget {
  /// Cree une carte enfant.
  const ChildCard({
    required this.prenom,
    required this.etat,
    super.key,
    this.urlAvatar,
    this.onOuvrir,
    this.onPoserHoraire,
    this.onAssister,
    this.horsLigne = false,
    this.onReessayer,
  });

  /// Le prenom de l'enfant.
  final String prenom;

  /// Ce que l'enfant est en train de vivre.
  final EtatEnfant etat;

  /// L'URL signee de sa photo, quand il en a une.
  final String? urlAvatar;

  /// Ouvre le detail de l'enfant.
  final VoidCallback? onOuvrir;

  /// Ouvre la pose de creneaux. N'a de sens que sur [EnfantSansPlanning].
  final VoidCallback? onPoserHoraire;

  /// Entre en observateur. N'a de sens que sur [EnfantEnCours].
  final VoidCallback? onAssister;

  /// Vrai quand l'appareil n'a pas de reseau.
  ///
  /// **La carte reste**, la donnee volatile se grise, et la mention remplace
  /// le bouton. Un message d'erreur brut n'apparait jamais.
  final bool horsLigne;

  /// Relance la lecture. N'est rendu que hors ligne.
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final AppColorPair paire = _paire(palette);
    // Le filet fort a gauche, et non tout autour : il signale l'imminence sans
    // faire de la carte une selection (`07-catalogue-composants.md` section 3).
    final bool avecLisere = etat is EnfantImminent;

    final Widget contenu = Padding(
      padding: EdgeInsets.all(metriques.marge),
      child: _corps(context, palette, paire),
    );

    return AppCard(
      surface: paire,
      onPress: onOuvrir,
      libelleSemantique: _libelleSemantique(),
      // « Aucun planning » porte un contour `borderStrong` tout autour, et non
      // le liseré gauche de l'imminence : c'est le registre que
      // `07-catalogue-composants.md` section 3 lui fixe.
      contourFort: etat is EnfantSansPlanning,
      marge: 0,
      child: avecLisere
          ? ClipRRect(
              borderRadius: metriques.arrondi,
              child: Row(
                // Le liseré prend toute la hauteur de la carte : c'est ce que
                // fait `stretch` dans une Row, dont l'axe transversal est la
                // hauteur.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    width: AppSpacing.xs,
                    child: ColoredBox(
                      color: palette.borderStrong.asBorderSide().color,
                    ),
                  ),
                  Expanded(child: contenu),
                ],
              ),
            )
          : contenu,
    );
  }

  Widget _corps(BuildContext context, AppPalette palette, AppColorPair paire) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AvatarTile(prenom: prenom, urlSignee: urlAvatar),
        Ecart.hLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                prenom,
                style: paire.applyTo(textes.titleMedium ?? const TextStyle()),
              ),
              ..._detail(context, palette, paire, textes),
              ..._action(context),
            ],
          ),
        ),
        if (onOuvrir != null) ...<Widget>[
          Ecart.hSm,
          IconTheme(
            data: IconThemeData(color: paire.onBackground, size: AppSpacing.xl),
            child: Icon(AppIcons.chevron.repos),
          ),
        ],
      ],
    );
  }

  /// La ligne qui dit ou en est l'enfant.
  ///
  /// Hors ligne, la donnee volatile passe a l'encre secondaire : elle reste
  /// lisible, et elle dit d'elle-meme qu'elle n'est plus fraiche.
  List<Widget> _detail(
    BuildContext context,
    AppPalette palette,
    AppColorPair paire,
    TextTheme textes,
  ) {
    final TextStyle base = textes.bodyMedium ?? const TextStyle();
    final TextStyle style = horsLigne
        ? palette.encreSecondaireSur(paire).applyTo(base)
        : paire.applyTo(base);

    return switch (etat) {
      final EnfantProchainCours e => <Widget>[
        Ecart.vXs,
        Text(e.quand, style: style),
      ],
      EnfantSansPlanning() => <Widget>[
        Ecart.vXs,
        Text(t.tuteur.accueil.sansCreneau(prenom: prenom), style: style),
      ],
      final EnfantImminent e => <Widget>[
        Ecart.vSm,
        StatusPill(libelle: t.etat.imminent, ton: TonEtat.accent),
        Ecart.vXs,
        Text('${e.heure} · ${e.minuteur}', style: style),
      ],
      final EnfantEnCours e => <Widget>[
        Ecart.vSm,
        StatusPill(libelle: t.etat.enDirect, ton: TonEtat.succes),
        Ecart.vXs,
        Text(t.tuteur.accueil.enCours(prenom: e.enseignant), style: style),
        Text(e.depuis, style: style),
      ],
      final EnfantEnRecherche e => <Widget>[
        Ecart.vSm,
        StatusPill(libelle: t.tuteur.accueil.enRecherche, ton: TonEtat.neutre),
        Ecart.vXs,
        // « Carte normale, encre `inkMuted` » (`07-catalogue-composants.md`
        // section 3) : l'encre attenuee nommee, et non l'encre secondaire que
        // `encreSecondaireSur` choisit pour la surface.
        Text(
          e.depuis,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
      final EnfantSeanceAnnulee e => <Widget>[
        Ecart.vSm,
        StatusPill(libelle: t.etat.annule, ton: TonEtat.alerte),
        Ecart.vXs,
        Text(e.motif, style: style),
        Text(e.propose, style: style),
      ],
    };
  }

  /// Ce que la carte propose de faire.
  ///
  /// Hors ligne, **aucune action n'est rendue** : un bouton qui echouerait
  /// apres le geste coute plus cher en confiance qu'un bouton absent
  /// (`02-regles-ux.md` section 10). Reste la mention et « Reessayer ».
  List<Widget> _action(BuildContext context) {
    if (horsLigne) {
      return <Widget>[
        Ecart.vSm,
        Text(
          t.reseau.syncImpossible,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
          ),
        ),
        if (onReessayer != null) ...<Widget>[
          Ecart.vXs,
          ActionPrincipale(
            libelle: t.commun.reessayer,
            onPress: onReessayer,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
        ],
      ];
    }

    return switch (etat) {
      EnfantSansPlanning() when onPoserHoraire != null => <Widget>[
        Ecart.vMd,
        ActionPrincipale(
          libelle: t.tuteur.accueil.poserDesHeures,
          onPress: onPoserHoraire,
          niveau: NiveauAction.secondaire,
          pleineLargeur: false,
        ),
      ],
      EnfantEnCours() when onAssister != null => <Widget>[
        Ecart.vMd,
        ActionPrincipale(
          libelle: t.tuteur.accueil.assister,
          onPress: onAssister,
          pleineLargeur: false,
        ),
      ],
      _ => const <Widget>[],
    };
  }

  /// La paire de la carte.
  ///
  /// Aucun aplat sature : un foyer de quatre enfants dont deux vont mal ne
  /// doit pas ressembler a un tableau d'alarmes
  /// (`01-systeme-visuel.md` section 3).
  AppColorPair _paire(AppPalette palette) => switch (etat) {
    EnfantSansPlanning() => palette.washWarning,
    EnfantImminent() => palette.washAccent,
    EnfantSeanceAnnulee() => palette.washAlert,
    EnfantProchainCours() ||
    EnfantEnCours() ||
    EnfantEnRecherche() => palette.surfaceRaised,
  };

  /// Ce que le lecteur d'ecran annonce.
  String _libelleSemantique() => switch (etat) {
    final EnfantProchainCours e => '$prenom, ${e.quand}',
    EnfantSansPlanning() => t.tuteur.accueil.sansCreneau(prenom: prenom),
    final EnfantImminent e => '$prenom, ${t.etat.imminent}, ${e.minuteur}',
    final EnfantEnCours e =>
      '$prenom, ${t.etat.enDirect}, ${t.tuteur.accueil.enCours(prenom: e.enseignant)}',
    final EnfantEnRecherche e =>
      '$prenom, ${t.tuteur.accueil.enRecherche}, ${e.depuis}',
    final EnfantSeanceAnnulee e => '$prenom, ${t.etat.annule}, ${e.motif}',
  };
}
