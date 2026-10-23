// La carte du profil de paiement (`BeneficiaryPaymentProfileCard`, spec §35 ;
// UX_REVIEW §4 ; CPT-BEN-1) : identite et etat en tete, puis la methode
// **masquee par la source** avec son pays, sa devise et sa verification, la
// derniere modification, la capacite de paiement du corridor et les
// paiements qui attendent ce profil ; enfin la phrase qui dit pourquoi rien
// ne se modifie ici (R-FIN-11, §16.1). Aucun bouton « Modifier
// coordonnees ».

import 'package:flutter/material.dart';

import '../../../core/capacites/port_beneficiaires_paiement.dart';
import '../../../core/comptable/statuts_comptable.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_nom.dart';
import '../../../core/widgets/comptable/ligne_activite.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/ligne_destination_masquee.dart';
import '../../../core/widgets/pastilles_comptable.dart';
import 'etat_beneficiaires.dart';

/// La carte du profil de paiement d'un beneficiaire, vue par le personnel.
class CarteProfilPaiement extends StatelessWidget {
  /// Cree la carte.
  const CarteProfilPaiement({required this.profil, super.key});

  /// Le profil rendu par la source.
  final ProfilPaiementBeneficiaire profil;

  @override
  Widget build(BuildContext context) {
    final p = t.comptable.beneficiaires.profil;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final DateTime? modifiee = profil.derniereModification;
    final CapacitePayout? capacite = profil.capacite;
    return AppCard(
      dominante: true,
      entete: AvatarNom.enLigne(
        prenom: profil.identite.nom,
        role: libelleTypeBeneficiaire(profil.identite.type),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // L'etat sous le nom, jamais a cote : « Invitation envoyee » a
          // 320 px ou a texte x2 ecraserait le nom (mots coupes).
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PastilleProfilPaiement(profil.etat),
          ),
          Ecart.vSm,
          LigneDestinationMasquee(destination: profil.destination),
          LigneCleValeur(
            cle: p.derniereModification,
            valeur: modifiee == null
                ? t.comptable.commun.aucuneValeur
                : dateComptable(modifiee),
            chiffres: true,
          ),
          LigneCleValeur(
            cle: p.capacite,
            valeur: capacite == null
                ? p.capaciteNonEvaluee
                : libelleCapacitePayout(capacite),
          ),
          LigneCleValeur(
            cle: p.enAttente,
            valeur: profil.obligationsEnAttente == 0
                ? t.comptable.beneficiaires.aucunEnAttente
                : t.comptable.beneficiaires.enAttente(
                    n: profil.obligationsEnAttente,
                  ),
            chiffres: true,
          ),
          Ecart.vMd,
          Text(
            p.proprietaire(nom: profil.identite.nom),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}
