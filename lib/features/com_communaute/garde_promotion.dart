// Le garde anti-promotion de la Communaute enseignants
// (`CommunityPromotionGuard`, spec section 5.1, section 5.2, section 20 ;
// textes exacts section 22 ; contrat serveur COM-BR-07).
//
// UN seul composant (UX_REVIEW L0 : `PromotionPolicyGuard` n'est que sa
// politique, pas un second composant). Il rappelle la politique et affiche
// le verdict que le port lui a rendu ; il ne detecte rien et ne pretend
// jamais qu'une detection serveur a eu lieu quand elle n'existe pas. Aucun
// etat « Verifie » n'existe ici.
//
// Etats (spec section 5.2) :
// - Aide (pas de verdict, ou verdict normal) : « Partage pedagogique
//   uniquement », puis « Aucune publicite. Aucun lien affilie. Aucune
//   vente. » et « Voir les regles » ;
// - Potentiellement commercial : avertissement (registre doux
//   `washWarning`), la publication est retenue ;
// - Lien affilie, Vente : blocage (registre doux `washAlert`), avec le
//   texte canonique.
// Chaque verdict dit son motif (un des huit motifs du socle, section 5.5) et
// l'etat des liens que le serveur a lus (section 5.4). L'etat ne se lit
// jamais a la couleur seule : une icone, un titre, une phrase.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';
import 'etat_lien.dart';
import 'port_garde_promotion.dart';
import 'regles_communaute.dart';

/// Le garde anti-promotion (`CommunityPromotionGuard`).
class GardePromotion extends StatelessWidget {
  /// Cree le garde. [verification] nulle ou normale : l'aide.
  const GardePromotion({
    super.key,
    this.verification,
    this.pourReponse = false,
  });

  /// Le verdict rendu par le port, s'il y en a un.
  final VerificationPromotion? verification;

  /// Vrai sous le composer d'une reponse (revue COM-R, R-01) : les titres
  /// et consignes parlent de la reponse, la politique reste la meme.
  final bool pourReponse;

  /// La cle de l'aide, pour les tests.
  static const ValueKey<String> cleAide = ValueKey<String>(
    'communaute-garde-aide',
  );

  /// La cle du lien « Voir les regles » de l'aide, pour les tests.
  static const ValueKey<String> cleVoirRegles = ValueKey<String>(
    'communaute-garde-voir-regles',
  );

  /// La cle de l'avertissement, pour les tests.
  static const ValueKey<String> cleAvertissement = ValueKey<String>(
    'communaute-garde-avertissement',
  );

  /// La cle du blocage, pour les tests.
  static const ValueKey<String> cleBlocage = ValueKey<String>(
    'communaute-garde-blocage',
  );

  /// La cle de la ligne du motif, pour les tests.
  static const ValueKey<String> cleMotif = ValueKey<String>(
    'communaute-garde-motif',
  );

  /// Le texte canonique d'un verdict qui retient la publication (spec
  /// section 5.2 et section 22) ; nul pour un verdict normal.
  static String? texteDe(VerdictPromotion verdict, {bool pourReponse = false}) {
    final g = t.com.communaute.garde;
    return switch (verdict) {
      VerdictPromotion.normal => null,
      VerdictPromotion.avertissement =>
        pourReponse ? g.reponse.avertissement : g.avertissement,
      VerdictPromotion.lienAffilie => g.bloqueAffilie,
      VerdictPromotion.vente => g.bloqueVente,
    };
  }

  @override
  Widget build(BuildContext context) {
    final VerificationPromotion? v = verification;
    if (v == null || !v.verdict.retient) return const _Aide();
    return _Verdict(verification: v, pourReponse: pourReponse);
  }
}

/// L'aide : la politique, toujours visible au-dessus du composer.
class _Aide extends StatelessWidget {
  const _Aide();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      key: GardePromotion.cleAide,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(
              child: IconTheme(
                data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
                child: Icon(AppIcons.info.repos),
              ),
            ),
            Ecart.hSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    t.com.communaute.regles.titre,
                    style: palette.inkStrong.applyTo(
                      textes.labelLarge ?? const TextStyle(),
                    ),
                  ),
                  Ecart.vXs,
                  Text(
                    t.com.communaute.garde.aide,
                    style: palette.inkMuted.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        LienFleche(
          key: GardePromotion.cleVoirRegles,
          libelle: t.com.communaute.regles.voir,
          onPress: () => BandeauRegles.ouvrirAide(context),
        ),
      ],
    );
  }
}

/// Un verdict qui retient la publication : avertissement ou blocage.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.verification, required this.pourReponse});

  final VerificationPromotion verification;
  final bool pourReponse;

  @override
  Widget build(BuildContext context) {
    final g = t.com.communaute.garde;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final VerdictPromotion verdict = verification.verdict;
    final bool bloque = verdict.bloque;
    final AppColorPair paire = bloque ? palette.washAlert : palette.washWarning;
    final String titre = pourReponse
        ? (bloque ? g.reponse.titreBlocage : g.reponse.titreAvertissement)
        : (bloque ? g.titreBlocage : g.titreAvertissement);
    final String texte =
        GardePromotion.texteDe(verdict, pourReponse: pourReponse) ?? '';
    final String? motif = verification.motif?.libelle;

    return Semantics(
      container: true,
      liveRegion: true,
      child: AppCard(
        key: bloque
            ? GardePromotion.cleBlocage
            : GardePromotion.cleAvertissement,
        surface: paire,
        contourFort: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                ExcludeSemantics(
                  child: IconTheme(
                    data: IconThemeData(
                      color: paire.onBackground,
                      size: AppSpacing.xl,
                    ),
                    child: Icon(
                      bloque
                          ? AppIcons.interdit.repos
                          : AppIcons.avertissement.repos,
                    ),
                  ),
                ),
                Ecart.hSm,
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      titre,
                      style: paire.applyTo(
                        textes.titleSmall ?? const TextStyle(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Ecart.vSm,
            Text(
              texte,
              style: paire.applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
            if (motif != null) ...<Widget>[
              Ecart.vSm,
              Text(
                g.motif(motif: motif),
                key: GardePromotion.cleMotif,
                style: paire.applyTo(textes.labelLarge ?? const TextStyle()),
              ),
            ],
            if (verification.liens.isNotEmpty) ...<Widget>[
              Ecart.vLg,
              Semantics(
                header: true,
                child: Text(
                  pourReponse ? g.reponse.liensTitre : g.liensTitre,
                  style: paire.applyTo(textes.labelLarge ?? const TextStyle()),
                ),
              ),
              Ecart.vSm,
              for (final LienAnalyse lien in verification.liens) ...<Widget>[
                LigneEtatLien(lien: lien),
                Ecart.vSm,
              ],
            ],
            // K-59 : le blocage dit quoi faire maintenant ; l'avertissement
            // le dit deja (« Retirez le lien, le code ou l'offre... »).
            if (bloque) ...<Widget>[
              Ecart.vSm,
              Text(
                pourReponse ? g.reponse.consigneBlocage : g.consigneBlocage,
                style: paire.applyTo(textes.bodySmall ?? const TextStyle()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
