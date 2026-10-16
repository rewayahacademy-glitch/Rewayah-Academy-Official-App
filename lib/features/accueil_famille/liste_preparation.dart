import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';

/// L'en-tete d'une section de l'Accueil : icone d'accent, titre, et lien
/// fleche a droite (« Voir tout → », « Voir l'historique → »), maquettes V1
/// et V2. Le lien n'est rendu que s'il mene quelque part.
class EnteteSection extends StatelessWidget {
  /// Cree l'en-tete.
  const EnteteSection({
    required this.icone,
    required this.titre,
    super.key,
    this.lien,
    this.onLien,
  });

  /// L'icone de section, en encre d'accent.
  final AppIcon icone;

  /// Le titre de la section.
  final String titre;

  /// Le libelle du lien.
  final String? lien;

  /// La destination du lien.
  final VoidCallback? onLien;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Telephone : titre `titleSmall` et icone de 20, pour que titre et lien
    // tiennent sur une ligne a 390 comme sur la maquette V1.
    final bool compact = AppGabarit.de(context) == Gabarit.mobile;
    return Row(
      children: <Widget>[
        ExcludeSemantics(
          child: IconTheme(
            data: palette.inkAccent.asIconTheme(
              size: compact ? AppSpacing.xl : AppSpacing.xxl,
            ),
            child: Icon(icone.repos),
          ),
        ),
        if (compact) Ecart.hSm else Ecart.hMd,
        // Titre et lien partagent la ligne tant qu'ils tiennent ; sinon le
        // lien passe dessous (texte agrandi, colonne etroite), sans rien
        // couper.
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  titre,
                  style: palette.inkStrong.applyTo(
                    (compact ? textes.titleSmall : textes.titleMedium) ??
                        const TextStyle(),
                  ),
                ),
              ),
              if (lien != null && onLien != null)
                LienFleche(libelle: lien!, onPress: onLien),
            ],
          ),
        ),
      ],
    );
  }
}

/// « Avant le prochain cours » : au plus trois actions, puis le lien vers le
/// travail complet de la classe (mandat, Accueil).
///
/// Les cercles sont **decoratifs** : aucune coche locale sans service
/// (l'ecriture « fait » est la dependance DB-CRS-10), et « fait » ne vaudrait
/// pas competence acquise. Quatre etats, jamais confondus :
///
/// - port non branche (`null`, aujourd'hui) ou classe inconnue : une phrase
///   honnete, **jamais** « Rien a preparer » ;
/// - lecture en cours : squelette ; lecture en echec : une phrase ;
/// - liste vide d'un port branche : « Rien a preparer pour l'instant » ;
/// - des actions : au plus trois lignes d'au moins 48, filets en retrait.
class ListePreparation extends StatelessWidget {
  /// Cree la section.
  const ListePreparation({required this.travail, super.key, this.onVoirTout});

  /// Le travail a venir de l'eleve dans sa classe ; `null` quand la classe
  /// n'est pas connue.
  final AsyncValue<List<SlotAction>?>? travail;

  /// Ouvre le travail complet de la classe. `null` sans classe connue.
  final VoidCallback? onVoirTout;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final AsyncValue<List<SlotAction>?>? valeur = travail;

    final Widget corps;
    if (valeur == null) {
      // L4-05 : classe inconnue, rien a lire. Dire « pas encore relie »
      // serait faux (le port est branche) ; la section n'invente rien.
      corps = const SizedBox.shrink();
    } else if (valeur.hasError && valeur.error is CapaciteIndisponible) {
      corps = Text(t.tuteur.accueil.travailIndisponible, style: discret);
    } else if (valeur.hasValue && valeur.value == null) {
      // Port pas branche (`null`) : la seule situation ou la phrase est vraie.
      corps = Text(t.tuteur.accueil.travailIndisponible, style: discret);
    } else if (valeur.hasError) {
      corps = Text(t.tuteur.accueil.travailIllisible, style: discret);
    } else if (!valeur.hasValue) {
      corps = const Skeleton.texte(lignes: 3);
    } else if (valeur.value!.isEmpty) {
      corps = Text(t.tuteur.accueil.rienAPreparer, style: discret);
    } else {
      final List<SlotAction> actions = valeur.value!
          .take(plafondActionsAvantCours)
          .toList();
      corps = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < actions.length; i++)
            _LigneTache(
              libelle: actions[i].libelle,
              filet: i < actions.length - 1,
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        EnteteSection(
          icone: AppIcons.lecon,
          titre: t.tuteur.accueil.avantProchainCours,
          lien: t.tuteur.accueil.voirTout,
          onLien: onVoirTout,
        ),
        Ecart.vMd,
        corps,
      ],
    );
  }
}

/// Une tache : cercle vide decoratif, libelle ; filet en retrait sous le
/// texte, pas sous le cercle (V1, V2).
class _LigneTache extends StatelessWidget {
  const _LigneTache({required this.libelle, required this.filet});

  final String libelle;
  final bool filet;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        ExcludeSemantics(
          child: SizedBox.square(
            dimension: AppSpacing.xxl,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  palette.borderStrong.asBorderSide(),
                ),
              ),
            ),
          ),
        ),
        Ecart.hMd,
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: filet
                  ? Border(bottom: palette.contourCarte.asBorderSide())
                  : null,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppTouchTarget.standard,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    libelle,
                    style: palette.inkStrong.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
