import 'package:flutter/material.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/sous_navigation_domaine.dart';

/// Les trois onglets de l'Administration des communications, dans l'ordre de
/// [ongletsCommunications].
enum OngletCommunications {
  /// Les annonces (COM-ANN-2).
  annonces,

  /// La file de moderation (COM-ANN-2).
  moderation,

  /// Les fils de messages, cote administration (COM-MSG-2).
  messages,
}

/// L'Administration des communications (COM-W04) : **ecran provisoire pose
/// par le socle (COM-F)**, propriete de la voie COM-ANN (l'onglet Messages
/// sera rempli par COM-MSG-2).
///
/// Sous Operations (QUESTIONS Q4), jamais un neuvieme domaine : chaque
/// onglet est une route distincte (`/admin/operations/communications/...`),
/// choisie par [SousNavigationDomaine], comme Pedagogie. Tant qu'aucun port
/// n'est branche, chaque onglet dit que la fonction arrive.
class AdministrationCommunicationsPage extends StatelessWidget {
  /// Cree la page sur l'onglet [onglet].
  const AdministrationCommunicationsPage({
    required this.onglet,
    super.key,
    this.filId,
  });

  /// L'onglet ouvert.
  final OngletCommunications onglet;

  /// Le fil ouvert dans l'onglet Messages, s'il y en a un.
  final String? filId;

  @override
  Widget build(BuildContext context) {
    final n = t.com.socle.navigation.provisoire;
    return PageShell(
      titre: n.administrationTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsCommunications(),
        indexActif: onglet.index,
      ),
      child: EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.com.socle.composants.etats.indisponibleTitre,
        phrase: n.administrationDetail,
        dependance: switch (onglet) {
          OngletCommunications.annonces ||
          OngletCommunications.moderation => 'COM-ANN-2',
          OngletCommunications.messages => 'COM-MSG-2',
        },
      ),
    );
  }
}
