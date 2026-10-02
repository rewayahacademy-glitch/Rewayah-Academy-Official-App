// Les soldes du foyer (EA-9, planche 4.1 et colonne droite de 6, UX_REVIEW_07
// ligne 14) : une ligne par beneficiaire autorise, son solde TEL QUE RENDU,
// une pastille seulement pour une exception rendue, un seul bouton
// « Recharger » au bord de fin, 16 sous la liste, puis un recapitulatif
// discret.
//
// Aucun ecran ni composant neuf (K-51) : un `GroupeReglages` du Compte, la
// `PhotoEleve` du Foyer (K-44 ; initiales quand le serveur ne rend pas de
// photo, le second adulte, Q4), la `StatusPill` partagee et `ActionPrincipale`.
// Aucun calcul (F9, F12) : ni total, ni seuil, ni taux, ni devise ajoutes ici.
// Aucune source serveur a ce jour (EA-BR-23) : le port rend
// `CapaciteIndisponible`, la demonstration surcharge le fournisseur (K-28).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/port_paiements_foyer.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../foyer/photo_eleve.dart';
import 'donnees_compte.dart';

/// La section des soldes du foyer, pour le titulaire.
class SoldesFoyerSection extends ConsumerWidget {
  /// Cree la section.
  const SoldesFoyerSection({super.key, this.titre, this.onRecharger});

  /// Le titre du groupe ; par defaut « Beneficiaires ». La colonne droite
  /// de Ma famille sur bureau y passe « Paiements du foyer » (planche 6).
  final String? titre;

  /// Ouvre la recharge (EA-10). Sans lui, le bouton n'est pas pose.
  final VoidCallback? onRecharger;

  /// La section.
  static const Key cle = Key('paiements.soldes');

  /// Le bouton « Recharger ».
  static const Key rechargerKey = Key('paiements.recharger');

  /// Le recapitulatif du foyer.
  static const Key recapitulatifKey = Key('paiements.recapitulatif');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SoldesFoyer> soldes = ref.watch(soldesFoyerProvider);
    void relire() => ref.invalidate(soldesFoyerProvider);
    final Object? erreur = soldes.hasError ? soldes.error : null;
    final Widget corps;
    if (erreur is CapaciteIndisponible) {
      // Libelles provisoires, lexique D4.
      corps = EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.adulte.paiements.soldesIndisponiblesTitre,
        phrase: t.adulte.paiements.soldesIndisponiblesPhrase,
        dependance: erreur.dependance,
      );
    } else if (erreur != null &&
        (ref.watch(horsLigneProvider).value ?? false)) {
      // Sans reseau, un echec se dit « hors ligne », comme Ma famille.
      corps = EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire);
    } else {
      corps = BlocAsynchrone<SoldesFoyer>(
        valeur: soldes,
        squelette: const Skeleton.liste(),
        onReessayer: relire,
        estVide: (SoldesFoyer s) => s.beneficiaires.isEmpty,
        // Libelles provisoires, lexique D4.
        vide: EtatSysteme(
          nature: NatureEtat.aucunResultat,
          titre: t.adulte.paiements.aucunBeneficiaireTitre,
          phrase: t.adulte.paiements.aucunBeneficiairePhrase,
        ),
        construire: (SoldesFoyer s) =>
            _Soldes(s, titre ?? t.adulte.paiements.beneficiaires, onRecharger),
      );
    }
    final String? titreLu = titre;
    return KeyedSubtree(
      key: cle,
      // Sans valeur, le titre reste pose au-dessus de l'etat : la section
      // garde son nom, et rien ne saute quand les soldes arrivent.
      child: soldes.hasValue && !soldes.hasError
          ? corps
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Titre(titreLu ?? t.adulte.paiements.beneficiaires),
                Ecart.vSm,
                corps,
              ],
            ),
    );
  }
}

class _Titre extends StatelessWidget {
  const _Titre(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      texte,
      style: AppPalette.of(context).inkStrong.applyTo(
        Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
      ),
    ),
  );
}

/// Le libelle d'une exception rendue, en un mot (jamais la couleur seule).
String libelleExceptionSolde(ExceptionSolde e) => switch (e) {
  ExceptionSolde.bientotEpuise => t.adulte.paiements.bientotEpuise,
  ExceptionSolde.inactif => t.adulte.paiements.inactif,
};

TonEtat _ton(ExceptionSolde e) => switch (e) {
  ExceptionSolde.bientotEpuise => TonEtat.avertissement,
  ExceptionSolde.inactif => TonEtat.neutre,
};

class _Soldes extends StatelessWidget {
  const _Soldes(this.soldes, this.titre, this.onRecharger);

  final SoldesFoyer soldes;
  final String titre;
  final VoidCallback? onRecharger;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final String? recapitulatif = soldes.recapitulatif;
    final VoidCallback? recharger = onRecharger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GroupeReglages(
          titre: titre,
          lignes: <LigneRubrique>[
            for (final SoldeBeneficiaire b in soldes.beneficiaires)
              LigneRubrique(
                meneur: PhotoEleve(
                  prenom: b.prenom,
                  cleAvatar: b.cleAvatar,
                  diametre: AppSpacing.section,
                ),
                libelle: b.prenom,
                // Le solde tel que rendu, sans unite ajoutee (E2, Q9).
                valeur: b.soldeRendu,
                marque: switch (b.exception) {
                  final ExceptionSolde e => StatusPill(
                    libelle: libelleExceptionSolde(e),
                    ton: _ton(e),
                  ),
                  null => null,
                },
              ),
          ],
        ),
        // Un seul bouton dominant, au bord de fin, 16 sous la liste
        // (UX_REVIEW_07 ligne 14 d, contrat A). `IntrinsicWidth` : sans lui,
        // `ActionPrincipale` s'etire a toute la colonne (motif de Ma famille).
        if (recharger != null) ...<Widget>[
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IntrinsicWidth(
              child: ActionPrincipale(
                key: SoldesFoyerSection.rechargerKey,
                libelle: t.adulte.paiements.recharger,
                pleineLargeur: false,
                onPress: recharger,
              ),
            ),
          ),
        ],
        // Le recapitulatif, discret : une phrase rendue, jamais un « budget »
        // ni un « total disponible » (F9, ligne 14 c). Libelle provisoire,
        // lexique D4.
        if (recapitulatif != null) ...<Widget>[
          Ecart.vXl,
          Text(
            key: SoldesFoyerSection.recapitulatifKey,
            t.adulte.paiements.recapitulatif(valeur: recapitulatif),
            style: palette.inkMuted.applyTo(
              Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
  }
}
