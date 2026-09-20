import 'package:flutter/widgets.dart';

import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../widgets/status_pill.dart';
import 'intention_pedagogique.dart';

/// La derivation **intention -> couleur**, et jamais l'inverse.
///
/// Personne ne choisit « du rouge » : on marque « A renforcer », et le rouge en
/// decoule. C'est l'invariant 2 du contrat (section 10) et la raison pour
/// laquelle aucun selecteur de couleur n'existe dans le Teaching Dock.
///
/// **Aucune couleur n'est posee ici.** La derivation passe par [TonEtat], le
/// vocabulaire ferme que `StatusPill` emploie deja : cinq familles semantiques,
/// chacune rattachee a une paire du theme. Reutiliser ce vocabulaire plutot que
/// d'en inventer un second garantit qu'un marqueur « A renforcer » et une
/// pilule « En retard » ne finiront pas avec deux rouges differents.
///
/// **Et la couleur ne voyage jamais seule.** Le rendu d'un marqueur passe par
/// `StatusPill`, qui refuse par construction une pastille sans libelle
/// (invariant J7 du depot).
abstract final class CouleurIntention {
  /// La famille semantique d'une intention.
  ///
  /// - « A apprendre » est l'accent : c'est ce qui s'ouvre, ce qui commence.
  /// - « A revoir » est neutre, parce que c'est le cas le plus frequent : une
  ///   revision normale n'est ni un succes ni une alerte, et la peindre en
  ///   couleur saturee rendrait la page illisible a force de signaux.
  /// - « A renforcer » est l'alerte : c'est une faiblesse constatee.
  /// - « A entretenir » est le succes : l'acquis qu'on maintient.
  /// - « Pour l'evaluation » est l'avertissement : a surveiller, pas en echec.
  static TonEtat ton(IntentionPedagogique intention) => switch (intention) {
    IntentionPedagogique.aApprendre => TonEtat.accent,
    IntentionPedagogique.aRevoir => TonEtat.neutre,
    IntentionPedagogique.aRenforcer => TonEtat.alerte,
    IntentionPedagogique.aEntretenir => TonEtat.succes,
    IntentionPedagogique.pourEvaluation => TonEtat.avertissement,
  };

  /// L'encre d'un trait porte par cette intention.
  ///
  /// Le neutre prend `inkMuted` et non `inkFaint` : un trait de stylet porte du
  /// sens, il doit tenir le seuil de contraste des elements signifiants.
  static EncreIntention encre(
    AppPalette palette,
    IntentionPedagogique intention,
  ) => EncreIntention._(switch (ton(intention)) {
    TonEtat.neutre => palette.inkMuted,
    TonEtat.accent => palette.inkAccent,
    TonEtat.succes => palette.inkSuccess,
    TonEtat.avertissement => palette.inkWarning,
    TonEtat.alerte => palette.inkAlert,
  });
}

/// Une encre d'intention, prete a peindre.
///
/// **Le seul endroit du lot D qui extrait une couleur brute d'une encre**, par
/// `asBorderSide().color` -- le meme detour que `AppPalette.calqueInteraction`,
/// qui en est le precedent dans le depot. Un `CustomPainter` a besoin d'une
/// [Color] : la faire sortir ici, une fois, evite qu'elle sorte partout.
@immutable
class EncreIntention {
  const EncreIntention._(this._encre);

  final AppInkColor _encre;

  /// L'encre, applicable a un style de texte ou a un theme d'icone.
  AppInkColor get encre => _encre;

  /// La couleur a peindre, eventuellement voilee.
  ///
  /// [opacite] sert au surligneur, qui se pose **sous** le texte : une encre
  /// pleine le rendrait illisible.
  Color couleur({double opacite = 1}) =>
      _encre.asBorderSide().color.withValues(alpha: opacite);

  @override
  bool operator ==(Object other) =>
      other is EncreIntention && other._encre == _encre;

  @override
  int get hashCode => _encre.hashCode;
}
