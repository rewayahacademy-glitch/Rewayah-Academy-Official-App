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
import 'visibilite_onglet.dart';

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
///
/// Le rang est le seul signal que les ecrans relisent (chacun relit alors
/// `com_lister_fils`, une lecture couteuse). Il est donc regroupe : le premier
/// changement monte le rang tout de suite (un message recu se voit sans
/// attendre), puis les suivants, dans [AppDelais.regroupementMessages], ne
/// montent le rang qu'une seule fois a la fin de la fenetre. Une rafale
/// (message puis lecture, ou deux messages) coute une relecture de plus, pas
/// une par signal. L'etat (`enDirect`, `dernier`) reste, lui, immediat.
class EtatVeilleMessagesControleur extends Notifier<EtatVeilleMessages> {
  Timer? _fenetre;
  bool _enAttente = false;

  @override
  EtatVeilleMessages build() {
    ref.onDispose(() {
      _fenetre?.cancel();
      _fenetre = null;
      _enAttente = false;
    });
    return const EtatVeilleMessages();
  }

  void _changer({bool? enDirect, FilABouge? dernier}) {
    if (_fenetre == null) {
      state = state.suivant(enDirect: enDirect, dernier: dernier);
      _fenetre = Timer(AppDelais.regroupementMessages, _fermerFenetre);
      return;
    }
    // Dans la fenetre : l'etat se met a jour, le rang attend la fin.
    _enAttente = true;
    state = EtatVeilleMessages(
      rang: state.rang,
      enDirect: enDirect ?? state.enDirect,
      dernier: dernier ?? state.dernier,
    );
  }

  void _fermerFenetre() {
    _fenetre = null;
    if (!_enAttente) return;
    _enAttente = false;
    _changer();
  }

  /// Un fil a bouge.
  void signaler(FilABouge f) => _changer(dernier: f);

  /// Tout est a relire (jointure, retour du reseau, relecture de repli).
  void relire() => _changer();

  /// Le canal est (re)joint : retour au direct.
  void enDirect() => _changer(enDirect: true);

  /// Le canal est tombe.
  ///
  /// PERSONNES-PERF (20/11/2026) : le rang ne monte pas. La chute du canal
  /// n'apporte rien a relire (les ecrans disent seulement « pas en direct ») ;
  /// les relectures viennent du repli et du retour du canal. Un canal qui
  /// tombait en boucle faisait relire a chaque chute.
  void horsDirect() {
    if (!state.enDirect) return;
    state = EtatVeilleMessages(
      rang: state.rang,
      enDirect: false,
      dernier: state.dernier,
    );
  }

  /// PERSONNES-PERF : le canal est rejoint, mais une relecture vient d'etre
  /// faite pour un retour precedent (canal qui se rejoint en boucle) : l'etat
  /// redit « en direct » sans monter le rang. La relecture qui couvre ce retour
  /// est programmee par la veille, a la fin de sa fenetre.
  void enDirectSansRelire() {
    if (state.enDirect) return;
    state = EtatVeilleMessages(
      rang: state.rang,
      enDirect: true,
      dernier: state.dernier,
    );
  }
}

/// La veille des messages. **Montee par `RewayahApp` seulement**, comme la
/// veille de fraicheur : un ecran teste seul n'ouvre aucun canal. Ouverte
/// quand la session porte un profil, fermee quand il disparait ; elle ecrit
/// [etatVeilleMessagesProvider], tient le repli et pose l'avis.
///
/// PERSONNES-PERF (20/11/2026 ; en production, un onglet du bureau laisse
/// ouvert relisait toute la messagerie 90 fois par heure, la nuit, sans aucun
/// geste) :
/// - le repli (canal tombe) est UN minuteur a la fois, rearme apres chaque
///   tic : [AppDelais.repliMessages] quand l'application est vue,
///   [AppDelais.repliMessagesCache] quand elle est cachee ; au retour, une
///   relecture immediate puis le rythme vu ;
/// - un canal qui se rejoint en boucle ne fait relire qu'une fois par
///   [AppDelais.rejointeMessagesMin] (les retours suivants sont reunis en une
///   relecture a la fin de la fenetre : rien n'est perdu) ;
/// - apres [AppDelais.echecsCanalAvantPause] echecs sans retour en direct, la
///   veille ferme le canal et le rouvre apres une attente qui double, de
///   [AppDelais.reouvertureCanalMin] a [AppDelais.reouvertureCanalMax] (et pas
///   avant le retour de l'onglet s'il est cache).
final Provider<void> veilleMessagesProvider = Provider<void>((Ref ref) {
  final String? profil = ref.watch(
    sessionProvider.select((SessionState s) => s.profileId),
  );
  if (profil == null) return;
  final PortVeilleMessages port = ref.watch(portVeilleMessagesProvider);
  final PortVisibilite visibilite = ref.watch(portVisibiliteProvider);
  final EtatVeilleMessagesControleur etat = ref.read(
    etatVeilleMessagesProvider.notifier,
  );
  StreamSubscription<SignalMessages>? abonnement;
  StreamSubscription<bool>? vue;
  Timer? repli;
  Timer? fenetreRejointe;
  Timer? reouverture;
  bool rejointeEnAttente = false;
  bool horsDirect = false;
  bool visible = visibilite.visible;
  bool reouvrirAuRetour = false;
  int echecs = 0;
  Duration attente = AppDelais.reouvertureCanalMin;

  // Un seul minuteur de repli a la fois, rearme apres son tic.
  void armerRepli() {
    repli?.cancel();
    repli = null;
    if (!horsDirect) return;
    repli = Timer(
      visible ? AppDelais.repliMessages : AppDelais.repliMessagesCache,
      () {
        repli = null;
        etat.relire();
        armerRepli();
      },
    );
  }

  late final void Function() ouvrir;

  void rejoint() {
    echecs = 0;
    attente = AppDelais.reouvertureCanalMin;
    horsDirect = false;
    armerRepli();
    if (fenetreRejointe == null) {
      etat.enDirect();
      // A la fin de la fenetre, les retours reunis font UNE relecture, qui
      // rouvre une fenetre : jamais plus d'une relecture par fenetre.
      void fermerFenetre() {
        fenetreRejointe = null;
        if (!rejointeEnAttente) return;
        rejointeEnAttente = false;
        etat.relire();
        fenetreRejointe = Timer(AppDelais.rejointeMessagesMin, fermerFenetre);
      }

      fenetreRejointe = Timer(AppDelais.rejointeMessagesMin, fermerFenetre);
    } else {
      rejointeEnAttente = true;
      etat.enDirectSansRelire();
    }
  }

  void auSignal(SignalMessages signal) {
    switch (signal) {
      case CanalMessagesRejoint():
        rejoint();
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

  void pause() {
    // Le client temps reel retente seul ; au-dela de quelques echecs, la
    // veille ferme le canal et le rouvre plus tard, de plus en plus tard.
    unawaited(abonnement?.cancel());
    abonnement = null;
    echecs = 0;
    final Duration delai = attente;
    final Duration double = attente * 2;
    attente = double > AppDelais.reouvertureCanalMax
        ? AppDelais.reouvertureCanalMax
        : double;
    reouverture?.cancel();
    reouverture = Timer(delai, () {
      reouverture = null;
      if (visible) {
        ouvrir();
      } else {
        reouvrirAuRetour = true;
      }
    });
  }

  void auxErreurs(Object erreur) {
    journalDev('Veille des messages en erreur : ${erreur.runtimeType}');
    if (erreur is! ErreurCanalMessages) return;
    etat.horsDirect();
    if (!horsDirect) {
      horsDirect = true;
      armerRepli();
    }
    echecs += 1;
    if (echecs >= AppDelais.echecsCanalAvantPause) pause();
  }

  ouvrir = () {
    unawaited(abonnement?.cancel());
    abonnement = port.ecouter(profil).listen(auSignal, onError: auxErreurs);
  };

  ouvrir();
  vue = visibilite.changements().listen((bool v) {
    if (v == visible) return;
    visible = v;
    if (!v) {
      armerRepli();
      return;
    }
    if (reouvrirAuRetour) {
      reouvrirAuRetour = false;
      ouvrir();
    }
    if (horsDirect) etat.relire();
    armerRepli();
  });
  ref.onDispose(() {
    repli?.cancel();
    fenetreRejointe?.cancel();
    reouverture?.cancel();
    unawaited(vue?.cancel());
    unawaited(abonnement?.cancel());
  });
  // Au retour du reseau : nouvel abonnement et relecture.
  ref.listen<AsyncValue<bool>>(horsLigneProvider, (
    AsyncValue<bool>? avant,
    AsyncValue<bool> apres,
  ) {
    if ((avant?.value ?? false) && !(apres.value ?? false)) {
      reouverture?.cancel();
      reouverture = null;
      echecs = 0;
      attente = AppDelais.reouvertureCanalMin;
      ouvrir();
      etat.relire();
    }
  });
});
