import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/presence/service_presence.dart';
import '../../core/presence/vue_presence.dart';
import '../../core/seance_famille/seance_famille.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_color_pair.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/ligne_presence.dart';
import '../../core/widgets/selecteur_profils.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../accueil_famille/bloc_seance.dart';
import 'bloc_observation_classe.dart';
import 'contexte_classe.dart';

/// Le bandeau d'etat de la seance, en une ligne : ce que la seance est, et a
/// droite ce qui l'accompagne (compte a rebours, presence de l'eleve).
///
/// **Pure** : calcule depuis [AffichageSeance] (la meme fonction que l'Accueil,
/// pour que les deux ecrans disent la meme chose de la meme seance) et la
/// presence deja mise en mots.
({String gauche, String? droite, TonEtat ton}) bandeauSeance(
  AffichageSeance affichage, {
  String? presence,
}) => switch (affichage.etat) {
  EtatSeanceFamille.salleOuverte => (
    gauche: LibellesGroupe.salleOuverteCourt,
    droite: affichage.ligneEtat,
    ton: TonEtat.succes,
  ),
  EtatSeanceFamille.enDirect || EtatSeanceFamille.prolongee => (
    gauche: affichage.ligneEtat,
    droite: presence,
    ton: TonEtat.succes,
  ),
  EtatSeanceFamille.aVenir => (
    gauche: affichage.ligneEtat,
    droite: null,
    ton: TonEtat.accent,
  ),
  EtatSeanceFamille.annulee || EtatSeanceFamille.annuleeTardive => (
    gauche: affichage.ligneEtat,
    droite: null,
    ton: TonEtat.alerte,
  ),
  EtatSeanceFamille.nonTenue || EtatSeanceFamille.reportee => (
    gauche: affichage.ligneEtat,
    droite: null,
    ton: TonEtat.avertissement,
  ),
  EtatSeanceFamille.terminee || EtatSeanceFamille.horaireIncertain => (
    gauche: affichage.ligneEtat,
    droite: null,
    ton: TonEtat.neutre,
  ),
};

/// Vrai quand la salle est ouverte ou la seance en direct : la presence de
/// l'eleve se lit alors (indicative, jamais une absence deduite).
bool presenceUtile(EtatSeanceFamille etat) => switch (etat) {
  EtatSeanceFamille.salleOuverte ||
  EtatSeanceFamille.enDirect ||
  EtatSeanceFamille.prolongee => true,
  _ => false,
};

/// La carte principale de la Classe (maquette M1) : l'enseignant (photo
/// publique ou initiale, Sayyid / Sayyida), la classe et le parcours ; puis
/// la prochaine seance (bandeau d'etat, jour et heure, duree) ; puis
/// l'observation.
///
/// **Un seul rectangle** ; la seance n'est pas une carte dans la carte.
/// Telephone : surface elevee ; tablette et bureau : surface mise en avant,
/// comme la carte de l'Accueil (manifeste : seul le format change la
/// composition, jamais le theme).
class CarteSeanceClasse extends ConsumerWidget {
  /// Cree la carte.
  const CarteSeanceClasse({
    required this.contexte,
    required this.seance,
    required this.maintenantServeurUtc,
    required this.compact,
    required this.onReessayerSeance,
    super.key,
  });

  /// La classe et l'eleve.
  final ContexteClasse contexte;

  /// La prochaine seance de l'eleve dans cette classe (K2).
  final AsyncValue<SeanceFamille?> seance;

  /// L'instant serveur, `null` sans horloge serveur.
  final DateTime? maintenantServeurUtc;

  /// Vrai sur telephone.
  final bool compact;

  /// Relit la seance.
  final VoidCallback onReessayerSeance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    return AppCard(
      surface: compact ? palette.surfaceRaised : palette.surfaceMiseEnAvant,
      marge: compact ? AppSpacing.lg : AppSpacing.xxl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Enseignant(classe: contexte.classe.classe, compact: compact),
          Ecart.vLg,
          ..._seance(context, ref),
        ],
      ),
    );
  }

  List<Widget> _seance(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle discret = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    if (seance.hasError) {
      return <Widget>[
        Text(t.classe.seance.illisible, style: discret),
        if (seance.error is! CapaciteIndisponible)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              libelle: t.commun.reessayer,
              onPress: onReessayerSeance,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
            ),
          ),
      ];
    }
    if (!seance.hasValue) {
      return const <Widget>[Skeleton(hauteur: AppSpacing.respiration * 2)];
    }
    final SeanceFamille? laSeance = seance.value;
    if (laSeance == null) {
      return <Widget>[
        Text(
          t.classe.seance.aucune,
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(
          t.classe.seance.aucuneDetail(prenom: contexte.eleve.prenom),
          style: discret,
        ),
      ];
    }

    final AffichageSeance affichage = AffichageSeance.depuis(
      laSeance,
      maintenantServeurUtc: maintenantServeurUtc,
    );
    final EtatPresence? presence = presenceUtile(affichage.etat)
        ? maPresence(
            ref.watch(presenceSeanceProvider(laSeance.seanceId)).value,
            contexte.eleveId,
          )?.etat
        : null;
    final ({String gauche, String? droite, TonEtat ton}) bandeau =
        bandeauSeance(
          affichage,
          presence: presenceUtile(affichage.etat)
              ? t.classe.seance.presence(
                  prenom: contexte.eleve.prenom,
                  etat: LignePresence.libelle(presence ?? EtatPresence.inconnu),
                )
              : null,
        );

    return <Widget>[
      _Bandeau(
        gauche: bandeau.gauche,
        droite: bandeau.droite,
        ton: bandeau.ton,
        compact: compact,
      ),
      Ecart.vLg,
      _Heures(affichage: affichage, compact: compact),
      if (affichage.heureClasse != null) ...<Widget>[
        Ecart.vSm,
        Text(affichage.heureClasse!, style: discret),
      ],
      Ecart.vXl,
      BlocObservationClasse(
        classeId: contexte.classeId,
        eleveId: contexte.eleveId,
        prenom: contexte.eleve.prenom,
        seance: laSeance,
        etat: affichage.etat,
        presence: presence,
      ),
    ];
  }
}

/// L'enseignant et la classe : photo publique de l'enseignant (DB-CRS-09 :
/// son initiale tant qu'aucun service ne resout la photo, jamais le portrait
/// de l'eleve), nom de la classe, « Sayyid / Sayyida » et prenom, parcours.
class _Enseignant extends StatelessWidget {
  const _Enseignant({required this.classe, required this.compact});

  final GroupSummaryVM classe;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String parcours = LibellesGroupe.coursEtNiveau(
      cours: classe.nomCours,
      niveau: classe.niveauHumain,
    );
    return MergeSemantics(
      child: Row(
        children: <Widget>[
          AvatarTile(
            prenom: classe.enseignant.nomAffichage,
            diametre: SelecteurProfils.diametreLarge,
          ),
          Ecart.hLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  classe.libelle,
                  style: palette.inkStrong.applyTo(
                    (compact ? textes.titleMedium : textes.titleLarge) ??
                        const TextStyle(),
                  ),
                ),
                Ecart.vXs,
                Text(
                  LibellesGroupe.enseignantNomme(classe.enseignant),
                  style: palette.inkMuted.applyTo(
                    textes.bodyLarge ?? const TextStyle(),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Le bandeau d'etat pleine largeur : un point, l'etat, et a droite ce qui
/// l'accompagne. Le point double toujours un mot (jamais la couleur seule).
class _Bandeau extends StatelessWidget {
  const _Bandeau({
    required this.gauche,
    required this.droite,
    required this.ton,
    required this.compact,
  });

  final String gauche;
  final String? droite;
  final TonEtat ton;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AppColorPair paire = palette.paireDe(ton);
    final BoxDecoration point = switch (ton) {
      TonEtat.succes => palette.pointsStatut.succes.pastille(),
      TonEtat.avertissement => palette.pointsStatut.attention.pastille(),
      TonEtat.alerte => palette.pointsStatut.alerte.pastille(),
      TonEtat.neutre => palette.pointsStatut.neutre.pastille(),
      TonEtat.accent => BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surfacePrimary.background,
      ),
    };
    return MergeSemantics(
      child: DecoratedBox(
        decoration: paire.decoration(borderRadius: AppRadius.arrondiSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: StatusPill.diametrePastille,
                child: DecoratedBox(decoration: point),
              ),
              Ecart.hSm,
              // L'etat au debut, l'accompagnement au bout de la ligne ; quand
              // les deux ne tiennent pas (texte agrandi, colonne etroite),
              // l'accompagnement passe dessous, sans rien couper.
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    Text(
                      gauche,
                      style: paire.applyTo(
                        AppTypography.tabulaire(
                          (compact ? textes.labelLarge : textes.titleSmall) ??
                              const TextStyle(),
                        ),
                      ),
                    ),
                    if (droite != null)
                      Text(
                        droite!,
                        style: paire.applyTo(
                          AppTypography.tabulaire(
                            (compact ? textes.bodySmall : textes.bodyMedium) ??
                                const TextStyle(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Jour et heure, puis duree, en deux colonnes a medaillon separees par un
/// filet vertical (M1). L'heure est celle rendue par le serveur dans le
/// fuseau du foyer ; sans horloge serveur, celle de l'appareil, **dite comme
/// telle** (jamais un fuseau devine).
class _Heures extends StatelessWidget {
  const _Heures({required this.affichage, required this.compact});

  final AffichageSeance affichage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: _Colonne(
              icone: AppIcons.journee,
              libelle: affichage.date,
              valeur: affichage.ville == null
                  ? affichage.heure
                  : LibellesGroupe.heureEtVille(
                      heure: affichage.heure,
                      ville: affichage.ville!,
                    ),
              complement: affichage.ville == null ? affichage.fuseau : null,
              compact: compact,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.md),
              // Le filet vertical, comme les autres separateurs
              // (`contourCarte`), jamais plus fonce (manifeste, bloc seance).
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    start: palette.contourCarte.asBorderSide(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.md,
                  ),
                  child: _Colonne(
                    icone: AppIcons.attente,
                    libelle: LibellesGroupe.dureeLibelle,
                    valeur: affichage.duree,
                    compact: compact,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Colonne extends StatelessWidget {
  const _Colonne({
    required this.icone,
    required this.libelle,
    required this.valeur,
    required this.compact,
    this.complement,
  });

  final AppIcon icone;
  final String libelle;
  final String valeur;
  final String? complement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    // Tablette et bureau : le corps a 14 et la valeur a 22 (manifeste,
    // typographie : legende et chiffre d'horaire du bureau).
    final TextStyle discret = palette.inkMuted.applyTo(
      (compact ? textes.bodySmall : textes.bodyMedium) ?? const TextStyle(),
    );
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: AppSpacing.section,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.washAccent.background,
                ),
                child: Center(
                  child: IconTheme(
                    data: palette.inkAccent.asIconTheme(size: AppSpacing.xl),
                    child: Icon(icone.repos),
                  ),
                ),
              ),
            ),
          ),
          Ecart.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(libelle, style: discret),
                Text(
                  valeur,
                  style: AppTypography.tabulaire(
                    palette.inkStrong.applyTo(
                      (compact ? textes.titleMedium : textes.titleLarge) ??
                          const TextStyle(),
                    ),
                  ),
                ),
                if (complement != null) Text(complement!, style: discret),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
