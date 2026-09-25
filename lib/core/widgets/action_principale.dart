import 'package:flutter/material.dart';

import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Les cinq niveaux d'action (la decisive ajoutee le 26/09, K-36).
///
/// Source : `docs/archive/2026-09-pre-remise-a-plat/design/02-regles-ux.md` section 4. Le nombre par ecran est
/// une regle d'ecran, pas une regle de composant : elle se tient en revue, et
/// c'est `08-catalogue-ecrans.md` qui la porte.
enum NiveauAction {
  /// Fond plein neutre `surfaceInverse` (encre sombre en clair, claire en
  /// sombre). **Une seule par ecran**, zero si l'ecran est en lecture.
  principale,

  /// Fond plein `surfacePrimary`, le violet. **Reservee aux rares actions
  /// qu'on ne doit surtout pas rater** : payer, confirmer une annulation.
  /// Remplace la principale de l'ecran, ne s'y ajoute pas (decision du
  /// directeur, 26/09, consigne K-36 : interface presque monochrome).
  decisive,

  /// Contour `borderStrong` sur `surfaceRaised`. Deux au plus.
  secondaire,

  /// Texte `inkStrong` souligne, sans contour. Autant que necessaire, mais
  /// jamais alignees comme des boutons.
  tertiaire,

  /// Texte `inkAlert`, **jamais un fond rouge plein**. Jamais dans la zone
  /// principale.
  destructive,
}

/// L'action d'un ecran, dans l'un de ses quatre niveaux.
///
/// **Seul point d'entree des actions du produit.** `tool/verifier_jetons.dart`
/// echoue sur tout `ElevatedButton`, `TextButton`, `OutlinedButton` ou
/// `FilledButton` dans `lib/` : un bouton Material rapporterait la palette de
/// Material avec lui.
///
/// Regle d'ecran heritee des parcours : **un ecran, une action principale.** Si
/// deux [NiveauAction.principale] se disputent un ecran, l'ecran est a revoir,
/// pas le composant.
///
/// Le quatrieme niveau, le destructif, a ete ajoute au lot C de la refonte.
/// Avant lui, un refus se peignait en passant la paire `surfaceAlert` au
/// bouton, c'est-a-dire en aplat rouge plein, ce que
/// `01-systeme-visuel.md` section 3 interdit.
class ActionPrincipale extends StatelessWidget {
  /// Cree une action.
  const ActionPrincipale({
    required this.libelle,
    required this.onPress,
    super.key,
    this.niveau = NiveauAction.principale,
    this.enCours = false,
    this.pleineLargeur = true,
    this.prefixe,
    this.fleche = false,
    this.pilule = false,
  });

  /// Le libelle du bouton. **Un verbe et son objet** : « Poser un creneau »,
  /// pas « Valider » (`02-regles-ux.md` section 9).
  final String libelle;

  /// L'action. `null` rend le bouton inerte, et le dit visuellement.
  final VoidCallback? onPress;

  /// Le niveau hierarchique de l'action.
  final NiveauAction niveau;

  /// Remplace le libelle par un indicateur d'activite, et bloque la pression.
  final bool enCours;

  /// Faux pour que le bouton ne prenne que la largeur de son libelle.
  final bool pleineLargeur;

  /// Un element pose avant le libelle, dans le meme alignement.
  ///
  /// **Reserve a ce que le libelle ne peut pas dire** : aujourd'hui le seul
  /// usage est le logo Google du bouton de connexion, qu'une marque tierce
  /// impose de montrer tel quel. Ce n'est pas une porte d'entree pour
  /// l'iconographie du produit : une action du produit se nomme, elle ne
  /// s'illustre pas (`docs/archive/2026-09-pre-remise-a-plat/design/02-regles-ux.md` section 9).
  ///
  /// L'indicateur d'activite le remplace tant que [enCours] vaut vrai : les
  /// deux occuperaient la meme place, et c'est l'attente qui prime.
  final Widget? prefixe;

  /// Pose une fleche apres le libelle : « Voir la classe -> ». C'est l'anatomie
  /// du CTA dominant des maquettes Tuteur (decisions du coordinateur, section
  /// 3, point 3). Decorative : le libelle seul porte le sens, l'etiquette
  /// semantique ne change pas. Miroitee en arabe.
  final bool fleche;

  /// Forme pilule (`AppRadius.full`) au lieu du rayon `sm` des boutons.
  ///
  /// **Reservee au CTA des etapes d'admission**, seule exception retenue par
  /// le coordinateur (decisions, section 3, point 2) ; partout ailleurs, un
  /// bouton a le rayon `sm` (12).
  final bool pilule;

  BorderRadius get _arrondi =>
      pilule ? AppRadius.arrondiFull : AppRadius.arrondiSm;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final bool actif = onPress != null && !enCours;
    // Sur ordinateur, un bouton prend la largeur de son libelle (K-36).
    final bool bureau = AppGabarit.de(context) == Gabarit.desktop;

    final Widget bouton = Pressable.selon(
      onPress: actif ? onPress : null,
      libelleSemantique: libelle,
      respecterCibleTactile: false,
      arrondiFocus: _arrondi,
      constructeur: (BuildContext contexte, EtatPression etat) => _corps(
        contexte,
        palette,
        metriques,
        etat,
        actif: actif,
        pleine: pleineLargeur && !bureau,
      ),
    );
    return pleineLargeur && bureau
        ? Align(alignment: AlignmentDirectional.centerStart, child: bouton)
        : bouton;
  }

  Widget _corps(
    BuildContext context,
    AppPalette palette,
    AppMetriques metriques,
    EtatPression etat, {
    required bool actif,
    required bool pleine,
  }) {
    final _Peinture peinture = _peinturePour(
      palette,
      actif: actif,
      etat: etat,
      guidee: metriques.estEnfant,
    );

    return Container(
      width: pleine ? double.infinity : null,
      constraints: BoxConstraints(
        minHeight: metriques.estEnfant
            ? AppTouchTarget.enfant
            : AppPage.hauteurBouton,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: peinture.fond,
        borderRadius: _arrondi,
        border: peinture.filet == null
            ? null
            : Border.fromBorderSide(peinture.filet!),
      ),
      child: Semantics(
        liveRegion: enCours,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (enCours) ...<Widget>[
              SizedBox.square(
                dimension: AppSpacing.xl,
                child: CircularProgressIndicator(
                  value: 0.65,
                  strokeWidth: 2,
                  color: peinture.encre(const TextStyle()).color,
                ),
              ),
              Ecart.hSm,
            ] else if (prefixe != null) ...<Widget>[prefixe!, Ecart.hSm],
            Flexible(
              child: Text(
                libelle,
                textAlign: TextAlign.center,
                style: peinture.encre(
                  Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
                ),
              ),
            ),
            if (fleche && !enCours) ...<Widget>[
              Ecart.hSm,
              IconTheme(
                data: IconThemeData(
                  color: peinture.encre(const TextStyle()).color,
                  size: AppSpacing.xl,
                ),
                child: Icon(AppIcons.flecheAction.repos),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Le fond, l'encre et le filet du niveau, dans l'etat courant.
  ///
  /// **Un bouton inerte ne se signale pas par de la transparence** : baisser
  /// l'opacite ferait tomber tout le sous-arbre sous le seuil de contraste. Il
  /// change de paire, donc son texte reste lisible et suit son fond.
  ///
  /// **Un [NiveauAction.principale] desactive reste plus lourd qu'un
  /// secondaire au repos** (lot T2, cause n2 mesuree du rejet du 11 septembre
  /// 2026) : avant ce lot, le fond `surfaceSunken` se fondait presque dans
  /// `surfaceCanvas` (1,06:1 d'ecart) et le filet `borderResting` etait le plus
  /// faible de la rampe, si bien que le bouton le plus important de l'ecran
  /// disparaissait au premier champ vide et se lisait comme une panne. Il
  /// passe desormais sur `surfaceRaised` avec le filet `borderStrong`, plus
  /// epais que celui d'un secondaire (3 contre 2) : la forme reste visible et
  /// pese plus, seule l'encre `inkMuted` dit qu'il attend une condition.
  ///
  /// Le survol n'invente aucune couleur : il passe au registre doux de la meme
  /// famille pour les niveaux plats, et pose le filet fort sur le niveau plein.
  _Peinture _peinturePour(
    AppPalette palette, {
    required bool actif,
    required EtatPression etat,
    required bool guidee,
  }) {
    if (!actif) {
      return _Peinture(
        fond: palette.surfaceRaised.background,
        encre: palette.inkMuted.applyTo,
        filet: palette.borderStrong.asBorderSide(width: 3),
      );
    }

    switch (niveau) {
      case NiveauAction.principale:
      case NiveauAction.decisive:
        // Interface presque monochrome (directeur, 26/09, K-36) : la
        // principale est un aplat neutre `surfaceInverse` ; le violet
        // `surfacePrimary` ne sert qu'a la decisive, rare.
        //
        // **Sauf en Interface guidee** : c'est souvent la seule action de
        // l'ecran d'un enfant, elle garde l'aplat `surfacePrimary`, a 3:1 au
        // moins contre chaque surface (teste), comme avant le chantier (revue
        // phase 0, jetons D3).
        final AppColorPair paireCta =
            guidee || niveau == NiveauAction.decisive
            ? palette.surfacePrimary
            : palette.surfaceInverse;
        return _Peinture(
          fond: paireCta.background,
          encre: paireCta.applyTo,
          // Au survol, l'aplat plein ne change pas de teinte : il gagne le
          // filet fort. Une seconde nuance de violet serait une couleur de
          // plus, hors palette.
          filet: etat.survole || etat.presse
              ? palette.borderStrong.asBorderSide(width: 2)
              : null,
        );
      case NiveauAction.secondaire:
        {
          // Le survol passe au fond enfonce, neutre : la paire change en
          // entier, le texte suit donc toujours son fond.
          final AppColorPair paire = etat.survole
              ? palette.surfaceSunken
              : palette.surfaceRaised;
          return _Peinture(
            fond: paire.background,
            encre: paire.applyTo,
            filet: palette.borderStrong.asBorderSide(width: 2),
          );
        }
      case NiveauAction.tertiaire:
        return _Peinture(
          fond: etat.survole ? palette.surfaceSunken.background : null,
          encre: (TextStyle base) => palette.inkStrong
              .applyTo(base)
              .copyWith(decoration: TextDecoration.underline),
        );
      case NiveauAction.destructive:
        return _Peinture(
          fond: etat.survole ? palette.washAlert.background : null,
          encre: palette.inkAlert.applyTo,
        );
    }
  }
}

/// Ce qu'il faut peindre : un fond eventuel, une encre, un filet eventuel.
///
/// L'encre est une **fonction de style** et non une couleur : c'est la
/// signature commune a `AppColorPair.applyTo` et a `AppInkColor.applyTo`, et
/// c'est ce qui permet aux quatre niveaux de puiser dans les deux familles
/// sans qu'aucune couleur brute ne transite par ce type.
@immutable
class _Peinture {
  const _Peinture({required this.fond, required this.encre, this.filet});

  final Color? fond;
  final TextStyle Function(TextStyle base) encre;
  final BorderSide? filet;
}
