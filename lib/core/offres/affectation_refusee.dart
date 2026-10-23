/// C11BIS-AFFECTATION (21/10/2026, `CAND-Q15`, lot c11bis) : le refus, par le
/// serveur, de confirmer un enseignant pour une classe en attente.
///
/// Depuis la migration `20261021210100`, `affecter_enseignant_classe_c11bis`
/// delegue a `tc_verifier_affectation_enseignant` : le serveur refuse donc
/// legitimement (piece d'identite, langue, genre, plafond, disponibilites,
/// chevauchement). Ces refus sont un verdict (P0001, 42501 :
/// [estRefusAffectation]), pas une reponse perdue ni une erreur passagere :
/// l'adaptateur les leve en [AffectationRefusee], avec un [motif] ferme, et
/// l'ecran dit une phrase par motif. **Jamais le texte SQL** (« enseignant non
/// disponible: jour %, heure %... » est technique, et en francais meme dans
/// l'interface arabe) ; un motif inconnu donne une phrase generique honnete.
///
/// Hors d'un fichier `port_*.dart` a dessein (`AGENTS.md:43-45`) : le port
/// `PortRegroupementsAdmin` reste inchange, sans ligne Contrats a ouvrir. Un
/// autre adaptateur du meme port peut lever la meme erreur.
library;

import 'package:flutter/foundation.dart';

/// Pourquoi le serveur a refuse la confirmation de l'enseignant.
enum MotifRefusAffectation {
  /// La personne connectee ne peut pas confirmer d'enseignant (SQLSTATE
  /// 42501 : direction inactive, autre role, ou fonction fermee).
  reservee,

  /// La classe n'attend plus d'enseignant (close, ou deja active par un autre
  /// chemin). Une classe deja affectee rend `deja_affecte`, pas ce refus.
  classeIndisponible,

  /// Le compte de l'enseignant, sa piece d'identite, la langue du cours ou son
  /// genre renseigne ne permettent pas cette classe.
  enseignantIndisponible,

  /// Le genre de l'enseignant ne correspond pas au public de la classe.
  genreIncompatible,

  /// La classe depasserait le plafond d'heures par semaine de l'enseignant.
  plafond,

  /// Ses disponibilites ne couvrent pas toutes les occurrences de la classe.
  nonDisponible,

  /// Il a deja une classe active ou un eleve suivi au meme instant.
  chevauchementClasse,

  /// Il a deja une seance ponctuelle au meme instant.
  chevauchementSeance,

  /// Un refus que le client ne connait pas : phrase generique.
  inconnu,
}

/// Le serveur a repondu non a la confirmation d'un enseignant.
@immutable
class AffectationRefusee implements Exception {
  /// Cree le refus.
  const AffectationRefusee(this.motif);

  /// Le motif, ferme. L'ecran le met en mots ; le texte du serveur n'est pas
  /// garde.
  final MotifRefusAffectation motif;

  @override
  String toString() => 'AffectationRefusee(${motif.name})';
}

/// Vrai seulement pour un verdict de `affecter_enseignant_classe_c11bis` :
/// P0001 (ses `RAISE EXCEPTION` et ceux de
/// `tc_verifier_affectation_enseignant`, sans code explicite) et 42501 (sa
/// garde F86, ou l'EXECUTE refuse par PostgREST quand la fonction est fermee).
///
/// Tout autre code n'est **pas** un refus, et l'adaptateur laisse passer
/// l'erreur telle quelle (la feuille dit alors « non confirme », D5) :
/// - un statut HTTP comme code (`'502'`, `'503'`, `'504'`...) : la librairie
///   PostgREST le met quand le corps n'est pas du JSON, page d'une
///   passerelle par exemple ; la transaction a pu aboutir ;
/// - `PGRST*` (jeton expire, schema en cours de rechargement...) ;
/// - 57014 (delai), 40001 (serialisation), 40P01 (interblocage), 55P03
///   (verrou) : la transaction est annulee sans verdict, et le meme choix
///   peut aboutir en pressant de nouveau.
bool estRefusAffectation(String? code) => code == 'P0001' || code == '42501';

/// Les debuts de message leves par `affecter_enseignant_classe_c11bis` et
/// `tc_verifier_affectation_enseignant` (`0082`), avec leur motif. Le prefixe
/// suffit : le message de disponibilite porte des valeurs, et deux messages
/// portent un accent que le serveur ecrit tel quel.
const List<(String, MotifRefusAffectation)> _prefixes =
    <(String, MotifRefusAffectation)>[
      ('classe indisponible', MotifRefusAffectation.classeIndisponible),
      ('enseignant indisponible', MotifRefusAffectation.enseignantIndisponible),
      (
        'enseignant incompatible avec le public',
        MotifRefusAffectation.genreIncompatible,
      ),
      ('plafond horaire enseignant', MotifRefusAffectation.plafond),
      ('enseignant non disponible', MotifRefusAffectation.nonDisponible),
      (
        'chevauchement avec une classe',
        MotifRefusAffectation.chevauchementClasse,
      ),
      ('chevauchement avec une s', MotifRefusAffectation.chevauchementSeance),
    ];

/// Le motif d'un refus serveur, d'apres son SQLSTATE ([code]) et son
/// [message]. Fonction pure : aucune phrase ici, et le message n'est jamais
/// rendu tel quel.
MotifRefusAffectation motifRefusAffectation({
  required String? code,
  required String message,
}) {
  if (code == '42501') return MotifRefusAffectation.reservee;
  final String m = message.trim().toLowerCase();
  for (final (String prefixe, MotifRefusAffectation motif) in _prefixes) {
    if (m.startsWith(prefixe)) return motif;
  }
  return MotifRefusAffectation.inconnu;
}
