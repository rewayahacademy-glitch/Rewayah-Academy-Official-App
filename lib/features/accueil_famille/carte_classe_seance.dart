import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_classes_foyer.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/skeleton.dart';
import 'bloc_seance.dart';

/// La carte classe de l'Accueil : l'eleve, sa classe et son enseignant, la
/// prochaine seance ; **la carte entiere est le lien** vers la classe
/// (DASH-TUT-CTA, DASH_STRATEGIE §3.4, D4, D5) : plus de bouton plein
/// « Voir la classe », pour qu'un blocage puisse porter le seul bouton
/// primaire de l'ecran.
///
/// Maquettes V1 (telephone) et V2 (tablette, bureau) ; manifeste, composants
/// « Carte classe » et « Bloc seance ». Aucune action concurrente : le lien
/// « fournir une photo » de la maquette V1 n'est pas repris (defaut C3, un
/// seul blocage, et aucune regle de photo en base, point P6).
///
/// **La carte n'est un lien que si la classe est connue** : sans identifiant
/// de classe, elle ne pourrait mener nulle part (`lib/CLAUDE.md`).
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
    // La carte n'est un lien que sans bouton « Reessayer » dedans : jamais un
    // bouton dans un bouton.
    final bool lien = laClasse != null && !classe.hasError && !seance.hasError;
    // Sans classe lisible, la carte n'est pas un bouton grise : elle n'est
    // simplement pas un lien (lib/CLAUDE.md).
    VoidCallback? ouvrir;
    if (lien) {
      ouvrir = () => onVoirClasse(laClasse.classe.groupeId);
    }

    return AppCard(
      onPress: ouvrir,
      libelleSemantique: lien ? t.tuteur.accueil.voirLaClasse : null,
      // Elle mene a la classe, elle n'engage rien : un lien, pas un bouton.
      lien: lien,
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
          if (!compact && seance.value != null) ...<Widget>[
            Ecart.vLg,
            const ConseilAppareil(),
          ],
          // L'indice du lien, pas un bouton : la carte entiere s'ouvre. Il ferme
          // la carte, sous le conseil appareil du bureau (DASH-TUT-CTA-b).
          if (lien) ...<Widget>[
            Ecart.vXl,
            ExcludeSemantics(
              child: Row(
                key: const ValueKey<String>('carte-classe-indice-lien'),
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Flexible(
                    child: TexteSansCoupure(
                      t.tuteur.accueil.voirLaClasse,
                      style: palette.inkAccent.applyTo(
                        Theme.of(context).textTheme.labelLarge ??
                            const TextStyle(),
                      ),
                    ),
                  ),
                  Ecart.hXs,
                  IconTheme(
                    data: palette.inkAccent.asIconTheme(size: AppSpacing.lg),
                    child: Icon(AppIcons.flecheAction.repos),
                  ),
                ],
              ),
            ),
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

    // AVATAR-1 : l'eleve est un couple avatar + prenom du composant partage
    // (prenom centre sur le cercle) ; la classe et l'enseignant se lisent
    // dessous, ils ne sont pas le texte de l'avatar.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          header: true,
          child: AvatarNom.enLigne(
            prenom: profil.prenom,
            urlSignee: urlPhotoEleve,
            diametre: compact
                ? SelecteurProfils.diametreMobile
                : SelecteurProfils.diametreLarge,
            styleNom: palette.inkStrong.applyTo(
              textes.titleLarge ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        ..._classe(context, palette, textes),
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
      // Photo publique de l'enseignant quand l'hote sait la resoudre
      // (DB-CRS-09), sinon son initiale : jamais le portrait de l'eleve a sa
      // place.
      MergeSemantics(
        child: AvatarNom.enLigne(
          prenom: c.enseignant.nomAffichage,
          nom: LibellesGroupe.enseignantNomme(c.enseignant),
          pays: c.enseignant.pays,
          diametre: AppAvatar.petit,
          ecart: AppSpacing.sm,
          styleNom: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
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
