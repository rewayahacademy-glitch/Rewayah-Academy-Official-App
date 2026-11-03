import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;
import 'invitation_conjoint.dart';
import 'role_foyer.dart';
import 'routes_n2_foyer_adulte.dart';

/// En tete du Foyer et de l'accueil du tuteur (N2, FA2 et FA3) : ce qui
/// attend la reponse de la personne connectee. L'invitation recue
/// (`mon_invitation_en_cours` rend `a_repondre`) et la demande de reprise que
/// le titulaire peut refuser (`etat_reprise_foyer` rend `a_refuser`). Rien
/// d'autre : sans lecture, en chargement ou en echec, aucune carte (le reste
/// de la page ne depend pas d'elles).
class AlertesSecondAdulte extends ConsumerWidget {
  /// Cree les alertes.
  const AlertesSecondAdulte({
    required this.aller,
    super.key,
    this.avecReprise = true,
  });

  /// Ouvre un chemin (le routeur par defaut de l'ecran hote).
  final void Function(String chemin) aller;

  /// Faux sur l'accueil du tuteur : la demande de reprise se lit au Foyer
  /// seulement (decision du pilote du 03/11/2026, Q3).
  final bool avecReprise;

  /// La carte de l'invitation recue.
  static const Key invitationKey = Key('foyer.n2.invitationRecue');

  /// La carte de la demande de reprise a refuser.
  static const Key repriseKey = Key('foyer.n2.repriseATraiter');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EtatInvitationRecue? invitation = ref
        .watch(invitationRecueProvider)
        .value;
    final DemandeRepriseRecue? reprise = avecReprise
        ? ref.watch(demandeRepriseRecueProvider).value
        : null;
    final List<Widget> cartes = <Widget>[
      if (invitation case final InvitationARepondre a)
        BandeauAttention(
          key: invitationKey,
          ton: TonEtat.accent,
          titre: t.adulte.acceptation.notification(prenom: a.prenomTitulaire),
          message: t.foyer.n2.invitationRecueMessage,
          action: LienFleche(
            libelle: t.foyer.n2.invitationRecueVoir,
            onPress: () => aller(RoutesN2.foyerInvitation),
          ),
        ),
      if (reprise is RepriseARefuser)
        BandeauAttention(
          key: repriseKey,
          titre: t.adulte.reprise.titulaire.ligne,
          message: t.adulte.reprise.titulaire.consigne,
          action: LienFleche(
            libelle: t.foyer.n2.repriseATraiterVoir,
            onPress: () => aller(RoutesN2.foyerRepriseTitulaire),
          ),
        ),
    ];
    if (cartes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.lg,
        children: cartes,
      ),
    );
  }
}

/// Dans le Foyer (N2, FA1 et FA3) : « Inviter un second adulte » pour le
/// titulaire, « Demander la reprise du foyer » pour le second adulte, selon
/// la capacite rendue par `mon_role_foyer()`, jamais selon un role devine.
/// Sans lecture : aucune ligne.
class LignesSecondAdulte extends ConsumerWidget {
  /// Cree les lignes.
  const LignesSecondAdulte({required this.aller, super.key});

  /// Ouvre un chemin.
  final void Function(String chemin) aller;

  /// La ligne « Inviter … ».
  static const Key inviterKey = Key('foyer.n2.inviter');

  /// La ligne « Demander la reprise du foyer ».
  static const Key repriseKey = Key('foyer.n2.demanderReprise');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RoleFoyerLu? lu = ref.watch(roleFoyerProvider).value;
    final LigneRubrique? ligne = switch (lu?.role) {
      RoleFoyer.titulaire => LigneRubrique(
        icone: AppIcons.invitationEnvoyee,
        libelle: switch (lu!.placeFeminine) {
          true => t.adulte.invitation.titreElle,
          false => t.adulte.invitation.titreLui,
          null => t.adulte.invitation.titreNeutre,
        },
        onPress: () => aller(RoutesN2.foyerInviter),
      ),
      RoleFoyer.secondAdulte => LigneRubrique(
        icone: AppIcons.foyer,
        libelle: t.foyer.n2.demanderReprise,
        legende: t.foyer.n2.demanderRepriseLegende,
        onPress: () => aller(RoutesN2.foyerReprise),
      ),
      _ => null,
    };
    if (ligne == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: GroupeReglages(
        key: lu!.role == RoleFoyer.titulaire ? inviterKey : repriseKey,
        titre: t.adulte.famille.forfaitFamille,
        lignes: <LigneRubrique>[ligne],
      ),
    );
  }
}
