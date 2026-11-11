// NAV-REFONTE 2b (directeur, 10/11/2026 ; condition du garde-cap) : la seance
// que la carte « Prochaine seance » de la Journee montre, et son bouton
// (CTA-FIN-1), se calculent ici une seule fois. La Journee et le halo vert du
// cercle Compte de l'enseignant lisent ce meme provider.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../controle/service_controle.dart' show graceApresFin;
import '../video/pre_vol.dart' show seuilOuvertureSalle;
import 'cta_seance.dart';
import 'modeles_enseignant.dart';
import 'service_enseignant.dart';

/// La seance de la carte et son bouton.
typedef CarteSeanceEnseignant = ({SeanceEnseignant seance, CtaSeance cta});

/// La seance de la carte a l'instant [maintenant] ([seanceDeLaCarte]) et son
/// bouton ([ctaDeSeance]), `null` sans seance (ou tant que les seances ne se
/// lisent pas). La salle est rejoignable quand le bouton est
/// [EtatCtaSeance.rejoindre].
final ProviderFamily<CarteSeanceEnseignant?, DateTime>
carteSeanceEnseignantProvider = Provider.autoDispose
    .family<CarteSeanceEnseignant?, DateTime>((Ref ref, DateTime maintenant) {
      final List<SeanceEnseignant>? seances = ref
          .watch(seancesEnseignantProvider)
          .value;
      if (seances == null) return null;
      final SeanceEnseignant? seance = seanceDeLaCarte(
        seances,
        maintenant,
        fenetreAcces: seuilOuvertureSalle,
        graceApresFin: graceApresFin,
      );
      if (seance == null) return null;
      return (
        seance: seance,
        cta: ctaDeSeance(
          seance,
          maintenant,
          fenetreAcces: seuilOuvertureSalle,
          graceApresFin: graceApresFin,
        ),
      );
    });
