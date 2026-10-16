/// L2-05 : la carte d'une offre vitrine, avec ses actions.
///
/// Une offre en brouillon se publie ; une offre publiee se retire ; une offre
/// retiree n'a plus d'action. **Jamais « Modifier »** : une offre publiee ne se
/// modifie pas (immuabilite, `0043`), et un brouillon se retire puis se
/// recree. Aucune information d'enseignant ni d'inscrits (decision du 09/10).
///
/// Les actions sont des boutons secondaires : le seul bouton plein de l'ecran
/// est « Nouvelle offre » (K-56). Hors ligne, aucune action n'est rendue (une
/// phrase de la page dit pourquoi), jamais un bouton grise.
library;

import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/offres/port_offres_admin.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_regroupements/regroupements_libelles.dart'
    show libelleHeureMinute, libelleJours, nomPublic;
import 'offres_libelles.dart';

/// Le ton de la pilule d'un etat.
TonEtat tonEtatOffre(EtatOffreAdmin etat) => switch (etat) {
  EtatOffreAdmin.brouillon => TonEtat.neutre,
  EtatOffreAdmin.publiee => TonEtat.succes,
  EtatOffreAdmin.retiree => TonEtat.avertissement,
};

/// La carte d'une offre.
class CarteOffre extends StatelessWidget {
  /// Cree la carte. [onPublier] et [onRetirer] sont nuls quand l'action n'est
  /// pas offerte (etat, ou hors ligne).
  const CarteOffre({
    required this.offre,
    super.key,
    this.onPublier,
    this.onRetirer,
  });

  /// L'offre.
  final OffreAdmin offre;

  /// Publier un brouillon.
  final VoidCallback? onPublier;

  /// Retirer une offre non retiree.
  final VoidCallback? onRetirer;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final o = t.admin.offres;
    final OffreAdmin of = offre;
    final String resume = resumeOffre(of);
    final bool actions = onPublier != null || onRetirer != null;

    return AppCard(
      key: ValueKey<String>('offre-${of.id}'),
      entete: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: TexteSansCoupure(
                '${nomPublic(of.public)}, ${of.langueNom}',
                style: textes.titleMedium,
              ),
            ),
          ),
          Ecart.hMd,
          StatusPill(
            key: ValueKey<String>('offre-etat-${of.id}'),
            libelle: nomEtatOffre(of.etat),
            ton: tonEtatOffre(of.etat),
          ),
        ],
      ),
      actions: actions
          ? Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: <Widget>[
                if (onPublier != null)
                  ActionPrincipale(
                    key: ValueKey<String>('offre-publier-${of.id}'),
                    libelle: o.publier,
                    libelleSemantique: o.publierPour(resume: resume),
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: false,
                    onPress: onPublier,
                  ),
                if (onRetirer != null)
                  ActionPrincipale(
                    key: ValueKey<String>('offre-retirer-${of.id}'),
                    libelle: o.retirer,
                    libelleSemantique: o.retirerPour(resume: resume),
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: false,
                    onPress: onRetirer,
                  ),
              ],
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(cle: o.cleJours, valeur: libelleJours(of.jours)),
          LigneCleValeur(
            cle: o.cleHeure,
            valeur: libelleHeureMinute(of.heureLocale, 0),
            chiffres: true,
          ),
          LigneCleValeur(
            cle: o.cleFuseau,
            valeur: villeDuFuseauLibelle(of.fuseauIana),
          ),
          LigneCleValeur(
            cle: o.cleDuree,
            valeur: libelleDuree(of.dureeMinutes),
            chiffres: true,
          ),
          if (of.etat == EtatOffreAdmin.retiree &&
              (of.motifRetrait ?? '').isNotEmpty)
            LigneCleValeur(
              key: ValueKey<String>('offre-motif-${of.id}'),
              cle: o.cleMotif,
              valeur: of.motifRetrait!,
            ),
        ],
      ),
    );
  }
}
