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

/// PE-A5 (20/11/2026) : pourquoi la verification n'a pas abouti, lu dans le
/// code d'erreur que Cloudflare rend (documentation « Client-side errors »).
/// Chaque cause a sa phrase : ce que la personne peut faire, elle, maintenant.
enum CauseEchecAntiRobot {
  /// Rien de precis : un nouvel essai suffit le plus souvent.
  inconnue,

  /// Le navigateur ne laisse pas la verification se faire (navigateur d'une
  /// application de messagerie, bloqueur, navigateur trop ancien).
  navigateur,

  /// L'heure de l'appareil est fausse (code 200100).
  horloge,

  /// Un reglage de l'academie (cle ou domaine refuses par Cloudflare) : la
  /// personne n'y peut rien.
  reglage,

  /// Aucune reponse de la verification dans le delai d'un envoi.
  delai,
}

/// La cause d'un code d'erreur de Cloudflare Turnstile (vide : inconnue).
CauseEchecAntiRobot causeDepuisCode(String? code) {
  final String c = (code ?? '').trim();
  if (c.isEmpty) return CauseEchecAntiRobot.inconnue;
  if (c == '200100') return CauseEchecAntiRobot.horloge;
  if (c.startsWith('1101') || c.startsWith('110200') || c.startsWith('4000')) {
    return CauseEchecAntiRobot.reglage;
  }
  if (c.startsWith('1105') ||
      c.startsWith('200500') ||
      c.startsWith('300') ||
      c.startsWith('600')) {
    return CauseEchecAntiRobot.navigateur;
  }
  return CauseEchecAntiRobot.inconnue;
}

/// Le controleur d'un controle pose sur un ecran : il recoit le jeton du
/// widget, le donne a l'envoi, puis demande un nouveau jeton (un jeton ne
/// sert qu'une fois).
class ControleurAntiRobot extends ChangeNotifier {
  EtatAntiRobot _etat = EtatAntiRobot.chargement;
  CauseEchecAntiRobot _cause = CauseEchecAntiRobot.inconnue;
  int _echecs = 0;
  String? _jeton;
  VoidCallback? _relancer;
  Completer<String?>? _attente;

  /// L'etat courant.
  EtatAntiRobot get etat => _etat;

  /// Le jeton courant, ou `null`.
  String? get jeton => _jeton;

  /// La cause du dernier echec (PE-A5).
  CauseEchecAntiRobot get cause => _cause;

  /// Le nombre d'echecs depuis le dernier jeton rendu : au second, la phrase
  /// propose un autre navigateur (PE-A5).
  int get echecs => _echecs;

  /// Le widget s'y inscrit pour etre relance (un nouveau jeton).
  // ignore: use_setters_to_change_properties
  void brancher(VoidCallback relancer) => _relancer = relancer;

  /// Le widget s'en desinscrit.
  void debrancher() => _relancer = null;

  /// Le widget rend un jeton.
  void recevoirJeton(String jeton) {
    _jeton = jeton;
    _echecs = 0;
    _cause = CauseEchecAntiRobot.inconnue;
    _changer(EtatAntiRobot.pret);
  }

  /// Le widget dit que la verification n'a pas abouti ; [code] : le code
  /// d'erreur de Cloudflare, s'il en rend un.
  void signalerErreur({bool horsLigne = false, String? code}) {
    _signalerEchec(
      horsLigne ? EtatAntiRobot.horsLigne : EtatAntiRobot.erreur,
      causeDepuisCode(code),
    );
  }

  void _signalerEchec(EtatAntiRobot etat, CauseEchecAntiRobot cause) {
    _jeton = null;
    _echecs++;
    _cause = cause;
    _changer(etat);
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
    // PE-A5 : au-dela du delai, l'echec se dit sous le bouton, avec
    // « Reessayer » et « Recharger la page » ; avant, l'etat restait « en
    // cours » et l'ecran n'offrait aucune issue.
    return attente.future.timeout(
      delai,
      onTimeout: () {
        if (_etat == EtatAntiRobot.chargement) {
          _signalerEchec(EtatAntiRobot.erreur, CauseEchecAntiRobot.delai);
        }
        return null;
      },
    );
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

/// PE-A5 (20/11/2026) : la cle a employer au moment d'un envoi.
///
/// Production, 18/11/2026 (journaux d'authentification) : six demandes de
/// lien sont parties **sans jeton** (« no captcha_token found ») alors que la
/// cle est reglee. Une cle lue nulle restait nulle jusqu'au rechargement de la
/// page (aucune relance), et l'ecran envoyait sans controle a chaque essai :
/// « La verification n'a pas abouti » sans fin. Ici, une cle nulle est relue
/// avant chaque envoi (au plus [delai]) ; si elle existe, le controle se pose
/// et l'envoi attend son jeton.
Future<String?> cleTurnstilePourEnvoi(
  WidgetRef ref, {
  Duration delai = const Duration(seconds: 6),
}) async {
  final String? deja = ref.read(cleTurnstileProvider).value;
  if (deja != null) return deja;
  try {
    return await ref.refresh(cleTurnstileProvider.future).timeout(delai);
  } on Object {
    return null;
  }
}
