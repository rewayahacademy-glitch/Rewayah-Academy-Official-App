// Les lectures et les filtres de W05 (spec §24, §33 ; CPT-BR-07).
//
// Les filtres §33 regroupent les neuf etats §24.1 : « Rembourses » couvre
// le remboursement total et partiel, « Contestes » la contestation et le
// chargeback, « Confirmes » tout ce que le prestataire a confirme (rapproche
// ou non). Le filtre se lit dans `?filtre=` (valeur brute, une inconnue vaut
// « Tous ») ; le comptage par filtre compte des lignes, il n'additionne
// aucun montant (FI6).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../../../core/capacites/port_encaissements.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';

/// Les filtres de la liste des encaissements (spec §33), dans l'ordre
/// d'affichage.
enum FiltreListeEncaissements {
  /// Tous.
  tous(null, <EtatEncaissement>{}),

  /// Confirmes par le prestataire (§24.3), rapproches ou non.
  confirmes('confirmes', <EtatEncaissement>{
    EtatEncaissement.confirme,
    EtatEncaissement.aRapprocher,
    EtatEncaissement.rapproche,
  }),

  /// En attente du prestataire.
  enAttente('attente', <EtatEncaissement>{EtatEncaissement.enAttente}),

  /// Echoues.
  echoues('echoues', <EtatEncaissement>{EtatEncaissement.echoue}),

  /// Rembourses, en totalite ou en partie.
  rembourses('rembourses', <EtatEncaissement>{
    EtatEncaissement.rembourse,
    EtatEncaissement.partiellementRembourse,
  }),

  /// Contestes, chargeback compris.
  contestes('contestes', <EtatEncaissement>{
    EtatEncaissement.conteste,
    EtatEncaissement.chargeback,
  }),

  /// Confirmes, pas encore rapproches.
  aRapprocher('rapprocher', <EtatEncaissement>{EtatEncaissement.aRapprocher});

  const FiltreListeEncaissements(this.valeur, this.etats);

  /// La valeur de `?filtre=` ; nulle pour « Tous ».
  final String? valeur;

  /// Les etats que le filtre retient ; vide pour « Tous ».
  final Set<EtatEncaissement> etats;

  /// Vrai si [etat] passe le filtre.
  bool retient(EtatEncaissement etat) =>
      this == FiltreListeEncaissements.tous || etats.contains(etat);

  /// Le filtre d'une valeur brute d'adresse ; « Tous » si elle est absente
  /// ou inconnue.
  static FiltreListeEncaissements depuis(String? brut) {
    for (final FiltreListeEncaissements f in values) {
      if (f.valeur != null && f.valeur == brut) return f;
    }
    return FiltreListeEncaissements.tous;
  }

  /// Le libelle du filtre.
  String get libelle {
    final e = t.comptable.encaissements;
    return switch (this) {
      FiltreListeEncaissements.tous => e.filtreTous,
      FiltreListeEncaissements.confirmes => e.filtreConfirmes,
      FiltreListeEncaissements.enAttente => e.filtreEnAttente,
      FiltreListeEncaissements.echoues => e.filtreEchoues,
      FiltreListeEncaissements.rembourses => e.filtreRembourses,
      FiltreListeEncaissements.contestes => e.filtreContestes,
      FiltreListeEncaissements.aRapprocher => e.filtreARapprocher,
    };
  }
}

/// Vrai si [e] correspond a la recherche [texte] (famille ou reference),
/// sans tenir compte de la casse.
bool correspondRecherche(Encaissement e, String texte) {
  final String r = texte.trim().toLowerCase();
  return r.isEmpty ||
      e.famille.toLowerCase().contains(r) ||
      e.reference.toLowerCase().contains(r);
}

/// La liste complete, lue une fois ; filtres et recherche s'appliquent a
/// l'affichage. `retry` nul : aucune relance silencieuse derriere
/// « Reessayer ».
final FutureProvider<List<Encaissement>> listeEncaissementsProvider =
    FutureProvider<List<Encaissement>>(
      (Ref ref) =>
          ref.watch(portEncaissementsProvider).liste(FiltreEncaissements.tout),
      retry: (int _, Object _) => null,
    );

/// Le detail d'un encaissement.
final FutureProviderFamily<Encaissement, String> detailEncaissementProvider =
    FutureProvider.family<Encaissement, String>(
      (Ref ref, String id) => ref.watch(portEncaissementsProvider).detail(id),
      retry: (int _, Object _) => null,
    );

/// Le journal d'un encaissement ou d'un remboursement (§48, CPT-BR-17).
final FutureProviderFamily<List<EntreeJournal>, String>
journalEncaissementProvider =
    FutureProvider.family<List<EntreeJournal>, String>(
      (Ref ref, String id) => ref.watch(portEncaissementsProvider).journal(id),
      retry: (int _, Object _) => null,
    );
