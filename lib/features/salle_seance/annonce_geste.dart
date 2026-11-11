// GESTES-POINTEUR (directeur, 11/11/2026, cahier de la salle §8) : ce qu'un
// geste de la salle dit a la personne, a UNE place, la meme pour tous les
// roles et tous les ecrans.
//
// Le defaut G-1 : « Le professeur vous appelle » vivait dans une couche que le
// telephone masque au bout de trois secondes ; l'eleve qui lisait ne voyait
// rien, et l'enseignant ne savait jamais si son geste etait parti.
//
// [CoucheAnnonceGeste] pose l'annonce par-dessus la salle, en tete, un court
// instant ([AppMouvement.annonceGesteMaintien], tenu par l'ecran qui la
// pose) : elle ne pousse rien, ne reduit pas la page, et s'efface seule.

import 'package:flutter/material.dart';

import '../../core/theme/app_mouvement.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/status_pill.dart' show TonEtat;

/// Ce qu'un geste dit : ce qui se passe, puis quoi faire ou ce que cela
/// change.
@immutable
class AnnonceGeste {
  /// Cree l'annonce.
  const AnnonceGeste({
    required this.titre,
    required this.message,
    this.ton = TonEtat.accent,
    this.cle,
  });

  /// Ce qui se passe, en quelques mots (« Yasmine recite »).
  final String titre;

  /// La consequence, ou quoi faire maintenant.
  final String message;

  /// Accent pour une information, alerte pour un geste qui n'a pas abouti.
  final TonEtat ton;

  /// La cle posee sur le bandeau (tests).
  final Key? cle;

  @override
  bool operator ==(Object other) =>
      other is AnnonceGeste &&
      other.titre == titre &&
      other.message == message &&
      other.ton == ton &&
      other.cle == cle;

  @override
  int get hashCode => Object.hash(titre, message, ton, cle);
}

/// La salle ([child]) et, par-dessus, l'annonce du dernier geste.
class CoucheAnnonceGeste extends StatelessWidget {
  /// Cree la couche.
  const CoucheAnnonceGeste({
    required this.annonce,
    required this.child,
    super.key,
  });

  /// L'annonce a montrer, ou `null`.
  final AnnonceGeste? annonce;

  /// La salle.
  final Widget child;

  /// La cle de la couche de l'annonce.
  static const Key cle = ValueKey<String>('annonce-geste');

  @override
  Widget build(BuildContext context) {
    final AnnonceGeste? a = annonce;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppPage.largeurDialogue,
                  ),
                  // « Reduire les animations » : l'annonce reste, le fondu
                  // disparait.
                  child: AnimatedSwitcher(
                    duration: AppMouvement.duree(
                      context,
                      AppMouvement.apparition,
                    ),
                    child: a == null
                        ? const SizedBox.shrink()
                        : Semantics(
                            key: ValueKey<AnnonceGeste>(a),
                            container: true,
                            liveRegion: true,
                            child: KeyedSubtree(
                              key: cle,
                              child: BandeauAttention(
                                key: a.cle,
                                titre: a.titre,
                                message: a.message,
                                ton: a.ton,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
