// La ligne d'un fil dans une liste de conversations : le SEUL endroit qui la
// compose (avatar du premier interlocuteur, titre, apercu, heure, non lus,
// badge « Nouveau »). Extraite de `ListeFils` (PX-4, 17/11/2026) pour que le
// choix des conversations d'essai de Praxis montre les conversations comme la
// messagerie les montre, sans recomposer la ligne (CONVERSATIONS-PARTOUT).

import 'package:flutter/material.dart';

import '../../core/communications/modeles_communication.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../../core/widgets/ligne_conversation.dart';
import 'avatar_participant.dart';
import 'entete_fil_contexte.dart';
import 'liste_fils.dart' show momentCourt;

/// Une conversation dans une liste.
class LigneFil extends StatelessWidget {
  /// Cree la ligne.
  const LigneFil({
    required this.fil,
    required this.maintenant,
    required this.onPress,
    super.key,
    this.selectionnee,
  });

  /// Le resume du fil.
  final ResumeFil fil;

  /// L'heure courante, pour dire « 10:24 » ou « 12 novembre ».
  final DateTime maintenant;

  /// La conversation ouverte a cote de la liste, ou `null`.
  final bool? selectionnee;

  /// L'ouverture (ou le choix) de la conversation.
  final VoidCallback onPress;

  /// La cle de la ligne d'un fil, pour les tests.
  static ValueKey<String> cleLigne(String filId) =>
      ValueKey<String>('liste-fils-$filId');

  @override
  Widget build(BuildContext context) {
    final ResumeFil f = fil;
    final int nonLus = f.attention.nonLus;
    final DateTime? dernier = f.dernierMessageLe;
    final String titre = titreFil(f.interlocuteurs, f.objet.libelle);
    final String apercu = f.apercuPhoto
        ? t.com.messages.images.photoApercu
        : f.apercu ??
              (f.nouveau
                  ? t.com.messages.ligne.sansMessage
                  : t.com.messages.ligne.sansApercu);
    return LigneConversation(
      key: ValueKey<String>('ligne-${f.id}'),
      // PHOTOS-2b et #Ra_staff : l'avatar du premier interlocuteur.
      meneur: KeyedSubtree(
        key: cleLigne(f.id),
        child: AvatarParticipant(
          participant: f.interlocuteurs.isEmpty ? null : f.interlocuteurs.first,
          repli: f.objet.libelle,
          diametre: AppAvatar.moyen,
        ),
      ),
      titre: titre,
      apercu: apercu,
      apercuPhoto: f.apercuPhoto,
      heure: dernier == null ? null : momentCourt(dernier, maintenant),
      nouveau: f.nouveau,
      nonLus: nonLus,
      libelleNonLus: nonLus > 0 ? BadgeNonLu.libelleNonLus(nonLus) : null,
      // Une attention sans nombre (mention, action requise) garde son badge.
      marque: nonLus == 0 && f.attention.estVisible
          ? BadgeNonLu(indicateur: f.attention, compact: true)
          : null,
      selectionnee: selectionnee,
      onPress: onPress,
    );
  }
}
