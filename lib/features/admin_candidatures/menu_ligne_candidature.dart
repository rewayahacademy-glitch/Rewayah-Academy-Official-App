// Le menu « ... » d'une ligne de la file (LISTES-1) : « Ouvrir le dossier », puis
// **les gestes que l'etat de la ligne permet**, calcules par la table de
// `gestes_proposes.dart` (la meme que celle de la fiche, pas une copie).
//
// Ce que le menu ne fait pas : il ne decide rien. La ligne ne porte ni la
// version de la candidature ni ses reponses, que tout geste exige : au choix
// d'un geste, la page **lit le dossier**, **rappelle la table sur ce qu'elle
// vient de lire**, puis ouvre la **meme feuille** que la fiche
// (`feuille_geste.dart`). Un geste qui n'est plus permis a ce moment est dit en
// mots, et rien n'est fait.
//
// L'ordre est celui de la frequence : le dossier d'abord, les gestes ordinaires
// ensuite, les gestes destructifs (refuser, retrait, ecarter un moyen) a la
// suite, en ton d'alerte, separes par un trait (`MenuActions`). « Choisir le
// responsable » n'y est pas : la liste des responsables n'est pas servie
// (`CAND-BR-04`), et un geste qui ne peut pas aboutir n'est pas offert.
library;

import 'package:flutter/material.dart';

import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/widgets/menu_actions.dart';
import '../admin_candidature/gestes_proposes.dart';
import '../admin_candidature/libelles_candidature.dart';
import 'libelles_candidatures.dart';

/// L'icone du catalogue de chaque geste : une par entree, pour que le menu se
/// lise d'un coup d'oeil.
AppIcon iconeDuGeste(GesteCandidature geste) => switch (geste) {
  GesteCandidature.demanderComplement => AppIcons.discussion,
  GesteCandidature.cloreComplement => AppIcons.succes,
  GesteCandidature.admettreVerifications => AppIcons.suivant,
  GesteCandidature.confirmerMoyenPaiement => AppIcons.paiements,
  GesteCandidature.infirmerMoyenPaiement => AppIcons.interdit,
  GesteCandidature.mettreEnPause => AppIcons.pause,
  GesteCandidature.leverPause => AppIcons.reconnexion,
  GesteCandidature.refuser => AppIcons.fermer,
  GesteCandidature.consignerRetrait => AppIcons.sortie,
  GesteCandidature.rouvrir => AppIcons.annuler,
  GesteCandidature.definirResponsable => AppIcons.profil,
};

/// Les gestes que le menu de [ligne] propose, dans l'ordre du menu : la
/// prochaine action d'abord, les autres gestes ordinaires, puis les gestes
/// destructifs. Vide sans le droit de decider.
List<GesteCandidature> gestesDuMenuLigne(
  LigneCandidature ligne,
  CapacitesCandidatures caps,
) {
  final GestesProposes g = gestesProposesPourLigne(
    ligne,
    caps,
    sansResponsable: true,
  );
  final List<GesteCandidature> tous = <GesteCandidature>[
    ?g.principal,
    ...g.autres,
  ];
  return <GesteCandidature>[
    ...tous.where((GesteCandidature x) => !x.destructif),
    ...tous.where((GesteCandidature x) => x.destructif),
  ];
}

/// Le menu d'une ligne : « Ouvrir le dossier » (quand une destination existe),
/// puis ses gestes. Un menu sans entree n'est pas rendu.
class MenuLigneCandidature extends StatelessWidget {
  /// Cree le menu.
  const MenuLigneCandidature({
    required this.ligne,
    required this.capacites,
    required this.onGeste,
    this.onOuvrir,
    super.key,
  });

  /// La ligne.
  final LigneCandidature ligne;

  /// Les capacites lues au serveur.
  final CapacitesCandidatures capacites;

  /// Ouvre le dossier, ou `null` : pas de destination.
  final VoidCallback? onOuvrir;

  /// Le geste choisi : la page lit le dossier, recalcule, puis ouvre la feuille.
  final void Function(GesteCandidature geste) onGeste;

  /// La cle du menu d'une candidature, pour les tests.
  static Key cle(String id) => ValueKey<String>('candidature-menu-$id');

  @override
  Widget build(BuildContext context) {
    final List<EntreeAction> actions = <EntreeAction>[
      if (onOuvrir != null)
        EntreeAction(
          libelle: t.admin.candidatures.liste.ouvrirDossier,
          icone: AppIcons.dossiers,
          onChoix: onOuvrir!,
        ),
      for (final GesteCandidature g in gestesDuMenuLigne(ligne, capacites))
        EntreeAction(
          libelle: libelleGeste(g),
          icone: iconeDuGeste(g),
          destructif: g.destructif,
          onChoix: () => onGeste(g),
        ),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return MenuActions(
      key: cle(ligne.id),
      points: true,
      objet: nomAffiche(ligne),
      actions: actions,
    );
  }
}
