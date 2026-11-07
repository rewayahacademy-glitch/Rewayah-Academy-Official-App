// La politique commerciale effective et ses versions (FI-1c, guide Finance
// V4 §1, §5.7 ; FI-BR-01, FI-BR-02).
//
// Lecture des versions (FI-1c) ; FI-11b ajoute la publication d'un
// brouillon, qui rend `CapaciteIndisponible` partout, demonstration comprise,
// jusqu'au branchement : « Publier » mene a un etat honnete et n'ecrit rien
// (K-28). FI-11c ajoute l'apercu d'un brouillon (foyer, enseignant) : des
// montants arretes par la source, jamais calcules dans un widget (FI6).
// Aucune source serveur a ce jour : la demonstration surcharge le port
// (`finance_demo.dart`).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/politique_commerciale.dart';
import 'capacite_indisponible.dart';
import 'port_revenus_enseignant.dart' show TypeClasseRevenus;

export 'port_revenus_enseignant.dart' show TypeClasseRevenus;

/// Les politiques commerciales, lues par tous les ecrans qui en dependent.
abstract interface class PortPolitiquesCommerciales {
  /// La politique effective aujourd'hui (FI-BR-01).
  Future<PolitiqueCommerciale> active();

  /// L'historique des versions, la plus recente d'abord (FI-BR-02).
  Future<List<PolitiqueCommerciale>> versions();

  /// Publie [brouillon] a sa date d'effet (FI-BR-02). **Aucune
  /// implementation n'ecrit a ce jour** : production et demonstration rendent
  /// `CapaciteIndisponible`.
  Future<void> publier(PolitiqueCommerciale brouillon);

  /// L'apercu d'un foyer de [enfants] membres payants (1 a 5) sous
  /// [brouillon] : la mensualite de chacun et le total, arretes.
  Future<ApercuFamille> apercuFamille(
    PolitiqueCommerciale brouillon,
    int enfants,
  );

  /// L'apercu de la paie d'une heure de seance dans une classe de [type],
  /// avec [presents] eleves presents, sous [brouillon] (paie par eleve
  /// present, REVENUS-VERITE, 06/11/2026).
  Future<ApercuEnseignant> apercuEnseignant(
    PolitiqueCommerciale brouillon, {
    required TypeClasseRevenus type,
    required int presents,
  });
}

/// **Aucune source serveur a ce jour** (FI-BR-01, FI-BR-02).
class PolitiquesCommercialesIndisponibles
    implements PortPolitiquesCommerciales {
  /// Cree l'implementation.
  const PolitiquesCommercialesIndisponibles();

  @override
  Future<PolitiqueCommerciale> active() => Future<PolitiqueCommerciale>.error(
    const CapaciteIndisponible('FI-BR-01'),
  );

  @override
  Future<List<PolitiqueCommerciale>> versions() =>
      Future<List<PolitiqueCommerciale>>.error(
        const CapaciteIndisponible('FI-BR-02'),
      );

  @override
  Future<void> publier(PolitiqueCommerciale brouillon) =>
      Future<void>.error(const CapaciteIndisponible('FI-BR-02'));

  @override
  Future<ApercuFamille> apercuFamille(
    PolitiqueCommerciale brouillon,
    int enfants,
  ) => Future<ApercuFamille>.error(const CapaciteIndisponible('FI-BR-01'));

  @override
  Future<ApercuEnseignant> apercuEnseignant(
    PolitiqueCommerciale brouillon, {
    required TypeClasseRevenus type,
    required int presents,
  }) => Future<ApercuEnseignant>.error(const CapaciteIndisponible('FI-BR-01'));
}

/// Le port des politiques ; la demonstration le surcharge.
final Provider<PortPolitiquesCommerciales> portPolitiquesCommercialesProvider =
    Provider<PortPolitiquesCommerciales>(
      (Ref _) => const PolitiquesCommercialesIndisponibles(),
    );
