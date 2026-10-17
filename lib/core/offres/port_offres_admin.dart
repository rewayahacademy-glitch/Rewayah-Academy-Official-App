/// L-05 : le port d'administration des offres vitrine (creer, publier,
/// retirer).
///
/// Decision du directeur du 09/10/2026 (`DECISION-OFFRES-GROUPES-2026-10-09.md`
/// §1) : seule l'administration publie une offre, et la vitrine se compose
/// d'offres **sans enseignant**. Ce port ne porte donc aucun champ enseignant,
/// aucun nombre d'inscrits : ce que la famille ne voit pas, l'ecran
/// d'administration des offres ne l'invente pas.
///
/// Ce que le serveur tient, et que Flutter ne decide jamais (migration
/// `0043`, RPC `creer_offre_horaire`, `publier_offre_horaire`,
/// `retirer_offre_horaire`) :
///
/// - **l'administration seule** : les trois RPC refusent tout autre compte ;
/// - **le nombre de jours** : l'academie annonce `groupe.seances_par_semaine`
///   seances par semaine, le serveur refuse un autre nombre ;
/// - **l'immuabilite** : une offre publiee ne se modifie pas, elle se retire ;
///   un retrait demande un motif ;
/// - **l'unicite** : deux offres vivantes identiques sont refusees.
///
/// Les jours sont des jours ISO (1 lundi ... 7 dimanche) ; l'heure locale est
/// une **heure pleine de 0 a 23** (`smallint` avec `check between 0 and 23`),
/// dans le fuseau IANA de l'offre.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offre_horaire.dart' show LangueCours, PublicOffre, ReglesAcademie;
import 'offres_admin_demo.dart';

/// Ou en est une offre (miroir de `offres_horaires.etat`).
enum EtatOffreAdmin {
  /// Creee, pas encore visible des familles.
  brouillon('brouillon'),

  /// Visible dans la vitrine.
  publiee('publiee'),

  /// Retiree de la vitrine, avec un motif.
  retiree('retiree');

  const EtatOffreAdmin(this.valeurSql);

  /// La valeur telle que la base la connait.
  final String valeurSql;

  /// Lit un etat. Se replie sur [brouillon], le seul etat qui n'expose rien
  /// aux familles : un etat illisible ne doit jamais passer pour publie.
  static EtatOffreAdmin depuisSql(String? valeur) =>
      EtatOffreAdmin.values
          .where((EtatOffreAdmin e) => e.valeurSql == valeur)
          .firstOrNull ??
      EtatOffreAdmin.brouillon;
}

/// Une offre vitrine, telle que l'administration la voit.
///
/// Le modele de la famille ([OffreHoraire]) ne porte ni l'etat ni le motif de
/// retrait, et il est lu dans le fuseau de la famille : l'administration lit
/// l'offre dans **son fuseau d'origine**, avec son etat.
@immutable
class OffreAdmin {
  /// Cree une offre.
  const OffreAdmin({
    required this.id,
    required this.public,
    required this.langueCode,
    required this.langueNom,
    required this.fuseauIana,
    required this.jours,
    required this.heureLocale,
    required this.dureeMinutes,
    required this.etat,
    this.motifRetrait,
  });

  /// L'identifiant. Jamais affiche.
  final String id;

  /// Le public.
  final PublicOffre public;

  /// Le code de la langue du cours.
  final String langueCode;

  /// Le nom de la langue, rendu par le serveur.
  final String langueNom;

  /// Le fuseau IANA de l'offre.
  final String fuseauIana;

  /// Les jours ISO (1 lundi ... 7 dimanche), tries.
  final List<int> jours;

  /// L'heure locale pleine (0 a 23) dans [fuseauIana].
  final int heureLocale;

  /// La duree d'une seance, en minutes.
  final int dureeMinutes;

  /// L'etat.
  final EtatOffreAdmin etat;

  /// Le motif du retrait, quand l'offre est retiree.
  final String? motifRetrait;
}

/// Une demande que le serveur a refusee, avec une phrase lisible.
///
/// L'adaptateur traduit les `raise exception` de `0043` ; l'ecran affiche
/// [message] tel quel (K-59 : le refus est dit, jamais avale).
class OffreAdminRefusee implements Exception {
  /// Cree un refus.
  const OffreAdminRefusee(this.message);

  /// La phrase affichable.
  final String message;

  @override
  String toString() => 'OffreAdminRefusee($message)';
}

/// Ce que le formulaire de creation doit connaitre et que le serveur tient :
/// les langues de cours actives et les regles de l'academie (nombre de
/// seances par semaine, durees). Aucune n'est ecrite dans un widget.
@immutable
class ReglesCreationOffre {
  /// Cree le jeu de regles.
  const ReglesCreationOffre({required this.langues, required this.regles});

  /// Les langues d'enseignement actives, dans l'ordre publie.
  final List<LangueCours> langues;

  /// Les regles de l'academie, lues dans `app_config`.
  final ReglesAcademie regles;

  /// La duree par defaut d'une seance du [public], celle du serveur.
  int dureeParDefaut(PublicOffre public) => public == PublicOffre.adultes
      ? regles.dureeMinutesAdulte
      : regles.dureeMinutesEnfant;
}

/// Le port d'administration des offres.
abstract interface class PortOffresAdmin {
  /// Les langues et les regles qui bornent le formulaire de creation.
  Future<ReglesCreationOffre> reglesCreation();

  /// Toutes les offres (brouillon, publiee, retiree), publiees d'abord, puis
  /// par heure.
  Future<List<OffreAdmin>> lister();

  /// Cree une offre en brouillon et rend son identifiant.
  ///
  /// [jours] : jours ISO (1 lundi ... 7 dimanche), comme le serveur.
  /// [heureLocale] : heure pleine de 0 a 23. [dureeMinutes] nul : le serveur
  /// applique la duree de l'academie pour ce public.
  Future<String> creer({
    required String typePublic,
    required String langueCode,
    required String fuseauIana,
    required List<int> jours,
    required int heureLocale,
    int? dureeMinutes,
  });

  /// Publie un brouillon.
  Future<void> publier(String offreId);

  /// Retire une offre de la vitrine. [motif] est obligatoire.
  Future<void> retirer(String offreId, {required String motif});
}

/// Le port. Par defaut le double de demonstration ; l'application reelle le
/// remplace par l'adaptateur Supabase (`lib/main.dart`).
final Provider<PortOffresAdmin> portOffresAdminProvider =
    Provider<PortOffresAdmin>((Ref ref) => OffresAdminDemo());

/// Les offres, relues par `ref.invalidate` apres chaque changement confirme.
final FutureProvider<List<OffreAdmin>> offresAdminProvider =
    FutureProvider<List<OffreAdmin>>(
      (Ref ref) => ref.watch(portOffresAdminProvider).lister(),
      retry: (int _, Object _) => null,
    );

/// Les langues et les regles du formulaire de creation.
final FutureProvider<ReglesCreationOffre> reglesCreationOffreProvider =
    FutureProvider<ReglesCreationOffre>(
      (Ref ref) => ref.watch(portOffresAdminProvider).reglesCreation(),
      retry: (int _, Object _) => null,
    );
