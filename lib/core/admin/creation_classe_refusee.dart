/// CAND-Q15, lot creer_groupe (21/10/2026) : le refus, par le serveur, de
/// creer une classe avec l'enseignant choisi.
///
/// Depuis la migration `20261021210200`, `creer_groupe` passe par le predicat
/// d'affectation (piece d'identite validee, date d'acces, profil enseignant,
/// genre connu, plafond hebdomadaire, collisions ; pas la couverture par les
/// disponibilites, decision du directeur). Le serveur refuse donc
/// legitimement : ces refus sont une reponse, et l'ecran dit une phrase par
/// motif. **Jamais le texte SQL** : « plafond horaire enseignant dépassé » est
/// technique, et en francais meme dans l'interface arabe. Un motif inconnu
/// donne une phrase generique honnete.
///
/// Hors d'un fichier `port_*.dart` a dessein (`AGENTS.md`, contrat commun) :
/// `PortCreationClasse` et `ServiceGroupes` gardent leur signature ; seul
/// l'adaptateur Supabase traduit l'erreur.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// Pourquoi le serveur a refuse de creer la classe.
enum MotifRefusCreationClasse {
  /// La personne connectee ne peut pas creer de classe (garde de la
  /// direction active, ou SQLSTATE 42501).
  reservee,

  /// Le compte de l'enseignant n'existe plus, n'est pas un compte
  /// d'enseignant ou n'est pas actif.
  compteEnseignant,

  /// Piece d'identite non validee, acces termine, profil d'enseignant absent
  /// ou supprime, ou genre non renseigne.
  enseignantNonEligible,

  /// Le genre de l'enseignant ne correspond pas au public de la classe.
  genreIncompatible,

  /// La classe depasserait le plafond d'heures par semaine de l'enseignant.
  plafond,

  /// L'enseignant a deja une classe active ou un eleve suivi au meme instant.
  chevauchementClasse,

  /// L'enseignant a deja une seance ponctuelle au meme instant.
  chevauchementSeance,

  /// Un refus que le client ne connait pas : phrase generique.
  inconnu,
}

/// Le serveur a repondu non a la creation d'une classe.
@immutable
class CreationClasseRefusee implements Exception {
  /// Cree le refus.
  const CreationClasseRefusee(this.motif);

  /// Le motif, ferme. L'ecran le met en mots ; le texte du serveur n'est pas
  /// garde.
  final MotifRefusCreationClasse motif;

  @override
  String toString() => 'CreationClasseRefusee(${motif.name})';
}

/// Les debuts des messages leves par `creer_groupe` et par le predicat
/// d'affectation (`0082`, repris par `20261021210200`), avec leur motif. Le
/// prefixe suffit, et deux messages portent un accent que le serveur ecrit
/// tel quel : on compare sans eux.
const List<(String, MotifRefusCreationClasse)>
_prefixes = <(String, MotifRefusCreationClasse)>[
  ('creation de groupe reservee', MotifRefusCreationClasse.reservee),
  ('cet enseignant n', MotifRefusCreationClasse.compteEnseignant),
  ('enseignant indisponible', MotifRefusCreationClasse.enseignantNonEligible),
  (
    'enseignant incompatible avec le public',
    MotifRefusCreationClasse.genreIncompatible,
  ),
  ('plafond horaire enseignant', MotifRefusCreationClasse.plafond),
  (
    'chevauchement avec une classe',
    MotifRefusCreationClasse.chevauchementClasse,
  ),
  ('chevauchement avec une s', MotifRefusCreationClasse.chevauchementSeance),
];

/// Le motif d'un refus serveur, d'apres son SQLSTATE ([code]) et son
/// [message]. Fonction pure : aucune phrase ici, et le message n'est jamais
/// rendu tel quel.
MotifRefusCreationClasse motifRefusCreationClasse({
  required String? code,
  required String message,
}) {
  if (code == '42501') return MotifRefusCreationClasse.reservee;
  final String m = message.trim().toLowerCase();
  for (final (String prefixe, MotifRefusCreationClasse motif) in _prefixes) {
    if (m.startsWith(prefixe)) return motif;
  }
  return MotifRefusCreationClasse.inconnu;
}

/// Lance [appel] et traduit un refus du serveur (`PostgrestException`) en
/// [CreationClasseRefusee]. Toute autre erreur (reseau, format) passe telle
/// quelle : ce n'est pas un refus, l'ecran la dit comme avant.
Future<T> traduireRefusCreationClasse<T>(Future<T> Function() appel) async {
  try {
    return await appel();
  } on PostgrestException catch (e) {
    throw CreationClasseRefusee(
      motifRefusCreationClasse(code: e.code, message: e.message),
    );
  }
}
