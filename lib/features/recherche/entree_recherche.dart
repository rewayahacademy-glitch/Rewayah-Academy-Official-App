import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/recherche/modeles_recherche.dart';
import '../../core/recherche/port_recherche.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/lien_fleche.dart';

/// L'espace de recherche d'un role de l'Espace Classe : un choix d'interface,
/// jamais un droit (le serveur intersecte avec les capacites reelles).
EspaceRecherche espacePourRoleGroupe(RoleEspaceGroupe role) => switch (role) {
  RoleEspaceGroupe.eleve => EspaceRecherche.eleve,
  RoleEspaceGroupe.tuteur => EspaceRecherche.famille,
  RoleEspaceGroupe.enseignant => EspaceRecherche.enseignant,
  RoleEspaceGroupe.admin => EspaceRecherche.administration,
};

/// L'entree contextuelle « Rechercher dans les supports » d'un module (Espace
/// Classe) : ouvre la **meme** surface `/recherche`, bornee au domaine des
/// supports (spec RECH-03 §4.1, §6.1 point 4). Ce n'est pas une seconde
/// recherche.
///
/// **Rendu seulement si le domaine est servi** : tant qu'aucun moteur de
/// supports n'est raccorde (production), l'entree n'existe pas, plutot qu'un
/// lien vers « Recherche indisponible ».
class EntreeRechercheSupports extends ConsumerWidget {
  /// Cree l'entree pour un [espace].
  const EntreeRechercheSupports({required this.espace, super.key});

  /// L'espace depuis lequel le module est ouvert.
  final EspaceRecherche espace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool servi =
        ref.watch(_supportsServisProvider(espace)).value ?? false;
    if (!servi) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: LienFleche(
        libelle: t.recherche.entree.supports,
        alignerEnDebut: true,
        onPress: () => GoRouter.of(
          context,
        ).push(Routes.rechercheAvec(domaine: DomaineRecherche.supports.name)),
      ),
    );
  }
}

final _supportsServisProvider = FutureProvider.autoDispose
    .family<bool, EspaceRecherche>((Ref ref, EspaceRecherche espace) async {
      final List<DomaineRecherche> servis = await ref
          .watch(portRechercheProvider)
          .portees(
            ContexteRecherche(
              espace: espace,
              domaineCible: DomaineRecherche.supports,
            ),
          );
      return servis.contains(DomaineRecherche.supports);
    });

/// Vrai quand au moins un domaine de recherche est servi a [espace] : la
/// capacite (jamais le role) qui decide si une coque pose son entree. Lu sans
/// la session ; une lecture en cours ou en echec vaut « non servi » : l'entree
/// est alors masquee, jamais grisee.
final rechercheServieProvider = FutureProvider.autoDispose
    .family<bool, EspaceRecherche>((Ref ref, EspaceRecherche espace) async {
      final List<DomaineRecherche> servis = await ref
          .watch(portRechercheProvider)
          .portees(ContexteRecherche(espace: espace));
      return servis.isNotEmpty;
    });

/// La cle de la loupe d'en-tete des coques, pour les tests.
const Key cleLoupeRecherche = ValueKey<String>('recherche-loupe');

/// La loupe d'en-tete d'une coque (RECH-D5, spec RECH-03 §4.1) : **une seule
/// entree par coque**, qui ouvre la meme surface `/recherche`. La coque ne la
/// pose que si [rechercheServieProvider] le dit pour son espace.
class LoupeRecherche extends StatelessWidget {
  /// Cree la loupe.
  const LoupeRecherche({super.key});

  @override
  Widget build(BuildContext context) => BoutonIcone(
    key: cleLoupeRecherche,
    icone: AppIcons.recherche,
    libelle: t.recherche.titre,
    infobulle: t.recherche.titre,
    onPress: () => GoRouter.of(context).push(Routes.recherche),
  );
}
