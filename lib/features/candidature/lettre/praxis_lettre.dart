// LETTRE-CANDIDATS (directeur, 20/11/2026) : Praxis dans la lettre aux
// candidats. « Praxis ne doit pas apparaitre plusieurs fois sur la meme
// viewport, il est en haut, il saute et rebondit avec le scroll pour suivre. »
//
// UN SEUL Praxis par page : il vit dans la tete fixe de la page
// (`PageShell.enteteSecondaire`, qui defile avec le corps quand la place
// manque) et change de phrase selon la partie lue. Il fait un petit saut
// quand la partie change et quand on recommence a defiler. Le dessin passe
// par `AvatarPraxisCandidat`, seul point du dessin cote candidat : changer
// de dessin se fait la-bas. Sous « Reduire les effets », aucun saut.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_color_pair.dart';
import '../../../core/theme/app_mouvement.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../praxis_candidat.dart';

/// Ce que Praxis dit, selon la partie lue.
enum MomentLettre {
  /// Le debut de la lettre.
  accueil,

  /// La paie.
  paie,

  /// Le retard et le remplacement.
  retard,

  /// L'attente d'une classe.
  attente,

  /// La piece d'identite.
  piece,

  /// La partie qui le presente.
  moi,

  /// La fin.
  fin;

  /// Sa phrase.
  String get phrase {
    final p = t.recrutement.lettre.praxis;
    return switch (this) {
      MomentLettre.accueil => p.accueil,
      MomentLettre.paie => p.paie,
      MomentLettre.retard => p.retard,
      MomentLettre.attente => p.attente,
      MomentLettre.piece => p.piece,
      MomentLettre.moi => p.moi,
      MomentLettre.fin => p.fin,
    };
  }

  /// Le moment d'une partie (1 a 14) : celui de la derniere partie qui en
  /// porte un, a partir d'elle en remontant.
  static MomentLettre pourPartie(int partie) {
    const Map<int, MomentLettre> reperes = <int, MomentLettre>{
      1: MomentLettre.accueil,
      4: MomentLettre.paie,
      6: MomentLettre.retard,
      7: MomentLettre.attente,
      8: MomentLettre.piece,
      11: MomentLettre.moi,
      14: MomentLettre.fin,
    };
    for (int p = partie; p >= 1; p--) {
      final MomentLettre? m = reperes[p];
      if (m != null) return m;
    }
    return MomentLettre.accueil;
  }
}

/// Praxis et sa bulle, en tete de la lettre.
class PraxisLettre extends StatefulWidget {
  /// Cree le guide. [moment] : la partie lue ; [secousses] : augmente a
  /// chaque reprise du defilement.
  const PraxisLettre({
    required this.moment,
    required this.secousses,
    super.key,
  });

  /// Le moment de la lettre.
  final ValueListenable<MomentLettre> moment;

  /// Un compteur qui augmente quand le lecteur recommence a defiler.
  final ValueListenable<int> secousses;

  /// La cle du guide.
  static const Key cle = ValueKey<String>('lettre-praxis');

  @override
  State<PraxisLettre> createState() => _EtatPraxisLettre();
}

class _EtatPraxisLettre extends State<PraxisLettre>
    with SingleTickerProviderStateMixin {
  late final AnimationController _saut = AnimationController(
    vsync: this,
    duration: AppMouvement.entreeArche,
  );

  @override
  void initState() {
    super.initState();
    widget.moment.addListener(_sauter);
    widget.secousses.addListener(_sauter);
  }

  @override
  void didUpdateWidget(PraxisLettre ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.moment != widget.moment) {
      ancien.moment.removeListener(_sauter);
      widget.moment.addListener(_sauter);
    }
    if (ancien.secousses != widget.secousses) {
      ancien.secousses.removeListener(_sauter);
      widget.secousses.addListener(_sauter);
    }
  }

  void _sauter() {
    if (!mounted || AppMouvement.mouvementReduit(context)) return;
    if (_saut.isAnimating) return;
    _saut.forward(from: 0);
  }

  @override
  void dispose() {
    widget.moment.removeListener(_sauter);
    widget.secousses.removeListener(_sauter);
    _saut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair bulle = palette.washAccent;
    return ValueListenableBuilder<MomentLettre>(
      valueListenable: widget.moment,
      builder: (BuildContext context, MomentLettre moment, Widget? _) {
        final String phrase = moment.phrase;
        return Padding(
          key: PraxisLettre.cle,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: <Widget>[
              AnimatedBuilder(
                animation: _saut,
                // Un saut : monte puis retombe, d'un palier au plus.
                builder: (BuildContext _, Widget? enfant) =>
                    Transform.translate(
                      offset: Offset(
                        0,
                        -math.sin(_saut.value * math.pi) * AppSpacing.sm,
                      ),
                      child: enfant,
                    ),
                child: AvatarPraxisCandidat(
                  sujet: phrase,
                  taille: AppSpacing.titreEcran,
                ),
              ),
              Ecart.hSm,
              Expanded(
                child: Material(
                  color: bulle.background,
                  shape: AppRadius.coinContinu(AppRadius.lg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      label: t.recrutement.lettre.praxisNom,
                      child: AnimatedSwitcher(
                        duration: AppMouvement.apparition,
                        // La phrase part du bord de debut, comme tout texte.
                        layoutBuilder:
                            (Widget? courant, List<Widget> precedents) => Stack(
                              alignment: AlignmentDirectional.centerStart,
                              children: <Widget>[...precedents, ?courant],
                            ),
                        child: Text(
                          phrase,
                          key: ValueKey<MomentLettre>(moment),
                          style: bulle.applyTo(
                            textes.bodyMedium ?? const TextStyle(),
                          ),
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
    );
  }
}
