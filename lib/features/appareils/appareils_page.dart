import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/bento_tile.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/page_shell.dart';

/// `TUT-02` : le foyer et ses appareils.
///
/// **Liste dense, pas de grandes cartes.** C'est un ecran de gestion, pas un
/// ecran de suivi affectif, et le registre visuel doit le dire
/// (`docs/archive/2026-09-pre-remise-a-plat/produit/parcours-utilisateurs.md`).
///
/// A la limite de deux appareils, le bouton d'ajout **est remplace par un
/// message** au lieu de rester actif puis d'echouer : un bouton qui echoue
/// apres le geste coute plus cher en confiance qu'un bouton absent.
class AppareilsPage extends ConsumerWidget {
  /// Cree l'ecran du foyer.
  const AppareilsPage({super.key});

  // Reprise au lot R4 : l'ecran passait par un `Scaffold` propre, un
  // `OfflineBanner` pose a la main et un tirage-pour-rafraichir
  // (`RefreshIndicator` invalidant les deux providers du foyer) autour de son
  // `ListView`. Il passe desormais par `PageShell`, qui porte deja le fond, le
  // bandeau hors ligne et la gouttiere du gabarit.
  //
  // Dette assumee : **le tirage-pour-rafraichir disparait**, meme sort et
  // meme raison que sur `TUT-00b`, `TUT-01`, `ENS-02` et `ADM-01` (voir leurs
  // fiches, section 6) : un `RefreshIndicator` autour d'un `ListView` a
  // besoin d'etre l'enfant direct d'un `Expanded` pour ne pas planter en
  // hauteur non bornee, et `PageShell` ne donne pas cette garantie a son
  // `child`. C'est le cinquieme ecran qui la demande.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<EleveDuFoyer>> eleves = ref.watch(
      elevesDuFoyerProvider,
    );
    final AsyncValue<List<AppareilAppaire>> appareils = ref.watch(
      appareilsDuFoyerProvider,
    );

    return PageShell(
      titre: t.appareils.titre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // La regle de l'ADR-010 est affichee en clair : deux appareils au
          // maximum, un seul en cours a la fois.
          Text(t.appareils.regle, style: textes.bodySmall),
          Ecart.vXl,
          if (eleves.hasValue && eleves.requireValue.isEmpty)
            EmptyState(
              message: t.enfant.aucun,
              invitation: t.enfant.aucunDetail,
              libelleAction: t.enfant.titre,
              onAction: () =>
                  GoRouter.of(context).go(Routes.tuteurAjouterEnfant),
            )
          else ...<Widget>[
            for (final EleveDuFoyer eleve
                in eleves.value ?? const <EleveDuFoyer>[])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _BlocEleve(
                  eleve: eleve,
                  appareils: (appareils.value ?? const <AppareilAppaire>[])
                      .where(
                        (AppareilAppaire a) =>
                            a.profilId == eleve.id && a.actif,
                      )
                      .toList(),
                  onRevoquer: (String id) async {
                    await ref.read(serviceAppairageProvider).revoquer(id);
                    ref.invalidate(appareilsDuFoyerProvider);
                  },
                ),
              ),
            Ecart.vLg,
            ActionPrincipale(
              libelle: t.enfant.titre,
              onPress: () =>
                  GoRouter.of(context).go(Routes.tuteurAjouterEnfant),
              niveau: NiveauAction.secondaire,
            ),
          ],
        ],
      ),
    );
  }
}

class _BlocEleve extends StatelessWidget {
  const _BlocEleve({
    required this.eleve,
    required this.appareils,
    required this.onRevoquer,
  });

  final EleveDuFoyer eleve;
  final List<AppareilAppaire> appareils;
  final Future<void> Function(String appareilId) onRevoquer;

  bool get _limiteAtteinte =>
      appareils.length >= ServiceAppairage.appareilsParEleve;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return BentoTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              // Photo reelle si elle existe, repli sur les initiales, jamais une
              // icone d'erreur (ADR-012). L'URL signee arrive a l'etape 4 avec
              // TUT-05 : ici, le repli est la normale.
              AvatarTile(prenom: eleve.prenom, diametre: AppSpacing.xxxl * 2),
              Ecart.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(eleve.prenom, style: textes.titleMedium),
                    Text(eleve.identifiantImmuable, style: textes.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          Ecart.vMd,
          if (appareils.isEmpty)
            Text(t.vide.aucunAppareil, style: textes.bodySmall)
          else
            for (final AppareilAppaire appareil in appareils)
              _LigneAppareil(
                appareil: appareil,
                onRevoquer: () => unawaited(onRevoquer(appareil.id)),
              ),
          Ecart.vMd,
          // Le bouton disparait, il ne devient pas inerte : la limite s'explique
          // au lieu de se heurter.
          if (_limiteAtteinte)
            Text(
              t.appareils.limiteAtteinte(prenom: eleve.prenom),
              style: palette.inkAlert.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            )
          else
            ActionPrincipale(
              libelle: t.appareils.ajouter,
              // L'emetteur revient d'ou l'on vient (Foyer ou liste des
              // appareils) : le chemin courant voyage en `retour`.
              onPress: () => GoRouter.of(context).go(
                Uri(
                  path: Routes.appairerPour(eleve.id),
                  queryParameters: switch (_cheminCourant(context)) {
                    final String chemin => <String, String>{'retour': chemin},
                    null => null,
                  },
                ).toString(),
              ),
            ),
        ],
      ),
    );
  }
}

class _LigneAppareil extends StatelessWidget {
  const _LigneAppareil({required this.appareil, required this.onRevoquer});

  final AppareilAppaire appareil;
  final VoidCallback onRevoquer;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(appareil.plateforme, style: textes.bodyMedium),
                Text(
                  appareil.derniereUtilisation == null
                      ? t.appareils.jamaisUtilise
                      : t.appareils.derniereUtilisation(
                          quand: _jour(appareil.derniereUtilisation!),
                        ),
                  style: textes.bodySmall,
                ),
              ],
            ),
          ),
          Ecart.hMd,
          ActionPrincipale(
            libelle: t.appareils.revoquer,
            onPress: onRevoquer,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
          ),
        ],
      ),
    );
  }
}

/// Le chemin de l'ecran courant, `null` hors routeur.
String? _cheminCourant(BuildContext context) {
  try {
    return GoRouterState.of(context).uri.path;
  } on GoError {
    return null;
  }
}

String _jour(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';
