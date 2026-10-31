/// IMM-ACCUEIL-FRONT : l'accueil d'une famille deja inscrite, importee par la
/// direction (`DECISION-IMMATRICULATION-2026-10-12.md` §5).
///
/// Le controleur appelle la reclamation **une seule fois par compte**, quand
/// la session est valide et qu'aucun profil n'existe encore (porte
/// `inscription`) : la connexion par lien ou par Google a deja prouve
/// l'adresse, et le serveur le revérifie. Il garde le resultat en memoire le
/// temps de l'accueil, puis redemande un jeton : le profil cree par le serveur
/// y apporte son role et son foyer, et le routeur mene a l'accueil.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controleur.dart';
import '../session/session_state.dart';
import 'port_reclamation_preinscription.dart';

/// Ou en est l'accueil des inscrits pour le compte connecte.
sealed class EtatAccueilInscrits {
  const EtatAccueilInscrits();
}

/// Rien n'est encore demande (ou le compte a deja un profil).
final class AccueilNonDemande extends EtatAccueilInscrits {
  /// Cree l'etat.
  const AccueilNonDemande();
}

/// La reclamation est en cours.
final class AccueilEnCours extends EtatAccueilInscrits {
  /// Cree l'etat.
  const AccueilEnCours();
}

/// Aucune pre-inscription : le parcours habituel, inchange.
final class AccueilSansInscription extends EtatAccueilInscrits {
  /// Cree l'etat.
  const AccueilSansInscription();
}

/// Une pre-inscription a ete reprise ; l'accueil reste a montrer tant que
/// [vu] est faux.
final class AccueilConnu extends EtatAccueilInscrits {
  /// Cree l'etat.
  const AccueilConnu(this.reclamation, {this.vu = false, this.pret = true});

  /// Ce que le serveur a rendu.
  final ReclamationPreinscription reclamation;

  /// Faux le temps de redemander un jeton apres la reprise : l'inscription
  /// n'ouvre alors rien, le routeur va mener a l'accueil.
  final bool pret;

  /// Vrai quand la personne a quitte l'accueil (« Continuer »).
  final bool vu;
}

/// Le serveur a refuse ou rendu une forme inattendue.
final class AccueilEnEchec extends EtatAccueilInscrits {
  /// Cree l'etat.
  const AccueilEnEchec();
}

/// Le serveur n'a pas repondu.
final class AccueilHorsLigne extends EtatAccueilInscrits {
  /// Cree l'etat.
  const AccueilHorsLigne();
}

/// L'etat de l'accueil des inscrits, garde en memoire du processus pour le
/// compte connecte ; oublie quand la personne change.
final NotifierProvider<AccueilInscritsControleur, EtatAccueilInscrits>
accueilInscritsProvider =
    NotifierProvider<AccueilInscritsControleur, EtatAccueilInscrits>(
      AccueilInscritsControleur.new,
    );

/// Vrai tant qu'un accueil des inscrits attend d'etre montre : le routeur y
/// mene le compte qui vient de quitter l'inscription.
final Provider<bool> accueilInscritsEnAttenteProvider = Provider<bool>((
  Ref ref,
) {
  final EtatAccueilInscrits etat = ref.watch(accueilInscritsProvider);
  return etat is AccueilConnu && !etat.vu;
});

/// Pilote la reclamation et l'accueil.
class AccueilInscritsControleur extends Notifier<EtatAccueilInscrits> {
  String? _compte;

  @override
  EtatAccueilInscrits build() {
    // Un autre compte (deconnexion, appareil partage) repart de zero : rien de
    // la famille precedente ne lui reste.
    ref.listen<String?>(
      sessionProvider.select((SessionState s) => s.profileId),
      (String? avant, String? apres) {
        if (avant != apres) {
          _compte = null;
          state = const AccueilNonDemande();
          unawaited(reclamerSiBesoin());
        }
      },
    );
    // La session peut se resoudre apres l'ouverture de l'inscription : la
    // reclamation part des que la porte `inscription` s'ouvre.
    ref.listen<PorteAcces>(
      sessionProvider.select((SessionState s) => s.porte),
      (PorteAcces? _, PorteAcces porte) {
        if (porte == PorteAcces.inscription) {
          unawaited(reclamerSiBesoin());
        }
      },
    );
    return const AccueilNonDemande();
  }

  /// Reclame la pre-inscription si la session le demande : compte connecte,
  /// sans profil, et rien encore demande pour lui. Sans effet sinon.
  Future<void> reclamerSiBesoin() async {
    final SessionState session = ref.read(sessionProvider);
    final String? compte = session.profileId;
    if (session.porte != PorteAcces.inscription || compte == null) {
      return;
    }
    if (!ref.read(portReclamationPreinscriptionProvider).disponible) {
      _compte = compte;
      state = const AccueilSansInscription();
      return;
    }
    // Deja demande pour ce compte : un echec ne repart que sur « Reessayer ».
    if (_compte == compte && state is! AccueilNonDemande) {
      return;
    }
    await _reclamer(compte);
  }

  /// Rejoue la reclamation apres un echec ou une coupure.
  Future<void> reessayer() async {
    final String? compte = ref.read(sessionProvider).profileId;
    if (compte == null || state is AccueilEnCours) {
      return;
    }
    await _reclamer(compte);
  }

  Future<void> _reclamer(String compte) async {
    _compte = compte;
    state = const AccueilEnCours();
    EtatAccueilInscrits suivant;
    try {
      final ReclamationPreinscription r = await ref
          .read(portReclamationPreinscriptionProvider)
          .reclamer();
      suivant = r.connue
          ? AccueilConnu(r, pret: false)
          : const AccueilSansInscription();
    } on ReclamationInjoignable {
      suivant = const AccueilHorsLigne();
    } on Object {
      suivant = const AccueilEnEchec();
    }
    if (!ref.mounted || _compte != compte) {
      return;
    }
    state = suivant;
    if (suivant is AccueilConnu) {
      // Le profil cree par le serveur n'est pas dans le jeton en cours : un
      // nouveau jeton porte son role et son foyer. Un echec laisse la porte
      // `inscription`, ou l'accueil reste lisible.
      try {
        await ref.read(sourceSessionProvider).rafraichir();
      } on Object {
        // Rien : la prochaine lecture de session fera le meme travail.
      }
      final EtatAccueilInscrits apres = state;
      if (ref.mounted && _compte == compte && apres is AccueilConnu) {
        state = AccueilConnu(apres.reclamation, vu: apres.vu);
      }
    }
  }

  /// La personne quitte l'accueil : il ne sera plus montre.
  void marquerVu() {
    final EtatAccueilInscrits etat = state;
    if (etat is AccueilConnu && !etat.vu) {
      state = AccueilConnu(etat.reclamation, vu: true, pret: etat.pret);
    }
  }
}
