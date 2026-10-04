import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';

/// Publier une annonce pour une Classe (spec section 14) : **ecran
/// provisoire pose par le socle (COM-F)**, propriete de la voie COM-ANN.
///
/// `/enseignant/groupe/:groupeId/annonce`, une tache focalisee ouverte depuis
/// l'Espace Classe enseignant (`FicheGroupePage`, emplacement
/// `AnnoncesDeClasse`). Tant qu'aucun port n'est branche, aucune saisie ni
/// bouton d'envoi : rien ne promettrait une publication que rien ne porte.
class PublierAnnonceClassePage extends StatelessWidget {
  /// Cree la page.
  const PublierAnnonceClassePage({required this.groupeId, super.key});

  /// La Classe concernee, portee par l'adresse.
  final String groupeId;

  @override
  Widget build(BuildContext context) {
    final n = t.com.socle.navigation.provisoire;
    return PageShell(
      titre: n.publierAnnonceTitre,
      // Le retour ramene a l'Espace Classe de la meme Classe.
      onRetour: () => GoRouter.of(context).go(Routes.groupePour(groupeId)),
      child: EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.com.socle.composants.etats.indisponibleTitre,
        phrase: n.publierAnnonceDetail,
        dependance: 'COM-ANN-1',
      ),
    );
  }
}
