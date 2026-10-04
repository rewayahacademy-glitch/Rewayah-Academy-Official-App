// Les lignes d'argent (FI-3a, guide Finance V4 §5.2, §5.3, §5.4 et §7 :
// `FinanceLineItem`, `TransactionRow`, `PaymentAllocationRow`).
//
// Trois habits de `LigneCleValeur`, jamais une recopie : la cle en encre
// attenuee, la valeur en chiffres tabulaires, empilees des que le texte est
// agrandi, lues en un seul noeud. Elles se posent dans une seule carte, des
// filets entre elles (`GroupedCard`, guide §7) : jamais une pile de
// mini-cartes.

import 'package:flutter/widgets.dart';

import '../finance/format_montant.dart';
import '../finance/montant.dart';
import 'ligne_cle_valeur.dart';

/// Une ligne de decomposition (`FinanceLineItem`) : « Tarif enfant 50 $ »,
/// « Remise familiale, 3e membre −5 $ », « Total a financer 145 $ ».
///
/// Les lignes viennent de la source, jamais d'une maquette : une remise qui
/// n'existe pas ne s'affiche pas (guide §5.2).
class LigneFinance extends StatelessWidget {
  /// Cree la ligne.
  const LigneFinance({
    required this.libelle,
    required this.montant,
    super.key,
    this.signe = false,
    this.total = false,
    this.detail,
    this.complement,
  });

  /// Ce que le montant designe.
  final String libelle;

  /// Le montant.
  final Montant montant;

  /// Vrai pour poser le signe d'un montant positif (une taxe ajoutee).
  final bool signe;

  /// Vrai pour la ligne qui conclut la decomposition : valeur au rang d'un
  /// titre de carte.
  final bool total;

  /// Une precision sous le libelle.
  final String? detail;

  /// Un element apres le montant (une pastille d'etat).
  final Widget? complement;

  @override
  Widget build(BuildContext context) => LigneCleValeur(
    cle: libelle,
    detailCle: detail,
    valeur: formaterMontant(montant, signe: signe),
    chiffres: true,
    valeurForte: total,
    complement: complement,
  );
}
