// Le port des ecrans de l'eleve adulte : Accueil, Ma classe, historique des
// seances (INVENTAIRE-NON-BRANCHE-2026-10-31 section B).
//
// Une seule interface pour les trois lectures, qui partagent la meme porte
// serveur (`ma_capacite_eleve()`). Hors application reelle, le port rend
// `CapaciteIndisponible`, comme les trois providers le faisaient avant
// (EA-BR-04) ; l'adaptateur Supabase est pose par `lib/main.dart`, et la
// demonstration surcharge les providers eux-memes (K-28).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../ma_classe_adulte/ma_classe_adulte_page.dart' show MaClasseAdulteVM;
import 'accueil_adulte_page.dart' show AccueilAdulteVM, SeancePasseeAdulte;

/// Ce que les ecrans de l'eleve adulte lisent du serveur.
abstract interface class PortEspaceAdulte {
  /// L'Accueil : prenom, Classe, dernieres seances ([limite] au plus).
  Future<AccueilAdulteVM> accueil({required int limite});

  /// Ma classe : la Classe et ses participants.
  Future<MaClasseAdulteVM> maClasse();

  /// Toutes les seances passees, les plus recentes d'abord.
  Future<List<SeancePasseeAdulte>> historique();
}

/// Le port sans source : chaque lecture dit la capacite absente, avec le
/// meme code qu'avant le branchement.
class EspaceAdulteIndisponible implements PortEspaceAdulte {
  /// Cree le port indisponible.
  const EspaceAdulteIndisponible();

  @override
  Future<AccueilAdulteVM> accueil({required int limite}) =>
      Future<AccueilAdulteVM>.error(
        const CapaciteIndisponible('accueil_eleve_adulte'),
      );

  @override
  Future<MaClasseAdulteVM> maClasse() => Future<MaClasseAdulteVM>.error(
    const CapaciteIndisponible('ma_classe_eleve_adulte'),
  );

  @override
  Future<List<SeancePasseeAdulte>> historique() =>
      Future<List<SeancePasseeAdulte>>.error(
        const CapaciteIndisponible('historique_seances_eleve_adulte'),
      );
}

/// Le port des ecrans de l'eleve adulte ; surcharge par `lib/main.dart`.
final Provider<PortEspaceAdulte> portEspaceAdulteProvider =
    Provider<PortEspaceAdulte>((Ref _) => const EspaceAdulteIndisponible());
