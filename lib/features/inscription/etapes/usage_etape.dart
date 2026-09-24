import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
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
            avancerDepuis(context, _route);
          },
        ),
      ),
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CarteChoixInscription(
            key: const Key('inscription-usage-moi'),
            icone: AppIcons.profil,
            titre: t.inscription.usage.moiTitre,
            description: t.inscription.usage.moiDescription,
            retenue: retenu == UsageInscription.moi,
            onPress: () => controleur.choisirUsage(UsageInscription.moi),
          ),
          Ecart.vMd,
          CarteChoixInscription(
            key: const Key('inscription-usage-famille'),
            icone: AppIcons.foyer,
            titre: t.inscription.usage.familleTitre,
            description: t.inscription.usage.familleDescription,
            retenue: retenu == UsageInscription.famille,
            onPress: () => controleur.choisirUsage(UsageInscription.famille),
          ),
        ],
      ),
    );
  }
}
