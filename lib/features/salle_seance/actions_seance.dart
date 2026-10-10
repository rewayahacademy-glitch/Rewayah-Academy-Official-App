// Les rappels de la salle de seance.
//
// Regle de lib/CLAUDE.md : un bouton qui ne peut pas aboutir n'est pas rendu.
// Un rappel `null` ici = le bouton correspondant n'existe pas a l'ecran. Dans
// `/salle`, les outils et Supports restent nuls tant que BR-1 ne les a pas
// cables ; la demonstration les fournit tous.

import 'package:flutter/foundation.dart';

import 'bibliotheque_seance.dart';
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
    this.onCommandes,
    this.onAffichage,
    this.onAjusterEcran,
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
    this.onReessayerConnexion,
    this.onContinuerSansMicro,
    this.onOuvrirReglages,
    this.onContexte,
    this.onPresenter,
  });

  /// TB-8 (LIB-02, LIB-03) : « Presenter » l'apercu choisi dans la
  /// Bibliotheque en seance. Le futur se termine quand le support est
  /// charge, avec son activation pour la classe, que la Bibliotheque
  /// n'appelle que si l'enseignant n'a pas renonce entre-temps ; il echoue
  /// sinon, et la classe garde le support d'avant ([PresenterSupport]).
  /// `null` : l'ancien selecteur (SelecteurRessources).
  final PresenterSupport? onPresenter;

  /// TB-3 (CTX-01, CTX-02) : l'avatar de la capsule deplie le contexte de
  /// l'enseignant, l'oeil le meme contexte a la section du controle ;
  /// « Reduire » rend [ContexteOuvert.aucun]. `null` : l'avatar reste une
  /// image, l'oeil un indicateur, rien n'est tapable.
  final ValueChanged<ContexteOuvert>? onContexte;

  // Les ecrans de secours (lot CL-7). `null` : l'action n'est pas rendue.

  /// « Reessayer » du bloc d'erreur de connexion.
  final VoidCallback? onReessayerConnexion;

  /// « Continuer sans micro » de la feuille micro bloque.
  final VoidCallback? onContinuerSansMicro;

  /// « Ouvrir les reglages » : `null` tant que la plateforme ne le permet
  /// pas (BR-1, aucun paquet de permission).
  final VoidCallback? onOuvrirReglages;

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

  /// TB-4 (CMD-01) : le declencheur « Commandes » ouvre ou reduit le
  /// panneau pedagogique (etat local, jamais diffuse). Nul : pas de
  /// declencheur.
  final VoidCallback? onCommandes;

  /// TB-4 : « Support », « Avec notes », « Tableau », un clic chacun (TB3).
  /// Nul : le choix n'est pas rendu (aucun champ partage avant TB-BR-13 en
  /// Classe Live).
  final ValueChanged<AffichagePartage>? onAffichage;

  /// TB-4 : « Ajuster a l'ecran » (section Lecture) retablit le cadrage
  /// personnel, sans rien diffuser. Nul : pas de bouton.
  final VoidCallback? onAjusterEcran;
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

  /// TB-5 : les memes rappels, Focus et sa sortie passes par la salle, qui
  /// replie puis restaure ses panneaux (plan V2 §18.1, UX-14 a UX-16).
  ActionsSeance avecAgrandir(VoidCallback? onAgrandir) => ActionsSeance(
    onRetour: onRetour,
    onQuitter: onQuitter,
    onMicro: onMicro,
    onCamera: onCamera,
    onAgrandir: onAgrandir,
    onReseau: onReseau,
    onEleves: onEleves,
    onSupports: onSupports,
    onCommandes: onCommandes,
    onAffichage: onAffichage,
    onAjusterEcran: onAjusterEcran,
    onOutil: onOutil,
    onPagePrecedente: onPagePrecedente,
    onPageSuivante: onPageSuivante,
    onZoomMoins: onZoomMoins,
    onZoomPlus: onZoomPlus,
    onNotifications: onNotifications,
    onReglages: onReglages,
    onCompte: onCompte,
    onNaviguer: onNaviguer,
    onRappeler: onRappeler,
    onChoisirPourReciter: onChoisirPourReciter,
    onNoter: onNoter,
    onSignaler: onSignaler,
    onOuvrirSupport: onOuvrirSupport,
    onBibliotheque: onBibliotheque,
    onReessayerConnexion: onReessayerConnexion,
    onContinuerSansMicro: onContinuerSansMicro,
    onOuvrirReglages: onOuvrirReglages,
    onContexte: onContexte,
    onPresenter: onPresenter,
  );
}
