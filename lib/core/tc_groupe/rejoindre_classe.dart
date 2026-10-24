import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../accessibilite/signaler_manque.dart';
import '../i18n/strings.g.dart';
import 'concierge_seance.dart';

/// Ce que fait « Rejoindre » d'une Classe.
///
/// [sessionId] connu : [entrer] tout de suite, aucun appel serveur (rien ne
/// change). Inconnu alors que la fenetre d'entree est ouverte : le concierge
/// (`seance_a_rejoindre`) rend la seance, creee si elle manquait, puis
/// [entrer] avec elle. Sans seance rendue, ou refus : ce qui manque et quoi
/// faire (K-59, « … Revenez 20 minutes avant l'heure du cours. ») ; panne :
/// la phrase existante de la seance illisible. La phrase est retenue par Classe
/// ([refusEntreeProvider]), dite sous le bouton par l'hote et annoncee ; le
/// bouton reste actif, un nouvel appui redemande.
Future<void> rejoindreClasse(
  BuildContext contexte, {
  required String groupeId,
  required String? sessionId,
  required void Function(String sessionId) entrer,
}) async {
  final ProviderContainer conteneur = ProviderScope.containerOf(
    contexte,
    listen: false,
  );
  final RefusEntreeControleur refus = conteneur.read(
    refusEntreeProvider.notifier,
  )..oublier(groupeId);
  if (sessionId != null) {
    entrer(sessionId);
    return;
  }
  String phrase;
  try {
    final String? rendue = await conteneur
        .read(portConciergeProvider)
        .seanceARejoindre(groupeId);
    if (rendue != null) {
      if (contexte.mounted) entrer(rendue);
      return;
    }
    phrase = t.classe.entree.revenirAvant;
  } on RefusConcierge {
    phrase = t.classe.entree.revenirAvant;
  } on Object {
    phrase = t.classe.entree.indisponible;
  }
  refus.retenir(groupeId, phrase);
  if (contexte.mounted) signalerManque(contexte, phrase);
}
