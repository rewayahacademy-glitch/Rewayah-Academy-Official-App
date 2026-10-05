// L'onglet Messages de l'Administration des communications (COM-MSG-2 ;
// QUESTIONS Q4 ; spec section 3.2, section 21 « Administration »).
//
// `/admin/operations/communications/messages` et
// `/admin/operations/communications/messages/:filId`, dans la VRAIE coquille
// admin (`_CoquilleAdmin`, domaine Operations : aucun neuvieme domaine), sous
// la sous-navigation des trois onglets du socle (`ongletsCommunications`).
// La page d'Annonces (COM-ANN) n'importe jamais ce fichier : le routeur monte
// cette page directement sur `adminCommunicationsMessages` et `/:filId`
// (COM-FUS), parcours prouve depuis la vraie coquille admin
// (`test/features/com_messages/entrees_admin_test.dart`).
//
// Le meme espace que le tuteur et l'enseignant (`EspaceMessagesMetier`) :
// ses etats (chargement, vide, erreur, hors ligne, indisponible, fil
// inaccessible, envoi non confirme) et ses panneaux (Conversations | Fil |
// Contexte sur ordinateur, une surface a la fois sur telephone). Les fils de
// l'Administration comprennent ceux du controleur, sur sa mission (paire
// « Controleur / Administration » de la section 3.2) : le controleur, lui,
// ecrit depuis son ecran Echanges, inchange (C13).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/communications/titre_administration.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import 'messages_page.dart';

/// L'onglet Messages de l'Administration des communications.
class MessagesAdminPage extends StatelessWidget {
  /// Cree la page, sur la liste ou sur le fil [filId].
  const MessagesAdminPage({super.key, this.filId});

  /// Le fil demande par l'adresse, s'il y en a un. Jamais une autorisation :
  /// le port decide (COM-BR-01).
  final String? filId;

  /// L'index de l'onglet Messages, lu dans la liste du socle (jamais en dur).
  static int get indexOnglet => ongletsCommunications().indexWhere(
    (({String libelle, String chemin}) o) =>
        o.chemin == Routes.adminCommunicationsMessages,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) =>
          _page(contexte, contraintes.maxWidth),
    );
  }

  Widget _page(BuildContext context, double largeur) {
    return PageShell(
      // D-FUS-3 : le corps pose le bandeau hors ligne des Communications ;
      // pas de bandeau generique en plus.
      bandeauHorsLigne: const SizedBox.shrink(),
      // Le titre de la spec, replie sur « Messages » quand un mot ne
      // tiendrait pas (revue COM-R, R-09 et R-15).
      titre: titreAdministrationCommunications(
        context,
        largeurPage: largeur,
        repli: t.com.socle.navigation.ongletMessages,
      ),
      entete: SousNavigationDomaine(
        onglets: ongletsCommunications(),
        indexActif: indexOnglet,
      ),
      // Un fil ouvert revient a la liste de l'onglet ; la liste elle-meme est
      // une page de domaine, sans retour (la coquille porte la navigation).
      onRetour: filId == null
          ? null
          : () => GoRouter.of(context).go(Routes.adminCommunicationsMessages),
      defilante: false,
      child: EspaceMessagesMetier(
        filId: filId,
        onOuvrirFil: (String id) =>
            GoRouter.of(context)
                .go(Routes.adminFilPour(Uri.encodeComponent(id))),
      ),
    );
  }
}
