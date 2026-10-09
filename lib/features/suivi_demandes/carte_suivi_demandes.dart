/// OFFRES-FAM-1 : le point d'entree du suivi des demandes, sur l'accueil
/// famille.
///
/// Une carte, une ligne par eleve concerne (« Yusuf : Demande envoyee ») et
/// un lien vers l'ecran de suivi. **Silencieuse** tant qu'il n'y a rien a
/// suivre : sans port (production avant branchement), pendant la premiere
/// lecture (l'accueil porte deja son squelette) et sans demande. Aucune carte
/// n'est inventee.
///
/// En echec, la carte reste, dit ce qui manque et garde le lien : l'ecran de
/// suivi porte la relecture.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/port_suivi_demandes.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/lien_fleche.dart';
import 'libelles_suivi_demandes.dart';
import 'suivi_demandes_page.dart' show trierDemandes;

/// La carte « Vos demandes de creneau » de l'accueil, suivie de son ecart.
class CarteSuiviDemandes extends ConsumerWidget {
  /// Cree la carte.
  const CarteSuiviDemandes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(portSuiviDemandesProvider) == null) {
      return const SizedBox.shrink();
    }
    final AsyncValue<List<SuiviDemande>> demandes = ref.watch(
      suiviDemandesProvider,
    );
    // (Pas de test isLoading : Riverpod 3 relance seul un fournisseur en
    // echec, l'etat reste alors en chargement AVEC l'erreur precedente.)
    final bool echec = !demandes.hasValue && demandes.hasError;
    if (!demandes.hasValue && !echec) {
      return const SizedBox.shrink();
    }
    final List<SuiviDemande> lues = demandes.value ?? const <SuiviDemande>[];
    if (!echec && lues.isEmpty) {
      return const SizedBox.shrink();
    }

    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppCard(
          key: const ValueKey<String>('carte-suivi-demandes'),
          entete: Semantics(
            header: true,
            child: TexteSansCoupure(
              t.suiviDemandes.accueil.titre,
              style: textes.titleMedium ?? const TextStyle(),
            ),
          ),
          actions: LienFleche(
            key: const ValueKey<String>('carte-suivi-demandes-voir'),
            libelle: t.suiviDemandes.accueil.voir,
            alignerEnFin: true,
            onPress: () => GoRouter.maybeOf(context)?.go(Routes.tuteurDemandes),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (echec)
                Text(t.suiviDemandes.sansDonnees, style: corps)
              else
                for (final (int i, SuiviDemande d) in trierDemandes(
                  lues,
                ).indexed) ...<Widget>[
                  if (i > 0) Ecart.vSm,
                  Text(
                    t.suiviDemandes.accueil.ligne(
                      prenom: d.prenom,
                      etat: etatCourtDemande(d),
                    ),
                    style: corps,
                  ),
                ],
            ],
          ),
        ),
        Ecart.vXl,
      ],
    );
  }
}
