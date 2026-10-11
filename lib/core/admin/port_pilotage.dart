/// R7, R9, R17, R19 (`DECISION-CLASSES-SIMULTANEES-2026-10-10.md`) : le
/// tableau de pilotage de la direction, par horaire et par categorie.
///
/// Pour chaque horaire (jour, heure locale, fuseau) et chaque public, une
/// ligne : le nombre de classes, leur taux de remplissage, les demandes en
/// attente, les enseignants libres et ceux qui manquent (le genre compris :
/// une classe de filles ne se confie qu'a une enseignante), les classes « en
/// attente d'enseignant » (R7) et celles qui sont passees sous le minimum
/// (R9).
///
/// **Ce que le serveur porte, et que Flutter ne decide jamais** : tout ce
/// qui precede. L'ecran additionne ce qu'on lui rend, il ne compare aucune
/// classe ni aucune disponibilite. **Le contrat attendu** (ligne Contrats a
/// demander) : une RPC paginee qui rend une page de lignes filtree (jour,
/// heure, fuseau, public, signal), le total, un resume du jeu filtre, les
/// compteurs par signal et les valeurs de filtre possibles.
///
/// Sans port ([portPilotageProvider] vaut `null`), l'ecran le dit
/// (« disponible au branchement serveur ») : il n'y a aucun repli honnete,
/// l'offre d'enseignants ne se deduit pas de la liste des classes. La
/// demonstration surcharge le port avec un grand volume simule.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

import '../capacites/capacite_indisponible.dart';
import '../capacites/port_enseignants_classe.dart' show GenreClasse;
import '../planning/service_planning.dart' show Creneau;
import 'service_groupes.dart' show TypePublicGroupe;

/// Ce qui demande l'attention de la direction sur un horaire.
enum SignalPilotage {
  /// Il manque des enseignants (R7).
  penurie,

  /// Au moins une classe est sous le minimum (R9).
  sousMinimum,

  /// Au moins une classe attend son enseignant (R7).
  attenteEnseignant,
}

/// Les enseignants d'un genre sur un horaire : ceux qui sont libres, et ceux
/// qui manquent pour couvrir les classes et les demandes de ce genre.
@immutable
class EnseignantsGenre {
  /// Cree la ligne.
  const EnseignantsGenre({
    required this.genre,
    required this.libres,
    required this.manquants,
  });

  /// Le genre des classes concernees ([GenreClasse.indetermine] : des
  /// demandes dont le genre n'est pas encore connu).
  final GenreClasse genre;

  /// Les enseignants libres a cet horaire, de ce genre.
  final int libres;

  /// Les enseignants qui manquent a cet horaire pour ce genre.
  final int manquants;
}

/// Une ligne du tableau : un horaire et une categorie.
@immutable
class LignePilotage {
  /// Cree la ligne.
  const LignePilotage({
    required this.id,
    required this.creneau,
    required this.type,
    required this.classes,
    required this.effectif,
    required this.capacite,
    this.classesSousMinimum = 0,
    this.classesAttenteEnseignant = 0,
    this.demandesEnAttente = 0,
    this.parGenre = const <EnseignantsGenre>[],
  });

  /// L'identifiant de la ligne (cle d'horaire et de categorie).
  final String id;

  /// Le jour ISO, l'heure locale et le fuseau de l'horaire.
  final Creneau creneau;

  /// La categorie : enfants ou adultes.
  final TypePublicGroupe type;

  /// Le nombre de classes de cet horaire (R19).
  final int classes;

  /// Le nombre d'eleves inscrits dans ces classes.
  final int effectif;

  /// La somme des plafonds de ces classes.
  final int capacite;

  /// Les classes passees sous le minimum (R9).
  final int classesSousMinimum;

  /// Les classes qui attendent leur enseignant (R7).
  final int classesAttenteEnseignant;

  /// Les demandes en attente sur cet horaire (R19).
  final int demandesEnAttente;

  /// Les enseignants libres et manquants, par genre.
  final List<EnseignantsGenre> parGenre;

  /// Les enseignants libres, tous genres confondus.
  int get enseignantsLibres =>
      parGenre.fold<int>(0, (int n, EnseignantsGenre g) => n + g.libres);

  /// Les enseignants qui manquent, tous genres confondus.
  int get enseignantsManquants =>
      parGenre.fold<int>(0, (int n, EnseignantsGenre g) => n + g.manquants);

  /// Le taux de remplissage, en pourcent. Nul sans capacite.
  int? get tauxRemplissage =>
      capacite <= 0 ? null : (effectif * 100 / capacite).round();

  /// Vrai quand il manque des enseignants (R7).
  bool get penurie => enseignantsManquants > 0;

  /// Vrai quand la ligne demande l'attention de la direction.
  bool get aSignaler =>
      penurie || classesSousMinimum > 0 || classesAttenteEnseignant > 0;

  /// Les signaux de la ligne.
  Set<SignalPilotage> get signaux => <SignalPilotage>{
    if (penurie) SignalPilotage.penurie,
    if (classesSousMinimum > 0) SignalPilotage.sousMinimum,
    if (classesAttenteEnseignant > 0) SignalPilotage.attenteEnseignant,
  };
}

/// Ce que l'ecran demande. `null` sur un axe veut dire « tous ».
@immutable
class FiltrePilotage {
  /// Cree un filtre.
  const FiltrePilotage({
    this.type,
    this.jour,
    this.heure,
    this.fuseau,
    this.signal,
  });

  /// La categorie.
  final TypePublicGroupe? type;

  /// Le jour ISO (1 = lundi).
  final int? jour;

  /// L'heure locale pleine.
  final int? heure;

  /// Le fuseau IANA.
  final String? fuseau;

  /// Le signal : ne garder que les horaires qui le portent.
  final SignalPilotage? signal;

  /// Le meme filtre, un axe change. Une fonction par axe rend `null`
  /// possible (« tous »).
  FiltrePilotage avec({
    TypePublicGroupe? Function()? type,
    int? Function()? jour,
    int? Function()? heure,
    String? Function()? fuseau,
    SignalPilotage? Function()? signal,
  }) => FiltrePilotage(
    type: type == null ? this.type : type(),
    jour: jour == null ? this.jour : jour(),
    heure: heure == null ? this.heure : heure(),
    fuseau: fuseau == null ? this.fuseau : fuseau(),
    signal: signal == null ? this.signal : signal(),
  );

  @override
  bool operator ==(Object other) =>
      other is FiltrePilotage &&
      other.type == type &&
      other.jour == jour &&
      other.heure == heure &&
      other.fuseau == fuseau &&
      other.signal == signal;

  @override
  int get hashCode => Object.hash(type, jour, heure, fuseau, signal);
}

/// Le resume du jeu filtre : les totaux que la direction lit d'abord.
@immutable
class ResumePilotage {
  /// Cree le resume.
  const ResumePilotage({
    required this.classes,
    required this.classesAttenteEnseignant,
    required this.classesSousMinimum,
    required this.demandesEnAttente,
    required this.enseignantsLibres,
    required this.enseignantsManquants,
  });

  /// Le nombre de classes.
  final int classes;

  /// Les classes qui attendent leur enseignant.
  final int classesAttenteEnseignant;

  /// Les classes sous le minimum.
  final int classesSousMinimum;

  /// Les demandes en attente.
  final int demandesEnAttente;

  /// Les enseignants libres.
  final int enseignantsLibres;

  /// Les enseignants qui manquent.
  final int enseignantsManquants;
}

/// Une page du tableau.
@immutable
class PagePilotage {
  /// Cree une page.
  const PagePilotage({
    required this.lignes,
    required this.total,
    required this.page,
    required this.taille,
    required this.resume,
    required this.compteurs,
    required this.jours,
    required this.heures,
    required this.fuseaux,
    required this.totalSansFiltre,
  });

  /// Les lignes de la page.
  final List<LignePilotage> lignes;

  /// Le nombre de lignes qui passent le filtre, toutes pages confondues.
  final int total;

  /// La page, a partir de 1.
  final int page;

  /// Le nombre de lignes par page.
  final int taille;

  /// Le resume du jeu filtre, toutes pages confondues.
  final ResumePilotage resume;

  /// Le nombre de lignes par signal, les autres axes du filtre appliques.
  final Map<SignalPilotage, int> compteurs;

  /// Les jours presents : les entrees du menu de filtre.
  final List<int> jours;

  /// Les heures presentes.
  final List<int> heures;

  /// Les fuseaux presents.
  final List<String> fuseaux;

  /// Le nombre de lignes sans aucun filtre : 0 veut dire « rien a
  /// piloter », pas « rien avec ce filtre ».
  final int totalSansFiltre;

  /// Le nombre de pages (1 au moins).
  int get pages => math.max(1, (total + taille - 1) ~/ taille);

  /// Le rang de la premiere ligne de la page, a partir de 1.
  int get debut => total == 0 ? 0 : (page - 1) * taille + 1;

  /// Le rang de la derniere ligne de la page.
  int get fin => (page - 1) * taille + lignes.length;
}

/// La page demandee : un filtre, un numero de page, une taille.
@immutable
class RequetePilotage {
  /// Cree une requete.
  const RequetePilotage({
    this.filtre = const FiltrePilotage(),
    this.page = 1,
    this.taille = taillePagePilotage,
  });

  /// Le filtre.
  final FiltrePilotage filtre;

  /// La page, a partir de 1.
  final int page;

  /// La taille de page.
  final int taille;

  @override
  bool operator ==(Object other) =>
      other is RequetePilotage &&
      other.filtre == filtre &&
      other.page == page &&
      other.taille == taille;

  @override
  int get hashCode => Object.hash(filtre, page, taille);
}

/// La taille de page du tableau de pilotage.
const int taillePagePilotage = 25;

/// Le port du tableau de pilotage (R17, R19).
abstract interface class PortPilotage {
  /// La page [page] (a partir de 1) de [taille] lignes qui passent
  /// [filtre].
  Future<PagePilotage> page(
    FiltrePilotage filtre, {
    required int page,
    required int taille,
  });
}

bool _passe(LignePilotage l, FiltrePilotage f, {bool avecSignal = true}) {
  if (f.type != null && l.type != f.type) return false;
  if (f.jour != null && l.creneau.jour != f.jour) return false;
  if (f.heure != null && l.creneau.heure != f.heure) return false;
  if (f.fuseau != null && l.creneau.fuseau != f.fuseau) return false;
  if (avecSignal && f.signal != null && !l.signaux.contains(f.signal)) {
    return false;
  }
  return true;
}

/// Pagine [toutes] en memoire : filtre, tri (les horaires en penurie
/// d'abord, puis le plus d'enseignants manquants, puis le plus de classes en
/// attente, puis l'horaire), decoupe, resume. Sert a la demonstration et aux
/// tests ; le serveur fera le meme travail en SQL (R17).
PagePilotage paginerPilotage(
  List<LignePilotage> toutes,
  FiltrePilotage filtre, {
  required int page,
  required int taille,
}) {
  assert(taille > 0, 'une page porte au moins une ligne');
  final List<LignePilotage> autresAxes = toutes
      .where((LignePilotage l) => _passe(l, filtre, avecSignal: false))
      .toList(growable: false);
  final List<LignePilotage> retenues =
      autresAxes
          .where(
            (LignePilotage l) =>
                filtre.signal == null || l.signaux.contains(filtre.signal),
          )
          .toList()
        ..sort((LignePilotage a, LignePilotage b) {
          final int penurie = (b.penurie ? 1 : 0).compareTo(a.penurie ? 1 : 0);
          if (penurie != 0) return penurie;
          final int manquants = b.enseignantsManquants.compareTo(
            a.enseignantsManquants,
          );
          if (manquants != 0) return manquants;
          final int attente = b.classesAttenteEnseignant.compareTo(
            a.classesAttenteEnseignant,
          );
          if (attente != 0) return attente;
          final int jour = a.creneau.jour.compareTo(b.creneau.jour);
          if (jour != 0) return jour;
          final int heure = a.creneau.heure.compareTo(b.creneau.heure);
          if (heure != 0) return heure;
          return a.id.compareTo(b.id);
        });
  final int pages = math.max(1, (retenues.length + taille - 1) ~/ taille);
  final int courante = page.clamp(1, pages);
  final int debut = (courante - 1) * taille;
  int somme(int Function(LignePilotage l) valeur) =>
      retenues.fold<int>(0, (int n, LignePilotage l) => n + valeur(l));
  return PagePilotage(
    lignes: retenues.sublist(
      math.min(debut, retenues.length),
      math.min(debut + taille, retenues.length),
    ),
    total: retenues.length,
    page: courante,
    taille: taille,
    resume: ResumePilotage(
      classes: somme((LignePilotage l) => l.classes),
      classesAttenteEnseignant: somme(
        (LignePilotage l) => l.classesAttenteEnseignant,
      ),
      classesSousMinimum: somme((LignePilotage l) => l.classesSousMinimum),
      demandesEnAttente: somme((LignePilotage l) => l.demandesEnAttente),
      enseignantsLibres: somme((LignePilotage l) => l.enseignantsLibres),
      enseignantsManquants: somme((LignePilotage l) => l.enseignantsManquants),
    ),
    compteurs: <SignalPilotage, int>{
      for (final SignalPilotage s in SignalPilotage.values)
        s: autresAxes.where((LignePilotage l) => l.signaux.contains(s)).length,
    },
    jours:
        (toutes.map((LignePilotage l) => l.creneau.jour).toSet()
              ..removeWhere((int j) => j < 1 || j > 7))
            .toList()
          ..sort(),
    heures: toutes.map((LignePilotage l) => l.creneau.heure).toSet().toList()
      ..sort(),
    fuseaux: toutes.map((LignePilotage l) => l.creneau.fuseau).toSet().toList()
      ..sort(),
    totalSansFiltre: toutes.length,
  );
}

/// L'identifiant de la dependance serveur, pour la trace et les tests
/// (jamais affiche).
const String dependancePilotage = 'DB-ECHELLE-PILOTAGE';

/// Le port : absent avant le contrat serveur.
final Provider<PortPilotage?> portPilotageProvider = Provider<PortPilotage?>(
  (Ref _) => null,
);

/// La page du tableau demandee. Sans port : [CapaciteIndisponible], que
/// l'ecran dit en clair. Aucune retentative automatique : un echec se relit
/// par « Reessayer ».
final FutureProviderFamily<PagePilotage, RequetePilotage> pagePilotageProvider =
    FutureProvider.family<PagePilotage, RequetePilotage>((
      Ref ref,
      RequetePilotage requete,
    ) {
      final PortPilotage? port = ref.watch(portPilotageProvider);
      if (port == null) {
        return Future<PagePilotage>.error(
          const CapaciteIndisponible(dependancePilotage),
        );
      }
      return port.page(
        requete.filtre,
        page: requete.page,
        taille: requete.taille,
      );
    }, retry: (int _, Object _) => null);
