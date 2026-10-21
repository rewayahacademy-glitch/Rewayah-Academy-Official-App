// L'historique des seances passees de l'eleve adulte (DASH-EA-PROD) : la
// page dediee qu'ouvre « Voir tout » des dernieres seances de l'Accueil
// adulte (DASH_STRATEGIE.md D6, §3.7 rang 4).
//
// Aucun composant neuf : `PageShell` (titre, retour, bandeau hors ligne),
// `BlocAsynchrone` + `Skeleton` (chargement, echec avec « Reessayer »,
// indisponible sans), `EmptyState` (vide subi), `EtatSysteme` (hors ligne)
// et la liste des seances passees de l'Accueil (`ListeSeancesPassees`).
//
// Le provider [historiqueSeancesAdulteProvider] n'a aucune source serveur
// avant BR-1 : il rend `CapaciteIndisponible`, que la page dit comme tel
// (D10 : rien d'invente). La demonstration le surcharge (K-28). La source
// est le prolongement d'EA-BR-06 (les trois dernieres seances) a tout
// l'historique de la Classe de l'eleve : DASH-BR-01 (registre
// `DASH_STRATEGIE.md` §5 bis, a reporter dans `EA-BR.md`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'accueil_adulte_page.dart';

/// Les seances passees de la Classe de l'eleve adulte connecte, les plus
/// recentes d'abord, date deja rendue, absence de l'eleve seule. **Aucune
/// source serveur a ce jour** : `CapaciteIndisponible`. La demonstration le
/// surcharge.
final FutureProvider<List<SeancePasseeAdulte>> historiqueSeancesAdulteProvider =
    FutureProvider<List<SeancePasseeAdulte>>(
      (Ref _) => Future<List<SeancePasseeAdulte>>.error(
        const CapaciteIndisponible('historique_seances_eleve_adulte'),
      ),
      // Aucune relance automatique (Riverpod 3) : une capacite absente ne
      // revient pas en insistant ; « Reessayer » relit a la demande.
      retry: (int _, Object _) => null,
    );

/// L'historique des seances passees de l'eleve adulte.
class HistoriqueSeancesAdultePage extends ConsumerWidget {
  /// Cree la page.
  const HistoriqueSeancesAdultePage({required this.onRetour, super.key});

  /// Le retour vers l'Accueil.
  final VoidCallback onRetour;

  /// Lignes du squelette : la forme d'une page de seances, sans fausse date.
  static const int lignesSquelette = 5;

  /// La cle du bloc « rien a afficher » hors ligne (EA-HL-DOUBLE-1).
  static const Key sansDonneesKey = Key('adulte.historique.sansDonnees');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    // Hors ligne se dit une fois (EA-HL-DOUBLE-1), comme l'Accueil : le
    // bandeau de `PageShell` le dit ; des seances deja lues restent
    // affichees, et sans elles le bloc dit ce qui manque. Une capacite
    // absente reste dite indisponible.
    final AsyncValue<List<SeancePasseeAdulte>> lecture = lectureHorsLigne(
      ref.watch(historiqueSeancesAdulteProvider),
      horsLigne: horsLigne,
    );
    void relire() => ref.invalidate(historiqueSeancesAdulteProvider);
    final bool echecHorsLigne = sansDonneesHorsLigne(
      lecture,
      horsLigne: horsLigne,
    );
    return PageShell(
      titre: t.adulte.historique.titre,
      onRetour: onRetour,
      child: echecHorsLigne
          ? EtatSansDonnees(
              key: sansDonneesKey,
              quoi: t.adulte.historique.sansDonnees,
              onAction: relire,
            )
          : BlocAsynchrone<List<SeancePasseeAdulte>>(
              valeur: lecture,
              squelette: const ExcludeSemantics(
                child: Skeleton.liste(lignes: lignesSquelette),
              ),
              titreEchec: t.adulte.historique.echec,
              onReessayer: relire,
              vide: EmptyState(
                message: t.adulte.historique.vide,
                invitation: t.adulte.historique.videDetail,
                icone: AppIcons.cours,
                registre: RegistreVide.subi,
              ),
              construire: (List<SeancePasseeAdulte> seances) =>
                  ListeSeancesPassees(
                    key: const ValueKey<String>('historique-adulte-seances'),
                    seances: seances,
                  ),
            ),
    );
  }
}
