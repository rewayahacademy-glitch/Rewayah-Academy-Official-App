import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// L'en-tete d'une page du tuteur : disque retour eventuel, titre, sous-titre,
/// actions a droite (maquettes V1, V2, V4, V8 ; manifeste visuel Tuteur V1
/// sections 3.3 et 3.4).
///
/// - Titre en DM Sans 700 : `headlineSmall` (28) sur telephone,
///   `headlineMedium` (32) au-dela ; annonce comme en-tete.
/// - Disque retour de 48, `surfaceOverlay`, fleche d'accent : seulement pour
///   une page de niveau 2 ou une tache focalisee ([onRetour]).
/// - Actions a droite, dans l'ordre donne : la bascule de theme
///   (`BasculeTheme`, tablette et bureau seulement) puis la cloche
///   ([ClocheNotifications]).
///
/// Ce n'est pas la coquille : `PageShell` reste le seul gabarit de page ;
/// l'en-tete se pose dans son corps ou dans son emplacement d'en-tete.
///
/// **En-tete compact** (SUPERPOS-1, decide par delegation le 05/10) : a texte
/// agrandi (au-dela de 130 %) ou sur une vue basse, voir [EnteteCompact].
class EntetePage extends StatelessWidget {
  /// Cree un en-tete.
  const EntetePage({
    required this.titre,
    super.key,
    this.sousTitre,
    this.ligneSousTitre,
    this.onRetour,
    this.actions = const <Widget>[],
    this.focusTitre,
  });

  /// Rend le titre focalisable par programme (hors parcours clavier) : une
  /// page y ramene le focus quand son contenu disparait.
  final FocusNode? focusTitre;

  /// Le titre de la page. Il ne souhaite pas la bienvenue.
  final String titre;

  /// Une ligne sous le titre, en encre attenuee.
  final String? sousTitre;

  /// Une ligne composee sous le titre, a la place de [sousTitre] : un fil
  /// d'Ariane dont un maillon mene ailleurs (« Foyer › Mariam »,
  /// maquette 06). `null` : [sousTitre].
  final Widget? ligneSousTitre;

  /// Le retour. Sans lui, pas de disque retour.
  final VoidCallback? onRetour;

  /// Les actions a droite du titre.
  final List<Widget> actions;

  /// La part minimale de la largeur de l'en-tete laissee au titre quand
  /// retour et actions sont sur sa ligne ; en dessous, ils passent
  /// au-dessus et le titre prend toute la largeur.
  static const double partMinTitre = 0.5;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final TextStyle styleTitre =
        (mobile ? textes.headlineSmall : textes.headlineMedium) ??
        const TextStyle();
    final bool compact = EnteteCompact.actif(context);
    final TextScaler echelleTitre = compact
        ? EnteteCompact.echelleTitre(context, styleTitre)
        : MediaQuery.textScalerOf(context);
    final TextStyle styleSousTitre =
        (compact ? textes.bodyMedium : textes.bodyLarge) ?? const TextStyle();

    final TextStyle titreComplet = palette.inkStrong.applyTo(styleTitre);
    final Widget titreW = titreFocalisable(
      focusTitre,
      // COUPE-MOTS-1 : entre les mots, jamais dans un mot
      // (« Centre de com / mande », « Cahier de trans / mission »).
      Semantics(
        header: true,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: echelleTitre),
          child: TexteSansCoupure(
            titre,
            key: EnteteCompact.titreKey,
            style: titreComplet,
            // SUPERPOS-1 : « Classe Al- / Badr » a 320 en texte double ;
            // en mode compact seulement (texte agrandi, vue basse).
            nomsComposesEntiers: compact,
          ),
        ),
      ),
    );
    final List<Widget> sousTitreW = <Widget>[
      if (ligneSousTitre case final Widget ligne) ...<Widget>[
        Ecart.vXs,
        ligne,
      ] else if (sousTitre != null) ...<Widget>[
        Ecart.vXs,
        TexteSansCoupure(
          sousTitre!,
          key: EnteteCompact.sousTitreKey,
          style: palette.inkMuted.applyTo(styleSousTitre),
        ),
      ],
    ];
    final Widget? retour = onRetour == null
        ? null
        : DisqueRetour(onPress: onRetour!);

    if (!compact) {
      // CPT-RC (revue CPT-R M3, ligne ui/comptable-v1), repris par
      // JONCTION-LIGNES-1 : quand retour et actions laissent au titre moins
      // de [partMinTitre] de la largeur (six actions de la coquille admin a
      // 800, Interface guidee), ils passent sur une rangee au-dessus et le
      // titre et son sous-titre prennent toute la largeur ; sinon, titre et
      // sous-titre etaient composes un mot par ligne.
      return LayoutBuilder(
        builder: (BuildContext contexte, BoxConstraints c) {
          final double aCote =
              c.maxWidth -
              (retour == null ? 0 : AppTouchTarget.standard + AppSpacing.md) -
              actions.length * (AppTouchTarget.standard + AppSpacing.xs);
          final bool auDessus =
              (retour != null || actions.isNotEmpty) &&
              c.maxWidth.isFinite &&
              aCote < c.maxWidth * partMinTitre;
          final Widget bloc = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[titreW, ...sousTitreW],
          );
          if (auDessus) {
            return Column(
              key: EnteteCompact.rangeeAuDessusKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    ?retour,
                    const Spacer(),
                    for (final Widget action in actions) ...<Widget>[
                      Ecart.hXs,
                      action,
                    ],
                  ],
                ),
                Ecart.vSm,
                bloc,
              ],
            );
          }
          return Row(
            children: <Widget>[
              if (retour != null) ...<Widget>[retour, Ecart.hMd],
              Expanded(child: bloc),
              for (final Widget action in actions) ...<Widget>[
                Ecart.hXs,
                action,
              ],
            ],
          );
        },
      );
    }

    // En-tete compact : le sous-titre prend toute la largeur, sous la rangee
    // du titre. Quand le mot le plus long du titre ne tient pas a cote du
    // disque retour et des actions, ils passent sur une rangee au-dessus et
    // le titre prend lui aussi toute la largeur : sinon, le mot se serait
    // reduit sous la taille d'un titre de section agrandi (HIER-1).
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints c) {
        final double aCote =
            c.maxWidth -
            (retour == null ? 0 : AppTouchTarget.standard + AppSpacing.md) -
            actions.length * (AppTouchTarget.standard + AppSpacing.xs);
        final double motLong = largeurMotLePlusLong(
          contexte,
          titre,
          titreComplet,
          echelleTitre,
        );
        final bool auDessus =
            (retour != null || actions.isNotEmpty) &&
            motLong + AppSpacing.xs > aCote;
        if (!auDessus) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (retour != null) ...<Widget>[retour, Ecart.hMd],
                  Expanded(child: titreW),
                  for (final Widget action in actions) ...<Widget>[
                    Ecart.hXs,
                    action,
                  ],
                ],
              ),
              ...sousTitreW,
            ],
          );
        }
        return Column(
          key: EnteteCompact.rangeeAuDessusKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                ?retour,
                const Spacer(),
                for (final Widget action in actions) ...<Widget>[
                  Ecart.hXs,
                  action,
                ],
              ],
            ),
            Ecart.vSm,
            titreW,
            ...sousTitreW,
          ],
        );
      },
    );
  }
}

/// L'en-tete compact, selon l'echelle HIER-1 (SUPERPOS-1, decide par
/// delegation le 05/10).
///
/// A texte agrandi (au-dela de [echelleSeuil]) ou sur une vue basse (sous
/// [hauteurSeuil], telephone en paysage), un titre d'ecran agrandi en
/// proportion prenait le tiers ou la moitie d'un telephone (320 en texte
/// double : « Classe Al-Badr · Jeudi 24 septembre » sur quatre lignes de
/// 56, « Dossiers a valider » et son sous-titre sur la moitie de l'ecran).
/// En mode compact :
///
/// - le titre grandit avec le texte, mais seulement jusqu'a rester **un
///   palier** ([palier]) au-dessus d'un titre de section (`titleLarge`) lui
///   aussi agrandi : la hierarchie HIER-1 tient a la taille rendue (titre
///   d'ecran > titre de section > corps), sans le surplus qui ne sert pas la
///   lecture. Jamais sous la taille du theme ;
/// - le sous-titre descend d'un rang du corps (`bodyMedium`), toujours
///   agrandi a l'echelle de l'appareil, et prend toute la largeur sous la
///   rangee du titre ;
/// - quand le mot le plus long du titre ne tient pas a cote du disque retour
///   et des actions, ceux-ci passent sur une rangee au-dessus et le titre
///   prend toute la largeur (sinon le mot se reduirait sous un titre de
///   section agrandi) ;
/// - un nom compose du titre (« Al-Badr ») ne passe pas a la ligne apres son
///   trait d'union (`TexteSansCoupure.nomsComposesEntiers`).
///
/// Le clavier ne compte pas : la structure ne bascule pas a son ouverture
/// (meme regle que `PageShell`).
abstract final class EnteteCompact {
  /// L'echelle de texte au-dela de laquelle l'en-tete est compact.
  static const double echelleSeuil = 1.3;

  /// La hauteur de vue sous laquelle l'en-tete est compact.
  static const double hauteurSeuil = 600;

  /// L'ecart minimal entre deux niveaux de l'echelle HIER-1 (titre de carte
  /// 18, titre de carte secondaire 16).
  static const double palier = 2;

  /// Le titre de l'en-tete (tests, captures).
  static const Key titreKey = ValueKey<String>('entete-page-titre');

  /// La forme a rangee au-dessus du titre (tests, captures).
  static const Key rangeeAuDessusKey = ValueKey<String>(
    'entete-page-rangee-au-dessus',
  );

  /// Le sous-titre de l'en-tete (tests, captures).
  static const Key sousTitreKey = ValueKey<String>('entete-page-sous-titre');

  /// Vrai quand l'en-tete de [context] doit etre compact.
  static bool actif(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > echelleSeuil ||
      MediaQuery.sizeOf(context).height < hauteurSeuil;

  /// L'echelle du titre [style] en mode compact : celle qui le pose un
  /// [palier] au-dessus d'un titre de section agrandi, jamais plus grande
  /// que celle de l'appareil, jamais sous 1.
  static TextScaler echelleTitre(BuildContext context, TextStyle style) {
    final TextScaler appareil = MediaQuery.textScalerOf(context);
    final double taille = style.fontSize ?? 0;
    final double section =
        Theme.of(context).textTheme.titleLarge?.fontSize ?? 0;
    if (taille <= 0) return appareil;
    final double vise = appareil.scale(section) + palier;
    if (appareil.scale(taille) <= vise) return appareil;
    final double facteur = vise / taille;
    return TextScaler.linear(facteur < 1 ? 1 : facteur);
  }
}

/// Enveloppe [titre] dans un [Focus] hors parcours clavier quand [noeud] est
/// donne ; sinon le rend tel quel (aucune semantique ajoutee).
Widget titreFocalisable(FocusNode? noeud, Widget titre) => noeud == null
    ? titre
    : Focus(focusNode: noeud, skipTraversal: true, child: titre);

/// Le disque retour de 48 : surface des superpositions, filet de carte,
/// fleche d'accent miroitee en arabe. Lu « Retour ».
class DisqueRetour extends StatelessWidget {
  /// Cree le disque.
  const DisqueRetour({
    required this.onPress,
    super.key,
    this.libelleSemantique,
  });

  /// Le retour.
  final VoidCallback onPress;

  /// Ce qu'annonce le disque ; « Retour » par defaut (« Fermer la piece »
  /// dans la visionneuse plein ecran).
  final String? libelleSemantique;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Pressable(
      onPress: onPress,
      libelleSemantique: libelleSemantique ?? t.commun.entete.retour,
      arrondiFocus: AppRadius.arrondiFull,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: AppTouchTarget.standard,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surfaceOverlay.background,
              border: Border.fromBorderSide(
                palette.contourCarte.asBorderSide(),
              ),
            ),
            child: Center(
              child: IconTheme(
                data: palette.inkAccent.asIconTheme(size: AppSpacing.xxl),
                child: Icon(AppIcons.retour.repos),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La cloche de l'en-tete, et son point de non-lus.
///
/// **Le point n'existe que pour de vrais non-lus** : [nonLues] vient du
/// service de notifications ; tant qu'aucune source n'existe (DB-CPT-04), il
/// vaut `null` et la cloche n'a pas de point. Lue « Notifications » ou
/// « Notifications, n non lues ».
///
/// **Active sur sa propre page** ([actif]) : icone pleine a l'encre d'accent
/// et etat selectionne, le meme traitement qu'une destination active de la
/// barre. La personne voit ou elle est, la cloche ne se lit plus comme une
/// entree vers une page deja ouverte.
class ClocheNotifications extends StatelessWidget {
  /// Cree la cloche.
  const ClocheNotifications({
    required this.onPress,
    super.key,
    this.nonLues,
    this.libelleSemantique,
    this.actif = false,
  });

  /// L'ouverture des notifications (`/tuteur/notifications`).
  final VoidCallback? onPress;

  /// Le nombre de notifications non lues, tel que le service le rend.
  final int? nonLues;

  /// Ce que lit le lecteur d'ecran, quand la cloche dit autre chose que des
  /// notifications non lues : la cloche des alertes de la direction annonce
  /// ses alertes urgentes (ALERTE-1). Nul : le libelle des notifications.
  final String? libelleSemantique;

  /// La page des notifications est celle qui est ouverte.
  final bool actif;

  /// Diametre du point de non-lus.
  static const double diametrePoint = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final int nombre = nonLues ?? 0;
    final String libelle =
        libelleSemantique ??
        switch (nombre) {
          <= 0 => t.commun.entete.notifications,
          1 => t.commun.entete.notificationsUneNonLue,
          _ => t.commun.entete.notificationsNonLues(nombre: nombre),
        };

    final AppInkColor encre = actif
        ? palette.inkAccent
        : (mobile ? palette.inkStrong : palette.inkMuted);

    return Pressable(
      onPress: onPress,
      libelleSemantique: libelle,
      // Annoncee selectionnee sur sa page seulement ; ailleurs, aucun etat
      // de selection (un bouton seul n'est pas un onglet).
      selectionne: actif ? true : null,
      arrondiFocus: AppRadius.arrondiFull,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: AppTouchTarget.standard,
          child: Stack(
            children: <Widget>[
              Center(
                child: IconTheme(
                  data: encre.asIconTheme(size: AppSpacing.xxl),
                  child: Icon(
                    AppIcons.notifications.resoudre(selectionne: actif),
                  ),
                ),
              ),
              if (nombre > 0)
                PositionedDirectional(
                  top: AppSpacing.md,
                  end: AppSpacing.md,
                  child: SizedBox.square(
                    dimension: diametrePoint,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.surfacePrimary.background,
                        border: Border.fromBorderSide(
                          BorderSide(
                            color: palette.surfaceCanvas.background,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
