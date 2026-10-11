import '../../core/i18n/strings.g.dart';

/// Titre et détail d'une notification serveur, prêts à afficher.
typedef ContenuNotification = ({String titre, String? texte});

/// Les événements que la boîte privée sait afficher (BR-1, B-09). Ils
/// reprennent, un pour un, ceux que l'adaptateur Supabase accepte.
const Set<String> evenementsNotificationAffichables = <String>{
  'demande_recue',
  'classe_validee',
  'enseignant_affecte',
  'demande_close',
  'remplacement_propose',
  'remplacement_pris',
};

/// Résout le libellé localisé d'un [evenement] serveur.
///
/// Les paramètres du serveur (état, début, motif) ne sont jamais recopiés à
/// l'écran : le texte vient de la seule table de traduction, pour qu'un champ
/// libre ne puisse pas devenir un message. Un événement inconnu rend `null` :
/// l'appelant refuse la ligne plutôt que d'afficher une clé brute.
///
/// L'arabe de `notifications.evenements` est à relire par un locuteur natif
/// (passation du 11/10/2026, §4).
ContenuNotification? contenuNotification(Traductions tr, String evenement) {
  final ({String titre, String texte})? paire = switch (evenement) {
    'demande_recue' => (
      titre: tr.notifications.evenements.demandeRecue.titre,
      texte: tr.notifications.evenements.demandeRecue.texte,
    ),
    'classe_validee' => (
      titre: tr.notifications.evenements.classeValidee.titre,
      texte: tr.notifications.evenements.classeValidee.texte,
    ),
    'enseignant_affecte' => (
      titre: tr.notifications.evenements.enseignantAffecte.titre,
      texte: tr.notifications.evenements.enseignantAffecte.texte,
    ),
    'demande_close' => (
      titre: tr.notifications.evenements.demandeClose.titre,
      texte: tr.notifications.evenements.demandeClose.texte,
    ),
    'remplacement_propose' => (
      titre: tr.notifications.evenements.remplacementPropose.titre,
      texte: tr.notifications.evenements.remplacementPropose.texte,
    ),
    'remplacement_pris' => (
      titre: tr.notifications.evenements.remplacementPris.titre,
      texte: tr.notifications.evenements.remplacementPris.texte,
    ),
    _ => null,
  };
  return paire == null ? null : (titre: paire.titre, texte: paire.texte);
}
