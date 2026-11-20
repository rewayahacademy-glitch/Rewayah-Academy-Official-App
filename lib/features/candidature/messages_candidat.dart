// ACCUEIL-CANDIDAT (directeur, 20/11/2026) : l'onglet Messages de l'accueil
// du candidat, en trois rubriques horizontales (`SelecteurSection`,
// ONGLETS-1) :
// - Messages : la conversation existante avec l'academie (`FilEnPlace`, le
//   meme fil que la page Messages, employe sans le modifier) ; tant que la
//   conversation n'est pas ouverte, l'entree existante
//   (`EntreeMessagesCandidature`) l'ouvre a la demande du candidat ;
// - Annonces : la grille des annonces (`AnnoncesCandidat`) ;
// - A savoir (nom propose, a valider) : les emplacements des informations que
//   les candidats n'ont pas (`ASavoirCandidat`).
//
// La rubrique est dans l'adresse (`/attente?onglet=messages&section=...`) :
// recharger rend la meme rubrique.
//
// Le nombre de la barre : les messages recus non lus, sur les fils metier du
// candidat (le serveur ne lui rend que ceux de sa candidature), relu a chaque
// signal de la veille des messages.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/communications/ma_candidature_fil.dart';
import '../../core/communications/veille_messages.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/observabilite/journal_dev.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/vue_etat_communication.dart';
import '../com_messages/entree_messages_candidature.dart';
import '../com_messages/fil_en_place.dart';
import '../com_messages/port_messages_metier.dart';

/// Les rubriques de l'onglet Messages.
enum SectionMessages {
  /// La conversation avec l'academie.
  messages(null),

  /// Les annonces, en grille.
  annonces('annonces'),

  /// Ce que les candidats n'ont pas encore (interface seulement).
  savoir('savoir');

  const SectionMessages(this.parametre);

  /// La valeur du parametre `section` de l'adresse ; nulle pour Messages.
  final String? parametre;

  /// Le nom du parametre de l'adresse.
  static const String cleParametre = 'section';

  /// La rubrique d'une adresse ; Messages pour une valeur inconnue.
  static SectionMessages depuis(String? parametre) {
    for (final SectionMessages s in values) {
      if (s.parametre == parametre) return s;
    }
    return SectionMessages.messages;
  }

  /// Le libelle de la rubrique.
  String get libelle {
    final s = t.recrutement.accueil.messages.sections;
    return switch (this) {
      SectionMessages.messages => s.messages,
      SectionMessages.annonces => s.annonces,
      SectionMessages.savoir => s.savoir,
    };
  }
}

/// Les messages recus non lus du candidat (messages, pas conversations :
/// directeur, 20/11/2026). 0 quand rien n'est lisible : rien n'est pose.
final FutureProvider<int> messagesNonLusCandidatProvider =
    FutureProvider.autoDispose<int>((Ref ref) async {
      ref.watch(
        etatVeilleMessagesProvider.select((EtatVeilleMessages e) => e.rang),
      );
      try {
        int total = 0;
        for (final ResumeFil f
            in await ref.watch(portMessagesMetierProvider).fils()) {
          if (estFilMetier(f)) total += f.attention.nonLus;
        }
        return total;
      } on CapaciteIndisponible {
        return 0;
      } on Object catch (e) {
        journalDev('Non lus du candidat illisibles : ${e.runtimeType}');
        return 0;
      }
    }, retry: (int retryCount, Object error) => null);

/// Le fil deja ouvert de la conversation du candidat avec l'academie, ou
/// `null` (pas encore ouvert, ou plusieurs interlocuteurs : l'entree
/// existante les liste). Jamais cree ici : un fil ne s'ouvre qu'a la demande
/// de la personne.
final FutureProvider<String?> filCandidatProvider =
    FutureProvider.autoDispose<String?>((Ref ref) async {
      final String? id = await ref.watch(maCandidatureIdProvider.future);
      if (id == null) return null;
      final List<ConversationPossible> possibles = await ref
          .watch(portMessagesMetierProvider)
          .conversationsPourObjet(TypeObjetLie.candidature, id);
      if (possibles.length != 1) return null;
      return possibles.single.filId;
    }, retry: (int retryCount, Object error) => null);

/// Le selecteur des trois rubriques.
class SelecteurMessages extends StatelessWidget {
  /// Cree le selecteur.
  const SelecteurMessages({
    required this.section,
    required this.onChange,
    super.key,
  });

  /// La rubrique ouverte.
  final SectionMessages section;

  /// Ouvre une rubrique.
  final ValueChanged<SectionMessages> onChange;

  @override
  Widget build(BuildContext context) => SelecteurSection<SectionMessages>(
    libelle: t.recrutement.accueil.messages.sections.libelle,
    valeur: section,
    onChange: onChange,
    sections: <Segment<SectionMessages>>[
      for (final SectionMessages s in SectionMessages.values)
        Segment<SectionMessages>(valeur: s, libelle: s.libelle),
    ],
  );
}

/// La rubrique Messages : la conversation, en place, ou son entree.
///
/// Elle remplit la hauteur que la page lui donne : le fil defile seul, champ
/// en bas, au-dessus de la barre (la page des messages, telle quelle).
class ConversationCandidat extends ConsumerWidget {
  /// Cree la rubrique. [onReplier] : le retour de la barre du fil.
  const ConversationCandidat({required this.onReplier, super.key});

  /// Le retour de la barre du fil (l'accueil reprend l'onglet Dossier).
  final VoidCallback onReplier;

  /// La cle de la phrase « pas de messagerie ».
  static const Key cleVide = ValueKey<String>('accueil-candidat-messages-vide');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<String?> id = ref.watch(maCandidatureIdProvider);
    final m = t.recrutement.accueil.messages;
    final TextStyle muet = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());
    Widget court(Widget enfant) =>
        SingleChildScrollView(primary: false, child: enfant);
    // Pas de messagerie pour cette candidature (serveur d'avant, ou aucune
    // candidature enregistree) : une phrase, jamais une rubrique vide.
    final bool sans =
        id.error is CapaciteIndisponible || (id.hasValue && id.value == null);
    if (!id.hasValue && !id.hasError) {
      return court(const Skeleton.liste(lignes: 2));
    }
    if (sans) return court(Text(m.vide, key: cleVide, style: muet));
    // L'echec de lecture de l'identifiant : l'entree le dit (« Reessayer »).
    if (id.hasError) return court(const EntreeMessagesCandidature());
    final AsyncValue<String?> fil = ref.watch(filCandidatProvider);
    if (!fil.hasValue && !fil.hasError) {
      return court(const Skeleton.liste(lignes: 2));
    }
    if (fil.hasError && fil.error is! CapaciteIndisponible) {
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      return court(
        VueEtatCommunication(
          etat: horsLigne
              ? EtatCommunication.horsLigne
              : EtatCommunication.erreur,
          onReessayer: () => ref.invalidate(filCandidatProvider),
        ),
      );
    }
    final String? filId = fil.hasValue ? fil.value : null;
    if (filId == null) {
      return court(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(m.intro, style: muet),
            const EntreeMessagesCandidature(ecartAvant: Ecart.vLg),
          ],
        ),
      );
    }
    return FilEnPlace(
      filId: filId,
      onReplier: onReplier,
      onLu: () => ref.invalidate(messagesNonLusCandidatProvider),
    );
  }
}
