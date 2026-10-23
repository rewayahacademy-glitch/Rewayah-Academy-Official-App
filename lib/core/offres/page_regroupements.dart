/// R17 (`DECISION-CLASSES-SIMULTANEES-2026-10-10.md`) : la liste des demandes
/// reunies (regroupements), paginee et filtree.
///
/// **Le contrat attendu du serveur** (ligne Contrats a demander) : une RPC
/// paginee qui rend une page de regroupements filtree (texte, public, etat,
/// jour, heure, fuseau), le total, les compteurs par etat et les valeurs de
/// filtre possibles. Tant qu'il n'existe pas, [portRegroupementsPagesProvider]
/// vaut `null` et [pageRegroupementsAdminProvider] pagine **en memoire** la
/// liste de [PortRegroupementsAdmin.regroupements]. La demonstration
/// surcharge le port avec un grand volume simule.
///
/// L'ecran ne decide d'aucun droit : il lit ce que le port rend.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../tc_bibliotheque/recherche_catalogue.dart';
import 'offre_horaire.dart' show PublicOffre;
import 'port_regroupements_admin.dart';

/// L'etat d'un regroupement dans la liste.
enum EtatRegroupement {
  /// Une classe est creee, son enseignant reste a confirmer.
  aFinir,

  /// Le quota est atteint : la classe peut ouvrir.
  pret,

  /// Le quota n'est pas atteint.
  incomplet,
}

/// L'etat d'un regroupement, deduit de ce que le serveur a rendu.
EtatRegroupement etatDe(RegroupementDemandes g) => g.classe != null
    ? EtatRegroupement.aFinir
    : g.pret
    ? EtatRegroupement.pret
    : EtatRegroupement.incomplet;

/// Le tri de la file : les prets d'abord, puis le plus grand nombre d'eleves ;
/// a egalite le premier jour, l'heure de ce premier jour, l'identifiant.
List<RegroupementDemandes> trierParPret(
  Iterable<RegroupementDemandes> regroupements,
) {
  int premierJour(RegroupementDemandes r) =>
      r.occurrences.isEmpty ? 8 : r.occurrences.first.jourIso;
  int premiereHeure(RegroupementDemandes r) =>
      r.occurrences.isEmpty ? 0 : r.occurrences.first.minutesDuJour;
  return regroupements.toList()
    ..sort((RegroupementDemandes a, RegroupementDemandes b) {
      final int pret = (a.pret ? 0 : 1).compareTo(b.pret ? 0 : 1);
      if (pret != 0) return pret;
      final int nombre = b.nombreEleves.compareTo(a.nombreEleves);
      if (nombre != 0) return nombre;
      final int jour = premierJour(a).compareTo(premierJour(b));
      if (jour != 0) return jour;
      final int heure = premiereHeure(a).compareTo(premiereHeure(b));
      if (heure != 0) return heure;
      return a.id.compareTo(b.id);
    });
}

/// Ce que l'ecran demande. `null` sur un axe veut dire « tous ».
@immutable
class FiltreRegroupements {
  /// Cree un filtre.
  const FiltreRegroupements({
    this.texte = '',
    this.public,
    this.etat,
    this.jour,
    this.heure,
    this.fuseau,
  });

  /// Le texte cherche (jours, langue, fuseau, nom de la classe creee).
  final String texte;

  /// Le public (la categorie).
  final PublicOffre? public;

  /// L'etat.
  final EtatRegroupement? etat;

  /// Le jour ISO (1 = lundi), parmi ceux du regroupement.
  final int? jour;

  /// L'heure pleine de reference, parmi celles du regroupement.
  final int? heure;

  /// Le fuseau IANA de reference.
  final String? fuseau;

  /// Le meme filtre, un axe change. Une fonction par axe rend `null`
  /// possible (« tous »).
  FiltreRegroupements avec({
    String? texte,
    PublicOffre? Function()? public,
    EtatRegroupement? Function()? etat,
    int? Function()? jour,
    int? Function()? heure,
    String? Function()? fuseau,
  }) => FiltreRegroupements(
    texte: texte ?? this.texte,
    public: public == null ? this.public : public(),
    etat: etat == null ? this.etat : etat(),
    jour: jour == null ? this.jour : jour(),
    heure: heure == null ? this.heure : heure(),
    fuseau: fuseau == null ? this.fuseau : fuseau(),
  );

  @override
  bool operator ==(Object other) =>
      other is FiltreRegroupements &&
      other.texte == texte &&
      other.public == public &&
      other.etat == etat &&
      other.jour == jour &&
      other.heure == heure &&
      other.fuseau == fuseau;

  @override
  int get hashCode => Object.hash(texte, public, etat, jour, heure, fuseau);
}

/// Une page de la liste.
@immutable
class PageRegroupements {
  /// Cree une page.
  const PageRegroupements({
    required this.lignes,
    required this.total,
    required this.page,
    required this.taille,
    required this.compteurs,
    required this.jours,
    required this.heures,
    required this.fuseaux,
    required this.totalSansFiltre,
    required this.demandesSansFiltre,
  });

  /// Les regroupements de la page.
  final List<RegroupementDemandes> lignes;

  /// Le nombre de regroupements qui passent le filtre, toutes pages
  /// confondues.
  final int total;

  /// La page, a partir de 1.
  final int page;

  /// Le nombre de regroupements par page.
  final int taille;

  /// Le nombre de regroupements par etat, les autres axes appliques.
  final Map<EtatRegroupement, int> compteurs;

  /// Les jours presents : les entrees du menu de filtre.
  final List<int> jours;

  /// Les heures de reference presentes.
  final List<int> heures;

  /// Les fuseaux de reference presents.
  final List<String> fuseaux;

  /// Le nombre de regroupements sans aucun filtre : 0 veut dire « aucune
  /// demande », pas « aucune avec ce filtre ».
  final int totalSansFiltre;

  /// Le nombre de demandes (eleves) sans aucun filtre.
  final int demandesSansFiltre;

  /// Le nombre de pages (1 au moins).
  int get pages => math.max(1, (total + taille - 1) ~/ taille);

  /// Le rang de la premiere ligne de la page, a partir de 1.
  int get debut => total == 0 ? 0 : (page - 1) * taille + 1;

  /// Le rang de la derniere ligne de la page.
  int get fin => (page - 1) * taille + lignes.length;

  /// Le nombre de regroupements, tous etats confondus, les autres axes
  /// appliques.
  int get toutesEtats =>
      compteurs.values.fold<int>(0, (int somme, int n) => somme + n);
}

/// La page demandee : un filtre, un numero de page, une taille.
@immutable
class RequeteRegroupements {
  /// Cree une requete.
  const RequeteRegroupements({
    this.filtre = const FiltreRegroupements(),
    this.page = 1,
    this.taille = taillePageRegroupements,
  });

  /// Le filtre.
  final FiltreRegroupements filtre;

  /// La page, a partir de 1.
  final int page;

  /// La taille de page.
  final int taille;

  @override
  bool operator ==(Object other) =>
      other is RequeteRegroupements &&
      other.filtre == filtre &&
      other.page == page &&
      other.taille == taille;

  @override
  int get hashCode => Object.hash(filtre, page, taille);
}

/// La taille de page de la liste des regroupements.
const int taillePageRegroupements = 25;

/// Le port de la liste paginee (R17).
abstract interface class PortRegroupementsPages {
  /// La page [page] (a partir de 1) de [taille] regroupements qui passent
  /// [filtre].
  Future<PageRegroupements> page(
    FiltreRegroupements filtre, {
    required int page,
    required int taille,
  });
}

bool _passe(
  RegroupementDemandes g,
  FiltreRegroupements f, {
  bool avecEtat = true,
}) {
  if (f.public != null && g.public != f.public) return false;
  if (avecEtat && f.etat != null && etatDe(g) != f.etat) return false;
  if (f.jour != null && !g.jours.contains(f.jour)) return false;
  if (f.heure != null &&
      !g.occurrences.any((OccurrenceCreneau o) => o.heure == f.heure)) {
    return false;
  }
  if (f.fuseau != null && g.fuseau != f.fuseau) return false;
  final String cherche = RechercheCatalogue.normaliser(f.texte.trim());
  if (cherche.isNotEmpty) {
    final String foin = RechercheCatalogue.normaliser(
      <String?>[
        g.langueNom,
        g.langueCode,
        g.fuseau,
        g.classe?.libelle,
        g.classe?.codeCourt,
      ].whereType<String>().join(' '),
    );
    if (!foin.contains(cherche)) return false;
  }
  return true;
}

/// Pagine [tous] en memoire : filtre, tri (a finir d'abord, puis prets, puis
/// le plus d'eleves), decoupe. Sert au repli sans port et a la demonstration ;
/// le serveur fera le meme travail en SQL (R17).
PageRegroupements paginerRegroupements(
  List<RegroupementDemandes> tous,
  FiltreRegroupements filtre, {
  required int page,
  required int taille,
}) {
  assert(taille > 0, 'une page porte au moins un regroupement');
  final List<RegroupementDemandes> autresAxes = tous
      .where((RegroupementDemandes g) => _passe(g, filtre, avecEtat: false))
      .toList(growable: false);
  final List<RegroupementDemandes> retenus = <RegroupementDemandes>[
    ...trierParPret(
      autresAxes.where(
        (RegroupementDemandes g) =>
            g.classe != null &&
            (filtre.etat == null || filtre.etat == EtatRegroupement.aFinir),
      ),
    ),
    ...trierParPret(
      autresAxes.where(
        (RegroupementDemandes g) =>
            g.classe == null &&
            (filtre.etat == null || etatDe(g) == filtre.etat),
      ),
    ),
  ];
  final int pages = math.max(1, (retenus.length + taille - 1) ~/ taille);
  final int courante = page.clamp(1, pages);
  final int debut = (courante - 1) * taille;
  return PageRegroupements(
    lignes: retenus.sublist(
      math.min(debut, retenus.length),
      math.min(debut + taille, retenus.length),
    ),
    total: retenus.length,
    page: courante,
    taille: taille,
    compteurs: <EtatRegroupement, int>{
      for (final EtatRegroupement e in EtatRegroupement.values)
        e: autresAxes.where((RegroupementDemandes g) => etatDe(g) == e).length,
    },
    jours:
        (tous
                .expand((RegroupementDemandes g) => g.jours)
                .where((int j) => j >= 1 && j <= 7)
                .toSet())
            .toList()
          ..sort(),
    heures:
        tous
            .expand(
              (RegroupementDemandes g) =>
                  g.occurrences.map((OccurrenceCreneau o) => o.heure),
            )
            .toSet()
            .toList()
          ..sort(),
    fuseaux: tous.map((RegroupementDemandes g) => g.fuseau).toSet().toList()
      ..sort(),
    totalSansFiltre: tous.length,
    demandesSansFiltre: tous.fold<int>(
      0,
      (int somme, RegroupementDemandes g) => somme + g.nombreEleves,
    ),
  );
}

/// Le port : absent avant le contrat serveur (repli en memoire).
final Provider<PortRegroupementsPages?> portRegroupementsPagesProvider =
    Provider<PortRegroupementsPages?>((Ref _) => null);

/// La page de regroupements demandee. Sans port de pages : la liste de
/// `regroupementsAdminProvider`, paginee en memoire (une source absente reste
/// absente : [CapaciteIndisponible] remonte telle quelle). Aucune
/// retentative automatique : un echec se relit par « Reessayer ».
final FutureProviderFamily<PageRegroupements, RequeteRegroupements>
pageRegroupementsAdminProvider =
    FutureProvider.family<PageRegroupements, RequeteRegroupements>((
      Ref ref,
      RequeteRegroupements requete,
    ) async {
      final PortRegroupementsPages? port = ref.watch(
        portRegroupementsPagesProvider,
      );
      if (port != null) {
        return port.page(
          requete.filtre,
          page: requete.page,
          taille: requete.taille,
        );
      }
      final List<RegroupementDemandes> tous = await ref.watch(
        regroupementsAdminProvider.future,
      );
      return paginerRegroupements(
        tous,
        requete.filtre,
        page: requete.page,
        taille: requete.taille,
      );
    }, retry: (int _, Object _) => null);
