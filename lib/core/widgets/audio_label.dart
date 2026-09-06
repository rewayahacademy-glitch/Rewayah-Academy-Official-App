import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../i18n/cle_audio.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
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
/// diverger (`docs/architecture/etape-2-core-flutter.md` section 5).
class AudioLabel extends StatefulWidget {
  /// Cree un libelle audio.
  const AudioLabel({
    required this.cle,
    super.key,
    this.afficherTexte = true,
  });

  /// La cle du libelle, commune au texte et au son.
  final CleAudio cle;

  /// Faux pour n'afficher que le haut-parleur, sans le texte.
  final bool afficherTexte;

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

    return Pressable(
      onPress: () => unawaited(_jouer()),
      libelleSemantique: texte,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconTheme(
            data: palette.textOnLightAccent.asIconTheme(
              size: metriques.estEnfant ? AppSpacing.xxxl : AppSpacing.xxl,
            ),
            child: Icon(
              AppIcons.libelleAudio.resoudre(selectionne: _enLecture),
            ),
          ),
          if (widget.afficherTexte) ...<Widget>[
            Ecart.hSm,
            Flexible(
              child: Text(
                texte,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
