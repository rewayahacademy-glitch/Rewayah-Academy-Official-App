// Les finances de l'eleve adulte autonome (FI-9b, guide Finance V4 §4
// « Eleve adulte » ; FI-BR-17 ; K-53.8) : Mon espace > Paiements.
//
// Aucun second ecran de finances : la page reprend la vue de la fiche du
// tuteur (`EtatsFinancesProfil`, `VueFinancesProfil`, FI-6a) et l'historique
// (`HistoriqueMouvements`, FI-6b), avec des textes a la deuxieme personne.
// Solde, periode financee, prochain debit, mensualite et son detail, lien
// vers les mouvements, et « Recharger », qui ouvre LE moteur de recharge du
// foyer (`RechargeFoyerPage`) avec son seul profil coche : jamais un second
// centre de paiement (guide §4).
//
// **Aucune donnee d'un autre membre** : tout vient de `PortMesFinances`,
// dont le perimetre est la session (le serveur ne rend que le profil de la
// personne connectee). Ni `PortPaiementsFoyer` (le foyer entier) ni la liste
// des profils du foyer ne sont lus ici ; aucun filtre « par personne ».
//
// En production le port rend `CapaciteIndisponible` : la page le dit, sans
// bouton. Les destinations sont passees par la coquille : la coquille adulte
// n'existe encore qu'en demonstration (choix provisoire Q2, deux coquilles) ;
// `/eleve/finances` (guide §4) arrivera avec elle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_mes_finances.dart';
import '../../core/finance/finances_profil.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/identite_profil.dart';
import '../../core/widgets/page_shell.dart';
import '../foyer/fiche/finances_page.dart';
import '../foyer/fiche/mouvements_page.dart';
import '../foyer/photo_eleve.dart';

/// Mes finances : Mon espace > Paiements de l'eleve adulte autonome.
class MesFinancesPage extends ConsumerWidget {
  /// Cree la page.
  const MesFinancesPage({
    required this.onRetour,
    required this.onRecharger,
    required this.onMouvements,
    super.key,
  });

  /// Le retour vers Mon espace.
  final VoidCallback onRetour;

  /// Ouvre LA recharge, ce seul profil coche (son identifiant rendu).
  final void Function(String profilId) onRecharger;

  /// Ouvre mes mouvements.
  final VoidCallback onMouvements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageShell(
      // La page d'arrivee porte le nom de la ligne tapee (EA-4c).
      titre: t.adulte.monEspace.paiements,
      onRetour: onRetour,
      child: EtatsFinancesProfil(
        lecture: ref.watch(mesFinancesProvider),
        onRelire: () => ref.invalidate(mesFinancesProvider),
        textes: (
          indisponibleTitre: t.adulte.finances.indisponibleTitre,
          indisponiblePhrase: t.adulte.finances.indisponiblePhrase,
          erreurTitre: t.adulte.finances.erreurTitre,
          videTitre: t.adulte.finances.videTitre,
          videPhrase: t.adulte.finances.videPhrase,
        ),
        construire: (FinancesProfil finance) => VueFinancesProfil(
          finance: finance,
          avatar: PhotoEleve(
            prenom: finance.prenom,
            cleAvatar: finance.cleAvatar,
            diametre: TailleIdentite.entete.diametre,
          ),
          libelleRecharger: t.adulte.paiements.recharger,
          onRecharger: () => onRecharger(finance.profilId),
          semantiqueMouvements: t.adulte.finances.voirMouvementsSemantique,
          onMouvements: onMouvements,
        ),
      ),
    );
  }
}

/// Mes mouvements : l'historique du seul profil de l'eleve adulte autonome.
class MesMouvementsPage extends ConsumerWidget {
  /// Cree la page.
  const MesMouvementsPage({required this.onRetour, super.key});

  /// Le retour vers Mes finances.
  final VoidCallback onRetour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageShell(
      titre: t.ficheEleve.mouvements.titre,
      onRetour: onRetour,
      child: HistoriqueMouvements(
        lecture: ref.watch(mesMouvementsProvider),
        onRelire: () => ref.invalidate(mesMouvementsProvider),
        textes: (
          contexte: t.adulte.finances.mouvementsContexte,
          indisponibleTitre: t.ficheEleve.mouvements.indisponibleTitre,
          indisponiblePhrase: t.adulte.finances.mouvementsIndisponiblePhrase,
          erreurTitre: t.adulte.finances.mouvementsErreurTitre,
          videTitre: t.ficheEleve.mouvements.videTitre,
          videPhrase: t.adulte.finances.mouvementsVidePhrase,
        ),
      ),
    );
  }
}
