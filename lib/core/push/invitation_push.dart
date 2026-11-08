// NOTIF-DEFAUT (08/11/2026, ordre du directeur) : a la premiere connexion sur
// un appareil, l'application demande l'autorisation des notifications, une
// seule fois par appareil.
//
// Chrome, Edge et les navigateurs de meme moteur ouvrent la demande sans
// geste : elle part au chargement. Safari, iOS (application ajoutee a l'ecran
// d'accueil) et Firefox exigent un geste : une seule fenetre « Recevoir les
// notifications ? » avec « Activer », qui declenche la demande du systeme.
// Apres un refus, un « Plus tard » ou une demande ignoree, plus jamais de
// demande ici (memoire de l'appareil) ; la personne revient par Preferences.
//
// Le serveur decide qui peut s'abonner (un compte enfant ou inactif n'a rien) ;
// les categories sont toutes actives tant que la personne n'a rien coupe
// (`push_mes_reglages`, `push_notifier`).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/inscription/questionnaire/memoire_appareil.dart';
import '../session/session_controleur.dart';
import 'port_push.dart';
import 'reglages_push.dart';

/// La cle de la memoire de l'appareil : la demande a deja ete faite.
const String cleMemoireInvitationPush = 'rewayah.notifications.invitation';

/// Ce que l'invitation montre.
class EtatInvitationPush {
  /// Cree l'etat.
  const EtatInvitationPush({
    this.visible = false,
    this.cle,
    this.enCours = false,
  });

  /// La fenetre est a l'ecran.
  final bool visible;

  /// La cle publique, lue d'avance : la demande suit le geste sans attente.
  final String? cle;

  /// « Activer » attend la reponse.
  final bool enCours;
}

/// L'invitation de premiere connexion.
class InvitationPush extends Notifier<EtatInvitationPush> {
  bool _verifiee = false;

  @override
  EtatInvitationPush build() => const EtatInvitationPush();

  /// A la connexion d'une personne : verifie, une fois, s'il faut demander.
  Future<void> verifier() async {
    if (_verifiee) return;
    _verifiee = true;
    if (lireMemoireAppareil(cleMemoireInvitationPush) != null) return;
    final PortPush? port = ref.read(portPushProvider);
    if (port == null) {
      _verifiee = false;
      return;
    }
    final NavigateurPush navigateur = ref.read(navigateurPushProvider);
    final EtatReglagesPush lu;
    final bool geste;
    try {
      lu = await lireReglagesPush(navigateur, port);
      geste = await navigateur.besoinGeste();
    } on Object {
      // Serveur injoignable : on redemandera a la prochaine ouverture.
      _verifiee = false;
      return;
    }
    if (lu.appareil == EtatAppareilPush.actif) {
      _retenir();
      return;
    }
    final String? cle = lu.clePublique;
    // Compte sans push, navigateur sans push, iPhone pas encore installe,
    // blocage deja choisi : rien a demander, et rien a retenir (un autre
    // compte, ou l'installation, peut changer la reponse).
    if (lu.appareil != EtatAppareilPush.inactif ||
        !lu.serveur.autorise ||
        cle == null) {
      return;
    }
    if (geste) {
      state = EtatInvitationPush(visible: true, cle: cle);
      return;
    }
    _retenir();
    try {
      await activerPush(navigateur, port, cle);
    } on Object {
      // Refus ou demande ignoree : retenu, la personne passe par Preferences.
    }
    ref.invalidate(reglagesPushProvider);
  }

  /// « Activer » : la demande du systeme part avant toute attente.
  Future<void> activer() async {
    final String? cle = state.cle;
    final PortPush? port = ref.read(portPushProvider);
    if (cle == null || port == null || state.enCours) return;
    final Future<void> demande = activerPush(
      ref.read(navigateurPushProvider),
      port,
      cle,
    );
    state = EtatInvitationPush(visible: true, cle: cle, enCours: true);
    try {
      await demande;
    } on Object {
      // Refus, demande ignoree ou echec : retenu, Preferences reste ouvert.
    }
    _retenir();
    state = const EtatInvitationPush();
    ref.invalidate(reglagesPushProvider);
  }

  /// « Plus tard » : on ne redemande plus ici.
  void plusTard() {
    _retenir();
    state = const EtatInvitationPush();
  }

  void _retenir() => ecrireMemoireAppareil(cleMemoireInvitationPush, 'faite');

  /// A la deconnexion : la fenetre disparait, la memoire de l'appareil reste.
  void oublierSession() {
    _verifiee = false;
    state = const EtatInvitationPush();
  }
}

/// L'invitation de premiere connexion.
final NotifierProvider<InvitationPush, EtatInvitationPush>
invitationPushProvider = NotifierProvider<InvitationPush, EtatInvitationPush>(
  InvitationPush.new,
);

/// Ecoute la session : a chaque personne connectee, une verification.
final Provider<void> veilleInvitationPushProvider = Provider<void>((Ref ref) {
  final InvitationPush invitation = ref.read(invitationPushProvider.notifier);
  ref.listen<String?>(sessionProvider.select((s) => s.profileId), (
    String? _,
    String? profil,
  ) {
    if (profil == null) {
      invitation.oublierSession();
    } else {
      unawaited(invitation.verifier());
    }
  }, fireImmediately: true);
});
