// Une ligne de la liste des conversations (BULLES-MESSAGERIE, directeur,
// 16/11/2026) : la photo de 48 (ou les initiales), le nom (en gras tant qu'il
// y a des non lus), l'apercu du dernier message sur une ligne (plus fonce tant
// que la conversation n'est pas lue), l'heure en haut cote fin et dessous la
// pastille violette du nombre de non lus. Aucune fleche ; la conversation
// ouverte est teintee. Le composant ne lit aucun role ni aucun port : tout lui
// vient de l'ecran.

import 'package:flutter/material.dart';

import '../accessibilite/sens_du_contenu.dart';
import '../icons/app_icons.dart';
import '../theme/app_color_pair.dart';
import '../theme/app_palette.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'badge_non_lu.dart';
import 'pressable.dart';

/// Une conversation dans une liste.
class LigneConversation extends StatelessWidget {
  /// Cree la ligne.
  const LigneConversation({
    required this.meneur,
    required this.titre,
    required this.apercu,
    required this.onPress,
    super.key,
    this.heure,
    this.nonLus = 0,
    this.libelleNonLus,
    this.marque,
    this.selectionnee,
    this.apercuPhoto = false,
  });

  /// La photo ou les initiales, deja a leur taille (48).
  final Widget meneur;

  /// Le nom de la conversation.
  final String titre;

  /// Le debut du dernier message, coupe a une ligne.
  final String apercu;

  /// Le dernier message est une photo : [apercu] dit « Photo », precede d'une
  /// petite icone image.
  final bool apercuPhoto;

  /// L'heure du dernier message, ou `null`.
  final String? heure;

  /// Le nombre de messages non lus ; 0 : lue.
  final int nonLus;

  /// La phrase du nombre de non lus, dite au lecteur d'ecran.
  final String? libelleNonLus;

  /// Ce qui se pose sous l'heure quand aucun nombre n'est connu (une
  /// attention sans nombre), ou `null`.
  final Widget? marque;

  /// La conversation ouverte a cote de la liste, ou `null`.
  final bool? selectionnee;

  /// L'ouverture de la conversation.
  final VoidCallback onPress;

  /// La cle de la pastille du nombre de non lus, pour les tests.
  static const Key cleNonLus = ValueKey<String>('ligne-conversation-non-lus');

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool aLire = nonLus > 0;
    final bool choisie = selectionnee ?? false;
    // Plus fonce tant que la conversation n'est pas lue (encre forte), discret
    // une fois lue.
    final AppInkColor apercuEncre = aLire
        ? palette.inkStrong
        : palette.inkMuted;
    final Widget texteApercu = Text(
      apercu,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: sensDuContenu(context, apercu),
      style: apercuEncre.applyTo(textes.bodyMedium ?? const TextStyle()),
    );
    return Pressable.selon(
      onPress: onPress,
      selectionne: selectionnee,
      arrondiFocus: AppRadius.arrondiSm,
      libelleSemantique: <String>[titre, apercu, ?libelleNonLus].join(', '),
      constructeur: (BuildContext context, EtatPression etat) => DecoratedBox(
        decoration: BoxDecoration(
          color: choisie
              ? palette.washAccent.background
              : etat.survole || etat.presse
              ? Color.alphaBlend(
                  palette.calqueInteraction(presse: etat.presse),
                  palette.surfaceCanvas.background,
                )
              : null,
          borderRadius: AppRadius.arrondiSm,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              meneur,
              Ecart.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // Le nom suit sa langue : un nom latin coupe a sa
                            // fin, jamais a son debut, dans une interface
                            // arabe.
                            textDirection: sensDuContenu(context, titre),
                            // Gras (600) tant qu'il y a des non lus.
                            style: palette.inkStrong.applyTo(
                              (aLire ? textes.labelLarge : textes.bodyLarge) ??
                                  const TextStyle(),
                            ),
                          ),
                        ),
                        if (heure != null) ...<Widget>[
                          Ecart.hSm,
                          Text(
                            heure!,
                            style: palette.inkMuted.applyTo(
                              textes.bodySmall ?? const TextStyle(),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Ecart.vXs,
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: apercuPhoto
                              ? Row(
                                  children: <Widget>[
                                    Icon(
                                      AppIcons.image.repos,
                                      size: AppSpacing.lg,
                                      color: apercuEncre
                                          .asIconTheme(size: AppSpacing.lg)
                                          .color,
                                    ),
                                    Ecart.hXs,
                                    Expanded(child: texteApercu),
                                  ],
                                )
                              : texteApercu,
                        ),
                        if (aLire) ...<Widget>[
                          Ecart.hSm,
                          PastilleNombre(key: cleNonLus, nombre: nonLus),
                        ] else if (marque != null) ...<Widget>[
                          Ecart.hSm,
                          marque!,
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
