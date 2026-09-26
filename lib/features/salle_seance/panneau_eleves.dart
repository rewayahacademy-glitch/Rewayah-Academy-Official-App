// Le panneau Eleves (CLV-07), enseignant seulement.
//
// Repris de /tc/classe sans en dupliquer la logique : memes intitules que
// `FicheSeance` (Niveau, Objectif actuel, Derniere seance, A reprendre,
// Presence recente, Travail actuel), memes quatre actions (Rappeler, Choisir
// pour reciter, Noter, Signaler un besoin), statuts de la liste de la vue
// (`VueSeance.eleves`, source unique du compteur, I-6). Connaissance privee
// minimale : ni telephone, ni e-mail, ni tuteur, ni « present » / « absent ».

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/pressable.dart';
import 'actions_seance.dart';
import 'vue_seance.dart';

/// Le libelle d'un statut pendant la seance.
String libelleStatutEleve(StatutEleveSeance statut) => switch (statut) {
  StatutEleveSeance.connecte => t.salle.seance.statut.connecte,
  StatutEleveSeance.pasEncoreConnecte =>
    t.salle.seance.statut.pasEncoreConnecte,
  StatutEleveSeance.connexionInterrompue =>
    t.salle.seance.statut.connexionInterrompue,
};

AppInkColor _encreStatut(AppPalette palette, StatutEleveSeance statut) =>
    switch (statut) {
      StatutEleveSeance.connecte => palette.inkSuccess,
      StatutEleveSeance.pasEncoreConnecte => palette.inkWarning,
      StatutEleveSeance.connexionInterrompue => palette.inkAlert,
    };

/// La couleur de la pastille. L'attente se lit jaune orange (images) : le
/// fond d'avertissement plein, et non l'encre de texte brun olive.
Color _couleurPastille(AppPalette palette, StatutEleveSeance statut) =>
    switch (statut) {
      StatutEleveSeance.pasEncoreConnecte => palette.surfaceWarning.background,
      _ => _encreStatut(palette, statut).asBorderSide().color,
    };

/// Le corps des intitules et valeurs de la fiche (image CLV-07 : ≈ 13 px).
/// Plus Jakarta Sans n'a pas d'axe `opsz` : la retaille est sure.
const double _corpsFiche = 13;

TextStyle _styleFiche(BuildContext context) =>
    (Theme.of(context).textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: _corpsFiche,
    );

/// La liste des inscrits ; une fiche depliee a la fois.
class PanneauEleves extends StatefulWidget {
  const PanneauEleves({
    required this.eleves,
    required this.actions,
    this.large = false,
    super.key,
  });

  final List<EleveSeance> eleves;
  final ActionsSeance actions;

  /// Colonne desktop : intitules au corps des valeurs (image desktop) ;
  /// ailleurs, intitules en petit (images web etroit et telephone).
  final bool large;

  @override
  State<PanneauEleves> createState() => _PanneauElevesState();
}

class _PanneauElevesState extends State<PanneauEleves> {
  /// Le prenom de la fiche depliee : au depart, le premier eleve connecte
  /// qui a une fiche (image : Mariam).
  late String? _deplie = _premierDeplie();

  String? _premierDeplie() {
    for (final EleveSeance e in widget.eleves) {
      if (e.statut == StatutEleveSeance.connecte && e.fiche != null) {
        return e.prenom;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const ValueKey<String>('panneau-eleves'),
      // Telephone : la feuille descend jusqu'au bord de l'ecran, la liste
      // defile jusque sous la barre du systeme.
      padding: EdgeInsets.only(
        bottom: AppSpacing.md + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: widget.eleves.length,
      separatorBuilder: (BuildContext _, int _) => Ecart.vSm,
      itemBuilder: (BuildContext _, int i) {
        final EleveSeance e = widget.eleves[i];
        final bool deplie = _deplie == e.prenom && e.fiche != null;
        return _CarteEleve(
          eleve: e,
          deplie: deplie,
          large: widget.large,
          actions: widget.actions,
          onBasculer: e.fiche == null
              ? null
              : () => setState(() => _deplie = deplie ? null : e.prenom),
        );
      },
    );
  }
}

class _CarteEleve extends StatelessWidget {
  const _CarteEleve({
    required this.eleve,
    required this.deplie,
    required this.large,
    required this.actions,
    required this.onBasculer,
  });

  final EleveSeance eleve;
  final bool deplie;
  final bool large;
  final ActionsSeance actions;
  final VoidCallback? onBasculer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final FicheEleveSeance? fiche = eleve.fiche;
    return DecoratedBox(
      key: ValueKey<String>('eleve-${eleve.prenom}'),
      decoration: palette.surfaceOverlay.decoration(
        borderRadius: AppRadius.arrondiMd,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _EnTeteEleve(eleve: eleve, deplie: deplie, onBasculer: onBasculer),
            if (deplie && fiche != null) ...<Widget>[
              Ecart.vSm,
              _GrilleFiche(fiche: fiche, large: large),
              _ActionsEleve(eleve: eleve, actions: actions),
            ],
          ],
        ),
      ),
    );
  }
}

class _EnTeteEleve extends StatelessWidget {
  const _EnTeteEleve({
    required this.eleve,
    required this.deplie,
    required this.onBasculer,
  });

  final EleveSeance eleve;
  final bool deplie;
  final VoidCallback? onBasculer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool connecte = eleve.statut == StatutEleveSeance.connecte;
    final AppInkColor encre = _encreStatut(palette, eleve.statut);
    final String statut = libelleStatutEleve(eleve.statut);
    final Widget ligne = Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: <Widget>[
          _Avatar(eleve: eleve),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  eleve.prenom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: palette.inkStrong.applyTo(
                    textes.titleSmall ?? const TextStyle(),
                  ),
                ),
                Ecart.vXs,
                Row(
                  children: <Widget>[
                    _Pastille(couleur: _couleurPastille(palette, eleve.statut)),
                    Ecart.hXs,
                    Flexible(
                      child: Text(
                        statut,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: (connecte ? encre : palette.inkMuted).applyTo(
                          _styleFiche(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onBasculer != null)
            IconTheme(
              data: palette.inkStrong.asIconTheme(size: AppSpacing.xl),
              child: Icon(
                deplie ? AppIcons.replier.repos : AppIcons.chevron.repos,
              ),
            ),
        ],
      ),
    );
    final VoidCallback? basculer = onBasculer;
    if (basculer == null) {
      return Semantics(label: '${eleve.prenom}, $statut', child: ligne);
    }
    return Semantics(
      expanded: deplie,
      child: Pressable(
        onPress: basculer,
        libelleSemantique:
            '${deplie ? t.salle.seance.replierFiche(prenom: eleve.prenom) : t.salle.seance.deplierFiche(prenom: eleve.prenom)}, $statut',
        arrondiFocus: AppRadius.arrondiSm,
        child: ligne,
      ),
    );
  }
}

/// L'avatar : l'initiale pour l'eleve connecte (image : « M »), sinon la
/// silhouette avec la pastille du statut en bas a droite.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.eleve});

  final EleveSeance eleve;

  static const double _diametre = AppSpacing.titreEcran - AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool connecte = eleve.statut == StatutEleveSeance.connecte;
    final AppColorPair fond = connecte
        ? palette.washAccent
        : palette.surfaceSunken;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _diametre,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: fond.decoration(
                  borderRadius: AppRadius.arrondiFull,
                ),
                child: Center(
                  child: connecte
                      ? Text(
                          eleve.prenom.substring(0, 1).toUpperCase(),
                          style: palette.inkAccent.applyTo(
                            Theme.of(context).textTheme.titleLarge ??
                                const TextStyle(),
                          ),
                        )
                      : IconTheme(
                          data: palette.inkMuted.asIconTheme(
                            size: AppSpacing.xxl,
                          ),
                          child: Icon(AppIcons.avatarSansPhoto.actif),
                        ),
                ),
              ),
            ),
            if (!connecte)
              PositionedDirectional(
                end: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: palette.surfaceOverlay.background,
                      width: AppSpacing.xs / 2,
                    ),
                  ),
                  child: _Pastille(
                    couleur: _couleurPastille(palette, eleve.statut),
                    grande: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.couleur, this.grande = false});

  final Color couleur;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final double d = grande ? AppSpacing.md : AppSpacing.sm;
    return SizedBox.square(
      dimension: d,
      child: DecoratedBox(
        decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
      ),
    );
  }
}

/// Les six champs, en grille de deux colonnes (images).
class _GrilleFiche extends StatelessWidget {
  const _GrilleFiche({required this.fiche, required this.large});

  final FicheEleveSeance fiche;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double ecart = large ? AppSpacing.md : AppSpacing.sm;
    // Cellules serrees sur les cotes : les valeurs tiennent sur une ligne,
    // comme sur les images (« 3 seances cette semaine »).
    const EdgeInsets marge = EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.md,
    );
    Widget champ(String intitule, String valeur, {bool objectif = false}) =>
        _Champ(
          intitule: intitule,
          valeur: valeur,
          large: large,
          objectif: objectif,
        );
    final Widget gauche = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ecart,
      children: <Widget>[
        champ(t.tc.classe.fiche.niveau, fiche.niveau),
        champ(t.tc.classe.fiche.objectif, fiche.objectifActuel, objectif: true),
        champ(t.tc.classe.fiche.derniereSeance, fiche.derniereSeance),
      ],
    );
    final Widget droite = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ecart,
      children: <Widget>[
        champ(t.tc.classe.fiche.aReprendre, fiche.aReprendre),
        champ(t.tc.classe.fiche.presenceRecente, fiche.presenceRecente),
        champ(t.tc.classe.fiche.travailActuel, fiche.travailActuel),
      ],
    );
    return DecoratedBox(
      key: const ValueKey<String>('fiche-eleve'),
      decoration: palette.surfaceRaised.decoration(
        borderRadius: AppRadius.arrondiSm,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Padding(padding: marge, child: gauche),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: palette.borderHairline.asBorderSide().color,
            ),
            Expanded(
              child: Padding(padding: marge, child: droite),
            ),
          ],
        ),
      ),
    );
  }
}

class _Champ extends StatelessWidget {
  const _Champ({
    required this.intitule,
    required this.valeur,
    required this.large,
    this.objectif = false,
  });

  final String intitule;
  final String valeur;
  final bool large;

  /// L'objectif actuel : le chapitre en gras sur sa ligne, la precision
  /// entre parentheses dessous (images : « Chapitre 1 » puis « (les bonnes
  /// manieres) »).
  final bool objectif;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = _styleFiche(context);
    final TextStyle styleIntitule = large
        ? corps
        : Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final int coupure = objectif ? valeur.indexOf(' (') : -1;
    final Widget texteValeur = coupure > 0
        ? Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: valeur.substring(0, coupure),
                  style: AppTypography.graisse(corps, FontWeight.w700),
                ),
                TextSpan(text: '\n${valeur.substring(coupure + 1)}'),
              ],
            ),
            style: palette.inkStrong.applyTo(corps),
          )
        : Text(valeur, style: palette.inkStrong.applyTo(corps));
    // Un fait = une annonce : intitule et valeur lus ensemble.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(intitule, style: palette.inkMuted.applyTo(styleIntitule)),
          Ecart.vXs,
          texteValeur,
        ],
      ),
    );
  }
}

/// Les quatre actions : tuiles icone pleine violette + libelle (images).
/// Une action sans rappel n'est pas rendue.
class _ActionsEleve extends StatelessWidget {
  const _ActionsEleve({required this.eleve, required this.actions});

  final EleveSeance eleve;
  final ActionsSeance actions;

  @override
  Widget build(BuildContext context) {
    final List<(AppIcon, String, ValueChanged<EleveSeance>?)>
    liste = <(AppIcon, String, ValueChanged<EleveSeance>?)>[
      (AppIcons.rappeler, t.salle.seance.rappeler, actions.onRappeler),
      (
        AppIcons.reciter,
        t.tc.classe.action.reciter,
        actions.onChoisirPourReciter,
      ),
      (AppIcons.noter, t.tc.classe.action.noter, actions.onNoter),
      // « Signaler / un besoin » : l'espace insecable garde « un
      // besoin » ensemble, comme sur les images.
      (AppIcons.signaler, t.salle.seance.signalerBesoin, actions.onSignaler),
    ];
    final List<Widget> tuiles = <Widget>[
      for (final (AppIcon icone, String libelle, ValueChanged<EleveSeance>? r)
          in liste)
        if (r != null)
          Expanded(
            child: _TuileAction(
              icone: icone,
              libelle: libelle,
              onPress: () => r(eleve),
            ),
          ),
    ];
    if (tuiles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.xs,
          children: tuiles,
        ),
      ),
    );
  }
}

class _TuileAction extends StatelessWidget {
  const _TuileAction({
    required this.icone,
    required this.libelle,
    required this.onPress,
  });

  final AppIcon icone;
  final String libelle;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Pressable(
      onPress: onPress,
      libelleSemantique: libelle,
      arrondiFocus: AppRadius.arrondiMd,
      child: DecoratedBox(
        decoration: palette.surfaceRaised.decoration(
          borderRadius: AppRadius.arrondiMd,
          side: palette.borderHairline.asBorderSide(),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.respiration + AppSpacing.lg,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconTheme(
                  data: palette.inkAccent.asIconTheme(
                    size: AppSpacing.xxl + AppSpacing.xs,
                  ),
                  child: Icon(icone.actif),
                ),
                Ecart.vXs,
                Text(
                  libelle,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: palette.inkStrong.applyTo(
                    Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
