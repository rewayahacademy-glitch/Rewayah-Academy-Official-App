import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../seance_famille/seance_famille.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_mouvement.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'status_pill.dart';

/// Les deux etats de seance qu'un coup d'oeil doit reconnaitre, partout ou
/// une seance apparait (ON-AIR-1, ANNUL-VIS-1, demande du directeur du
/// 01/10/2026).
enum EtatPastilleSeance {
  /// La seance a demarre et n'est pas terminee. Calcule cote serveur.
  enDirect,

  /// La seance n'aura pas lieu (annulee, annulee tardivement).
  annulee,
}

/// L'etat de pastille d'un etat de seance de la famille, ou `null` quand
/// l'etat n'est ni « en direct » ni « annulee ».
///
/// Table unique : une seance prolongee est encore en direct, une annulation
/// tardive reste une annulation (la ligne d'etat dit la nuance).
EtatPastilleSeance? etatPastilleDe(EtatSeanceFamille etat) => switch (etat) {
  EtatSeanceFamille.enDirect ||
  EtatSeanceFamille.prolongee => EtatPastilleSeance.enDirect,
  EtatSeanceFamille.annulee ||
  EtatSeanceFamille.annuleeTardive => EtatPastilleSeance.annulee,
  _ => null,
};

/// La pastille d'etat de seance : **le seul composant** qui dit « En direct »
/// ou « Annulee », pour tous les roles et tous les ecrans.
///
/// - **En direct** : pilule douce de la famille succes, un point qui pulse
///   doucement ([AppMouvement.pulsationDirect], [AppMouvement.pulsationCourbe]).
///   Le battement dure [AppMouvement.battementsDirect] cycles puis s'arrete
///   (WCAG 2.2.2) ; il ne demarre pas du tout quand l'utilisateur reduit les
///   animations. Dans tous les cas le mot « En direct » et le point restent.
/// - **Annulee** : pilule douce de la famille alerte (la paire `washAlert` du
///   theme, aucun rouge invente) et l'icone d'annulation devant le mot.
///
/// **Jamais la couleur seule** : le mot, plus un point ou une icone.
class PastilleEtatSeance extends StatelessWidget {
  /// Cree la pastille. [libelle] remplace le mot par defaut quand l'ecran
  /// dit plus (« Seance en direct »), jamais pour dire autre chose.
  const PastilleEtatSeance({required this.etat, super.key, this.libelle});

  /// L'etat a montrer.
  final EtatPastilleSeance etat;

  /// Le mot, ou `null` pour le mot par defaut de l'etat.
  final String? libelle;

  /// Le mot par defaut de [etat].
  static String libelleDe(EtatPastilleSeance etat) => switch (etat) {
    EtatPastilleSeance.enDirect => t.etat.enDirect,
    EtatPastilleSeance.annulee => t.etat.seanceAnnulee,
  };

  @override
  Widget build(BuildContext context) => switch (etat) {
    EtatPastilleSeance.enDirect => StatusPill(
      libelle: libelle ?? libelleDe(etat),
      ton: TonEtat.succes,
      marqueur: const PointDirect(),
    ),
    EtatPastilleSeance.annulee => StatusPill(
      libelle: libelle ?? libelleDe(etat),
      ton: TonEtat.alerte,
      marqueur: const _IconeAnnulation(),
    ),
  };
}

/// Le point d'« En direct » : un disque de statut et, derriere, un halo qui
/// grossit et s'efface.
///
/// Le halo ne pousse rien autour de lui (il deborde sans prendre de place) ;
/// aucune opacite n'est posee sur le texte.
class PointDirect extends StatefulWidget {
  /// Cree le point. [cerclage] pose un anneau de la couleur du fond (le point
  /// d'un profil, pose sur une photo).
  const PointDirect({
    super.key,
    this.cerclage,
    this.diametre = StatusPill.diametrePastille,
  });

  /// Le diametre du point.
  final double diametre;

  /// La couleur de l'anneau, ou `null` sans anneau.
  final AppColorPair? cerclage;

  @override
  State<PointDirect> createState() => _PointDirectState();
}

class _PointDirectState extends State<PointDirect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cycle = AnimationController(
    vsync: this,
    duration: AppMouvement.pulsationDirect,
  )..addStatusListener(_suite);
  int _faits = 0;
  bool _reduit = false;
  bool _decide = false;

  void _suite(AnimationStatus statut) {
    if (statut != AnimationStatus.completed) return;
    _faits++;
    if (_faits < AppMouvement.battementsDirect) {
      _cycle.forward(from: 0);
    } else {
      // Le point au repos : valeur 0, halo nul.
      _cycle.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduit = AppMouvement.mouvementReduit(context);
    if (_decide && reduit == _reduit) return;
    _decide = true;
    _reduit = reduit;
    if (reduit) {
      // Mouvement reduit : point fixe, aucun battement.
      _cycle.stop();
      _cycle.value = 0;
    } else if (_faits < AppMouvement.battementsDirect) {
      _cycle.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _cycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BoxDecoration disque = palette.pointsStatut.succes.pastille();
    final AppColorPair? anneau = widget.cerclage;
    final BoxDecoration point = anneau == null
        ? disque
        : palette.pointsStatut.succes.pastille(cerclage: anneau);
    return SizedBox.square(
      dimension: widget.diametre,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          AnimatedBuilder(
            animation: _cycle,
            builder: (BuildContext _, Widget? halo) {
              // Un battement : le halo grossit en s'effacant, une fois par
              // cycle. Au repos (valeur 0), il n'y a rien a peindre.
              if (_cycle.value <= 0) return const SizedBox.shrink();
              final double avance = AppMouvement.pulsationCourbe.transform(
                math.min(1, _cycle.value),
              );
              return Opacity(
                opacity: AppMouvement.opaciteHaloDirect * (1 - avance),
                child: Transform.scale(
                  scale: 1 + AppMouvement.ampleurHaloDirect * avance,
                  child: halo,
                ),
              );
            },
            child: SizedBox.square(
              key: const ValueKey<String>('pastille-direct-halo'),
              dimension: widget.diametre,
              child: DecoratedBox(decoration: disque),
            ),
          ),
          SizedBox.square(
            key: const ValueKey<String>('pastille-direct-point'),
            // Le point porte l'anneau, pas le halo.
            dimension: widget.diametre,
            child: DecoratedBox(decoration: point),
          ),
        ],
      ),
    );
  }
}

/// L'icone d'annulation de la pastille « Annulee », a l'encre de la paire.
class _IconeAnnulation extends StatelessWidget {
  const _IconeAnnulation();

  /// Taille de l'icone : deux fois le point, pour rester lisible.
  static const double _taille = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final AppColorPair paire = AppPalette.of(context).washAlert;
    return Icon(
      AppIcons.interdit.actif,
      key: const ValueKey<String>('pastille-annulee-icone'),
      size: _taille,
      color: paire.onBackground,
    );
  }
}

/// Le marqueur d'une seance annulee quand il n'y a pas la place d'une
/// pastille (le coin d'un avatar du selecteur de profils) : un disque de la
/// paire d'alerte et l'icone d'annulation. **L'icone remplace le point**, elle
/// ne se pose pas a cote : le mot « Annulee » est dit juste dessous par
/// l'ecran qui l'emploie.
class PointAnnulation extends StatelessWidget {
  /// Cree le marqueur. [cerclage] pose un anneau de la couleur du fond.
  const PointAnnulation({super.key, this.cerclage});

  /// Diametre du disque.
  static const double diametre = AppSpacing.xl;

  /// La couleur de l'anneau, ou `null` sans anneau.
  final AppColorPair? cerclage;

  @override
  Widget build(BuildContext context) {
    final AppColorPair paire = AppPalette.of(context).washAlert;
    final AppColorPair? anneau = cerclage;
    return SizedBox.square(
      key: const ValueKey<String>('point-annulation'),
      dimension: diametre,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: paire.background,
          border: anneau == null
              ? null
              : Border.fromBorderSide(
                  BorderSide(
                    color: anneau.background,
                    width: AppSpacing.xs / 2,
                  ),
                ),
        ),
        child: Icon(
          AppIcons.interdit.actif,
          size: AppSpacing.md,
          color: paire.onBackground,
        ),
      ),
    );
  }
}

/// La paire de surface d'une carte de seance : la surface elevee, ou la
/// surface enfoncee quand la seance est annulee.
///
/// **La carte annulee s'attenue par sa surface, jamais par une opacite** :
/// une opacite fait tomber le texte sous le seuil de contraste. L'encre
/// secondaire (`inkMuted`) tient 4,5:1 sur la surface enfoncee, mesure dans
/// `test/core/widgets/pastille_etat_seance_test.dart`.
AppColorPair surfaceCarteSeance(AppPalette palette, {required bool annulee}) =>
    annulee ? palette.surfaceSunken : palette.surfaceRaised;

/// L'heure d'une seance : barree et attenuee quand la seance est annulee,
/// sans changer sa taille ni sa police.
///
/// Le trait ne se lit pas a l'oreille : le lecteur d'ecran annonce
/// « Annulee : {valeur} », une formule neutre qui vaut pour une heure, une
/// plage ou une date (le composant ne sait pas laquelle il porte). Quand
/// plusieurs valeurs d'une meme carte sont barrees, **une seule** porte
/// l'annonce ([annoncer]) : les autres se lisent telles quelles.
class TexteHeureSeance extends StatelessWidget {
  /// Cree l'heure.
  const TexteHeureSeance({
    required this.heure,
    required this.annulee,
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.annoncer = true,
  });

  /// La valeur : une heure, une plage ou une date, deja rendue (« 10:00 »,
  /// « 10:00 - 11:00 », « Lundi 28 sept. »).
  final String heure;

  /// Vrai quand la seance est annulee.
  final bool annulee;

  /// Le style de l'heure (le theme par defaut).
  final TextStyle? style;

  /// Nombre de lignes maximal.
  final int? maxLines;

  /// Debordement.
  final TextOverflow? overflow;

  /// Vrai (par defaut) pour que cette valeur annonce « Annulee : ... » au
  /// lecteur d'ecran. Faux pour la seconde valeur barree d'une meme carte,
  /// afin que la carte ne dise « Annulee » qu'une fois.
  final bool annoncer;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = style ?? DefaultTextStyle.of(context).style;
    if (!annulee) {
      return Text(heure, style: base, maxLines: maxLines, overflow: overflow);
    }
    final AppPalette palette = AppPalette.of(context);
    final TextStyle barre = palette.inkMuted
        .applyTo(base)
        .copyWith(
          decoration: TextDecoration.lineThrough,
          decorationColor: palette.inkMuted.applyTo(base).color,
        );
    final Text texte = Text(
      heure,
      style: barre,
      maxLines: maxLines,
      overflow: overflow,
    );
    if (!annoncer) return texte;
    return Semantics(
      label: t.etat.annuleeValeur(valeur: heure),
      excludeSemantics: true,
      child: texte,
    );
  }
}

/// La ligne qui dit pourquoi une seance est annulee et, quand l'information
/// existe, la suite (« Aucun remplacant trouve · seance non facturee »).
///
/// Rien n'est invente : [raison] et [suite] viennent de la donnee, une
/// [suite] nulle ne laisse aucune trace.
class LigneRaisonSeance extends StatelessWidget {
  /// Cree la ligne.
  const LigneRaisonSeance({required this.raison, super.key, this.suite});

  /// Pourquoi la seance n'a pas lieu.
  final String raison;

  /// Ce qui suit, ou `null` quand on ne le sait pas.
  final String? suite;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String? apres = suite;
    final String texte = apres == null || apres.isEmpty
        ? raison
        : t.etat.raisonEtSuite(raison: raison, suite: apres);
    return Text(
      texte,
      style: palette.inkMuted.applyTo(
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
      ),
    );
  }
}
