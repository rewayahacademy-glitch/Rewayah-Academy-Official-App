import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/alertes/alerte.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import 'ligne_alerte.dart';
import 'section_alertes.dart';

/// `ADM-ALERTES` : toutes les alertes ouvertes (`/admin/alertes`, ALERTE-1).
///
/// Ouverte par la cloche de la coquille, le bandeau d'alerte urgente et
/// « Voir toutes les alertes » du Centre de commande. UNE carte a lignes
/// fines, dans l'ordre de lecture : la gravite d'abord, puis la plus recente
/// (`trierAlertes`) ; une alerte urgente est donc toujours en tete, au-dessus
/// de tout autre contenu, jusqu'a son traitement. Chaque ligne ouvre la page
/// ou l'alerte se traite.
///
/// Production : aucune source (DASH-BR-03), la page le dit (« indisponible »),
/// jamais une liste vide. Cinq etats : voir [LectureAlertes].
class AlertesPage extends StatelessWidget {
  /// Cree la page.
  const AlertesPage({super.key});

  @override
  Widget build(BuildContext context) => PageShell(
    titre: t.alertes.titre,
    child: LectureAlertes(
      lignesSquelette: 4,
      vide: EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.alertes.videTitre,
        phrase: t.alertes.videPhrase,
      ),
      construire: (List<Alerte> alertes) => ListeAlertes(
        alertes: alertes,
        onOuvrir: (String chemin) => GoRouter.of(context).go(chemin),
      ),
    ),
  );
}
