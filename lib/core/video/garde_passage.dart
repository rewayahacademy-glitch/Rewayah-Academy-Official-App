// SALLE-SECOND-APPAREIL (directeur, 23/11/2026) : le battement suit la
// CONNEXION video vivante, jamais la page de la salle.
//
// Quand la salle est reduite dans l'ile (ou que l'on est sur un autre ecran),
// le premier appareil est toujours dans la classe : il garde sa place, et il
// recoit la question « Laisser passer ? » par-dessus l'ecran ouvert. Le battement
// s'arrete seulement quand la connexion se termine vraiment (hors de la salle,
// echec, sortie, expulsion). Meme regle pour l'observateur tuteur : il entre par
// le meme moteur.
//
// Le moteur de salle (`moteurSalleProvider`) possede la connexion LiveKit ; ce
// garde l'ecoute. Il est monte une fois, a la racine de l'application.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/billet_salle.dart';
import '../session/session_controleur.dart' show sessionProvider;
import '../tc_classe/session_persistante.dart';
import 'appareil_salle.dart';
import 'libelle_appareil.dart';
import 'livekit_session_provider.dart' show moteurSalleProvider;
import 'second_appareil.dart';
import 'service_video.dart' show serviceVideoProvider;
import 'video_session_provider.dart';

/// Le rythme du battement : assez court pour qu'une demande apparaisse « presque
/// tout de suite », assez long pour ne rien charger. Le serveur tient un
/// appareil pour silencieux apres 30 secondes.
const Duration rythmeBattementSalle = Duration(seconds: 5);

/// Le rythme employe (reglable dans un test).
final Provider<Duration> rythmeBattementProvider = Provider<Duration>(
  (Ref _) => rythmeBattementSalle,
);

/// Ce que le garde sait et dit.
@immutable
class EtatGardePassage {
  /// Cree l'etat.
  const EtatGardePassage({
    this.demande,
    this.enCours = false,
    this.echec = false,
    this.cedeSeance,
  });

  /// Une demande d'un autre appareil, a traiter.
  final DemandePassage? demande;

  /// La reponse part : les boutons attendent.
  final bool enCours;

  /// La reponse n'a pas pu partir : on le dit, on peut reessayer.
  final bool echec;

  /// La seance que cet appareil vient de ceder (sortie propre faite).
  final String? cedeSeance;

  /// Copie.
  EtatGardePassage copieAvec({
    Object? demande = _inchange,
    bool? enCours,
    bool? echec,
    Object? cedeSeance = _inchange,
  }) => EtatGardePassage(
    demande: identical(demande, _inchange)
        ? this.demande
        : demande as DemandePassage?,
    enCours: enCours ?? this.enCours,
    echec: echec ?? this.echec,
    cedeSeance: identical(cedeSeance, _inchange)
        ? this.cedeSeance
        : cedeSeance as String?,
  );

  static const Object _inchange = Object();
}

/// Le garde de la place du profil dans la classe.
class GardePassage extends Notifier<EtatGardePassage> {
  Timer? _minuteur;
  bool _cedeEnCours = false;

  @override
  EtatGardePassage build() {
    final VideoSessionProvider moteur = ref.watch(moteurSalleProvider);
    final StreamSubscription<EtatSalle> abonnement = moteur.etats.listen(
      _suivre,
    );
    ref.onDispose(() {
      unawaited(abonnement.cancel());
      _minuteur?.cancel();
    });
    // L'etat deja en cours au montage (la salle peut etre ouverte avant).
    Future<void>.microtask(() => _suivre(moteur.etatCourant));
    return const EtatGardePassage();
  }

  /// La connexion est vivante : elle tient la place, meme reconnectee ou
  /// degradee. Tout le reste est une fin (ou pas encore un debut).
  static bool _vivante(EtatSalle etat) => switch (etat) {
    EtatSalle.connecte ||
    EtatSalle.instable ||
    EtatSalle.reconnexion ||
    EtatSalle.retabli => true,
    _ => false,
  };

  void _suivre(EtatSalle etat) {
    if (_vivante(etat)) {
      if (_minuteur == null && !_cedeEnCours) {
        unawaited(_battre());
        _minuteur = Timer.periodic(
          ref.read(rythmeBattementProvider),
          (_) => unawaited(_battre()),
        );
      }
    } else {
      _minuteur?.cancel();
      _minuteur = null;
      if (state.demande != null || state.enCours || state.echec) {
        state = state.copieAvec(demande: null, enCours: false, echec: false);
      }
    }
  }

  Future<void> _battre() async {
    final VideoSessionProvider moteur = ref.read(moteurSalleProvider);
    final AccesSalle? acces = moteur.accesCourant;
    final String? seance = acces?.seanceId;
    final String? profil =
        acces?.eleveId ?? ref.read(sessionProvider).profileId;
    if (seance == null || profil == null || _cedeEnCours) return;
    try {
      final BattementSalle b = await ref
          .read(portSecondAppareilProvider)
          .battement(
            seanceId: seance,
            profilId: profil,
            appareilId: identifiantAppareilSalle(),
            libelle: libelleAppareilCourant(),
          );
      if (_minuteur == null && !_vivante(moteur.etatCourant)) return;
      if (b.cede) {
        await _ceder(seance);
        return;
      }
      if (b.demande != state.demande) {
        state = state.copieAvec(
          demande: b.demande,
          echec: b.demande == null ? false : state.echec,
        );
      }
    } on Object {
      // Un battement perdu n'est pas une coupure : le serveur ne tient un
      // appareil pour silencieux qu'apres 30 secondes, le suivant rattrape.
    }
  }

  /// Cet appareil cede la place : sortie propre (annonce, deconnexion, la barre
  /// se ferme), puis il le dit.
  Future<void> _ceder(String seance) async {
    if (_cedeEnCours) return;
    _cedeEnCours = true;
    _minuteur?.cancel();
    _minuteur = null;
    state = state.copieAvec(demande: null, enCours: false, echec: false);
    try {
      RepriseSalle.oublier();
      final ControleurSessionPersistante controleur = ref.read(
        controleurSessionProvider,
      );
      final VideoSessionProvider moteur = ref.read(moteurSalleProvider);
      if (controleur.pilote(moteur) && controleur.tient(seance)) {
        await controleur.quitter();
      } else {
        await ref.read(serviceVideoProvider).annoncerSortie(seance);
        await moteur.quitter();
      }
    } finally {
      _cedeEnCours = false;
    }
    state = state.copieAvec(cedeSeance: seance);
  }

  /// Le premier appareil accepte ou refuse la demande en cours.
  Future<void> repondre({required bool accepter}) async {
    final DemandePassage? d = state.demande;
    final AccesSalle? acces = ref.read(moteurSalleProvider).accesCourant;
    final String? seance = acces?.seanceId;
    if (d == null || state.enCours || seance == null) return;
    state = state.copieAvec(enCours: true, echec: false);
    try {
      await ref
          .read(portSecondAppareilProvider)
          .repondre(d.id, accepter: accepter);
      state = state.copieAvec(enCours: false, demande: null);
      if (accepter) await _ceder(seance);
    } on Object {
      state = state.copieAvec(enCours: false, echec: true);
    }
  }

  /// Le message de sortie a ete vu : on l'oublie.
  void acquitterCession() => state = state.copieAvec(cedeSeance: null);
}

/// Le garde, monte a la racine de l'application.
final NotifierProvider<GardePassage, EtatGardePassage> gardePassageProvider =
    NotifierProvider<GardePassage, EtatGardePassage>(GardePassage.new);
