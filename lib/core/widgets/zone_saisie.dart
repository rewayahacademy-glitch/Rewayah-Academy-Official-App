import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'bouton_icone.dart';

/// L'envoi integre a une [ZoneSaisie] : un message, une reponse.
@immutable
class EnvoiZoneSaisie {
  /// Cree l'envoi.
  const EnvoiZoneSaisie({
    required this.libelle,
    required this.onEnvoyer,
    this.cle,
  });

  /// Ce que lit le lecteur d'ecran, et l'infobulle : « Envoyer ».
  final String libelle;

  /// L'envoi du texte saisi.
  final VoidCallback onEnvoyer;

  /// La cle du bouton (tests).
  final Key? cle;
}

/// La zone de saisie de texte multiligne du produit (SUPERPOS-1, decision
/// du 05/10/2026 prise par delegation) : **seul point d'entree** d'un champ
/// de plusieurs lignes.
///
/// - **Style du systeme de design** : rayon, fond, filet et marges viennent
///   du theme (`inputDecorationTheme` : `AppRadius.sm`, `surfaceSunken`,
///   filet `contour`, marge `AppSpacing.lg`), jamais d'un style local.
/// - **La hauteur grandit avec le texte**, de [minLignes] a [maxLignes], et
///   ne prend jamais plus des deux cinquiemes de la hauteur visible (clavier
///   ouvert, texte agrandi) : au-dela, le champ defile en lui-meme et le
///   contenu de la page reste lisible au-dessus.
/// - **Bouton d'envoi integre et centre** ([envoi]) : une icone nommee
///   (`BoutonIcone`, cible de 48, infobulle et lecteur d'ecran), posee DANS
///   le rectangle du champ, a son bord de fin, centree en hauteur quelle que
///   soit la hauteur du champ ; la fleche se miroite en arabe.
/// - **Jamais de bouton grise** : tant que le champ est vide, le bouton
///   n'est pas rendu (sa place reste reservee, le texte ne saute pas) et
///   [explication] dit pourquoi, sous le champ.
/// - **L'etiquette est posee au-dessus du champ**, jamais en etiquette
///   flottante a cheval sur le filet : a 320 en texte double, celle-ci se
///   coupait en ellipse, ou passait sur deux lignes par-dessus le contenu
///   au-dessus du champ (une bulle du fil). Un champ d'envoi ne la montre
///   pas : son invite la dit, le lecteur d'ecran la lit ([libelleVisible]).
/// - Les aides et erreurs passent a la ligne autant qu'il le faut : jamais
///   coupees a 320 px en texte double.
class ZoneSaisie extends StatelessWidget {
  /// Cree la zone.
  const ZoneSaisie({
    required this.controleur,
    super.key,
    this.cleChamp,
    this.noeud,
    this.libelle,
    this.libelleVisible,
    this.aide,
    this.explication,
    this.erreur,
    this.minLignes = 1,
    this.maxLignes = 6,
    this.envoi,
    this.lectureSeule = false,
    this.autofocus = false,
    this.majuscules = TextCapitalization.sentences,
    this.onChanged,
    this.actionClavier = TextInputAction.newline,
    this.onSubmitted,
    this.sens,
  }) : assert(minLignes >= 1 && maxLignes >= minLignes);

  /// Le texte saisi.
  final TextEditingController controleur;

  /// La cle du `TextField` lui-meme (tests, focus).
  final Key? cleChamp;

  /// Le noeud de focus du champ.
  final FocusNode? noeud;

  /// Le nom du champ : lu par le lecteur d'ecran, et montre au-dessus du
  /// champ selon [libelleVisible].
  final String? libelle;

  /// Vrai : [libelle] est ecrit au-dessus du champ. Par defaut, vrai pour un
  /// champ de formulaire, faux pour un champ d'envoi. Faux aussi quand
  /// l'ecran ecrit deja le nom du champ au-dessus (le cahier de seance).
  final bool? libelleVisible;

  /// L'invite du champ vide.
  final String? aide;

  /// La phrase sous le champ : une aide, ou pourquoi l'envoi attend.
  final String? explication;

  /// L'erreur sous le champ (remplace l'explication).
  final String? erreur;

  /// Le nombre de lignes du champ vide.
  final int minLignes;

  /// Le nombre de lignes au-dela duquel le champ defile en lui-meme.
  final int maxLignes;

  /// L'envoi integre, ou `null` : un champ de formulaire.
  final EnvoiZoneSaisie? envoi;

  /// Vrai : le texte se lit sans se modifier.
  final bool lectureSeule;

  /// Vrai : le champ prend le focus a l'ouverture.
  final bool autofocus;

  /// Les majuscules automatiques.
  final TextCapitalization majuscules;

  /// Chaque changement du texte.
  final ValueChanged<String>? onChanged;

  /// La touche d'action du clavier : par defaut, a la ligne. `done` pour un
  /// champ court (une position de reprise) dont le texte passe seulement a
  /// la ligne a l'ecran, sans retour saisi : il se lit en entier a 320 en
  /// texte double au lieu de defiler de cote.
  final TextInputAction actionClavier;

  /// La validation au clavier (avec [actionClavier] autre que `newline`).
  final ValueChanged<String>? onSubmitted;

  /// Le sens d'ecriture du champ, ou `null` : celui de l'ecran. Un texte
  /// libre (les mots d'un enseignant) prend le sens de sa premiere lettre
  /// (CARTES-PERSO-1b, `sensDeLaSaisie`).
  final TextDirection? sens;

  /// La place reservee du bouton d'envoi tant que le champ est vide (tests).
  static const Key placeEnvoiKey = ValueKey<String>('zone-saisie-place-envoi');

  /// La part de la hauteur visible que le champ ne depasse jamais.
  static const double partMaxVue = 0.4;

  /// Les lignes d'une aide ou d'une erreur de champ : assez pour qu'aucune
  /// ne passe a l'ellipse a 320 en texte double (mesure SUPERPOS-1 : 3 ne
  /// suffisaient pas a l'aide du courriel de l'invitation, ni a celle de
  /// l'age d'un profil eleve). Aussi pour les champs d'une ligne.
  static const int lignesAideMax = 8;

  /// Les lignes [min, max] que le champ peut prendre dans cette vue.
  ///
  /// La hauteur visible est celle de la vue, moins le clavier (lu sur la
  /// vue : la coquille retire le clavier du `MediaQuery` de son corps).
  static (int, int) lignesPour(
    BuildContext context, {
    required int minLignes,
    required int maxLignes,
  }) {
    final MediaQueryData media = MediaQuery.of(context);
    final double clavier = View.of(context).viewInsets.bottom;
    final double densite = View.of(context).devicePixelRatio;
    final double visible =
        media.size.height -
        math.max(media.viewInsets.bottom, clavier / densite) -
        media.padding.vertical;
    final TextStyle corps =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final double ligne =
        media.textScaler.scale(corps.fontSize ?? AppSpacing.lg) *
        (corps.height ?? 1.5);
    final int tiennent = ((visible * partMaxVue - 2 * AppSpacing.lg) / ligne)
        .floor();
    final int max = math.max(1, math.min(maxLignes, tiennent));
    return (math.min(minLignes, max), max);
  }

  @override
  Widget build(BuildContext context) {
    final (int min, int max) = lignesPour(
      context,
      minLignes: minLignes,
      maxLignes: maxLignes,
    );
    final EnvoiZoneSaisie? envoi = this.envoi;
    final String? libelle = this.libelle;
    final Widget champ = TextField(
      key: cleChamp,
      controller: controleur,
      focusNode: noeud,
      autofocus: autofocus,
      readOnly: lectureSeule,
      textDirection: sens,
      minLines: min,
      maxLines: max,
      keyboardType: actionClavier == TextInputAction.newline
          ? TextInputType.multiline
          : TextInputType.text,
      textInputAction: actionClavier,
      onSubmitted: onSubmitted,
      textCapitalization: majuscules,
      onChanged: onChanged,
      decoration: InputDecoration(
        // L'aide du champ vide passe a la ligne entre ses mots, jamais dans
        // un mot (« administratio / n… » a 320 en texte double, SUPERPOS-1) :
        // le style d'aide du theme, rendu par `TexteSansCoupure`.
        hint: aide == null
            ? null
            : TexteSansCoupure(
                aide!,
                style: Theme.of(context).inputDecorationTheme.hintStyle,
              ),
        helperText: explication,
        helperMaxLines: lignesAideMax,
        errorText: erreur,
        errorMaxLines: lignesAideMax,
        suffixIcon: envoi == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                child: _BoutonEnvoi(controleur: controleur, envoi: envoi),
              ),
      ),
    );
    if (libelle == null) return champ;
    final Widget nomme = Semantics(label: libelle, child: champ);
    if (!(libelleVisible ?? envoi == null)) return nomme;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Le nom est deja lu sur le champ : l'ecrit ne le redit pas.
        // COUPE-MOTS-4 : un mot lie a sa ponctuation par une espace
        // insecable (« changement ? ») qui ne tient pas sur la ligne reduit
        // son echelle au lieu de laisser le signe seul a la ligne.
        ExcludeSemantics(
          child: TexteSansCoupure(
            libelle,
            style: palette.inkStrong.applyTo(
              Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        nomme,
      ],
    );
  }
}

/// Le bouton d'envoi : rendu seulement quand il y a un texte a envoyer.
class _BoutonEnvoi extends StatelessWidget {
  const _BoutonEnvoi({required this.controleur, required this.envoi});

  final TextEditingController controleur;
  final EnvoiZoneSaisie envoi;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controleur,
        builder: (BuildContext context, TextEditingValue valeur, Widget? _) {
          if (valeur.text.trim().isEmpty) {
            // Jamais grise : absent, sa place gardee ; l'explication sous le
            // champ dit pourquoi.
            return const SizedBox.square(
              key: ZoneSaisie.placeEnvoiKey,
              dimension: AppTouchTarget.standard,
            );
          }
          final bool arabe = Directionality.of(context) == TextDirection.rtl;
          return Transform.flip(
            flipX: arabe,
            child: BoutonIcone(
              key: envoi.cle,
              icone: AppIcons.envoyerMessage,
              libelle: envoi.libelle,
              onPress: envoi.onEnvoyer,
            ),
          );
        },
      );
}
