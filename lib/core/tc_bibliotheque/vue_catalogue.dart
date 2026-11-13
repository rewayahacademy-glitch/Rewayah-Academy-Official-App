import 'package:flutter/foundation.dart';

import '../tc_telechargement/port_etat_offline.dart';
import 'library_resource.dart';
import 'port_catalogue.dart';
import 'recherche_catalogue.dart';

/// Ou la Bibliotheque est ouverte.
///
/// **Ce n'est pas deux bibliotheques**, c'est un ordre de decouverte
/// different : en classe, on cherche d'abord ce qu'on vient de montrer
/// (decision D-20, spec section 6.2). Le catalogue, les ressources, les etats
/// hors ligne et les droits sont les memes des deux cotes.
enum ContexteDecouverte {
  /// Bibliotheque ouverte depuis le Groupe ou la navigation.
  horsClasse,

  /// Bibliotheque ouverte en classe, en panneau ou en feuille.
  enClasse,
}

/// Les sections de la Bibliotheque.
enum IdSectionCatalogue {
  /// « Continuer » : derniere ressource, derniere position.
  continuer,

  /// « Pour ce groupe » : epinglees ou assignees.
  pourCeGroupe,

  /// « Recents ».
  recents,

  /// « Tous les supports ».
  tousLesSupports,

  /// Les resultats d'une recherche ou d'un filtre.
  resultats,
}

/// L'etat global de la Bibliotheque.
enum EtatCatalogue {
  /// La lecture est en cours.
  chargement,

  /// Le catalogue est vide : rien n'a encore ete publie.
  vide,

  /// La recherche ou les filtres ne rendent rien, mais le catalogue, lui,
  /// n'est pas vide. **Deux vides differents, deux messages differents.**
  aucunResultat,

  /// Il y a quelque chose a montrer.
  contenu,

  /// La lecture a echoue. Une absence n'est pas un echec.
  indisponible,
}

/// Une section rendue.
@immutable
class SectionCatalogue {
  /// Cree une section.
  const SectionCatalogue({required this.id, required this.ressources});

  /// De quelle section il s'agit.
  final IdSectionCatalogue id;

  /// Ce qu'elle contient, dans l'ordre d'affichage.
  final List<LibraryResource> ressources;
}

/// Ce que la Bibliotheque affiche, decide **hors de tout widget**.
///
/// Meme forme que `VueLecteur.depuis()` et `VuePresence.depuis()` : une
/// fonction pure, donc un comportement mesurable sans monter d'arbre de
/// widgets, et un seul endroit ou l'ordre de decouverte est ecrit -- celui que
/// la Bibliotheque hors classe et le `ClassLibraryPicker` partagent.
@immutable
class VueCatalogue {
  /// Cree une vue. Passer par [depuis] plutot que par ce constructeur.
  const VueCatalogue({
    required this.etat,
    required this.sections,
    required this.etatsOffline,
    required this.horsLigne,
    required this.contexte,
    this.reprise,
    this.rechercheActive = false,
  });

  /// L'etat global.
  final EtatCatalogue etat;

  /// Les sections, dans l'ordre de decouverte du contexte.
  final List<SectionCatalogue> sections;

  /// L'etat hors ligne de chaque ressource citee.
  final Map<String, EtatOffline> etatsOffline;

  /// Vrai quand l'APPAREIL est hors ligne. Vient de `horsLigneProvider`,
  /// jamais d'un second abonnement.
  final bool horsLigne;

  /// Ou la Bibliotheque est ouverte.
  final ContexteDecouverte contexte;

  /// « Continuer », quand il y a quelque chose a reprendre.
  final ReprisLecture? reprise;

  /// Vrai quand une requete ou un filtre est pose.
  final bool rechercheActive;

  /// L'etat hors ligne d'une ressource. `indisponible` quand il n'a pas ete
  /// mesure : une absence de mesure ne vaut pas une disponibilite.
  EtatOffline etatOffline(String resourceId) =>
      etatsOffline[resourceId] ?? EtatOffline.indisponible;

  /// Vrai quand la ressource peut etre ouverte **maintenant**.
  ///
  /// Deux raisons de dire non, et une seule d'entre elles est un defaut :
  /// une ressource sans version publiee n'a rien a montrer, et une ressource
  /// absente de l'appareil ne s'ouvre pas sans reseau. Dans les deux cas la
  /// carte reste visible et porte sa raison : la faire disparaitre ferait
  /// croire a une perte de droit.
  bool ouvrable(LibraryResource r) {
    if (!r.publiee) return false;
    if (!horsLigne) return true;
    final EtatOffline e = etatOffline(r.id);
    return e == EtatOffline.telecharge || e == EtatOffline.enCache;
  }

  /// Compose la vue.
  ///
  /// Aucun parametre optionnel pour les donnees : une section absente se passe
  /// en liste vide. Un appelant qui oublierait une source la verrait alors
  /// comme vide, pas comme nulle, et le bug se voit a l'ecran.
  static VueCatalogue depuis({
    required ContexteDecouverte contexte,
    required List<LibraryResource> tous,
    required List<LibraryResource> recents,
    required List<LibraryResource> pourGroupe,
    required Map<String, EtatOffline> etatsOffline,
    required bool horsLigne,
    ReprisLecture? reprise,
    String requete = '',
    FiltreCatalogue? filtre,
    bool chargement = false,
    bool echec = false,
  }) {
    if (echec) {
      return VueCatalogue(
        etat: EtatCatalogue.indisponible,
        sections: const <SectionCatalogue>[],
        etatsOffline: etatsOffline,
        horsLigne: horsLigne,
        contexte: contexte,
      );
    }
    if (chargement) {
      return VueCatalogue(
        etat: EtatCatalogue.chargement,
        sections: const <SectionCatalogue>[],
        etatsOffline: etatsOffline,
        horsLigne: horsLigne,
        contexte: contexte,
      );
    }

    final bool rechercheActive =
        requete.trim().isNotEmpty || (filtre != null && !filtre.vide);

    // Une reprise seule suffit a sortir du vide : « Continuer » est du
    // contenu, meme quand le reste du catalogue n'est pas encore lisible.
    if (tous.isEmpty &&
        recents.isEmpty &&
        pourGroupe.isEmpty &&
        reprise == null) {
      return VueCatalogue(
        etat: EtatCatalogue.vide,
        sections: const <SectionCatalogue>[],
        etatsOffline: etatsOffline,
        horsLigne: horsLigne,
        contexte: contexte,
        rechercheActive: rechercheActive,
      );
    }

    // Une recherche ou un filtre remplace les sections par une liste unique :
    // garder « Recents » et « Pour ce groupe » a cote de resultats filtres
    // ferait apparaitre des ressources que le filtre vient d'exclure.
    if (rechercheActive) {
      final List<LibraryResource> resultats = RechercheCatalogue.chercher(
        RechercheCatalogue.filtrer(tous, filtre, etats: etatsOffline),
        requete,
      );
      return VueCatalogue(
        etat: resultats.isEmpty
            ? EtatCatalogue.aucunResultat
            : EtatCatalogue.contenu,
        sections: resultats.isEmpty
            ? const <SectionCatalogue>[]
            : <SectionCatalogue>[
                SectionCatalogue(
                  id: IdSectionCatalogue.resultats,
                  ressources: resultats,
                ),
              ],
        etatsOffline: etatsOffline,
        horsLigne: horsLigne,
        contexte: contexte,
        // « Continuer » disparait pendant une recherche : la garder au-dessus
        // de resultats filtres montrerait une ressource que le filtre vient
        // d'exclure.
        rechercheActive: true,
      );
    }

    final List<SectionCatalogue> sections =
        <SectionCatalogue>[
              for (final IdSectionCatalogue id in _ordre(contexte))
                SectionCatalogue(
                  id: id,
                  ressources: switch (id) {
                    IdSectionCatalogue.pourCeGroupe => pourGroupe,
                    IdSectionCatalogue.recents => recents,
                    IdSectionCatalogue.tousLesSupports => tous,
                    IdSectionCatalogue.continuer ||
                    IdSectionCatalogue.resultats => const <LibraryResource>[],
                  },
                ),
            ]
            .where((SectionCatalogue s) => s.ressources.isNotEmpty)
            .toList(growable: false);

    return VueCatalogue(
      etat: sections.isEmpty && reprise == null
          ? EtatCatalogue.vide
          : EtatCatalogue.contenu,
      sections: sections,
      etatsOffline: etatsOffline,
      horsLigne: horsLigne,
      contexte: contexte,
      reprise: reprise,
    );
  }

  /// L'ordre de decouverte du contexte.
  ///
  /// Hors classe (spec section 6.1) : Continuer, Pour ce groupe, Recents, Tous.
  /// En classe (spec section 6.2) : Recents, Ce groupe, Tous, puis Recherche.
  /// « Continuer » n'est pas une section en classe : le professeur choisit ce
  /// qu'il montre, il ne reprend pas sa lecture personnelle devant le groupe.
  static List<IdSectionCatalogue> _ordre(ContexteDecouverte contexte) =>
      switch (contexte) {
        ContexteDecouverte.horsClasse => const <IdSectionCatalogue>[
          IdSectionCatalogue.pourCeGroupe,
          IdSectionCatalogue.recents,
          IdSectionCatalogue.tousLesSupports,
        ],
        ContexteDecouverte.enClasse => const <IdSectionCatalogue>[
          IdSectionCatalogue.recents,
          IdSectionCatalogue.pourCeGroupe,
          IdSectionCatalogue.tousLesSupports,
        ],
      };
}
