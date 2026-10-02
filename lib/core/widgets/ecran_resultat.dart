import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'action_principale.dart';
import 'status_pill.dart';

/// L'ecran resultat : cercle heros, titre, phrase, encart, action dominante,
/// lien (maquette V8 M5, manifeste visuel Tuteur V1 section 3.4).
///
/// **Une seule grammaire pour tout ce qui occupe la page a la place du
/// contenu** : fin de visite d'observation, association confirmee, page
/// introuvable, acces refuse, session expiree, hors ligne, vide actionnable
/// (manifeste section 6.3). `EtatSysteme` en portee page le rend ; un ecran
/// metier l'emploie directement pour un vrai resultat.
///
/// Ce n'est pas une page : il se pose dans le corps d'une coquille
/// (`PageShell`), qui porte la gouttiere, le defilement et la zone sure.
///
/// Regles portees par l'API :
///
/// - l'action n'est rendue que si elle a un libelle ET un geste : un bouton
///   qui ne peut pas aboutir n'est pas rendu (`lib/CLAUDE.md`) ;
/// - le ton choisit la paire douce du cercle ([TonEtat]), jamais une couleur
///   pleine : la seule zone pleine de l'ecran reste l'action principale ;
/// - l'icone du cercle est decorative, exclue de l'arbre semantique ; le
///   titre est annonce comme un en-tete.
class EcranResultat extends StatelessWidget {
  /// Cree un ecran resultat.
  const EcranResultat({
    required this.icone,
    required this.titre,
    super.key,
    this.phrase,
    this.encart,
    this.ton = TonEtat.accent,
    this.libelleAction,
    this.onAction,
    this.actionEnCours = false,
    this.libelleSecondaire,
    this.onSecondaire,
    this.focusAction = false,
    this.cleAction,
  });

  /// La cle de l'action dominante, pour qu'un ecran metier garde la cle
  /// publique de son bouton (tests, captures). Facultative.
  final Key? cleAction;

  /// Vrai pour poser le focus clavier sur l'action dominante a l'ouverture
  /// (ecran qui remplace la page sans geste, ex. acces retire en salle).
  final bool focusAction;

  /// L'icone du cercle heros, rendue dans sa graisse pleine (medaillon).
  final AppIcon icone;

  /// Le titre humain, en une phrase courte. Jamais un code technique.
  final String titre;

  /// La phrase utile qui suit : ce qui s'est passe, ce qu'on peut faire.
  final String? phrase;

  /// Un encart doux sous la phrase (rappel, consequence), facultatif.
  final String? encart;

  /// La famille du cercle heros.
  final TonEtat ton;

  /// Le libelle de l'action dominante.
  final String? libelleAction;

  /// L'action dominante.
  final VoidCallback? onAction;

  /// Vrai pendant que l'action dominante aboutit : elle affiche l'attente et
  /// refuse une seconde pression.
  final bool actionEnCours;

  /// Le libelle du lien secondaire, discret.
  final String? libelleSecondaire;

  /// Le lien secondaire.
  final VoidCallback? onSecondaire;

  /// Diametre du cercle heros : 96 (maquette 88 a 96).
  static const double diametreHeros = AppSpacing.titreEcran * 2;

  /// Taille de l'icone dans le cercle.
  static const double tailleIcone = AppSpacing.section;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair cercle = palette.paireDe(ton);
    final bool avecAction = libelleAction != null && onAction != null;
    final bool avecSecondaire =
        libelleSecondaire != null && onSecondaire != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPage.largeurEtatVide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: ExcludeSemantics(
                child: SizedBox.square(
                  dimension: diametreHeros,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cercle.background,
                    ),
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(
                          color: cercle.onBackground,
                          size: tailleIcone,
                        ),
                        child: Icon(icone.actif),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Ecart.vXxl,
            Semantics(
              header: true,
              child: Text(
                titre,
                textAlign: TextAlign.center,
                style: palette.inkStrong.applyTo(
                  textes.titleLarge ?? const TextStyle(),
                ),
              ),
            ),
            if (phrase != null) ...<Widget>[
              Ecart.vSm,
              Text(
                phrase!,
                textAlign: TextAlign.center,
                style: palette.inkMuted.applyTo(
                  textes.bodyLarge ?? const TextStyle(),
                ),
              ),
            ],
            if (encart != null) ...<Widget>[
              Ecart.vXl,
              DecoratedBox(
                decoration: palette.washAccent.decoration(
                  borderRadius: AppRadius.arrondiSm,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  // Centre comme le titre et la phrase (EA-PL) : jamais un
                  // texte au bord de debut dans un bloc centre.
                  child: Text(
                    encart!,
                    textAlign: TextAlign.center,
                    style: palette.washAccent.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ),
              ),
            ],
            if (avecAction) ...<Widget>[
              Ecart.vXxl,
              ActionPrincipale(
                key: cleAction,
                libelle: libelleAction!,
                onPress: onAction,
                enCours: actionEnCours,
                fleche: true,
                autofocus: focusAction,
              ),
            ],
            if (avecSecondaire) ...<Widget>[
              Ecart.vSm,
              ActionPrincipale(
                libelle: libelleSecondaire!,
                onPress: onSecondaire,
                niveau: NiveauAction.tertiaire,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
