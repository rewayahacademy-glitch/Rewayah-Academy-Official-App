// Le detail d'un encaissement (FIN-CPT-W05, panneau a 1440 et page sous
// 1200 ; spec §24.2, §24.3, §33, §43, §48).
//
// Le panneau §33 : brut, frais, net, reference, prestataire, foyer,
// affectation, rapprochement ; puis le journal de l'operation (§48), tel que
// la source le rend. Flutter n'additionne rien : le net arrive calcule, les
// frais aussi (§43, DR-23). « Confirme » seulement si la source le dit
// (§24.3) : l'ecran n'en deduit jamais l'etat. Aucun « Voir le recu » : la
// source n'en rend pas (UX_REVIEW §5.5, S).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/port_encaissements.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/skeleton.dart';
import 'commun_encaissements.dart';
import 'donnees_encaissements.dart';

/// Vrai quand l'encaissement attend encore une action de rapprochement : le
/// lien vers l'espace de rapprochement se montre alors.
bool attendRapprochement(Encaissement e) =>
    e.etat == EtatEncaissement.aRapprocher ||
    switch (e.rapprochement) {
      EtatRapprochement.aVerifier ||
      EtatRapprochement.conflit ||
      EtatRapprochement.sansCorrespondance ||
      EtatRapprochement.doublonPotentiel => true,
      _ => false,
    };

/// Le contenu du detail d'un encaissement, commun au panneau et a la page.
class ContenuEncaissement extends StatelessWidget {
  /// Cree le contenu.
  const ContenuEncaissement({
    required this.encaissement,
    super.key,
    this.avecTitre = true,
  });

  /// L'encaissement rendu par la source.
  final Encaissement encaissement;

  /// Faux sur la page, dont l'en-tete porte deja le titre.
  final bool avecTitre;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final e = t.comptable.encaissements;
    final Encaissement enc = encaissement;
    final String? note = switch (enc.etat) {
      EtatEncaissement.confirme ||
      EtatEncaissement.aRapprocher ||
      EtatEncaissement.rapproche => e.confirmeNote,
      EtatEncaissement.enAttente => e.enAttenteNote,
      _ => null,
    };
    final EtatRapprochement? rapprochement = enc.rapprochement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (avecTitre) ...<Widget>[
          Semantics(
            header: true,
            child: Text(
              enc.famille,
              style: palette.inkStrong.applyTo(
                textes.titleLarge ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vXs,
          NoteAttenuee(dateComptable(enc.date)),
          Ecart.vMd,
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            PastilleEncaissement(enc.etat),
            if (rapprochement != null) PastilleRapprochement(rapprochement),
          ],
        ),
        if (note != null) ...<Widget>[Ecart.vSm, NoteAttenuee(note)],
        Ecart.vLg,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LigneMontant(libelle: e.brut, montant: enc.brut),
              LigneMontant(
                libelle: e.frais,
                montant: enc.frais,
                detail: e.fraisSource,
              ),
              LigneMontant(libelle: e.net, montant: enc.net, fort: true),
            ],
          ),
        ),
        Ecart.vLg,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LigneCleValeur(
                cle: e.reference,
                valeur: enc.reference,
                chiffres: true,
              ),
              LigneCleValeur(cle: e.prestataire, valeur: enc.prestataire),
              LigneCleValeur(cle: e.moyen, valeur: enc.moyen),
              LigneCleValeur(cle: e.foyer, valeur: enc.famille),
              LigneCleValeur(cle: e.devise, valeur: enc.brut.devise),
              LigneCleValeur(cle: e.date, valeur: dateComptable(enc.date)),
            ],
          ),
        ),
        Ecart.vLg,
        TitreZone(e.affectation),
        Ecart.vSm,
        AppCard(
          child: enc.profils.isEmpty
              ? NoteAttenuee(e.affectationAucune)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final AffectationProfil p in enc.profils)
                      LigneMontant(libelle: p.prenom, montant: p.montant),
                  ],
                ),
        ),
        Ecart.vLg,
        TitreZone(e.rapprochement),
        Ecart.vSm,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (rapprochement != null)
                PastilleRapprochement(rapprochement)
              else
                NoteAttenuee(e.rapprochementAucun),
              if (attendRapprochement(enc)) ...<Widget>[
                Ecart.vSm,
                LienFleche(
                  libelle: e.ouvrirRapprochement,
                  onPress: () => context.go(Routes.comptableRapprochement),
                ),
              ],
            ],
          ),
        ),
        Ecart.vLg,
        TitreZone(e.journal),
        Ecart.vSm,
        JournalOperation(objetId: enc.id, vide: e.journalVide),
      ],
    );
  }
}

/// Le journal d'un encaissement ou d'un remboursement (§48), lu sur le port
/// des encaissements ; rien n'est invente quand la source ne rend rien.
class JournalOperation extends ConsumerWidget {
  /// Cree le journal.
  const JournalOperation({
    required this.objetId,
    required this.vide,
    super.key,
  });

  /// L'objet.
  final String objetId;

  /// La phrase quand le journal est vide.
  final String vide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: BlocEncaissements<List<EntreeJournal>>(
        valeur: ref.watch(journalEncaissementProvider(objetId)),
        onReessayer: () => ref.invalidate(journalEncaissementProvider(objetId)),
        squelette: const Skeleton.texte(lignes: 2),
        vide: NoteAttenuee(vide),
        construire: (List<EntreeJournal> entrees) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final EntreeJournal entree in entrees) LigneActivite(entree),
          ],
        ),
      ),
    );
  }
}

/// Le detail lu sur le port (page sous 1200, panneau a 1440).
class DetailEncaissementLu extends ConsumerWidget {
  /// Cree le detail.
  const DetailEncaissementLu({
    required this.encaissementId,
    super.key,
    this.avecTitre = true,
  });

  /// L'encaissement.
  final String encaissementId;

  /// Voir [ContenuEncaissement.avecTitre].
  final bool avecTitre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocEncaissements<Encaissement>(
      valeur: ref.watch(detailEncaissementProvider(encaissementId)),
      onReessayer: () =>
          ref.invalidate(detailEncaissementProvider(encaissementId)),
      squelette: const Skeleton.texte(lignes: 6),
      construire: (Encaissement enc) =>
          ContenuEncaissement(encaissement: enc, avecTitre: avecTitre),
    );
  }
}
