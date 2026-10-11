// COUPE-MOTS-FOND-1 : la garde du rendu sur la coque de l'administration
// en demonstration (rail et pied de la barre laterale a 1440, barre du
// haut a 320 et 390), a chacune de ses adresses : Accueil, Operations,
// Personnes (Dossiers, Comptes), Pedagogie (les cinq fonctions et leur
// `SousNavigationDomaine`), Configuration, Securite et audit (Journal,
// Acces des agents, Observations). Trois gabarits, francais et arabe,
// standard et Interface guidee (`test/support/balayage_ecrans.dart`).
//
// Hors balayage, ecrans d'autres voies de travail (fiche) : Finance (FIN),
// Communications et Studio (COM), Regroupements et Classes cote logique
// (ECHELLE-CORR-ECRANS-1, mesures par leur propre lot).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rewayah_academy/core/admin/service_comptes.dart';
import 'package:rewayah_academy/core/journal/service_journal.dart';
import 'package:rewayah_academy/core/router/app_router.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/tc_observation/port_historique_observations.dart';
import 'package:rewayah_academy/features/admin_observations/annuaire_observations.dart';
import 'package:rewayah_academy/features/demo/mode_demonstration.dart';

import '../features/admin_observations/support_admin_observations.dart'
    show FauxAnnuaire, FauxHistoriqueObservationsAdmin;
import '../features/filtres1_rangee_unique_test.dart'
    show CasFiltres1, casFiltres1;
import '../support/balayage_ecrans.dart';
import '../support/doubles_balayage.dart';

/// Les doubles de toutes les pages a collection, en une surcharge par
/// fournisseur.
List<Override> _doubles() {
  List<Override> toutes = <Override>[];
  for (final CasFiltres1 c in casFiltres1()) {
    toutes = fusionnerSurcharges(toutes, c.surcharges);
  }
  return fusionnerSurcharges(toutes, <Override>[
    serviceComptesProvider.overrideWithValue(ComptesBalayage()),
    serviceJournalProvider.overrideWithValue(journalBalayage()),
    portHistoriqueObservationsAdminProvider.overrideWithValue(
      FauxHistoriqueObservationsAdmin(),
    ),
    annuaireObservationsProvider.overrideWithValue(FauxAnnuaire()),
  ]);
}

/// Les adresses balayees.
const List<(String, String)> adressesAdmin = <(String, String)>[
  ('Accueil', Routes.admin),
  ('Traitement', Routes.adminOperationsTraitement),
  ('Dossiers', Routes.adminPersonnesDossiers),
  ('Comptes', Routes.adminPersonnesComptes),
  ('Diagnostics', Routes.adminPedagogieDiagnostics),
  ('Progression', Routes.adminPedagogieProgression),
  ('Evaluations', Routes.adminPedagogieEvaluations),
  ('Programmes', Routes.adminPedagogieProgrammes),
  ('Qualite', Routes.adminPedagogieQualite),
  ('Regles', Routes.adminConfigurationRegles),
  ('Fonctionnalites', Routes.adminConfigurationFonctionnalites),
  ('Conservation', Routes.adminConfigurationConservationDonnees),
  ('Politique KYC', Routes.adminConfigurationPolitiqueRevueKyc),
  ('Journal', Routes.adminSecuriteAuditJournal),
  ('Acces des agents', Routes.adminSecuriteAuditAccesAgents),
  ('Observations', Routes.adminSecuriteAuditObservations),
];

/// Les ecrans de la coque admin.
List<EcranBalayage> ecransAdmin() => <EcranBalayage>[
  for (final (String nom, String adresse) in adressesAdmin)
    (
      nom: 'admin $nom',
      page: null,
      routeur: (WidgetRef ref) => ref.read(routeurProvider),
      depart: adresse,
      surcharges: () => fusionnerSurcharges(
        surchargesDemoAdmin(environnement: 'staging'),
        _doubles(),
      ),
    ),
];

void main() {
  balayer(ecransAdmin());
}
