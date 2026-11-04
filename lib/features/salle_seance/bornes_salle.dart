// FN-023 (lot « Fin de seance », etape 1) : les bornes du chrono de `/salle`.
//
// LIVE-CHRONO-01 existait (`core/tc_horloge/chrono_seance.dart`, rendu par
// `chrome_seance.dart`), mais la salle ne lui passait jamais de bornes : aucun
// temps restant n'etait affiche. Ce fichier ne calcule aucun horaire. Il
// retrouve, dans les seances que le serveur sert DEJA a l'appelant, le debut
// et la fin prevue de la seance ouverte :
//
// - l'enseignant : `seancesEnseignantProvider` (`mes_seances_enseignant_v`,
//   plus le cours du moment de `horloge_classe`) ;
// - l'eleve : `seancesProvider` (`mes_seances_v`, idem).
//
// Seance introuvable dans ces lectures (lecture en echec, pas encore rendue,
// role sans salle de seance) : `null`, et la salle n'affiche pas de chrono.
// Rien n'est invente.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;

import '../../core/controle/service_controle.dart' show graceApresFin;
import '../../core/enseignant/modeles_enseignant.dart' show SeanceEnseignant;
import '../../core/enseignant/service_enseignant.dart'
    show seancesEnseignantProvider;
import '../../core/planning/service_planning.dart' show Seance, seancesProvider;
import '../../core/tc_horloge/chrono_seance.dart';
import '../../core/tc_horloge/fenetre_seance.dart';
import '../../core/video/pre_vol.dart' show seuilOuvertureSalle;

/// Une seance lue, reduite a ce que le chrono demande.
typedef LigneBornes = ({
  String id,
  String? groupeId,
  bool aCreer,
  DateTime debut,
  DateTime fin,
});

/// Les bornes de la seance [seanceId] parmi [lignes], ou `null`.
///
/// La seance se trouve par son identifiant. A defaut, le cours du moment de
/// la Classe [groupeId] encore sans seance au moment de la lecture (le
/// concierge l'a creee a l'appui sur « Rejoindre ») : ses bornes sont celles
/// de `horloge_classe`, donc du serveur.
BornesChrono? bornesDeLaSeance({
  required String seanceId,
  required String? groupeId,
  required Iterable<LigneBornes> lignes,
}) {
  LigneBornes? trouvee;
  for (final LigneBornes l in lignes) {
    if (l.id == seanceId) {
      trouvee = l;
      break;
    }
  }
  if (trouvee == null && groupeId != null) {
    for (final LigneBornes l in lignes) {
      if (l.aCreer && l.groupeId == groupeId) {
        trouvee = l;
        break;
      }
    }
  }
  if (trouvee == null || trouvee.fin.isBefore(trouvee.debut)) return null;
  return BornesChrono.depuisFenetre(
    FenetreSeance(
      debutUtc: trouvee.debut.toUtc(),
      finPrevueUtc: trouvee.fin.toUtc(),
      // Le seuil et la grace de core (ADR-005), jamais redeclares ici ; le
      // chrono n'en lit que le debut et la fin prevue.
      fenetreAcces: seuilOuvertureSalle,
      graceApresFin: graceApresFin,
    ),
  );
}

/// La cle d'une salle : la seance, sa Classe, et si l'appelant l'anime.
typedef CleBornesSalle = ({String seanceId, String? groupeId, bool enseignant});

/// Les bornes du chrono de la salle, depuis les seances deja servies.
final ProviderFamily<BornesChrono?, CleBornesSalle> bornesSalleProvider =
    Provider.family<BornesChrono?, CleBornesSalle>((
      Ref ref,
      CleBornesSalle cle,
    ) {
      final Iterable<LigneBornes> lignes;
      if (cle.enseignant) {
        lignes = <LigneBornes>[
          for (final SeanceEnseignant s
              in ref.watch(seancesEnseignantProvider).value ??
                  const <SeanceEnseignant>[])
            (
              id: s.id,
              groupeId: s.groupeId,
              aCreer: s.aCreer,
              debut: s.debut,
              fin: s.fin,
            ),
        ];
      } else {
        lignes = <LigneBornes>[
          for (final Seance s
              in ref.watch(seancesProvider).value ?? const <Seance>[])
            (
              id: s.id,
              groupeId: s.groupeId,
              aCreer: s.aCreer,
              debut: s.debut,
              fin: s.fin,
            ),
        ];
      }
      return bornesDeLaSeance(
        seanceId: cle.seanceId,
        groupeId: cle.groupeId,
        lignes: lignes,
      );
    });
