import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/chrono_vivant.dart';
import '../../core/widgets/ile_liquide.dart';
import 'chrono_salle.dart';
import 'media_salle.dart';
import 'mention_seance.dart';
import 'vue_seance.dart';

/// Standard des commandes d'appel (24/10/2026) : la pilule d'etat de la
/// salle, translucide, hauteur 36 : « ● En ligne · Visite de controle
/// possible. » (ADR-011), phrase entiere, jamais coupee ; aucun lien dessous,
/// la mention elle-meme ouvre la lecture. Telephone et ordinateur.
class PiluleEtatSalle extends StatelessWidget {
  const PiluleEtatSalle({
    required this.vue,
    this.largeurMax = double.infinity,
    this.cle = const ValueKey<String>('pilule-etat-salle'),
    this.aLaLigne = false,
    this.surface,
    this.avecChrono = false,
    this.onPause,
    this.onEtatChrono,
    super.key,
  });

  /// N3, S2 : demarrer ou terminer la pause programmee, depuis le chrono.
  /// Rendue seulement si le serveur a donne `peut_piloter` (ChronoSalle) ;
  /// nulle : la pause se lit, sans commande.
  final VoidCallback? onPause;

  /// CHRONO-ETAT : le chrono change d'etat (cinq minutes avant la fin, fin
  /// prevue) ; la salle y branche le signal sonore de qui dirige la seance.
  final ValueChanged<EtatChronoVivant>? onEtatChrono;

  /// FN-023 : la pilule porte aussi le chrono du temps restant
  /// (LIVE-CHRONO-01), quand la vue a ses bornes. Les salles du 26/10
  /// (ordinateur, telephone de l'enseignant, plein ecran) n'ont pas d'autre
  /// en-tete ; l'ancien `ChromeSeance` rend son chrono lui-meme et laisse
  /// ce drapeau a faux.
  final bool avecChrono;

  /// La surface ou la ligne se pose (la couche sombre du profil, pilote C4) ;
  /// `null` : la pilule translucide de la salle.
  final AppColorPair? surface;

  /// Fiche 1, ligne 5 (carte du profil du telephone) : etroite ou texte
  /// agrandi, la phrase passe a la ligne entre deux mots, jamais dans un mot.
  final bool aLaLigne;

  final VueSeance vue;

  /// La largeur que la pilule ne depasse pas.
  final double largeurMax;

  /// La cle de la pilule elle-meme (tests, captures).
  final Key cle;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair fond = surface ?? palette.piluleSalle;
    final TextStyle style = fond.applyTo(
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
    );
    final Widget point = SizedBox.square(
      dimension: AppSpacing.sm,
      child: DecoratedBox(
        decoration:
            (vue.connexion.etablie
                    ? palette.pointsStatut.succes
                    : palette.pointsStatut.attention)
                .pastille(),
      ),
    );
    // CHRONO-ETAT (directeur, 11/11/2026 : « j'espere que ce layout de ces
    // consignes va etre ameliore ») : UNE pilule, trois elements dans cet
    // ordre : le chrono (c'est lui qu'on cherche de l'oeil), l'etat (un seul
    // mot), la mention. Sur une ligne quand tout tient ; sinon un element
    // entier passe a la ligne, jamais la moitie d'une phrase.
    final Widget? chrono = avecChrono && vue.voitChrono
        ? ChronoSalle(
            bornes: vue.chrono!,
            connexion: vue.connexion,
            pause: vue.pause,
            onPause: onPause,
            echecPause: vue.echecPause,
            style: style,
            garderCouleur: true,
            surfaceCapsule: fond,
            dansUnePilule: true,
            sobre: !vue.conduitLaSeance,
            sonne: vue.conduitLaSeance,
            onEtat: onEtatChrono,
          )
        : null;
    // Un seul mot pour un seul etat : presence confirmee, la pilule dit « En
    // salle » ; sinon l'etat de la connexion (« En ligne », « Reconnexion »).
    final bool enSalle =
        (PorteeMediaSalle.de(context)?.presenceEnSalle ?? false) &&
        vue.connexion.etablie &&
        !vue.videoSuspendue;
    final String etat = enSalle ? t.presence.presente : vue.texteConnexion;
    final double largeurTexte = (largeurMax - 2 * AppSpacing.md).clamp(
      0,
      double.infinity,
    );
    final Widget ligne = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        ?chrono,
        // Le point et son mot ne se separent jamais ; la phrase du repli
        // audio, plus longue, peut passer sur deux lignes sans deborder.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: largeurTexte),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              point,
              Ecart.hSm,
              // ILE-SALLE : le mot qui change (« En ligne », « Reconnexion »,
              // « En salle ») se fond dans le suivant ; l'ile change de forme.
              Flexible(
                child: FonduLiquide(
                  cle: etat,
                  child: Text(etat, style: style),
                ),
              ),
            ],
          ),
        ),
        // La phrase entiere (ADR-011) ; aucun lien dessous, la mention
        // elle-meme ouvre la lecture.
        if (vue.texteMention != null)
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: largeurTexte),
            child: FonduLiquide(
              cle: vue.texteMention,
              child: MentionSeance(vue: vue, lienSousLaLigne: false),
            ),
          ),
      ],
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: largeurMax,
        minHeight: AppSpacing.xxxl + AppSpacing.xs,
      ),
      // ILE-SALLE (directeur, 11/11/2026) : la pilule est une ile liquide.
      // Quand le mot d'etat change, quand le chrono prend sa capsule teintee
      // (bientot fini, depassement, fini) ou quand la mention change de
      // longueur, sa forme suit le contenu sur les ressorts de l'effet
      // liquide, sans rebond. Au repos, rien ne bouge : pendant une
      // recitation, elle ne change que si l'etat change.
      child: IleLiquide(
        key: cle,
        // Rayon 24 : une ligne donne une pilule (hauteur 36 a 48), deux
        // lignes une carte aux coins doux.
        decoration: fond.decoration(borderRadius: AppRadius.arrondiLg),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: ligne,
      ),
    );
  }
}
