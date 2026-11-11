// PORTS-COMPTABLE (pilote, 11/11/2026) : les onglets du comptable montres,
// sans ceux dont le serveur manque (Encaissements, Rapprochement,
// Contractuels, Beneficiaires). `navigation_comptable.dart` reste tel quel (gele apres
// CPT-F) : ses listes et ses index sont filtres ici, par adresse.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/admin_domaine.dart';
import '../capacites/port_beneficiaires_paiement.dart'
    show beneficiairesOuvertsProvider;
import '../capacites/port_encaissements.dart' show encaissementsOuvertsProvider;
import '../capacites/port_obligations_contractuels.dart'
    show contractuelsOuvertsProvider;
import '../capacites/port_rapprochement.dart' show rapprochementOuvertProvider;
import '../router/routes.dart';

/// [tous] sans les onglets dont le serveur manque, et l'index de l'onglet
/// actif ([indexActif] dans [tous]) dans la liste montree. L'onglet ouvert
/// reste toujours montre (une adresse tapee a la main).
({List<({String libelle, String chemin})> onglets, int indexActif})
ongletsComptableOuverts(
  WidgetRef ref,
  List<({String libelle, String chemin})> tous, {
  required int indexActif,
}) {
  final Set<String> fermes = <String>{
    if (!ref.watch(encaissementsOuvertsProvider)) Routes.comptableEncaissements,
    if (!ref.watch(rapprochementOuvertProvider)) Routes.comptableRapprochement,
    if (!ref.watch(contractuelsOuvertsProvider)) Routes.comptableContractuels,
    if (!ref.watch(beneficiairesOuvertsProvider)) Routes.comptableBeneficiaires,
  };
  return ongletsOuverts(
    tous,
    indexActif: indexActif,
    fermes: <int>{
      for (final (int i, ({String libelle, String chemin}) o) in tous.indexed)
        if (fermes.contains(o.chemin)) i,
    },
  );
}
