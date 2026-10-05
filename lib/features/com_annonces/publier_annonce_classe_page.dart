import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import 'administration_communications_page.dart' show ChargementPublieur;
import 'port_annonces.dart';
import 'publieur_annonce.dart';

/// Publier une annonce pour une Classe (spec section 13.4 ; COM-0b,
/// 02_DEC-04) : le MEME publieur que l'Administration (`PublieurAnnonce`),
/// limite a la Classe, audience fixee.
///
/// `/enseignant/groupe/:groupeId/annonce`, une tache focalisee ouverte depuis
/// l'Espace Classe enseignant (`FicheGroupePage`, emplacement
/// `AnnoncesDeClasse`, qui ne montre « Publier une annonce » qu'avec la
/// capacite portee par la Classe). La seule audience vient du serveur
/// (`ciblesPublication(classeId:)`) : sans elle, l'ecran le dit et ne
/// propose rien ; aucune annonce globale n'est possible ici. Le serveur
/// refuse quand meme toute autre audience (COM-BR-10).
///
/// Production : le port est neutre, l'ecran dit « pas encore disponible »,
/// sans saisie ni envoi. Le retour ramene a l'Espace Classe.
class PublierAnnonceClassePage extends ConsumerWidget {
  /// Cree la page.
  const PublierAnnonceClassePage({
    required this.groupeId,
    super.key,
    this.onRetour,
    this.horloge,
  });

  /// La Classe concernee, portee par l'adresse.
  final String groupeId;

  /// Le retour ; par defaut, l'Espace Classe de la meme Classe. La
  /// demonstration passe le sien.
  final VoidCallback? onRetour;

  /// L'horloge des creneaux du publieur ; par defaut, maintenant.
  final DateTime Function()? horloge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void retour() {
      final VoidCallback? r = onRetour;
      if (r != null) {
        r();
      } else {
        GoRouter.of(context).go(Routes.groupePour(groupeId));
      }
    }

    return ChargementPublieur(
      classeId: groupeId,
      titre: t.com.socle.navigation.provisoire.publierAnnonceTitre,
      onQuitter: retour,
      // Seule la Classe de l'adresse, lue par `classeId` (l'identifiant de
      // l'audience n'est pas celui de la Classe, COM-BR-10) : une audience
      // d'une autre nature rendue par erreur n'est jamais proposee ici.
      retenir: (CibleAnnonce c) =>
          c.nature == NatureCible.classe && c.classeId == groupeId,
      construire: (List<CibleAnnonce> cibles, bool peutProgrammer) =>
          PublieurAnnonce(
            cibles: cibles.take(1).toList(),
            audienceFixee: true,
            peutProgrammer: peutProgrammer,
            horloge: horloge,
            onQuitter: retour,
            onConfirmee: (AnnonceConfirmee _) =>
                ref.invalidate(annoncesDeClasseProvider(groupeId)),
          ),
    );
  }
}
