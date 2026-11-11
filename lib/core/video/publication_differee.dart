import 'dart:async';

import '../observabilite/journal_dev.dart';
import 'video_session_provider.dart';

/// MICRO-AVANT-ENSEIGNANT (decision du directeur du 11/11/2026, defaut SEC-1
/// de `docs/current/salle/CONSTAT.md`).
///
/// Tant que l'enseignant n'est pas dans la salle, le serveur LiveKit refuse
/// le micro et la camera d'un eleve. A l'entree de l'enseignant, le serveur
/// les lui rend (webhook `participant_joined`). **L'application ne decide
/// rien** : elle lit ce que le serveur accorde et, si un message s'est perdu,
/// elle le lui redemande.

/// Le role du jeton de celui qui conduit la seance (metadonnees signees).
const String roleQuiConduit = 'teacher';

/// L'acces [acces] apres un changement de permissions annonce par LiveKit
/// pour le participant local, ou `null` si rien ne change pour l'ecran.
///
/// [peutPublier] et [camera] sont ce que le serveur accorde maintenant.
///
/// RECITATION-MICRO-SEUL (directeur, 11/11/2026) : [micro] dit si le droit
/// de publier couvre le micro ([droitsAccordes]). Pendant la recitation d'un
/// camarade, le serveur ferme le micro seul : [peutPublier] et [camera]
/// vrais, [micro] faux. L'ecran n'a alors pas de bouton de micro, garde son
/// bouton de camera, et dit pourquoi. Absent : le micro suit [peutPublier].
AccesSalle? accesApresPermissions(
  AccesSalle acces, {
  required bool peutPublier,
  required bool camera,
  bool? micro,
}) {
  final AccesSalle neuf = acces.avecPublication(
    peutPublier: peutPublier,
    peutPublierVideo: camera,
    micro: micro,
  );
  final bool pareil =
      neuf.capacites.peutPublier == acces.capacites.peutPublier &&
      neuf.capacites.peutPublierVideo == acces.capacites.peutPublierVideo &&
      neuf.publicationDifferee == acces.publicationDifferee;
  return pareil ? null : neuf;
}

/// RECITATION-MICRO-SEUL (directeur, 11/11/2026) : ce que le serveur LiveKit
/// accorde au participant local, source par source.
///
/// [peutPublier] est le `canPublish` de LiveKit, [sources] les noms des
/// sources auxquelles il est borne (`canPublishSources` : `MICROPHONE`,
/// `CAMERA`). Sans liste, LiveKit autorise toutes les sources. Pendant la
/// recitation d'un camarade, la liste ne porte que `CAMERA` : le micro est
/// ferme, la camera reste.
({bool micro, bool camera}) droitsAccordes({
  required bool peutPublier,
  required Iterable<String> sources,
}) {
  if (!peutPublier) {
    return (micro: false, camera: false);
  }
  final Set<String> noms = sources.toSet();
  if (noms.isEmpty) {
    return (micro: true, camera: true);
  }
  return (micro: noms.contains('MICROPHONE'), camera: noms.contains('CAMERA'));
}

/// RECITATION-MICRO-SEUL (directeur, 11/11/2026) : vrai quand le serveur vient
/// de fermer le micro **alors que l'enseignant est dans la salle** : le micro
/// etait permis ([avant]), il ne l'est plus ([apres]).
///
/// C'est la recitation d'un camarade : la seule regle du serveur qui ferme un
/// micro devant l'enseignant (l'attente de l'enseignant et la fermeture apres
/// son depart ne jouent que sans lui, `microFermeSansEnseignant`).
///
/// Le moteur oublie alors que la personne voulait son micro ouvert : quand la
/// recitation se termine, le droit revient et **le micro reste ferme** tant
/// qu'elle ne le rouvre pas elle-meme (rien ne s'ouvre seul ; D-014 :
/// « Terminer la recitation rend son droit a chacun, micros fermes »). Une
/// reprise apres une veille ou une coupure de reseau n'est pas concernee : le
/// serveur n'y ferme aucun droit, et le micro voulu est rouvert.
bool microFermeDevantEnseignant({
  required AccesSalle avant,
  required AccesSalle apres,
  required bool enseignantPresent,
}) =>
    avant.capacites.peutPublier &&
    !apres.capacites.peutPublier &&
    enseignantPresent;

/// Vrai quand celui qui conduit la seance figure parmi les autres
/// participants de la salle.
bool enseignantDansLaSalle(List<ParticipantSalle> participants) => participants
    .any((ParticipantSalle p) => !p.estLocal && p.role == roleQuiConduit);

/// Le filet : l'eleve voit son enseignant dans la salle alors que son propre
/// droit de publier est encore ferme (webhook perdu ou en retard). Il le
/// redemande au serveur, qui reverifie tout lui-meme et rend le droit.
///
/// **Un eleve reste muet devant son enseignant serait pire que le defaut** :
/// tant que la situation dure, la demande est refaite, de plus en plus
/// espacee, jamais abandonnee. Elle s'arrete d'elle-meme quand le droit
/// arrive (par le webhook ou par ce filet), quand l'enseignant sort, ou a la
/// sortie de la salle.
class FiletPublication {
  /// Cree le filet. [demander] appelle le serveur (`create-room-token`,
  /// action `retablir_publication`) ; ses erreurs sont rattrapees ici.
  FiletPublication(this._demander);

  final Future<void> Function(AccesSalle acces) _demander;

  /// Le temps laisse au webhook avant la premiere demande : dans le cas
  /// ordinaire, le serveur a deja rendu le droit et rien n'est demande.
  static const Duration delaiPremiereDemande = Duration(seconds: 2);

  /// L'ecart le plus long entre deux demandes.
  static const Duration delaiMaximal = Duration(seconds: 15);

  AccesSalle? _acces;
  bool _aDemander = false;
  bool _enCours = false;
  int _essais = 0;
  Timer? _minuterie;

  /// L'ecart avant la demande numero [essais] (0 pour la premiere) : 2, 4, 8,
  /// puis 15 secondes.
  static Duration delaiAvant(int essais) {
    final int secondes = delaiPremiereDemande.inSeconds << essais.clamp(0, 6);
    return secondes >= delaiMaximal.inSeconds
        ? delaiMaximal
        : Duration(seconds: secondes);
  }

  /// A appeler a chaque changement de la salle ou des droits.
  void observer({required AccesSalle? acces, required bool enseignantPresent}) {
    _acces = acces;
    _aDemander =
        acces != null && acces.publicationDifferee && enseignantPresent;
    if (!_aDemander) {
      _minuterie?.cancel();
      _minuterie = null;
      _essais = 0;
      return;
    }
    _armer();
  }

  void _armer() {
    if (_minuterie != null || _enCours) return;
    _minuterie = Timer(delaiAvant(_essais), () => unawaited(_tenter()));
  }

  Future<void> _tenter() async {
    _minuterie = null;
    final AccesSalle? acces = _acces;
    if (!_aDemander || acces == null || _enCours) return;
    _enCours = true;
    _essais++;
    try {
      await _demander(acces);
    } catch (e) {
      // Une demande manquee n'arrete rien : la suivante reessaie.
      journalDev('retablissement de la publication non obtenu : $e');
    } finally {
      _enCours = false;
    }
    // Le droit arrive par l'evenement de permissions de LiveKit, qui repasse
    // par [observer] et arrete tout. Tant qu'il n'est pas la, on redemande.
    if (_aDemander) _armer();
  }

  /// Arrete tout (sortie de la salle).
  void arreter() {
    _minuterie?.cancel();
    _minuterie = null;
    _acces = null;
    _aDemander = false;
    _essais = 0;
  }
}
