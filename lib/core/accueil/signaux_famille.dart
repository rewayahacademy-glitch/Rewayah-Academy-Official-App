// LUMIERE-ACCUEILS, point 1 (directeur, 09-10/11/2026 ; arbitrages du pilote
// du 11/11/2026) : les signaux de l'Accueil de la famille et de l'adulte
// autonome, **calcules uniquement depuis des etats que le serveur rend**.
// Aucune horloge d'appareil : l'instant est celui du serveur, ou il n'y a
// aucune lumiere.
//
// * acces bloque (rouge) : seances fermees pour paiement (`mon_acces`), ou
//   aucun appareil pret ; une lecture absente ou en echec ne ferme rien ;
// * a preparer (orange) : la prochaine seance commence dans moins d'une heure
//   et du travail est a preparer ;
// * nouveau (bleu) : le cahier de la derniere seance est partageable avec la
//   famille, pendant 24 h a partir de la date de la seance (aucune memoire
//   « lu » n'existe : decision du pilote, sans migration).
//
// Le vert (salle rejoignable) et le rouge « retard » viennent dans leurs
// propres PR ; le dore n'a aucune source (aucune progression de programme).
// Une seule lumiere tourne par ecran : l'arbitre (`ArbitreLumieres`) choisit,
// ces signaux ne font que dire ce qui existe.
library;

import '../capacites/port_partage_pedagogique.dart' show EtatCompteRendu;
import '../widgets/halo_lumiere.dart';
import 'signaux_accueils.dart';

/// Ce que signale une lumiere de l'Accueil de la famille.
enum MotifFamille {
  /// Les seances sont fermees (paiement) ou aucun appareil n'est pret.
  acces,

  /// Du travail est a preparer avant la prochaine seance.
  preparer,

  /// Le cahier de la derniere seance est a lire.
  cahier,
}

/// La fenetre de l'orange : la seance commence dans moins de cette duree.
const Duration fenetreAPreparer = Duration(hours: 1);

/// La duree du bleu apres la date de la seance.
const Duration dureeNouveauCahier = Duration(hours: 24);

/// Les signaux de l'Accueil de la famille pour l'eleve choisi, dans l'ordre
/// de priorite (rouge, orange, bleu).
List<SignalAccueil<MotifFamille>> signauxFamille({
  required bool accesBloque,
  required DateTime? maintenantServeurUtc,
  required DateTime? debutProchaineUtc,
  required bool travailAPreparer,
  required EtatCompteRendu? etatCahier,
  required DateTime? debutDerniereUtc,
}) {
  final DateTime? now = maintenantServeurUtc;
  final DateTime? prochain = debutProchaineUtc;
  final DateTime? dernier = debutDerniereUtc;
  final bool bientot =
      now != null &&
      prochain != null &&
      prochain.isAfter(now) &&
      prochain.difference(now) < fenetreAPreparer;
  final bool recent =
      now != null &&
      dernier != null &&
      !dernier.isAfter(now) &&
      now.difference(dernier) <= dureeNouveauCahier;
  return <SignalAccueil<MotifFamille>>[
    if (accesBloque)
      const SignalAccueil<MotifFamille>(
        nature: NatureHalo.urgent,
        motif: MotifFamille.acces,
        nombre: 1,
      ),
    if (bientot && travailAPreparer)
      const SignalAccueil<MotifFamille>(
        nature: NatureHalo.aPreparer,
        motif: MotifFamille.preparer,
        nombre: 1,
      ),
    if (recent && etatCahier == EtatCompteRendu.partage)
      const SignalAccueil<MotifFamille>(
        nature: NatureHalo.nouveau,
        motif: MotifFamille.cahier,
        nombre: 1,
      ),
  ];
}

/// La lumiere d'un [motif], ou `null` : aucun signal.
NatureHalo? lumierePourFamille(
  List<SignalAccueil<MotifFamille>> signaux,
  MotifFamille motif,
) {
  for (final SignalAccueil<MotifFamille> s in signaux) {
    if (s.motif == motif) return s.nature;
  }
  return null;
}
