// Les lectures et les aides partagees de W07 (CPT-BEN-1) : la liste des
// beneficiaires, un profil, son journal, les filtres de la liste et les
// libelles qui ne dependent que des valeurs rendues par la source.
//
// Aucune decision d'acces ici : ce que le Comptable peut faire vient des
// permissions du profil (`PermissionsFinance`), jamais d'un role.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, ProviderOrFamily;

import '../../../core/capacites/port_beneficiaires_paiement.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';

/// La liste complete des beneficiaires. Le filtre de la page est une vue sur
/// cette liste (un seul appel, des compteurs exacts par filtre).
///
/// `retry` nul : pas de retentative silencieuse derriere « Reessayer ».
final FutureProvider<List<ProfilPaiementBeneficiaire>> beneficiairesProvider =
    FutureProvider<List<ProfilPaiementBeneficiaire>>(
      (Ref ref) => ref
          .watch(portBeneficiairesPaiementProvider)
          .liste(FiltreBeneficiaires.tout),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portBeneficiairesPaiementProvider],
    );

/// Le profil d'un beneficiaire.
final FutureProviderFamily<ProfilPaiementBeneficiaire, String>
profilBeneficiaireProvider =
    FutureProvider.family<ProfilPaiementBeneficiaire, String>(
      (Ref ref, String id) =>
          ref.watch(portBeneficiairesPaiementProvider).profil(id),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portBeneficiairesPaiementProvider],
    );

/// Le journal d'un profil (CPT-BR-17).
final FutureProviderFamily<List<EntreeJournal>, String>
journalBeneficiaireProvider =
    FutureProvider.family<List<EntreeJournal>, String>(
      (Ref ref, String id) =>
          ref.watch(portBeneficiairesPaiementProvider).journal(id),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portBeneficiairesPaiementProvider],
    );

/// Les filtres de la liste (`?filtre=`), chacun un ensemble d'etats du
/// profil (§38, §18).
enum FiltreListeBeneficiaires {
  /// Tous les beneficiaires.
  tous(<EtatProfilPaiement>{}),

  /// Infos manquantes : aucun moyen, incomplet, action requise (§27.2).
  /// Valeur d'adresse `infos`, celle des liens d'Aujourd'hui.
  infos(<EtatProfilPaiement>{
    EtatProfilPaiement.aucunMoyen,
    EtatProfilPaiement.incomplet,
    EtatProfilPaiement.actionRequise,
  }),

  /// Methode en verification (§19).
  verification(<EtatProfilPaiement>{EtatProfilPaiement.enVerification}),

  /// Paiements suspendus.
  suspendus(<EtatProfilPaiement>{EtatProfilPaiement.suspendu}),

  /// Beneficiaires externes invites (§18).
  invitations(<EtatProfilPaiement>{EtatProfilPaiement.invitationEnvoyee});

  const FiltreListeBeneficiaires(this.etats);

  /// Les etats retenus ; vide pour [tous].
  final Set<EtatProfilPaiement> etats;

  /// Vrai si [profil] passe le filtre.
  bool retient(ProfilPaiementBeneficiaire profil) =>
      etats.isEmpty || etats.contains(profil.etat);

  /// Le filtre d'une valeur d'adresse brute ; inconnue ou absente : [tous].
  static FiltreListeBeneficiaires depuis(String? brut) {
    for (final FiltreListeBeneficiaires f in values) {
      if (f.name == brut) return f;
    }
    return tous;
  }

  /// Le libelle de la pastille de filtre.
  String get libelle {
    final b = t.comptable.beneficiaires;
    return switch (this) {
      tous => b.filtreTous,
      infos => b.filtreInfos,
      verification => b.filtreVerification,
      suspendus => b.filtreSuspendus,
      invitations => b.filtreInvitations,
    };
  }
}

/// Le type lisible d'un beneficiaire.
String libelleTypeBeneficiaire(TypeBeneficiaire type) => switch (type) {
  TypeBeneficiaire.enseignant => t.comptable.beneficiaires.typeEnseignant,
  TypeBeneficiaire.contractuel => t.comptable.beneficiaires.typeContractuel,
};

/// La destination masquee en une ligne de texte (« Mobile money •••• 4423 »),
/// ou « Aucune methode de paiement ».
String texteDestination(DestinationMasquee? destination) {
  if (destination == null) return t.comptable.commun.destinationAucune;
  final String type = destination.operateur == null
      ? destination.type
      : '${destination.type} · ${destination.operateur}';
  return t.comptable.commun.destinationMasquee(
    type: type,
    suffixe: destination.suffixe,
  );
}
