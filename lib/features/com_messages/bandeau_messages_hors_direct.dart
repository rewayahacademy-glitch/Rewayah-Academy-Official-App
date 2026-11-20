// MESSAGERIE-TEMPS-REEL (14/11/2026) : quand le canal temps reel des messages
// est tombe, la page le dit (K-59 : ce qui manque, la cause probable, ce qui
// se passe maintenant), au lieu de laisser croire que rien n'arrive. Hors
// ligne, le bandeau des communications parle deja : celui-ci se tait.
//
// PE-D8 (directeur, 19/11/2026 : « laid, repetitif », il ne pouvait pas se
// fermer) : ce n'est plus un bandeau jaune encadre, c'est un signe discret,
// une ligne en encre douce, que la personne masque d'un toucher. Masque, il
// ne revient qu'apres un retour en direct suivi d'une nouvelle chute.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/communications/veille_messages.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_icone.dart';

/// Vrai quand la personne a masque le signe ; repasse a faux des que les
/// messages reviennent en direct.
final NotifierProvider<MasqueHorsDirect, bool> masqueHorsDirectProvider =
    NotifierProvider<MasqueHorsDirect, bool>(MasqueHorsDirect.new);

/// Porte le masquage du signe « pas en direct ».
class MasqueHorsDirect extends Notifier<bool> {
  @override
  bool build() {
    ref.listen<bool>(
      etatVeilleMessagesProvider.select((EtatVeilleMessages e) => e.enDirect),
      (bool? _, bool enDirect) {
        if (enDirect) state = false;
      },
    );
    return false;
  }

  /// Masque le signe jusqu'a la prochaine chute.
  void masquer() => state = true;
}

/// Le signe « les messages n'arrivent pas en direct », ou rien.
class BandeauMessagesHorsDirect extends ConsumerWidget {
  /// Cree le signe. [ecartApres] se pose sous lui quand il est rendu.
  const BandeauMessagesHorsDirect({super.key, this.ecartApres});

  /// L'ecart a poser apres le signe, jamais rendu sans lui.
  final Widget? ecartApres;

  /// La cle du signe, pour les tests.
  static const Key cle = ValueKey<String>('messages-hors-direct');

  /// La cle de la croix qui le masque.
  static const Key cleMasquer = ValueKey<String>(
    'messages-hors-direct-masquer',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enDirect = ref.watch(
      etatVeilleMessagesProvider.select((EtatVeilleMessages e) => e.enDirect),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final bool masque = ref.watch(masqueHorsDirectProvider);
    if (enDirect || horsLigne || masque) return const SizedBox.shrink();
    final AppPalette palette = AppPalette.of(context);
    final String texte = t.com.messages.direct.horsDirect;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          key: cle,
          children: <Widget>[
            ExcludeSemantics(
              child: IconTheme(
                data: palette.inkMuted.asIconTheme(),
                child: Icon(AppIcons.info.repos),
              ),
            ),
            Ecart.hSm,
            Flexible(
              child: Text(
                texte,
                style: palette.inkMuted.applyTo(
                  Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                ),
              ),
            ),
            BoutonIcone(
              key: cleMasquer,
              icone: AppIcons.fermer,
              libelle: t.racine.horsDirect.masquer,
              infobulle: t.racine.horsDirect.masquer,
              onPress: ref.read(masqueHorsDirectProvider.notifier).masquer,
            ),
          ],
        ),
        ?ecartApres,
      ],
    );
  }
}
