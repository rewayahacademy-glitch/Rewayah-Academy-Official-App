// Les zones d'Aujourd'hui du Comptable (FIN-CPT-W01, spec §29 ; CPT-JOUR) :
// paiements a effectuer, echeances, encaissements recents, prestataires,
// activite recente, acces rapides. La synthese de tresorerie et la Reserve
// sont importees de `lib/core/widgets/comptable/` (proprietes de CPT-TRES).
//
// Regles tenues ici :
// - **aucun bouton Payer** (DR-11) : une ligne ouvre l'ecran canonique,
//   la ou le detail se lit avant de payer (spec §5.1, §13.3) ;
// - **aucun graphique** (DR-09) : des lignes, des montants, des pastilles ;
// - tout montant passe par `MontantSensible` (masque par defaut, spec §7) ;
// - Flutter n'additionne aucun montant : chaque total vient de la source.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/capacites/port_aujourdhui_comptable.dart';
import '../../../core/comptable/modeles_comptable.dart';
import '../../../core/finance/montant.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/carte_lignes.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/montant_sensible.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import '../../../core/widgets/pressable.dart';
import 'file_attention.dart';

/// Une ligne d'une zone d'Aujourd'hui, posee dans une [CarteLignes] : un
/// titre, une precision, a la fin un montant ou une pastille, et le chevron
/// quand la ligne mene a un ecran. Texte agrandi (200 %) : la fin passe sous
/// le titre avec le chevron, au bord de fin, et aucun mot n'est coupe.
class LigneZone extends StatelessWidget {
  /// Cree la ligne.
  const LigneZone({
    required this.titre,
    super.key,
    this.precision,
    this.fin,
    this.onPress,
  });

  /// Ce dont il s'agit : « Facture #024 », « Famille Diallo ».
  final String titre;

  /// La precision : une date en mots, un beneficiaire.
  final String? precision;

  /// Ce qui se pose au bord de fin : un montant masquable, une pastille.
  final Widget? fin;

  /// L'ecran canonique ; nul : la ligne se lit seulement.
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? p = precision;
    final Widget? f = fin;
    final bool empiler =
        MediaQuery.textScalerOf(context).scale(AppSpacing.lg) / AppSpacing.lg >=
        AppGabarit.seuilTexteColonne;
    final Widget textes0 = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          titre,
          style: palette.inkStrong.applyTo(
            textes.titleSmall ?? const TextStyle(),
          ),
        ),
        if (p != null) ...<Widget>[
          Ecart.vXs,
          Text(
            p,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
        ],
      ],
    );
    final Widget chevron = IconTheme(
      data: palette.inkMuted.asIconTheme(size: AppSpacing.xl),
      // Le chevron se miroite en arabe : une direction de lecture.
      child: Icon(AppIcons.chevron.repos),
    );
    final bool menant = onPress != null;
    final Widget ligne;
    if (empiler) {
      // Texte agrandi : le titre prend toute la largeur de la carte ; la fin
      // et le chevron passent dessous, au bord de fin, pour qu'aucun mot ne
      // se coupe dans une carte etroite (marge laterale resserree d'un cran).
      ligne = Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            textes0,
            if (f != null || menant) ...<Widget>[
              Ecart.vXs,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (f != null) Flexible(child: f),
                  if (menant) ...<Widget>[Ecart.hSm, chevron],
                ],
              ),
            ],
          ],
        ),
      );
    } else {
      final Widget corps = f == null
          ? textes0
          : Row(
              children: <Widget>[
                Expanded(child: textes0),
                Ecart.hMd,
                // Borne la fin a la moitie de la ligne : une pastille et un
                // montant passent a la ligne au lieu de deborder dans une
                // colonne etroite, sans couper « Temporairement ».
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: f,
                  ),
                ),
              ],
            );
      ligne = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: corps),
            if (menant) ...<Widget>[Ecart.hSm, chevron],
          ],
        ),
      );
    }
    final VoidCallback? appui = onPress;
    return MergeSemantics(
      child: appui == null
          ? ligne
          : Pressable(
              onPress: appui,
              respecterCibleTactile: false,
              child: ligne,
            ),
    );
  }
}

/// Une phrase calme quand une zone est vide : un constat, en encre
/// attenuee, dans la carte de la zone. Un jour sans echeance n'est pas une
/// panne : pas d'illustration.
class VideZone extends StatelessWidget {
  /// Cree le constat.
  const VideZone(this.message, {super.key, this.precision});

  /// Le constat.
  final String message;

  /// La precision, quand il y en a une.
  final String? precision;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final String? p = precision;
    return CarteLignes(
      lignes: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                message,
                style: palette.inkStrong.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
              if (p != null) ...<Widget>[
                Ecart.vXs,
                Text(
                  p,
                  style: palette.inkMuted.applyTo(
                    textes.bodySmall ?? const TextStyle(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Zone 6 : les paiements a effectuer, par famille (enseignants,
/// contractuels), avec leur nombre et le total **rendu par la source**.
/// Chaque ligne ouvre la liste canonique deja filtree (W02 ou W06) : aucun
/// bouton Payer ici (DR-11).
class ZonePaiementsAEffectuer extends StatelessWidget {
  /// Cree la zone.
  const ZonePaiementsAEffectuer(this.elements, {super.key});

  /// Les familles a payer, rendues par la source.
  final List<ElementAttention> elements;

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.aujourdhui;
    if (elements.isEmpty) return VideZone(a.paiementsVide);
    return CarteLignes(
      lignes: <Widget>[
        for (final ElementAttention e in elements)
          LigneZone(
            key: ValueKey<String>('paiement-${e.id}'),
            titre: a.elementCompteur(
              libelle: libelleTypeAlerte(e.type),
              n: e.compteur,
            ),
            precision: a.paiementsAEffectuerDetail,
            fin: _montantOuRien(e.montant),
            onPress: () => context.go(e.route),
          ),
      ],
    );
  }
}

/// Zone 4 : les echeances proches, datees (obligations et remboursements ;
/// jamais une facture de fournisseur non specifiee, DR-25).
class ZoneEcheances extends StatelessWidget {
  /// Cree la zone.
  const ZoneEcheances(this.echeances, {super.key, this.limite});

  /// Les echeances, dans l'ordre de la source.
  final List<EcheanceComptable> echeances;

  /// Le nombre maximal de lignes (telephone) ; nul : toutes.
  final int? limite;

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.aujourdhui;
    if (echeances.isEmpty) return VideZone(a.echeancesVide);
    final int? max = limite;
    final List<EcheanceComptable> rendues =
        max == null || echeances.length <= max
        ? echeances
        : echeances.sublist(0, max);
    return CarteLignes(
      lignes: <Widget>[
        for (final EcheanceComptable e in rendues)
          LigneZone(
            key: ValueKey<String>('echeance-${e.id}'),
            titre: e.libelle,
            precision: <String>[
              dateComptable(e.date),
              ?e.beneficiaire?.nom,
            ].join(' · '),
            fin: _montantOuRien(e.montant),
            onPress: () => context.go(e.route),
          ),
      ],
    );
  }
}

/// Zone 5 : les encaissements recents, avec leur etat (§24.1) ; chacun
/// ouvre son detail (W05).
class ZoneEncaissementsRecents extends StatelessWidget {
  /// Cree la zone.
  const ZoneEncaissementsRecents(this.encaissements, {super.key});

  /// Les encaissements, dans l'ordre de la source.
  final List<EncaissementRecent> encaissements;

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.aujourdhui;
    if (encaissements.isEmpty) return VideZone(a.encaissementsVide);
    return CarteLignes(
      lignes: <Widget>[
        for (final EncaissementRecent e in encaissements)
          LigneZone(
            key: ValueKey<String>('encaissement-${e.id}'),
            titre: e.famille,
            precision: dateComptable(e.date),
            fin: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                PastilleEncaissement(e.etat),
                MontantSensible(e.net),
              ],
            ),
            onPress: () => context.go(Routes.comptableEncaissementPour(e.id)),
          ),
      ],
    );
  }
}

/// L'etat des prestataires reellement actives (§42, CPT-BR-10) : un nom
/// rendu par la source, son solde s'il est connu, son etat en pastille.
/// Jamais un logo ni une couleur de marque (DR-21).
class ZonePrestataires extends StatelessWidget {
  /// Cree la zone.
  const ZonePrestataires(this.prestataires, {super.key});

  /// Les prestataires.
  final List<PrestataireFinance> prestataires;

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.aujourdhui;
    if (prestataires.isEmpty) {
      return VideZone(a.prestatairesVide, precision: a.prestatairesVideDetail);
    }
    return CarteLignes(
      lignes: <Widget>[
        for (final PrestataireFinance p in prestataires)
          LigneZone(
            key: ValueKey<String>('prestataire-${p.id}'),
            titre: p.nom,
            fin: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                PastilleCapacitePayout(p.capacite),
                ?_montantOuRien(p.solde),
              ],
            ),
          ),
      ],
    );
  }
}

/// Zone 8 : l'activite recente (§48), lue seulement.
class ZoneActivite extends StatelessWidget {
  /// Cree la zone.
  const ZoneActivite(this.activite, {super.key});

  /// Les entrees du journal, dans l'ordre de la source.
  final List<EntreeJournal> activite;

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.aujourdhui;
    if (activite.isEmpty) return VideZone(a.activiteVide);
    return CarteLignes(
      lignes: <Widget>[
        for (final EntreeJournal e in activite)
          Padding(
            key: ValueKey<String>('activite-${e.id}'),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LigneActivite(e),
          ),
      ],
    );
  }
}

/// Zone 9 : les acces rapides, des liens vers les ecrans canoniques par
/// leur route (spec §5.1). « Alimenter » mene a la Tresorerie, ou l'action
/// vit (W04) ; Aujourd'hui ne l'execute pas.
class ZoneAccesRapides extends StatelessWidget {
  /// Cree la zone.
  const ZoneAccesRapides({super.key});

  @override
  Widget build(BuildContext context) {
    final a = t.comptable.aujourdhui;
    Widget lien(String cle, String libelle, String route) => LienFleche(
      key: ValueKey<String>('acces-$cle'),
      libelle: libelle,
      onPress: () => context.go(route),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        lien('paiements', a.accesPaiements, Routes.comptablePaiements),
        lien('contractuels', a.accesContractuels, Routes.comptableContractuels),
        lien(
          'encaissements',
          a.accesEncaissements,
          Routes.comptableEncaissements,
        ),
        // Passation du 17/10, point 3 : enregistrer un paiement recu d'une
        // famille et emettre les factures du mois.
        lien(
          'paiements-familles',
          t.comptable.paiementsFamilles.entree,
          Routes.comptablePaiementsFamilles,
        ),
        lien('tresorerie', a.accesTresorerie, Routes.comptableTresorerie),
        lien('rapports', a.accesRapports, Routes.comptableRapports),
        lien(
          'alimenter',
          a.accesAlimenter,
          Routes.comptableTresorerieAlimenter,
        ),
      ],
    );
  }
}

Widget? _montantOuRien(Montant? montant) =>
    montant == null ? null : MontantSensible(montant);
