// PUSH-1 (07/11/2026, DECISION-PUSH-2026-11-01 amendee le 07/11) : les
// notifications sur l'appareil. Le serveur decide tout (qui peut s'abonner,
// ce qui part en push, jamais un compte enfant) ; l'application ne fait que
// demander l'autorisation apres un geste, transmettre l'abonnement et
// afficher les reglages que le serveur rend.

import 'package:flutter/foundation.dart';

/// Les cinq categories que la personne coupe ou garde (meme liste que la
/// contrainte de `public.push_preferences`).
enum CategoriePush {
  /// Classes et seances.
  classes,

  /// Remplacements.
  remplacements,

  /// Paiements.
  paiements,

  /// Demandes et dossiers.
  admissions,

  /// Suivi des eleves.
  suivi;

  /// La categorie d'un code du serveur ; nulle s'il est inconnu.
  static CategoriePush? depuisCode(String code) {
    for (final CategoriePush c in values) {
      if (c.name == code) return c;
    }
    return null;
  }
}

/// Ce que le navigateur de cet appareil permet.
enum EtatAppareilPush {
  /// Le navigateur ne recoit pas de push.
  nonPrisEnCharge,

  /// iPhone ou iPad : l'application doit etre ajoutee a l'ecran d'accueil.
  iosEcranAccueil,

  /// La personne a bloque les notifications dans le navigateur.
  refuse,

  /// Rien n'est encore demande, ou l'abonnement est retire.
  inactif,

  /// L'appareil est abonne.
  actif,
}

/// Un abonnement Web Push, tel que le navigateur le rend.
@immutable
class AbonnementNavigateur {
  /// Cree un abonnement.
  const AbonnementNavigateur({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
  });

  /// L'adresse du service de push.
  final String endpoint;

  /// La cle publique de l'appareil (base64url).
  final String p256dh;

  /// Le secret d'authentification de l'appareil (base64url).
  final String auth;
}

/// Pourquoi l'appareil n'a pas pu etre abonne.
enum RefusActivation {
  /// La personne a refuse l'autorisation (le navigateur la bloque).
  refuse,

  /// La personne a ferme la demande sans choisir.
  ignore,

  /// Le navigateur ne recoit pas de push.
  nonPrisEnCharge,

  /// Le navigateur n'a pas pu creer l'abonnement.
  echec,
}

/// Le refus d'une activation.
class ActivationRefusee implements Exception {
  /// Cree le refus.
  const ActivationRefusee(this.raison);

  /// La raison.
  final RefusActivation raison;

  @override
  String toString() => 'ActivationRefusee($raison)';
}

/// Le Web Push du navigateur (web : `web/push_client.js` ; ailleurs : rien).
abstract interface class NavigateurPush {
  /// Ce que le navigateur permet, et si cet appareil est abonne.
  Future<EtatAppareilPush> etat();

  /// L'adresse de l'abonnement de cet appareil, nulle s'il n'y en a pas.
  Future<String?> adresse();

  /// Demande l'autorisation et abonne l'appareil. A appeler depuis le geste
  /// de la personne, sans attente avant : la demande doit suivre le geste.
  /// Leve [ActivationRefusee].
  Future<AbonnementNavigateur> activer(String clePublique);

  /// Retire l'abonnement de cet appareil ; rend son adresse, ou nulle.
  Future<String?> desactiver();

  /// Ce navigateur n'ouvre la demande d'autorisation qu'apres un geste de la
  /// personne (Safari, iOS, Firefox) : la demande se fait alors par un bouton.
  Future<bool> besoinGeste();

  /// Un nom court de l'appareil (« Android », « iPhone »...).
  String get appareil;
}

/// Les reglages rendus par `push_mes_reglages`.
@immutable
class ReglagesPushServeur {
  /// Cree les reglages.
  const ReglagesPushServeur({
    required this.autorise,
    required this.cetAppareil,
    required this.appareils,
    required this.categories,
  });

  /// Le compte peut recevoir des notifications sur l'appareil (jamais un
  /// compte enfant).
  final bool autorise;

  /// Cet appareil est inscrit sur le serveur.
  final bool cetAppareil;

  /// Le nombre d'appareils inscrits pour ce compte.
  final int appareils;

  /// Chaque categorie et son etat, dans l'ordre du serveur.
  final Map<CategoriePush, bool> categories;
}

/// Le serveur des notifications sur l'appareil.
abstract interface class PortPush {
  /// Les reglages de la personne ; [adresse] dit si cet appareil est inscrit.
  Future<ReglagesPushServeur> reglages({String? adresse});

  /// La cle publique VAPID (servie par le serveur, jamais ecrite ici).
  Future<String> clePublique();

  /// Inscrit cet appareil.
  Future<void> inscrire(AbonnementNavigateur abonnement, {String? appareil});

  /// Retire cet appareil.
  Future<void> desinscrire(String adresse);

  /// Coupe ou garde une categorie, pour tous les appareils de la personne.
  Future<void> reglerCategorie(CategoriePush categorie, {required bool actif});
}

/// Tout ce que la feuille des reglages affiche.
@immutable
class EtatReglagesPush {
  /// Cree l'etat.
  const EtatReglagesPush({
    required this.appareil,
    required this.serveur,
    required this.clePublique,
  });

  /// Ce que permet le navigateur de cet appareil.
  final EtatAppareilPush appareil;

  /// Ce que dit le serveur.
  final ReglagesPushServeur serveur;

  /// La cle publique, lue d'avance : l'activation part du geste sans attente.
  final String? clePublique;

  /// L'appareil recoit les notifications : abonne dans le navigateur ET
  /// inscrit sur le serveur.
  bool get actif => appareil == EtatAppareilPush.actif && serveur.cetAppareil;
}
