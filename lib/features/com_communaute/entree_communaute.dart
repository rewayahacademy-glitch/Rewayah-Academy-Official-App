// L'entree de la Communaute enseignants sur Aujourd'hui (reponse Q2 du
// directeur, 04/10 : un raccourci, jamais une destination de la barre, E10).
//
// Une LIGNE dans un bloc toujours rendu de `JourneePage` (« Ma journee »),
// jamais un cinquieme bloc (K-42, « Quatre blocs, pas un de plus ») ni une
// ligne d'« Alertes utiles », qui n'est rendu que s'il n'est pas vide
// (UX_REVIEW L0, point 23 ; 02_DECOUPAGE regle 3). La page hote ne sait rien
// de ce que la ligne montre : elle pose seulement l'emplacement.
//
// Emplacement pose par le socle (COM-F-b, 02_DEC-10), rempli ici par la voie
// COM-COMU (02_DECOUPAGE, regle des fichiers 3). Contrat d'ecart fixe par le
// socle : la page dit l'ecart a poser avant le contenu ([ecartAvant], celui
// qui separe les lignes de « Ma journee ») ; la ligne le rend devant son
// contenu, et seulement quand elle rend quelque chose.
//
// R-27 (decision du directeur du 05/10, choix a) : tant que la Communaute
// n'est pas ouverte (le port de production rend `CapaciteIndisponible`), la
// ligne n'est pas rendue : l'enseignant ne tombe plus sur « Pas encore
// disponible ». Elle reste visible en demonstration, ou le port repond.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/lien_fleche.dart';
import 'port_communaute.dart';

/// L'adresse ouverte par le raccourci : la Communaute de l'enseignant. La
/// demonstration la remplace par la sienne, hors production.
final Provider<String> destinationCommunauteProvider = Provider<String>(
  (Ref ref) => Routes.enseignantCommunaute,
  dependencies: const <ProviderOrFamily>[],
);

/// La ligne « Communaute enseignants » d'Aujourd'hui.
class EntreeCommunaute extends ConsumerWidget {
  /// Cree la ligne.
  const EntreeCommunaute({super.key, this.ecartAvant});

  /// L'ecart a poser avant le contenu, ou `null` (contrat du socle).
  final Widget? ecartAvant;

  /// La cle du lien, pour les tests.
  static const ValueKey<String> cleLien = ValueKey<String>(
    'entree-communaute-lien',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // R-27 : la ligne n'apparait que quand la Communaute repond. Une
    // capacite absente (production) la masque ; pendant la lecture, rien
    // n'est rendu, pour ne pas montrer puis retirer un lien. Un echec
    // ordinaire la garde : la page dira « Reessayer ».
    final AsyncValue<CapacitesCommunaute> capacites = ref.watch(
      capacitesCommunauteProvider,
    );
    if (capacites.error is CapaciteIndisponible ||
        (!capacites.hasValue && !capacites.hasError)) {
      return const SizedBox.shrink();
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final e = t.com.communaute.entree;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ?ecartAvant,
        LienFleche(
          key: cleLien,
          libelle: t.com.socle.lexique.communaute,
          libelleSemantique: e.lecteur,
          icone: AppIcons.discussion,
          onPress: () =>
              GoRouter.of(context).go(ref.read(destinationCommunauteProvider)),
        ),
        Text(
          e.detail,
          style: palette.inkMuted.applyTo(
            textes.bodySmall ?? const TextStyle(),
          ),
        ),
      ],
    );
  }
}
