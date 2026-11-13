/// ESPACE-APPRENDRE (lot 5) : l'onglet « Bibliotheque » de l'espace Apprendre.
///
/// Une coquille mince : tout le contenu est la planche commune
/// ([PlancheDocuments], `lib/core/apprendre`), alimentee par l'adaptateur du
/// catalogue existant ([documentsApprendreProvider]). Les cinq etats : le
/// squelette pendant la lecture, la planche (contenu, vide des rayons, aucun
/// resultat de filtre), l'echec avec « Reessayer », hors ligne.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/apprendre/document_planche.dart';
import '../../core/apprendre/documents_apprendre.dart';
import '../../core/apprendre/planche_documents.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';

/// Les cles des tests.
abstract final class ClesBibliotheque {
  /// Le squelette.
  static const Key chargement = ValueKey<String>('apprendre-bib-chargement');

  /// L'echec de lecture.
  static const Key erreur = ValueKey<String>('apprendre-bib-erreur');
}

/// L'onglet.
class OngletBibliotheque extends ConsumerWidget {
  /// Cree l'onglet.
  const OngletBibliotheque({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DocumentPlanche>> documents = ref.watch(
      documentsApprendreProvider,
    );
    if (documents.hasError && !documents.hasValue) {
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      void relire() => ref.invalidate(documentsApprendreProvider);
      return horsLigne
          // Le bandeau de la page dit l'absence de reseau ; le bloc dit ce qui
          // manque.
          ? EtatSansDonnees(
              key: ClesBibliotheque.erreur,
              quoi: t.tc.bibliotheque.indisponible.message,
              onAction: relire,
            )
          : EmptyState(
              key: ClesBibliotheque.erreur,
              message: t.tc.bibliotheque.indisponible.message,
              invitation: t.tc.bibliotheque.indisponible.invitation,
              icone: AppIcons.avertissement,
              libelleAction: t.tc.bibliotheque.indisponible.action,
              onAction: relire,
            );
    }
    if (!documents.hasValue) {
      return const Skeleton.liste(key: ClesBibliotheque.chargement, lignes: 4);
    }
    // La carte « Coran » est reecrite ici, dans la langue courante : le
    // fournisseur garde la langue de sa lecture.
    return PlancheDocuments(
      documents: <DocumentPlanche>[
        for (final DocumentPlanche d in documents.requireValue)
          d.id == idDocumentCoran ? documentCoran() : d,
      ],
    );
  }
}
