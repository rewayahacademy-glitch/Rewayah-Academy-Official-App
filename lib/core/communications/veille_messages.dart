// MESSAGERIE-TEMPS-REEL (14/11/2026, retour du directeur en production) : la
// messagerie metier (candidat et direction compris) n'etait ni en direct ni
// signalee. Le serveur pose desormais, a chaque message recu et a chaque
// lecture, une ligne de `public.com_signaux` pour la personne concernee
// (migration 20261125800000), publiee dans Realtime.
//
// Le signal ne porte AUCUN texte : il dit « un fil vous concernant a bouge ».
// L'application relit alors ses lectures habituelles (`com_lister_fils`,
// `com_lire_fil`), sous les gardes du serveur. Le rang de la veille
// ([EtatVeilleMessages.rang]) est ce que chaque ecran des messages ecoute.
//
// Une veille A PART de la veille de fraicheur (`core/fraicheur`) : un canal
// propre, pour qu'un ennui de ce canal (table pas encore installee, par
// exemple) ne coupe jamais la fraicheur des classes et des seances.
//
// Si le temps reel tombe (canal en erreur, delai depasse), la veille le dit
// ([EtatVeilleMessages.enDirect] faux, message K-59 a l'ecran) et relit
// d'elle-meme toutes les 30 secondes, jusqu'au retour du canal.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fraicheur/avis_ephemere.dart';
import '../i18n/strings.g.dart';
import '../observabilite/journal_dev.dart';
import '../reseau/service_reseau.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import '../theme/app_delais.dart';

/// Ce qu'a fait la personne signalee : recevoir un message, ou lire un fil
/// (sur cet appareil ou un autre).
enum NatureSignalMessages {
  /// Un message est arrive dans un fil de la personne.
  message,

  /// La personne a lu un fil : ses badges sont a relire.
  lecture,
}

/// Ce que la veille des messages signale.
sealed class SignalMessages {
  const SignalMessages();
}

/// Un fil de la personne a bouge.
final class FilABouge extends SignalMessages {
  /// Cree le signal.
  const FilABouge({required this.filId, required this.nature});

  /// Le fil concerne. Jamais une autorisation : le port des messages decide.
  final String filId;

  /// Message recu ou lecture faite.
  final NatureSignalMessages nature;
}

/// Le canal vient d'etre joint ou rejoint : ce qui a pu arriver entre-temps
/// est inconnu, tout est a relire.
final class CanalMessagesRejoint extends SignalMessages {
  /// Cree le signal.
  const CanalMessagesRejoint();
}

/// Le canal est en erreur ou n'a pas repondu a temps. Arrive comme erreur du
/// flux de [PortVeilleMessages.ecouter] ; ne porte que le nom de l'etat.
final class ErreurCanalMessages implements Exception {
  /// Cree l'erreur.
  const ErreurCanalMessages(this.statut);

  /// Le nom de l'etat du canal (`channelError`, `timedOut`).
  final String statut;

  @override
  String toString() => 'ErreurCanalMessages($statut)';
}

/// Par ou l'application ecoute les signaux des messages.
abstract interface class PortVeilleMessages {
  /// Ouvre la veille pour la personne [profilId] ; se ferme quand l'ecoute
  /// est annulee.
  Stream<SignalMessages> ecouter(String profilId);
}

/// Une veille qui ne signale rien : tests, galerie, demonstration.
class VeilleMessagesMuette implements PortVeilleMessages {
  /// Cree la veille muette.
  const VeilleMessagesMuette();

  @override
  Stream<SignalMessages> ecouter(String profilId) =>
      const Stream<SignalMessages>.empty();
}

/// Le port employe par l'application : muet par defaut, l'adaptateur
/// Supabase est branche au demarrage reel (`lib/main.dart`).
final Provider<PortVeilleMessages> portVeilleMessagesProvider =
    Provider<PortVeilleMessages>((Ref ref) => const VeilleMessagesMuette());

/// L'etat de la veille des messages.
@immutable
class EtatVeilleMessages {
  /// Cree l'etat.
  const EtatVeilleMessages({this.rang = 0, this.enDirect = true, this.dernier});

  /// Monte a chaque signal (et a chaque relecture de repli) : les ecrans des
  /// messages relisent quand il change.
  final int rang;

  /// Faux quand le canal temps reel est tombe : les ecrans le disent (K-59)
  /// et la veille relit d'elle-meme a intervalle regulier.
  final bool enDirect;

  /// Le dernier fil signale, s'il y en a un.
  final FilABouge? dernier;

  /// L'etat suivant, rang monte.
  EtatVeilleMessages suivant({bool? enDirect, FilABouge? dernier}) =>
      EtatVeilleMessages(
        rang: rang + 1,
        enDirect: enDirect ?? this.enDirect,
        dernier: dernier ?? this.dernier,
      );
}

/// Le fil ouvert a l'ecran, s'il y en a un : un message qui y arrive se voit
/// deja, l'avis « Nouveau message » n'est pas pose.
final NotifierProvider<FilAfficheControleur, String?> filAfficheProvider =
    NotifierProvider<FilAfficheControleur, String?>(FilAfficheControleur.new);

/// Porte le fil ouvert a l'ecran.
class FilAfficheControleur extends Notifier<String?> {
  @override
  String? build() => null;

  /// Le fil [filId] est a l'ecran.
  void ouvrir(String filId) => state = filId;

  /// Le fil [filId] quitte l'ecran (rien si un autre l'a remplace).
  void fermer(String filId) {
    // Appele apres un demontage : la portee peut deja etre fermee.
    if (!ref.mounted) return;
    if (state == filId) state = null;
  }
}

/// L'etat de la veille, lu par les ecrans des messages. Sans dependance :
/// un ecran teste seul le lit sans ouvrir de session ni de canal. Seule la
/// veille ([veilleMessagesProvider]) l'ecrit.
final NotifierProvider<EtatVeilleMessagesControleur, EtatVeilleMessages>
etatVeilleMessagesProvider =
    NotifierProvider<EtatVeilleMessagesControleur, EtatVeilleMessages>(
      EtatVeilleMessagesControleur.new,
    );

/// Porte l'etat de la veille.
class EtatVeilleMessagesControleur extends Notifier<EtatVeilleMessages> {
  @override
  EtatVeilleMessages build() => const EtatVeilleMessages();

  /// Un fil a bouge.
  void signaler(FilABouge f) => state = state.suivant(dernier: f);

  /// Tout est a relire (jointure, retour du reseau, relecture de repli).
  void relire() => state = state.suivant();

  /// Le canal est (re)joint : retour au direct.
  void enDirect() => state = state.suivant(enDirect: true);

  /// Le canal est tombe.
  void horsDirect() {
    if (state.enDirect) state = state.suivant(enDirect: false);
  }
}

/// La veille des messages. **Montee par `RewayahApp` seulement**, comme la
/// veille de fraicheur : un ecran teste seul n'ouvre aucun canal. Ouverte
/// quand la session porte un profil, fermee quand il disparait ; elle ecrit
/// [etatVeilleMessagesProvider], tient le repli et pose l'avis.
final Provider<void> veilleMessagesProvider = Provider<void>((Ref ref) {
  final String? profil = ref.watch(
    sessionProvider.select((SessionState s) => s.profileId),
  );
  if (profil == null) return;
  final PortVeilleMessages port = ref.watch(portVeilleMessagesProvider);
  final EtatVeilleMessagesControleur etat = ref.read(
    etatVeilleMessagesProvider.notifier,
  );
  StreamSubscription<SignalMessages>? abonnement;
  Timer? repli;

  void auSignal(SignalMessages signal) {
    switch (signal) {
      case CanalMessagesRejoint():
        repli?.cancel();
        repli = null;
        etat.enDirect();
      case final FilABouge f:
        etat.signaler(f);
        if (f.nature == NatureSignalMessages.message &&
            ref.read(filAfficheProvider) != f.filId) {
          ref
              .read(avisEphemereProvider.notifier)
              .dire(t.com.messages.direct.nouveau);
        }
    }
  }

  void auxErreurs(Object erreur) {
    journalDev('Veille des messages en erreur : ${erreur.runtimeType}');
    if (erreur is! ErreurCanalMessages) return;
    etat.horsDirect();
    repli ??= Timer.periodic(AppDelais.repliMessages, (_) => etat.relire());
  }

  void ouvrir() {
    unawaited(abonnement?.cancel());
    abonnement = port.ecouter(profil).listen(auSignal, onError: auxErreurs);
  }

  ouvrir();
  ref.onDispose(() {
    repli?.cancel();
    unawaited(abonnement?.cancel());
  });
  // Au retour du reseau : nouvel abonnement et relecture.
  ref.listen<AsyncValue<bool>>(horsLigneProvider, (
    AsyncValue<bool>? avant,
    AsyncValue<bool> apres,
  ) {
    if ((avant?.value ?? false) && !(apres.value ?? false)) {
      ouvrir();
      etat.relire();
    }
  });
});
