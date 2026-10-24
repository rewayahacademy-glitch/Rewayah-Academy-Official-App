import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../observabilite/journal_dev.dart';

/// A partir de quand la salle s'ouvre a l'enseignant.
///
/// Le meme seuil que la base (ADR-005 : `debut - 10 minutes`), pose ici pour
/// **ne pas proposer** un geste dont on sait qu'il serait refuse. Ce n'est pas
/// une barriere : c'est `autoriser_jeton_video()` qui refuse, et elle refuserait
/// aussi bien si ce seuil etait faux.
///
/// L'enseignant l'obtient avant l'eleve, dont l'accueil n'offre « Rejoindre »
/// qu'en direct : c'est lui qui ouvre la salle, verifie son micro et accueille.
///
/// **Elle vit a cote du pre-vol, et ce n'est pas un rangement arbitraire** : les
/// deux repondent a la meme question, « ce geste peut-il aboutir maintenant ? ».
/// L'un interroge le materiel, l'autre l'horloge, et un ecran qui offre d'entrer
/// en salle a besoin des deux reponses. Remontee de `journee_page.dart` a
/// l'integration du lot Enseignant (`CONTRACT_REQUEST_A.md` §1) : une constante
/// que tout ecran offrant l'entree doit respecter n'a pas sa place dans le
/// fichier de l'un d'eux.
///
/// R8 (24/10/2026, decision du pilote) : vingt minutes, la valeur par defaut
/// du serveur (`app_config_int('join_window_minutes', 20)`, qui pose
/// `sessions.join_opens_at`). A dix, l'enseignant et le tuteur voyaient la
/// salle fermee dix minutes de trop alors que le serveur l'ouvrait deja.
const Duration seuilOuvertureSalle = Duration(minutes: 20);

/// Ce que le pre-vol a trouve.
///
/// Le pre-vol existe pour une raison precise : **une salle qui echoue apres
/// etre entree est bien pire qu'une salle qui refuse d'ouvrir.** Dans le
/// premier cas l'enseignant et l'eleve sont tous deux dedans, l'un voit l'autre
/// muet, et personne ne sait si c'est le micro, la permission ou le reseau. Le
/// pre-vol repond avant, pendant que l'usager est encore seul devant son ecran.
///
/// `sessions.status` porte deja la valeur `preflight` depuis l'etape 1 : cet
/// etat n'est pas invente ici, il attendait d'etre rempli.
@immutable
class ResultatPreVol {
  /// Cree un resultat.
  const ResultatPreVol({
    required this.microDisponible,
    required this.cameraDisponible,
    required this.sortieAudioDisponible,
    required this.permissionRefusee,
  });

  /// Au moins une entree audio est utilisable.
  final bool microDisponible;

  /// Au moins une camera est utilisable.
  final bool cameraDisponible;

  /// Au moins une sortie audio est utilisable.
  ///
  /// Sur le web cette liste est souvent vide alors que le son fonctionne : le
  /// navigateur ne l'expose qu'apres accord. Son absence n'est donc jamais
  /// bloquante, seulement informative.
  final bool sortieAudioDisponible;

  /// L'usager a refuse l'acces au materiel, ou le navigateur l'a refuse pour
  /// lui. C'est la cause la plus frequente, et la seule qui se repare sans
  /// changer de materiel.
  final bool permissionRefusee;

  /// Vrai quand la seance peut commencer.
  ///
  /// **Le micro suffit, et c'est deliberе** : pour une academie de Coran,
  /// l'audio prime sur la video (specification section 17 et ADR-001). Un
  /// eleve sans camera -- ou dont la politique camera l'interdit, ce qui est le
  /// defaut pour un mineur -- doit pouvoir suivre son cours.
  bool get peutEntrer => microDisponible && !permissionRefusee;
}

/// La verification du materiel avant d'entrer en salle.
abstract interface class ServicePreVol {
  /// Inspecte le materiel disponible.
  Future<ResultatPreVol> verifier();
}

/// L'implementation reelle, appuyee sur le SDK.
///
/// Elle n'enumere pas les peripheriques a la main : `Hardware` le fait deja,
/// sur les six plateformes, avec les differences de chacune. En reecrire une
/// version serait exactement ce que la specification section 2 interdit.
class ServicePreVolLiveKit implements ServicePreVol {
  /// Cree le service.
  const ServicePreVolLiveKit();

  @override
  Future<ResultatPreVol> verifier() async {
    try {
      final List<lk.MediaDevice> appareils = await lk.Hardware.instance
          .enumerateDevices();

      // Un peripherique dont le `label` est vide signale un navigateur qui n'a
      // pas encore accorde la permission : il existe, mais on ne sait pas
      // lequel c'est. On le compte comme present -- la demande de permission
      // viendra a l'ouverture de la piste.
      bool aUnDe(String genre) =>
          appareils.any((lk.MediaDevice d) => d.kind == genre);

      return ResultatPreVol(
        microDisponible: aUnDe('audioinput'),
        cameraDisponible: aUnDe('videoinput'),
        sortieAudioDisponible: aUnDe('audiooutput'),
        permissionRefusee: false,
      );
    } catch (e) {
      // Une exception ici, c'est presque toujours un refus de permission. On
      // ne peut pas le distinguer proprement d'une panne de peripherique sur
      // toutes les plateformes, et pretendre le contraire donnerait un message
      // faux une fois sur deux.
      journalDev('pre-vol impossible : $e');
      return const ResultatPreVol(
        microDisponible: false,
        cameraDisponible: false,
        sortieAudioDisponible: false,
        permissionRefusee: true,
      );
    }
  }
}

/// Le service de pre-vol employe par l'application.
final Provider<ServicePreVol> servicePreVolProvider = Provider<ServicePreVol>(
  (Ref ref) => const ServicePreVolLiveKit(),
);

/// Le resultat du pre-vol. **Le seul chemin du produit vers l'inspection du
/// materiel.**
///
/// Deux chemins existaient : celui-ci, que personne n'employait, et un appel
/// imperatif a [servicePreVolProvider] depuis la salle. Le prochain ecran qui en
/// aurait besoin -- la Journee, avant d'ouvrir une salle -- en aurait choisi un
/// au hasard, et deux mesures du meme materiel auraient fini par ne pas dire la
/// meme chose. Depuis le 20 septembre 2026, tout passe par ce provider.
///
/// **Il ne recalcule PAS a chaque ecoute**, contrairement a ce que disait ce
/// commentaire : un `FutureProvider` garde sa valeur tant qu'il vit, et celui-ci
/// vit aussi longtemps que l'application. C'est voulu -- enumerer les
/// peripheriques coute un aller-retour a la plateforme -- et cela impose deux
/// usages distincts :
///
/// - pour **savoir** ou l'on en est, on l'ecoute (`ref.watch`) ;
/// - pour **mesurer a nouveau**, on le rafraichit
///   (`ref.refresh(preVolProvider.future)`). C'est ce que fait la salle a chaque
///   entree et a chaque « Reessayer » : un casque branche entre deux essais ne
///   servirait a rien si l'on relisait le cache.
final FutureProvider<ResultatPreVol> preVolProvider =
    FutureProvider<ResultatPreVol>(
      (Ref ref) => ref.watch(servicePreVolProvider).verifier(),
    );
