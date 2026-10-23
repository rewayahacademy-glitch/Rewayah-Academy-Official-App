// Le port de l'import des formulaires : `PortImportCandidatures`
// (`docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md`, section 2),
// pour `ADM-23`.
//
// Le contrat prevoyait trois methodes (`analyser`, `essaiABlanc`, `confirmer`).
// Tel que livre par CAND-L3 (23/10), le serveur analyse tout le fichier : le
// client l'envoie, il ne le lit pas. `analyser` et `essaiABlanc` ne font plus
// qu'une operation, [PortImportCandidatures.apercu]. Deux RPC, toutes deux
// reservees au super-admin en double verification (aal2 exigee en base) :
//
// - `apercu_import_formulaires` : l'essai a blanc. Aucune ecriture, hors une
//   ligne d'audit de compteurs. Ni nom, ni courriel, ni telephone ;
// - `confirmer_import_formulaires` : l'ecriture, idempotente par cle.
//
// Les refus du serveur arrivent **dans la reponse** (`{erreur: ...}`), jamais en
// exception de base : ils deviennent des [ErreurImportCandidatures] typees, que
// l'ecran dit en mots. Rien n'est dit importe avant la reponse du serveur.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'modeles_import_candidatures.dart';

/// La dependance serveur de l'import des formulaires (`CAND-BR-09`), pour la
/// trace et les tests : jamais affichee.
const String dependanceImportCandidatures = 'CAND-BR-09';

/// Pourquoi une operation de l'import n'a pas abouti. Aucune de ces erreurs
/// n'a ecrit quoi que ce soit, hormis [ImportHorsLigne] pendant une
/// confirmation : la reponse a pu se perdre.
sealed class ErreurImportCandidatures implements Exception {
  const ErreurImportCandidatures();
}

/// Le fichier n'a pas pu etre lu par le serveur. [cause] est le message du
/// serveur : il ne s'affiche pas tel quel.
final class FichierIllisible extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const FichierIllisible(this.cause);

  /// La cause rendue par le serveur.
  final String cause;
}

/// Le fichier ne contient aucune ligne.
final class FichierVide extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const FichierVide();
}

/// Deux colonnes portent le titre d'un meme champ : le serveur ne choisit pas.
final class EntetesAmbigus extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const EntetesAmbigus({required this.champs, required this.colonnes});

  /// Les champs reconnus deux fois.
  final List<ChampFormulaire> champs;

  /// Les colonnes, avec le champ retenu (la premiere reconnue).
  final List<ColonneLue> colonnes;
}

/// Des champs obligatoires n'ont aucune colonne.
final class MappageIncomplet extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const MappageIncomplet({required this.champs, required this.colonnes});

  /// Les champs manquants, nommes par le serveur.
  final List<ChampManquant> champs;

  /// Les colonnes, avec le champ reconnu dans chacune.
  final List<ColonneLue> colonnes;
}

/// Le super-admin n'est pas en double verification (aal2) : rien n'a ete ecrit.
final class DoubleVerificationRequise extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const DoubleVerificationRequise();
}

/// Le fichier, le classeur, l'onglet, le mappage ou le fuseau a change depuis
/// l'apercu : l'apercu ne vaut plus.
final class JetonPerime extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const JetonPerime();
}

/// La cle d'idempotence a deja servi pour un autre fichier ou un autre auteur.
final class CleIdempotenceReutilisee extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const CleIdempotenceReutilisee();
}

/// Un choix de doublon ne correspond pas au fichier : groupe inconnu, ligne qui
/// n'est pas dans le groupe, ou deux choix pour un groupe.
final class ChoixInvalide extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const ChoixInvalide(this.groupes);

  /// Les groupes nommes par le serveur.
  final List<String> groupes;
}

/// Le serveur a refuse les arguments (`22023`) : borne depassee, forme
/// inattendue. [message] est celui du serveur : il ne s'affiche pas tel quel.
final class ImportInvalide extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const ImportInvalide(this.message);

  /// Le message du serveur.
  final String message;
}

/// Le serveur a repondu une erreur que ce client ne connait pas.
final class ImportRefuseInconnu extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const ImportRefuseInconnu(this.code);

  /// Le code rendu (trace et tests, jamais affiche).
  final String code;
}

/// La connexion a coupe. Pour une confirmation, l'import est **non confirme** :
/// la meme demande, rejouee avec la meme cle d'idempotence, ne s'enregistre
/// qu'une fois.
final class ImportHorsLigne extends ErreurImportCandidatures {
  /// Cree l'erreur.
  const ImportHorsLigne();
}

/// Le port de l'import des formulaires.
abstract interface class PortImportCandidatures {
  /// Ce que ce lecteur peut faire de l'import. Une capacite se lit, jamais un
  /// role.
  Future<CapacitesImportCandidatures> capacites();

  /// L'essai a blanc de [csv] : aucune ecriture. [classeur] et [onglet]
  /// entrent dans la reference source de chaque reponse. [mappage] corrige la
  /// reconnaissance des titres ; [fuseau] dit l'heure des horodatages (UTC par
  /// defaut).
  ///
  /// Les erreurs sont des [ErreurImportCandidatures]. `CapaciteIndisponible`
  /// quand le lot serveur n'est pas encore verse, `PermissionInsuffisante` pour
  /// un lecteur qui n'est pas le super-admin.
  Future<ApercuImport> apercu({
    required String csv,
    required String classeur,
    required String onglet,
    MappageColonnes mappage = MappageColonnes.aucun,
    String fuseau = 'UTC',
  });

  /// La confirmation : ecrit des reponses importees, ni compte, ni invitation,
  /// ni piece, ni accord, ni candidature. [jeton] est celui de l'apercu du meme
  /// fichier. [choix] : un par groupe tranche par la direction. [cleIdempotence]
  /// (8 a 200 signes) : rejouer la meme cle avec le meme fichier rend le meme
  /// rapport, sans rien ecrire de plus.
  Future<RapportImport> confirmer({
    required String csv,
    required String classeur,
    required String onglet,
    required String jeton,
    required List<ChoixDoublon> choix,
    required String cleIdempotence,
    MappageColonnes mappage = MappageColonnes.aucun,
    String fuseau = 'UTC',
  });
}

/// Le port : absent avant le branchement serveur.
final Provider<PortImportCandidatures?> portImportCandidaturesProvider =
    Provider<PortImportCandidatures?>((Ref _) => null);

/// Les capacites de l'import. Sans port : [CapaciteIndisponible]. Relues a
/// chaque ouverture de la page, sans retentative automatique.
final FutureProvider<CapacitesImportCandidatures>
capacitesImportCandidaturesProvider =
    FutureProvider.autoDispose<CapacitesImportCandidatures>((Ref ref) {
      final PortImportCandidatures? port = ref.watch(
        portImportCandidaturesProvider,
      );
      if (port == null) {
        return Future<CapacitesImportCandidatures>.error(
          const CapaciteIndisponible(dependanceImportCandidatures),
        );
      }
      return port.capacites();
    }, retry: (int _, Object _) => null);
