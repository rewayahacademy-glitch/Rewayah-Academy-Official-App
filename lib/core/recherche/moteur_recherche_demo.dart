import 'dart:async';

import 'budgets_recherche.dart';
import 'modeles_recherche.dart';
import 'normalisation_recherche.dart';
import 'port_recherche.dart';

/// Une ligne du corpus de demonstration : tout ce que le moteur factice sait
/// d'un objet, et rien de plus (les champs prives n'y existent pas).
class EntreeCorpusDemo {
  /// Cree une entree.
  EntreeCorpusDemo({
    required this.type,
    required this.reference,
    required this.titre,
    required this.cible,
    this.contexte,
  }) : titreNormalise = normaliserPourRecherche(titre);

  /// La nature du resultat.
  final TypeResultat type;

  /// La reference opaque.
  final String reference;

  /// Le titre affiche et cherche.
  final String titre;

  /// La ligne de contexte affichee.
  final String? contexte;

  /// La destination.
  final CibleRecherche cible;

  /// Le titre sous sa forme de comparaison, calcule une fois.
  final String titreNormalise;
}

/// Ce que le moteur factice rend, pour jouer chaque etat sans serveur.
enum ComportementDemo {
  /// Repond normalement.
  normal,

  /// En panne : `indisponible`.
  indisponible,

  /// Ne repond jamais : le delai de la demande le coupe.
  silencieux,

  /// Trop de demandes.
  limite,

  /// Session expiree.
  sessionExpiree,

  /// Droit retire.
  contexteRevoque,
}

/// Le moteur de recherche factice d'un domaine (demonstration et tests).
///
/// Un corpus de plusieurs milliers d'elements, filtre par espace : **un
/// espace non liste ne voit rien et le domaine lui est absent**, jamais
/// desactive. Les curseurs sont opaques et lies a l'espace, au domaine et a
/// la requete : un curseur d'un autre contexte est refuse (`curseurPerime`).
/// Hors production seulement : en production, `moteursRechercheProvider` est
/// vide.
class MoteurRechercheDemo implements MoteurRechercheDomaine {
  /// Cree un moteur sur un [corpus], pour les [espaces] autorises.
  MoteurRechercheDemo({
    required this.domaine,
    required this.corpus,
    required this.espaces,
    this.comportement = ComportementDemo.normal,
    this.latence = Duration.zero,
  });

  @override
  final DomaineRecherche domaine;

  /// Le corpus complet (jamais montre tel quel : seule la reponse filtree
  /// sort du moteur).
  final List<EntreeCorpusDemo> corpus;

  /// Les espaces qui peuvent interroger ce domaine.
  final Set<EspaceRecherche> espaces;

  /// Le comportement joue.
  ComportementDemo comportement;

  /// L'attente avant la reponse, pour jouer le chargement et la lenteur.
  Duration latence;

  /// Le nombre d'appels recus (pour les tests de bornes).
  int appels = 0;

  @override
  Future<bool> disponiblePour(ContexteRecherche contexte) async =>
      espaces.contains(contexte.espace);

  @override
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    appels++;
    if (latence > Duration.zero) await Future<void>.delayed(latence);
    switch (comportement) {
      case ComportementDemo.silencieux:
        return Completer<ReponseDomaine>().future;
      case ComportementDemo.indisponible:
        return ReponseEchec(domaine, StatutRecherche.indisponible);
      case ComportementDemo.limite:
        return ReponseEchec(domaine, StatutRecherche.limite);
      case ComportementDemo.sessionExpiree:
        return ReponseEchec(domaine, StatutRecherche.sessionExpiree);
      case ComportementDemo.contexteRevoque:
        return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
      case ComportementDemo.normal:
        break;
    }
    if (!espaces.contains(contexte.espace)) {
      // Un espace non autorise ne sait rien de ce domaine.
      return ReponseEchec(domaine, StatutRecherche.contexteRevoque);
    }
    final String cle = normaliserPourRecherche(requete);
    final String empreinte = _empreinte(contexte, cle);
    int depart = 0;
    if (curseur != null) {
      final int? lu = _lireCurseur(curseur, empreinte);
      if (lu == null) {
        return ReponseEchec(domaine, StatutRecherche.curseurPerime);
      }
      depart = lu;
    }
    // Les titres qui commencent par la requete d'abord, puis l'ordre du
    // corpus : un classement stable, sans score cache.
    final List<EntreeCorpusDemo> prioritaires = <EntreeCorpusDemo>[];
    final List<EntreeCorpusDemo> autres = <EntreeCorpusDemo>[];
    for (final EntreeCorpusDemo e in corpus) {
      if (!correspondTousLesTermes(e.titreNormalise, cle)) continue;
      (e.titreNormalise.startsWith(cle) ? prioritaires : autres).add(e);
    }
    final List<EntreeCorpusDemo> trouves = <EntreeCorpusDemo>[
      ...prioritaires,
      ...autres,
    ];
    final int fin = (depart + limite).clamp(0, trouves.length);
    final bool aPlus = fin < trouves.length;
    return ReponseOk(
      domaine,
      elements: <ResultatRecherche>[
        for (final EntreeCorpusDemo e in trouves.sublist(
          depart.clamp(0, trouves.length),
          fin,
        ))
          ResultatRecherche(
            type: e.type,
            reference: e.reference,
            titre: e.titre,
            contexte: e.contexte,
            cible: e.cible,
          ),
      ],
      curseurSuivant: aPlus ? 'c1.${empreinte.hashCode}.$fin' : null,
      aPlus: aPlus,
    );
  }

  String _empreinte(ContexteRecherche contexte, String cle) =>
      '${domaine.name}|${contexte.espace.name}|$cle';

  int? _lireCurseur(String curseur, String empreinte) {
    final List<String> parties = curseur.split('.');
    if (parties.length != 3 || parties[0] != 'c1') return null;
    if (parties[1] != empreinte.hashCode.toString()) return null;
    return int.tryParse(parties[2]);
  }
}
