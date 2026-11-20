import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/candidature/port_inscription_candidat.dart';
import '../../../core/equipe/port_inscription_associe.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/recrutement/port_invitations_comptable.dart';
import '../../../core/recrutement/port_invitations_enseignant.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../brouillon_inscription.dart';
import '../code_comptable_retenu.dart';
import '../inscription_page.dart';
import '../questionnaire/questionnaire_inscription.dart';

/// Les deux portes de l'entree (PE-A3, 20/11/2026 ; standard « ecran a
/// deux portes » du plan du parcours de l'enseignant, §6).
enum PorteEntree {
  /// Suivre les cours, pour soi ou pour son enfant.
  apprendre,

  /// Deposer sa candidature d'enseignant.
  enseigner,
}

/// `/inscription/usage` : d'abord deux grandes cartes de meme poids,
/// « Apprendre » et « Enseigner », sans preselection (PE-A3). « Apprendre »
/// ouvre ensuite les deux cartes « pour moi » / « mon enfant » (mandat A,
/// 05_LOTS_PHASE1.md section A, sous-paquet 2 ; L1-11) ; « Enseigner » mene
/// au parcours de candidature qui existe deja (identite quand le serveur
/// ouvre l'entree sans code, sinon le champ du code).
class UsageEtape extends ConsumerStatefulWidget {
  /// Cree l'etape.
  const UsageEtape({super.key});

  /// La cle du groupe des deux portes.
  static const Key portesKey = Key('inscription-portes');

  @override
  ConsumerState<UsageEtape> createState() => _UsageEtapeState();
}

class _UsageEtapeState extends ConsumerState<UsageEtape> {
  static const String _route = Routes.inscriptionUsage;

  /// La porte touchee, pas encore confirmee par « Continuer ».
  PorteEntree? _porte;

  /// Vrai une fois « Apprendre » confirme. Une carte « pour moi » / « mon
  /// enfant » deja choisie (retour depuis l'identite) y ramene directement.
  late bool _apprendre = switch (ref.read(brouillonInscriptionProvider).usage) {
    UsageInscription.moi || UsageInscription.famille => true,
    _ => false,
  };

  @override
  Widget build(BuildContext context) {
    final UsageInscription? usage = ref.watch(
      brouillonInscriptionProvider.select((BrouillonInscription b) => b.usage),
    );
    final BrouillonInscriptionControleur controleur = ref.read(
      brouillonInscriptionProvider.notifier,
    );

    // Une carte deja choisie reste retenue au retour ; l'enseignant n'est pas
    // une carte : on ne le montre pas comme une preselection.
    final UsageInscription? retenu =
        usage == UsageInscription.enseignant ||
            usage == UsageInscription.comptable
        ? null
        : usage;
    // Lot F2 : le lien du comptable n'existe que si le serveur verifie ses
    // codes (capacite servie, jamais un role).
    final bool comptableInvitable =
        ref.watch(portVerificationInvitationComptableProvider) != null;
    // Suite de BE-2a-2 : le lien d'un associe invite, tant que l'adaptateur du
    // serveur est branche ; sans lui, il ne pourrait pas aboutir.
    final bool associeInvitable =
        ref.watch(portInscriptionAssocieProvider) != null;
    // CAND-04 : quand le serveur ouvre l'inscription sans code, « Enseigner »
    // mene a l'identite ; sinon (fermee, illisible, lot absent), au champ du
    // code : l'academie invite par courriel, et le code est la seule entree.
    final bool sansCodeOuvert =
        ref.watch(ouvertureInscriptionCandidatProvider).value?.ouverte ?? false;
    // Une lecture ratee par panne de reseau est relue au retour de la
    // connexion : l'entree sans code ne reste pas fermee toute la session.
    ref.listen<AsyncValue<bool>>(horsLigneProvider, (
      AsyncValue<bool>? avant,
      AsyncValue<bool> apres,
    ) {
      if ((avant?.value ?? false) && !(apres.value ?? false)) {
        ref.invalidate(ouvertureInscriptionCandidatProvider);
      }
    });

    void deposerSansCode() {
      controleur.deposerSansCode();
      // Sans code : tout code deja verifie est mis de cote, pour que la porte
      // de l'inscription ne soit jamais ambigue.
      ref.read(codeInvitationRetenuProvider.notifier).oublier();
      context.go(Routes.inscriptionIdentite);
    }

    void versLeCodeEnseignant() {
      controleur.choisirUsage(UsageInscription.enseignant);
      // Le serveur refuse tout profil enseignant sans code valide : sans code
      // retenu, on ouvre toujours le champ du code (si la verification n'est
      // pas branchee, l'ecran le dit).
      if (ref.read(codeInvitationRetenuProvider) == null) {
        context.go(Routes.inscriptionInvitation);
      } else {
        avancerDepuis(context, ref.read(brouillonInscriptionProvider), _route);
      }
    }

    if (!_apprendre) {
      return _portes(
        comptableInvitable: comptableInvitable,
        associeInvitable: associeInvitable,
        onEnseigner: sansCodeOuvert ? deposerSansCode : versLeCodeEnseignant,
        onCodeEnseignant: versLeCodeEnseignant,
        controleur: controleur,
      );
    }

    return CoquilleEtape(
      route: _route,
      choix: true,
      question: t.inscription.usage.question,
      libelleAction: t.commun.continuer,
      // PE-A3 : l'espace porte son nom en haut ; le retour ramene aux portes.
      espace: t.inscription.porte.espaceEleve,
      onRetour: () => setState(() {
        _apprendre = false;
        _porte = null;
      }),
      // Admission, lot B : « pour moi » et « mon enfant » continuent dans le
      // questionnaire (`/commencer`), qui revient ici une fois repondu.
      onAction: retenu == null
          ? null
          : () {
              ref
                  .read(questionnaireInscriptionProvider.notifier)
                  .choisirUsage(retenu);
              context.go(Routes.commencer);
            },
      // Le groupe partage (ADR-013), sans carte « Autre » : deux cartes
      // exactement, a description (demande B-3 levee par COORD).
      // Admission, lot B (directeur, 29/10/2026, apres une eleve adulte
      // perdue le 28/10) : deux grands choix egaux, cote a cote, en haut,
      // « Je m'inscris pour moi » et « J'inscris mon enfant ».
      enfant: ChoiceCardGroup(
        key: const Key('inscription-usage'),
        autoriserSaisieLibre: false,
        coteACote: true,
        choixEgaux: true,
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
    );
  }

  /// PE-A3 : les deux portes, de meme poids, sans preselection. Sous le
  /// bouton, les entrees par code (enseignant, comptable, associe) restent
  /// des liens discrets : un code recu par courriel garde sa porte.
  Widget _portes({
    required bool comptableInvitable,
    required bool associeInvitable,
    required VoidCallback onEnseigner,
    required VoidCallback onCodeEnseignant,
    required BrouillonInscriptionControleur controleur,
  }) {
    final TextStyle discret = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());
    return CoquilleEtape(
      route: _route,
      choix: true,
      question: t.inscription.porte.question,
      explication: t.inscription.porte.explication,
      libelleAction: t.commun.continuer,
      onAction: switch (_porte) {
        null => null,
        PorteEntree.apprendre => () => setState(() => _apprendre = true),
        PorteEntree.enseigner => onEnseigner,
      },
      complement: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: ActionPrincipale(
              key: const Key('inscription-lien-enseignant'),
              libelle: t.inscription.usage.enseignant,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: onCodeEnseignant,
            ),
          ),
          if (comptableInvitable) ...<Widget>[
            Text(
              t.inscription.usage.comptableInvite,
              key: const Key('inscription-comptable-invite'),
              textAlign: TextAlign.center,
              style: discret,
            ),
            Center(
              child: ActionPrincipale(
                key: const Key('inscription-lien-comptable'),
                libelle: t.inscription.usage.comptable,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                onPress: () {
                  controleur.choisirUsage(UsageInscription.comptable);
                  // Meme regle que l'enseignant : sans code de comptable
                  // retenu, le champ du code s'ouvre.
                  if (ref.read(codeComptableRetenuProvider) == null) {
                    context.go(Routes.inscriptionInvitationComptable);
                  } else {
                    avancerDepuis(
                      context,
                      ref.read(brouillonInscriptionProvider),
                      _route,
                    );
                  }
                },
              ),
            ),
          ],
          if (associeInvitable) ...<Widget>[
            Text(
              t.inscription.usage.associeInvite,
              key: const Key('inscription-associe-invite'),
              textAlign: TextAlign.center,
              style: discret,
            ),
            Center(
              child: ActionPrincipale(
                key: const Key('inscription-lien-associe'),
                libelle: t.inscription.usage.associe,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                onPress: () => context.go(Routes.inscriptionAssocie),
              ),
            ),
          ],
        ],
      ),
      enfant: ChoiceCardGroup(
        key: UsageEtape.portesKey,
        autoriserSaisieLibre: false,
        coteACote: true,
        choixEgaux: true,
        valeurInitiale: _porte == null
            ? null
            : ReponseChoix(valeurs: <String>{_porte!.name}),
        options: <OptionChoix>[
          OptionChoix(
            valeur: PorteEntree.apprendre.name,
            libelle: t.inscription.porte.apprendreTitre,
            explication: t.inscription.porte.apprendreDescription,
            exemple: t.inscription.porte.apprendreExemple,
            icone: AppIcons.livreOuvert,
            illustration: const IllustrationChoix(
              AppIcons.livreOuvert,
              autour: <AppIcon>[AppIcons.profil, AppIcons.foyer],
            ),
          ),
          OptionChoix(
            valeur: PorteEntree.enseigner.name,
            libelle: t.inscription.porte.enseignerTitre,
            explication: t.inscription.porte.enseignerDescription,
            exemple: t.inscription.porte.enseignerExemple,
            icone: AppIcons.eleves,
            illustration: const IllustrationChoix(
              AppIcons.eleves,
              autour: <AppIcon>[AppIcons.livreOuvert, AppIcons.suivi],
            ),
          ),
        ],
        onChange: (ReponseChoix reponse) => setState(() {
          _porte = PorteEntree.values
              .where((PorteEntree p) => reponse.valeurs.contains(p.name))
              .firstOrNull;
        }),
      ),
    );
  }
}
