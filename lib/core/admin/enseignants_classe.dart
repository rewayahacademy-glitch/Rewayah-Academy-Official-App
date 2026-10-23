import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Les types de famille ne sont pas exportes par l'entree principale de
// Riverpod 3 (meme convention que `personnes_proposables.dart`).
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, ProviderFamily;

import '../capacites/capacite_indisponible.dart';
import '../capacites/port_enseignants_classe.dart';
import '../domain/enums.dart';
import '../planning/service_planning.dart' show Creneau;
import '../tc_bibliotheque/recherche_catalogue.dart';
import 'personnes_proposables.dart';
import 'service_comptes.dart';
import 'service_groupes.dart';

/// Vrai, faux ou inconnu : un enseignant de ce genre peut-il prendre une
/// classe de ce genre ? (D2, decide par delegation le 09/10.)
///
/// Classe d'hommes : un enseignant ; classe de femmes : une enseignante ;
/// genre non determine : tous. Nul quand le genre de l'enseignant n'est pas
/// connu ou que celui de la classe n'est pas encore choisi : cette fonction
/// ne conclut rien. Un genre d'enseignant non renseigne se traite a part
/// ([EnseignantClasse.genreInconnu], D3 revue le 21/10).
bool? genreCompatible(GenreClasse? classe, GenreEnseignant? enseignant) {
  if (classe == GenreClasse.indetermine) return true;
  if (classe == null || enseignant == null) return null;
  return switch (classe) {
    GenreClasse.hommes => enseignant == GenreEnseignant.homme,
    GenreClasse.femmes => enseignant == GenreEnseignant.femme,
    GenreClasse.indetermine => true,
  };
}

/// Deux creneaux designent la meme heure de la semaine.
///
/// Le fuseau n'entre pas dans la comparaison : la source rend tous les
/// creneaux d'un enseignant dans son fuseau, et le formulaire lit l'heure
/// dans ce meme fuseau (limite ecrite dans `UX_REVIEW_CLASSE-FORM-1.md`).
bool memeHeure(Creneau a, Creneau b) => a.jour == b.jour && a.heure == b.heure;

/// Un enseignant classe pour une classe a creer.
@immutable
class EnseignantClasse {
  /// Cree une ligne de classement.
  const EnseignantClasse({
    required this.enseignant,
    required this.genreCompatible,
    required this.libre,
    required this.pris,
    required this.plusAdapte,
    this.genreInconnu = false,
  });

  /// L'enseignant.
  final EnseignantPropose enseignant;

  /// Voir [genreCompatible] (la fonction) : nul quand on ne sait pas.
  final bool? genreCompatible;

  /// Libre au creneau choisi ; sans creneau choisi, libre a au moins un
  /// creneau (D5). Nul quand ses disponibilites ne sont pas rendues.
  final bool? libre;

  /// Vrai quand l'une de ses classes actives occupe deja le creneau choisi.
  final bool pris;

  /// Vrai pour le seul enseignant mentionne « le plus adapte ».
  final bool plusAdapte;

  /// Vrai quand la source dit le genre des enseignants mais pas le sien :
  /// son genre n'est pas renseigne. Le serveur ne lui confie alors aucune
  /// classe, quel que soit son public (decision du directeur sur CAND-Q15,
  /// 21/10 : controle strict sauf les disponibilites ; D3 revue).
  ///
  /// Faux quand la source ne dit le genre de personne (repli sur les
  /// comptes) : l'ecran ne sait pas, il ne conclut rien, et le serveur
  /// tranche a l'envoi.
  final bool genreInconnu;

  /// Faux quand le choisir menerait a une classe que la regle refuse (genre
  /// incompatible ou non renseigne) ou a une collision : il reste visible,
  /// avec sa raison (D3, D4), mais ne se choisit pas.
  bool get choisissable => genreCompatible != false && !pris && !genreInconnu;
}

/// Le classement des enseignants pour une classe (D2, D3, D4, D5).
///
/// Ordre : les choisissables d'abord (genre compatible et renseigne, pas de
/// collision), puis libres au creneau, puis inconnus, puis non libres ; a
/// egalite, le moins charge (classes actives), puis le nom. Le premier
/// choisissable **libre** est « le plus adapte » ; si aucun n'est libre, ou
/// si les disponibilites ne sont pas rendues, personne ne l'est : la mention
/// ne s'invente pas.
///
/// Une classe a plusieurs seances par semaine (OFFRES-ADM-1 : les jours d'un
/// regroupement de demandes) passe [creneaux] a la place de [creneau] : libre
/// veut alors dire libre a **chacun** d'eux, et une seule collision suffit a
/// rendre l'enseignant non choisissable.
///
/// Un genre d'enseignant nul ne veut dire « non renseigne » que si la source
/// dit le genre d'au moins un enseignant (meme lecture que l'ecran) : il est
/// alors visible, non choisissable, avec sa raison (D3 revue le 21/10).
List<EnseignantClasse> classerEnseignants(
  List<EnseignantPropose> enseignants, {
  GenreClasse? genre,
  Creneau? creneau,
  List<Creneau>? creneaux,
}) {
  final List<Creneau>? vises =
      creneaux ?? (creneau == null ? null : <Creneau>[creneau]);
  final bool genresRendus = enseignants.any(
    (EnseignantPropose e) => e.genre != null,
  );
  EnseignantClasse ligne(EnseignantPropose e) {
    final List<Creneau>? libres = e.creneauxLibres;
    return EnseignantClasse(
      enseignant: e,
      genreCompatible: genreCompatible(genre, e.genre),
      genreInconnu: genresRendus && e.genre == null,
      libre: libres == null
          ? null
          : vises == null || vises.isEmpty
          ? libres.isNotEmpty
          : vises.every(
              (Creneau v) => libres.any((Creneau c) => memeHeure(c, v)),
            ),
      pris:
          vises != null &&
          vises.any(
            (Creneau v) => e.creneauxPris.any((Creneau c) => memeHeure(c, v)),
          ),
      plusAdapte: false,
    );
  }

  int rangLibre(bool? libre) => switch (libre) {
    true => 0,
    null => 1,
    false => 2,
  };

  final List<EnseignantClasse> lignes = enseignants.map(ligne).toList()
    ..sort((EnseignantClasse a, EnseignantClasse b) {
      final int choix = (a.choisissable ? 0 : 1).compareTo(
        b.choisissable ? 0 : 1,
      );
      if (choix != 0) return choix;
      final int libre = rangLibre(a.libre).compareTo(rangLibre(b.libre));
      if (libre != 0) return libre;
      final int charge = a.enseignant.classesActives.compareTo(
        b.enseignant.classesActives,
      );
      if (charge != 0) return charge;
      return RechercheCatalogue.normaliser(a.enseignant.libelle)
          .compareTo(RechercheCatalogue.normaliser(b.enseignant.libelle));
    });

  final int adapte = lignes.indexWhere(
    (EnseignantClasse l) => l.choisissable && l.libre == true,
  );
  if (adapte < 0) return lignes;
  final EnseignantClasse l = lignes[adapte];
  lignes[adapte] = EnseignantClasse(
    enseignant: l.enseignant,
    genreCompatible: l.genreCompatible,
    libre: l.libre,
    pris: l.pris,
    plusAdapte: true,
    genreInconnu: l.genreInconnu,
  );
  return lignes;
}

/// Le repli tant que la source dediee est indisponible : les enseignants
/// actifs de `comptes_admin()` (meme filtre que FORM-L2), avec leur charge
/// et leurs creneaux pris lus dans les classes deja chargees. Ni genre ni
/// disponibilites : ils restent nuls, rien n'est devine.
List<EnseignantPropose> enseignantsDepuisComptes(
  List<CompteAdmin> comptes,
  List<GroupeAdmin> groupes,
) => <EnseignantPropose>[
  for (final p in personnesProposablesDepuis(comptes, AppRole.teacher))
    EnseignantPropose(
      id: p.id,
      libelle: p.nom,
      identifiant: p.identifiant,
      classesActives: groupes
          .where((GroupeAdmin g) => g.actif && g.teacherId == p.id)
          .length,
      creneauxPris: <Creneau>[
        for (final GroupeAdmin g in groupes)
          if (g.actif && g.teacherId == p.id) g.creneau,
      ],
    ),
];

/// La lecture de la source dediee, sans retentative automatique : une source
/// « indisponible » le reste, Riverpod 3 n'a pas a la relancer.
final FutureProviderFamily<List<EnseignantPropose>, TypePublicGroupe>
enseignantsDuPortProvider =
    FutureProvider.family<List<EnseignantPropose>, TypePublicGroupe>(
      (Ref ref, TypePublicGroupe public) =>
          ref.watch(portEnseignantsClasseProvider).pourClasse(public: public),
      retry: (int _, Object _) => null,
    );

/// Les enseignants proposables pour une classe : la source dediee, ou le
/// repli sur les comptes actifs quand elle est indisponible.
///
/// Une projection qui met l'echec d'abord, comme
/// `personnesProposablesProvider` : un echec de lecture se voit, il ne
/// repasse jamais en simple chargement.
final ProviderFamily<AsyncValue<List<EnseignantPropose>>, TypePublicGroupe>
enseignantsPourClasseProvider =
    Provider.family<AsyncValue<List<EnseignantPropose>>, TypePublicGroupe>((
      Ref ref,
      TypePublicGroupe public,
    ) {
      final AsyncValue<List<EnseignantPropose>> source = ref.watch(
        enseignantsDuPortProvider(public),
      );
      if (source.hasError && source.error is! CapaciteIndisponible) {
        return AsyncError<List<EnseignantPropose>>(
          source.error!,
          source.stackTrace ?? StackTrace.empty,
        );
      }
      if (source.hasValue && !source.hasError) {
        return AsyncData<List<EnseignantPropose>>(source.requireValue);
      }
      if (!source.hasError) {
        return const AsyncLoading<List<EnseignantPropose>>();
      }
      // Repli : la source dediee n'existe pas encore cote serveur.
      final AsyncValue<List<CompteAdmin>> comptes = ref.watch(comptesProvider);
      if (comptes.hasError) {
        return AsyncError<List<EnseignantPropose>>(
          comptes.error!,
          comptes.stackTrace ?? StackTrace.empty,
        );
      }
      if (!comptes.hasValue) {
        return const AsyncLoading<List<EnseignantPropose>>();
      }
      final List<GroupeAdmin> groupes =
          ref.watch(groupesProvider).value ?? const <GroupeAdmin>[];
      return AsyncData<List<EnseignantPropose>>(
        enseignantsDepuisComptes(comptes.requireValue, groupes),
      );
    });
