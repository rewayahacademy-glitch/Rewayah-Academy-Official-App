// HORS-SALLE-2 (directeur, 12/11/2026 au soir) : « Toutes ses sorties de
// l'app doivent etre consignees sur le rapport : leur nombre total, frequence,
// de quand jusqu'a quand. » Regle du 11/11 : rien n'est garde pour un eleve
// mineur sans l'accord d'un tuteur de son foyer
// (`docs/current/salle/DROIT-RELEVE-QUALITE.md`, par. 10 point 3).
//
// Le port du journal des sorties de l'application : noter une sortie, lire le
// journal d'une seance, lire et changer l'accord, lire le delai et l'etat du
// journal (reglages de la direction). Le serveur decide de tout
// (`20261124200000_journal_sorties.sql`) : qui note, qui lit, les heures ; le
// client n'envoie jamais d'heure, seulement la duree mesuree par l'horloge.
//
// **Serveur ancien (fonctions absentes)** : tout se replie sans erreur
// visible. Rien n'est note, la lecture rend une liste vide, l'accord se lit
// « absent » (null) et les ecrans ne montrent pas la section.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../session/session_controleur.dart';
import '../session/session_state.dart';
import 'journal_sorties_demonstration.dart';
import 'journal_sorties_supabase.dart';

/// Les reglages publics du journal, lus dans `regles_academie()`.
@immutable
class ReglagesSorties {
  /// Cree les reglages.
  const ReglagesSorties({required this.journalActif, this.delai});

  /// Lit les cles `sorties_*` de `regles_academie()` ; null quand la reponse
  /// ne les porte pas (serveur d'avant le lot, ou compte hors parcours).
  static ReglagesSorties? depuisRegles(Object? json) {
    if (json is! Map) return null;
    final Object? delai = json['sorties_delai_secondes'];
    final Object? actif = json['sorties_journal_actif'];
    if (delai is! num && actif is! bool) return null;
    return ReglagesSorties(
      journalActif: actif == true,
      delai: delai is num && delai > 0
          ? Duration(seconds: delai.toInt())
          : null,
    );
  }

  /// Vrai quand la direction a allume le journal.
  final bool journalActif;

  /// Le delai hors de l'application avant la sortie de la salle, ou null.
  final Duration? delai;
}

/// L'accord pour un eleve, tel que la page le montre.
@immutable
class AccordSortiesEleve {
  /// Cree l'entree.
  const AccordSortiesEleve({
    required this.eleveId,
    required this.prenom,
    required this.autonome,
    required this.enCours,
    this.accepteLe,
  });

  /// Lit une entree de `accords_sorties()`.
  factory AccordSortiesEleve.depuisJson(Map<String, dynamic> json) =>
      AccordSortiesEleve(
        eleveId: json['eleveId'] as String,
        prenom: (json['prenom'] as String?) ?? '',
        autonome: json['autonome'] == true,
        enCours: json['enCours'] == true,
        accepteLe: switch (json['accepteLe']) {
          final String s => DateTime.tryParse(s),
          _ => null,
        },
      );

  /// L'eleve concerne.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// Vrai pour l'eleve adulte autonome, qui decide pour lui-meme.
  final bool autonome;

  /// Vrai quand un accord vaut aujourd'hui (version en cours, bonne personne).
  final bool enCours;

  /// La date de l'accord en cours.
  final DateTime? accepteLe;
}

/// L'etat des accords de l'appelant.
@immutable
class EtatAccordsSorties {
  /// Cree l'etat.
  const EtatAccordsSorties({
    required this.journalActif,
    required this.versionCourante,
    required this.eleves,
  });

  /// Lit la reponse de `accords_sorties()` (et des deux ecritures).
  factory EtatAccordsSorties.depuisJson(Map<String, dynamic> json) =>
      EtatAccordsSorties(
        journalActif: json['journalActif'] == true,
        versionCourante: json['versionCourante'] as String?,
        eleves: <AccordSortiesEleve>[
          for (final Object? e in (json['eleves'] as List<dynamic>?) ?? const [])
            if (e is Map<String, dynamic>) AccordSortiesEleve.depuisJson(e),
        ],
      );

  /// Vrai quand la direction a allume le journal.
  final bool journalActif;

  /// La version du texte en cours.
  final String? versionCourante;

  /// Une entree par eleve sur lequel l'appelant decide.
  final List<AccordSortiesEleve> eleves;

  /// La page est proposee : journal allume et au moins une decision a prendre.
  /// Tant que la direction n'a pas allume le journal, la page n'annonce pas un
  /// releve qui n'existe pas.
  bool get propose => journalActif && versionCourante != null && eleves.isNotEmpty;

  /// Vrai quand l'appelant decide pour lui-meme (eleve adulte autonome).
  bool get pourSoi => eleves.length == 1 && eleves.single.autonome;
}

/// Pourquoi un accord n'a pas ete enregistre.
enum MotifRefusAccord {
  /// Le texte a change entre la lecture et l'envoi : relire.
  versionPerimee,

  /// La direction a eteint le journal entre-temps.
  journalEteint,
}

/// L'accord n'a pas ete enregistre, pour un motif que le serveur a dit.
class AccordSortiesRefuse implements Exception {
  /// Cree le refus.
  const AccordSortiesRefuse(this.motif);

  /// Le motif.
  final MotifRefusAccord motif;
}

/// Une sortie de l'application, lue dans le journal d'une seance.
@immutable
class SortieApp {
  /// Cree la sortie.
  const SortieApp({
    required this.eleveId,
    required this.prenom,
    required this.sortieLe,
    required this.retourLe,
    required this.dureeSecondes,
    required this.sortieSalle,
  });

  /// Lit une ligne de `sorties_seance()`.
  factory SortieApp.depuisJson(Map<String, dynamic> json) => SortieApp(
    eleveId: json['eleve_id'] as String,
    prenom: (json['prenom'] as String?) ?? '',
    sortieLe: DateTime.parse(json['sortie_le'] as String),
    retourLe: DateTime.parse(json['retour_le'] as String),
    dureeSecondes: (json['duree_secondes'] as num?)?.toInt() ?? 0,
    sortieSalle: json['sortie_salle'] == true,
  );

  /// L'eleve.
  final String eleveId;

  /// Son prenom.
  final String prenom;

  /// L'heure ou il a quitte l'application (posee par le serveur).
  final DateTime sortieLe;

  /// L'heure ou il est revenu (posee par le serveur).
  final DateTime retourLe;

  /// La duree de l'absence, en secondes.
  final int dureeSecondes;

  /// Vrai quand l'absence l'a fait sortir de la salle.
  final bool sortieSalle;
}

/// Le resume des sorties d'un eleve sur une seance : le nombre et la duree
/// totale.
@immutable
class ResumeSorties {
  /// Cree le resume.
  const ResumeSorties({required this.nombre, required this.totalSecondes});

  /// Le resume de chaque eleve, dans l'ordre des lignes.
  static Map<String, ResumeSorties> parEleve(List<SortieApp> sorties) {
    final Map<String, ResumeSorties> resumes = <String, ResumeSorties>{};
    for (final SortieApp s in sorties) {
      final ResumeSorties? avant = resumes[s.eleveId];
      resumes[s.eleveId] = ResumeSorties(
        nombre: (avant?.nombre ?? 0) + 1,
        totalSecondes: (avant?.totalSecondes ?? 0) + s.dureeSecondes,
      );
    }
    return resumes;
  }

  /// Le nombre de sorties.
  final int nombre;

  /// La duree totale, en secondes.
  final int totalSecondes;
}

/// Le journal des sorties de l'application.
abstract interface class PortJournalSorties {
  /// Note une sortie de [secondes] mesuree par l'horloge de l'appareil, au
  /// retour de l'eleve. [eleveId] : l'eleve qui suit la seance depuis
  /// l'appareil de son tuteur (D6), sinon null. Rend vrai quand une ligne est
  /// ecrite ; ne leve jamais : sans accord, journal eteint ou serveur ancien,
  /// rien n'est note et rien ne s'affiche.
  Future<bool> noterSortie({
    required String seanceId,
    required int secondes,
    required bool sortieSalle,
    String? eleveId,
  });

  /// Les sorties d'une seance que l'appelant a le droit de lire (bornees par
  /// le serveur). Liste vide quand rien n'est lisible ou en cas d'echec.
  Future<List<SortieApp>> sortiesSeance(String seanceId);

  /// L'etat des accords de l'appelant ; null quand le serveur ne connait pas
  /// le journal (fonctions absentes) ou refuse ce compte. Une panne de reseau
  /// remonte : la page dit qu'elle n'a pas pu lire.
  Future<EtatAccordsSorties?> accords();

  /// Donne l'accord pour [eleveId] a la [version] affichee. Leve
  /// [AccordSortiesRefuse] sur un refus dit par le serveur.
  Future<EtatAccordsSorties> accepter({
    required String eleveId,
    required String version,
  });

  /// Retire l'accord pour [eleveId] : plus rien n'est note.
  Future<EtatAccordsSorties> retirer(String eleveId);

  /// Les reglages publics (delai, journal allume) ; null quand le serveur ne
  /// les rend pas. Ne leve jamais.
  Future<ReglagesSorties?> reglages();
}

/// Choisit le port selon le mode de compilation : la demonstration ne sort
/// que sous `PLAYGROUND=true`, que le deploiement force a `false`.
PortJournalSorties portJournalSortiesSelon({required bool demo}) => demo
    ? JournalSortiesDemonstration()
    : JournalSortiesSupabase(() => Supabase.instance.client);

/// Le port du journal des sorties employe par l'application.
final Provider<PortJournalSorties> portJournalSortiesProvider =
    Provider<PortJournalSorties>(
      (Ref ref) => portJournalSortiesSelon(demo: Env.playgroundActif),
    );

/// Les reglages publics, relus a chaque changement de compte.
final FutureProvider<ReglagesSorties?> reglagesSortiesProvider =
    FutureProvider<ReglagesSorties?>((Ref ref) {
      ref.watch(sessionProvider.select((SessionState s) => s.profileId));
      return ref.watch(portJournalSortiesProvider).reglages();
    });

/// L'etat des accords de l'appelant (tuteur : ses enfants ; eleve adulte
/// autonome : lui-meme).
final FutureProvider<EtatAccordsSorties?> accordsSortiesProvider =
    FutureProvider<EtatAccordsSorties?>((Ref ref) {
      ref.watch(sessionProvider.select((SessionState s) => s.profileId));
      return ref.watch(portJournalSortiesProvider).accords();
    });

/// Vrai quand la page de l'accord est proposee dans le Compte : une capacite
/// servie (journal allume, au moins une decision), jamais un role.
final Provider<bool> accordSortiesProposeProvider = Provider<bool>(
  (Ref ref) => ref.watch(accordsSortiesProvider).value?.propose ?? false,
);

/// Les sorties lisibles d'une seance.
final FutureProviderFamily<List<SortieApp>, String> sortiesSeanceProvider =
    FutureProvider.family<List<SortieApp>, String>(
      (Ref ref, String seanceId) =>
          ref.watch(portJournalSortiesProvider).sortiesSeance(seanceId),
    );
