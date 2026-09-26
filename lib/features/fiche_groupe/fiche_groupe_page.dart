import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/service_groupes.dart' show TypePublicGroupe;
import '../../core/enseignant/modeles_enseignant.dart';
import '../../core/enseignant/service_enseignant.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart' show Creneau;
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/status_pill.dart';

/// `ENS-07` : la fiche d'un groupe, telle que son enseignant la lit.
///
/// **Une pose, jamais une destination.** Elle s'ouvre depuis la Journee, par la
/// carte de seance, et vit donc hors de la coquille de navigation : elle porte
/// pour cela un chemin de sortie visible, en tete de page. L'enseignant a trois
/// destinations, et il atteint un groupe par le cours qu'il donne, pas par un
/// annuaire.
///
/// **Une fiche se lit, elle ne s'edite pas.** Aucune action principale : c'est
/// l'administration qui compose les groupes (`ADM-09`), et un bouton
/// « ajouter » ici serait une promesse que la base refuserait --
/// `groupe_membre_ajouter` est bornee a `app_role() = 'admin'`.
///
/// **Aucun nom de famille, aucun courriel, aucun telephone.** La garantie n'est
/// pas dans cet ecran mais dans le modele qu'il lit : [MembreSeance] n'a aucun
/// champ de nom de famille, il n'y a donc rien a oublier de masquer.
/// `MembreGroupe` (`core/admin/service_groupes.dart`) en porte un, parce que
/// l'administration en a le droit : il n'est pas employe ici (ADR-008).
///
/// Le `niveau` affiche vient de `student_profiles.level`, **un texte libre**.
/// Ce n'est pas le niveau institutionnel du programme, qui vit dans
/// `progression_historique` : le libelle dit « niveau indique », et jamais
/// « niveau du programme » (en-tete de `0021`).
class FicheGroupePage extends ConsumerWidget {
  /// Cree la fiche d'un groupe.
  const FicheGroupePage({required this.groupeId, super.key});

  /// Le groupe a montrer.
  final String groupeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageShell(
      titre: t.enseignant.ficheGroupe.titre,
      // Le chemin de sortie, visible et en haut : cet ecran n'a pas de barre de
      // navigation pour le porter.
      entete: const _Sortie(),
      child: _Corps(groupeId: groupeId),
    );
  }
}

/// Le retour vers la Journee.
class _Sortie extends StatelessWidget {
  const _Sortie();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ActionPrincipale(
        libelle: t.enseignant.ficheGroupe.retour,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
        // `go` et non `pop` : la fiche peut avoir ete ouverte par une adresse,
        // et une sortie qui ne fonctionne que sur une pile existante laisserait
        // l'enseignant enferme.
        onPress: () => GoRouter.of(context).go(Routes.enseignantJournee),
      ),
    );
  }
}

/// Les cinq etats de la fiche, plus « ce groupe n'est pas le votre ».
class _Corps extends ConsumerWidget {
  const _Corps({required this.groupeId});

  final String groupeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<GroupeEnseignant>> groupes = ref.watch(
      groupesEnseignantProvider,
    );
    final AsyncValue<List<MembreSeance>> membres = ref.watch(
      membresGroupeEnseignantProvider(groupeId),
    );

    if (groupes.hasError || membres.hasError) {
      return EmptyState(
        message: t.enseignant.ficheGroupe.erreur,
        icone: AppIcons.avertissement,
        libelleAction: t.commun.reessayer,
        onAction: () {
          ref.invalidate(groupesEnseignantProvider);
          ref.invalidate(membresGroupeEnseignantProvider(groupeId));
        },
      );
    }

    if (!groupes.hasValue || !membres.hasValue) {
      // Le squelette prend la forme de ce qui arrive : l'en-tete du groupe,
      // puis trois lignes de membre.
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Skeleton.tuileBento(hauteur: 140),
          Ecart.vXl,
          Skeleton.liste(lignes: 3),
        ],
      );
    }

    GroupeEnseignant? trouve;
    for (final GroupeEnseignant groupe in groupes.requireValue) {
      if (groupe.id == groupeId) {
        trouve = groupe;
      }
    }
    final GroupeEnseignant? groupe = trouve;

    if (groupe == null) {
      // `mes_groupes_v` ne rend que les groupes actifs de l'appelant : une
      // absence ici n'est pas une erreur de lecture, c'est un groupe cloture ou
      // celui d'un collegue. Un etat subi : l'enseignant ne peut rien y faire.
      return EmptyState(
        message: t.enseignant.ficheGroupe.introuvable,
        invitation: t.enseignant.ficheGroupe.introuvableDetail,
        icone: AppIcons.rienAAfficher,
        registre: RegistreVide.subi,
      );
    }

    final Widget entete = _EnteteGroupe(groupe: groupe);
    final Widget liste = _Membres(membres: membres.requireValue);
    final Widget revue = Align(
      alignment: AlignmentDirectional.centerStart,
      child: ActionPrincipale(
        libelle: t.enseignant.ficheGroupe.revue,
        niveau: NiveauAction.tertiaire,
        pleineLargeur: false,
        onPress: () => GoRouter.of(context).go(Routes.revuePour(groupe.id)),
      ),
    );

    // [RESPONSIVE] Deux colonnes a partir de 1200 : le groupe et son creneau a
    // gauche, ses eleves a droite. En dessous, une seule colonne -- c'est la ou
    // l'enseignant lit, et une fiche coupee en deux sur 390 de large ne se lit
    // pas.
    if (AppGabarit.de(context) == Gabarit.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[entete, Ecart.vXl, revue],
            ),
          ),
          Ecart.hXl,
          Expanded(child: liste),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[entete, Ecart.vXl, liste, Ecart.vXl, revue],
    );
  }
}

/// Le groupe, son public, son rendez-vous hebdomadaire et ses places libres.
class _EnteteGroupe extends StatelessWidget {
  const _EnteteGroupe({required this.groupe});

  final GroupeEnseignant groupe;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BentoTile(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      groupe.libelle,
                      style: textes.headlineSmall ?? const TextStyle(),
                    ),
                  ),
                  if (groupe.complet)
                    StatusPill(
                      libelle: t.enseignant.ficheGroupe.complet,
                      ton: TonEtat.avertissement,
                    ),
                ],
              ),
              Ecart.vXs,
              Text(
                _nomType(groupe.type),
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
              Ecart.vLg,
              Text(
                t.enseignant.ficheGroupe.creneauTitre,
                style: textes.labelLarge ?? const TextStyle(),
              ),
              Ecart.vXs,
              // Une seule visio commune par semaine depuis le pivot : le
              // creneau du groupe EST l'heure du cours.
              Text(
                t.enseignant.ficheGroupe.creneauHebdo(
                  jour: _jour(groupe.creneau),
                  heure: _heure(groupe.creneau),
                ),
                style: textes.titleMedium ?? const TextStyle(),
              ),
            ],
          ),
        ),
        Ecart.vMd,
        // Le seuil affiche est celui du groupe, jamais un chiffre calcule ici :
        // cinq enfants, six adultes, et c'est la base qui le tient. Le zero
        // s'affiche comme les autres valeurs.
        //
        // Sans `onPress` : l'enseignant ne compose pas son groupe, ce compteur
        // est un constat, et il n'existe aucun ecran d'action ou le mener.
        StatTile(
          valeur: groupe.placesLibres,
          libelle: groupe.placesLibres == 1
              ? t.enseignant.ficheGroupe.placesLibresUn
              : t.enseignant.ficheGroupe.placesLibres,
          ton: groupe.complet ? TonEtat.avertissement : TonEtat.neutre,
        ),
      ],
    );
  }
}

/// Les eleves du groupe, ou le fait qu'il n'y en ait aucun.
class _Membres extends StatelessWidget {
  const _Membres({required this.membres});

  final List<MembreSeance> membres;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          titre: t.enseignant.ficheGroupe.membresTitre,
          compteur: membres.length,
        ),
        Ecart.vMd,
        if (membres.isEmpty)
          EmptyState(
            message: t.enseignant.ficheGroupe.aucunMembre,
            invitation: t.enseignant.ficheGroupe.aucunMembreDetail,
            icone: AppIcons.rienAAfficher,
            // Un etat subi : c'est l'administration qui compose les groupes,
            // l'enseignant ne peut pas y remedier. Aucun bouton, donc.
            registre: RegistreVide.subi,
          )
        else
          for (final MembreSeance membre in membres)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _LigneMembre(membre: membre),
            ),
      ],
    );
  }
}

/// Un eleve : son prenom, son identifiant immuable, son niveau indique.
///
/// Non actionnable, donc ni `SignalRow` ni `Pressable` : depuis la fiche, un
/// eleve ne mene a aucun ecran que l'enseignant ait le droit d'ouvrir. La ligne
/// est lue **d'un bloc** par les technologies d'assistance, sinon trois textes
/// se liraient comme trois elements sans rapport.
class _LigneMembre extends StatelessWidget {
  const _LigneMembre({required this.membre});

  final MembreSeance membre;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String? niveau = membre.niveau;

    return MergeSemantics(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // `libelle` rend le prenom, ou l'identifiant immuable quand la base
            // l'a masque en observation : un eleve reste designable.
            Text(membre.libelle, style: textes.titleSmall ?? const TextStyle()),
            Ecart.vXs,
            // L'identifiant immuable ne se coupe pas : c'est le seul moyen de
            // nommer un eleve sans nom de famille, y compris a 200 % de taille
            // de texte. [A11Y]
            Text(
              membre.identifiantImmuable,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
            if (niveau != null && niveau.trim().isNotEmpty) ...<Widget>[
              Ecart.vXs,
              Text(
                t.enseignant.ficheGroupe.niveauIndique(niveau: niveau.trim()),
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Le nom du public d'un groupe.
///
/// Les deux libelles existent deja sous `admin.groupes.*` : en declarer des
/// jumeaux sous `enseignant.*` donnerait deux cles pour le meme mot.
String _nomType(TypePublicGroupe type) => switch (type) {
  TypePublicGroupe.enfant => t.admin.groupes.typeEnfant,
  TypePublicGroupe.adulte => t.admin.groupes.typeAdulte,
};

/// Le jour du creneau, en clair. `t.disponibilites.joursLongs` est lu par sept
/// ecrans : c'est la seule liste de jours du produit.
String _jour(Creneau creneau) => t.disponibilites.joursLongs[creneau.jour - 1];

/// L'heure pleine du creneau, sur deux chiffres.
///
/// Un entier, pas un instant : ce n'est donc pas le formatage `HH:MM` d'une
/// `DateTime` qui existe deja deux fois dans le depot, et il n'y a rien a
/// reutiliser ici.
String _heure(Creneau creneau) =>
    '${creneau.heure.toString().padLeft(2, '0')}:00';
