import '../tc_bibliotheque/content_position.dart';
import '../tc_bibliotheque/content_range.dart';

/// Ce que le lot H a besoin de savoir du contenu presente en classe.
///
/// **Ce n'est pas un contrat du chantier, et c'est volontaire.** L'etat partage
/// appartient a Agent F (`SharedContentState`, `PortEtatPartage`), et
/// l'AMENDEMENT 2 de `TEACHING_CORE_CONTRACTS.md` tranche le cas d'un port dont
/// la chaine de types est ouverte : on ne le stube pas, on expose une surface
/// etroite que l'hote remplira. `SharedContentState` traine `MarqueurSemantique`
/// (Agent D) et `ModeAffichagePartage` (Agent F), dont le lot H n'a **aucun**
/// usage : les recopier serait trois occasions de diverger pour deux lectures.
///
/// Les trois lectures ci-dessous sont exactement ce que le post-cours et le bloc
/// « Avant le prochain cours » consomment. Agent Z ecrit l'adaptateur au-dessus
/// de `PortEtatPartage` a l'integration ; la correspondance est donnee en
/// section 4 de `docs/teaching-core/TC_CONTRACT_REQUEST_H.md`.
///
/// **Une lecture manque cote serveur**, et elle est demandee : [repriseDeGroupe]
/// raisonne par **groupe**, alors que `PortEtatPartage` raisonne par **seance**.
/// La position ou un groupe reprend son cours survit a la seance qui l'a
/// produite -- c'est l'invariant `D-19`, « le Groupe est permanent, la Classe
/// Live est temporaire ».
abstract class SourceContenuSeance {
  /// La position ou la seance s'est arretee. `null` quand elle est inconnue.
  ///
  /// `null` n'est pas une position par defaut : le post-cours dit alors qu'il ne
  /// sait pas, plutot que de proposer la premiere page d'un support.
  Future<ContentPosition?> positionDeReprise(String sessionId);

  /// Les plages reellement travaillees pendant la seance.
  ///
  /// Vide quand rien n'a ete presente ou que la trace n'existe pas. Une liste
  /// vide dit « aucune plage connue », elle ne promet pas que rien n'a ete fait.
  Future<List<ContentRange>> rangesTravailles(String sessionId);

  /// La position ou le **groupe** reprend, toutes seances confondues.
  ///
  /// C'est elle qui rend l'action contextuelle « Reprendre le cours ». `null`
  /// quand le groupe n'a pas encore de position connue : l'action n'apparait
  /// alors pas du tout, au lieu d'apparaitre inerte.
  Future<ContentPosition?> repriseDeGroupe(String groupeId);
}

/// La source qui ne sait rien, et qui le dit.
///
/// **DOUBLE LOCAL ASSUME, et c'est l'etat reel du depot** : aucune persistance
/// de `SharedContentState` n'existe (zero occurrence de `shared_content` dans
/// les migrations), donc aucune position de reprise de groupe n'est lisible
/// aujourd'hui. Elle rend `null` et vide -- jamais une position inventee, qui
/// ferait reprendre un groupe au mauvais endroit.
class ContenuSeanceIndisponible implements SourceContenuSeance {
  /// Cree la source vide.
  const ContenuSeanceIndisponible();

  @override
  Future<ContentPosition?> positionDeReprise(String sessionId) async => null;

  @override
  Future<List<ContentRange>> rangesTravailles(String sessionId) async =>
      const <ContentRange>[];

  @override
  Future<ContentPosition?> repriseDeGroupe(String groupeId) async => null;
}
