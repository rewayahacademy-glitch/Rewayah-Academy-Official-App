// La visibilite des montants sensibles du Comptable (CPT-F, spec §7.2, §7.3 ;
// DR-06 ; R-FIN-01 a 03).
//
// **Un seul etat pour tout l'espace Comptable**, en memoire : masque par
// defaut, revele par `FinanceAmountVisibilityToggle`, **remis a masque a
// chaque nouvelle session** (connexion, deconnexion, changement de compte).
// Jamais ecrit par `PortPreferencesPersistantes`, jamais lu ni ecrit sur le
// serveur (`CPT-BR.md` §3). Les yeux locaux par tuile sont refuses : ils
// creeraient l'etat incoherent que la spec §7.4 interdit.
//
// **Fichier gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`, liste A).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controleur.dart';
import '../session/session_state.dart';

/// L'etat : vrai quand les montants sont affiches, faux quand ils sont
/// masques. **Faux au depart de toute session.**
final NotifierProvider<VisibiliteMontants, bool> visibiliteMontantsProvider =
    NotifierProvider<VisibiliteMontants, bool>(VisibiliteMontants.new);

/// Le controleur de la visibilite.
class VisibiliteMontants extends Notifier<bool> {
  @override
  bool build() {
    // La session change (connexion, deconnexion, autre compte) : ce
    // `build` est rejoue et l'etat repart a « masque » (R-FIN-03). Seule
    // l'identite de la session compte, pas ses details (mode d'interface,
    // lecture de profil), qui ne doivent pas remasquer en pleine lecture.
    ref.watch(sessionProvider.select(_identiteDe));
    return false;
  }

  /// Affiche les montants, pour cette session seulement.
  void afficher() => state = true;

  /// Masque les montants.
  void masquer() => state = false;

  /// Bascule entre affiche et masque.
  void basculer() => state = !state;

  static (bool, String?, String?) _identiteDe(SessionState s) =>
      (s.resolue, s.role?.name, s.profileId);
}
