import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';

/// Connexion et securite du titulaire (`/tuteur/compte/securite`).
///
/// Ce qui est vrai en production : on entre par un lien a usage unique ou par
/// Google (`service_auth.dart`). **Aucun mot de passe** n'est donc rendu, et
/// aucune liste d'appareils connectes (aucune API de sessions, DB-CPT-02) : une
/// phrase le dit. La deconnexion a une seule place, au pied de Mon compte.
class SecuriteComptePage extends ConsumerWidget {
  /// Cree la page.
  const SecuriteComptePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextStyle phrase = palette.inkMuted.applyTo(
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
    );

    return PageShell(
      titre: t.compte.tuteur.pageSecurite.titre,
      sousTitre: t.compte.tuteur.pageSecurite.sousTitre,
      onRetour: () => GoRouter.of(context).go(Routes.tuteurCompte),
      child: ColonneSousPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BlocAsynchrone<IdentiteTitulaire>(
              valeur: ref.watch(identiteTitulaireProvider),
              squelette: const Skeleton.liste(lignes: 2),
              onReessayer: () => ref.invalidate(identiteTitulaireProvider),
              construire: (IdentiteTitulaire identite) => GroupeReglages(
                lignes: <LigneRubrique>[
                  LigneRubrique(
                    icone: AppIcons.verrou,
                    libelle: t.compte.tuteur.pageSecurite.methode,
                    legende: phraseConnexion(identite.methodeConnexion),
                  ),
                  LigneRubrique(
                    icone: AppIcons.dossiers,
                    libelle: t.compte.tuteur.pageSecurite.adresse,
                    valeur:
                        identite.courriel ??
                        t.compte.tuteur.identite.courrielAbsent,
                  ),
                ],
              ),
            ),
            Ecart.vLg,
            Text(t.compte.tuteur.pageSecurite.appareils, style: phrase),
            Ecart.vSm,
            Text(t.compte.tuteur.pageSecurite.deconnexion, style: phrase),
          ],
        ),
      ),
    );
  }
}
