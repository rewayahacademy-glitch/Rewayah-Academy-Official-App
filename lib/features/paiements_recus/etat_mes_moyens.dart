// Les lectures de « Recevoir mes paiements » (CPT-BEN-2) et les aides qui ne
// dependent que des valeurs rendues par la source (`PortMesMoyensPaiement`,
// CPT-BR-16).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../core/capacites/port_mes_moyens_paiement.dart';
import '../../core/comptable/modeles_comptable.dart';
import '../../core/comptable/statuts_comptable.dart';
import '../../core/i18n/strings.g.dart';

/// L'etat de mes moyens de paiement. **C'est aussi la capacite** qui fait
/// apparaitre la rubrique dans Compte et la ligne du Profil : sans source
/// (`CapaciteIndisponible`), ni l'une ni l'autre (jamais selon le role).
///
/// `retry` nul : pas de retentative silencieuse derriere « Reessayer ».
final FutureProvider<EtatMesMoyensPaiement> mesMoyensPaiementProvider =
    FutureProvider<EtatMesMoyensPaiement>(
      (Ref ref) => ref.watch(portMesMoyensPaiementProvider).etat(),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portMesMoyensPaiementProvider],
    );

/// Le journal de mes changements (CPT-BR-17).
final FutureProvider<List<EntreeJournal>> journalMesMoyensProvider =
    FutureProvider<List<EntreeJournal>>(
      (Ref ref) => ref.watch(portMesMoyensPaiementProvider).journal(),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portMesMoyensPaiementProvider],
    );

/// Les etats qui appellent la notice « Informations de paiement a
/// completer » (§27.1, R-FIN-19).
const Set<EtatProfilPaiement> etatsInfosACompleter = <EtatProfilPaiement>{
  EtatProfilPaiement.aucunMoyen,
  EtatProfilPaiement.incomplet,
  EtatProfilPaiement.actionRequise,
  EtatProfilPaiement.invitationEnvoyee,
};

/// Vrai quand la notice §27.1 doit s'afficher.
bool infosACompleter(EtatMesMoyensPaiement etat) =>
    etatsInfosACompleter.contains(etat.etat);

/// La phrase qui dit ce que l'etat veut dire pour moi, et quoi faire (§38).
String phraseEtatMesMoyens(EtatProfilPaiement etat) {
  final r = t.comptable.beneficiaires.recevoir;
  return switch (etat) {
    EtatProfilPaiement.aucunMoyen => r.phraseAucunMoyen,
    EtatProfilPaiement.incomplet => r.phraseIncomplet,
    EtatProfilPaiement.enVerification => r.phraseEnVerification,
    EtatProfilPaiement.verifie => r.phraseVerifie,
    EtatProfilPaiement.suspendu => r.phraseSuspendu,
    EtatProfilPaiement.actionRequise => r.phraseActionRequise,
    EtatProfilPaiement.invitationEnvoyee => r.phraseInvitationEnvoyee,
  };
}
