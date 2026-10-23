// Le port du candidat pour ses autres competences : `PortAutresCompetences`
// (`CAND-07`, « Vos autres talents », `CAND-BR-19`,
// `docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md`, section 3 bis), et
// celui du catalogue des competences, que lit la direction : `PortCatalogueCompetences`
// (section 3 ter).
//
// **Ce n'est pas un etat.** Ni `etat_dossier()` ni la candidature n'en portent
// rien : ce port lit et ecrit ses propres reponses, que ni un controle de
// passage ni le paiement ne lisent.
//
// Les refus metier arrivent dans la reponse du serveur et deviennent ici des
// exceptions typees ([RefusAutresCompetences]) : l'ecran dit chacun en mots,
// avec quoi faire (K-59), jamais un code. Un refus ne laisse aucune ecriture.
// Un port dont le lot serveur manque leve `CapaciteIndisponible('CAND-BR-19')` ;
// l'ecran le dit sans « Reessayer ». Une panne de reseau est
// `HorsLigneCandidature` : ce qui a ete envoye est alors non confirme.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../capacites/capacite_indisponible.dart';
import 'modeles_autres_competences.dart';
import 'modeles_candidature.dart';

/// Les refus metier du port des autres competences.
sealed class RefusAutresCompetences implements Exception {
  const RefusAutresCompetences();
}

/// Aucun document de reponses n'a encore ete envoye de la Salle d'examen : les
/// autres competences s'ouvrent apres l'envoi de la candidature.
final class QuestionnaireNonEnvoye extends RefusAutresCompetences {
  /// Cree le refus.
  const QuestionnaireNonEnvoye();
}

/// La candidature d'enseignant est refusee ou retiree : les reponses ne
/// s'enregistrent plus, elles se lisent et se retirent encore.
final class CandidatureClose extends RefusAutresCompetences {
  /// Cree le refus.
  const CandidatureClose(this.issue);

  /// L'issue de la candidature, quand le serveur la rend.
  final IssueCandidature? issue;
}

/// Les reponses ont change depuis l'ouverture de la page (autre appareil,
/// autre onglet) : [versionCourante] est la version a relire.
final class ConflitAutresCompetences extends RefusAutresCompetences {
  /// Cree le refus.
  const ConflitAutresCompetences(this.versionCourante);

  /// La version courante des reponses (0 sans reponse).
  final int? versionCourante;
}

/// Des reponses ne sont pas valables : [champs] les nomme (`domaines`,
/// `autreTexte`, `disponibilite`) et [motifs] donne la cause de chacun
/// (`domaine_desactive`, `texte_trop_long`...).
final class ReponsesAutresCompetencesInvalides extends RefusAutresCompetences {
  /// Cree le refus.
  const ReponsesAutresCompetencesInvalides(
    this.champs, {
    this.motifs = const <String, String>{},
  });

  /// Les champs refuses.
  final List<String> champs;

  /// La cause nommee d'un refus, par champ.
  final Map<String, String> motifs;

  /// Vrai quand une competence choisie n'est plus offerte (desactivee depuis).
  bool get domaineDesactive => motifs['domaines'] == 'domaine_desactive';

  /// Vrai quand le texte « Autre domaine » est trop long.
  bool get texteTropLong => motifs['autreTexte'] == 'texte_trop_long';
}

/// La cle d'idempotence a deja servi a un autre geste ou a une autre
/// candidature : un geste neuf prend une cle neuve.
final class CleAutresCompetencesReutilisee extends RefusAutresCompetences {
  /// Cree le refus.
  const CleAutresCompetencesReutilisee();
}

/// Le port du candidat pour ses autres competences.
abstract interface class PortAutresCompetences {
  /// Les reponses de la personne, si elle peut enregistrer, et le referentiel
  /// (catalogue et listes fermees). `PermissionInsuffisante` quand le compte
  /// n'est pas le titulaire d'une candidature d'enseignant ;
  /// `CapaciteIndisponible('CAND-BR-19')` sans lot serveur.
  Future<AutresCompetences> lire();

  /// Enregistre les reponses. [domaines] : au moins un code du catalogue, chacun
  /// avec son niveau ; [autreTexte] exige avec `autre`, refuse sinon ;
  /// [versionAttendue] vaut 0 tant que rien n'est enregistre. Rend la version ;
  /// **jamais une reponse** : l'ecran relit par [lire].
  ///
  /// Les refus sont des [RefusAutresCompetences]. Une panne de reseau est
  /// `HorsLigneCandidature` : rejouer la meme [cleIdempotence] est sans risque.
  Future<ResultatEnregistrement> enregistrer({
    required Map<String, NiveauCompetence> domaines,
    required DisponibiliteMission disponibilite,
    required bool accord,
    required int versionAttendue,
    required String cleIdempotence,
    String? autreTexte,
  });

  /// Retire les reponses et l'accord. Permis meme apres un refus ou un retrait
  /// de la candidature d'enseignant. `retire = false` quand rien n'etait
  /// enregistre.
  Future<ResultatRetrait> retirer({
    required int versionAttendue,
    required String cleIdempotence,
  });
}

/// Le port du catalogue des competences. Cette version ne lit que : l'ecriture
/// (`enregistrer_competence_catalogue`) viendra avec l'ecran du catalogue de la
/// direction.
abstract interface class PortCatalogueCompetences {
  /// Le catalogue : tout, avec les versions, pour la direction ; les actives et
  /// celles de sa propre reponse pour le candidat.
  Future<CatalogueCompetences> lire();
}

/// L'identifiant de la dependance serveur des autres competences et de leur
/// catalogue (`CAND-BR-19`), pour la trace et les tests : jamais affiche.
const String dependanceAutresCompetences = 'CAND-BR-19';

/// Le port des autres competences : absent avant le branchement serveur.
final Provider<PortAutresCompetences?> portAutresCompetencesProvider =
    Provider<PortAutresCompetences?>((Ref _) => null);

/// Le port du catalogue des competences : absent avant le branchement serveur.
final Provider<PortCatalogueCompetences?> portCatalogueCompetencesProvider =
    Provider<PortCatalogueCompetences?>((Ref _) => null);

/// Les autres competences de la personne. Sans port : [CapaciteIndisponible].
/// Relues a chaque ouverture ; aucune retentative automatique (un echec se
/// relit par « Reessayer »).
final FutureProvider<AutresCompetences> autresCompetencesProvider =
    FutureProvider.autoDispose<AutresCompetences>((Ref ref) {
      final PortAutresCompetences? port = ref.watch(
        portAutresCompetencesProvider,
      );
      if (port == null) {
        return Future<AutresCompetences>.error(
          const CapaciteIndisponible(dependanceAutresCompetences),
        );
      }
      return port.lire();
    }, retry: (int _, Object _) => null);

/// Le catalogue des competences. Sans port : [CapaciteIndisponible].
final FutureProvider<CatalogueCompetences> catalogueCompetencesProvider =
    FutureProvider.autoDispose<CatalogueCompetences>((Ref ref) {
      final PortCatalogueCompetences? port = ref.watch(
        portCatalogueCompetencesProvider,
      );
      if (port == null) {
        return Future<CatalogueCompetences>.error(
          const CapaciteIndisponible(dependanceAutresCompetences),
        );
      }
      return port.lire();
    }, retry: (int _, Object _) => null);
