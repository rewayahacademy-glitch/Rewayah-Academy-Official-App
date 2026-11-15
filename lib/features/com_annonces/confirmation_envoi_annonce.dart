// La confirmation simple d'un envoi d'annonce (ANNONCES-SIMPLES, 14/11/2026) :
// elle repete le public et le nombre de personnes avant l'envoi. Ce n'est pas
// un geste destructif (ni argent, ni compte, ni suppression) : pas de
// `ConfirmDestructive`, une feuille (telephone) ou une boite (ordinateur) a
// deux actions, « Envoyer a N personnes » et « Revenir au message ».
//
// Dans son propre fichier : c'est un second ecran, au-dessus du publieur, avec
// son propre bouton plein (K-56, un par ecran).

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';

/// Ouvre la confirmation et rend `true` si la personne envoie. Une feuille
/// fermee autrement (glissement, Echap, voile) n'envoie rien.
Future<bool> confirmerEnvoiAnnonce(
  BuildContext context, {
  required String titre,
  required String consequence,
  required String libelleEnvoyer,
  required String libelleRevenir,
  Key? cleEnvoyer,
}) async {
  final bool? reponse = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: titre,
    constructeur: (BuildContext contexte) {
      final AppPalette palette = AppPalette.of(contexte);
      return Text(
        consequence,
        style: palette.inkStrong.applyTo(
          Theme.of(contexte).textTheme.bodyLarge ?? const TextStyle(),
        ),
      );
    },
    actions: (BuildContext contexte) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ActionPrincipale(
          key: cleEnvoyer,
          libelle: libelleEnvoyer,
          onPress: () => Navigator.of(contexte).pop(true),
        ),
        Ecart.vMd,
        ActionPrincipale(
          libelle: libelleRevenir,
          niveau: NiveauAction.secondaire,
          onPress: () => Navigator.of(contexte).pop(false),
        ),
      ],
    ),
  );
  return reponse ?? false;
}
