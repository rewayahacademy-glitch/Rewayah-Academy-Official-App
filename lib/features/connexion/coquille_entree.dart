import 'package:flutter/material.dart';

import '../../core/domain/enums.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/entete_page.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/porte_lumiere.dart';

/// La largeur de lecture du formulaire sur ordinateur
/// (`docs/current/PARCOURS-ENTREE-2026-10-25.md`, §3 C).
const double largeurFormulaireEntree = AppPage.largeurEtatVide;

/// La largeur de la scene dans le volet de marque sur ordinateur (560 sur le
/// site, ramene a l'echelle d'espacement).
const double largeurSceneBureau = AppSpacing.respiration * 9;

/// L'habillage unique du parcours d'entree (connexion, lien envoye,
/// recuperation d'acces), celui de la page « Ne plus recevoir ces e-mails » du
/// site public (decisions du directeur du 25/10/2026, 16:20 et 16:40) :
///
/// - **telephone** (moins de [AppGabarit.seuilEtendu] en largeur utile) : une
///   page qui defile sur la surface de marque, logo horizontal blanc centre en
///   haut, la porte et sa lumiere, puis le formulaire pose sur la page, sans
///   carte ;
/// - **ordinateur** : deux volets, Material 3 fenetre « expanded » ; le volet
///   de marque au debut de ligne (a droite en arabe), logo centre en haut et
///   la porte centree ; le formulaire sur le parchemin (`surfaceQuran`), a
///   [largeurFormulaireEntree] au plus, centre verticalement.
///
/// **Theme unique** (decision du directeur du 25/10/2026) : la page est la
/// meme en clair et en sombre, comme la page modele qui force son rendu ; le
/// theme clair est force ici, comme la salle le fait pour sa page.
///
/// Les textes et les gestes restent ceux des ecrans : [formulaire] recoit
/// `bureau` pour poser ses boutons a la largeur de leur contenu.
class CoquilleEntree extends StatelessWidget {
  /// Cree l'habillage.
  const CoquilleEntree({
    required this.formulaire,
    this.pied = const <Widget>[],
    this.onRetour,
    super.key,
  });

  /// Le formulaire de l'ecran ; `bureau` vrai dans le volet d'ordinateur.
  final Widget Function(bool bureau) formulaire;

  /// Ce qui suit le formulaire : les liens de bas de page.
  final List<Widget> pied;

  /// Le retour, quand l'ecran en a un (la recuperation d'acces) : le disque
  /// retour au debut de ligne, en haut.
  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    final InterfaceMode mode = AppMetriques.of(context).mode;
    final double facteur = MediaQuery.textScalerOf(context).scale(1);
    final ThemeData clair = AppTheme.pour(mode, Brightness.light);
    final ThemeData marque = AppTheme.depuis(
      AppPalette.surMarque(),
      mode,
      Brightness.dark,
    );

    return Theme(
      data: clair,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) {
          // Material 3, fenetre « expanded » : deux volets des 840, mesures
          // en largeur utile (le texte agrandi ramene au telephone).
          final bool bureau =
              contraintes.maxWidth / facteur >= AppGabarit.seuilEtendu;
          final AppPalette palette = AppPalette.of(context);
          if (!bureau) {
            return PageShell(
              fond: palette.surfaceMarque,
              // La page mene son propre defilement : sur une fenetre haute,
              // le contenu se centre ; sur une fenetre basse, il defile, et
              // l'image ne disparait jamais.
              defilante: false,
              child: SurMarque(
                theme: marque,
                child: _Defilant(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _Tete(onRetour: onRetour),
                      Ecart.vXxl,
                      const Center(child: PorteLumiere.surMarque()),
                      Ecart.vXxl,
                      formulaire(false),
                      ...pied,
                      Ecart.vXxl,
                    ],
                  ),
                ),
              ),
            );
          }
          return PageShell(
            fond: palette.surfaceQuran,
            bordABord: true,
            defilante: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Le volet de marque au debut de ligne : a droite en arabe.
                Expanded(
                  child: ColoredBox(
                    color: palette.surfaceMarque.background,
                    child: SurMarque(
                      theme: marque,
                      child: const Padding(
                        padding: EdgeInsets.all(AppPage.gouttiereDesktop),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            LogoEntree(),
                            Expanded(
                              child: Center(
                                child: PorteLumiere.surMarque(
                                  largeurMax: largeurSceneBureau,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _Defilant(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth:
                              largeurFormulaireEntree +
                              2 * AppPage.gouttiereDesktop,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppPage.gouttiereDesktop,
                            vertical: AppSpacing.section,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              if (onRetour != null) ...<Widget>[
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: DisqueRetour(onPress: onRetour!),
                                ),
                                Ecart.vXxl,
                              ],
                              formulaire(true),
                              ...pied,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Le contenu pose sur la surface de marque : le theme de
/// [AppPalette.surMarque] et son encre blanche par defaut.
class SurMarque extends StatelessWidget {
  /// Pose [child] sur la surface de marque.
  const SurMarque({required this.theme, required this.child, super.key});

  /// Le theme de [AppPalette.surMarque].
  final ThemeData theme;

  /// Le contenu.
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: theme,
    child: DefaultTextStyle(
      style: theme.textTheme.bodyMedium ?? const TextStyle(),
      child: child,
    ),
  );
}

/// Le haut de la page sur telephone : le logo centre, et, quand l'ecran en a
/// un, le disque retour au debut de ligne (le logo reste au centre).
class _Tete extends StatelessWidget {
  const _Tete({required this.onRetour});

  final VoidCallback? onRetour;

  @override
  Widget build(BuildContext context) {
    if (onRetour == null) {
      return const LogoEntree();
    }
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        const LogoEntree(),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: DisqueRetour(onPress: onRetour!),
        ),
      ],
    );
  }
}

/// Un contenu qui se centre verticalement quand la hauteur le permet et
/// defile des qu'elle ne le permet plus.
class _Defilant extends StatelessWidget {
  const _Defilant({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints contraintes) =>
        SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: contraintes.maxHeight),
            child: Center(child: child),
          ),
        ),
  );
}

/// Le logo horizontal blanc, centre en haut, lu comme le nom de la marque
/// (decision du directeur du 25/10/2026, 16:40). **Il apparait par un fondu
/// net ([AppMouvement.apparition]) et ne se deplace jamais** (16:50, 17:10).
class LogoEntree extends StatelessWidget {
  /// Cree le logo.
  const LogoEntree({super.key});

  /// La hauteur du dessin, hors zone de protection.
  static const double hauteur = AppSpacing.xxxl;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      header: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: AppMouvement.apparition,
        builder: (BuildContext context, double opacite, Widget? enfant) =>
            Opacity(opacity: opacite, child: enfant),
        child: BrandLogo(
          key: const ValueKey<String>('entree-logo'),
          variante: VarianteLogo.horizontal,
          hauteur: hauteur,
          fond: FondLogo.violet,
          libelle: t.commun.marque,
        ),
      ),
    ),
  );
}

/// Un bouton du formulaire : pleine largeur sur le telephone, a la largeur de
/// son contenu et au bord de fin sur ordinateur (contrat C, CTA au bord de
/// fin ; pas de bouton pleine largeur sur bureau).
class BoutonEntree extends StatelessWidget {
  /// Pose [child].
  const BoutonEntree({required this.bureau, required this.child, super.key});

  /// Vrai dans le volet d'ordinateur.
  final bool bureau;

  /// Le bouton, construit avec `pleineLargeur: !bureau`.
  final Widget child;

  @override
  Widget build(BuildContext context) => bureau
      ? Align(alignment: AlignmentDirectional.centerEnd, child: child)
      : child;
}

/// Un champ avec son etiquette **au dessus**, et non flottante dans le cadre.
///
/// L'etiquette flottante de Material se pose a l'interieur du champ tant qu'il
/// est vide, en gris, exactement la ou l'oeil attend un texte d'invite. Le
/// champ courriel de cet ecran se lisait donc comme desactive alors qu'il
/// attendait une frappe. L'etiquette monte, l'invite descend, et les deux
/// disent chacune une chose.
///
/// Le champ lui-meme est blanc a encre sombre, sur la marque comme sur le
/// parchemin : il prend le theme clair, fond de carte. L'etiquette et la
/// phrase d'erreur restent sur la page et prennent son encre (blanche sur la
/// marque, encre d'alerte sur le parchemin).
class ChampEntree extends StatelessWidget {
  /// Cree le champ.
  const ChampEntree({
    required this.cle,
    required this.etiquette,
    required this.indice,
    required this.controleur,
    required this.erreur,
    required this.onSoumettre,
    required this.clavier,
    required this.autofill,
    this.onChanged,
    this.masque = false,
    super.key,
  });

  /// La cle du `TextField`, lue par les tests.
  final String cle;

  /// L'etiquette, au-dessus du champ.
  final String etiquette;

  /// L'invite, dans le champ vide.
  final String? indice;

  /// Le controleur.
  final TextEditingController controleur;

  /// La phrase d'erreur, sous le champ.
  final String? erreur;

  /// A chaque frappe.
  final VoidCallback? onChanged;

  /// A la validation au clavier ; `null` : passer au champ suivant.
  final VoidCallback? onSoumettre;

  /// Le clavier.
  final TextInputType clavier;

  /// Les indices de remplissage automatique.
  final List<String> autofill;

  /// Vrai pour un mot de passe.
  final bool masque;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette page = AppPalette.of(context);
    final AppPalette claire = AppPalette.claire();
    final ThemeData champ = AppTheme.depuis(
      claire.copyWith(surfaceSunken: claire.surfaceRaised),
      AppMetriques.of(context).mode,
      Brightness.light,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(etiquette, style: textes.labelLarge),
        Ecart.vSm,
        Theme(
          data: champ,
          child: TextField(
            key: ValueKey<String>(cle),
            controller: controleur,
            onChanged: onChanged == null ? null : (String _) => onChanged!(),
            onSubmitted: onSoumettre == null
                ? null
                : (String _) => onSoumettre!(),
            keyboardType: clavier,
            autofillHints: autofill,
            obscureText: masque,
            textInputAction: onSoumettre == null
                ? TextInputAction.next
                : TextInputAction.go,
            decoration: InputDecoration(
              hintText: indice,
              errorText: erreur,
              errorMaxLines: 4,
              errorStyle: page.inkAlert.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Un lien avec fleche du parcours d'entree, au debut de ligne comme le texte
/// qu'il suit (blanc sur la marque, encre d'accent sur le parchemin : la
/// palette de la surface en decide).
class LienEntree extends StatelessWidget {
  /// Cree le lien ; [cle] est posee sur le lien lui-meme (tests).
  const LienEntree({
    required this.libelle,
    required this.onPress,
    this.cle,
    super.key,
  });

  /// Le libelle.
  final String libelle;

  /// L'action.
  final VoidCallback onPress;

  /// La cle du [LienFleche].
  final Key? cle;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: LienFleche(
      key: cle,
      alignerEnDebut: true,
      libelle: libelle,
      onPress: onPress,
    ),
  );
}
