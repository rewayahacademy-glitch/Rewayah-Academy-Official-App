// « Recevoir mes paiements » (spec §17, §18, §19, §20, §27.1, §38) : la
// surface personnelle de tout beneficiaire avec compte (enseignant,
// contractuel avec compte, Comptable lui-meme), route partagee
// `/compte/paiements-recus` dans la coquille du role connecte
// (`_CoquilleSecondaire`). Posee « en preparation » par CPT-F avec son
// constructeur definitif ; **propriete de la voie CPT-BEN (CPT-BEN-2)
// ensuite**, qui ecrit dans `lib/features/paiements_recus/**` et pose une
// ligne dans le Profil de l'enseignant et une rubrique dans Compte, chacune
// selon une capacite rendue par le port, jamais selon le role
// (`20_comptable/02_DECOUPAGE.md`).
//
// Le beneficiaire seul ajoute, remplace, supprime, choisit sa methode
// preferee (R-FIN-13) ; notice « Informations de paiement a completer » et
// « Configurer mes paiements » (R-FIN-19). Aucune coordonnee reelle
// conservee : `portMesMoyensPaiementProvider` (CPT-BR-16).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';

/// Mes moyens de paiement, geres par moi seul.
class RecevoirPaiementsPage extends StatelessWidget {
  /// Cree la page.
  const RecevoirPaiementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final r = t.comptable.beneficiaires.recevoir;
    return PageShell(
      titre: r.titre,
      sousTitre: r.sousTitre,
      onRetour: () {
        final GoRouter routeur = GoRouter.of(context);
        if (routeur.canPop()) {
          routeur.pop();
        } else {
          routeur.go(Routes.compte);
        }
      },
      child: EmptyState(
        message: t.comptable.commun.enPreparationTitre,
        invitation: t.comptable.commun.enPreparationPhrase,
      ),
    );
  }
}
