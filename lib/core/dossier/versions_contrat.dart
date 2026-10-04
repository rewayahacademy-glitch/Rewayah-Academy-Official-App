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
  /// d'accuse de l'ADR-011. Elle est en production depuis le 21/09 : des
  /// comptes reels ont pu la signer. Ses textes (`t.contrat.pointEnregistrement`,
  /// `t.contrat.pointControle`, `t.accuse`) sont donc gardes tels quels, comme
  /// trace de ce qui a ete signe, et ne sont plus affiches.
  static const String courante = '2026-09';

  /// Les textes juridiques valides par le directeur le 02/10/2026
  /// (pilotage `14_controleur/juridique/SIGNATURES_2026-10-02.md`) : A3 et E1
  /// corriges (`t.contrat.a3`, `t.contrat.e1`), la clause des visites de
  /// controle et la case de l'article 9 du contrat enseignant
  /// (`t.contrat.clauseControle`). Nouvelle version, parce que l'ancienne
  /// ([courante]) a pu etre vue par un compte reel.
  static const String textesJuridiques = '2026-10-jur';

  /// Les conditions du tuteur avec le paragraphe des visites d'observation
  /// (decisions 03 section 1 bis-2 et 3), et depuis le 02/10 le texte A3
  /// corrige. Cette version n'a jamais ete deployee en production (`main`
  /// porte seulement [courante]) : aucun compte reel ne l'a vue, et la regle
  /// des corrections A0/A3 autorise d'y faire entrer le texte A3 valide.
  static const String avecObservation = '2026-09-obs';

  /// La duree de conservation des enregistrements dite par le texte signe
  /// (`{duree_enreg}` de A3, 30 jours, `09_consentements/TEXTES_V2.md`). Elle
  /// fait partie du texte de la version : la changer demande une nouvelle
  /// version, jamais une lecture de la configuration au moment d'afficher.
  static const int dureeEnregistrementJours = 30;

  /// La version a signer pour une sorte de texte.
  static String pour(SorteContrat sorte) => switch (sorte) {
    SorteContrat.conditionsTuteur => avecObservation,
    SorteContrat.contratEnseignant => textesJuridiques,
    SorteContrat.accuseEnregistrementControle => textesJuridiques,
  };
}
