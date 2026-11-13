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
import '../../core/router/etat_routeur_sur.dart';
import '../../core/tc_bibliotheque/couverture_ressource.dart';
import '../../core/tc_bibliotheque/library_resource.dart'
    show RayonBibliotheque;
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../tc_catalogue/vignette_ressource.dart';

/// Les cles des tests.
abstract final class ClesBibliotheque {
  /// Le squelette.
  static const Key chargement = ValueKey<String>('apprendre-bib-chargement');

  /// L'echec de lecture.
  static const Key erreur = ValueKey<String>('apprendre-bib-erreur');

  /// La place reservee de « Pour cette classe » pendant sa lecture.
  static const Key classeChargement = ValueKey<String>(
    'apprendre-bib-classe-chargement',
  );

  /// L'echec de lecture de « Pour cette classe ».
  static const Key classeErreur = ValueKey<String>(
    'apprendre-bib-classe-erreur',
  );
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
    // « Pour cette classe » : seulement quand l'eleve vient de sa classe
    // (`?groupe=`) ; ces documents ne sont montres qu'une fois, dans cette
    // rubrique, et plus dans « Documents des cours ». Pendant la lecture, sa
    // place est reservee ; en echec, elle le dit, sans se confondre avec
    // « aucun document » (qui, lui, la fait disparaitre). Le reste de la
    // Bibliotheque ne depend jamais d'elle.
    final String? groupe = parametreRouteurSur(
      context,
      parametreGroupeApprendre,
    );
    final AsyncValue<List<DocumentPlanche>>? classeLue =
        groupe == null || groupe.isEmpty
        ? null
        : ref.watch(documentsDeLaClasseProvider(groupe));
    final List<DocumentPlanche> classe =
        classeLue?.value ?? const <DocumentPlanche>[];
    Widget? rubrique;
    if (classeLue != null && !classeLue.hasValue) {
      if (classeLue.hasError) {
        final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
        void relire() => ref.invalidate(documentsDeLaClasseProvider(groupe!));
        rubrique = _RubriqueClasse(
          cle: ClesBibliotheque.classeErreur,
          corps: horsLigne
              ? EtatSansDonnees(
                  quoi: t.apprendre.bibliotheque.classeErreur.message,
                  onAction: relire,
                )
              : EmptyState(
                  message: t.apprendre.bibliotheque.classeErreur.message,
                  invitation: t.apprendre.bibliotheque.classeErreur.invitation,
                  icone: AppIcons.avertissement,
                  libelleAction: t.commun.reessayer,
                  onAction: relire,
                ),
        );
      } else {
        rubrique = const _RubriqueClasse(
          cle: ClesBibliotheque.classeChargement,
          corps: Skeleton.liste(lignes: 2),
        );
      }
    }
    final Set<String> dansLaClasse = <String>{
      for (final DocumentPlanche d in classe) d.id,
    };
    return PlancheDocuments(
      rubriqueClasse: rubrique,
      rayons:
          ref.watch(rayonsApprendreProvider).value ??
          const <RayonBibliotheque>[],
      documents: <DocumentPlanche>[
        for (final DocumentPlanche d in <DocumentPlanche>[
          ...classe,
          for (final DocumentPlanche d in documents.requireValue)
            if (!dansLaClasse.contains(d.id))
              d.id == idDocumentCoran ? documentCoran() : d,
        ])
          _avecVignette(d),
      ],
    );
  }
}

/// La vignette de la Bibliotheque une (lot 3) pour [d] : la meme couverture
/// que les cartes de la liste d'origine (par defaut selon le type, ou la
/// vignette deposee par-dessus). Une seule couverture pour un document.
DocumentPlanche _avecVignette(DocumentPlanche d) {
  final CouvertureRessource? couverture = d.couverture;
  if (couverture == null) return d;
  return d.avecVignette(
    VignetteRessource(
      couverture: couverture,
      image: d.aVignetteDeposee ? ImageVignetteDeposee(resourceId: d.id) : null,
    ),
  );
}

/// La rubrique « Pour cette classe » quand elle attend ou ne s'affiche pas :
/// son titre, et dessous l'attente ou la phrase d'echec.
class _RubriqueClasse extends StatelessWidget {
  const _RubriqueClasse({required this.cle, required this.corps});

  final Key cle;
  final Widget corps;

  @override
  Widget build(BuildContext context) => Column(
    key: cle,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SectionHeader(titre: t.apprendre.bibliotheque.rayonClasse),
      Ecart.vMd,
      corps,
    ],
  );
}
