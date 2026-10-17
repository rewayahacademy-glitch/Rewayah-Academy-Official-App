import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/recrutement/port_invitations_enseignant.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../brouillon_inscription.dart';
import '../inscription_page.dart';

/// `/inscription/usage` : deux cartes exactement, aucune preselection, aucune
/// carte « Autre » ; l'enseignant passe par un lien discret vers le code
/// d'invitation (mandat A, 05_LOTS_PHASE1.md section A, sous-paquet 2 ; L1-11).
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

    final bool? suitDesCours = ref.watch(
      brouillonInscriptionProvider.select(
        (BrouillonInscription b) => b.parentSuitDesCours,
      ),
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
      onAction:
          retenu == null ||
              (retenu == UsageInscription.famille && suitDesCours == null)
          ? null
          : () => avancerDepuis(context, _route),
      // L1-11 (A-07, option 1) : l'enseignant n'entre que par invitation. Une
      // phrase dit pourquoi il n'y a pas de carte, et le lien ouvre le champ du
      // code ; jamais de bouton grise (K-59).
      complement: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            t.inscription.usage.enseignantInvite,
            key: const Key('inscription-enseignant-invite'),
            textAlign: TextAlign.center,
            style: AppPalette.of(context).inkMuted.applyTo(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
          ),
          Center(
            child: ActionPrincipale(
              key: const Key('inscription-lien-enseignant'),
              libelle: t.inscription.usage.enseignant,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: () {
                controleur.choisirUsage(UsageInscription.enseignant);
                // Le serveur refuse tout profil enseignant sans code valide :
                // sans code retenu, on ouvre toujours le champ du code (si la
                // verification n'est pas branchee, l'ecran le dit).
                if (ref.read(codeInvitationRetenuProvider) == null) {
                  context.go(Routes.inscriptionInvitation);
                } else {
                  avancerDepuis(context, _route);
                }
              },
            ),
          ),
        ],
      ),
      // Le groupe partage (ADR-013), sans carte « Autre » : deux cartes
      // exactement, a description (demande B-3 levee par COORD).
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ChoiceCardGroup(
            key: const Key('inscription-usage'),
            autoriserSaisieLibre: false,
            valeurInitiale: retenu == null
                ? null
                : ReponseChoix(valeurs: <String>{retenu.name}),
            options: <OptionChoix>[
              // Lot E2 : chaque option s'explique, avec un exemple, et
              // s'illustre en bento sur grand ecran.
              OptionChoix(
                valeur: UsageInscription.moi.name,
                libelle: t.inscription.usage.moiTitre,
                explication: t.inscription.usage.moiDescription,
                exemple: t.inscription.usage.moiExemple,
                icone: AppIcons.profil,
                illustration: const IllustrationChoix(
                  AppIcons.profil,
                  autour: <AppIcon>[AppIcons.livreOuvert, AppIcons.horloge],
                ),
              ),
              OptionChoix(
                valeur: UsageInscription.famille.name,
                libelle: t.inscription.usage.familleTitre,
                explication: t.inscription.usage.familleDescription,
                exemple: t.inscription.usage.familleExemple,
                icone: AppIcons.foyer,
                illustration: const IllustrationChoix(
                  AppIcons.foyer,
                  autour: <AppIcon>[
                    AppIcons.eleves,
                    AppIcons.livreOuvert,
                    AppIcons.suivi,
                  ],
                ),
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
          if (retenu == UsageInscription.famille) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              t.inscription.usage.coursQuestion,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ChoiceCardGroup(
              key: const Key('inscription-parent-suit-des-cours'),
              autoriserSaisieLibre: false,
              coteACote: true,
              valeurInitiale: suitDesCours == null
                  ? null
                  : ReponseChoix(
                      valeurs: <String>{suitDesCours ? 'oui' : 'non'},
                    ),
              options: <OptionChoix>[
                OptionChoix(
                  valeur: 'oui',
                  libelle: t.inscription.usage.coursOui,
                  explication: t.inscription.usage.coursOuiExplication,
                  exemple: t.inscription.usage.coursOuiExemple,
                  icone: AppIcons.livreOuvert,
                  illustration: const IllustrationChoix(
                    AppIcons.livreOuvert,
                    autour: <AppIcon>[AppIcons.profil, AppIcons.eleves],
                  ),
                ),
                OptionChoix(
                  valeur: 'non',
                  libelle: t.inscription.usage.coursNon,
                  explication: t.inscription.usage.coursNonExplication,
                  exemple: t.inscription.usage.coursNonExemple,
                  icone: AppIcons.suivi,
                  illustration: const IllustrationChoix(
                    AppIcons.suivi,
                    autour: <AppIcon>[AppIcons.eleves],
                  ),
                ),
              ],
              onChange: (ReponseChoix reponse) {
                if (reponse.valeurs.contains('oui')) {
                  controleur.choisirParentSuitDesCours(suit: true);
                } else if (reponse.valeurs.contains('non')) {
                  controleur.choisirParentSuitDesCours(suit: false);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
