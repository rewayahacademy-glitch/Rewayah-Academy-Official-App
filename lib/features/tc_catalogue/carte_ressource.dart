import 'package:flutter/material.dart';

import '../../core/tc_bibliotheque/couverture_ressource.dart';
import '../../core/tc_bibliotheque/library_resource.dart';
import '../../core/tc_telechargement/port_etat_offline.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/status_pill.dart';
import 'libelles_bibliotheque.dart';
import 'vignette_ressource.dart';

/// La carte d'une ressource.
///
/// Elle porte **toujours** trois choses : la couverture, le titre humain, et
/// l'etat hors ligne nomme. L'etat est une `StatusPill`, donc une pastille
/// **et un mot** : jamais une couleur seule (invariant J7 du depot).
///
/// **Une carte qui ne peut pas s'ouvrir n'est pas pressable, et elle dit
/// pourquoi.** Elle n'est ni grisee ni retiree : la retirer ferait croire a
/// une perte de droit, la griser laisserait chercher le geste qui la
/// reactiverait (`lib/CLAUDE.md`, rappels de l'etape 3).
///
/// **Une seule disposition, en ligne.** Une grille de tuiles a ete ecartee
/// pour une raison mesurable : une couverture a un rapport fixe, donc une
/// hauteur qui suit la largeur de sa cellule ; posee dans une grille a hauteur
/// bornee, elle deborde des que la colonne s'elargit. La couverture grandit
/// donc avec le gabarit sans changer de disposition -- voir
/// [largeurVignettePour].
class CarteRessource extends StatelessWidget {
  /// Cree une carte.
  const CarteRessource({
    required this.ressource,
    required this.etatOffline,
    super.key,
    this.onPress,
    this.raisonIndisponible,
    this.couvertureDeposee,
    this.pointDeReprise,
  });

  /// TB-9 (plan V2 §3 « Ranger reellement ») : le point de reprise d'un
  /// support range pendant la seance (« Reprise a la page 3 sur 12 »), ou
  /// `null`. Une ligne de texte, jamais une couleur seule.
  final String? pointDeReprise;

  /// La ressource presentee.
  final LibraryResource ressource;

  /// Son etat hors ligne.
  final EtatOffline etatOffline;

  /// L'action au tap. `null` quand la ressource ne peut pas s'ouvrir.
  final VoidCallback? onPress;

  /// Pourquoi la ressource ne s'ouvre pas, en une phrase.
  final String? raisonIndisponible;

  /// La couverture deposee, quand l'appelant sait la charger.
  final Widget? couvertureDeposee;

  /// La largeur de la couverture selon le gabarit.
  ///
  /// Deux valeurs de l'echelle, pas un calcul : 64 sur telephone, 112 des que
  /// la colonne s'elargit. Une couverture de 64 points reste reconnaissable au
  /// pouce ; a 112 elle redevient une couverture de livre.
  static double largeurVignettePour(BuildContext context) =>
      AppGabarit.de(context) == Gabarit.mobile
      ? AppSpacing.respiration
      : AppPage.hauteurChoix;

  @override
  Widget build(BuildContext context) {
    final double largeur = largeurVignettePour(context);

    return AppCard(
      onPress: onPress,
      libelleSemantique: libelleSemantique,
      // TB-RC (TB_RAPPORT §d n. 22) : le nom lu dit deja titre, type et
      // etat ; le texte peint se tait, la carte n'est pas lue deux fois.
      child: ExcludeSemantics(
        excluding: onPress != null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: largeur,
              child: VignetteRessource(
                couverture: CouvertureRessource.pour(ressource),
                image: couvertureDeposee,
                compacte: largeur <= AppSpacing.respiration,
              ),
            ),
            Ecart.hLg,
            Expanded(child: _texte(context)),
          ],
        ),
      ),
    );
  }

  /// Ce que lisent les technologies d'assistance.
  ///
  /// Le titre, le type et l'etat, dans cet ordre : la pastille est marquee
  /// `excludeSemantics`, donc sans cette phrase l'etat hors ligne ne serait
  /// jamais annonce.
  String get libelleSemantique {
    final String base =
        '${ressource.title}, ${libelleTypeRessource(ressource.resourceType)}, '
        '${libelleOffline(etatOffline)}';
    final String? reprise = pointDeReprise;
    final String avecReprise = reprise == null ? base : '$base. $reprise';
    final String? raison = raisonIndisponible;
    return raison == null ? avecReprise : '$avecReprise. $raison';
  }

  Widget _texte(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String sousTitre = <String>[
      libelleTypeRessource(ressource.resourceType),
      if (ressource.category.isNotEmpty) ressource.category,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          ressource.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: palette.surfaceRaised.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(
          sousTitre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
        if (pointDeReprise != null) ...<Widget>[
          Ecart.vSm,
          Text(
            pointDeReprise!,
            style: palette.inkStrong.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusPill(
            libelle: libelleOffline(etatOffline),
            ton: tonDe(etatOffline),
          ),
        ),
        if (raisonIndisponible != null) ...<Widget>[
          Ecart.vSm,
          Text(
            raisonIndisponible!,
            style: palette.inkWarning.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }

  /// Le ton d'un etat hors ligne.
  ///
  /// **Aucun etat n'est une alerte.** Une ressource pas encore telechargee
  /// n'est pas un probleme : c'est l'etat normal de la plupart des supports.
  /// Reserver le rouge a ce qui est reellement casse est ce qui lui garde son
  /// pouvoir d'alerte.
  static TonEtat tonDe(EtatOffline etat) => switch (etat) {
    EtatOffline.telecharge => TonEtat.succes,
    EtatOffline.enCours => TonEtat.accent,
    EtatOffline.enCache ||
    EtatOffline.aTelecharger ||
    EtatOffline.indisponible => TonEtat.neutre,
  };
}
