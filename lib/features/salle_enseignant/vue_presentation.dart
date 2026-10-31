import 'package:flutter/foundation.dart';

import '../../core/coran/service_coran.dart';
import '../../core/video/video_session_provider.dart';

/// Ou en est la presentation de contenu, vue par l'enseignant.
///
/// **Ce ne sont pas les etats du lien, ce sont leurs consequences
/// pedagogiques.** `EtatSalle` dit ce que le moteur temps reel constate ;
/// celle-ci dit ce que l'enseignant peut encore faire de sa page, et ce n'est
/// pas la meme liste : un lien faible laisse tourner la page, une reconnexion
/// non. Traduire une fois ici evite que chaque widget du panneau refasse le
/// raisonnement, et surtout qu'un jour l'un d'eux l'oublie.
enum PhasePresentation {
  /// L'entree en salle n'a pas encore abouti. Rien ne part, et rien ne se perd
  /// non plus : il n'y a pas encore de classe a qui presenter.
  horsSalle,

  /// En salle, lien sain. Les commandes pedagogiques repondent.
  active,

  /// En salle, lien degrade. **La seance continue** : les commandes restent
  /// ouvertes, et le seul fait a dire est que le tour de page peut arriver en
  /// retard chez le groupe.
  instable,

  /// Le lien est perdu, le moteur le retablit.
  ///
  /// Les commandes se ferment -- un paquet publie maintenant n'atteindrait
  /// personne -- mais **le contenu presente reste affiche** : le socle le garde
  /// et le republie au retour, et une surface qui se viderait ici ferait croire
  /// a l'enseignant qu'il a perdu sa page.
  reconnexion,

  /// Le lien vient d'etre retabli, et le contenu presente a ete republie.
  ///
  /// Une phase a elle seule, et non un retour silencieux a [active] : qui a lu
  /// « Reconnexion » a besoin de lire qu'elle a abouti, sans quoi il tourne la
  /// page une seconde fois pour en etre sur.
  retabli,

  /// La connexion n'a pas pu etre retablie. La presentation est interrompue, et
  /// le dernier contenu reste affiche pour que rien ne soit perdu de vue.
  echec,
}

/// Ce que la surface de presentation de l'enseignant montre, a un instant donne.
///
/// **Fonction pure, comme `VueSalle.depuis` et `VueLecteur.depuis`** : les six
/// phases, le droit de presenter et les bornes du mushaf se verifient sans
/// monter d'ecran, sans reseau et sans SDK. Elle ne traduit rien : les libelles
/// vivent dans `strings.g.dart`, et le panneau les choisit d'apres [phase].
@immutable
class VuePresentation {
  const VuePresentation._({
    required this.phase,
    required this.peutPresenter,
    this.contenu,
  });

  /// Calcule la vue a partir de ce que le moteur publie.
  ///
  /// [contenu] vient du canal de donnees, **jamais d'un etat local** : le
  /// presentateur lit ce qu'il a publie par le meme chemin que le groupe, donc
  /// aucune divergence n'est possible entre ce qu'il croit montrer et ce qui est
  /// montre.
  ///
  /// [peutPresenter] est le droit signe dans le jeton (`can_publish_data`), pas
  /// une preference : un enseignant qui ne l'a pas ne doit voir aucun bouton qui
  /// echouerait.
  factory VuePresentation.depuis({
    required EtatSalle etatMoteur,
    required ContenuPresente? contenu,
    required bool peutPresenter,
  }) => VuePresentation._(
    phase: switch (etatMoteur) {
      EtatSalle.absent || EtatSalle.connexion => PhasePresentation.horsSalle,
      EtatSalle.connecte => PhasePresentation.active,
      EtatSalle.instable => PhasePresentation.instable,
      EtatSalle.reconnexion => PhasePresentation.reconnexion,
      EtatSalle.retabli => PhasePresentation.retabli,
      EtatSalle.echec || EtatSalle.retire => PhasePresentation.echec,
    },
    contenu: contenu,
    peutPresenter: peutPresenter,
  );

  /// Ou en est la presentation.
  final PhasePresentation phase;

  /// Le pointeur presente a la classe, ou `null` quand rien ne l'est.
  final ContenuPresente? contenu;

  /// Le jeton autorise la diffusion du contenu presente.
  final bool peutPresenter;

  /// Vrai quand une page est presentee au groupe.
  bool get presente => contenu != null;

  /// Vrai quand le lien porte encore un paquet.
  ///
  /// Les trois phases reunies ici ont ceci de commun que **le groupe recevrait**
  /// ce qui part maintenant. Le rassembler ici plutot que dans chaque bouton
  /// evite qu'une septieme phase, un jour, en oublie un.
  bool get lienPorte =>
      phase == PhasePresentation.active ||
      phase == PhasePresentation.instable ||
      phase == PhasePresentation.retabli;

  /// Vrai quand une commande de presentation aboutirait.
  bool get commandesActives => peutPresenter && lienPorte;

  /// Vrai quand la page reste affichee alors que le lien ne porte plus.
  ///
  /// C'est l'exigence de reconnexion sans perte d'etat pedagogique, cote
  /// interface : le socle garde le dernier contenu et le republie ; ici, on
  /// s'interdit simplement de l'effacer entre-temps.
  bool get contenuConserve =>
      contenu != null &&
      (phase == PhasePresentation.reconnexion ||
          phase == PhasePresentation.echec);

  /// La page precedente du mushaf, ou `null` a la premiere page.
  ///
  /// Bornee sur le **pointeur** et non sur la page lue : la reference est connue
  /// meme quand le texte n'a pas pu etre charge, et un enseignant doit pouvoir
  /// tourner la page malgre une lecture en echec.
  int? get pagePrecedente => switch (contenu) {
    final ContenuPresente pointeur when pointeur.page > 1 => pointeur.page - 1,
    _ => null,
  };

  /// La page suivante du mushaf, ou `null` a la derniere page de l'edition.
  int? get pageSuivante => switch (contenu) {
    final ContenuPresente pointeur when pointeur.page < pagesMushafMedine =>
      pointeur.page + 1,
    _ => null,
  };
}
