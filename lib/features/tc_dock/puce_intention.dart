import 'package:flutter/widgets.dart';

import '../../core/tc_outils/couleur_intention.dart';
import '../../core/tc_outils/intention_pedagogique.dart';
import '../../core/tc_outils/libelles_outils.dart';
import '../../core/widgets/status_pill.dart';

/// Le nom d'une intention, avec sa couleur.
///
/// **Jamais la couleur seule** (invariant J7). La bande coloree qu'un marqueur
/// pose sur le texte ne dit rien a qui ne distingue pas les teintes, et rien du
/// tout a un lecteur d'ecran : c'est cette puce qui la nomme, et l'hote la rend
/// a cote du passage marque ou dans sa liste de marqueurs.
///
/// Elle n'ajoute **aucun composant** au depot : `StatusPill` sait deja rendre
/// « une pastille de couleur et un mot », et il refuse par construction d'etre
/// employe sans mot. La puce ne fait que lui fournir la famille semantique
/// derivee de l'intention -- ce qui garantit qu'un marqueur « A renforcer » et
/// une pilule « En retard » portent exactement le meme rouge.
class PuceIntention extends StatelessWidget {
  /// Cree la puce d'une intention.
  const PuceIntention({required this.intention, super.key});

  /// L'intention nommee.
  final IntentionPedagogique intention;

  @override
  Widget build(BuildContext context) => StatusPill(
    libelle: libelleIntentionPedagogique(intention),
    ton: CouleurIntention.ton(intention),
  );
}
