// MESSAGERIE-TEMPS-REEL (14/11/2026) : quand le canal temps reel des messages
// est tombe, la page le dit (K-59 : ce qui manque, la cause probable, ce qui
// se passe maintenant), au lieu de laisser croire que rien n'arrive. Hors
// ligne, le bandeau des communications parle deja : celui-ci se tait.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/communications/veille_messages.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/widgets/offline_banner.dart';

/// Le bandeau « les messages n'arrivent pas en direct », ou rien.
class BandeauMessagesHorsDirect extends ConsumerWidget {
  /// Cree le bandeau. [ecartApres] se pose sous lui quand il est rendu.
  const BandeauMessagesHorsDirect({super.key, this.ecartApres});

  /// L'ecart a poser apres le bandeau, jamais rendu sans lui.
  final Widget? ecartApres;

  /// La cle du bandeau, pour les tests.
  static const Key cle = ValueKey<String>('messages-hors-direct');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enDirect = ref.watch(
      etatVeilleMessagesProvider.select((EtatVeilleMessages e) => e.enDirect),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    if (enDirect || horsLigne) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        OfflineBanner.message(
          key: cle,
          message: t.com.messages.direct.horsDirect,
          encadre: true,
        ),
        ?ecartApres,
      ],
    );
  }
}
