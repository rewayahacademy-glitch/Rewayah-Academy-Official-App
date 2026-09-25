import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/skeleton.dart';
import 'bloc_seance.dart';

/// La carte classe de l'Accueil : l'eleve, sa classe et son enseignant, la
/// prochaine seance, puis le CTA dominant « Voir la classe → ».
///
/// Maquettes V1 (telephone) et V2 (tablette, bureau) ; manifeste, composants
/// « Carte classe » et « Bloc seance ». Une seule carte, un seul CTA dominant
/// (`ActionPrincipale` principale), aucune action concurrente : le lien
/// « fournir une photo » de la maquette V1 n'est pas repris (defaut C3, un
/// seul blocage, et aucune regle de photo en base, point P6).
///
/// **Le CTA n'est rendu que si la classe est connue** : sans identifiant de
/// classe, « Voir la classe » ne pourrait mener nulle part (un bouton qui ne
/// peut pas aboutir n'est pas rendu, `lib/CLAUDE.md`).
class CarteClasseSeance extends StatelessWidget {
  /// Cree la carte.
  const CarteClasseSeance({
    required this.profil,
    required this.classe,
    required this.seance,
    required this.maintenantServeurUtc,
    required this.compact,
    required this.onVoirClasse,
    required this.onReessayerClasse,
    required this.onReessayerSeance,
    super.key,
    this.urlPhotoEleve,
  });

  /// L'eleve selectionne.
  final ProfilEleveFoyer profil;

  /// Sa photo (URL signee courte), sinon l'initiale.
  final String? urlPhotoEleve;

  /// Sa classe courante (K6), `null` s'il n'en a pas.
  final AsyncValue<ClasseFoyer?> classe;

  /// Sa prochaine seance (K2), `null` s'il n'en a pas.
  final AsyncValue<SeanceFamille?> seance;

  /// L'instant serveur, `null` sans horloge serveur.
  final DateTime? maintenantServeurUtc;

  /// Vrai sur telephone.
  final bool compact;

  /// Ouvre la classe.
  final ValueChanged<String> onVoirClasse;

  /// Relit la classe.
  final VoidCallback onReessayerClasse;

  /// Relit la seance.
  final VoidCallback onReessayerSeance;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final ClasseFoyer? laClasse = classe.value;

    return AppCard(
      // Bureau et tablette : la carte mise en avant (V2) ; telephone : la
      // surface elevee, avec la seance en zone imbriquee (V1).
      surface: compact ? palette.surfaceRaised : palette.surfaceMiseEnAvant,
      marge: compact ? AppSpacing.lg : AppSpacing.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Identite(
            profil: profil,
            urlPhotoEleve: urlPhotoEleve,
            classe: classe,
            compact: compact,
            onReessayer: onReessayerClasse,
          ),
          if (compact)
            Ecart.vLg
          else ...<Widget>[Ecart.vXl, const FiletHorizontal(), Ecart.vXl],
          _Seance(
            profil: profil,
            seance: seance,
            maintenantServeurUtc: maintenantServeurUtc,
            compact: compact,
            onReessayer: onReessayerSeance,
          ),
          if (laClasse != null) ...<Widget>[
            Ecart.vXl,
            ActionPrincipale(
              libelle: t.tuteur.accueil.voirLaClasse,
              fleche: true,
              onPress: () => onVoirClasse(laClasse.classe.groupeId),
            ),
          ],
          if (!compact && seance.value != null) ...<Widget>[
            Ecart.vLg,
            const ConseilAppareil(),
          ],
        ],
      ),
    );
  }
}

/// L'en-tete d'identite : l'eleve (portrait ou initiale), sa classe, son
/// enseignant (photo publique ou initiale, titre Sayyid / Sayyida) et le
/// parcours lisible. Le portrait de l'eleve et celui de l'enseignant sont
/// deux avatars distincts (defaut C4 des maquettes).
class _Identite extends StatelessWidget {
  const _Identite({
    required this.profil,
    required this.urlPhotoEleve,
    required this.classe,
    required this.compact,
    required this.onReessayer,
  });

  final ProfilEleveFoyer profil;
  final String? urlPhotoEleve;
  final AsyncValue<ClasseFoyer?> classe;
  final bool compact;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: AvatarTile(
            prenom: profil.prenom,
            urlSignee: urlPhotoEleve,
            diametre: compact
                ? SelecteurProfils.diametreMobile
                : SelecteurProfils.diametreLarge,
          ),
        ),
        Ecart.hLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  profil.prenom,
                  style: palette.inkStrong.applyTo(
                    textes.titleLarge ?? const TextStyle(),
                  ),
                ),
              ),
              Ecart.vXs,
              ..._classe(context, palette, textes),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _classe(
    BuildContext context,
    AppPalette palette,
    TextTheme textes,
  ) {
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    if (classe.hasError) {
      final bool indisponible = classe.error is CapaciteIndisponible;
      return <Widget>[
        Text(
          indisponible
              ? t.tuteur.accueil.classeIndisponible
              : t.tuteur.accueil.classeIllisible,
          style: discret,
        ),
        if (!indisponible)
          ActionPrincipale(
            libelle: t.commun.reessayer,
            onPress: onReessayer,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
          ),
      ];
    }
    if (!classe.hasValue) {
      return const <Widget>[Skeleton.texte(lignes: 2)];
    }
    final ClasseFoyer? laClasse = classe.value;
    if (laClasse == null) {
      return const <Widget>[];
    }
    final GroupSummaryVM c = laClasse.classe;
    final String parcours = LibellesGroupe.coursEtNiveau(
      cours: c.nomCours,
      niveau: c.niveauHumain,
    );
    return <Widget>[
      Text(
        c.libelle,
        style: palette.inkStrong.applyTo(
          textes.titleMedium ?? const TextStyle(),
        ),
      ),
      Ecart.vSm,
      MergeSemantics(
        child: Row(
          children: <Widget>[
            // Photo publique de l'enseignant quand l'hote sait la resoudre
            // (DB-CRS-09), sinon son initiale : jamais le portrait de
            // l'eleve a sa place.
            AvatarTile(
              prenom: c.enseignant.nomAffichage,
              diametre: AppSpacing.xxxl,
            ),
            Ecart.hSm,
            Expanded(
              child: Text(
                LibellesGroupe.enseignantNomme(c.enseignant),
                style: palette.inkMuted.applyTo(
                  textes.bodyLarge ?? const TextStyle(),
                ),
              ),
            ),
          ],
        ),
      ),
      if (parcours.isNotEmpty) ...<Widget>[
        Ecart.vXs,
        Text(
          parcours,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    ];
  }
}

/// La partie seance de la carte : le bloc seance, ou l'etat honnete qui le
/// remplace (chargement, echec, capacite absente, aucune seance).
class _Seance extends StatelessWidget {
  const _Seance({
    required this.profil,
    required this.seance,
    required this.maintenantServeurUtc,
    required this.compact,
    required this.onReessayer,
  });

  final ProfilEleveFoyer profil;
  final AsyncValue<SeanceFamille?> seance;
  final DateTime? maintenantServeurUtc;
  final bool compact;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    if (seance.hasError) {
      final bool indisponible = seance.error is CapaciteIndisponible;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(t.tuteur.accueil.seanceIllisible, style: discret),
          if (!indisponible)
            ActionPrincipale(
              libelle: t.commun.reessayer,
              onPress: onReessayer,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
            ),
        ],
      );
    }
    if (!seance.hasValue) {
      return const Skeleton(hauteur: AppSpacing.respiration * 2);
    }
    final SeanceFamille? laSeance = seance.value;
    if (laSeance == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            t.tuteur.accueil.aucuneSeance,
            style: palette.inkStrong.applyTo(
              textes.titleMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            t.tuteur.accueil.aucuneSeanceDetail(prenom: profil.prenom),
            style: discret,
          ),
        ],
      );
    }
    return BlocSeance(
      affichage: AffichageSeance.depuis(
        laSeance,
        maintenantServeurUtc: maintenantServeurUtc,
      ),
      compact: compact,
    );
  }
}
