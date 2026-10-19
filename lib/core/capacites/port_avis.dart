// Les avis des familles et des eleves (DECISION-AVIS-2026-10-19, migration
// 20261019120000) : le formulaire public, sans compte, et la moderation par la
// direction.
//
// Le serveur decide de tout : si un lien est ouvert, quels champs sont valides,
// qui peut moderer. Flutter envoie et affiche ; il ne calcule ni validite de
// lien ni droit. Le jeton d'un lien n'est montre qu'une fois, a la creation, et
// n'est jamais range.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// Ou en est un avis.
enum StatutAvis {
  /// Depose, la direction ne l'a pas encore lu.
  enAttente('en_attente'),

  /// Publie sur le site.
  publie('publie'),

  /// Refuse avant publication, avec un motif.
  refuse('refuse'),

  /// Publie puis retire, avec un motif.
  retire('retire');

  const StatutAvis(this.sql);

  /// La valeur cote serveur.
  final String sql;

  /// Le statut de la valeur serveur, ou `null` si elle est inconnue.
  static StatutAvis? depuisSql(String? v) {
    for (final StatutAvis s in values) {
      if (s.sql == v) return s;
    }
    return null;
  }
}

/// Qui parle.
enum QualiteAvis {
  /// Parent ou tuteur d'un eleve.
  parent('parent'),

  /// Eleve adulte.
  eleveAdulte('eleve_adulte');

  const QualiteAvis(this.sql);

  /// La valeur cote serveur.
  final String sql;

  /// La qualite de la valeur serveur, ou `null` si elle est inconnue.
  static QualiteAvis? depuisSql(String? v) {
    for (final QualiteAvis q in values) {
      if (q.sql == v) return q;
    }
    return null;
  }
}

/// Les champs que le serveur sait refuser (`22023`, message = nom du champ).
enum ChampAvis {
  /// Le nom affiche.
  nom,

  /// La qualite.
  qualite,

  /// Le pays.
  pays,

  /// Le mois et l'annee d'arrivee.
  depuis,

  /// La note.
  note,

  /// Le titre.
  titre,

  /// Le texte de l'avis.
  texte,

  /// L'accord de publication.
  accord;

  /// Le champ nomme par le serveur (`p_nom`, `nom_affiche`, `nom`...), ou
  /// `null` s'il est inconnu.
  static ChampAvis? depuisServeur(String? message) {
    final String m = (message ?? '').trim().toLowerCase().replaceFirst(
      RegExp('^p_'),
      '',
    );
    return switch (m) {
      'nom' || 'nom_affiche' => nom,
      'qualite' => qualite,
      'pays' => pays,
      'depuis' => depuis,
      'note' => note,
      'titre' => titre,
      'texte' => texte,
      'accord' || 'accord_public' => accord,
      _ => null,
    };
  }
}

/// Le serveur refuse un champ du formulaire (`22023`).
class ChampAvisInvalide implements Exception {
  /// Cree l'erreur. [champ] est `null` quand le serveur ne le nomme pas.
  const ChampAvisInvalide(this.champ);

  /// Le champ refuse, s'il est connu.
  final ChampAvis? champ;

  @override
  String toString() => 'ChampAvisInvalide($champ)';
}

/// Le lien est ferme, expire ou plein (`P0002`).
class LienAvisFerme implements Exception {
  /// Cree l'erreur.
  const LienAvisFerme();

  @override
  String toString() => 'LienAvisFerme()';
}

/// Le serveur refuse la moderation : l'avis n'existe plus, n'est plus dans
/// l'etat attendu, ou le motif manque.
enum RefusModeration {
  /// L'avis n'existe plus (`P0002`).
  introuvable,

  /// L'avis n'est plus dans l'etat d'ou ce geste part (`55000`).
  etatChange,

  /// Le motif manque (`22023`).
  motifManquant,
}

/// La moderation est refusee pour une raison metier.
class ModerationAvisRefusee implements Exception {
  /// Cree l'erreur.
  const ModerationAvisRefusee(this.raison);

  /// Pourquoi.
  final RefusModeration raison;

  @override
  String toString() => 'ModerationAvisRefusee($raison)';
}

/// Ce qu'une personne envoie depuis le formulaire public.
@immutable
class DepotAvis {
  /// Cree un depot.
  const DepotAvis({
    required this.nom,
    required this.qualite,
    required this.pays,
    required this.depuis,
    required this.note,
    required this.texte,
    required this.accord,
    this.titre,
  });

  /// Le nom affiche (2 a 60 caracteres).
  final String nom;

  /// Parent ou tuteur, ou eleve adulte.
  final QualiteAvis qualite;

  /// Le code ISO 3166-1 alpha-2 du pays de residence.
  final String pays;

  /// Le premier jour du mois d'arrivee a l'academie.
  final DateTime depuis;

  /// De 1 a 5.
  final int note;

  /// Le titre, facultatif (80 caracteres au plus).
  final String? titre;

  /// Le texte (20 a 1500 caracteres).
  final String texte;

  /// L'accord de publication (nom affiche, pays, date), obligatoire.
  final bool accord;
}

/// Un lien de collecte, vu de la direction. Le jeton n'y figure jamais : le
/// serveur n'en garde que l'empreinte.
@immutable
class LienAvis {
  /// Cree un lien.
  const LienAvis({
    required this.id,
    required this.libelle,
    required this.creeLe,
    required this.expireLe,
    required this.avisMax,
    required this.avisRecus,
    required this.ferme,
    required this.actif,
  });

  /// L'identifiant.
  final String id;

  /// Le nom donne par la direction.
  final String libelle;

  /// La creation.
  final DateTime creeLe;

  /// La fin de validite.
  final DateTime expireLe;

  /// Le nombre maximal d'avis.
  final int avisMax;

  /// Les avis recus.
  final int avisRecus;

  /// Vrai quand la direction l'a ferme.
  final bool ferme;

  /// Vrai quand le serveur dit le lien ouvert (ni ferme, ni expire, ni plein).
  final bool actif;
}

/// La reponse a la creation d'un lien : le seul moment ou le jeton existe en
/// clair.
@immutable
class LienAvisCree {
  /// Cree la reponse.
  const LienAvisCree({
    required this.id,
    required this.jeton,
    required this.expireLe,
  });

  /// L'identifiant du lien.
  final String id;

  /// Le jeton, en clair, une seule fois.
  final String jeton;

  /// La fin de validite.
  final DateTime expireLe;
}

/// Un avis, vu de la direction. Le texte n'est jamais modifie.
@immutable
class AvisAdmin {
  /// Cree un avis.
  const AvisAdmin({
    required this.id,
    required this.nomAffiche,
    required this.qualite,
    required this.pays,
    required this.depuis,
    required this.note,
    required this.texte,
    required this.statut,
    required this.deposeLe,
    this.lienLibelle,
    this.titre,
    this.accordPublicLe,
    this.motif,
    this.modereLe,
    this.publieLe,
  });

  /// L'identifiant.
  final String id;

  /// Le nom du lien par lequel il est arrive.
  final String? lienLibelle;

  /// Le nom affiche.
  final String nomAffiche;

  /// Qui parle.
  final QualiteAvis qualite;

  /// Le code ISO du pays.
  final String pays;

  /// Le premier jour du mois d'arrivee.
  final DateTime depuis;

  /// De 1 a 5.
  final int note;

  /// Le titre, s'il y en a un.
  final String? titre;

  /// Le texte, tel que la personne l'a ecrit.
  final String texte;

  /// Le moment de l'accord de publication.
  final DateTime? accordPublicLe;

  /// Le statut.
  final StatutAvis statut;

  /// Le motif d'un refus ou d'un retrait.
  final String? motif;

  /// Le depot.
  final DateTime deposeLe;

  /// La derniere decision.
  final DateTime? modereLe;

  /// La publication.
  final DateTime? publieLe;
}

/// Les avis (contrat de la migration 20261019120000).
abstract interface class PortAvis {
  /// Vrai quand le lien de [jeton] accepte encore des avis (`avis_lien_etat`).
  /// Ne dit rien d'autre.
  Future<bool> lienOuvert(String jeton);

  /// Depose un avis (`avis_deposer`). [ChampAvisInvalide] si le serveur refuse
  /// un champ, [LienAvisFerme] si le lien est ferme, expire ou plein.
  Future<void> deposer(String jeton, DepotAvis avis);

  /// Cree un lien (`avis_lien_creer`). Le jeton n'est rendu qu'ici.
  Future<LienAvisCree> creerLien({
    required String libelle,
    required int jours,
    required int avisMax,
  });

  /// Les liens, le plus recent d'abord (`avis_liens_lister`).
  Future<List<LienAvis>> listerLiens();

  /// Ferme le lien [id] (`avis_lien_fermer`).
  Future<void> fermerLien(String id);

  /// Les avis, filtres par [statut] si donne (`avis_lister_admin`).
  Future<List<AvisAdmin>> listerAvis({StatutAvis? statut});

  /// Publie, refuse ou retire l'avis [id] (`avis_moderer`). Le motif est
  /// obligatoire pour `refuse` et `retire`. [ModerationAvisRefusee] si le
  /// serveur refuse.
  Future<void> moderer(String id, StatutAvis statut, {String? motif});
}

/// Tant qu'aucun adaptateur serveur n'est branche : les ecrans disent que la
/// fonction est indisponible.
class AvisIndisponibles implements PortAvis {
  /// Cree l'implementation.
  const AvisIndisponibles();

  static const CapaciteIndisponible _absente = CapaciteIndisponible(
    'AVIS-PUBLICS',
  );

  @override
  Future<bool> lienOuvert(String jeton) => Future<bool>.error(_absente);

  @override
  Future<void> deposer(String jeton, DepotAvis avis) =>
      Future<void>.error(_absente);

  @override
  Future<LienAvisCree> creerLien({
    required String libelle,
    required int jours,
    required int avisMax,
  }) => Future<LienAvisCree>.error(_absente);

  @override
  Future<List<LienAvis>> listerLiens() =>
      Future<List<LienAvis>>.error(_absente);

  @override
  Future<void> fermerLien(String id) => Future<void>.error(_absente);

  @override
  Future<List<AvisAdmin>> listerAvis({StatutAvis? statut}) =>
      Future<List<AvisAdmin>>.error(_absente);

  @override
  Future<void> moderer(String id, StatutAvis statut, {String? motif}) =>
      Future<void>.error(_absente);
}

/// Le port des avis.
final Provider<PortAvis> portAvisProvider = Provider<PortAvis>(
  (Ref ref) => const AvisIndisponibles(),
);
