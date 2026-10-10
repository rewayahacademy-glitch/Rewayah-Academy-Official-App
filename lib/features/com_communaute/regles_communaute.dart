// L'aide et les regles de la Communaute enseignants (spec section 4.1,
// section 5.2 etat « Normal » et « Aide », section 22 textes anti-promotion
// exacts ; colonne « Aide/Regles » de COM-W02, section 23).
//
// Ici, la politique se RAPPELLE : elle ne detecte rien. Le blocage d'un
// contenu commercial (`CommunityPromotionGuard`) appartient a COM-COMU-2 et
// se nourrira d'un port, jamais d'un moteur artisanal (spec section 20).
//
// Sur ordinateur, [ReglesCommunaute] est la colonne de contexte ; ailleurs,
// [BandeauRegles] est le bandeau discret « Partage pedagogique uniquement »,
// dont « Voir les regles » ouvre la meme aide en feuille. La maquette pose
// aussi « Ressources utiles » : non repris, il concurrencerait la
// Bibliotheque (UX_REVIEW L0, point 12).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/carte_groupee.dart';
import '../../core/widgets/lien_fleche.dart';

/// L'aide de la Communaute : « A propos de cet espace », puis la politique
/// (« Partage pedagogique uniquement ») et les regles de publication.
class ReglesCommunaute extends StatelessWidget {
  /// Cree l'aide.
  const ReglesCommunaute({super.key});

  /// La cle de l'aide, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('communaute-regles');

  @override
  Widget build(BuildContext context) {
    final r = t.com.communaute.regles;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle titre = palette.inkStrong.applyTo(
      textes.titleSmall ?? const TextStyle(),
    );
    final TextStyle corps = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    return CarteGroupee(
      key: cle,
      sections: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(header: true, child: Text(r.aProposTitre, style: titre)),
            Ecart.vXs,
            Text(r.aPropos, style: corps),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(header: true, child: Text(r.titre, style: titre)),
            Ecart.vXs,
            Text(r.corps, style: corps),
            Ecart.vMd,
            Semantics(
              header: true,
              child: Text(
                r.reglesTitre,
                style: palette.inkStrong.applyTo(
                  textes.labelLarge ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
            for (final String regle in <String>[
              r.pasPublicite,
              r.pasAffilie,
              r.pasVente,
              r.pasSollicitation,
              r.pasDonnees,
            ]) ...<Widget>[_PuceRegleCommunaute(texte: regle), Ecart.vSm],
            Ecart.vXs,
            Text(
              r.signaler,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Une regle : une marque et une phrase. La marque est decorative (la phrase
/// dit tout) : elle est exclue de la semantique.
class _PuceRegleCommunaute extends StatelessWidget {
  const _PuceRegleCommunaute({required this.texte});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: IconTheme(
            data: palette.inkMuted.asIconTheme(size: AppSpacing.lg),
            child: Icon(AppIcons.interdit.repos),
          ),
        ),
        Ecart.hSm,
        Expanded(
          child: Text(
            texte,
            style: palette.inkStrong.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Le bandeau discret « Partage pedagogique uniquement » (spec section 5.2,
/// etat « Normal ») et le lien « Voir les regles », qui ouvre l'aide en
/// feuille (une boite de dialogue sur ordinateur, `AppBottomSheet`).
class BandeauRegles extends StatelessWidget {
  /// Cree le bandeau.
  const BandeauRegles({super.key});

  /// La cle du bandeau, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('communaute-bandeau');

  /// La cle du lien « Voir les regles », pour les tests.
  static const ValueKey<String> cleVoir = ValueKey<String>(
    'communaute-voir-regles',
  );

  /// Ouvre l'aide en feuille.
  static Future<void> ouvrirAide(BuildContext context) =>
      AppBottomSheet.ouvrir<void>(
        context,
        titre: t.com.communaute.regles.panneau,
        constructeur: (BuildContext _) => const ReglesCommunaute(),
      );

  @override
  Widget build(BuildContext context) {
    final r = t.com.communaute.regles;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Le titre puis le lien, l'un sous l'autre : le bandeau tient dans une
    // colonne de flux de 256 comme sur un telephone a texte agrandi.
    return Column(
      key: cle,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            ExcludeSemantics(
              child: IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                child: Icon(AppIcons.info.repos),
              ),
            ),
            Ecart.hSm,
            Expanded(
              child: Text(
                r.titre,
                style: palette.inkStrong.applyTo(
                  textes.labelLarge ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
        LienFleche(
          key: cleVoir,
          libelle: r.voir,
          onPress: () => ouvrirAide(context),
        ),
      ],
    );
  }
}
