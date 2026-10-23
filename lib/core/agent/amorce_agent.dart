import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'recharger_adresse.dart';
import 'session_agent.dart';

/// Le nom du parametre d'URL qui porte le jeton d'observation.
const String parametreJetonAgent = 'jeton';

/// Lit le jeton d'observation dans l'adresse de la page.
///
/// **Le jeton ne vit que la ou il arrive.** Il n'est ecrit ni sur le disque, ni
/// dans le stockage du navigateur : fermer l'onglet met fin a l'observation, et
/// rien ne reste derriere sur la machine de l'agent. C'est aussi ce qui rend
/// l'acces impossible a reprendre par un tiers qui ouvrirait le meme navigateur
/// plus tard.
///
/// Hors du Web, `Uri.base` designe le repertoire de travail : la lecture rend
/// alors `null`, ce qui est le comportement voulu. Une observation se fait dans
/// un navigateur (ADR-025), l'application native n'a pas de tunnel d'agent.
String? jetonAgentDeLUrl([Uri? adresse]) {
  final Uri uri = adresse ?? Uri.base;
  final String? brut = uri.queryParameters[parametreJetonAgent];
  if (brut == null) {
    return null;
  }
  final String jeton = brut.trim();
  // Le prefixe est verifie ici pour ne pas envoyer n'importe quel parametre
  // d'URL a la fonction Edge : ce n'est pas une securite, c'est ce qui evite
  // qu'un lien mal colle compte comme une tentative sur un jeton.
  return jeton.startsWith('rag_') ? jeton : null;
}

/// Pourquoi l'entree d'un agent a echoue au demarrage, ou `null`.
///
/// Surcharge par `main()` quand la remise du jeton n'a pas abouti : l'ecran
/// `AGT-00` a besoin de la cause pour dire ce qui s'est passe plutot que de
/// presenter un formulaire vide a quelqu'un qui vient de cliquer sur un lien.
final Provider<EchecAgent?> echecAgentProvider = Provider<EchecAgent?>(
  (Ref ref) => null,
);

/// Relance l'ouverture d'une session d'agent : recharge l'adresse courante,
/// jeton compris, pour que `main()` refasse la remise (EA-HL-DOUBLE-1f).
/// Surchargeable en test.
final Provider<void Function()> relancerOuvertureAgentProvider =
    Provider<void Function()>((Ref ref) => rechargerAdresse);
