import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/marque_page.dart';
import '../../core/widgets/page_shell.dart';
import '../demo/racine_demonstrable.dart';

/// Largeur maximale du contenu sur bureau (deux colonnes).
const double _largeurBureau = 1040;

/// Largeur de la colonne unique sur telephone et tablette.
const double _largeurColonne = 460;

/// L'accueil public avant connexion (mandat Tuteur V1, arbre section 4).
///
/// Une promesse, trois points dans UNE carte groupee, et deux sorties vers la
/// connexion : « Commencer » (un compte se cree par le lien de connexion, puis
/// l'inscription) et « J'ai deja un compte ». Aucune donnee lue : pas d'etat
/// de chargement ni d'erreur a dire. Sur bureau, deux colonnes.
class BienvenuePage extends StatelessWidget {
  /// Cree la page.
  const BienvenuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool bureau =
        AppGabarit.de(context) != Gabarit.mobile &&
        MediaQuery.sizeOf(context).width >= 900;

    return PageShell(
      defilante: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints contraintes) =>
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: contraintes.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const MarquePage(),
                    if (bureau) Ecart.vSection else Ecart.vXxl,
                    if (bureau)
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _largeurBureau,
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(child: _Promesse(bureau: true)),
                            SizedBox(width: AppSpacing.xxl),
                            Expanded(child: _Points()),
                          ],
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _largeurColonne,
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            _Promesse(bureau: false),
                            SizedBox(height: AppSpacing.xxl),
                            _Points(),
                            SizedBox(height: AppSpacing.xxl),
                            _Sorties(),
                          ],
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

class _Promesse extends StatelessWidget {
  const _Promesse({required this.bureau});

  /// Sur bureau, les sorties suivent la promesse dans la colonne de gauche.
  final bool bureau;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          t.bienvenue.accroche,
          key: const ValueKey<String>('bienvenue-accroche'),
          style: bureau ? textes.displaySmall : textes.headlineMedium,
        ),
        Ecart.vMd,
        Text(
          t.bienvenue.phrase,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        if (bureau) ...<Widget>[Ecart.vXxl, const _Sorties()],
      ],
    );
  }
}

class _Points extends StatelessWidget {
  const _Points();

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return AppCard(
      key: const ValueKey<String>('bienvenue-points'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(t.bienvenue.pointsTitre, style: textes.titleMedium),
          Ecart.vLg,
          _Point(
            icone: AppIcons.cours.repos,
            titre: t.bienvenue.pointClasseTitre,
            texte: t.bienvenue.pointClasse,
          ),
          const Divider(height: AppSpacing.xxl),
          _Point(
            icone: AppIcons.profil.repos,
            titre: t.bienvenue.pointEnseignantTitre,
            texte: t.bienvenue.pointEnseignant,
          ),
          const Divider(height: AppSpacing.xxl),
          _Point(
            icone: AppIcons.foyer.repos,
            titre: t.bienvenue.pointFoyerTitre,
            texte: t.bienvenue.pointFoyer,
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icone, required this.titre, required this.texte});

  final IconData icone;
  final String titre;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: Icon(icone, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(titre, style: textes.titleSmall),
                Ecart.vXs,
                Text(
                  texte,
                  style: palette.inkMuted.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sorties extends StatelessWidget {
  const _Sorties();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ActionPrincipale(
        key: const ValueKey<String>('bienvenue-commencer'),
        libelle: t.bienvenue.commencer,
        onPress: () => GoRouter.of(context).go(Routes.connexion),
      ),
      Ecart.vMd,
      Align(
        child: ActionPrincipale(
          key: const ValueKey<String>('bienvenue-deja-compte'),
          libelle: t.bienvenue.dejaCompte,
          onPress: () => GoRouter.of(context).go(Routes.connexion),
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
        ),
      ),
      // Hors production seulement : sans lanceur, l'entree ne rend rien.
      const EntreeDemonstration(),
    ],
  );
}
