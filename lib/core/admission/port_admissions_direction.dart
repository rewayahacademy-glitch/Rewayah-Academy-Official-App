// Admission, lot C (decision du directeur du 27/10/2026, §3 et §4 ; fiche
// docs/current/FICHE-ADMISSION-LOT-C-2026-10-30.md) : les demandes des
// familles et des eleves adultes, telles que la direction les traite. Le
// serveur decide de tout (migration 20261030140000) : chaque geste est une
// regle serveur avec motif, auteur et journal, et son e-mail part par la file.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admissions_direction_supabase.dart';

/// Les deux populations des admissions.
enum PopulationAdmission {
  /// Un tuteur qui inscrit un ou plusieurs enfants.
  famille('famille'),

  /// Une personne de 18 ans ou plus, pour elle-meme.
  eleveAdulte('eleve_adulte');

  const PopulationAdmission(this.valeurSql);

  /// La valeur serveur (`candidature_types.code`).
  final String valeurSql;
}

/// Ou en est une demande.
enum EtatDemandeAdmission {
  /// Recue, a traiter.
  aTraiter,

  /// Des precisions ont ete demandees.
  aCompleter,

  /// Acceptee : le compte est ouvert.
  acceptee,

  /// Refusee.
  refusee,

  /// Retiree par la personne.
  retiree,
}

/// Un apprenant d'une demande.
class ApprenantAdmission {
  /// Cree un apprenant.
  const ApprenantAdmission({
    required this.prenom,
    required this.titulaire,
    this.age,
    this.genre,
    this.niveau,
    this.objectif,
    this.moments = const <String>[],
    this.langue,
  });

  /// Lit une ligne du serveur.
  factory ApprenantAdmission.depuisJson(Map<String, dynamic> j) =>
      ApprenantAdmission(
        prenom: j['prenom'] as String? ?? '',
        titulaire: j['estTitulaire'] == true,
        age: (j['age'] as num?)?.toInt(),
        genre: j['genre'] as String?,
        niveau: j['niveau'] as String?,
        objectif: j['objectif'] as String?,
        moments: <String>[
          if (j['moments'] is List<dynamic>)
            for (final Object? m in j['moments'] as List<dynamic>)
              if (m is String) m,
        ],
        langue: j['langue'] as String?,
      );

  /// Le prenom (celui du compte pour le titulaire).
  final String prenom;

  /// Vrai pour le titulaire lui-meme.
  final bool titulaire;

  /// L'age d'un enfant.
  final int? age;

  /// `male` ou `female`.
  final String? genre;

  /// Le niveau declare (code de `NiveauDeclare`).
  final String? niveau;

  /// L'objectif (code de `ObjectifApprentissage`).
  final String? objectif;

  /// Les moments de la journee (`matin`, `apres_midi`, `soir`).
  final List<String> moments;

  /// La langue du cours (code de `langues_cours`).
  final String? langue;
}

/// Une demande d'admission, vue par la direction.
class DemandeAdmission {
  /// Cree une demande.
  const DemandeAdmission({
    required this.id,
    required this.reference,
    required this.nom,
    required this.recueLe,
    required this.etat,
    required this.version,
    this.courriel,
    this.derniereActivite,
    this.apprenants = const <ApprenantAdmission>[],
  });

  /// Lit une ligne du serveur.
  factory DemandeAdmission.depuisJson(Map<String, dynamic> j) {
    final String issue = j['issue'] as String? ?? 'en_cours';
    final String etape = j['etape'] as String? ?? 'recue';
    return DemandeAdmission(
      id: j['id'] as String,
      reference: j['reference'] as String? ?? '',
      nom: j['nom'] as String? ?? '',
      courriel: j['courriel'] as String?,
      recueLe:
          DateTime.tryParse(j['recueLe'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      derniereActivite: DateTime.tryParse(
        j['derniereActivite'] as String? ?? '',
      )?.toLocal(),
      version: (j['version'] as num?)?.toInt() ?? 0,
      etat: switch ((issue, etape, j['etat'])) {
        ('refusee', _, _) => EtatDemandeAdmission.refusee,
        ('retiree', _, _) => EtatDemandeAdmission.retiree,
        (_, 'confirmee', _) => EtatDemandeAdmission.acceptee,
        (_, _, 'a_completer') => EtatDemandeAdmission.aCompleter,
        _ => EtatDemandeAdmission.aTraiter,
      },
      apprenants: <ApprenantAdmission>[
        if (j['apprenants'] is List<dynamic>)
          for (final Object? a in j['apprenants'] as List<dynamic>)
            if (a is Map<String, dynamic>) ApprenantAdmission.depuisJson(a),
      ],
    );
  }

  /// L'identifiant de la demande.
  final String id;

  /// La reference `CAND-…`.
  final String reference;

  /// Le nom du titulaire.
  final String nom;

  /// Son adresse e-mail, quand elle est connue.
  final String? courriel;

  /// La date de reception.
  final DateTime recueLe;

  /// La derniere activite (le refus, pour le delai d'annulation).
  final DateTime? derniereActivite;

  /// Ou en est la demande.
  final EtatDemandeAdmission etat;

  /// La version attendue par le prochain geste.
  final int version;

  /// Les apprenants de la demande.
  final List<ApprenantAdmission> apprenants;

  /// Vrai quand une acceptation s'annule encore (sept jours ; le serveur
  /// compte depuis l'acceptation et refuse si un enfant est en classe).
  bool acceptationAnnulableA(DateTime maintenant) =>
      etat == EtatDemandeAdmission.acceptee &&
      derniereActivite != null &&
      maintenant.difference(derniereActivite!).inDays < 7;

  /// Vrai quand un refus s'annule encore (sept jours, regle serveur).
  bool refusAnnulableA(DateTime maintenant) =>
      etat == EtatDemandeAdmission.refusee &&
      derniereActivite != null &&
      maintenant.difference(derniereActivite!).inDays < 7;
}

/// Une page d'une liste.
class PageAdmissions {
  /// Cree la page.
  const PageAdmissions({
    required this.lignes,
    required this.total,
    required this.aTraiter,
    required this.page,
    required this.parPage,
  });

  /// Les demandes de la page.
  final List<DemandeAdmission> lignes;

  /// Le nombre de demandes de la liste (recherche comprise).
  final int total;

  /// Les demandes a traiter de la population.
  final int aTraiter;

  /// La page lue, a partir de 1.
  final int page;

  /// Le nombre de demandes par page.
  final int parPage;
}

/// Pourquoi le serveur n'a pas fait le geste (refus rendu, jamais le SQL).
enum RefusGesteAdmission {
  /// Une autre personne de la direction a traite la demande entre-temps.
  dejaTraitee,

  /// Le geste ne vaut pas dans l'etat de la demande (ou le delai est passe).
  transitionInterdite,

  /// Un motif est exige.
  motifRequis,

  /// L'adresse e-mail de la personne n'est pas connue.
  adresseInconnue,

  /// Un enfant de la demande est deja dans une classe.
  enfantEnClasse,

  /// Un autre refus.
  autre,
}

/// Un refus du serveur.
class GesteAdmissionRefuse implements Exception {
  /// Cree le refus.
  const GesteAdmissionRefuse(this.raison);

  /// La raison.
  final RefusGesteAdmission raison;

  @override
  String toString() => 'GesteAdmissionRefuse(${raison.name})';
}

/// Les demandes d'admission, cote direction.
abstract interface class PortAdmissionsDirection {
  /// Une page de la liste de [population], recherche facultative.
  Future<PageAdmissions> lister(
    PopulationAdmission population, {
    String? recherche,
    int page = 1,
  });

  /// Accepte la demande ; le compte s'ouvre et l'e-mail part.
  Future<void> accepter(DemandeAdmission d, {required String cle});

  /// Refuse avec un motif interne et un modele de message pour la personne.
  Future<void> refuser(
    DemandeAdmission d, {
    required String motif,
    required String modele,
    required String cle,
  });

  /// Annule un refus de moins de sept jours.
  Future<void> annulerRefus(
    DemandeAdmission d, {
    required String motif,
    required String cle,
  });

  /// Annule une acceptation de moins de sept jours : le compte repasse en
  /// attente, les profils des enfants sont mis de cote.
  Future<void> annulerAcceptation(
    DemandeAdmission d, {
    required String motif,
    required String cle,
  });

  /// Demande des precisions ; le message part par e-mail.
  Future<void> demanderPrecisions(
    DemandeAdmission d, {
    required String message,
    required String cle,
  });

  /// Ecrit a la personne, sans changer la demande.
  Future<void> contacter(
    DemandeAdmission d, {
    required String sujet,
    required String message,
    required String cle,
  });
}

/// Le port employe par l'application.
final Provider<PortAdmissionsDirection> portAdmissionsDirectionProvider =
    Provider<PortAdmissionsDirection>(
      (Ref ref) => AdmissionsDirectionSupabase(Supabase.instance.client),
    );
