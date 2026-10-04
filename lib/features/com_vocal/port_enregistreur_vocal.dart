// Le port d'enregistrement des messages vocaux (spec Communications V1,
// section 11 ; contrat serveur COM-BR-03).
//
// **Aucun enregistrement reel dans cette version** : `pubspec.yaml` ne porte
// ni `record` ni `permission_handler` (K-19, UX_REVIEW_COMMUNICATIONS_L0
// point 10), et il est interdit de l'ouvrir. Le composer vocal vit donc
// entierement derriere ce port :
//
// - en production, `EnregistreurVocalIndisponible` leve `CapaciteIndisponible`
//   (`COM-BR-03`) a chaque appel : le composer dit « indisponible », il ne
//   simule jamais un micro ;
// - en demonstration seulement (`environnementAutoriseDemo`), un faux
//   enregistreur le remplace (`com_vocal_demo.dart`) ;
// - dans les tests, une horloge fixe ([horlogeVocaleProvider]) rend les
//   durees exactes.
//
// Un vocal enregistre ne porte qu'un identifiant local opaque et sa duree :
// jamais une URL de stockage, un chemin ou un jeton. La lecture d'un vocal
// recu passe par [PortLectureVocale], qui demandera un lien signe de courte
// duree au serveur au moment du toucher (BR-1), jamais garde ni affiche.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/port_pieces_jointes.dart';

/// La duree maximale d'un message vocal en V1 (spec section 11.1).
const Duration dureeMaxVocal = Duration(minutes: 3);

/// A partir de cette duree, l'enregistrement annonce la limite proche : il
/// reste trente secondes (choix d'interface, la spec ne fixe que la limite).
const Duration seuilLimiteProcheVocal = Duration(minutes: 2, seconds: 30);

/// La dependance serveur des messages vocaux (`COM-BR.md`, ligne COM-BR-03).
const String dependanceVocal = 'COM-BR-03';

/// L'heure courante, injectee : `DateTime.now` dans l'application, une
/// horloge fixe dans les tests.
typedef HorlogeVocale = DateTime Function();

/// L'horloge des messages vocaux. Les tests la remplacent par une horloge
/// qu'ils avancent eux-memes.
final Provider<HorlogeVocale> horlogeVocaleProvider = Provider<HorlogeVocale>(
  (Ref ref) => DateTime.now,
);

/// L'autorisation du microphone, telle que la plateforme la donne.
enum PermissionMicro {
  /// Le microphone est autorise : l'enregistrement peut commencer.
  accordee,

  /// La plateforme n'a pas encore pose la question : le composer l'explique
  /// avant de la poser.
  aDemander,

  /// La personne a refuse le microphone a Rewayah.
  refusee,
}

/// Un message vocal enregistre sur l'appareil, pas encore envoye.
@immutable
class EnregistrementVocal {
  /// Cree l'enregistrement.
  const EnregistrementVocal({required this.id, required this.duree});

  /// L'identifiant local, opaque : jamais un chemin, jamais affiche.
  final String id;

  /// La duree enregistree, bornee a [dureeMaxVocal].
  final Duration duree;

  @override
  bool operator ==(Object other) =>
      other is EnregistrementVocal && other.id == id && other.duree == duree;

  @override
  int get hashCode => Object.hash(id, duree);

  /// Ne rend jamais l'identifiant.
  @override
  String toString() => 'EnregistrementVocal(<opaque>, $duree)';
}

/// L'etat d'une lecture audio a un instant.
@immutable
class EtatLectureAudio {
  /// Cree l'etat.
  const EtatLectureAudio({
    this.position = Duration.zero,
    this.enLecture = false,
    this.termine = false,
    this.echec = false,
  });

  /// La position de lecture.
  final Duration position;

  /// Vrai pendant la lecture.
  final bool enLecture;

  /// Vrai quand la lecture est arrivee a la fin.
  final bool termine;

  /// Vrai quand la lecture s'est interrompue d'elle-meme apres son lancement
  /// (source expiree, reseau perdu) : le lecteur le dit et propose de
  /// reessayer.
  final bool echec;

  @override
  bool operator ==(Object other) =>
      other is EtatLectureAudio &&
      other.position == position &&
      other.enLecture == enLecture &&
      other.termine == termine &&
      other.echec == echec;

  @override
  int get hashCode => Object.hash(position, enLecture, termine, echec);
}

/// Une lecture audio ouverte : un vocal recu, ou la pre-ecoute d'un vocal
/// enregistre.
abstract interface class LectureVocale {
  /// La duree totale.
  Duration get duree;

  /// L'etat de la lecture, ecoute par le lecteur.
  ValueListenable<EtatLectureAudio> get etat;

  /// Lance ou reprend la lecture.
  Future<void> lire();

  /// Met la lecture en pause, la position gardee.
  Future<void> mettreEnPause();

  /// Revient au debut et relance la lecture.
  Future<void> relire();

  /// Libere la lecture : plus aucun son, plus aucune ecoute.
  Future<void> liberer();
}

/// L'enregistreur de messages vocaux de l'appareil.
///
/// Toutes les methodes peuvent lever [CapaciteIndisponible] (aucun
/// enregistreur sur cette plateforme) ou une autre erreur (micro occupe).
abstract interface class PortEnregistreurVocal {
  /// L'autorisation actuelle du microphone, sans poser la question.
  Future<PermissionMicro> permission();

  /// Pose la question de l'autorisation et rend la reponse.
  Future<PermissionMicro> demanderPermission();

  /// Demarre un nouvel enregistrement.
  Future<void> demarrer();

  /// Met l'enregistrement en pause.
  Future<void> mettreEnPause();

  /// Reprend l'enregistrement mis en pause.
  Future<void> reprendre();

  /// Arrete l'enregistrement et le rend, sans jamais l'envoyer. [duree] est
  /// la duree mesuree par le composer, deja bornee a [dureeMaxVocal].
  Future<EnregistrementVocal> arreter({required Duration duree});

  /// Abandonne l'enregistrement en cours (ou en pause), sans le garder.
  Future<void> abandonner();

  /// Efface un vocal enregistre et pas encore envoye.
  Future<void> supprimer(EnregistrementVocal vocal);

  /// Ouvre la pre-ecoute d'un vocal enregistre.
  Future<LectureVocale> preEcoute(EnregistrementVocal vocal);
}

/// L'enregistreur tant qu'aucun paquet ni contrat n'existe (COM-BR-03) :
/// chaque appel echoue avec [CapaciteIndisponible], jamais un faux micro.
class EnregistreurVocalIndisponible implements PortEnregistreurVocal {
  /// Cree l'implementation.
  const EnregistreurVocalIndisponible();

  static Future<T> _indisponible<T>() =>
      Future<T>.error(const CapaciteIndisponible(dependanceVocal));

  @override
  Future<PermissionMicro> permission() => _indisponible();

  @override
  Future<PermissionMicro> demanderPermission() => _indisponible();

  @override
  Future<void> demarrer() => _indisponible();

  @override
  Future<void> mettreEnPause() => _indisponible();

  @override
  Future<void> reprendre() => _indisponible();

  @override
  Future<EnregistrementVocal> arreter({required Duration duree}) =>
      _indisponible();

  @override
  Future<void> abandonner() => _indisponible();

  @override
  Future<void> supprimer(EnregistrementVocal vocal) => _indisponible();

  @override
  Future<LectureVocale> preEcoute(EnregistrementVocal vocal) => _indisponible();
}

/// L'enregistreur employe par l'application. La demonstration le remplace
/// par `overrideWithValue`, sous `environnementAutoriseDemo`.
final Provider<PortEnregistreurVocal> portEnregistreurVocalProvider =
    Provider<PortEnregistreurVocal>(
      (Ref ref) => const EnregistreurVocalIndisponible(),
    );

/// L'ouverture d'un vocal recu (piece jointe de nature
/// [NaturePieceJointe.vocal]).
abstract interface class PortLectureVocale {
  /// Ouvre la lecture de [vocal]. La source (lien signe de courte duree) est
  /// demandee au serveur ici, au toucher, et n'est ni gardee ni affichee.
  Future<LectureVocale> ouvrir(PieceJointe vocal);
}

/// La lecture tant qu'aucun contrat serveur n'existe (COM-BR-03).
class LectureVocaleIndisponible implements PortLectureVocale {
  /// Cree l'implementation.
  const LectureVocaleIndisponible();

  @override
  Future<LectureVocale> ouvrir(PieceJointe vocal) =>
      Future<LectureVocale>.error(const CapaciteIndisponible(dependanceVocal));
}

/// La lecture des vocaux employee par l'application. La demonstration la
/// remplace par `overrideWithValue`, sous `environnementAutoriseDemo`.
final Provider<PortLectureVocale> portLectureVocaleProvider =
    Provider<PortLectureVocale>((Ref ref) => const LectureVocaleIndisponible());
