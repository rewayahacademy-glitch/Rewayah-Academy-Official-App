import 'package:flutter/foundation.dart';

import '../widgets/status_pill.dart';
import 'service_presence.dart';

/// Ce que la duree affichee a cote d'un etat est en train de mesurer.
///
/// **Une duree sans son repere ne veut rien dire.** « 3 minutes » n'a pas le
/// meme sens selon qu'il s'agit du temps passe en salle, du retard a l'entree
/// ou du silence depuis la derniere trace -- et c'est exactement le genre de
/// confusion que la Bible section 29.3 interdit en exigeant un contexte.
enum RepereTemps {
  /// Rien d'utile a dater : l'etat se suffit.
  aucun,

  /// Depuis l'entree en salle.
  entree,

  /// De combien l'entree a suivi l'heure prevue.
  retard,

  /// Depuis la derniere trace recue.
  silence,

  /// Depuis l'heure prevue, sans que personne ne soit entre.
  attente,
}

/// Ce qu'un ecran doit montrer d'une presence, a un instant donne.
///
/// **Fonction pure, comme `VueSalle.depuis` et `deciderRedirection`** : les
/// quinze etats, leurs tons et leurs reperes se verifient sans monter d'ecran,
/// sans base et sans horloge reelle. C'est aussi ce qui rend J3 et J7
/// mesurables : ils ne dependent pas du rendu.
///
/// Elle ne traduit rien. Les libelles vivent dans `strings.g.dart`, et l'ecran
/// les choisit d'apres [etat] : une fonction pure qui irait chercher `t` ne
/// serait plus testable hors du contexte de traduction.
@immutable
class VuePresence {
  const VuePresence._({
    required this.etat,
    required this.ton,
    required this.repere,
    required this.consolide,
    this.ecoule,
  });

  /// Calcule ce qu'il faut montrer d'une ligne de presence.
  ///
  /// [ligne] vaut `null` quand la presence est **indisponible** : la lecture a
  /// echoue, ou la personne n'a aucune ligne. L'etat est alors
  /// [EtatPresence.inconnu] -- **jamais « absente »**. C'est l'invariant J3, et
  /// c'est ici qu'il tient, pas dans l'ecran.
  factory VuePresence.depuis({
    required PresenceParticipant? ligne,
    required DateTime maintenant,
  }) {
    if (ligne == null) {
      return const VuePresence._(
        etat: EtatPresence.inconnu,
        ton: TonEtat.neutre,
        repere: RepereTemps.aucun,
        consolide: false,
      );
    }

    final RepereTemps repere = _repere(ligne.etat);
    final DateTime? origine = switch (repere) {
      RepereTemps.entree || RepereTemps.retard => ligne.entreLe,
      RepereTemps.silence => ligne.derniereTraceLe,
      RepereTemps.attente => ligne.debutSeance,
      RepereTemps.aucun => null,
    };

    // Le retard se mesure contre l'heure prevue, tout le reste contre
    // maintenant. Une duree negative -- une horloge d'appareil en avance, une
    // seance qui n'a pas commence -- ne s'affiche pas : mieux vaut taire une
    // duree que l'annoncer a l'envers.
    final Duration? ecoule = origine == null
        ? null
        : switch (repere) {
            RepereTemps.retard =>
              ligne.debutSeance == null
                  ? null
                  : origine.difference(ligne.debutSeance!),
            RepereTemps.entree ||
            RepereTemps.silence ||
            RepereTemps.attente => maintenant.difference(origine),
            RepereTemps.aucun => null,
          };

    return VuePresence._(
      etat: ligne.etat,
      ton: _ton(ligne.etat),
      repere: ecoule == null || ecoule.isNegative ? RepereTemps.aucun : repere,
      consolide: ligne.consolide,
      ecoule: ecoule != null && ecoule.isNegative ? null : ecoule,
    );
  }

  /// L'etat a montrer, [EtatPresence.inconnu] compris.
  final EtatPresence etat;

  /// La famille semantique dont la pastille tire sa teinte.
  final TonEtat ton;

  /// Ce que [ecoule] mesure.
  final RepereTemps repere;

  /// Le temps ecoule, quand [repere] en designe un.
  final Duration? ecoule;

  /// Vrai quand une decision humaine a fige cet etat.
  ///
  /// C'est le « provisoire contre finalise » de la section 6.6. La vue ne dit
  /// pas **pourquoi** : le motif reste en base et au journal d'audit.
  final bool consolide;

  /// Vrai quand l'etat demande une reaction.
  ///
  /// L'ecran s'en sert pour l'invariant **J7** : un etat critique ne se
  /// represente jamais par une couleur seule, il vient toujours avec son mot
  /// et, quand il y en a une, sa phrase de contexte.
  bool get critique => etat.critique;

  /// La teinte de chaque etat.
  ///
  /// **L'inconnu est neutre, et ce choix se defend dans les deux sens** : le
  /// peindre en rouge alarmerait sur un fait non constate, le peindre en vert
  /// rassurerait sur un fait tout aussi peu constate. Ne pas savoir n'est ni
  /// bon ni mauvais, c'est exactement ce que `TonEtat.neutre` veut dire.
  static TonEtat _ton(EtatPresence etat) => switch (etat) {
    EtatPresence.presente ||
    EtatPresence.reconnectee ||
    EtatPresence.finalisee => TonEtat.succes,
    EtatPresence.enConnexion => TonEtat.accent,
    EtatPresence.enRetard ||
    EtatPresence.enReconnexion => TonEtat.avertissement,
    EtatPresence.deconnectee || EtatPresence.absente => TonEtat.alerte,
    EtatPresence.planifiee ||
    EtatPresence.enAttente ||
    EtatPresence.sortie ||
    EtatPresence.excusee ||
    EtatPresence.confirmationEnAttente ||
    EtatPresence.corrigeeManuel ||
    EtatPresence.inconnu => TonEtat.neutre,
  };

  /// Ce que chaque etat donne a dater.
  static RepereTemps _repere(EtatPresence etat) => switch (etat) {
    EtatPresence.presente || EtatPresence.reconnectee => RepereTemps.entree,
    EtatPresence.enRetard => RepereTemps.retard,
    EtatPresence.deconnectee ||
    EtatPresence.enReconnexion ||
    EtatPresence.sortie => RepereTemps.silence,
    EtatPresence.enAttente => RepereTemps.attente,
    // Les six derniers ne datent rien : `planifiee` parle d'un futur,
    // `en_connexion` dure quelques secondes, et les quatre etats de cloture
    // portent leur propre date de decision, qui n'est pas une duree.
    EtatPresence.planifiee ||
    EtatPresence.enConnexion ||
    EtatPresence.absente ||
    EtatPresence.excusee ||
    EtatPresence.confirmationEnAttente ||
    EtatPresence.corrigeeManuel ||
    EtatPresence.finalisee ||
    EtatPresence.inconnu => RepereTemps.aucun,
  };
}

/// Le tableau de presence d'une seance, tel que l'enseignant le lit.
///
/// **Les inscrits, dans un ordre stable.** Les eleves d'abord, par prenom, puis
/// l'enseignant : c'est de ses eleves que l'enseignant est responsable, et
/// c'est la premiere ligne qu'il cherche. L'ordre ne depend **jamais de
/// l'etat**, alors qu'un tri par urgence serait tentant : la liste se relit
/// toutes les vingt secondes, et une ligne qui remonterait d'elle-meme entre
/// deux regards se ferait toucher a la place d'une autre.
///
/// Personne n'en est retire, soi-meme compris : un enseignant a le droit de
/// verifier qu'il est bien note present, et le controleur, lui, n'a deja
/// aucune ligne -- la vue le lui refuse en base (ADR-011).
List<PresenceParticipant> tableauDePresence(List<PresenceParticipant>? lignes) {
  if (lignes == null) {
    return const <PresenceParticipant>[];
  }
  return lignes.toList()..sort((PresenceParticipant a, PresenceParticipant b) {
    final int rangA = a.estEnseignant ? 1 : 0;
    final int rangB = b.estEnseignant ? 1 : 0;
    if (rangA != rangB) {
      return rangA - rangB;
    }
    return a.prenom.compareTo(b.prenom);
  });
}

/// Ma propre ligne dans la presence d'une seance.
///
/// Rend `null` quand elle n'y est pas -- ce qui n'est pas une anomalie : un
/// controleur n'a aucune ligne lisible, pas meme la sienne (ADR-011), et une
/// lecture qui a echoue n'a de ligne pour personne. Dans les deux cas l'ecran
/// affichera l'inconnu, et c'est la bonne reponse.
PresenceParticipant? maPresence(
  List<PresenceParticipant>? lignes,
  String? monProfilId,
) {
  if (lignes == null || monProfilId == null) {
    return null;
  }
  for (final PresenceParticipant ligne in lignes) {
    if (ligne.profilId == monProfilId) {
      return ligne;
    }
  }
  return null;
}
