import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/port_identite_titulaire.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';

/// Les informations personnelles du titulaire (`/tuteur/compte/informations`),
/// en lecture seule.
///
/// Aucune ecriture n'existe pour le tuteur (DB-CPT-01) : pas de formulaire,
/// pas de bouton « Modifier » qui ne pourrait pas aboutir ; une phrase le dit.
/// Pas de telephone ni de ville : aucune colonne ne les porte pour le tuteur.
/// Le fuseau est celui des seances (`mon_fuseau()`), jamais celui de
/// l'appareil.
class InformationsComptePage extends ConsumerWidget {
  /// Cree la page.
  const InformationsComptePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<String> fuseau = ref.watch(monFuseauProvider);
    final String valeurFuseau = fuseau.hasValue && !fuseau.hasError
        ? villeDuFuseau(fuseau.requireValue)
        : t.compte.tuteur.pageInformations.fuseauIndisponible;

    return PageShell(
      titre: t.compte.tuteur.pageInformations.titre,
      onRetour: () => GoRouter.of(context).go(Routes.tuteurCompte),
      child: ColonneSousPage(
        child: BlocAsynchrone<IdentiteTitulaire>(
          valeur: ref.watch(identiteTitulaireProvider),
          squelette: const Skeleton.liste(lignes: 4),
          onReessayer: () => ref.invalidate(identiteTitulaireProvider),
          construire: (IdentiteTitulaire identite) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GroupeReglages(
                lignes: <LigneRubrique>[
                  LigneRubrique(
                    icone: AppIcons.profil,
                    libelle: t.compte.tuteur.pageInformations.prenom,
                    valeur: _ou(identite.prenom),
                  ),
                  LigneRubrique(
                    icone: AppIcons.profil,
                    libelle: t.compte.tuteur.pageInformations.nom,
                    valeur: _ou(identite.nom),
                  ),
                  LigneRubrique(
                    icone: AppIcons.dossiers,
                    libelle: t.compte.tuteur.pageInformations.courriel,
                    valeur:
                        identite.courriel ??
                        t.compte.tuteur.identite.courrielAbsent,
                  ),
                  LigneRubrique(
                    icone: AppIcons.direction,
                    libelle: t.compte.tuteur.pageInformations.langue,
                    valeur: t.compte.francais,
                  ),
                  LigneRubrique(
                    icone: AppIcons.historique,
                    libelle: t.compte.tuteur.pageInformations.fuseau,
                    valeur: valeurFuseau,
                  ),
                ],
              ),
              Ecart.vLg,
              Text(
                t.compte.tuteur.pageInformations.note,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _ou(String valeur) =>
      valeur.trim().isEmpty ? t.compte.nonDisponible : valeur.trim();
}
