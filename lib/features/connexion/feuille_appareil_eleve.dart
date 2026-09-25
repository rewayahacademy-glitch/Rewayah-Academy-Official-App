import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';

/// La feuille qui explique l'appairage d'un appareil d'eleve, depuis `TUT-00`.
///
/// **Elle s'adresse au tuteur, pas a l'enfant**, et le vouvoie, comme la
/// saisie du code qui suit (`/connexion/eleve/code`, `SaisieCodePage`). Seuls
/// le choix du profil et le code personnel (`ELV-01`) tutoient l'eleve.
///
/// Le scan existe la ou la plateforme sait lire un QR code (Android, iOS,
/// macOS, web ; port `LecteurQr`) : `/connexion/eleve/scanner`, propose depuis
/// la saisie. Sur Windows et Linux, la saisie reste le seul chemin, et la
/// feuille dit « scannez le QR code ou saisissez le code » sans rien promettre
/// de plus (etape 4).
///
/// Elle rend `true` quand le tuteur veut passer a la saisie. **Elle ne navigue
/// pas elle-meme** : son contexte appartient a une route modale sur le point
/// d'etre depopee, et c'est l'appelant qui detient le bon.
Future<bool> ouvrirFeuilleAppareilEleve(BuildContext context) async {
  final bool? saisir = await AppBottomSheet.ouvrir<bool>(
    context,
    titre: t.connexion.appareilEleve,
    constructeur: (BuildContext _) => const _CorpsFeuilleAppareilEleve(),
    actions: (BuildContext contexte) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ActionPrincipale(
          libelle: t.connexion.feuilleAppareil.saisir,
          onPress: () => Navigator.of(contexte).pop(true),
        ),
        Ecart.vMd,
        ActionPrincipale(
          libelle: t.connexion.feuilleAppareil.fermer,
          onPress: () => Navigator.of(contexte).pop(false),
          niveau: NiveauAction.tertiaire,
        ),
      ],
    ),
  );
  return saisir ?? false;
}

class _CorpsFeuilleAppareilEleve extends StatelessWidget {
  const _CorpsFeuilleAppareilEleve();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    final List<String> etapes = <String>[
      t.connexion.feuilleAppareil.etape1,
      t.connexion.feuilleAppareil.etape2,
      t.connexion.feuilleAppareil.etape3,
      t.connexion.feuilleAppareil.etape4,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          t.connexion.feuilleAppareil.pourQui,
          style: palette.surfaceRaised.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXxl,
        Text(
          t.connexion.feuilleAppareil.etapesTitre,
          style: palette.surfaceRaised.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vLg,
        for (int i = 0; i < etapes.length; i++) ...<Widget>[
          if (i > 0) Ecart.vMd,
          _Etape(rang: i + 1, texte: etapes[i]),
        ],
        Ecart.vXxl,
        Text(
          t.connexion.feuilleAppareil.plafond,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}

/// Une etape numerotee.
///
/// Le rang est decoratif pour le lecteur d'ecran : la liste se lit dans
/// l'ordre, et annoncer « un », « deux » devant chaque phrase n'ajoute rien a
/// ce que la structure dit deja.
class _Etape extends StatelessWidget {
  const _Etape({required this.rang, required this.texte});

  final int rang;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: SizedBox(
            width: AppSpacing.xl,
            child: Text(
              '$rang.',
              style: palette.inkAccent.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
        ),
        Ecart.hSm,
        Expanded(
          child: Text(
            texte,
            style: palette.surfaceRaised.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}
