// Les lectures de « Recevoir mes paiements » (lot FINANCE-ENSEIGNANT,
// 06/11/2026) : mes coordonnees de versement, leur journal, mes versements
// recus. Tout vient du serveur ; l'ecran ne deduit aucun etat.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../core/capacites/port_coordonnees_versement.dart';
import '../../core/capacites/port_versements_paie.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';

/// Mes coordonnees. **C'est aussi la capacite** qui fait apparaitre la
/// rubrique dans Compte et dans le Profil : sans source, ou pour une personne
/// qui n'est pas payee (`CapaciteIndisponible`), rien (jamais selon le role).
final FutureProvider<MesCoordonneesVersement> mesCoordonneesVersementProvider =
    FutureProvider<MesCoordonneesVersement>(
      (Ref ref) => ref.watch(portCoordonneesVersementProvider).mesCoordonnees(),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portCoordonneesVersementProvider],
    );

/// Le journal de mes coordonnees.
final FutureProvider<List<EntreeJournalCoordonnees>>
journalCoordonneesProvider = FutureProvider<List<EntreeJournalCoordonnees>>(
  (Ref ref) => ref.watch(portCoordonneesVersementProvider).journal(),
  retry: (int retryCount, Object error) => null,
  dependencies: <ProviderOrFamily>[portCoordonneesVersementProvider],
);

/// Mes versements recus, notes par la direction.
final FutureProvider<List<VersementPaie>> mesVersementsPaieProvider =
    FutureProvider<List<VersementPaie>>(
      (Ref ref) => ref.watch(portVersementsPaieProvider).mesVersements(),
      retry: (int retryCount, Object error) => null,
      dependencies: <ProviderOrFamily>[portVersementsPaieProvider],
    );

/// Le libelle d'un champ.
String libelleChampVersement(ChampVersement c) {
  final l = t.comptable.beneficiaires.recevoir.wise.champ;
  return switch (c) {
    ChampVersement.titulaire => l.titulaire,
    ChampVersement.numeroCompte => l.numeroCompte,
    ChampVersement.iban => l.iban,
    ChampVersement.swift => l.swift,
    ChampVersement.adressePays => l.adressePays,
    ChampVersement.adresseVille => l.adresseVille,
    ChampVersement.adresseLigne => l.adresseLigne,
    ChampVersement.codePostal => l.codePostal,
    ChampVersement.adresseEtat => l.adresseEtat,
  };
}

/// L'aide d'un champ.
String aideChampVersement(ChampVersement c) {
  final a = t.comptable.beneficiaires.recevoir.wise.aide;
  return switch (c) {
    ChampVersement.titulaire => a.titulaire,
    ChampVersement.numeroCompte => a.numeroCompte,
    ChampVersement.iban => a.iban,
    ChampVersement.swift => a.swift,
    ChampVersement.adressePays => a.adressePays,
    ChampVersement.adresseVille => a.adresseVille,
    ChampVersement.adresseLigne => a.adresseLigne,
    ChampVersement.codePostal => a.codePostal,
    ChampVersement.adresseEtat => a.adresseEtat,
  };
}

/// Le libelle d'un lien avec le titulaire, dit par l'enseignant (« Mon pere ou
/// ma mere »).
String libelleLienTitulaire(LienTitulaire l) {
  final x = t.comptable.beneficiaires.recevoir.wise.lien;
  return switch (l) {
    LienTitulaire.parent => x.parent,
    LienTitulaire.conjoint => x.conjoint,
    LienTitulaire.frereSoeur => x.frereSoeur,
    LienTitulaire.autre => x.autre,
  };
}

/// Le libelle d'un moyen de versement.
String libelleMoyenVersement(MoyenVersement m) {
  final l = t.comptable.beneficiaires.recevoir.wise.moyen;
  return switch (m) {
    MoyenVersement.virementBancaire => l.virementBancaire,
    MoyenVersement.mobileMoney => l.mobileMoney,
    MoyenVersement.autre => l.autre,
  };
}

/// La valeur relue d'un champ, telle qu'on la montre : le pays par son nom.
String valeurChampVersement(ChampVersement c, String valeur) =>
    c == ChampVersement.adressePays ? nomDuPays(valeur) : valeur;

/// « octobre 2026 ».
String libelleMoisPaie(DateTime mois) =>
    '${t.commun.dates.mois[mois.month - 1]} ${mois.year}';

/// Les caracteres refuses par le serveur dans un texte libre (fichier CSV).
final RegExp caracteresInterditsVersement = RegExp(r'[,";\r\n]');
