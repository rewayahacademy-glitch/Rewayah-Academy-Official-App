import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/priere/position_appareil.dart';
import '../../core/priere/service_priere.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';

/// Aucun lieu connu : un seul bouton plein, « Utiliser ma position » (PRIERE-2).
///
/// L'appareil donne sa position et son fuseau ; le serveur arrondit la position
/// au centieme de degre (environ un kilometre), donne un nom lisible et calcule
/// aussitot. **Jamais un formulaire de coordonnees** : un refus ou un echec se
/// dit en mots (« Position non partagee »), le bouton reste la pour reessayer, et
/// la direction peut poser le lieu.
class SansLieuPriere extends ConsumerStatefulWidget {
  /// Cree l'etat « aucun lieu ».
  const SansLieuPriere({required this.onFait, super.key});

  /// Appele apres un partage reussi : la page relit le lieu et les heures.
  final VoidCallback onFait;

  @override
  ConsumerState<SansLieuPriere> createState() => _SansLieuEtat();
}

class _SansLieuEtat extends ConsumerState<SansLieuPriere> {
  bool _enCours = false;
  String? _message;

  Future<void> _partager() async {
    setState(() {
      _enCours = true;
      _message = null;
    });
    String? message;
    try {
      final PositionAppareil position = await ref.read(
        lecturePositionAppareilProvider,
      )();
      await ref.read(servicePriereProvider).partagerPosition(position);
      ref.invalidate(pausePrevueProvider);
      widget.onFait();
    } on PositionNonPartagee {
      message = t.priere.enseignant.positionRefusee;
    } catch (erreur) {
      message = '$erreur'.contains('lieu_pose_par_la_direction')
          ? t.priere.enseignant.positionDirection
          : t.priere.enseignant.positionErreur;
    }
    if (mounted) {
      setState(() {
        _enCours = false;
        _message = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(t.priere.enseignant.vide, style: textes.bodyMedium),
        if (_message != null) ...<Widget>[
          Ecart.vMd,
          Text(
            _message!,
            key: const ValueKey<String>('priere-position-message'),
            style: textes.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        Ecart.vLg,
        // Un bouton plein ne s'etire pas sur tout un ecran d'ordinateur (B5, 640 px).
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ActionPrincipale(
            key: const ValueKey<String>('priere-utiliser-position'),
            libelle: t.priere.enseignant.utiliserPosition,
            enCours: _enCours,
            onPress: _enCours ? null : () => unawaited(_partager()),
          ),
        ),
      ],
    );
  }
}
