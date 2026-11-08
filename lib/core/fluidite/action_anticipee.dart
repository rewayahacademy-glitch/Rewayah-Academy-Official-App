// FLUIDITE-1 : l'outil « afficher d'avance, revenir en arriere si echec »
// (`docs/current/DECISION-FLUIDITE-2026-11-07.md` §1 et §3).
//
// UN SEUL OUTIL, dans `lib/core`, pour toutes les actions INSTANTANEES : un
// ecran n'invente pas sa propre mecanique d'affichage anticipe.
//
// Ce que fait l'outil :
// - l'ecran montre le resultat tout de suite (etat [EtatAnticipe.enCours]) ;
// - l'action part vers le serveur avec une cle d'idempotence FIXE, la meme a
//   chaque essai : un nouvel essai ne peut pas faire deux fois la chose ;
// - reponse : [EtatAnticipe.confirme] ;
// - echec : [EtatAnticipe.echec], et « Reessayer » rejoue la meme cle.
//   Precision du garde-cap (07/11) : un CONTENU saisi (un message) reste
//   visible en echec, avec « Reessayer », et le texte n'est jamais perdu ; un
//   ETAT (coche, lu, reglage) revient en arriere : c'est le role de
//   [ActionAnticipee.annuler].
//
// Ce que l'outil ne fait JAMAIS :
// - decider. Le serveur reste seul juge (`00`, invariants) : une action
//   instantanee est seulement AFFICHEE d'avance, jamais decidee dans Flutter ;
// - porter une action SENSIBLE. Payer, recharger, rembourser ; se connecter,
//   s'inscrire, un code ou une invitation ; creer un compte ou un profil ;
//   supprimer, retirer, cloturer ; tout changement de role ou de droit : ces
//   actions attendent la reponse du serveur, avec une belle attente
//   (`ActionPrincipale.enCours`). L'outil ne s'emploie que sur appel
//   explicite, qui declare [NatureAction.instantanee] ; une action declaree
//   [NatureAction.sensible] est refusee des la construction. En cas de doute,
//   l'action est sensible (decision, §1).

import 'package:flutter/foundation.dart';

/// La famille d'une action (decision FLUIDITE §1).
enum NatureAction {
  /// Affichee d'avance, revient en arriere si le serveur refuse : un message,
  /// marquer comme lu, cocher, un reglage, un filtre, un onglet.
  instantanee,

  /// Attend le serveur, avec une belle attente : l'argent, le compte, les
  /// droits, une suppression. **Refusee par [ActionAnticipee].**
  sensible,
}

/// L'etat d'une action affichee d'avance.
enum EtatAnticipe {
  /// Affichee, le serveur n'a pas encore repondu.
  enCours,

  /// Le serveur a repondu.
  confirme,

  /// Le serveur a refuse ou n'a pas repondu : « Reessayer » est propose.
  echec,
}

/// Une action instantanee, affichee d'avance (FLUIDITE-1).
///
/// L'ecran cree l'action, l'affiche aussitot dans l'etat [etat], puis appelle
/// [tenter]. Il ecoute l'action (`ChangeNotifier`) pour se redessiner a chaque
/// changement d'etat, et propose « Reessayer » ([tenter] a nouveau) tant que
/// l'etat est [EtatAnticipe.echec]. La meme [cle] part a chaque essai.
class ActionAnticipee extends ChangeNotifier {
  /// Cree l'action, deja affichee ([EtatAnticipe.enCours]).
  ///
  /// [nature] doit valoir [NatureAction.instantanee] : une action sensible
  /// leve une [ArgumentError] (elle attend le serveur, elle ne s'affiche pas
  /// d'avance).
  ActionAnticipee({
    required NatureAction nature,
    required this.cle,
    required this.envoi,
    this.annuler,
  }) {
    if (nature != NatureAction.instantanee) {
      throw ArgumentError.value(
        nature,
        'nature',
        'une action sensible attend la reponse du serveur ; elle ne '
            's\'affiche jamais d\'avance (DECISION-FLUIDITE §1)',
      );
    }
  }

  /// La cle d'idempotence, fixe pour toute la vie de l'action : chaque essai
  /// la rejoue.
  final String cle;

  /// L'appel au serveur, sous [cle]. Un retour normal confirme ; une erreur,
  /// quelle qu'elle soit, est un echec.
  final Future<void> Function(String cle) envoi;

  /// Remet l'etat d'avant, a chaque echec, pour une action qui change un
  /// ETAT (coche, lu, reglage). Nul pour un CONTENU saisi, qui reste visible
  /// en echec avec « Reessayer ».
  final VoidCallback? annuler;

  EtatAnticipe _etat = EtatAnticipe.enCours;
  bool _enVol = false;
  bool _liberee = false;

  /// L'etat a afficher.
  EtatAnticipe get etat => _etat;

  /// Envoie l'action (premier essai ou « Reessayer »), sous la meme [cle].
  ///
  /// Rend vrai si le serveur a confirme. Un essai deja en vol n'en lance pas
  /// un second (un double appui ne fait qu'un envoi) : il rend faux tout de
  /// suite, sans rien changer.
  ///
  /// [siConfirme] et [siEchec] s'executent a l'issue de CET essai, avant que
  /// l'etat ne change a l'ecran, meme si l'ecran a ete quitte entre-temps :
  /// c'est la place d'un effet de bord qui ne doit pas dependre de l'ecran
  /// (le brouillon d'un message, par exemple).
  Future<bool> tenter({VoidCallback? siConfirme, VoidCallback? siEchec}) async {
    if (_enVol) return false;
    _enVol = true;
    _changer(EtatAnticipe.enCours);
    try {
      await envoi(cle);
    } on Object {
      _enVol = false;
      annuler?.call();
      siEchec?.call();
      _changer(EtatAnticipe.echec);
      return false;
    }
    _enVol = false;
    siConfirme?.call();
    _changer(EtatAnticipe.confirme);
    return true;
  }

  void _changer(EtatAnticipe etat) {
    _etat = etat;
    // L'ecran a pu partir pendant l'envoi : l'action est alors liberee, et
    // personne n'ecoute plus.
    if (!_liberee) notifyListeners();
  }

  @override
  void dispose() {
    _liberee = true;
    super.dispose();
  }
}
