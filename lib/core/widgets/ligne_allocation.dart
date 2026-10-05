// La part d'un paiement qui va a un profil (FI-3a, guide Finance V4 §5.3,
// §5.4 et §7 : `PaymentAllocationRow`), habit de `LigneCleValeur`.

import 'package:flutter/material.dart';

import '../finance/format_montant.dart';
import '../finance/montant.dart';
import '../i18n/strings.g.dart';
import '../icons/app_icons.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import 'carte_lignes.dart';
import 'ligne_cle_valeur.dart';

/// La part d'un paiement qui va a un profil (`PaymentAllocationRow`, guide
/// §5.3 et §5.4) : on voit toujours **a qui** va chaque montant, son avatar
/// et son prenom en tete, jamais un « solde commun ».
///
/// Posee dans une `CarteLignes`, la ligne prend la marge horizontale de la
/// carte (`AppSpacing.lg`, comme `SettingRow`) : l'avatar ne touche pas le
/// bord de debut, le montant pas celui de fin (revue FI-VAGUE-R, R3-03).
/// Hors carte (le recu), elle reste au bord de sa colonne.
class LigneAllocation extends StatelessWidget {
  /// Cree la ligne.
  const LigneAllocation({
    required this.prenom,
    required this.montant,
    required this.avatar,
    super.key,
    this.detail,
    this.credite = false,
  });

  /// La coche « Credite », pour les tests.
  static const Key crediteKey = Key('ligneAllocation.credite');

  /// Le prenom du profil.
  final String prenom;

  /// Ce qui lui est attribue.
  final Montant montant;

  /// Son avatar, avec son bandeau de couleur s'il en a un (`BandeauProfil`).
  final Widget avatar;

  /// Une precision : la periode financee, le nouveau solde.
  final String? detail;

  /// Vrai quand la source dit la part creditee (paiement `termine`, guide
  /// §5.4, maquette 01) : le montant porte son signe « + » et une coche lue
  /// « Credite » le precede. Jamais avant : une part en attente n'est pas un
  /// credit (FI9).
  final bool credite;

  @override
  Widget build(BuildContext context) {
    final Widget ligne = LigneCleValeur(
      meneur: avatar,
      cle: prenom,
      detailCle: detail,
      valeur: formaterMontant(montant, signe: credite),
      chiffres: true,
      valeurEnFin: true,
      complement: credite
          ? Semantics(
              key: crediteKey,
              label: t.argent.allocation.credite,
              child: ExcludeSemantics(
                child: IconTheme(
                  data: AppPalette.of(context).inkSuccess
                      .asIconTheme(size: AppSpacing.lg),
                  child: Icon(AppIcons.succes.actif),
                ),
              ),
            )
          : null,
    );
    if (!LigneDansCarte.de(context)) return ligne;
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.lg),
      child: ligne,
    );
  }
}
