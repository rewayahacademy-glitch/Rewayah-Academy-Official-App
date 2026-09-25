import 'package:flutter/material.dart';

import '../capacites/port_finance_foyer.dart';
import '../finance/format_montant.dart';
import '../i18n/strings.g.dart';
import '../theme/app_metriques.dart';
import 'avatar_tile.dart';
import 'groupe_reglages.dart';

/// La ligne d'un profil beneficiaire (S01 ; planche « Soldes du foyer ») :
/// avatar, prenom, solde, etat d'acces.
///
/// Rendue seule, elle est un [GroupeReglages] d'une ligne. Plusieurs profils
/// se posent dans **un seul** groupe a filets, via [rubrique] :
/// `GroupeReglages(lignes: [for (...) LigneBeneficiaire(...).rubrique(c)])`.
///
/// Un solde inconnu se dit en mots, jamais « 0 ».
class LigneBeneficiaire extends StatelessWidget {
  /// Cree la ligne.
  const LigneBeneficiaire({
    required this.prenom,
    required this.solde,
    super.key,
    this.acces,
    this.urlPhoto,
    this.onPress,
  });

  /// Le prenom du profil.
  final String prenom;

  /// Le solde rendu par le serveur ; `null` ou montant `null` = inconnu.
  final SoldeProfil? solde;

  /// L'etat d'acces, deja en mots (« Acces actif »), fixe par l'ecran.
  final String? acces;

  /// Photo reelle (URL signee courte), sinon l'initiale.
  final String? urlPhoto;

  /// Ouvre la fiche du profil. Avec lui, la ligne porte un chevron.
  final VoidCallback? onPress;

  /// Le solde en mots : montant mis en forme, ou « Solde inconnu ».
  static String texteSolde(SoldeProfil? solde) {
    final int? mineur = solde?.montantMineur;
    final String? devise = solde?.devise;
    return mineur == null || devise == null
        ? t.finance.soldeInconnu
        : t.finance.soldeLigne(montant: formaterMontant(mineur, devise));
  }

  /// La rubrique, pour un [GroupeReglages] qui reunit plusieurs profils.
  LigneRubrique rubrique(BuildContext context) => LigneRubrique(
    libelle: prenom,
    meneur: AvatarTile(
      prenom: prenom,
      urlSignee: urlPhoto,
      diametre: AppMetriques.of(context).cibleTactile,
    ),
    legende: <String>[texteSolde(solde), ?acces].join('\n'),
    onPress: onPress,
  );

  @override
  Widget build(BuildContext context) =>
      GroupeReglages(lignes: <LigneRubrique>[rubrique(context)]);
}
