import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../i18n/cle_audio.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_metriques.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Bouton haut-parleur qui rejoue un libelle audio.
///
/// Utilise partout ou le zero-lecture s'applique : un enfant de 6 ans doit
/// pouvoir comprendre un ecran sans savoir lire.
///
/// Le composant consomme une [CleAudio], jamais un chemin de fichier libre :
/// la meme cle designe le texte et le son, donc les deux ne peuvent pas
/// diverger (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-2-core-flutter.md` section 5).
class AudioLabel extends StatefulWidget {
  /// Cree un libelle audio.
  const AudioLabel({
    required this.cle,
    super.key,
    this.afficherTexte = true,
    this.surface,
    this.alignerEnFin = false,
    this.libelleSemantique,
  });

  /// La cle du libelle, commune au texte et au son.
  final CleAudio cle;

  /// Faux pour n'afficher que le haut-parleur, sans le texte.
  final bool afficherTexte;

  /// Vrai : le haut-parleur se range au bord de fin de sa cible tactile, au
  /// lieu du bord de debut. Pour un haut-parleur seul pose en fin de ligne
  /// (en-tete d'une carte) : son glyphe tombe alors sur le bord de fin du
  /// contenu, aligne sur un chevron ou une valeur pose dessous, comme
  /// `LienFleche.alignerEnFin`. La cible reste de 48 (72 en mode enfant), en
  /// RTL le bord de fin passe a gauche. Faux (defaut) : rendu inchange.
  final bool alignerEnFin;

  /// Le nom du bouton pour le lecteur d'ecran, quand il differe du texte.
  ///
  /// Pour un haut-parleur seul ([afficherTexte] faux) pose pres d'un lien qui
  /// porte deja le meme texte : « Ecouter : Le Coran » dit l'action et evite
  /// deux arrets de meme nom de suite (CORAN-CARTE-3). Nul (defaut) : le
  /// texte de la cle, rendu inchange.
  final String? libelleSemantique;

  /// La paire de la surface qui porte ce libelle.
  ///
  /// Par defaut, le composant ecrit pour le fond general : haut-parleur a
  /// l'encre d'accent, texte a la couleur du theme. Pose tel quel sur une
  /// surface d'accent, le violet ecrirait sur du violet et le texte du theme en
  /// noir. **Une paire dit sur quoi elle s'ecrit** : un bloc colore passe la
  /// sienne, comme il le fait deja a `BentoTile` et a `ActionPrincipale`.
  final AppColorPair? surface;

  @override
  State<AudioLabel> createState() => _AudioLabelState();
}

class _AudioLabelState extends State<AudioLabel> {
  final AudioPlayer _lecteur = AudioPlayer();
  bool _enLecture = false;

  @override
  void dispose() {
    unawaited(_lecteur.dispose());
    super.dispose();
  }

  Future<void> _jouer() async {
    if (_enLecture) {
      return;
    }
    setState(() => _enLecture = true);
    try {
      await _lecteur.setAsset(
        widget.cle.fichierPour(LocaleSettings.currentLocale.languageCode),
      );
      await _lecteur.seek(Duration.zero);
      await _lecteur.play();
    } on PlayerException {
      // Un libelle audio manquant ne casse pas l'ecran : le texte reste
      // affiche et le bouton redevient simplement disponible.
    } on PlayerInterruptedException {
      // Lecture interrompue par le systeme : rien a signaler.
    } finally {
      if (mounted) {
        setState(() => _enLecture = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final AppMetriques metriques = AppMetriques.of(context);
    final String texte = t.parCle(widget.cle);
    final double taille = metriques.estEnfant
        ? AppSpacing.xxxl
        : AppSpacing.xxl;
    final AppColorPair? paire = widget.surface;
    final TextStyle base =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle();

    return Pressable(
      onPress: () => unawaited(_jouer()),
      libelleSemantique: widget.libelleSemantique ?? texte,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: widget.alignerEnFin
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: <Widget>[
          IconTheme(
            data: paire == null
                ? palette.inkAccent.asIconTheme(size: taille)
                : IconThemeData(color: paire.onBackground, size: taille),
            child: Icon(
              AppIcons.libelleAudio.resoudre(selectionne: _enLecture),
            ),
          ),
          if (widget.afficherTexte) ...<Widget>[
            Ecart.hSm,
            Flexible(
              // R8-03 : « Ton cours a commencé » entier a 320 px et 200 %.
              child: TexteSansCoupure(
                texte,
                style: paire == null ? base : paire.applyTo(base),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
