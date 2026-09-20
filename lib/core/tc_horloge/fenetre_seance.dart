import 'package:flutter/foundation.dart';

/// Les sept moments d'une seance, du point de vue de l'interface.
///
/// C'est la machine d'etats de la section 5.1 de la specification, posee **une
/// seule fois**. Deux machines existent deja dans le depot pour deux besoins
/// differents (`etatAccueilEleve()` cote eleve, `EtatLignePlanning` cote
/// controle) : celle-ci ne les remplace pas, elle donne au temps une source
/// unique que les deux peuvent consommer.
enum PhaseSeance {
  /// Avant la fenetre d'acces : « Rejoindre » absent ou desactive.
  avantFenetre,

  /// De l'ouverture de la salle jusqu'a T0 : « Salle ouverte ».
  salleOuverte,

  /// Connecte avant T0 : etat d'attente, **aucun temps academique consomme**.
  attenteAvantT0,

  /// De T0 a la fin prevue : « Cours en cours ».
  enCours,

  /// Apres la fin prevue, seance encore ouverte : « Cours toujours en cours ».
  ///
  /// **Jamais un compte a rebours negatif.**
  prolongee,

  /// Seance terminee : retour a la prochaine, « Rejoindre » ferme.
  terminee,
}

/// La fenetre d'une seance : ses bornes, et ce qu'on en deduit a un instant.
///
/// **Fonction pure, et c'est le point de tout l'objet.** Le depot porte deja
/// trois calculs de temps restant : `Seance.avantDebut()`
/// (`lib/core/planning/service_planning.dart`), `_compteARebours()` avec son
/// `Timer.periodic` dans `accueil_eleve_page.dart`, et un troisieme minuteur
/// dans `journee_page.dart`. `SessionClockVM` doit les **unifier**, pas devenir
/// le quatrieme : toute la logique de temps du Teaching Core passe par ici, et
/// nulle part ailleurs.
///
/// Trois regles inscrites dans le type lui-meme :
///
/// 1. **Aucun offset de fuseau.** Tous les instants sont en UTC, toutes les
///    operations sont des additions de duree sur des instants UTC. Un
///    changement d'heure ne traverse jamais ce fichier.
/// 2. **[fenetreAcces] est une donnee, pas une constante.** Elle arrive du port,
///    donc du serveur. Le depot porte deja trois valeurs de fenetre ecrites en
///    dur (`autoriser_jeton_video()`, `etat_presence()` et `seuilOuvertureSalle`
///    dans `lib/core/video/pre_vol.dart`) : **aucun agent n'en pose une
///    quatrieme** (decision `D-13`).
/// 3. **Le client ne decide rien.** `rejoindreOuvertA` dit ce qu'il faut
///    proposer ; la barriere reste `autoriser_jeton_video()`.
@immutable
class FenetreSeance {
  /// Cree la fenetre d'une occurrence.
  const FenetreSeance({
    required this.debutUtc,
    required this.finPrevueUtc,
    required this.fenetreAcces,
    required this.graceApresFin,
  }) : assert(
         fenetreAcces >= Duration.zero,
         'une fenetre d acces ne se compte pas a l envers',
       ),
       assert(
         graceApresFin >= Duration.zero,
         'une grace ne se compte pas a l envers',
       );

  /// Debut prevu, en UTC.
  final DateTime debutUtc;

  /// Fin prevue, en UTC.
  final DateTime finPrevueUtc;

  /// De combien la salle ouvre avant le debut. **Vient du serveur.**
  final Duration fenetreAcces;

  /// De combien une seance reste joignable apres sa fin prevue.
  final Duration graceApresFin;

  /// L'instant a partir duquel la salle est ouverte.
  DateTime get joinOpensAtUtc => debutUtc.subtract(fenetreAcces);

  /// L'instant apres lequel plus rien n'est joignable.
  DateTime get finGraceUtc => finPrevueUtc.add(graceApresFin);

  /// La phase a un instant donne.
  ///
  /// [connecte] distingue `salleOuverte` de `attenteAvantT0` : les deux
  /// decrivent le meme creneau, mais la seconde dit que la personne est **deja
  /// dans la salle**. La distinction porte l'invariant de la section 5.2 de la
  /// specification : entrer a T-20 prouve qu'on etait pret, cela ne credite
  /// aucune minute de presence academique.
  ///
  /// [seanceOuverte] est l'etat que le serveur declare. Apres la fin prevue,
  /// une seance encore ouverte est `prolongee` ; une seance close est
  /// `terminee`. Sans information, la grace tranche.
  PhaseSeance phaseA(
    DateTime maintenantUtc, {
    bool connecte = false,
    bool? seanceOuverte,
  }) {
    if (maintenantUtc.isBefore(joinOpensAtUtc)) {
      return PhaseSeance.avantFenetre;
    }
    if (maintenantUtc.isBefore(debutUtc)) {
      return connecte ? PhaseSeance.attenteAvantT0 : PhaseSeance.salleOuverte;
    }
    if (maintenantUtc.isBefore(finPrevueUtc)) {
      return PhaseSeance.enCours;
    }
    final bool encoreOuverte =
        seanceOuverte ?? maintenantUtc.isBefore(finGraceUtc);
    return encoreOuverte ? PhaseSeance.prolongee : PhaseSeance.terminee;
  }

  /// Le temps restant a afficher, ou `null` quand il n'y en a plus a afficher.
  ///
  /// Avant le debut, c'est le temps avant le debut. Pendant, c'est le temps
  /// avant la fin prevue. En prolongation et apres, c'est `null` : **un compte
  /// a rebours negatif est un mensonge**, et l'interface dit « Cours toujours
  /// en cours » plutot qu'un nombre.
  Duration? restantA(DateTime maintenantUtc, {bool? seanceOuverte}) {
    final PhaseSeance phase = phaseA(
      maintenantUtc,
      seanceOuverte: seanceOuverte,
    );
    return switch (phase) {
      PhaseSeance.avantFenetre ||
      PhaseSeance.salleOuverte ||
      PhaseSeance.attenteAvantT0 => debutUtc.difference(maintenantUtc),
      PhaseSeance.enCours => finPrevueUtc.difference(maintenantUtc),
      PhaseSeance.prolongee || PhaseSeance.terminee => null,
    };
  }

  /// Vrai quand il faut proposer « Rejoindre ».
  ///
  /// `maintenant >= joinOpensAtUtc` et la seance n'est pas terminee : c'est
  /// exactement l'invariant 5 du contrat `SessionClockVM`. La vraie barriere
  /// reste serveur.
  bool rejoindreOuvertA(DateTime maintenantUtc, {bool? seanceOuverte}) {
    if (maintenantUtc.isBefore(joinOpensAtUtc)) {
      return false;
    }
    return phaseA(maintenantUtc, seanceOuverte: seanceOuverte) !=
        PhaseSeance.terminee;
  }
}
