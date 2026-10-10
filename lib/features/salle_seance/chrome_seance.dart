// L'en-tete de la salle de seance (CLV-04, 05, 06 ; I-1, I-8, I-9).

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bascule_theme.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/status_pill.dart';
import 'actions_seance.dart';
import 'capsule_seance.dart';
import 'cible_debordante.dart';
import 'dock_seance.dart';
import 'mention_seance.dart';
import 'vue_seance.dart';

/// Retour ‹, titre, ligne d'etat, pastille « En ligne », mention.
///
/// Desktop : la mention suit « En ligne » sur la ligne d'etat ; coin droit
/// = bascule de theme, cloche, reglages, compte (eleve, enseignant) ou
/// sortie + avatar sans menu (guidee). Telephone et web etroit : « En ligne »
/// a droite du titre, la mention sur une ligne seule dessous, rien d'autre a
/// droite. Aucune barre d'application empilee au-dessus (I-8).
class ChromeSeance extends StatelessWidget {
  const ChromeSeance({
    required this.vue,
    required this.actions,
    this.compacte = false,
    this.focusCapsule,
    super.key,
  });

  final VueSeance vue;
  final ActionsSeance actions;

  /// TB-3 : le noeud de l'avatar de la capsule (retour du focus quand le
  /// contexte se reduit).
  final FocusNode? focusCapsule;

  /// MA-CMD-1 : en Mode Accessibilite (telephone et web etroit), l'en-tete
  /// tient sur une ligne ; la ligne d'etat et la mention restent lues par le
  /// lecteur d'ecran.
  final bool compacte;

  @override
  Widget build(BuildContext context) {
    final Gabarit gabarit = AppGabarit.de(context);
    final AppPalette palette = AppPalette.of(context);
    // L'en-tete garde l'echelle standard, meme en guidee : sur CLV-05, « Ma
    // seance » a la taille de « Seance en direct » et la notice reste un petit
    // texte, plus petit que « En ligne ». Le theme n'est pas modifie : seul ce
    // sous-arbre lit l'echelle standard au lieu de l'echelle enfant.
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: AppTypography.standard.apply(
          bodyColor: palette.surfaceCanvas.onBackground,
          displayColor: palette.surfaceCanvas.onBackground,
        ),
      ),
      // La cible du lien « En savoir plus » de la mention deborde de sa
      // ligne sans prendre de hauteur : l'en-tete entier recoit ses touches.
      child: ZoneCiblesDebordantes(
        child: gabarit == Gabarit.desktop
            ? _Large(vue: vue, actions: actions, focusCapsule: focusCapsule)
            : _Etroit(
                vue: vue,
                actions: actions,
                gabarit: gabarit,
                compacte: compacte,
                focusCapsule: focusCapsule,
              ),
      ),
    );
  }
}

/// L'en-tete de la fin de seance enseignant (CLV-10).
///
/// Desktop : chevron, « Seance terminee », « Classe An-Nour » + pastille
/// « Terminee », coin droit complet (theme, cloche, reglages, compte). Web
/// etroit : le chevron seul (image CLV-07-08-10 web). Telephone : rien (image
/// mobile). Jamais de mention d'enregistrement : la seance est finie.
class EnteteFinSeance extends StatelessWidget {
  const EnteteFinSeance({required this.vue, required this.actions, super.key});

  final VueSeance vue;
  final ActionsSeance actions;

  @override
  Widget build(BuildContext context) {
    final Gabarit gabarit = AppGabarit.de(context);
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = AppPalette.of(context);
    if (gabarit == Gabarit.mobile) return const SizedBox.shrink();
    if (gabarit != Gabarit.desktop) {
      if (actions.onRetour == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppPage.gouttiereMobile,
          top: AppSpacing.xxl,
          end: AppPage.gouttiereMobile,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: _Retour(onPress: actions.onRetour),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: palette.borderHairline.asBorderSide()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: <Widget>[
            _Retour(onPress: actions.onRetour),
            Ecart.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _Titre(
                    texte: t.salle.fin.titre,
                    style: theme.textTheme.headlineMedium,
                  ),
                  Ecart.vXs,
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        vue.nomClasse,
                        style: palette.inkMuted.applyTo(
                          theme.textTheme.bodyLarge ?? const TextStyle(),
                        ),
                      ),
                      StatusPill(
                        libelle: t.salle.fin.enseignant.terminee,
                        ton: TonEtat.neutre,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Ecart.hLg,
            _CoinComplet(vue: vue, actions: actions),
          ],
        ),
      ),
    );
  }
}

/// Le retrait des lignes sous le titre, quand le chevron ‹ est la : la
/// largeur du chevron et l'ecart qui le suit.
const double _retraitEtroit = AppTouchTarget.standard + AppSpacing.xs;

class _Large extends StatelessWidget {
  const _Large({required this.vue, required this.actions, this.focusCapsule});

  final VueSeance vue;
  final ActionsSeance actions;
  final FocusNode? focusCapsule;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = AppPalette.of(context);
    final String? ligne = vue.ligneEtat;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: <Widget>[
          _Retour(onPress: actions.onRetour),
          Ecart.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Titre(texte: vue.titre, style: theme.textTheme.headlineMedium),
                Ecart.vXs,
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    if (ligne != null)
                      Text(
                        ligne,
                        style: palette.inkMuted.applyTo(
                          theme.textTheme.bodyLarge ?? const TextStyle(),
                        ),
                      ),
                    _Connexion(vue: vue),
                    MentionSeance(vue: vue),
                  ],
                ),
              ],
            ),
          ),
          // TB-3 (UI-01) : pendant le partage, la capsule a la place de la
          // vignette, avant le coin de l'en-tete.
          if (vue.voitCapsule) ...<Widget>[
            Ecart.hLg,
            CapsuleSeance(
              vue: vue,
              actions: actions,
              focusAvatar: focusCapsule,
            ),
          ],
          Ecart.hLg,
          if (vue.voitReglagesEnTete)
            _CoinComplet(vue: vue, actions: actions)
          else
            _CoinGuide(vue: vue, actions: actions),
        ],
      ),
    );
  }
}

class _Etroit extends StatelessWidget {
  const _Etroit({
    required this.vue,
    required this.actions,
    required this.gabarit,
    this.compacte = false,
    this.focusCapsule,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final Gabarit gabarit;
  final bool compacte;
  final FocusNode? focusCapsule;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette palette = AppPalette.of(context);
    final String? ligne = vue.ligneEtat;
    final bool retour = actions.onRetour != null;
    final bool mention = vue.texteMention != null;
    // TB-3 (UI-01) : la capsule suit la mention sur la meme ligne quand la
    // place le permet ; sinon elle passe dessous (Wrap), rien n'est coupe.
    final bool capsule = vue.voitCapsule;
    final Widget? laCapsule = capsule
        ? CapsuleSeance(vue: vue, actions: actions, focusAvatar: focusCapsule)
        : null;
    if (compacte) {
      // MA-CMD-1 : une seule ligne (chevron, titre, « En ligne ») ; la ligne
      // d'etat reste lue sans prendre de hauteur. La mention (observation
      // du parent, enregistrement) reste VISIBLE dessous quand elle existe :
      // transparence due a l'enfant (Children's Code), elle n'est pas
      // masquee.
      final String lu = ligne ?? '';
      return Padding(
        key: const ValueKey<String>('entete-seance-compacte'),
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppPage.gouttiereMobile,
          AppSpacing.xs,
          AppPage.gouttiereMobile,
          AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              hint: lu.isEmpty ? null : lu,
              child: Row(
                children: <Widget>[
                  if (retour) ...<Widget>[
                    _Retour(onPress: actions.onRetour),
                    Ecart.hXs,
                  ],
                  // MA-TITRE-1 : jamais de points de suspension. L'en-tete
                  // reste sur une ligne (MA-CMD-1) : le titre se reduit
                  // juste assez pour tenir en entier.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Semantics(
                        header: true,
                        child: Text(
                          vue.titre,
                          maxLines: 1,
                          softWrap: false,
                          style: palette.inkStrong.applyTo(
                            theme.textTheme.titleMedium ?? const TextStyle(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Ecart.hSm,
                  _Connexion(vue: vue, compacte: true),
                ],
              ),
            ),
            if (mention || capsule)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (mention) MentionSeance(vue: vue),
                  ?laCapsule,
                ],
              ),
          ],
        ),
      );
    }
    // Gouttiere de 16 des deux cotes ; le web etroit laisse plus d'air
    // au-dessus du titre (CLV-04-05-06_web_etroit).
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppPage.gouttiereMobile,
        top: gabarit == Gabarit.mobile ? AppSpacing.md : AppSpacing.xxl,
        end: AppPage.gouttiereMobile,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Chevron, titre et « En ligne » sur une meme ligne, centres.
          Row(
            children: <Widget>[
              if (retour) ...<Widget>[
                _Retour(onPress: actions.onRetour),
                Ecart.hXs,
              ],
              Expanded(
                child: _Titre(
                  texte: vue.titre,
                  style: theme.textTheme.titleLarge,
                  lignes: vue.connexion == ConnexionSeance.enLigne ? 2 : 1,
                ),
              ),
              Ecart.hSm,
              _Connexion(vue: vue, compacte: true),
            ],
          ),
          if (ligne != null || mention || capsule)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: retour ? _retraitEtroit : 0,
              ),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  if (ligne != null || mention)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (ligne != null)
                          Text(
                            ligne,
                            style: palette.inkMuted.applyTo(
                              theme.textTheme.bodyMedium ?? const TextStyle(),
                            ),
                          ),
                        if (ligne != null && mention) Ecart.vXs,
                        if (mention) MentionSeance(vue: vue),
                      ],
                    ),
                  ?laCapsule,
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Le rapport minimal entre la taille du titre de la salle et celle de son
/// sous-titre (`bodyMedium`, a l'echelle de l'appareil) : la hierarchie ne
/// s'inverse jamais. Le titre se reduit pour tenir dans ses lignes, mais pas
/// sous 1,15 fois le sous-titre ; s'il n'y tient toujours pas, il prend une
/// ligne de plus (l'en-tete grandit, la feuille du telephone defile).
const double rapportMinimalTitreSousTitre = 1.15;

/// L'echelle sous laquelle le titre de la salle (de style [style]) ne
/// descend pas pour garder ses lignes : jamais sous 1, jamais au-dessus de
/// l'echelle de l'appareil.
double plancherTitreSeance(BuildContext context, TextStyle? style) {
  final TextTheme textes = Theme.of(context).textTheme;
  // Secours : l'echelle typographique elle-meme (AppTypography), jamais une
  // copie de ses valeurs.
  final double titre =
      style?.fontSize ??
      textes.titleLarge?.fontSize ??
      AppTypography.standard.titleLarge!.fontSize!;
  final double sousTitre =
      textes.bodyMedium?.fontSize ??
      AppTypography.standard.bodyMedium!.fontSize!;
  final double facteur = MediaQuery.textScalerOf(context).scale(1);
  final double p = facteur * rapportMinimalTitreSousTitre * sousTitre / titre;
  if (p > facteur) return facteur;
  return p < 1 ? 1 : p;
}

class _Titre extends StatelessWidget {
  const _Titre({required this.texte, required this.style, this.lignes = 2});

  final String texte;
  final TextStyle? style;

  /// Doc 04 §28, §33 n. 13 : a 200 %, le titre passe sur deux lignes. Une
  /// seule quand un bloc de secours occupe deja l'ecran etroit.
  ///
  /// COUPE-MOTS-1 : c'est un nombre de lignes VISE, plus une troncature. Un
  /// titre de page n'a jamais de points de suspension (« Seance en d... ») :
  /// son echelle se reduit pour tenir dans ces lignes, au plus jusqu'a
  /// [plancherTitreSeance] (le titre reste plus grand que son sous-titre) ; au-dela, il
  /// prend une ligne de plus. Les mots ne sont jamais coupes.
  final int lignes;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: TexteSansCoupure(
      texte,
      maxLignes: lignes,
      plancher: plancherTitreSeance(context, style),
      style: AppPalette.of(context).inkStrong
          .applyTo(style ?? const TextStyle()),
    ),
  );
}

class _Connexion extends StatelessWidget {
  const _Connexion({required this.vue, this.compacte = false});

  final VueSeance vue;

  /// Telephone et web etroit : la petite pastille des images, marges serrees.
  final bool compacte;

  @override
  Widget build(BuildContext context) {
    final bool enLigne = vue.connexion.etablie;
    final TonEtat ton = enLigne ? TonEtat.succes : TonEtat.avertissement;
    if (!compacte) return StatusPill(libelle: vue.texteConnexion, ton: ton);

    final AppPalette palette = AppPalette.of(context);
    final AppColorPair fond = palette.paireDe(ton);
    return Semantics(
      label: vue.texteConnexion,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: fond.decoration(borderRadius: AppRadius.arrondiFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: StatusPill.diametrePastille,
                child: DecoratedBox(
                  decoration:
                      (enLigne
                              ? palette.pointsStatut.succes
                              : palette.pointsStatut.attention)
                          .pastille(),
                ),
              ),
              Ecart.hXs,
              Text(
                vue.texteConnexion,
                style: fond.applyTo(
                  Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Retour extends StatelessWidget {
  const _Retour({required this.onPress});

  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = onPress;
    if (action == null) return const SizedBox.shrink();
    // Le chevron ‹ des images : [AppIcons.chevron] retourne. Il suit la
    // direction de lecture (matchTextDirection), le retournement aussi.
    return _IconeEnTete(
      icone: AppIcons.chevron,
      libelle: t.salle.seance.retour,
      onPress: action,
      retourne: true,
    );
  }
}

class _IconeEnTete extends StatelessWidget {
  const _IconeEnTete({
    required this.icone,
    required this.libelle,
    required this.onPress,
    this.retourne = false,
  });

  final AppIcon icone;
  final String libelle;
  final VoidCallback onPress;
  final bool retourne;

  @override
  Widget build(BuildContext context) => Pressable(
    onPress: onPress,
    libelleSemantique: libelle,
    arrondiFocus: AppRadius.arrondiFull,
    respecterCibleTactile: false,
    // Taille normale pour tous les roles (D5) : en guidee, une cible de 72
    // decalait le titre et descendait le chevron sous la ligne du titre.
    child: SizedBox.square(
      dimension: AppTouchTarget.standard,
      child: Center(
        child: IconTheme(
          data: AppPalette.of(context).inkStrong
              .asIconTheme(size: AppSpacing.xxl),
          child: Transform.flip(flipX: retourne, child: Icon(icone.repos)),
        ),
      ),
    ),
  );
}

/// Eleve standard et enseignant, desktop : theme, cloche, reglages, compte.
class _CoinComplet extends StatelessWidget {
  const _CoinComplet({required this.vue, required this.actions});

  final VueSeance vue;
  final ActionsSeance actions;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? cloche = actions.onNotifications;
    final VoidCallback? reglages = actions.onReglages;
    final VoidCallback? menu = actions.onCompte;
    final CompteSeance compte = vue.compte;
    final Widget identite = _Identite(compte: compte, menu: menu != null);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const BasculeTheme(),
        Ecart.hMd,
        if (cloche != null) ...<Widget>[
          ClocheNotifications(
            onPress: cloche,
            nonLues: vue.notificationsNonLues,
          ),
          Ecart.hXs,
        ],
        if (reglages != null) ...<Widget>[
          _IconeEnTete(
            icone: AppIcons.reglages,
            libelle: t.salle.seance.reglages,
            onPress: reglages,
          ),
          Ecart.hMd,
        ],
        if (menu == null)
          identite
        else
          Pressable(
            onPress: menu,
            libelleSemantique: t.salle.seance.compteDe(
              deNom: deDevant(compte.nom),
            ),
            arrondiFocus: AppRadius.arrondiFull,
            child: identite,
          ),
      ],
    );
  }
}

/// Guidee, desktop : icone de sortie et avatar de l'enfant, sans menu.
class _CoinGuide extends StatelessWidget {
  const _CoinGuide({required this.vue, required this.actions});

  final VueSeance vue;
  final ActionsSeance actions;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? sortie = actions.onQuitter;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (sortie != null) ...<Widget>[
          _IconeEnTete(
            icone: AppIcons.sortie,
            libelle: t.salle.seance.sortir,
            // Meme confirmation que Quitter (dock).
            onPress: () => confirmerQuitterSeance(context, sortie),
          ),
          Ecart.hMd,
        ],
        _Identite(compte: vue.compte, menu: false),
      ],
    );
  }
}

class _Identite extends StatelessWidget {
  const _Identite({required this.compte, required this.menu});

  final CompteSeance compte;
  final bool menu;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ThemeData theme = Theme.of(context);
    // AVATAR-1 : le meme couple avatar + nom que partout (plus de cercle
    // d'initiales maison), le nom centre verticalement sur le cercle.
    return AvatarNom.enLigne(
      prenom: compte.nom,
      ajuste: true,
      styleNom: palette.inkStrong.applyTo(
        theme.textTheme.titleSmall ?? const TextStyle(),
      ),
      fin: menu
          ? IconTheme(
              data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
              child: Icon(AppIcons.menuDeroulant.repos),
            )
          : null,
    );
  }
}
