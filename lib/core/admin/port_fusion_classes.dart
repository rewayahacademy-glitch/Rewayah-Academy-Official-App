/// R5, R9, R10 (`DECISION-CLASSES-SIMULTANEES-2026-10-10.md`) : la fusion de
/// classes paralleles et le transfert d'un eleve, par la direction.
///
/// - **Fusion (R9)** : une classe passee sous le minimum se fusionne avec une
///   classe parallele de meme cle (meme horaire, meme categorie) qui a de la
///   place pour tous ses eleves. La fusion est atomique : membres transferes,
///   enseignant libere, historique conserve, chaque famille prevenue. Jamais
///   de fusion automatique et silencieuse : la direction voit l'apercu des
///   effets, puis confirme.
/// - **Transfert (R10)** : le passage d'un eleve vers une classe parallele
///   est une action de la direction. Elle est tracee, controlee par R5 (un
///   eleve n'est jamais dans deux classes dont les seances se chevauchent) et
///   la famille en est prevenue.
///
/// **Ce que le serveur porte, et que Flutter ne decide jamais** : quelles
/// classes sont des cibles possibles, l'apercu des effets, l'atomicite, le
/// controle R5, les notifications, l'historique. L'ecran dit ce que le port
/// rend, et ne suppose aucun etat quand la reponse n'arrive pas. **Le contrat
/// attendu** (ligne Contrats a demander) : `classes_cibles_fusion`,
/// `apercu_fusion`, `fusionner_classes` (idempotente par cle d'envoi),
/// `membres_transferables`, `transferer_eleve` (idempotente, refus
/// `chevauchement` / `classe_pleine`) et `historique_classe`.
///
/// Sans port ([portFusionClassesProvider] vaut `null`), l'ecran n'en rend
/// aucune action : les capacites (`peutFusionner`, `peutTransferer` d'une
/// `ClasseListee`) restent fausses, aucun bouton ne promet ce que rien ne
/// fait.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Une classe qui peut accueillir les eleves d'une autre : meme horaire,
/// meme categorie, assez de place.
@immutable
class ClasseCible {
  /// Cree une cible.
  const ClasseCible({
    required this.classeId,
    required this.nom,
    required this.membres,
    required this.capacite,
    this.enseignant,
  });

  /// L'identifiant de la classe.
  final String classeId;

  /// Son nom sans ambiguite (R16 : numero ou code, parmi ses classes
  /// paralleles).
  final String nom;

  /// Son titulaire. Nul : elle n'a pas encore d'enseignant (R7).
  final String? enseignant;

  /// Les eleves qu'elle compte.
  final int membres;

  /// Son plafond.
  final int capacite;

  /// Les places qui lui restent.
  int get places => capacite - membres;
}

/// Ce qu'une fusion fera, calcule par le serveur avant la confirmation.
@immutable
class ApercuFusion {
  /// Cree l'apercu.
  const ApercuFusion({
    required this.sourceNom,
    required this.cible,
    required this.membresDeplaces,
    required this.famillesNotifiees,
    this.enseignantLibere,
  });

  /// Le nom de la classe qui disparait.
  final String sourceNom;

  /// La classe qui accueille.
  final ClasseCible cible;

  /// Les eleves qui changent de classe.
  final int membresDeplaces;

  /// L'enseignant de la classe fusionnee, qui redevient libre a cet horaire.
  /// Nul : elle n'en avait pas.
  final String? enseignantLibere;

  /// Les familles qui seront prevenues.
  final int famillesNotifiees;

  /// Les eleves de la classe qui accueille apres la fusion.
  int get membresApres => cible.membres + membresDeplaces;
}

/// La reponse du serveur a une fusion.
@immutable
sealed class ResultatFusion {
  const ResultatFusion();
}

/// La fusion est faite, les familles sont prevenues.
final class FusionFaite extends ResultatFusion {
  /// Cree le resultat.
  const FusionFaite({required this.cibleNom, required this.elevesDeplaces});

  /// La classe qui a accueilli les eleves.
  final String cibleNom;

  /// Les eleves deplaces.
  final int elevesDeplaces;
}

/// Un autre membre de la direction a fusionne cette classe avant : rien n'a
/// ete fait en double.
final class FusionDejaFaite extends ResultatFusion {
  /// Cree le resultat.
  const FusionDejaFaite();
}

/// Le serveur a refuse la fusion, avec son motif en clair.
final class FusionRefusee extends ResultatFusion {
  /// Cree le resultat.
  const FusionRefusee(this.motif);

  /// Le motif, deja mis en mots par le serveur.
  final String motif;
}

/// Un eleve que la direction peut transferer.
@immutable
class MembreTransferable {
  /// Cree le membre.
  const MembreTransferable({required this.eleveId, required this.prenom});

  /// L'identifiant de l'eleve.
  final String eleveId;

  /// Son prenom.
  final String prenom;
}

/// Pourquoi un transfert est refuse.
enum RaisonRefusTransfert {
  /// Les seances de l'eleve se chevauchent (R5).
  chevauchement,

  /// La classe cible n'a plus de place.
  classePleine,

  /// Un autre motif, dit par le serveur.
  autre,
}

/// La reponse du serveur a un transfert.
@immutable
sealed class ResultatTransfert {
  const ResultatTransfert();
}

/// Le transfert est fait, la famille est prevenue.
final class TransfertFait extends ResultatTransfert {
  /// Cree le resultat.
  const TransfertFait({required this.prenom, required this.cibleNom});

  /// Le prenom de l'eleve.
  final String prenom;

  /// La classe qui l'accueille.
  final String cibleNom;
}

/// Ce transfert a deja ete fait : rien n'a ete fait en double.
final class TransfertDejaFait extends ResultatTransfert {
  /// Cree le resultat.
  const TransfertDejaFait();
}

/// Le serveur a refuse le transfert.
final class TransfertRefuse extends ResultatTransfert {
  /// Cree le resultat.
  const TransfertRefuse(this.raison, {this.motif});

  /// La raison du refus.
  final RaisonRefusTransfert raison;

  /// Le motif du serveur, pour [RaisonRefusTransfert.autre].
  final String? motif;
}

/// Ce qui est arrive a une classe.
enum TypeEvenementClasse {
  /// Elle a ete fusionnee dans une autre.
  fusionSortante,

  /// Une autre a ete fusionnee dedans.
  fusionEntrante,

  /// Un de ses eleves est parti vers une classe parallele.
  transfertSortant,

  /// Un eleve est arrive d'une classe parallele.
  transfertEntrant,
}

/// Une ligne de l'historique d'une classe.
@immutable
class EvenementClasse {
  /// Cree l'evenement.
  const EvenementClasse({
    required this.id,
    required this.type,
    required this.quand,
    required this.autreClasse,
    this.nombre,
    this.prenom,
  });

  /// L'identifiant de l'evenement.
  final String id;

  /// Ce qui est arrive.
  final TypeEvenementClasse type;

  /// Quand, tel que le serveur l'a trace.
  final DateTime quand;

  /// L'autre classe concernee, nommee sans ambiguite.
  final String autreClasse;

  /// Pour une fusion : le nombre d'eleves deplaces.
  final int? nombre;

  /// Pour un transfert : le prenom de l'eleve.
  final String? prenom;
}

/// Le port de la fusion, du transfert et de l'historique (R5, R9, R10).
abstract interface class PortFusionClasses {
  /// Les classes paralleles de [classeId] (meme horaire, meme categorie) qui
  /// ont de la place pour [eleves] eleves, ou pour tous ceux de [classeId]
  /// quand [eleves] est nul (fusion). Un transfert passe 1.
  Future<List<ClasseCible>> classesCibles(String classeId, {int? eleves});

  /// Ce que la fusion de [sourceId] dans [cibleId] fera.
  Future<ApercuFusion> apercu({
    required String sourceId,
    required String cibleId,
  });

  /// Fusionne [sourceId] dans [cibleId]. [cleEnvoi] est la meme pour toutes
  /// les pressions d'une meme feuille : le serveur ne fusionne jamais deux
  /// fois. Leve une exception quand la reponse n'arrive pas : l'ecran ne
  /// suppose alors aucun etat.
  Future<ResultatFusion> fusionner({
    required String sourceId,
    required String cibleId,
    required String cleEnvoi,
  });

  /// Les eleves de [classeId] que la direction peut transferer.
  Future<List<MembreTransferable>> membres(String classeId);

  /// Transfere [eleveId] de [sourceId] vers [cibleId] (R5 controle cote
  /// serveur). Meme regle d'idempotence que [fusionner].
  Future<ResultatTransfert> transferer({
    required String eleveId,
    required String sourceId,
    required String cibleId,
    required String cleEnvoi,
  });

  /// L'historique de [classeId], le plus recent d'abord.
  Future<List<EvenementClasse>> historique(String classeId);
}

/// L'identifiant de la dependance serveur, pour la trace et les tests
/// (jamais affiche).
const String dependanceFusion = 'DB-ECHELLE-FUSION';

/// Le port : absent avant le contrat serveur.
final Provider<PortFusionClasses?> portFusionClassesProvider =
    Provider<PortFusionClasses?>((Ref _) => null);

/// Ce que l'on cherche : les classes paralleles de [classeId] qui ont de la
/// place pour [eleves] eleves (nul : tous ceux de [classeId]).
typedef CleCibles = ({String classeId, int? eleves});

/// Les classes cibles d'une fusion ou d'un transfert. Aucune retentative
/// automatique : un echec se relit par « Reessayer ».
final FutureProviderFamily<List<ClasseCible>, CleCibles> classesCiblesProvider =
    FutureProvider.family<List<ClasseCible>, CleCibles>((
      Ref ref,
      CleCibles cle,
    ) {
      final PortFusionClasses? port = ref.watch(portFusionClassesProvider);
      if (port == null) {
        return Future<List<ClasseCible>>.error(StateError(dependanceFusion));
      }
      return port.classesCibles(cle.classeId, eleves: cle.eleves);
    }, retry: (int _, Object _) => null);

/// Les eleves transferables d'une classe.
final FutureProviderFamily<List<MembreTransferable>, String>
membresTransferablesProvider =
    FutureProvider.family<List<MembreTransferable>, String>((
      Ref ref,
      String id,
    ) {
      final PortFusionClasses? port = ref.watch(portFusionClassesProvider);
      if (port == null) {
        return Future<List<MembreTransferable>>.error(
          StateError(dependanceFusion),
        );
      }
      return port.membres(id);
    }, retry: (int _, Object _) => null);

/// L'historique d'une classe.
final FutureProviderFamily<List<EvenementClasse>, String>
historiqueClasseProvider = FutureProvider.family<List<EvenementClasse>, String>(
  (Ref ref, String id) {
    final PortFusionClasses? port = ref.watch(portFusionClassesProvider);
    if (port == null) {
      return Future<List<EvenementClasse>>.error(StateError(dependanceFusion));
    }
    return port.historique(id);
  },
  retry: (int _, Object _) => null,
);

/// L'apercu d'une fusion : la classe fusionnee et la classe qui accueille.
typedef CleApercuFusion = ({String sourceId, String cibleId});

/// L'apercu d'une fusion, relu a chaque choix de cible.
final FutureProviderFamily<ApercuFusion, CleApercuFusion> apercuFusionProvider =
    FutureProvider.family<ApercuFusion, CleApercuFusion>((
      Ref ref,
      CleApercuFusion cle,
    ) {
      final PortFusionClasses? port = ref.watch(portFusionClassesProvider);
      if (port == null) {
        return Future<ApercuFusion>.error(StateError(dependanceFusion));
      }
      return port.apercu(sourceId: cle.sourceId, cibleId: cle.cibleId);
    }, retry: (int _, Object _) => null);
