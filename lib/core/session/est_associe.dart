// BE-2b : « la personne connectee est-elle un associe ? », lu sans jamais
// echouer. Un ecran qui s'adapte a l'associe (la page des candidatures) peut
// etre monte sans session (outil, test, galerie) : l'absence de session se lit
// « non », jamais comme une erreur. Le serveur reste la seule barriere.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import 'session_controleur.dart';
import 'session_state.dart';

/// Vrai quand la session connue porte le role `associe`.
final Provider<bool> estAssocieProvider = Provider<bool>((Ref ref) {
  try {
    return ref.watch(
      sessionProvider.select((SessionState s) => s.role == AppRole.associe),
    );
  } on Object {
    return false;
  }
});
