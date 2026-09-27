import '../domain/enums.dart';

/// La version des textes que l'on fait signer.
///
/// Une acceptation est enregistree avec sa version, et l'unicite en base porte
/// sur le triplet profil, sorte, version. Une nouvelle version est donc une
/// nouvelle ligne a signer ; une version deja signee n'est jamais reecrite.
///
/// **Attention** : `etat_dossier()` ne filtre pas la version (C03 section 5,
/// DB-ADM-03). Changer une version ne redemande donc la signature qu'aux
/// dossiers qui passent par `/attente` ; les comptes deja actifs sont invites
/// par `/tuteur/compte/consentements`, qui lit leurs acceptations.
///
/// Ne faire bouger une version qu'en meme temps que le contenu de `t.contrat`,
/// `t.accuse` ou `t.consentement.texte`, jamais separement.
abstract final class VersionsContrat {
  /// La version d'origine des conditions, du contrat enseignant et de la carte
  /// d'accuse de l'ADR-011. Elle reste celle du contrat enseignant et de
  /// l'accuse : leur texte n'a pas change.
  static const String courante = '2026-09';

  /// Les conditions du tuteur avec le paragraphe des visites d'observation
  /// (decisions 03 section 1 bis-2 et 3) : le texte d'origine, notice
  /// d'enregistrement comprise, plus ce paragraphe.
  static const String avecObservation = '2026-09-obs';

  /// La version a signer pour une sorte de texte.
  static String pour(SorteContrat sorte) => switch (sorte) {
    SorteContrat.conditionsTuteur => avecObservation,
    SorteContrat.contratEnseignant => courante,
    SorteContrat.accuseEnregistrementControle => courante,
  };
}
