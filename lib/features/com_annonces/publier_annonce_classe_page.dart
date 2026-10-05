import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/vue_etat_communication.dart';
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
/// Ouverte par URL directe, la page lit d'abord la capacite de publier
/// portee par la Classe (`CapaciteAnnonces.publier`, revue COM-R, R-20) :
/// sans elle, l'ecran dit que la publication est reservee et ne rend aucun
/// publieur. Le serveur refuse quand meme (COM-BR-10).
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

  /// La cle de l'etat « publication reservee », pour les tests.
  static const ValueKey<String> cleRefusee = ValueKey<String>(
    'publier-annonce-classe-refusee',
  );

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

    final String titre = t.com.socle.navigation.provisoire.publierAnnonceTitre;
    final AsyncValue<AnnoncesDeLaClasse> classe = ref.watch(
      annoncesDeClasseProvider(groupeId),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final p = t.com.annonces.publieur;
    Widget page(Widget corps) =>
        PageShell(titre: titre, onRetour: retour, child: corps);
    if (classe.hasError) {
      final Object erreur = classe.error!;
      return page(
        erreur is CapaciteIndisponible
            ? EtatSysteme(
                nature: NatureEtat.indisponible,
                titre: t.com.socle.composants.etats.indisponibleTitre,
                phrase: p.indisponible,
                dependance: erreur.dependance,
              )
            // R-23 : hors ligne ou echec, par l'aide partagee.
            : VueEtatCommunication.depuisErreur(
                erreur,
                horsLigne: horsLigne,
                onReessayer: () =>
                    ref.invalidate(annoncesDeClasseProvider(groupeId)),
              ),
      );
    }
    if (!classe.hasValue) {
      return page(
        Semantics(
          label: t.com.socle.composants.etats.chargement,
          child: const ExcludeSemantics(child: Skeleton.liste()),
        ),
      );
    }
    if (!classe.requireValue.peut(CapaciteAnnonces.publier)) {
      return page(
        EtatSysteme(
          key: cleRefusee,
          nature: NatureEtat.accesRefuse,
          titre: p.classeRefuseeTitre,
          phrase: p.classeRefusee,
        ),
      );
    }
    return ChargementPublieur(
      classeId: groupeId,
      titre: titre,
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
