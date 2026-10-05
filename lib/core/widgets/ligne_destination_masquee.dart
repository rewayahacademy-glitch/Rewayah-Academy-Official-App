import 'package:flutter/material.dart';

import '../comptable/modeles_comptable.dart';
import '../i18n/strings.g.dart';
import 'ligne_cle_valeur.dart';
import 'pastilles_comptable.dart';

/// Une destination de paiement masquee (`PaymentMethodRow` du personnel,
/// spec §16.3 ; CPT-F) : « Destination : Orange Money •••• 4423 », pays et
/// devise sous la cle, etat de verification en pastille.
///
/// Habit de [LigneCleValeur], pas de `LigneMoyenPaiement` (qui sert a
/// **payer**, cote tuteur). Le suffixe est **rendu masque par la source** :
/// l'app n'a jamais vu la coordonnee complete, elle ne peut donc rien
/// reveler. Le lecteur d'ecran entend « numero masque, se termine par 4423 »,
/// pas une suite de points. Sans destination, la ligne dit « Aucune methode
/// de paiement », jamais un champ vide.
///
/// **Fichier gele apres CPT-F** (`20_comptable/02_DECOUPAGE.md`, liste A).
class LigneDestinationMasquee extends StatelessWidget {
  /// Cree la ligne.
  const LigneDestinationMasquee({super.key, this.destination, this.cle});

  /// La destination, ou `null` quand le beneficiaire n'en a aucune.
  final DestinationMasquee? destination;

  /// La cle, « Destination » par defaut.
  final String? cle;

  @override
  Widget build(BuildContext context) {
    final DestinationMasquee? d = destination;
    final String libelleCle = cle ?? t.comptable.commun.destination;
    if (d == null) {
      return LigneCleValeur(
        cle: libelleCle,
        valeur: t.comptable.commun.destinationAucune,
      );
    }
    final String type = d.operateur == null
        ? d.type
        : '${d.type} · ${d.operateur}';
    return Semantics(
      label:
          '$libelleCle : '
          '${t.comptable.commun.destinationMasqueeLecteur(type: type, suffixe: d.suffixe)}, '
          '${t.comptable.commun.paysDevise(pays: d.pays, devise: d.devise)}, '
          '${libelleProfilPaiement(d.verification)}',
      excludeSemantics: true,
      child: LigneCleValeur(
        cle: libelleCle,
        detailCle: t.comptable.commun.paysDevise(
          pays: d.pays,
          devise: d.devise,
        ),
        valeur: t.comptable.commun.destinationMasquee(
          type: type,
          suffixe: d.suffixe,
        ),
        chiffres: true,
        complement: PastilleProfilPaiement(d.verification),
      ),
    );
  }
}
