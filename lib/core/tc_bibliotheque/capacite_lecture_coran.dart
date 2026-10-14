import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_controleur.dart';
import '../session/session_state.dart';

/// La capacite « lire le Coran dans le lecteur dedie » (BIBLIO-LECTURE) : un
/// eleve, ou un adulte eleve autonome (compte tuteur dont le serveur sert la
/// capacite `SessionState.eleveAutonome`, C-24). Un tuteur seul, un
/// enseignant, un controleur ou l'administration ne l'ont pas.
///
/// Un widget lit cette capacite, jamais `AppRole`. Une session illisible vaut
/// « sans capacite » : on ferme, on n'ouvre rien.
final Provider<bool> capaciteLectureCoranProvider = Provider<bool>((Ref ref) {
  try {
    return ref.watch(
      sessionProvider.select((SessionState s) => s.peutLireLeCoran),
    );
  } on Object {
    return false;
  }
});
