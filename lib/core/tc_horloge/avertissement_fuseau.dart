// PARCOURS-BOUT-EN-BOUT, partie B4 (directeur, 22/11/2026 : « bien travailler
// les fuseaux horaires, sinon ce sera dangereux ») : quand le fuseau de
// l'appareil differe de la ville enregistree pour le foyer, un avertissement
// discret le dit, avec l'action pour corriger (la page « Votre ville »).
//
// Rien n'est modifie en silence : l'ecran montre deja l'heure de l'appareil et
// le dit (regle des trois cas, `mon_horloge.dart`) ; l'avertissement ajoute
// pourquoi les heures ne sont pas celles de la ville, et que le cours, lui,
// reste a la meme heure a La Mecque. Une personne en voyage peut l'ignorer.
//
// Le client n'a aucune base de fuseaux : le decalage de la ville vient du
// serveur ([MonHorloge.moi]). Sans lecture, ou sans ville choisie (le parcours
// de la ville s'en charge), aucun avertissement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../i18n/strings.g.dart';
import '../i18n/villes_fuseau.dart';
import '../router/routes.dart';
import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_card.dart';
import '../widgets/lien_fleche.dart';
import 'fuseaux_interlocuteurs.dart';
import 'mon_horloge.dart';

/// L'identifiant IANA de la ville enregistree quand son heure differe de celle
/// de l'appareil a l'instant [maintenant] ; `null` sinon (meme heure, ville non
/// choisie, fuseau non lu, ou changement d'heure incertain : jamais un
/// avertissement fabrique).
String? villeEnDesaccord({
  required MonHorloge? horloge,
  required Duration decalageAppareil,
  required DateTime maintenant,
}) {
  final FuseauVu? ville = horloge?.moi;
  if (horloge == null || ville == null || horloge.lieuChoisi != true) {
    return null;
  }
  final Duration? decalageVille = ville.decalageA(maintenant.toUtc());
  if (decalageVille == null || decalageVille == decalageAppareil) return null;
  return ville.fuseau;
}

/// L'avertissement, en tete de l'Accueil de la famille.
class AvertissementFuseau extends ConsumerWidget {
  /// Cree l'avertissement. [decalageAppareil] et [maintenant] : pour les tests.
  const AvertissementFuseau({
    this.decalageAppareil,
    this.maintenant,
    super.key,
  });

  /// Le decalage de l'appareil ; l'appareil lui-meme par defaut.
  final Duration? decalageAppareil;

  /// L'instant lu ; maintenant par defaut.
  final DateTime? maintenant;

  /// Cle de l'avertissement.
  static const Key cle = ValueKey<String>('avertissement-fuseau');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime instant = maintenant ?? DateTime.now();
    final String? iana = villeEnDesaccord(
      horloge: ref.watch(monHorlogeProvider).value,
      decalageAppareil: decalageAppareil ?? instant.timeZoneOffset,
      maintenant: instant,
    );
    if (iana == null) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final f = t.avertissementFuseau;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppCard(
          key: cle,
          surface: palette.washAccent,
          child: Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(f.titre, style: textes.titleSmall),
                Ecart.vXs,
                Text(
                  f.phrase(ville: villeDuFuseauLibelle(iana)),
                  style: textes.bodyMedium,
                ),
                Ecart.vSm,
                LienFleche(
                  libelle: f.action,
                  alignerEnDebut: true,
                  onPress: () => GoRouter.maybeOf(context)?.go(Routes.ville),
                ),
              ],
            ),
          ),
        ),
        Ecart.vLg,
      ],
    );
  }
}
