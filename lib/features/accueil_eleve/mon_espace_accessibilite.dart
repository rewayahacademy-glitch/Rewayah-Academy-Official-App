// MA-8 : la destination « Mon espace » du Mode Accessibilite.
//
// Consigne K-51 : la page commune des reglages (`ReglagesComptePage`) est
// REPRISE telle quelle ; seul ce qui est propre au mode s'ajoute autour :
// - en tete, la carte d'identite (prenom seul, jamais l'age : MA23) et la
//   ligne « Mode Accessibilite » avec sa description (A9) ;
// - l'adulte a une bascule (demonstration, MA24) ; le mineur lit l'etat et
//   peut DEMANDER la presentation standard a son tuteur (S7 = b), par un
//   port (`PortDemandePresentation`) : en cours, envoyee, ou envoi non
//   confirme avec « Reessayer » (D5) ;
// - en dernier, l'aide honnete : aucun canal publie, aucune promesse (MA14).
// « Aide audio » est absente : aucune preference ne pilote un audio (A9).
// Ni la bascule ni la demande ne touchent camera, micro ou droit (MA5).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/accessibilite/port_demande_presentation.dart';
import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../compte/compte_page.dart';

/// L'etat de la demande de presentation standard du mineur.
enum EtatDemandePresentation {
  /// Aucune demande.
  aucune,

  /// Envoi en cours.
  enCours,

  /// Demande envoyee au tuteur.
  envoyee,

  /// Envoi non confirme.
  nonConfirmee,
}

/// Mon espace, en Mode Accessibilite, autour des reglages communs.
class MonEspaceAccessibilite extends StatefulWidget {
  /// Cree la destination.
  const MonEspaceAccessibilite({
    required this.prenom,
    required this.modeActif,
    required this.onAide,
    this.onBasculer,
    this.portDemande,
    super.key,
  });

  /// Le prenom de l'eleve (jamais l'age).
  final String prenom;

  /// L'etat du Mode Accessibilite.
  final bool modeActif;

  /// Ouvre la page d'aide honnete, comme la ligne d'aide des autres ecrans
  /// du Mode Accessibilite (MA14, MA9).
  final VoidCallback onAide;

  /// La bascule de l'adulte ; nulle pour le mineur.
  final ValueChanged<bool>? onBasculer;

  /// Le port de la demande du mineur ; nul pour l'adulte.
  final PortDemandePresentation? portDemande;

  @override
  State<MonEspaceAccessibilite> createState() => _MonEspaceAccessibiliteEtat();
}

class _MonEspaceAccessibiliteEtat extends State<MonEspaceAccessibilite> {
  EtatDemandePresentation _demande = EtatDemandePresentation.aucune;

  Future<void> _demander(PortDemandePresentation port) async {
    setState(() => _demande = EtatDemandePresentation.enCours);
    EtatDemandePresentation resultat;
    try {
      await port.demanderPresentationStandard();
      resultat = EtatDemandePresentation.envoyee;
    } on Object {
      resultat = EtatDemandePresentation.nonConfirmee;
    }
    if (mounted) setState(() => _demande = resultat);
  }

  LigneRubrique _ligneDemande(PortDemandePresentation port) {
    final bool pressable =
        _demande == EtatDemandePresentation.aucune ||
        _demande == EtatDemandePresentation.nonConfirmee;
    return LigneRubrique(
      libelle: t.accessibilite.monEspace.presentationStandard,
      legende: switch (_demande) {
        EtatDemandePresentation.aucune =>
          t.accessibilite.monEspace.demanderDetail,
        EtatDemandePresentation.enCours =>
          t.accessibilite.monEspace.demandeEnCours,
        EtatDemandePresentation.envoyee =>
          t.accessibilite.monEspace.demandeEnvoyee,
        EtatDemandePresentation.nonConfirmee =>
          t.accessibilite.monEspace.demandeNonConfirmee,
      },
      valeur: _demande == EtatDemandePresentation.nonConfirmee
          ? t.compte.reessayer
          : null,
      icone: AppIcons.reglages,
      onPress: pressable ? () => unawaited(_demander(port)) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ValueChanged<bool>? basculer = widget.onBasculer;
    final PortDemandePresentation? port = widget.portDemande;
    return ReglagesComptePage(
      titre: t.accessibilite.monEspace.titre,
      avant: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppCard(
            key: const ValueKey<String>('mon-espace-identite'),
            dominante: true,
            // MA15 : a texte agrandi, l'avatar passe au-dessus du prenom, qui
            // prend toute la largeur (aucun mot coupe).
            child: MediaQuery.textScalerOf(context).scale(1) > seuilTexteEmpile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AvatarTile(prenom: widget.prenom),
                      Ecart.vMd,
                      Text(
                        widget.prenom,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      AvatarTile(prenom: widget.prenom),
                      Ecart.hXl,
                      Expanded(
                        child: Text(
                          widget.prenom,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
          ),
          Ecart.vSection,
          // L'etat de la demande est annonce quand il change (region vive).
          Semantics(
            liveRegion: true,
            child: GroupeReglages(
              key: const ValueKey<String>('mon-espace-mode'),
              lignes: <LigneRubrique>[
                LigneRubrique(
                  libelle: t.accessibilite.monEspace.mode,
                  legende: t.accessibilite.monEspace.modeDetail,
                  icone: AppIcons.reglages,
                  // L'adulte : la bascule, sans chevron ; le mineur : l'etat,
                  // dit une seule fois, sans pastille.
                  valeur: basculer == null && widget.modeActif
                      ? t.accessibilite.monEspace.modeActif
                      : null,
                  controle: basculer == null
                      ? null
                      : Switch.adaptive(
                          key: const ValueKey<String>('bascule-mode'),
                          value: widget.modeActif,
                          onChanged: basculer,
                        ),
                ),
                if (basculer == null && port != null && widget.modeActif)
                  _ligneDemande(port),
              ],
            ),
          ),
        ],
      ),
      apres: GroupeReglages(
        key: const ValueKey<String>('mon-espace-aide'),
        lignes: <LigneRubrique>[
          LigneRubrique(
            libelle: t.accessibilite.accueil.aide,
            onPress: widget.onAide,
            icone: AppIcons.info,
          ),
        ],
      ),
    );
  }
}
