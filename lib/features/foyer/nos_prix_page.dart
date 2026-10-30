// « Nos prix, en toute transparence » (TRANSPARENCE, directeur, 30/10/2026 ;
// DECISION-BIBLIOTHEQUE-ET-RESTES-2026-10-30.md §2 ; DECISION-TARIFS, 22/10) :
// pour le tuteur et l'eleve adulte, atteinte depuis leurs finances.
//
// La repartition de chaque paiement d'un eleve, **en pourcentages seulement** :
// aucun montant de charge, aucune paie horaire. Les parts viennent du serveur
// (`politique_commerciale_famille`, table versionnee `repartitions_paiement`) ;
// aucune n'est ecrite ici. Puis trois paragraphes fixes : pourquoi pas les
// magasins d'applications, les prix peuvent augmenter, les montants exacts se
// demandent a l'administration.
//
// Etats : chargement, contenu, vide (aucune repartition publiee), erreur, hors
// ligne, et production sans source (`CapaciteIndisponible`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/finance/politique_famille.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import 'finances_foyer.dart';
import 'ligne_membre.dart' show dateEcheance;

/// Une part en pour mille, dite en pourcentage au dixieme : 470 -> « 47 % »,
/// 11 -> « 1,1 % » (« 1٫1 ٪ » en arabe). Fonction pure.
String partEnPourcent(int pourMille) {
  final int dixieme = pourMille % 10;
  final String valeur = dixieme == 0
      ? '${pourMille ~/ 10}'
      : '${pourMille ~/ 10}${t.argent.transparence.virgule}$dixieme';
  return t.argent.transparence.part(valeur: valeur);
}

/// Le libelle d'un poste de la repartition.
String libellePoste(PosteRepartition poste) {
  return switch (poste) {
    PosteRepartition.enseignant => t.argent.transparence.postes.enseignant,
    PosteRepartition.fraisCarteChange =>
      t.argent.transparence.postes.fraisCarteChange,
    PosteRepartition.fraisEnvoiPaie =>
      t.argent.transparence.postes.fraisEnvoiPaie,
    PosteRepartition.visioconference =>
      t.argent.transparence.postes.visioconference,
    PosteRepartition.applicationHebergement =>
      t.argent.transparence.postes.applicationHebergement,
    PosteRepartition.emails => t.argent.transparence.postes.emails,
    PosteRepartition.stockage => t.argent.transparence.postes.stockage,
    PosteRepartition.comptabilite => t.argent.transparence.postes.comptabilite,
    PosteRepartition.developpement =>
      t.argent.transparence.postes.developpement,
    PosteRepartition.administration =>
      t.argent.transparence.postes.administration,
    PosteRepartition.impotSocietes =>
      t.argent.transparence.postes.impotSocietes,
    PosteRepartition.benefice => t.argent.transparence.postes.benefice,
  };
}

/// La page « Nos prix, en toute transparence ».
class NosPrixPage extends ConsumerWidget {
  /// Cree la page.
  const NosPrixPage({required this.onRetour, super.key});

  /// Le retour vers les finances d'ou elle a ete ouverte.
  final VoidCallback onRetour;

  /// La carte de la repartition.
  static const Key repartitionCle = Key('prix.repartition');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PageShell(
      titre: t.argent.transparence.titre,
      onRetour: onRetour,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurLecture),
          child: _Etats(lecture: ref.watch(politiqueActiveProvider)),
        ),
      ),
    );
  }
}

class _Etats extends ConsumerWidget {
  const _Etats({required this.lecture});

  final AsyncValue<PolitiqueFamille> lecture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Object? erreur = lecture.hasError ? lecture.error : null;
    if (erreur is CapaciteIndisponible) {
      return EtatSysteme(
        nature: NatureEtat.indisponible,
        portee: PorteeEtat.page,
        titre: t.argent.transparence.indisponibleTitre,
        phrase: t.argent.transparence.indisponiblePhrase,
        dependance: erreur.dependance,
      );
    }
    void relire() => ref.invalidate(politiqueActiveProvider);
    if (erreur != null) {
      return (ref.watch(horsLigneProvider).value ?? false)
          ? EtatSansDonnees(
              quoi: t.argent.transparence.sansDonnees,
              onAction: relire,
            )
          : EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: t.argent.transparence.erreurTitre,
              onAction: relire,
            );
    }
    if (!lecture.hasValue) return const Skeleton.liste(lignes: 6);
    final RepartitionPaiement? repartition = lecture.requireValue.repartition;
    if (repartition == null) {
      return EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.argent.transparence.videTitre,
        phrase: t.argent.transparence.videPhrase,
      );
    }
    return _Contenu(repartition: repartition);
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.repartition});

  final RepartitionPaiement repartition;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final TextStyle corps = palette.inkStrong.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );
    final TextStyle note = palette.inkMuted.applyTo(
      textes.bodySmall ?? const TextStyle(),
    );
    Widget titre(String texte) => Semantics(
      header: true,
      child: Text(
        texte,
        style: palette.inkStrong.applyTo(
          textes.titleMedium ?? const TextStyle(),
        ),
      ),
    );
    // La somme affichee est celle des parts rendues (l'adaptateur refuse une
    // repartition qui ne fait pas 1000) : jamais un « 100 % » ecrit en dur.
    final int somme = repartition.postes.fold<int>(
      0,
      (int s, PartPoste p) => s + p.pourMille,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(t.argent.transparence.intro, style: corps),
        Ecart.vXl,
        titre(t.argent.transparence.repartitionTitre),
        Text(
          t.argent.transparence.version(
            date: dateEcheance(repartition.dateEffet),
          ),
          style: note,
        ),
        Ecart.vSm,
        AppCard(
          key: NosPrixPage.repartitionCle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final PartPoste p in repartition.postes)
                MergeSemantics(
                  child: Semantics(
                    label: t.argent.transparence.posteSemantique(
                      poste: libellePoste(p.poste),
                      part: partEnPourcent(p.pourMille),
                    ),
                    excludeSemantics: true,
                    child: LigneCleValeur(
                      cle: libellePoste(p.poste),
                      valeur: partEnPourcent(p.pourMille),
                      chiffres: true,
                      valeurEnFin: true,
                    ),
                  ),
                ),
              const Divider(),
              LigneCleValeur(
                cle: t.argent.transparence.total,
                valeur: partEnPourcent(somme),
                chiffres: true,
                valeurEnFin: true,
                valeurForte: true,
              ),
            ],
          ),
        ),
        Ecart.vSm,
        Text(
          t.argent.transparence.estimation(
            enfants: repartition.baseElevesEnfants,
            adultes: repartition.baseElevesAdultes,
          ),
          style: note,
        ),
        Ecart.vXxl,
        titre(t.argent.transparence.magasinsTitre),
        Ecart.vXs,
        Text(t.argent.transparence.magasinsPhrase, style: corps),
        Ecart.vXxl,
        titre(t.argent.transparence.hausseTitre),
        Ecart.vXs,
        Text(t.argent.transparence.haussePhrase, style: corps),
        Ecart.vXxl,
        titre(t.argent.transparence.montantsTitre),
        Ecart.vXs,
        Text(t.argent.transparence.montantsPhrase, style: corps),
      ],
    );
  }
}
