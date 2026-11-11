import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/chrono_vivant.dart';
import '../../core/widgets/ile_liquide.dart';
import '../../core/widgets/permanent_notice.dart' show PointEnregistrement;
import '../../core/widgets/pressable.dart';
import 'chrono_salle.dart';
import 'media_salle.dart';
import 'mention_seance.dart';
import 'vue_seance.dart';

/// Standard des commandes d'appel (24/10/2026) : la pilule d'etat de la
/// salle, translucide, hauteur 36. Telephone et ordinateur.
///
/// ILE-SALLE (directeur, 11/11/2026 ; D-007 approuvee) : la pilule est une
/// **ile liquide** ([IleLiquide]) a deux formes.
///
/// - **Repliee, au repos** : le cercle qui se remplit et le temps restant,
///   un point d'etat (jamais la couleur seule : un disque quand tout va bien,
///   une icone d'avertissement sinon), et, tant qu'une situation dure, un
///   signe court (camera barree pour « image coupee ») ; la mention de
///   controle garde son point neutre permanent. Rien d'autre : la pilule ne
///   recouvre plus la page du Coran.
/// - **Depliee** quand une phrase arrive (mot d'etat qui change, situation
///   de reseau, mention a l'entree) : la phrase entiere, puis l'ile se
///   replie seule apres [AppMouvement.ilePassage] (6 s), ou
///   [AppMouvement.ileMention] (10 s) pour la mention a l'entree.
/// - **Un appui** (doigt ou clavier) la redeplie pour le meme temps ; la
///   cible fait 48 de haut sans grossir l'ile a l'oeil.
/// - **Ce qui empeche d'entendre reste deplie** tant que ca dure (lien perdu,
///   reconnexion, plus de reseau).
///
/// Le lecteur d'ecran lit toujours l'etat et la mention entiers, repliee ou
/// non. La mention n'est jamais rendue au controleur (la vue n'en a pas).
/// Le chrono reste au meme endroit dans les deux formes : il n'est jamais
/// recree (son etat et son signal sonore ne repartent pas de zero).
class PiluleEtatSalle extends StatefulWidget {
  const PiluleEtatSalle({
    required this.vue,
    this.largeurMax = double.infinity,
    this.cle = const ValueKey<String>('pilule-etat-salle'),
    this.aLaLigne = false,
    this.surface,
    this.avecChrono = false,
    this.onPause,
    this.onEtatChrono,
    this.microOuvert = false,
    super.key,
  });

  /// Lot CORAN-ELEVE (pilote, 11/11/2026) : le micro local est ouvert. Les
  /// commandes de l'appel se masquent au repos ; l'ile repliee garde alors
  /// le signe du micro (icone et nom lu, jamais la couleur seule) : on sait
  /// toujours qu'on est entendu. Rien quand il est ferme.
  final bool microOuvert;

  /// Le signe « micro ouvert » de l'ile repliee (tests).
  static const Key cleMicroOuvert = ValueKey<String>('pilule-etat-micro');

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

  /// La zone d'appui qui redeplie l'ile repliee (tests).
  static const Key cleDeplier = ValueKey<String>('pilule-etat-deplier');

  /// Le contenu de l'ile depliee (tests).
  static const Key cleDepliee = ValueKey<String>('pilule-etat-depliee');

  /// Les signes de l'ile repliee (tests).
  static const Key cleRepliee = ValueKey<String>('pilule-etat-repliee');

  @override
  State<PiluleEtatSalle> createState() => _PiluleEtatSalleEtat();
}

class _PiluleEtatSalleEtat extends State<PiluleEtatSalle> {
  bool _deplie = false;
  Timer? _replier;
  String? _mot;
  String? _mention;

  /// Le mot d'etat : « En salle » quand la presence est confirmee, sinon
  /// l'etat de la connexion (« En ligne », « Reconnexion… », image coupee).
  String _motDe(BuildContext context) {
    final VueSeance vue = widget.vue;
    final bool enSalle =
        (PorteeMediaSalle.de(context)?.presenceEnSalle ?? false) &&
        vue.connexion.etablie &&
        !vue.videoSuspendue;
    return enSalle ? t.presence.presente : vue.texteConnexion;
  }

  /// Deplie l'ile pour [duree], puis la replie (sans `setState` : l'appelant
  /// est deja en construction, ou le demande).
  void _ouvrir(Duration duree) {
    _deplie = true;
    _replier?.cancel();
    _replier = Timer(duree, () {
      if (mounted) setState(() => _deplie = false);
    });
  }

  /// Une phrase nouvelle (mot d'etat, mention) deplie l'ile ; a l'entree,
  /// la mention reste depliee plus longtemps.
  void _relire() {
    final String mot = _motDe(context);
    final String? mention = widget.vue.texteMention;
    final bool entree = _mot == null;
    if (entree) {
      _ouvrir(
        mention != null ? AppMouvement.ileMention : AppMouvement.ilePassage,
      );
    } else if (mention != _mention && mention != null) {
      _ouvrir(AppMouvement.ileMention);
    } else if (mot != _mot) {
      _ouvrir(AppMouvement.ilePassage);
    }
    _mot = mot;
    _mention = mention;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _relire();
  }

  @override
  void didUpdateWidget(PiluleEtatSalle ancien) {
    super.didUpdateWidget(ancien);
    _relire();
  }

  @override
  void dispose() {
    _replier?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = widget.vue;
    final AppPalette palette = AppPalette.of(context);
    final AppColorPair fond = widget.surface ?? palette.piluleSalle;
    final TextStyle style = fond.applyTo(
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
    );
    final String etat = _mot ?? _motDe(context);
    // Ce qui empeche d'entendre reste dit tant que ca dure.
    final bool bloquant = !vue.connexion.etablie;
    final bool deplie = _deplie || bloquant;

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
    // CHRONO-ETAT (directeur, 11/11/2026) : UNE pilule ; le chrono d'abord
    // (c'est lui qu'on cherche de l'oeil), puis l'etat, puis la mention.
    final Widget? chrono = widget.avecChrono && vue.voitChrono
        ? ChronoSalle(
            bornes: vue.chrono!,
            connexion: vue.connexion,
            pause: vue.pause,
            onPause: widget.onPause,
            echecPause: vue.echecPause,
            style: style,
            garderCouleur: true,
            surfaceCapsule: fond,
            dansUnePilule: true,
            sobre: !vue.conduitLaSeance,
            sonne: vue.conduitLaSeance,
            onEtat: widget.onEtatChrono,
          )
        : null;
    final double largeurTexte = (widget.largeurMax - 2 * AppSpacing.md).clamp(
      0,
      double.infinity,
    );

    // Depliee : le point et son mot (jamais separes), la mention entiere.
    final Widget depliee = Wrap(
      key: PiluleEtatSalle.cleDepliee,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: largeurTexte),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              point,
              Ecart.hSm,
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
            child: MentionSeance(vue: vue, lienSousLaLigne: false),
          ),
      ],
    );

    // Repliee : des signes, jamais une phrase ; le lecteur d'ecran, lui, lit
    // l'etat et la mention entiers.
    const double icone = AppSpacing.lg;
    final Widget repliee = Row(
      key: PiluleEtatSalle.cleRepliee,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          label: etat,
          child: vue.connexion.etablie
              ? point
              : IconTheme(
                  data: IconThemeData(color: fond.onBackground, size: icone),
                  child: Icon(AppIcons.avertissement.repos),
                ),
        ),
        if (widget.microOuvert) ...<Widget>[
          // Un ecart serre : a 320 en texte x2, l'ile reste sur une ligne.
          Ecart.hXs,
          Semantics(
            key: PiluleEtatSalle.cleMicroOuvert,
            label: t.salle.microOuvert,
            child: ExcludeSemantics(
              child: IconTheme(
                data: IconThemeData(color: fond.onBackground, size: icone),
                child: Icon(AppIcons.micro.repos),
              ),
            ),
          ),
        ],
        if (vue.videoSuspendue) ...<Widget>[
          Ecart.hSm,
          ExcludeSemantics(
            child: IconTheme(
              data: IconThemeData(color: fond.onBackground, size: icone),
              child: Icon(AppIcons.cameraCoupee.repos),
            ),
          ),
        ],
        // Sans chrono (Interface guidee, bornes inconnues), le mot reste :
        // une ile vide ne dirait rien.
        if (chrono == null) ...<Widget>[
          Ecart.hSm,
          Flexible(
            child: ExcludeSemantics(child: Text(etat, style: style)),
          ),
        ],
        if (vue.texteMention != null) ...<Widget>[
          Ecart.hSm,
          Semantics(
            label: vue.texteMention,
            // Le point neutre de la mention permanente ; d'alerte et
            // clignotant pendant une visite annoncee (MentionSeance).
            child: PointEnregistrement(
              clignote: vue.pointClignote,
              neutre: !vue.visiteVisible,
            ),
          ),
        ],
      ],
    );

    final Widget ile = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.xxxl + AppSpacing.xs,
      ),
      child: IleLiquide(
        key: widget.cle,
        // Rayon 24 : une ligne donne une pilule (hauteur 36 a 48), deux
        // lignes une carte aux coins doux.
        decoration: fond.decoration(borderRadius: AppRadius.arrondiLg),
        alignement: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            ?chrono,
            FonduLiquide(cle: deplie, child: deplie ? depliee : repliee),
          ],
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.largeurMax),
      // La cible d'appui fait 48 de haut ; l'ile, 36 : la marge est
      // invisible. Seule l'ile repliee se touche ; depliee, la mention et la
      // pause gardent leurs propres commandes.
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.titreEcran),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              heightFactor: 1,
              child: ile,
            ),
          ),
          if (!deplie)
            Positioned.fill(
              child: Pressable(
                key: PiluleEtatSalle.cleDeplier,
                onPress: () => setState(() => _ouvrir(AppMouvement.ilePassage)),
                libelleSemantique: t.salle.ile.deplierEtat,
                respecterCibleTactile: false,
                arrondiFocus: AppRadius.arrondiLg,
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}
