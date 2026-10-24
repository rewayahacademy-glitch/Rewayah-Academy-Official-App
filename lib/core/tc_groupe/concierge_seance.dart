// B2.2 bis (b), « le concierge » (plan de nuit du pilote, 24/10/2026) :
// `seance_a_rejoindre(classe)` rend la seance de l'emploi du temps qu'on peut
// rejoindre maintenant, et la cree sans doublon si elle manque (Classe creee
// pendant le cours du jour, horizon de materialisation epuise). Migration
// `20261025010000_seances_concierge.sql`.
//
// « Rejoindre » ne l'appelle que lorsque la seance n'est pas lisible alors
// que la fenetre d'entree est ouverte ; une seance deja connue entre comme
// avant, sans appel.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'concierge_seance_memoire.dart';
import 'concierge_seance_supabase.dart';

/// Pourquoi le serveur refuse de rendre une seance.
enum MotifRefusConcierge {
  /// Ni l'enseignant de la Classe, ni un eleve inscrit, ni la direction
  /// (`SeanceNonAutorisee`, 42501).
  nonAutorise,

  /// Aucune Classe designee (`ClasseInconnue`, 22023).
  classeInconnue,
}

/// Le refus du concierge, jamais avec le texte SQL.
class RefusConcierge implements Exception {
  /// Cree le refus.
  const RefusConcierge(this.motif);

  /// Le motif.
  final MotifRefusConcierge motif;

  @override
  String toString() => 'RefusConcierge(${motif.name})';
}

/// La seance d'une Classe a rejoindre maintenant.
abstract interface class PortConcierge {
  /// L'identifiant de la seance a rejoindre maintenant, creee si elle
  /// manquait. `null` quand la salle n'ouvre pas encore, ou quand la
  /// direction a supprime la seance. Un refus arrive en [RefusConcierge] ;
  /// une panne (reseau) passe telle quelle.
  Future<String?> seanceARejoindre(String groupeId);
}

/// Choisit le port selon le mode de compilation : le double ne sort que sous
/// `PLAYGROUND=true`, et n'y rend aucune seance.
PortConcierge portConciergeSelon({required bool demo}) => demo
    ? ConciergeMemoire()
    : ConciergeSupabase(Supabase.instance.client);

/// Le concierge employe par l'application.
final Provider<PortConcierge> portConciergeProvider = Provider<PortConcierge>(
  (Ref ref) => portConciergeSelon(demo: Env.playgroundActif),
);

/// La phrase dite sous « Rejoindre » apres un appui qui n'a pas pu entrer,
/// par Classe. Effacee au prochain appui.
class RefusEntreeControleur extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const <String, String>{};

  /// Retient [phrase] pour [groupeId].
  void retenir(String groupeId, String phrase) =>
      state = <String, String>{...state, groupeId: phrase};

  /// Efface la phrase de [groupeId].
  void oublier(String groupeId) {
    if (!state.containsKey(groupeId)) return;
    state = <String, String>{...state}..remove(groupeId);
  }
}

/// Les phrases de refus d'entree, par Classe.
final NotifierProvider<RefusEntreeControleur, Map<String, String>>
refusEntreeProvider =
    NotifierProvider<RefusEntreeControleur, Map<String, String>>(
      RefusEntreeControleur.new,
    );
