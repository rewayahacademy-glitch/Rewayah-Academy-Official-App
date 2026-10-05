import 'package:flutter/material.dart';

import '../accessibilite/texte_sans_coupure.dart';
import '../theme/app_gabarit.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'pastille_etat_seance.dart';

/// Une ligne « cle : valeur » de fiche de detail : « Horaire : 18:00 (heure
/// de Paris) », « Presence : En cours de verification » (detail de seance et
/// detail d'observation, manifeste visuel Tuteur V1 section 3.4).
///
/// La cle se lit en encre attenuee, la valeur en encre forte. Cote a cote
/// quand la place le permet, **empilees des que le texte est agrandi**
/// (`AppGabarit.seuilTexteColonne`) : a 200 %, deux colonnes coupent les
/// mots, une pile ne coupe rien.
///
/// Le lecteur d'ecran lit la cle puis la valeur, en un seul noeud
/// (`MergeSemantics`) : une valeur lue seule, « 18:00 », ne dit rien.
class LigneCleValeur extends StatelessWidget {
  /// Cree une ligne.
  const LigneCleValeur({
    required this.cle,
    required this.valeur,
    super.key,
    this.complement,
    this.chiffres = false,
    this.annulee = false,
    this.detailCle,
    this.meneur,
    this.valeurForte = false,
    this.valeurEnFin = false,
  });

  /// La marge au-dessus et au-dessous de la ligne : un bandeau de profil
  /// pose en [meneur] y remonte sans depasser la ligne (`BandeauProfil`,
  /// `remontee`).
  static const double margeVerticale = AppSpacing.sm;

  /// Ce que la valeur designe : « Horaire », « Duree », « Presence ».
  final String cle;

  /// La valeur, deja mise en mots par le service ou l'ecran.
  final String valeur;

  /// Un element pose apres la valeur : une pastille d'etat, par exemple.
  final Widget? complement;

  /// Vrai pour une valeur faite de chiffres (horaire, duree, code) : chiffres
  /// tabulaires, qui ne dansent pas d'une ligne a l'autre.
  final bool chiffres;

  /// Vrai quand la valeur est l'horaire d'une seance annulee : barree et
  /// attenuee, annoncee « Annulee : ... » (ANNUL-VIS-1).
  final bool annulee;

  /// Une precision sous la cle, en plus petit : la date d'un mouvement, la
  /// periode d'un profil (lignes d'argent, FI-3a).
  final String? detailCle;

  /// Ce qui se pose avant la cle : l'avatar d'un profil (lignes d'argent,
  /// FI-3a). Reste en tete quand la ligne s'empile.
  final Widget? meneur;

  /// Vrai pour une valeur qui conclut un bloc (un total) : au rang des noms
  /// et titres de carte (`titleMedium`) au lieu du corps.
  final bool valeurForte;

  /// Vrai pour une valeur posee au bord de fin de la ligne (droite en LTR,
  /// gauche en RTL) : les montants des lignes d'argent (revue FI-3-R, M1 ;
  /// guide Finance V4 §7, §11.3 « colonnes calmes et stables »). Les fins de
  /// montants d'une meme carte tombent alors sur un seul bord, et les
  /// chiffres tabulaires alignent les decimales. Le complement (une
  /// pastille) passe avant la valeur, pour que le montant reste au bord.
  /// Faux par defaut : les autres lignes gardent leur valeur au debut.
  final bool valeurEnFin;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle base =
        (valeurForte ? textes.titleMedium : textes.bodyLarge) ??
        const TextStyle();
    final TextStyle styleValeur = palette.inkStrong.applyTo(
      chiffres ? AppTypography.tabulaire(base) : base,
    );
    final Text libelleCle = Text(
      cle,
      style: palette.inkMuted.applyTo(textes.bodyMedium ?? const TextStyle()),
    );
    final String? detail = detailCle;
    final Widget texteCle = detail == null
        ? libelleCle
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              libelleCle,
              Text(
                detail,
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
          );
    final Widget texteValeur = annulee
        ? TexteHeureSeance(heure: valeur, annulee: true, style: styleValeur)
        // COUPE-MOTS-1 : une valeur (« facture-024.pdf ») ne se coupe pas
        // dans un mot a 320 px, texte x2 (CPT-FUS).
        : TexteSansCoupure(
            valeur,
            style: styleValeur,
            textAlign: valeurEnFin ? TextAlign.end : null,
          );
    final Widget blocValeur = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      alignment: valeurEnFin ? WrapAlignment.end : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        if (valeurEnFin) ?complement,
        texteValeur,
        if (!valeurEnFin) ?complement,
      ],
    );
    final bool empiler =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne;

    final Widget corps = empiler
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              texteCle,
              Ecart.vXs,
              // Empilee, la valeur garde son bord : celui de fin pour un
              // montant, celui de la colonne des autres montants.
              if (valeurEnFin)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: blocValeur,
                )
              else
                blocValeur,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 2, child: texteCle),
              Ecart.hLg,
              Expanded(flex: 3, child: blocValeur),
            ],
          );
    final Widget? tete = meneur;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: margeVerticale),
        child: tete == null
            ? corps
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  tete,
                  Ecart.hMd,
                  Expanded(child: corps),
                ],
              ),
      ),
    );
  }
}
