// Les rappels de la salle de seance.
//
// Regle de lib/CLAUDE.md : un bouton qui ne peut pas aboutir n'est pas rendu.
// Un rappel `null` ici = le bouton correspondant n'existe pas a l'ecran. Dans
// `/salle`, les outils et Supports restent nuls tant que BR-1 ne les a pas
// cables ; la demonstration les fournit tous.

import 'package:flutter/foundation.dart';

import 'vue_seance.dart';

/// Les outils d'enseignement (CLV-06), enseignant seulement.
enum OutilEnseignement { pointeur, marquer, masquer, annoter }

/// Les rappels d'une salle de seance.
@immutable
class ActionsSeance {
  const ActionsSeance({
    this.onRetour,
    this.onQuitter,
    this.onMicro,
    this.onCamera,
    this.onAgrandir,
    this.onReseau,
    this.onEleves,
    this.onSupports,
    this.onOutil,
    this.onPagePrecedente,
    this.onPageSuivante,
    this.onZoomMoins,
    this.onZoomPlus,
    this.onNotifications,
    this.onReglages,
    this.onCompte,
    this.onNaviguer,
    this.onRappeler,
    this.onChoisirPourReciter,
    this.onNoter,
    this.onSignaler,
    this.onOuvrirSupport,
    this.onBibliotheque,
  });

  // Les quatre actions de la fiche d'un eleve (panneau Eleves, CLV-07),
  // reprises de `FicheSeance` (/tc/classe) : aucune ne touche au support ni
  // a la page. `null` : l'action n'est pas rendue (jamais grisee).
  final ValueChanged<EleveSeance>? onRappeler;
  final ValueChanged<EleveSeance>? onChoisirPourReciter;
  final ValueChanged<EleveSeance>? onNoter;
  final ValueChanged<EleveSeance>? onSignaler;

  // Le panneau Supports (CLV-08), repris de `ClassLibraryPicker` : l'appelant
  // reste maitre de la suite (remplacer le support partage, fermer le
  // panneau). `null` dans `/salle` jusqu'a BR-1 : rien n'est rendu.

  /// « Ouvrir » (Reprendre) et les lignes des Recents.
  final ValueChanged<SupportDisponible>? onOuvrirSupport;

  /// « Voir tout », la ligne de la Bibliotheque de la Classe et « Voir toute
  /// la bibliotheque ».
  final VoidCallback? onBibliotheque;

  /// Le chevron ‹ de l'en-tete. Passe par la meme confirmation que Quitter.
  final VoidCallback? onRetour;

  /// Quitter (dock) et l'icone de sortie de la guidee.
  final VoidCallback? onQuitter;
  final VoidCallback? onMicro;
  final VoidCallback? onCamera;
  final VoidCallback? onAgrandir;
  final VoidCallback? onReseau;
  final VoidCallback? onEleves;
  final VoidCallback? onSupports;
  final ValueChanged<OutilEnseignement>? onOutil;
  final VoidCallback? onPagePrecedente;
  final VoidCallback? onPageSuivante;
  final VoidCallback? onZoomMoins;
  final VoidCallback? onZoomPlus;
  final VoidCallback? onNotifications;
  final VoidCallback? onReglages;

  /// Le menu du compte. `null` : le compte s'affiche sans chevron.
  final VoidCallback? onCompte;

  /// Une entree du rail enseignant (desktop) : la route cible, apres la
  /// confirmation de Quitter. `null` : le rail n'est pas rendu.
  final ValueChanged<String>? onNaviguer;
}
