// La confirmation « Executer ce remboursement ? » (spec §26, §47 ;
// CPT-BR-15). La feuille rappelle le beneficiaire, le motif, la source et le
// montant (masquable comme partout, revele par la bascule de la page) ; elle
// dit que les regles viennent de la politique Finance. Rien ne se saisit :
// le Comptable applique, il ne reecrit pas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/capacites/port_encaissements.dart';
import '../../../../core/i18n/strings.g.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/action_principale.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/ligne_cle_valeur.dart';
import '../commun_encaissements.dart';

/// La cle du bouton de confirmation de la feuille.
const Key confirmerRemboursementKey = ValueKey<String>('remb-confirmer');

/// Ouvre la confirmation ; vrai si la personne confirme.
///
/// La feuille vit sur la route modale, hors de l'arbre de la page : elle
/// reprend le conteneur de la page, pour lire la meme visibilite des
/// montants (et les memes surcharges en demonstration).
Future<bool> confirmerRemboursement(
  BuildContext context,
  Remboursement remboursement,
) async {
  final ProviderContainer conteneur = ProviderScope.containerOf(context);
  final r = t.comptable.encaissements.rap;
  final bool? ok = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: r.executerTitre,
    constructeur: (BuildContext _) => UncontrolledProviderScope(
      container: conteneur,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LigneCleValeur(
            cle: r.beneficiaire,
            valeur: remboursement.beneficiaire,
          ),
          LigneCleValeur(cle: r.motif, valeur: remboursement.motif),
          LigneCleValeur(cle: r.source, valeur: remboursement.source),
          LigneMontant(
            libelle: r.montant,
            montant: remboursement.montant,
            fort: true,
          ),
          Ecart.vMd,
          NoteAttenuee(r.executerPhrase),
        ],
      ),
    ),
    actions: (BuildContext feuille) => RangeeActions(
      children: <Widget>[
        ActionPrincipale(
          libelle: t.commun.annuler,
          niveau: NiveauAction.secondaire,
          onPress: () => Navigator.of(feuille).pop(false),
        ),
        ActionPrincipale(
          key: confirmerRemboursementKey,
          libelle: r.executer,
          niveau: NiveauAction.principale,
          onPress: () => Navigator.of(feuille).pop(true),
        ),
      ],
    ),
  );
  return ok ?? false;
}
