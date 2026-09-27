import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/planning/service_planning.dart';
import '../../core/preferences/preferences_locales.dart';
import '../../core/router/routes.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import 'carte_rubriques.dart';
import 'donnees_compte.dart';

/// Les preferences du titulaire sur cet appareil
/// (`/tuteur/compte/preferences`, maquette V4 « Reglages », ecran 01).
///
/// Tache focalisee : sur telephone la barre basse s'efface, le disque retour
/// ramene au Compte. **Un seul groupe a filets**, pas quatre cartes (V4).
///
/// Seules les rubriques qui aboutissent menent ailleurs : Apparence (theme
/// reellement applique et garde sur l'appareil). Langue et region se lit
/// sans bascule (francais seul, fuseau tenu par l'academie) ; Notifications
/// dit qu'elles n'existent pas encore (DB-CPT-04). La rubrique « Securite » de
/// la maquette n'est pas reprise : sa fonction a sa place dans Mon compte
/// (« Connexion et securite »), une seule fois.
class PreferencesComptePage extends ConsumerWidget {
  /// Cree la page.
  const PreferencesComptePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String> fuseau = ref.watch(monFuseauProvider);
    final String langue = fuseau.hasValue && !fuseau.hasError
        ? t.compte.tuteur.informations.langueFuseau(
            ville: villeDuFuseau(fuseau.requireValue),
          )
        : t.compte.francais;

    return PageShell(
      titre: t.compte.tuteur.pagePreferences.titre,
      sousTitre: t.compte.tuteur.pagePreferences.sousTitre,
      onRetour: () => GoRouter.of(context).go(Routes.tuteurCompte),
      child: ColonneSousPage(
        child: GroupeReglages(
          lignes: <LigneRubrique>[
            LigneRubrique(
              icone: AppIcons.personnalisationGroupe,
              libelle: t.compte.tuteur.pagePreferences.apparence,
              legende: t.compte.tuteur.pagePreferences.apparenceDetail,
              onPress: () =>
                  GoRouter.of(context).go(Routes.tuteurCompteApparence),
            ),
            LigneRubrique(
              icone: AppIcons.direction,
              libelle: t.compte.tuteur.pagePreferences.langue,
              legende: langue,
            ),
            LigneRubrique(
              icone: AppIcons.notifications,
              libelle: t.compte.tuteur.pagePreferences.notifications,
              legende: t.compte.tuteur.pagePreferences.notificationsDetail,
            ),
          ],
        ),
      ),
    );
  }
}

/// Le nom d'un choix de theme : « Systeme », « Clair », « Sombre ».
String libelleTheme(PreferenceTheme theme) => switch (theme) {
  PreferenceTheme.systeme => t.compte.themeSysteme,
  PreferenceTheme.clair => t.compte.themeClair,
  PreferenceTheme.sombre => t.compte.themeSombre,
};
