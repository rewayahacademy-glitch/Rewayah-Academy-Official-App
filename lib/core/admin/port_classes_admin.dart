/// R16, R17 (`DECISION-CLASSES-SIMULTANEES-2026-10-10.md`) : la liste des
/// classes de la direction, paginee et filtree, ou chaque classe se nomme
/// sans ambiguite parmi ses classes paralleles.
///
/// **Le contrat attendu du serveur** (ligne Contrats a demander) : une RPC
/// paginee qui rend une page de classes filtree (texte, public, etat, jour,
/// heure, fuseau, genre, enseignant ou « sans enseignant »), le total, les
/// compteurs par etat et les valeurs de filtre possibles, et pour chaque
/// classe son numero dans sa famille de classes paralleles (ou un code
/// court), son genre et son enseignant eventuellement absent (R7).
///
/// Tant que ce contrat n'existe pas, [portClassesAdminProvider] vaut `null`
/// et [pageClassesAdminProvider] pagine **en memoire** la liste deja lue par
/// `groupes_admin()` ([groupesProvider]) : meme ecran, memes filtres, sans
/// numero (le nom reste discrimine par le titre de l'enseignant). La
/// demonstration surcharge le port avec un grand volume simule.
///
/// L'ecran ne decide d'aucun droit : il lit ce que le port rend.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../capacites/port_enseignants_classe.dart' show GenreClasse;
import '../classes/nom_classe_distinct.dart';
import '../tc_bibliotheque/recherche_catalogue.dart';
import 'service_groupes.dart';

/// L'etat d'une classe dans la liste.
enum EtatClasseListee {
  /// Active, avec son enseignant.
  active,

  /// Active, mais sans enseignant libre (R7) : « en attente d'enseignant ».
  attenteEnseignant,

  /// Cloturee.
  cloturee,
}

/// Le remplissage d'une classe (R17) : pleine, ou avec des places.
enum RemplissageClasse {
  /// Le plafond est atteint.
  pleine,

  /// Il reste au moins une place.
  avecPlaces,
}

/// Une ligne de la liste des classes.
@immutable
class ClasseListee {
  /// Cree une ligne.
  const ClasseListee({
    required this.groupe,
    this.numeroDansFamille,
    this.codeCourt,
    this.genre,
    this.sansEnseignant = false,
  });

  /// Une ligne lue de `groupes_admin()` : ni numero, ni code, ni genre ; une
  /// classe sans identifiant d'enseignant est « sans enseignant ».
  factory ClasseListee.depuisGroupe(GroupeAdmin groupe) =>
      ClasseListee(groupe: groupe, sansEnseignant: groupe.teacherId.isEmpty);

  /// La classe, telle que les feuilles d'action la connaissent.
  final GroupeAdmin groupe;

  /// R16 : le numero de la classe parmi les classes paralleles de meme cle,
  /// attribue par le serveur.
  final int? numeroDansFamille;

  /// R16 : un code court attribue par le serveur, a defaut de numero.
  final String? codeCourt;

  /// Le genre de la classe. Nul : non rendu.
  final GenreClasse? genre;

  /// Vrai quand aucun enseignant n'est affecte (R7).
  final bool sansEnseignant;

  /// L'identifiant de la classe.
  String get id => groupe.id;

  /// Le remplissage : l'effectif contre le plafond de la classe.
  RemplissageClasse get remplissage =>
      groupe.seuilMax > 0 && groupe.nombreMembres >= groupe.seuilMax
      ? RemplissageClasse.pleine
      : RemplissageClasse.avecPlaces;

  /// L'etat, deduit de ce que le serveur a rendu.
  EtatClasseListee get etat => !groupe.actif
      ? EtatClasseListee.cloturee
      : sansEnseignant
      ? EtatClasseListee.attenteEnseignant
      : EtatClasseListee.active;

  /// L'enseignant affiche, ou nul quand il n'y en a pas.
  String? get enseignant => sansEnseignant ? null : groupe.teacherLibelle;

  /// Le fuseau de la classe.
  String get fuseau => groupe.creneau.fuseau;

  /// Le nom sans ambiguite (R16) : le numero dans la famille de classes,
  /// sinon le code court. Sans l'un ni l'autre, le nom seul : l'enseignant
  /// (ou « Sans enseignant ») a sa propre colonne, qui sert alors de
  /// discriminant sans etre repete dans le nom.
  String get nom => nomClasseDistinct(
    groupe.libelle,
    numero: numeroDansFamille,
    code: codeCourt,
  );
}

/// Un enseignant proposable dans le filtre.
typedef EnseignantFiltre = ({String id, String libelle});

/// Ce que l'ecran demande. `null` sur un axe veut dire « tous ».
@immutable
class FiltreClasses {
  /// Cree un filtre.
  const FiltreClasses({
    this.texte = '',
    this.type,
    this.etat,
    this.jour,
    this.heure,
    this.fuseau,
    this.genre,
    this.enseignantId,
    this.remplissage,
  });

  /// L'identifiant d'enseignant qui designe les classes sans enseignant.
  static const String sansEnseignant = '';

  /// Le texte cherche (nom, numero, code, enseignant).
  final String texte;

  /// Le public.
  final TypePublicGroupe? type;

  /// L'etat.
  final EtatClasseListee? etat;

  /// Le jour ISO (1 = lundi).
  final int? jour;

  /// L'heure locale pleine.
  final int? heure;

  /// Le fuseau IANA.
  final String? fuseau;

  /// Le genre.
  final GenreClasse? genre;

  /// L'enseignant, ou [sansEnseignant].
  final String? enseignantId;

  /// Le remplissage (R17).
  final RemplissageClasse? remplissage;

  /// Le meme filtre, un axe change. Une fonction par axe rend `null`
  /// possible (« tous »).
  FiltreClasses avec({
    String? texte,
    TypePublicGroupe? Function()? type,
    EtatClasseListee? Function()? etat,
    int? Function()? jour,
    int? Function()? heure,
    String? Function()? fuseau,
    GenreClasse? Function()? genre,
    String? Function()? enseignantId,
    RemplissageClasse? Function()? remplissage,
  }) => FiltreClasses(
    texte: texte ?? this.texte,
    type: type == null ? this.type : type(),
    etat: etat == null ? this.etat : etat(),
    jour: jour == null ? this.jour : jour(),
    heure: heure == null ? this.heure : heure(),
    fuseau: fuseau == null ? this.fuseau : fuseau(),
    genre: genre == null ? this.genre : genre(),
    enseignantId: enseignantId == null ? this.enseignantId : enseignantId(),
    remplissage: remplissage == null ? this.remplissage : remplissage(),
  );

  @override
  bool operator ==(Object other) =>
      other is FiltreClasses &&
      other.texte == texte &&
      other.type == type &&
      other.etat == etat &&
      other.jour == jour &&
      other.heure == heure &&
      other.fuseau == fuseau &&
      other.genre == genre &&
      other.enseignantId == enseignantId &&
      other.remplissage == remplissage;

  @override
  int get hashCode => Object.hash(
    texte,
    type,
    etat,
    jour,
    heure,
    fuseau,
    genre,
    enseignantId,
    remplissage,
  );
}

/// Une page de la liste.
@immutable
class PageClasses {
  /// Cree une page.
  const PageClasses({
    required this.lignes,
    required this.total,
    required this.page,
    required this.taille,
    required this.compteurs,
    required this.jours,
    required this.heures,
    required this.fuseaux,
    required this.enseignants,
    required this.genres,
    required this.totalSansFiltre,
  });

  /// Les classes de la page.
  final List<ClasseListee> lignes;

  /// Le nombre de classes qui passent le filtre, toutes pages confondues.
  final int total;

  /// La page, a partir de 1.
  final int page;

  /// Le nombre de classes par page.
  final int taille;

  /// Le nombre de classes par etat, les autres axes du filtre appliques.
  final Map<EtatClasseListee, int> compteurs;

  /// Les jours, heures, fuseaux, enseignants et genres presents : les
  /// entrees des menus de filtre.
  final List<int> jours;

  /// Les heures presentes.
  final List<int> heures;

  /// Les fuseaux presents.
  final List<String> fuseaux;

  /// Les enseignants presents (sans les classes sans enseignant).
  final List<EnseignantFiltre> enseignants;

  /// Les genres presents.
  final List<GenreClasse> genres;

  /// Le nombre de classes sans aucun filtre : 0 veut dire « aucune classe
  /// creee », pas « aucune avec ce filtre ».
  final int totalSansFiltre;

  /// Le nombre de pages (1 au moins).
  int get pages => math.max(1, (total + taille - 1) ~/ taille);

  /// Le rang de la premiere ligne de la page, a partir de 1.
  int get debut => total == 0 ? 0 : (page - 1) * taille + 1;

  /// Le rang de la derniere ligne de la page.
  int get fin => (page - 1) * taille + lignes.length;

  /// Le nombre de classes, tous etats confondus, les autres axes appliques.
  int get toutesEtats =>
      compteurs.values.fold<int>(0, (int somme, int n) => somme + n);
}

/// La page demandee : un filtre, un numero de page, une taille.
@immutable
class RequeteClasses {
  /// Cree une requete.
  const RequeteClasses({
    this.filtre = const FiltreClasses(),
    this.page = 1,
    this.taille = taillePageClasses,
  });

  /// Le filtre.
  final FiltreClasses filtre;

  /// La page, a partir de 1.
  final int page;

  /// La taille de page.
  final int taille;

  @override
  bool operator ==(Object other) =>
      other is RequeteClasses &&
      other.filtre == filtre &&
      other.page == page &&
      other.taille == taille;

  @override
  int get hashCode => Object.hash(filtre, page, taille);
}

/// La taille de page de la liste des classes.
const int taillePageClasses = 25;

/// Le port de la liste paginee (R17).
abstract interface class PortClassesAdmin {
  /// La page [page] (a partir de 1) de [taille] classes qui passent
  /// [filtre].
  Future<PageClasses> page(
    FiltreClasses filtre, {
    required int page,
    required int taille,
  });
}

bool _passe(ClasseListee c, FiltreClasses f, {bool avecEtat = true}) {
  final GroupeAdmin g = c.groupe;
  if (f.type != null && g.type != f.type) return false;
  if (avecEtat && f.etat != null && c.etat != f.etat) return false;
  if (f.jour != null && g.creneau.jour != f.jour) return false;
  if (f.heure != null && g.creneau.heure != f.heure) return false;
  if (f.fuseau != null && c.fuseau != f.fuseau) return false;
  if (f.genre != null && c.genre != f.genre) return false;
  if (f.remplissage != null && c.remplissage != f.remplissage) return false;
  if (f.enseignantId case final String id) {
    if (id == FiltreClasses.sansEnseignant) {
      if (!c.sansEnseignant) return false;
    } else if (c.sansEnseignant || g.teacherId != id) {
      return false;
    }
  }
  final String cherche = RechercheCatalogue.normaliser(f.texte.trim());
  if (cherche.isNotEmpty) {
    final String foin = RechercheCatalogue.normaliser(
      <String?>[
        c.nom,
        g.libelle,
        c.codeCourt,
        c.enseignant,
        if (c.numeroDansFamille case final int n) '$n',
      ].whereType<String>().join(' '),
    );
    if (!foin.contains(cherche)) return false;
  }
  return true;
}

/// Pagine [toutes] en memoire : filtre, tri stable (nom de base, numero,
/// identifiant), decoupe. Sert au repli sans port et a la demonstration ;
/// le serveur fera le meme travail en SQL (R17).
PageClasses paginerClasses(
  List<ClasseListee> toutes,
  FiltreClasses filtre, {
  required int page,
  required int taille,
}) {
  assert(taille > 0, 'une page porte au moins une classe');
  final List<ClasseListee> autresAxes = toutes
      .where((ClasseListee c) => _passe(c, filtre, avecEtat: false))
      .toList(growable: false);
  final List<ClasseListee> retenues =
      autresAxes
          .where(
            (ClasseListee c) => filtre.etat == null || c.etat == filtre.etat,
          )
          .toList()
        ..sort((ClasseListee a, ClasseListee b) {
          final int nom = a.groupe.libelle.compareTo(b.groupe.libelle);
          if (nom != 0) return nom;
          final int numero = (a.numeroDansFamille ?? 0).compareTo(
            b.numeroDansFamille ?? 0,
          );
          if (numero != 0) return numero;
          return a.id.compareTo(b.id);
        });
  final int pages = math.max(1, (retenues.length + taille - 1) ~/ taille);
  final int courante = page.clamp(1, pages);
  final int debut = (courante - 1) * taille;
  final Map<String, String> enseignants = <String, String>{
    for (final ClasseListee c in toutes)
      if (!c.sansEnseignant) c.groupe.teacherId: c.groupe.teacherLibelle,
  };
  return PageClasses(
    lignes: retenues.sublist(
      math.min(debut, retenues.length),
      math.min(debut + taille, retenues.length),
    ),
    total: retenues.length,
    page: courante,
    taille: taille,
    compteurs: <EtatClasseListee, int>{
      for (final EtatClasseListee e in EtatClasseListee.values)
        e: autresAxes.where((ClasseListee c) => c.etat == e).length,
    },
    jours:
        (toutes.map((ClasseListee c) => c.groupe.creneau.jour).toSet()
              ..removeWhere((int j) => j < 1 || j > 7))
            .toList()
          ..sort(),
    heures:
        toutes.map((ClasseListee c) => c.groupe.creneau.heure).toSet().toList()
          ..sort(),
    fuseaux: toutes.map((ClasseListee c) => c.fuseau).toSet().toList()..sort(),
    enseignants:
        <EnseignantFiltre>[
          for (final MapEntry<String, String> e in enseignants.entries)
            (id: e.key, libelle: e.value),
        ]..sort(
          (EnseignantFiltre a, EnseignantFiltre b) =>
              a.libelle.compareTo(b.libelle),
        ),
    genres: <GenreClasse>[
      for (final GenreClasse g in GenreClasse.values)
        if (toutes.any((ClasseListee c) => c.genre == g)) g,
    ],
    totalSansFiltre: toutes.length,
  );
}

/// Le port : absent avant le contrat serveur (repli en memoire).
final Provider<PortClassesAdmin?> portClassesAdminProvider =
    Provider<PortClassesAdmin?>((Ref _) => null);

/// La page de classes demandee. Sans port : la liste de `groupes_admin()`,
/// paginee en memoire. Aucune retentative automatique : un echec se relit
/// par « Reessayer ».
final FutureProviderFamily<PageClasses, RequeteClasses>
pageClassesAdminProvider = FutureProvider.family<PageClasses, RequeteClasses>((
  Ref ref,
  RequeteClasses requete,
) async {
  final PortClassesAdmin? port = ref.watch(portClassesAdminProvider);
  if (port != null) {
    return port.page(
      requete.filtre,
      page: requete.page,
      taille: requete.taille,
    );
  }
  final List<GroupeAdmin> groupes = await ref.watch(groupesProvider.future);
  return paginerClasses(
    <ClasseListee>[
      for (final GroupeAdmin g in groupes) ClasseListee.depuisGroupe(g),
    ],
    requete.filtre,
    page: requete.page,
    taille: requete.taille,
  );
}, retry: (int _, Object _) => null);
