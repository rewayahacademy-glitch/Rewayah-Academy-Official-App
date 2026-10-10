import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/recrutement/port_invitations_enseignant.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../brouillon_inscription.dart';
import '../inscription_page.dart';

/// `/inscription/usage` : deux cartes exactement, aucune preselection, aucune
/// carte « Autre » ; l'enseignant passe par un lien discret (mandat A,
/// 05_LOTS_PHASE1.md section A, sous-paquet 2).
class UsageEtape extends ConsumerWidget {
  /// Cree l'etape.
  const UsageEtape({super.key});

  static const String _route = Routes.inscriptionUsage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UsageInscription? usage = ref.watch(
      brouillonInscriptionProvider.select((BrouillonInscription b) => b.usage),
    );
    final BrouillonInscriptionControleur controleur = ref.read(
      brouillonInscriptionProvider.notifier,
    );

    // Une carte deja choisie reste retenue au retour ; l'enseignant n'est pas
    // une carte : on ne le montre pas comme une preselection.
    final UsageInscription? retenu = usage == UsageInscription.enseignant
        ? null
        : usage;

    return CoquilleEtape(
      route: _route,
      question: t.inscription.usage.question,
      libelleAction: t.commun.continuer,
      onAction: retenu == null ? null : () => avancerDepuis(context, _route),
      complement: Center(
        child: ActionPrincipale(
          key: const Key('inscription-lien-enseignant'),
          libelle: t.inscription.usage.enseignant,
          niveau: NiveauAction.tertiaire,
          pleineLargeur: false,
          onPress: () {
            controleur.choisirUsage(UsageInscription.enseignant);
            // RECRUT-ECRANS : des que le serveur verifie les invitations,
            // l'inscription enseignant exige un code valide (le serveur le
            // consomme a la creation du profil). Sans port, l'ancien parcours.
            final bool exigeCode =
                ref.read(portVerificationInvitationProvider) != null &&
                ref.read(codeInvitationRetenuProvider) == null;
            if (exigeCode) {
              context.go(Routes.inscriptionInvitation);
            } else {
              avancerDepuis(context, _route);
            }
          },
        ),
      ),
      // Le groupe partage (ADR-013), sans carte « Autre » : deux cartes
      // exactement, a description (demande B-3 levee par COORD).
      enfant: ChoiceCardGroup(
        key: const Key('inscription-usage'),
        autoriserSaisieLibre: false,
        valeurInitiale: retenu == null
            ? null
            : ReponseChoix(valeurs: <String>{retenu.name}),
        options: <OptionChoix>[
          OptionChoix(
            valeur: UsageInscription.moi.name,
            libelle: t.inscription.usage.moiTitre,
            description: t.inscription.usage.moiDescription,
            icone: AppIcons.profil,
          ),
          OptionChoix(
            valeur: UsageInscription.famille.name,
            libelle: t.inscription.usage.familleTitre,
            description: t.inscription.usage.familleDescription,
            icone: AppIcons.foyer,
          ),
        ],
        onChange: (ReponseChoix reponse) {
          for (final UsageInscription u in <UsageInscription>[
            UsageInscription.moi,
            UsageInscription.famille,
          ]) {
            if (reponse.valeurs.contains(u.name)) {
              controleur.choisirUsage(u);
            }
          }
        },
      ),
    );
  }
}
