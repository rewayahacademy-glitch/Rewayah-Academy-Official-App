import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';

/// Les Messages metier (COM-M01, COM-W01) : **ecran provisoire pose par le
/// socle (COM-F)**, propriete de la voie COM-MSG, qui le remplace dans ce
/// dossier sans rouvrir le routeur.
///
/// Une seule page pour le tuteur (`/tuteur/messages`) et l'enseignant
/// (`/enseignant/messages`) : le routeur donne le retour du role, la page
/// ne lit aucun role. Tant qu'aucun port n'est branche (COM-BR), elle dit
/// honnetement que la fonction arrive, sans liste vide ni faux echec ; le
/// bandeau hors ligne vient de [PageShell].
class MessagesPage extends StatelessWidget {
  /// Cree la page.
  const MessagesPage({super.key, this.filId, this.cheminRetour});

  /// Le fil demande par l'adresse (`/messages/:filId`), s'il y en a un.
  /// Jamais une autorisation : le port decidera (COM-BR).
  final String? filId;

  /// Ou mene le retour : la page du role d'ou l'on vient, donnee par le
  /// routeur (jamais lue d'un role). Nul : aucun disque retour.
  final String? cheminRetour;

  @override
  Widget build(BuildContext context) {
    final n = t.com.socle.navigation.provisoire;
    return PageShell(
      titre: n.messagesTitre,
      onRetour: switch (cheminRetour) {
        final String chemin => () => GoRouter.of(context).go(chemin),
        null => null,
      },
      child: EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.com.socle.composants.etats.indisponibleTitre,
        phrase: n.messagesDetail,
        dependance: 'COM-MSG-1',
      ),
    );
  }
}
