// Une ligne de mouvement (FI-3a, guide Finance V4 §5.2 et §7 :
// `TransactionRow`), habit de `LigneCleValeur`, jamais une recopie.

import 'package:flutter/widgets.dart';

import '../finance/format_montant.dart';
import '../finance/montant.dart';
import 'ligne_cle_valeur.dart';

/// Un mouvement (`TransactionRow`) : ce qui s'est passe, sa date deja mise
/// en mots, le montant **toujours signe** (un credit « +50 $ », un debit
/// « −50 $ ») et, s'il y en a un, son etat en pastille.
class LigneTransaction extends StatelessWidget {
  /// Cree la ligne.
  const LigneTransaction({
    required this.libelle,
    required this.date,
    required this.montant,
    super.key,
    this.statut,
  });

  /// Ce qui s'est passe : « Recharge », « Debit de la periode d'octobre ».
  final String libelle;

  /// La date, deja mise en mots par l'ecran.
  final String date;

  /// Le montant, signe.
  final Montant montant;

  /// L'etat du mouvement (« En confirmation »), une pastille qui se lit sans
  /// la couleur.
  final Widget? statut;

  @override
  Widget build(BuildContext context) => LigneCleValeur(
    cle: libelle,
    detailCle: date,
    valeur: formaterMontant(montant, signe: true),
    chiffres: true,
    complement: statut,
    valeurEnFin: true,
  );
}
