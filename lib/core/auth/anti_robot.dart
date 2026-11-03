/// ANTI-ROBOT (03/11/2026) : le controle « je ne suis pas un robot » devant
/// l'envoi du lien de connexion et la connexion par mot de passe (fiche
/// PLAN-LOTS §13, decision du directeur du 03/11 : « Oui pour la securite »).
///
/// Le controle est Cloudflare Turnstile, en mode gere et presque invisible.
/// Le jeton qu'il rend part a Supabase par `captchaToken` ; c'est Supabase qui
/// le verifie, avec la cle secrete posee par le directeur (jamais dans le
/// depot, jamais dans l'application).
///
/// **Rien en dur.** La cle PUBLIQUE du site est un reglage de la console
/// (`securite.turnstile_cle_site`, migration 20261109000000), lu sans compte.
/// Reglage vide : aucun controle, l'ecran se comporte exactement comme avant.
/// C'est ce qui permet de livrer l'application avant d'activer le controle.
///
/// **Apercus Vercel** (`ENVIRONNEMENT=staging`) : ils visent la meme base que la
/// production. Ils montrent le widget avec la cle de TEST publique de
/// Cloudflare, documentee par Cloudflare pour les essais (elle passe toujours),
/// mais une fois le captcha actif dans Supabase, la connexion n'aboutit pas sur
/// un apercu : la cle secrete reelle refuse un jeton de test. La recette des
/// ecrans passe par le banc local (decision du pilote du 03/11, voie a).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';

/// La cle de site publique de TEST de Cloudflare (« passe toujours »), pour les
/// apercus seulement. Ce n'est pas un secret : Cloudflare la publie pour les
/// essais. La cle de production vient du reglage, jamais d'ici.
const String cleTurnstileApercu = '1x00000000000000000000AA';

/// La lecture de la cle publique du site.
abstract interface class PortCleTurnstile {
  /// La cle publique, ou `null` quand le reglage est vide (aucun controle).
  Future<String?> lire();
}

/// Le port : absent tant que `main.dart` ne le pose pas ; sans lui, aucun
/// controle (les tests et la demonstration gardent l'ecran d'avant).
final Provider<PortCleTurnstile?> portCleTurnstileProvider =
    Provider<PortCleTurnstile?>((Ref _) => null);

/// L'environnement de compilation, lu par un fournisseur pour les tests.
final Provider<String> environnementAntiRobotProvider = Provider<String>(
  (Ref _) => Env.environnement,
);

/// La cle a employer : celle de test sur un apercu, celle du reglage sinon ;
/// `null` : aucun controle. Une lecture impossible vaut « aucun controle » :
/// si Supabase exige pourtant un jeton, l'envoi le dira (`captcha_failed`).
final FutureProvider<String?> cleTurnstileProvider = FutureProvider<String?>((
  Ref ref,
) async {
  final PortCleTurnstile? port = ref.watch(portCleTurnstileProvider);
  if (port == null) return null;
  if (ref.watch(environnementAntiRobotProvider) == 'staging') {
    return cleTurnstileApercu;
  }
  try {
    final String? cle = (await port.lire())?.trim();
    return (cle == null || cle.isEmpty) ? null : cle;
  } on Object {
    return null;
  }
}, retry: (int _, Object _) => null);

/// Ou en est le controle.
enum EtatAntiRobot {
  /// Le widget se charge, ou la verification tourne.
  chargement,

  /// Un jeton est pret pour l'envoi.
  pret,

  /// La verification n'a pas abouti (ou le jeton a expire sans relance).
  erreur,

  /// Le reseau ne repond pas : le widget ne se charge pas.
  horsLigne,
}

/// Le controleur d'un controle pose sur un ecran : il recoit le jeton du
/// widget, le donne a l'envoi, puis demande un nouveau jeton (un jeton ne
/// sert qu'une fois).
class ControleurAntiRobot extends ChangeNotifier {
  EtatAntiRobot _etat = EtatAntiRobot.chargement;
  String? _jeton;
  VoidCallback? _relancer;
  Completer<String?>? _attente;

  /// L'etat courant.
  EtatAntiRobot get etat => _etat;

  /// Le jeton courant, ou `null`.
  String? get jeton => _jeton;

  /// Le widget s'y inscrit pour etre relance (un nouveau jeton).
  // ignore: use_setters_to_change_properties
  void brancher(VoidCallback relancer) => _relancer = relancer;

  /// Le widget s'en desinscrit.
  void debrancher() => _relancer = null;

  /// Le widget rend un jeton.
  void recevoirJeton(String jeton) {
    _jeton = jeton;
    _changer(EtatAntiRobot.pret);
  }

  /// Le widget dit que la verification n'a pas abouti.
  void signalerErreur({bool horsLigne = false}) {
    _jeton = null;
    _changer(horsLigne ? EtatAntiRobot.horsLigne : EtatAntiRobot.erreur);
  }

  /// Le jeton a expire : il ne vaut plus.
  void signalerExpiration() {
    _jeton = null;
    _changer(EtatAntiRobot.chargement);
  }

  /// « Reessayer » : un nouveau tour de verification.
  void relancer() {
    _jeton = null;
    _changer(EtatAntiRobot.chargement);
    _relancer?.call();
  }

  /// Le jeton pour un envoi : tout de suite s'il est pret ; sinon attendu au
  /// plus [delai] ; `null` si la verification n'aboutit pas.
  Future<String?> jetonPourEnvoi({
    Duration delai = const Duration(seconds: 15),
  }) {
    if (_etat == EtatAntiRobot.pret) return Future<String?>.value(_jeton);
    if (_etat != EtatAntiRobot.chargement) {
      return Future<String?>.value();
    }
    final Completer<String?> attente = _attente ??= Completer<String?>();
    return attente.future.timeout(delai, onTimeout: () => null);
  }

  /// Apres un envoi : le jeton est use, un autre est demande.
  void apresEnvoi() => relancer();

  void _changer(EtatAntiRobot etat) {
    _etat = etat;
    final Completer<String?>? attente = _attente;
    if (attente != null && etat != EtatAntiRobot.chargement) {
      _attente = null;
      if (!attente.isCompleted) attente.complete(_jeton);
    }
    notifyListeners();
  }
}

/// La fabrique du controleur d'un ecran ; les tests la remplacent pour donner
/// un jeton sans widget de Cloudflare.
final Provider<ControleurAntiRobot Function()>
fabriqueControleurAntiRobotProvider = Provider<ControleurAntiRobot Function()>(
  (Ref _) => ControleurAntiRobot.new,
);
