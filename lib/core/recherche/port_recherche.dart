import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'budgets_recherche.dart';
import 'modeles_recherche.dart';

/// Le port de la recherche transversale (spec RECH-03 §8, §12).
///
/// **Une seule surface, plusieurs moteurs metier** : ce port ne contient
/// aucune logique de recherche. Il rend les domaines que la personne connectee
/// peut interroger, puis la reponse d'UN domaine a la fois, ce qui permet les
/// retours partiels (un domaine lent n'attend personne). L'adaptateur
/// Supabase de chaque domaine est ecrit par ChatGPT (Codex) dans
/// `*_supabase.dart` (COHABITATION.md, K-68) ; ce fichier ne porte que le
/// contrat et le raccord.
///
/// Regles du contrat, a tenir par tout adaptateur :
///
/// - le serveur tire l'identite de la session verifiee ; [ContexteRecherche]
///   est un choix d'interface, jamais une preuve de droit ;
/// - un domaine interdit est **absent** de [portees], jamais liste « desactive » ;
/// - `ReponseOk` sans element est le seul vide confirme ; toute panne est une
///   `ReponseEchec` ;
/// - aucun total, aucune facette globale, aucun lien signe, aucun corps de
///   message (SEC-R09, R10, R13).
abstract interface class PortRecherche {
  /// Les domaines que la personne peut interroger dans [contexte], dans
  /// l'ordre d'affichage.
  Future<List<DomaineRecherche>> portees(ContexteRecherche contexte);

  /// La reponse du [domaine] a [requete] (deja nettoyee), a partir de
  /// [curseur] (opaque, rendu par la page precedente) et pour au plus
  /// [limite] elements.
  Future<ReponseDomaine> rechercher({
    required DomaineRecherche domaine,
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  });
}

/// Un moteur metier : un domaine, son autorite de lecture, ses champs.
abstract interface class MoteurRechercheDomaine {
  /// Le domaine servi.
  DomaineRecherche get domaine;

  /// Vrai quand la personne peut interroger ce domaine dans [contexte].
  Future<bool> disponiblePour(ContexteRecherche contexte);

  /// La reponse du domaine (voir [PortRecherche.rechercher]).
  Future<ReponseDomaine> rechercher({
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  });
}

/// Le port de l'application : une liste de moteurs, un par domaine.
///
/// Sans moteur (production, tant qu'aucun adaptateur n'existe), aucun domaine
/// n'est servi : la page dit « Recherche indisponible pour le moment. » et
/// n'invente aucun resultat.
class PortRechercheParMoteurs implements PortRecherche {
  /// Cree le port sur les [moteurs] donnes.
  const PortRechercheParMoteurs(this.moteurs);

  /// Les moteurs raccordes.
  final List<MoteurRechercheDomaine> moteurs;

  @override
  Future<List<DomaineRecherche>> portees(ContexteRecherche contexte) async {
    final List<MoteurRechercheDomaine> ordre =
        <MoteurRechercheDomaine>[...moteurs]..sort(
          (MoteurRechercheDomaine a, MoteurRechercheDomaine b) =>
              a.domaine.index.compareTo(b.domaine.index),
        );
    final List<DomaineRecherche> servis = <DomaineRecherche>[];
    for (final MoteurRechercheDomaine m in ordre) {
      // Un moteur qui echoue a dire son droit est ferme : on ne devine pas.
      bool ouvert;
      try {
        ouvert = await m.disponiblePour(contexte);
      } on Object {
        ouvert = false;
      }
      if (ouvert && !servis.contains(m.domaine)) servis.add(m.domaine);
    }
    return servis;
  }

  @override
  Future<ReponseDomaine> rechercher({
    required DomaineRecherche domaine,
    required String requete,
    required ContexteRecherche contexte,
    String? curseur,
    int limite = BudgetsRecherche.limiteCommune,
  }) async {
    // Un domaine peut avoir plusieurs moteurs, un par source qui couvre un role
    // (RECHERCHE-LIVRAISON : les classes de la famille et celles de
    // l'enseignant ne se lisent pas au meme endroit). On interroge le premier
    // qui est ouvert a ce contexte ; faute d'un tel moteur, le premier du
    // domaine, qui repond lui-meme que le contexte est refuse.
    MoteurRechercheDomaine? choisi;
    for (final MoteurRechercheDomaine m in moteurs) {
      if (m.domaine != domaine) continue;
      choisi ??= m;
      try {
        if (await m.disponiblePour(contexte)) {
          choisi = m;
          break;
        }
      } on Object {
        // Un moteur qui echoue a dire son droit est ferme : on ne devine pas.
      }
    }
    if (choisi == null) {
      return ReponseEchec(domaine, StatutRecherche.indisponible);
    }
    try {
      return await choisi.rechercher(
        requete: requete,
        contexte: contexte,
        curseur: curseur,
        limite: limite.clamp(1, BudgetsRecherche.plafondPage),
      );
    } on Object {
      return ReponseEchec(domaine, StatutRecherche.indisponible);
    }
  }
}

/// Les moteurs raccordes a l'application. Vide par defaut (une page sans moteur
/// dit « Recherche indisponible », n'invente rien) ; l'application reelle les
/// pose dans `lib/main.dart` (`moteursRechercheProduction`) et la demonstration
/// (hors production) dans `surchargesDemo*`.
final Provider<List<MoteurRechercheDomaine>> moteursRechercheProvider =
    Provider<List<MoteurRechercheDomaine>>(
      (Ref ref) => const <MoteurRechercheDomaine>[],
    );

/// Le port de recherche utilise par l'application.
final Provider<PortRecherche> portRechercheProvider = Provider<PortRecherche>(
  (Ref ref) => PortRechercheParMoteurs(ref.watch(moteursRechercheProvider)),
);
