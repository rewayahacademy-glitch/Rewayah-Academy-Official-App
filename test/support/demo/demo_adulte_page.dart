// La coquille de l'eleve adulte en demonstration : /demo/adulte (hors
// production, EA-1b).
//
// Sans parametre : les liens vers les ecrans, les situations et les variantes.
// Avec `ecran` (accueil, maClasse, coran, forfaitFamille, maFamille,
// notifications, invitationRecue, invitationSansCompte...), `etat` (un des
// 25 cas du doc section 18), `titulaire=femme` et `vue=conjoint` : la VRAIE
// coquille (`NavShell`) a trois destinations, Accueil, Ma classe, Coran
// (MON-ESPACE-ADULTE-SUPPR, 11/11/2026 : « Mon espace » de l'eleve adulte
// est supprime sur ordre du directeur). « Ma famille » ouvre la coquille du
// tuteur existante sur le VRAI Foyer (F20), jamais une destination de plus.
//
// Aucun role serveur n'est change : la demonstration choisit la coquille, le
// role reel reste lu du jeton. Aucun appel serveur (K-28).
//
// L'Accueil (EA-2) et Ma classe (EA-3) sont les vrais ecrans ; les vraies
// sous-pages du Compte (informations, paiements, securite,
// apparence, aide, informations legales) restent ouvertes par leur adresse,
// avec un retour vers l'Accueil (MON-ESPACE-ADULTE-SUPPR, 11/11/2026 : Mon
// espace, qui les ouvrait, est supprime ; « Mes accords » et « Cours et
// acces », ses rubriques sans source ni page, avec lui). Forfait famille
// porte « Quitter le forfait famille » (EA-8) et le lien « Demande de
// reprise du foyer » (EA-11). Coran (PT-B) : aucun corpus n'est embarque
// dans la demonstration ; l'onglet dit que le Coran est disponible apres
// connexion (`CoranDemoAdulte`), sans serveur.
//
// EA-11 : la demande de reprise du second adulte (`ecran=repriseFoyer`), la
// notification du titulaire et sa decision (`ecran=repriseTitulaire`, aussi
// depuis la ligne de la place de Ma famille), puis les etats rendus (cas 16
// a 20 du doc section 18), dans la cloche de la personne concernee.
//
// EA-8 : la place occupee de Ma famille porte « Retirer ma conjointe » ou
// « Retirer mon conjoint », la place en delai ouvre « Nouvelle invitation
// indisponible » ; apres un depart, la cloche de l'Accueil de l'AUTRE adulte
// ouvre le centre de notifications existant avec la notification du doc
// section 9.3 (F16).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:rewayah_academy/core/appairage/service_appairage.dart'
    show AppareilAppaire, EleveDuFoyer;
import 'package:rewayah_academy/core/auth/service_auth.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/capacites/port_mes_finances.dart';
import 'package:rewayah_academy/core/capacites/port_notifications.dart';
import 'package:rewayah_academy/core/capacites/port_paiements_foyer.dart';
import 'package:rewayah_academy/core/capacites/port_politiques_commerciales.dart';
import 'package:rewayah_academy/core/capacites/port_recharge_foyer.dart';
import 'package:rewayah_academy/core/config/env.dart';
import 'package:rewayah_academy/core/domain/enums.dart';
import 'package:rewayah_academy/core/finance/finances_profil.dart';
import 'package:rewayah_academy/core/finance/mouvements_profil.dart';
import 'package:rewayah_academy/core/finance/suivi_paiement.dart';
import 'package:rewayah_academy/core/foyer/port_creation_profil_eleve.dart';
import 'package:rewayah_academy/core/foyer/profil_eleve_brouillon.dart';
import 'package:rewayah_academy/core/foyer/selection_eleve.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/icons/app_icons.dart';
import 'package:rewayah_academy/core/mouvement/mouvement.dart';
import 'package:rewayah_academy/core/planning/service_planning.dart'
    show monFuseauProvider;
import 'package:rewayah_academy/core/profil/service_acceptations.dart';
import 'package:rewayah_academy/core/reseau/service_reseau.dart';
import 'package:rewayah_academy/core/router/routes.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/theme/app_palette.dart';
import 'package:rewayah_academy/core/theme/app_spacing.dart';
import 'package:rewayah_academy/core/widgets/etat_systeme.dart';
import 'package:rewayah_academy/core/widgets/lien_fleche.dart';
import 'package:rewayah_academy/core/widgets/nav_shell.dart';
import 'package:rewayah_academy/core/widgets/page_shell.dart';
import 'package:rewayah_academy/features/accueil_adulte/accueil_adulte_page.dart';
import 'package:rewayah_academy/features/accueil_adulte/historique_seances_adulte_page.dart';
import 'package:rewayah_academy/features/appareils/appareils_page.dart';
import 'package:rewayah_academy/features/appareils/liste_appareils_eleve.dart'
    show donneesAppareilsFoyerProvider;
import 'package:rewayah_academy/features/compte/aide_page.dart';
import 'package:rewayah_academy/features/compte/donnees_compte.dart'
    show
        identiteTitulaireProvider,
        paiementsFoyerProvider,
        profilEleveTitulaireExisteProvider;
import 'package:rewayah_academy/features/compte/informations_page.dart';
import 'package:rewayah_academy/features/compte/paiements_page.dart';
import 'package:rewayah_academy/features/compte/securite_page.dart';
import 'package:rewayah_academy/features/foyer/creer_mon_profil_page.dart';
import 'package:rewayah_academy/features/foyer/fiche_eleve_page.dart';
import 'package:rewayah_academy/features/foyer/finances_foyer.dart'
    show financesFoyerProvider, politiqueActiveProvider;
import 'package:rewayah_academy/features/foyer/formulaire_profil_eleve.dart';
import 'package:rewayah_academy/features/foyer/foyer_page.dart';
import 'package:rewayah_academy/features/foyer/invitation_conjoint.dart';
import 'package:rewayah_academy/features/foyer/place_adulte.dart';
import 'package:rewayah_academy/features/foyer/transactions_foyer.dart'
    show derniersMouvementsFoyerProvider, nombreDernieresTransactions;
import 'package:rewayah_academy/features/ma_classe_adulte/ma_classe_adulte_page.dart';
import 'package:rewayah_academy/features/mon_espace_adulte/mes_finances_page.dart';
import 'package:rewayah_academy/features/notifications/notifications_page.dart';

import 'adulte_demo.dart';
import 'classe_demo.dart';
import 'coran_demo_adulte.dart';
import 'demo_classe_page.dart'
    show PreparationEleveDemo, adressePreparationEleveDemo, surchargesEleveDemo;
import 'finance_demo.dart';
import 'mode_demonstration.dart';
import 'repere_demonstration.dart';

/// Les ecrans de la demonstration. Les trois premiers sont les
/// destinations de la coquille, dans leur ordre.
enum EcranDemoAdulte {
  /// Accueil (EA-2).
  accueil,

  /// Ma classe (EA-3).
  maClasse,

  /// Coran.
  coran,

  /// Forfait famille du second adulte (EA-4), avec « Quitter le forfait
  /// famille » (EA-8).
  forfaitFamille,

  /// Ma famille : la coquille du tuteur sur le Foyer (EA-5).
  maFamille,

  /// Paiements (EA-4).
  paiements,

  /// Mes informations (EA-4).
  informations,

  /// Connexion et securite (EA-4).
  securite,

  /// Aide et contact (EA-4).
  aide,

  /// Paiements du foyer, ouverts depuis Ma famille (EA-5) : les soldes, le
  /// bouton « Recharger » et l'historique pour le titulaire (EA-9).
  paiementsFoyer,

  /// La recharge, ouverte par « Recharger » (EA-9) : beneficiaires, offres,
  /// verification et paiement (EA-10).
  recharge,

  /// La place adulte, ouverte depuis sa ligne de Ma famille (EA-8) : occupee,
  /// « Retirer ma conjointe » ; en delai, « Nouvelle invitation
  /// indisponible ».
  placeAdulte,

  /// Le formulaire d'ajout d'un profil eleve, ouvert depuis Ma famille.
  ajouterProfil,

  /// La fiche d'un enfant (`eleve=`), ouverte depuis Ma famille.
  ficheEleve,

  /// Les appareils du foyer, ouverts depuis Ma famille.
  appareils,

  /// « Ajouter ma famille », de l'adulte sans foyer (EA-PL) : inscrire un
  /// enfant ou inviter le second adulte.
  ajouterMaFamille,

  /// Inviter la conjointe ou le conjoint, ouvert depuis la place libre de Ma
  /// famille (EA-6).
  inviterConjoint,

  /// L'invitation envoyee, ouverte depuis sa ligne de Ma famille (EA-6).
  invitationEnvoyee,

  /// « A propos du forfait famille », ouvert depuis Ma famille (EA-5c, E6).
  aProposForfait,

  /// « Creer mon profil eleve », ouvert depuis Ma famille : la page
  /// indisponible existante (DB-FOY-01, EA-BR-19).
  creerMonProfil,

  /// Apres « Creer le profil » en demonstration : rien n'a ete cree, et la
  /// page le dit (EA-5c).
  profilNonCree,

  /// Les notifications, ouvertes par la cloche de l'Accueil (EA-7) : le
  /// `NotificationsPage` existant.
  notifications,

  /// L'invitation recue par le second adulte, ouverte depuis sa notification
  /// (EA-7), dans son propre compte.
  invitationRecue,

  /// L'invitation ouverte sans compte (lien du message, EA-7) : hors de
  /// toute coquille, vers la connexion existante.
  invitationSansCompte,

  /// La demande de reprise du foyer du second adulte, ouverte depuis Forfait
  /// famille ou sa notification (EA-11).
  repriseFoyer,

  /// La demande de reprise vue par le titulaire, ouverte depuis sa
  /// notification ou la ligne de la place de Ma famille (EA-11).
  repriseTitulaire,

  /// L'historique des seances passees, ouvert par « Voir tout » des
  /// dernieres seances de l'Accueil (DASH-EA-PROD).
  seancesPassees,

  /// Mes mouvements, ouverts depuis Paiements par l'eleve adulte autonome
  /// (FI-9b).
  mesMouvements,

  /// La recharge de l'eleve adulte autonome, ouverte par « Recharger » de
  /// Paiements (FI-9b) : le meme moteur que celle du foyer, son seul profil
  /// coche (`eleve=`).
  maRecharge,
}

/// Les ecrans ranges sous l'Accueil : la cloche y mene (EA-7).
const Set<EcranDemoAdulte> _ecransSousAccueil = <EcranDemoAdulte>{
  EcranDemoAdulte.notifications,
  EcranDemoAdulte.invitationRecue,
  EcranDemoAdulte.seancesPassees,
};

/// Les ecrans de l'espace foyer (coquille du tuteur), reserves au titulaire
/// d'un foyer (F6, F7).
const Set<EcranDemoAdulte> _ecransFoyer = <EcranDemoAdulte>{
  EcranDemoAdulte.maFamille,
  EcranDemoAdulte.paiementsFoyer,
  EcranDemoAdulte.recharge,
  EcranDemoAdulte.placeAdulte,
  EcranDemoAdulte.ajouterProfil,
  EcranDemoAdulte.ficheEleve,
  EcranDemoAdulte.appareils,
  EcranDemoAdulte.inviterConjoint,
  EcranDemoAdulte.invitationEnvoyee,
  EcranDemoAdulte.aProposForfait,
  EcranDemoAdulte.creerMonProfil,
  EcranDemoAdulte.profilNonCree,
  EcranDemoAdulte.repriseTitulaire,
};

/// Les ecrans des finances de l'eleve adulte autonome (FI-9b), dans SA
/// coquille : jamais au titulaire d'une famille ni au second adulte
/// rattache, qui n'ont pas de finances personnelles a lire ici (F7).
const Set<EcranDemoAdulte> _ecransAutonome = <EcranDemoAdulte>{
  EcranDemoAdulte.mesMouvements,
  EcranDemoAdulte.maRecharge,
};

/// Les ecrans qui lisent `PortMesFinances` : Paiements, Mes mouvements et
/// la recharge.
const Set<EcranDemoAdulte> _ecransMesFinances = <EcranDemoAdulte>{
  EcranDemoAdulte.paiements,
  ..._ecransAutonome,
};

/// Vrai pour l'adulte autonome : la ligne famille « Ajouter ma famille »
/// (adulte seul, ou second adulte qui n'est pas ou plus rattache).
bool _autonome(EtatDemoAdulte etat, VueDemoAdulte vue) =>
    DonneesAdulteDemo.ligneFamille(etat, vue) ==
    LigneFamilleDemo.ajouterMaFamille;

/// Les ecrans du Foyer qu'ouvre « Ajouter ma famille » a l'adulte seul
/// (EA-PL) : l'invitation du second adulte, l'ajout d'un enfant et son
/// resultat de demonstration.
const Set<EcranDemoAdulte> _ecransAjouterMaFamille = <EcranDemoAdulte>{
  EcranDemoAdulte.inviterConjoint,
  EcranDemoAdulte.ajouterProfil,
  EcranDemoAdulte.profilNonCree,
};

/// Les situations « pendant une mutation » du doc section 18 (22, 23) : la
/// demonstration les montre sur l'invitation, quel que soit l'etat de la
/// place (EA-6).
bool _mutation(EtatDemoAdulte etat) =>
    etat == EtatDemoAdulte.erreurReseau ||
    etat == EtatDemoAdulte.doubleSoumission;

/// L'ecran que la personne a le droit de voir : l'espace foyer n'est qu'au
/// titulaire d'un foyer. La regle est celle de la ligne famille
/// (`DonneesAdulteDemo.ligneFamille`, EA-4c) : seul « Ma famille » ouvre le
/// Foyer. Le second adulte rattache arrive sur « Forfait famille », ou sur
/// les paiements du foyer, rendus dans SA coquille (E3) ; l'adulte sans
/// foyer, ou le second adulte qui n'est pas rattache, sur « Ajouter ma
/// famille » ; sans ligne, sur l'Accueil (F6, F7 ; Mon espace est supprime,
/// MON-ESPACE-ADULTE-SUPPR) : jamais les donnees d'un role qui n'y a pas
/// droit, jamais les enfants.
EcranDemoAdulte ecranPermisDemoAdulte(
  EcranDemoAdulte ecran,
  EtatDemoAdulte etat,
  VueDemoAdulte vue,
) {
  // L'invitation recue n'existe que pour le second adulte, et seulement
  // dans une situation qui en a une (EA-7) : jamais pour le titulaire.
  if (ecran == EcranDemoAdulte.invitationRecue) {
    return vue == VueDemoAdulte.secondAdulte &&
            DonneesAdulteDemo.invitationRecue(etat, GenreTitulaireDemo.homme) !=
                null
        ? ecran
        : EcranDemoAdulte.accueil;
  }
  // La demande de reprise n'est qu'au second adulte (matrice du doc section
  // 16) : rattache, ou apres une reprise validee, qu'il lit depuis sa
  // notification (EA-11).
  if (ecran == EcranDemoAdulte.repriseFoyer) {
    return vue == VueDemoAdulte.secondAdulte &&
            (DonneesAdulteDemo.secondAdultePresent(etat) ||
                etat == EtatDemoAdulte.repriseValidee)
        ? ecran
        : EcranDemoAdulte.accueil;
  }
  // Forfait famille n'est qu'au second adulte rattache (EA-4c, EA-8).
  if (ecran == EcranDemoAdulte.forfaitFamille) {
    return DonneesAdulteDemo.ligneFamille(etat, vue) ==
            LigneFamilleDemo.forfaitFamille
        ? ecran
        : EcranDemoAdulte.accueil;
  }
  // Les finances personnelles (FI-9b) : a l'adulte autonome seulement.
  if (_ecransAutonome.contains(ecran)) {
    return _autonome(etat, vue) ? ecran : EcranDemoAdulte.accueil;
  }
  if (!_ecransFoyer.contains(ecran)) return ecran;
  // « Ajouter ma famille » (EA-PL, doc section 4) : l'adulte seul ouvre
  // l'invitation et l'ajout d'un enfant, la meme architecture familiale que
  // l'onboarding ; rien d'autre du Foyer tant qu'il n'en a pas.
  if (etat == EtatDemoAdulte.adulteSeul &&
      vue == VueDemoAdulte.titulaire &&
      _ecransAjouterMaFamille.contains(ecran)) {
    return ecran;
  }
  switch (DonneesAdulteDemo.ligneFamille(etat, vue)) {
    case LigneFamilleDemo.maFamille:
      break;
    case LigneFamilleDemo.forfaitFamille:
      return ecran == EcranDemoAdulte.paiementsFoyer
          ? EcranDemoAdulte.paiementsFoyer
          : EcranDemoAdulte.forfaitFamille;
    case LigneFamilleDemo.ajouterMaFamille:
      return EcranDemoAdulte.ajouterMaFamille;
    case null:
      return EcranDemoAdulte.accueil;
  }
  // L'invitation suit l'etat de la place : jamais un formulaire d'invitation
  // sur une place occupee ou en delai (F17, R4), jamais le detail d'une
  // invitation qui n'existe pas. Sinon, Ma famille dit l'etat. Apres un
  // refus de validation, « Faire une nouvelle demande » relance l'invitation
  // (E5, doc section 10.3).
  final EtatPlaceAdulte place = DonneesAdulteDemo.place(
    etat,
    GenreTitulaireDemo.homme,
  );
  final bool permis = switch (ecran) {
    EcranDemoAdulte.inviterConjoint =>
      place is PlaceDisponible ||
          placePermetNouvelleDemande(place) ||
          _mutation(etat),
    EcranDemoAdulte.invitationEnvoyee =>
      place is InvitationEnvoyee || _mutation(etat),
    // La place occupee (retrait) ou en delai (son detail), EA-8.
    EcranDemoAdulte.placeAdulte =>
      place is PlaceOccupee || place is DelaiEnCours,
    // La demande de reprise, seulement s'il y en a une pour lui (EA-11).
    EcranDemoAdulte.repriseTitulaire =>
      DonneesAdulteDemo.repriseTitulaire(etat) != null,
    _ => true,
  };
  return permis ? ecran : EcranDemoAdulte.maFamille;
}

/// Les routes de la demonstration adulte : AUCUNE en production.
List<RouteBase> routesDemoAdulte(String environnement) {
  if (!environnementAutoriseDemo(environnement)) return const <RouteBase>[];
  return <RouteBase>[
    GoRoute(
      path: Routes.demoAdulte,
      builder: (BuildContext _, GoRouterState etat) {
        final Map<String, String> p = etat.uri.queryParameters;
        return DemoAdultePage(
          ecran: _lire(EcranDemoAdulte.values, p['ecran']),
          etat:
              _lire(EtatDemoAdulte.values, p['etat']) ??
              EtatDemoAdulte.conjointActif,
          genre: p['titulaire'] == 'femme'
              ? GenreTitulaireDemo.femme
              : GenreTitulaireDemo.homme,
          vue: p['vue'] == 'conjoint'
              ? VueDemoAdulte.secondAdulte
              : VueDemoAdulte.titulaire,
          seance:
              _lire(EtatDemoClasse.values, p['seance']) ??
              EtatDemoClasse.aVenir,
          eleve: p['eleve'],
          reseauCoupe: p['reseau'] == 'coupe',
          foyerNouveau: p['foyer'] == 'nouveau',
          financeARegulariser: p['finance'] == 'a-regulariser',
        );
      },
    ),
  ];
}

T? _lire<T extends Enum>(List<T> valeurs, String? nom) {
  for (final T v in valeurs) {
    if (v.name == nom) return v;
  }
  return null;
}

/// L'adresse d'un ecran de la demonstration.
String adresseDemoAdulte(
  EcranDemoAdulte ecran, {
  EtatDemoAdulte etat = EtatDemoAdulte.conjointActif,
  GenreTitulaireDemo genre = GenreTitulaireDemo.homme,
  VueDemoAdulte vue = VueDemoAdulte.titulaire,
  EtatDemoClasse seance = EtatDemoClasse.aVenir,
  String? eleve,
  bool reseauCoupe = false,
  bool foyerNouveau = false,
  bool financeARegulariser = false,
}) => Uri(
  path: Routes.demoAdulte,
  queryParameters: <String, String>{
    'ecran': ecran.name,
    'etat': etat.name,
    if (genre == GenreTitulaireDemo.femme) 'titulaire': 'femme',
    if (vue == VueDemoAdulte.secondAdulte) 'vue': 'conjoint',
    if (seance != EtatDemoClasse.aVenir) 'seance': seance.name,
    'eleve': ?eleve,
    if (reseauCoupe) 'reseau': 'coupe',
    if (foyerNouveau) 'foyer': 'nouveau',
    if (financeARegulariser) 'finance': 'a-regulariser',
  },
).toString();

/// Le libelle d'un ecran : celui de sa destination ou de sa ligne.
String libelleEcranDemoAdulte(EcranDemoAdulte ecran) => switch (ecran) {
  EcranDemoAdulte.accueil => t.adulte.nav.accueil,
  EcranDemoAdulte.maClasse => t.adulte.nav.maClasse,
  EcranDemoAdulte.coran => t.adulte.nav.coran,
  EcranDemoAdulte.forfaitFamille => t.adulte.famille.forfaitFamille,
  EcranDemoAdulte.maFamille => t.adulte.famille.maFamille,
  EcranDemoAdulte.paiements => t.adulte.monEspace.paiements,
  EcranDemoAdulte.informations => t.adulte.monEspace.informations,
  EcranDemoAdulte.securite => t.compte.tuteur.securite.titre,
  EcranDemoAdulte.aide => t.compte.tuteur.aide.ligne,
  EcranDemoAdulte.paiementsFoyer => t.adulte.famille.paiementsFoyer,
  EcranDemoAdulte.recharge => t.adulte.paiements.recharger,
  EcranDemoAdulte.placeAdulte => t.adulte.famille.forfaitFamille,
  EcranDemoAdulte.ajouterProfil => t.foyer.ajouterProfil,
  EcranDemoAdulte.ficheEleve => t.ficheEleve.titreRepli,
  EcranDemoAdulte.appareils => t.foyer.appareilsFoyer,
  EcranDemoAdulte.ajouterMaFamille => t.adulte.famille.ajouter,
  EcranDemoAdulte.inviterConjoint => t.adulte.invitation.envoyer,
  EcranDemoAdulte.invitationEnvoyee => t.adulte.famille.place.invitationEnvoyee,
  EcranDemoAdulte.aProposForfait => t.adulte.famille.aProposForfait,
  EcranDemoAdulte.creerMonProfil => t.foyer.creerMonProfil,
  EcranDemoAdulte.profilNonCree => t.adulte.famille.profilNonCreeTitre,
  EcranDemoAdulte.notifications => t.notifications.titre,
  EcranDemoAdulte.invitationRecue => t.adulte.acceptation.titreNeutre,
  EcranDemoAdulte.invitationSansCompte => t.adulte.demo.invitationSansCompte,
  EcranDemoAdulte.repriseFoyer ||
  EcranDemoAdulte.repriseTitulaire => t.adulte.reprise.titre,
  EcranDemoAdulte.seancesPassees => t.adulte.historique.titre,
  EcranDemoAdulte.mesMouvements => t.ficheEleve.mouvements.titre,
  EcranDemoAdulte.maRecharge => t.adulte.paiements.recharger,
};

/// Le libelle d'une situation (doc section 18).
String libelleEtatDemoAdulte(EtatDemoAdulte etat) =>
    t['adulte.demo.etats.${etat.name}'] as String;

/// Les trois destinations de l'eleve adulte en demonstration (UX_REVIEW_07
/// ligne 1, sans Mon espace depuis MON-ESPACE-ADULTE-SUPPR) : le chemin est
/// l'ecran de la demonstration, la coquille ne le lit pas.
List<Destination> destinationsEleveAdulte() => <Destination>[
  Destination(
    libelle: t.adulte.nav.accueil,
    icone: AppIcons.accueil,
    chemin: EcranDemoAdulte.accueil.name,
  ),
  Destination(
    libelle: t.adulte.nav.maClasse,
    icone: AppIcons.classes,
    chemin: EcranDemoAdulte.maClasse.name,
  ),
  Destination(
    libelle: t.adulte.nav.coran,
    icone: AppIcons.coran,
    chemin: EcranDemoAdulte.coran.name,
  ),
];

/// La session de demonstration : un adulte resolu, sans source serveur.
///
/// « Se deconnecter » la ferme localement (`fermerDemo` rend vrai) : la carte
/// n'atteint jamais le service d'authentification, et [_quitter] ramene a la
/// liste de la demonstration (K-28, F24, revue EA-R M6).
class _SessionAdulteDemo extends SessionControleur {
  _SessionAdulteDemo(this._quitter);

  final VoidCallback _quitter;

  @override
  SessionState build() => const SessionState(
    resolue: true,
    role: AppRole.student,
    profileId: DonneesAdulteDemo.mamadouId,
    accountStatus: AccountStatus.active,
    lectureProfil: LectureProfil.presente,
  );

  @override
  bool fermerDemo() {
    _quitter();
    return true;
  }
}

/// Le service d'authentification de la demonstration, surcharge dans les
/// deux coquilles (adulte et tuteur) : rien ne part vers le serveur, meme si
/// une page l'appelait sans passer par `fermerDemo` (K-28, revue EA-R M6).
/// La deconnexion ramene a la liste de la demonstration.
class _ServiceAuthDemo implements ServiceAuth {
  const _ServiceAuthDemo(this._quitter);

  final VoidCallback _quitter;

  @override
  Future<void> envoyerLienCourriel(
    String courriel, {
    String? jetonControle,
  }) async {}

  @override
  Future<void> connexionMotDePasse(
    String courriel,
    String motDePasse, {
    String? jetonControle,
  }) async {}

  @override
  Future<void> connexionGoogle() async {}

  @override
  Future<void> deconnexion() async => _quitter();
}

/// L'echec de lecture de la demonstration quand le reseau est coupe
/// (`reseau=coupe`, revue EA-R M5) : rien n'est appele.
final StateError _reseauCoupe = StateError('reseau coupe (demonstration)');

/// La page : la liste des ecrans, ou la coquille sur l'ecran choisi.
class DemoAdultePage extends StatelessWidget {
  /// Cree la page.
  const DemoAdultePage({
    this.ecran,
    this.etat = EtatDemoAdulte.conjointActif,
    this.genre = GenreTitulaireDemo.homme,
    this.vue = VueDemoAdulte.titulaire,
    this.seance = EtatDemoClasse.aVenir,
    this.eleve,
    this.reseauCoupe = false,
    this.foyerNouveau = false,
    this.financeARegulariser = false,
    super.key,
  });

  /// `finance=a-regulariser` : l'eleve adulte autonome n'a pas finance le
  /// mois de reference (FI-12, refus 9 du guide §13) ; sans lui, finance.
  final bool financeARegulariser;

  /// `foyer=nouveau` : le foyer que l'adulte seul vient d'ouvrir par
  /// « Ajouter ma famille » (EA-PL), sans enfant.
  final bool foyerNouveau;

  /// La situation de la prochaine seance (Accueil).
  final EtatDemoClasse seance;

  /// L'enfant dont la fiche est ouverte (`ficheEleve`).
  final String? eleve;

  /// `reseau=coupe` : l'appareil est hors ligne (revue EA-R M5).
  final bool reseauCoupe;

  /// L'ecran choisi, ou nul pour la liste.
  final EcranDemoAdulte? ecran;

  /// La situation du foyer.
  final EtatDemoAdulte etat;

  /// Le genre du titulaire.
  final GenreTitulaireDemo genre;

  /// La personne qui regarde.
  final VueDemoAdulte vue;

  @override
  Widget build(BuildContext context) {
    final EcranDemoAdulte? e = ecran;
    if (e != null) {
      return CoquilleAdulteDemo(
        ecran: e,
        etat: etat,
        genre: genre,
        vue: vue,
        seance: seance,
        eleve: eleve,
        reseauCoupe: reseauCoupe,
        foyerNouveau: foyerNouveau,
        financeARegulariser: financeARegulariser,
      );
    }
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    Widget titre(String valeur) => Semantics(
      header: true,
      child: Text(
        valeur,
        style: palette.inkStrong.applyTo(
          textes.titleMedium ?? const TextStyle(),
        ),
      ),
    );
    final bool femme = genre == GenreTitulaireDemo.femme;
    return PageShell(
      titre: t.adulte.demo.titre,
      sousTitre: t.adulte.demo.mention,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            t.adulte.demo.intro,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vXxl,
          titre(t.adulte.demo.ecrans),
          Ecart.vMd,
          for (final EcranDemoAdulte ecran in <EcranDemoAdulte>[
            EcranDemoAdulte.accueil,
            EcranDemoAdulte.maClasse,
            EcranDemoAdulte.coran,
            EcranDemoAdulte.maFamille,
          ])
            LienFleche(
              key: ValueKey<String>('lien-ecran-${ecran.name}'),
              libelle: libelleEcranDemoAdulte(ecran),
              onPress: () => context.go(adresseDemoAdulte(ecran)),
            ),
          Ecart.vXxl,
          titre(t.adulte.demo.variantes),
          Ecart.vMd,
          LienFleche(
            key: const ValueKey<String>('lien-titulaire-femme'),
            libelle: t.adulte.demo.titulaireFemme,
            onPress: () => context.go(
              adresseDemoAdulte(
                EcranDemoAdulte.accueil,
                genre: GenreTitulaireDemo.femme,
              ),
            ),
          ),
          LienFleche(
            key: const ValueKey<String>('lien-vue-conjoint'),
            libelle: femme
                ? t.adulte.demo.vueConjoint
                : t.adulte.demo.vueConjointe,
            onPress: () => context.go(
              adresseDemoAdulte(
                EcranDemoAdulte.accueil,
                genre: genre,
                vue: VueDemoAdulte.secondAdulte,
              ),
            ),
          ),
          // EA-7 : l'invitation recue dans le compte du second adulte, par la
          // cloche de son Accueil ; puis l'invitation ouverte sans compte.
          LienFleche(
            key: const ValueKey<String>('lien-invitation-recue'),
            libelle: femme
                ? t.adulte.demo.invitationRecueConjoint
                : t.adulte.demo.invitationRecueConjointe,
            onPress: () => context.go(
              adresseDemoAdulte(
                EcranDemoAdulte.accueil,
                etat: EtatDemoAdulte.invitationEnAttente,
                genre: genre,
                vue: VueDemoAdulte.secondAdulte,
              ),
            ),
          ),
          LienFleche(
            key: const ValueKey<String>('lien-invitation-sans-compte'),
            libelle: t.adulte.demo.invitationSansCompte,
            onPress: () => context.go(
              adresseDemoAdulte(EcranDemoAdulte.invitationSansCompte),
            ),
          ),
          // Revue EA-R M5 : le reseau coupe, l'Accueil et Ma classe disent
          // « hors ligne ».
          LienFleche(
            key: const ValueKey<String>('lien-reseau-coupe'),
            libelle: t.adulte.demo.reseauCoupe,
            onPress: () => context.go(
              adresseDemoAdulte(EcranDemoAdulte.accueil, reseauCoupe: true),
            ),
          ),
          Ecart.vXxl,
          titre(t.adulte.demo.situations),
          Ecart.vMd,
          for (final EtatDemoAdulte etat in EtatDemoAdulte.values)
            LienFleche(
              key: ValueKey<String>('lien-etat-${etat.name}'),
              libelle: libelleEtatDemoAdulte(etat),
              onPress: () => context.go(
                adresseDemoAdulte(EcranDemoAdulte.accueil, etat: etat),
              ),
            ),
        ],
      ),
    );
  }
}

/// La VRAIE coquille de l'eleve adulte (NavShell, quatre destinations), ou,
/// pour « Ma famille », la VRAIE coquille du tuteur sur le VRAI Foyer.
class CoquilleAdulteDemo extends StatelessWidget {
  /// Cree la coquille.
  const CoquilleAdulteDemo({
    required this.ecran,
    this.etat = EtatDemoAdulte.conjointActif,
    this.genre = GenreTitulaireDemo.homme,
    this.vue = VueDemoAdulte.titulaire,
    this.seance = EtatDemoClasse.aVenir,
    this.environnement = Env.environnement,
    this.eleve,
    this.reseauCoupe = false,
    this.foyerNouveau = false,
    this.financeARegulariser = false,
    super.key,
  });

  /// `finance=a-regulariser` : l'eleve adulte autonome n'a pas finance le
  /// mois de reference (FI-12, refus 9 du guide §13) ; sans lui, finance.
  final bool financeARegulariser;

  /// `foyer=nouveau` : le foyer que l'adulte seul vient d'ouvrir par
  /// « Ajouter ma famille » (EA-PL). Ma famille n'y montre aucun enfant, et
  /// les soldes, que le titulaire. Son espace eleve ne change pas : Accueil,
  /// Accueil et Ma classe ne lisent pas cette valeur.
  final bool foyerNouveau;

  /// La situation de la prochaine seance (Accueil).
  final EtatDemoClasse seance;

  /// `reseau=coupe` : l'appareil est hors ligne, et les lectures de
  /// l'Accueil et de Ma classe echouent (revue EA-R M5). Sans lui, rien ne
  /// change.
  final bool reseauCoupe;

  /// L'enfant dont la fiche est ouverte (`ficheEleve`) ; par defaut le
  /// premier enfant du foyer.
  final String? eleve;

  /// L'ecran demande (voir [ecranPermisDemoAdulte] pour celui qui s'affiche).
  final EcranDemoAdulte ecran;

  /// La situation du foyer.
  final EtatDemoAdulte etat;

  /// Le genre du titulaire.
  final GenreTitulaireDemo genre;

  /// La personne qui regarde.
  final VueDemoAdulte vue;

  /// L'environnement compile : la coquille du tuteur n'est montee que hors
  /// production (`surchargesDemoTuteur` le verifie).
  final String environnement;

  String _adresse(EcranDemoAdulte e, {String? eleve}) => adresseDemoAdulte(
    e,
    etat: etat,
    genre: genre,
    vue: vue,
    seance: seance,
    eleve: eleve,
    reseauCoupe: reseauCoupe,
    foyerNouveau: foyerNouveau,
    financeARegulariser: financeARegulariser,
  );

  @override
  Widget build(BuildContext context) {
    final EcranDemoAdulte vu = ecranPermisDemoAdulte(ecran, etat, vue);
    // Sans compte, aucune coquille. Dans l'application, « Continuer » mene a
    // la connexion existante (EA-7) ; depuis la demonstration, il revient a
    // la liste : la vraie connexion appellerait le vrai service
    // d'authentification (K-28, F24, relecture EA-RC).
    if (vu == EcranDemoAdulte.invitationSansCompte) {
      return RepereDemonstration(
        child: InvitationSansComptePage(
          onContinuer: () => context.go(Routes.demoAdulte),
        ),
      );
    }
    // La coquille du tuteur et le Foyer : au titulaire seulement. Les
    // paiements du foyer du second adulte restent dans sa coquille (E3).
    if (_ecransFoyer.contains(vu) && vue == VueDemoAdulte.titulaire) {
      return _foyer(context, vu);
    }
    final List<Destination> destinations = destinationsEleveAdulte();
    // Les pages hors des trois destinations (sous-pages du Compte, forfait
    // famille, cloche) gardent l'Accueil allume, ou elles reviennent
    // (MON-ESPACE-ADULTE-SUPPR : Mon espace n'existe plus).
    final bool sousAccueil = _ecransSousAccueil.contains(vu);
    final bool horsDestinations =
        !sousAccueil && vu.index > EcranDemoAdulte.coran.index;
    final int actif = sousAccueil || horsDestinations
        ? EcranDemoAdulte.accueil.index
        : vu.index;
    void versAccueil() => context.go(_adresse(EcranDemoAdulte.accueil));
    void versPaiements() => context.go(_adresse(EcranDemoAdulte.paiements));
    // L'eleve adulte autonome et sa finance de demonstration (FI-9b).
    final bool autonome = _autonome(etat, vue);
    final FinancesProfil mesFinances = DonneesFinanceDemo.financesAdulte(
      profilId: DonneesAdulteDemo.idVue(genre, vue),
      prenom: DonneesAdulteDemo.prenomVue(genre, vue),
      classe: vue == VueDemoAdulte.titulaire
          ? DonneesAdulteDemo.classeTitulaire
          : null,
      aRegulariser: financeARegulariser,
    );
    void versNotifications() =>
        context.go(_adresse(EcranDemoAdulte.notifications));
    void versAccueilApres(EtatInvitationRecue suite) => context.go(
      adresseDemoAdulte(
        EcranDemoAdulte.accueil,
        etat: DonneesAdulteDemo.apresReponse(etat, suite),
        genre: genre,
        vue: vue,
        seance: seance,
        reseauCoupe: reseauCoupe,
      ),
    );
    // L'invitation recue par le second adulte, et sa notification (EA-7,
    // EA-BR-20) : jamais pour le titulaire.
    final EtatInvitationRecue? invitation = vue == VueDemoAdulte.secondAdulte
        ? DonneesAdulteDemo.invitationRecue(etat, genre)
        : null;
    // Apres un depart, la notification de l'AUTRE adulte (F16, EA-8).
    final String? depart = DonneesAdulteDemo.notificationDepart(
      etat,
      genre,
      vue,
    );
    void versAccueilDans(EtatDemoAdulte suite) => context.go(
      adresseDemoAdulte(
        EcranDemoAdulte.accueil,
        etat: suite,
        genre: genre,
        vue: vue,
        seance: seance,
        reseauCoupe: reseauCoupe,
      ),
    );
    // La suite d'une demande de reprise, dans la cloche de la personne
    // concernee (EA-11, F16) : le titulaire ouvre la decision, le second
    // adulte l'etat de sa demande.
    final String? reprise = DonneesAdulteDemo.notificationReprise(etat, vue);
    return ProviderScope(
      key: ValueKey<String>(_adresse(vu)),
      overrides: <Override>[
        sessionProvider.overrideWith(
          () => _SessionAdulteDemo(() => context.go(Routes.demoAdulte)),
        ),
        serviceAuthProvider.overrideWithValue(
          _ServiceAuthDemo(() => context.go(Routes.demoAdulte)),
        ),
        // L'Accueil lit la Classe An-Nour de la demonstration de Classe
        // (seance, reseau, travail, supports), plus sa propre vue.
        // Reseau coupe (revue EA-R M5) : la seance de la Classe se lit hors
        // ligne (`horsLigneProvider` vrai) et la lecture de la page echoue.
        if (vu == EcranDemoAdulte.accueil) ...<Override>[
          ...surchargesEleveDemo(
            reseauCoupe ? EtatDemoClasse.horsLigne : seance,
          ),
          // Le second adulte est eleve d'une autre Classe, que la
          // demonstration n'a pas : le fournisseur reel reste (indisponible),
          // jamais la Classe An-Nour du titulaire (EA-BR-13).
          if (reseauCoupe)
            accueilAdulteProvider.overrideWith(
              (Ref _) => Future<AccueilAdulteVM>.error(_reseauCoupe),
            )
          else if (DonneesAdulteDemo.accueil(genre, vue)
              case final AccueilAdulteVM accueil)
            accueilAdulteProvider.overrideWith((Ref _) async => accueil),
        ] else if (vu == EcranDemoAdulte.maClasse) ...<Override>[
          // Ma classe lit la meme Classe An-Nour, plus sa propre vue (EA-3).
          ...surchargesEleveDemo(
            reseauCoupe ? EtatDemoClasse.horsLigne : seance,
          ),
          // Le second adulte est eleve d'une autre Classe, que la
          // demonstration n'a pas : le fournisseur reel reste (indisponible).
          if (reseauCoupe)
            maClasseAdulteProvider.overrideWith(
              (Ref _) => Future<MaClasseAdulteVM>.error(_reseauCoupe),
            )
          else if (DonneesAdulteDemo.maClasse(genre, vue)
              case final MaClasseAdulteVM classe)
            maClasseAdulteProvider.overrideWith((Ref _) async => classe),
        ] else ...<Override>[
          horsLigneProvider.overrideWith(
            (Ref _) => Stream<bool>.value(reseauCoupe),
          ),
          // L'historique des seances passees (DASH-EA-PROD) : celui de la
          // Classe An-Nour ; le second adulte garde le fournisseur reel
          // (indisponible, EA-BR-13), le reseau coupe fait echouer la lecture.
          if (vu == EcranDemoAdulte.seancesPassees)
            if (reseauCoupe)
              historiqueSeancesAdulteProvider.overrideWith(
                (Ref _) => Future<List<SeancePasseeAdulte>>.error(_reseauCoupe),
              )
            else if (vue == VueDemoAdulte.titulaire)
              historiqueSeancesAdulteProvider.overrideWith(
                (Ref _) async => DonneesAdulteDemo.historiqueSeances(),
              ),
          // La cloche du second adulte : sa notification d'invitation, puis
          // l'invitation et sa reponse, ou rien n'est envoye (EA-7, K-28).
          // Sans invitation, les fournisseurs reels restent (indisponibles,
          // DB-CPT-04 et EA-BR-20).
          if (sousAccueil && invitation != null) ...<Override>[
            notificationsTuteurProvider.overrideWith(
              (Ref _) async => <NotificationTuteur>[
                NotificationTuteur(
                  id: 'demo-invitation-forfait',
                  // Phrase de T3 (UX_REVIEW_07), sans « sur Rewayah
                  // Academy » : libelle provisoire, lexique D4.
                  titre: t.adulte.acceptation.notification(
                    prenom: DonneesAdulteDemo.prenomTitulaire(genre),
                  ),
                  date: DonneesAdulteDemo.dateInvitation,
                  destination: _adresse(EcranDemoAdulte.invitationRecue),
                ),
              ],
            ),
            invitationRecueProvider.overrideWith((Ref _) async => invitation),
            portReponseInvitationProvider.overrideWithValue(
              _ReponseInvitationDemo(etat, genre),
            ),
          ],
          // La notification d'un depart, dans le centre de l'autre adulte,
          // sans push (doc section 9.3, F16, EA-BR-21). Celle du titulaire
          // ouvre Ma famille, ou la ligne de la place dit deja l'etat
          // (UX_REVIEW_07 ligne 12 c) ; celle du second adulte n'ouvre rien.
          if (sousAccueil && depart != null)
            notificationsTuteurProvider.overrideWith(
              (Ref _) async => <NotificationTuteur>[
                NotificationTuteur(
                  id: 'demo-depart-forfait',
                  titre: depart,
                  date: DonneesAdulteDemo.dateDepart,
                  destination: vue == VueDemoAdulte.titulaire
                      ? _adresse(EcranDemoAdulte.maFamille)
                      : null,
                ),
              ],
            ),
          // La demande de reprise (EA-11, EA-BR-27 et 28), sans push : la
          // notification du titulaire porte le texte du doc section 12.2.
          if (sousAccueil && reprise != null)
            notificationsTuteurProvider.overrideWith(
              (Ref _) async => <NotificationTuteur>[
                NotificationTuteur(
                  id: 'demo-reprise-foyer',
                  titre: reprise,
                  date: vue == VueDemoAdulte.titulaire
                      ? DonneesAdulteDemo.dateDepotReprise
                      : DonneesAdulteDemo.dateSuiteReprise,
                  destination: _adresse(
                    vue == VueDemoAdulte.titulaire
                        ? EcranDemoAdulte.repriseTitulaire
                        : EcranDemoAdulte.repriseFoyer,
                  ),
                ),
              ],
            ),
          // Les pages hors des destinations lisent l'identite de la personne
          // qui regarde par le port du Compte (EA-4). Les paiements et l'aide
          // gardent leur fournisseur reel (indisponible, DB-CPT-03 et
          // DB-CPT-07) ; le fuseau et les textes acceptes, qui partiraient
          // vers le serveur, sont indisponibles : rien d'invente.
          if (horsDestinations) ...<Override>[
            identiteTitulaireProvider.overrideWith(
              (Ref _) async => DonneesAdulteDemo.identite(genre, vue),
            ),
            monFuseauProvider.overrideWith(
              (Ref _) => Future<String>.error(
                const CapaciteIndisponible('demonstration'),
              ),
            ),
            acceptationsProvider.overrideWith(
              (Ref _) => Future<List<Acceptation>>.error(
                const CapaciteIndisponible('demonstration'),
              ),
            ),
            // Les finances de l'adulte autonome (FI-9b, FI-BR-17) : son seul
            // profil, jamais un autre membre ; la recharge est le moteur du
            // foyer, son seul profil pour beneficiaire. Rien n'est paye.
            // Reseau coupe : les lectures echouent (hors ligne).
            if (autonome && _ecransMesFinances.contains(vu)) ...<Override>[
              portMesFinancesProvider.overrideWithValue(
                MesFinancesDemo(mesFinances),
              ),
              mesFinancesProvider.overrideWith(
                (Ref _) => reseauCoupe
                    ? Future<FinancesProfil?>.error(_reseauCoupe)
                    : Future<FinancesProfil?>.value(mesFinances),
              ),
              mesMouvementsProvider.overrideWith(
                (Ref _) => reseauCoupe
                    ? Future<List<MouvementProfil>>.error(_reseauCoupe)
                    : MesFinancesDemo(mesFinances).mouvements(),
              ),
              portRechargeFoyerProvider.overrideWithValue(
                RechargeAdulteDemo(mesFinances),
              ),
              beneficiairesRechargeProvider.overrideWith(
                (Ref _) => reseauCoupe
                    ? Future<List<BeneficiaireRecharge>>.error(_reseauCoupe)
                    : RechargeAdulteDemo(mesFinances).beneficiaires(),
              ),
              portPolitiquesCommercialesProvider.overrideWithValue(
                const PolitiquesCommercialesDemo(),
              ),
              politiqueActiveProvider.overrideWith(
                (Ref _) async => DonneesFinanceDemo.politiqueFamille,
              ),
            ],
            // Forfait famille du second adulte rattache (EA-8, EA-BR-22) et
            // sa sortie, ou rien n'est envoye (EA-BR-21, K-28).
            if (vu == EcranDemoAdulte.forfaitFamille) ...<Override>[
              forfaitFamilleProvider.overrideWith(
                (Ref _) async => DonneesAdulteDemo.forfaitFamille(genre),
              ),
              portSortieForfaitProvider.overrideWithValue(_SortieDemo(etat)),
            ],
            // La demande de reprise du second adulte (EA-11, EA-BR-27) : rien
            // n'est envoye.
            if (vu == EcranDemoAdulte.repriseFoyer) ...<Override>[
              repriseFoyerProvider.overrideWith(
                (Ref _) async => DonneesAdulteDemo.reprise(etat),
              ),
              portRepriseFoyerProvider.overrideWithValue(_RepriseDemo(etat)),
            ],
          ],
        ],
      ],
      child: RepereDemonstration(
        child: NavShell(
          destinations: destinations,
          indexActif: actif,
          libellesDansLeRail: true,
          onAller: (String chemin) {
            final EcranDemoAdulte? cible = _lire(
              EcranDemoAdulte.values,
              chemin,
            );
            if (cible != null) context.go(_adresse(cible));
          },
          child: switch (vu) {
            // La cloche ouvre le centre de notifications existant (EA-7,
            // EA-8, sans fork) ; « Voir tout » ouvre Ma
            // classe, dont le « Voir tout » ouvre la Bibliotheque de la
            // Classe, avec toutes ses ressources (EA-3).
            EcranDemoAdulte.accueil => AccueilAdultePage(
              onNotifications: versNotifications,
              onRejoindre: (_) => context.go(
                adressePreparationEleveDemo(PreparationEleveDemo.pret),
              ),
              onVoirRessources: (_) =>
                  context.go(_adresse(EcranDemoAdulte.maClasse)),
              onVoirDernieresSeances: () =>
                  context.go(_adresse(EcranDemoAdulte.seancesPassees)),
            ),
            // « Voir tout » des dernieres seances (DASH-EA-PROD), retour a
            // l'Accueil.
            EcranDemoAdulte.seancesPassees => HistoriqueSeancesAdultePage(
              onRetour: () => context.go(_adresse(EcranDemoAdulte.accueil)),
            ),
            EcranDemoAdulte.maClasse => MaClasseAdultePage(
              onRejoindre: (_) => context.go(
                adressePreparationEleveDemo(PreparationEleveDemo.pret),
              ),
            ),
            // Aucun corpus en demonstration (PT-B) : disponible apres
            // connexion, sans aucun appel serveur (K-28).
            EcranDemoAdulte.coran => const CoranDemoAdulte(),
            // L'adulte autonome : ses finances (FI-9b) ; les autres, la page
            // des paiements existante.
            EcranDemoAdulte.paiements =>
              autonome
                  ? MesFinancesPage(
                      onRetour: versAccueil,
                      onRecharger: (String id) => context.go(
                        _adresse(EcranDemoAdulte.maRecharge, eleve: id),
                      ),
                      onMouvements: () =>
                          context.go(_adresse(EcranDemoAdulte.mesMouvements)),
                    )
                  : PaiementsComptePage(onRetour: versAccueil),
            EcranDemoAdulte.mesMouvements => MesMouvementsPage(
              onRetour: versPaiements,
            ),
            // LE moteur de recharge du foyer, son seul profil coche
            // (guide §4) : aucun second moteur. Ouverte directement, sans
            // `eleve=`, elle coche aussi son profil : il n'en a pas d'autre.
            EcranDemoAdulte.maRecharge => RechargeFoyerPage(
              preselection: <String>{mesFinances.profilId},
              // Son seul profil : aucune finance du foyer lue (FI-9b).
              regularisation: false,
              onAbandon: versPaiements,
              onTerminee: versPaiements,
              // La demo de l'adulte seul ne rend aucune commande payee : par
              // surete, une commande rendue ramenerait a ses paiements.
              onPaye: (String _) => versPaiements(),
            ),
            EcranDemoAdulte.informations => InformationsComptePage(
              onRetour: versAccueil,
            ),
            EcranDemoAdulte.securite => SecuriteComptePage(
              onRetour: versAccueil,
            ),
            EcranDemoAdulte.aide => AideComptePage(onRetour: versAccueil),
            // Apres « Compris », l'Accueil relu : le second adulte n'est
            // plus rattache (« Ajouter ma famille »).
            EcranDemoAdulte.forfaitFamille => ForfaitFamillePage(
              onRetour: versAccueil,
              onCompris: () => versAccueilDans(EtatDemoAdulte.conjointQuitte),
              onReprise: () =>
                  context.go(_adresse(EcranDemoAdulte.repriseFoyer)),
            ),
            // La demande de reprise (EA-11) : apres le depot, la page relue
            // dans la situation que le serveur rendrait (demande deposee).
            // Le retour mene au forfait famille, ou a l'Accueil quand il n'y
            // en a plus (reprise validee, `ecranPermisDemoAdulte`).
            EcranDemoAdulte.repriseFoyer => RepriseFoyerPage(
              onRetour: () =>
                  context.go(_adresse(EcranDemoAdulte.forfaitFamille)),
              onDeposee: () => context.go(
                adresseDemoAdulte(
                  EcranDemoAdulte.repriseFoyer,
                  etat: EtatDemoAdulte.repriseDemandee,
                  genre: genre,
                  vue: vue,
                  seance: seance,
                  reseauCoupe: reseauCoupe,
                ),
              ),
            ),
            // « Ajouter ma famille » (EA-PL, doc section 4) : le libelle de
            // l'invitation suit le genre de la personne qui regarde (doc
            // section 2). Les actions ouvrent les vrais ecrans du Foyer pour
            // l'adulte seul ; le second adulte qui n'est plus rattache n'a
            // pas encore de foyer de demonstration a lui (EA-BR-17) : un etat
            // honnete « pas encore disponible » et son retour, jamais la
            // phrase du doc qui promet des actions absentes.
            EcranDemoAdulte.ajouterMaFamille =>
              vue == VueDemoAdulte.titulaire
                  ? AjouterMaFamillePage(
                      placeFeminine: genre == GenreTitulaireDemo.homme,
                      onRetour: versAccueil,
                      onInscrireEnfant: () =>
                          context.go(_adresse(EcranDemoAdulte.ajouterProfil)),
                      onInviter: () =>
                          context.go(_adresse(EcranDemoAdulte.inviterConjoint)),
                    )
                  : PageShell(
                      titre: t.adulte.famille.ajouter,
                      onRetour: versAccueil,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxl),
                        child: EtatSysteme(
                          key: const ValueKey<String>(
                            'demo-ajouter-famille-indisponible',
                          ),
                          nature: NatureEtat.indisponible,
                          portee: PorteeEtat.page,
                          titre: t.adulte.famille.indisponibleTitre,
                          phrase: t.adulte.famille.indisponiblePhrase,
                          libelleAction: t.commun.etats.actions.retourAccueil,
                          onAction: versAccueil,
                          dependance: 'EA-BR-17',
                        ),
                      ),
                    ),
            // Le second adulte rattache : les paiements du foyer, la meme
            // page que le titulaire (E3, EA-BR-16), retour vers l'Accueil.
            EcranDemoAdulte.paiementsFoyer => PaiementsComptePage(
              titre: t.adulte.famille.paiementsFoyer,
              onRetour: versAccueil,
            ),
            // La cloche ouvre le centre de notifications existant (sans
            // fork), retour a l'Accueil (EA-7).
            EcranDemoAdulte.notifications => NotificationsPage(
              onRetour: () => context.go(_adresse(EcranDemoAdulte.accueil)),
            ),
            // Apres la reponse, l'Accueil dans la situation rendue : le
            // second adulte rattache, ou en attente de validation. Le retour
            // y mene aussi : les notifications de l'etat de depart
            // rouvriraient l'invitation « a repondre », un etat faux.
            EcranDemoAdulte.invitationRecue => InvitationRecuePage(
              onRetour: versNotifications,
              libelleSuite: t.commun.etats.actions.retourAccueil,
              onSuite: versAccueilApres,
              onRetourApresReponse: versAccueilApres,
            ),
            EcranDemoAdulte.invitationSansCompte ||
            EcranDemoAdulte.recharge ||
            EcranDemoAdulte.maFamille ||
            EcranDemoAdulte.placeAdulte ||
            EcranDemoAdulte.ajouterProfil ||
            EcranDemoAdulte.ficheEleve ||
            EcranDemoAdulte.appareils ||
            EcranDemoAdulte.inviterConjoint ||
            EcranDemoAdulte.invitationEnvoyee ||
            EcranDemoAdulte.aProposForfait ||
            EcranDemoAdulte.creerMonProfil ||
            EcranDemoAdulte.repriseTitulaire ||
            EcranDemoAdulte.profilNonCree => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  /// La coquille du tuteur existante (Accueil, Foyer, Historique, Compte) sur
  /// Ma famille, le Foyer du tuteur peuple du foyer Diallo (EA-5). Le retour
  /// vers l'Accueil de l'eleve adulte est une ligne au bord de debut,
  /// au-dessus du Foyer (UX_REVIEW_07 ligne 1 a), sur le fond de page du
  /// theme.
  ///
  /// Decision EA-5 (releve d'EA-1b, « seul le Foyer reagit ») : la coquille
  /// du tuteur n'est pas recreee ; chacune de ses destinations reagit, et
  /// celles qui n'ont pas de page dans l'espace foyer de la demonstration
  /// ramenent a l'espace eleve : « Accueil », « Historique » et « Compte »
  /// ouvrent l'Accueil (« Compte » ouvrait Mon espace, supprime par
  /// MON-ESPACE-ADULTE-SUPPR le 11/11/2026).
  ///
  /// Les chemins internes du Foyer ouvrent les VRAIES pages du tuteur dans
  /// cette coquille (K-51, rien de recree) : le formulaire commun d'ajout
  /// (`FormulaireProfilEleve`, sans « Un proche adulte », F2), la fiche de
  /// chaque enfant (`FicheElevePage`) et les appareils du foyer
  /// (`AppareilsPage`). Les sous-pages de la fiche n'ont pas encore d'ecran
  /// de demonstration : leurs lignes ne quittent pas la coquille. La ligne
  /// de la place adulte ouvre l'invitation (place libre) ou l'invitation
  /// envoyee (EA-6), sinon une page provisoire (EA-8).
  Widget _foyer(BuildContext context, EcranDemoAdulte vu) {
    final List<Destination> destinations = destinationsPour(
      role: AppRole.guardian,
      mode: InterfaceMode.standard,
    );
    final List<EleveDuFoyer> enfants = DonneesAdulteDemo.enfantsPour(
      etat,
      foyerNouveau: foyerNouveau,
    );
    final FoyerTitulaireVM titulaire = DonneesAdulteDemo.foyerTitulaire(
      etat,
      genre,
    );
    // L'adulte seul, venu de « Ajouter ma famille » (EA-PL) : abandonner y
    // ramene, il n'a pas encore de Ma famille.
    final bool seul = etat == EtatDemoAdulte.adulteSeul;
    void versMaFamille() => context.go(
      _adresse(
        seul ? EcranDemoAdulte.ajouterMaFamille : EcranDemoAdulte.maFamille,
      ),
    );
    void versRecharge() => context.go(_adresse(EcranDemoAdulte.recharge));
    void versFiche(String id) =>
        context.go(_adresse(EcranDemoAdulte.ficheEleve, eleve: id));
    // Les chemins du tuteur, ramenes aux ecrans de la demonstration.
    void allerFoyer(String chemin) {
      final Uri uri = Uri.parse(chemin);
      final String p = uri.path;
      if (p == Routes.tuteurFoyer) {
        versMaFamille();
      } else if (p == Routes.tuteurAjouterEnfant) {
        // `?pour=moi` : « Creer mon profil eleve », jamais le formulaire d'un
        // enfant.
        context.go(
          _adresse(
            uri.queryParameters['pour'] == 'moi'
                ? EcranDemoAdulte.creerMonProfil
                : EcranDemoAdulte.ajouterProfil,
          ),
        );
      } else if (p == Routes.tuteurFoyerAppareils) {
        context.go(_adresse(EcranDemoAdulte.appareils));
      } else if (p == Routes.tuteurFoyerRecharge) {
        // La recharge de la synthese, ou celle d'une carte (`?profils=`),
        // ce profil coche (R1-06).
        final String? profils = uri.queryParameters['profils'];
        context.go(
          _adresse(
            EcranDemoAdulte.recharge,
            eleve: profils == null || profils.contains(',') ? null : profils,
          ),
        );
      } else if (p.startsWith('${Routes.tuteurFoyer}/')) {
        // La fiche, ou une de ses sous-pages (« Voir le détail » d'une
        // carte) : la demonstration n'a que la fiche, ouverte a sa place.
        final String id = p.substring(Routes.tuteurFoyer.length + 1);
        versFiche(id.split('/').first);
      }
    }

    // Apres un envoi ou une annulation, Ma famille dans la situation que le
    // serveur rendrait : l'invitation envoyee, ou la place libre « annulee ».
    // Envoyee par l'adulte seul (EA-PL) : il devient titulaire d'un foyer
    // nouveau, sans enfant, et sa ligne famille dit desormais « Ma famille ».
    void versMaFamilleApres(EtatDemoAdulte suite) => context.go(
      adresseDemoAdulte(
        EcranDemoAdulte.maFamille,
        etat: suite,
        genre: genre,
        vue: vue,
        seance: seance,
        reseauCoupe: reseauCoupe,
        foyerNouveau: foyerNouveau || seul,
      ),
    );
    final EtatPlaceAdulte place = titulaire.place;
    final PaiementsFoyerProfilsDemo paiements = PaiementsFoyerProfilsDemo(
      DonneesAdulteDemo.finances(etat, genre, foyerNouveau: foyerNouveau),
    );

    final Widget page = switch (vu) {
      // Le titulaire : « Recharger », raccourci vers LA recharge du foyer,
      // puis l'historique (FI-7). Ses soldes ne sont plus repetes ici : la
      // synthese et les cartes de Ma famille les portent (E-11, revue
      // FI-VAGUE-R R1-06).
      EcranDemoAdulte.paiementsFoyer => PaiementsComptePage(
        titre: t.adulte.famille.paiementsFoyer,
        onRetour: versMaFamille,
        onRecharger: versRecharge,
      ),
      // La recharge (EA-10, EA-BR-24 et 25) : les beneficiaires et leurs
      // offres, la verification, puis un etat honnete, jamais un paiement
      // reussi (F13). Rien n'est paye. Ouverte depuis la carte d'un enfant,
      // ce profil coche (`eleve`).
      EcranDemoAdulte.recharge => RechargeFoyerPage(
        preselection: <String>{?eleve},
        onAbandon: () => context.go(_adresse(EcranDemoAdulte.paiementsFoyer)),
        onTerminee: () => context.go(_adresse(EcranDemoAdulte.paiementsFoyer)),
        // Le paiement EA ne rend jamais de commande (F13) : par surete, une
        // commande rendue ramenerait aux paiements, ou l'on verifie.
        onPaye: (String _) =>
            context.go(_adresse(EcranDemoAdulte.paiementsFoyer)),
      ),
      EcranDemoAdulte.inviterConjoint => InviterConjointPage(
        placeFeminine: titulaire.placeFeminine,
        onAbandon: versMaFamille,
        onTerminee: () =>
            versMaFamilleApres(EtatDemoAdulte.invitationEnAttente),
      ),
      EcranDemoAdulte.invitationEnvoyee => InvitationEnvoyeePage(
        invitation: place is InvitationEnvoyee
            ? place
            : DonneesAdulteDemo.invitationEnvoyee(genre),
        onRetour: versMaFamille,
        onAnnulee: () => versMaFamilleApres(EtatDemoAdulte.invitationAnnulee),
      ),
      // La place (EA-8) : occupee, le retrait, puis Ma famille relue dans
      // la situation que le serveur rendrait (le delai et sa date) ; en
      // delai, son detail. `ecranPermisDemoAdulte` n'ouvre que ces deux cas.
      EcranDemoAdulte.placeAdulte => switch (place) {
        DelaiEnCours(:final DateTime possibleLe) => DelaiPlacePage(
          possibleLe: possibleLe,
          onRetour: versMaFamille,
        ),
        PlaceOccupee(:final String prenom) => PlaceConjointPage(
          placeFeminine: titulaire.placeFeminine,
          prenom: prenom,
          onRetour: versMaFamille,
          onCompris: () => versMaFamilleApres(EtatDemoAdulte.conjointRetire),
        ),
        _ => const SizedBox.shrink(),
      },
      // En demonstration, rien n'est envoye : apres « Creer le profil », une
      // page le dit, au lieu d'un retour muet a Ma famille (EA-5c).
      EcranDemoAdulte.ajouterProfil => FormulaireProfilEleve(
        onAbandon: versMaFamille,
        onVoirFoyer: versMaFamille,
        onCree: (String? _) =>
            context.go(_adresse(EcranDemoAdulte.profilNonCree)),
      ),
      EcranDemoAdulte.profilNonCree => PageShell(
        titre: t.foyer.ajouterProfil,
        onRetour: versMaFamille,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: EtatSysteme(
            key: const ValueKey<String>('demo-profil-non-cree'),
            nature: NatureEtat.indisponible,
            portee: PorteeEtat.page,
            // Titre et phrase sans source (spec, planche) : libelle
            // provisoire, lexique D4.
            titre: t.adulte.famille.profilNonCreeTitre,
            // L'adulte seul (EA-PL) n'a pas de Ma famille : son espace eleve
            // reste tel quel, et il y revient. Libelle provisoire, lexique D4.
            phrase: seul
                ? t.adulte.famille.profilNonCreePhraseSeul
                : t.adulte.famille.profilNonCreePhrase,
            libelleAction: seul
                ? t.commun.etats.actions.retourAccueil
                : t.adulte.invitation.revenirMaFamille,
            onAction: seul
                ? () => context.go(_adresse(EcranDemoAdulte.accueil))
                : versMaFamille,
            dependance: 'demonstration',
          ),
        ),
      ),
      EcranDemoAdulte.aProposForfait => AProposForfaitFamillePage(
        onRetour: versMaFamille,
      ),
      // La demande de reprise, cote titulaire (EA-11, EA-BR-28) : apres le
      // refus, la page relue dans la situation que le serveur rendrait.
      EcranDemoAdulte.repriseTitulaire => RepriseTitulairePage(
        onRetour: versMaFamille,
        onRefusee: () => context.go(
          adresseDemoAdulte(
            EcranDemoAdulte.repriseTitulaire,
            etat: EtatDemoAdulte.repriseRefuseeParTitulaire,
            genre: genre,
            vue: vue,
            seance: seance,
            reseauCoupe: reseauCoupe,
          ),
        ),
      ),
      // Mamadou suit deja les cours : la page lui parle en adulte, jamais du
      // « compte de tuteur » (EA-5c, EA-BR-19).
      // PROFIL-DEJA (11/11/2026) : il est eleve autonome ; « Ouvrir mon
      // espace eleve » ramene a son Accueil de demonstration.
      EcranDemoAdulte.creerMonProfil => CreerMonProfilPage(
        onRetour: versMaFamille,
        eleveAutonome: true,
        onOuvrirEspace: () => context.go(_adresse(EcranDemoAdulte.accueil)),
      ),
      EcranDemoAdulte.ficheEleve => FicheElevePage(
        eleveId: eleve ?? DonneesAdulteDemo.aichaId,
        onAller: allerFoyer,
        onRetour: versMaFamille,
        // Aucune page Finances de demonstration : pas d'onglets.
        avecPageFinances: false,
      ),
      EcranDemoAdulte.appareils => AppareilsPage(
        onAller: allerFoyer,
        onRetour: versMaFamille,
      ),
      _ => ColoredBox(
        // Le fond de page du theme sous la ligne de retour : jamais une bande
        // claire en sombre, ni deux tons en clair (rail et barre laterale).
        color: AppPalette.of(context).surfaceCanvas.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                end: AppSpacing.lg,
                top: AppSpacing.sm,
              ),
              child: LienFleche(
                key: const ValueKey<String>('retour-accueil'),
                icone: AppIcons.retour,
                fleche: false,
                libelle: t.commun.etats.actions.retourAccueil,
                onPress: () => context.go(_adresse(EcranDemoAdulte.accueil)),
              ),
            ),
            Expanded(
              child: FoyerPage(
                onAller: allerFoyer,
                // La ligne de la place ouvre ce que son etat permet : inviter
                // (place libre), l'invitation envoyee, ou la place (EA-8).
                onPlaceAdulte: () => context.go(
                  _adresse(switch (place) {
                    PlaceDisponible() => EcranDemoAdulte.inviterConjoint,
                    InvitationEnvoyee() => EcranDemoAdulte.invitationEnvoyee,
                    // Une demande de reprise attend sa reponse : la ligne
                    // ouvre la decision (EA-11, UX_REVIEW_07 ligne 18 d).
                    PlaceOccupee(repriseARepondre: true) =>
                      EcranDemoAdulte.repriseTitulaire,
                    _ => EcranDemoAdulte.placeAdulte,
                  }),
                ),
                onPaiementsFoyer: () =>
                    context.go(_adresse(EcranDemoAdulte.paiementsFoyer)),
                onAProposForfait: () =>
                    context.go(_adresse(EcranDemoAdulte.aProposForfait)),
                // Validation refusee : la nouvelle demande relance
                // l'invitation (E5, EA-BR-18).
                onNouvelleDemande: () =>
                    context.go(_adresse(EcranDemoAdulte.inviterConjoint)),
              ),
            ),
          ],
        ),
      ),
    };

    return ProviderScope(
      key: ValueKey<String>(_adresse(vu, eleve: eleve)),
      overrides: <Override>[
        ...surchargesDemoTuteur(environnement: environnement, eleves: enfants),
        // Aucune deconnexion reelle depuis la demonstration (revue EA-R M6).
        serviceAuthProvider.overrideWithValue(
          _ServiceAuthDemo(() => context.go(Routes.demoAdulte)),
        ),
        // Sous un ProviderScope imbrique, un provider derive non surcharge se
        // resoudrait dans le conteneur racine, sans les eleves Diallo.
        profilsElevesFoyerProvider.overrideWith(
          (Ref _) async => <ProfilEleveFoyer>[
            for (final EleveDuFoyer e in enfants) ProfilEleveFoyer.depuis(e),
          ],
        ),
        donneesAppareilsFoyerProvider.overrideWith(
          (Ref _) async =>
              (eleves: enfants, appareils: const <AppareilAppaire>[]),
        ),
        horsLigneProvider.overrideWith(
          (Ref _) => Stream<bool>.value(reseauCoupe),
        ),
        // Le formulaire d'ajout : la porte du titulaire (compte actif) et une
        // creation de demonstration, qui n'envoie rien (K-28).
        porteAjoutProfilProvider.overrideWithValue(PorteAcces.actif),
        portCreationProfilEleveProvider.overrideWithValue(
          const _CreationProfilDemo(),
        ),
        // N2 (FA5) : Mamadou suit deja les cours, il a son profil eleve ; la
        // page le dit, sans rien creer.
        profilEleveTitulaireExisteProvider.overrideWith((Ref _) async => true),
        // Ma famille du titulaire (EA-5, EA-BR-14) : son identite par le port
        // du Compte, et la place adulte selon la situation.
        identiteTitulaireProvider.overrideWith(
          (Ref _) async =>
              DonneesAdulteDemo.identite(genre, VueDemoAdulte.titulaire),
        ),
        foyerTitulaireProvider.overrideWith((Ref _) async => titulaire),
        // Les finances du foyer, au titulaire seulement (F7) : Ma famille a
        // la composition du Foyer du tuteur (E-11, revue FI-VAGUE-R R1-06),
        // la synthese, la finance de chaque enfant sur sa carte et les
        // dernieres transactions ; « Paiements du foyer », l'historique.
        // Les fournisseurs derives sont surcharges ici : sous ce
        // ProviderScope imbrique, ils se resoudraient sinon sur le port reel
        // (indisponible). Reseau coupe : les lectures echouent (hors ligne).
        portPaiementsFoyerProvider.overrideWithValue(paiements),
        financesFoyerProvider.overrideWith(
          (Ref _) => reseauCoupe
              ? Future<FinancesFoyer>.error(_reseauCoupe)
              : paiements.finances(),
        ),
        derniersMouvementsFoyerProvider.overrideWith(
          (Ref _) => reseauCoupe
              ? Future<List<MouvementFoyer>>.error(_reseauCoupe)
              : paiements.derniersMouvements(
                  limite: nombreDernieresTransactions,
                ),
        ),
        paiementsFoyerProvider.overrideWith(
          (Ref _) => reseauCoupe
              ? Future<List<PaiementFoyer>>.error(_reseauCoupe)
              : paiements.historique(),
        ),
        // L'invitation (EA-6, EA-BR-15) : rien n'est envoye (K-28).
        portInvitationConjointProvider.overrideWithValue(_InvitationDemo(etat)),
        // Le retrait du second adulte (EA-8, EA-BR-21) : rien n'est envoye.
        portSortieForfaitProvider.overrideWithValue(_SortieDemo(etat)),
        // La recharge (EA-10, EA-BR-24 et 25), au titulaire seulement (F7) :
        // rien n'est paye.
        portRechargeFoyerProvider.overrideWithValue(
          _RechargeDemo(etat, genre, foyerNouveau: foyerNouveau),
        ),
        // Derive du port : sans surcharge ici, il se resoudrait dans le
        // conteneur racine, sur le port reel (indisponible).
        beneficiairesRechargeProvider.overrideWith(
          (Ref _) => _RechargeDemo(
            etat,
            genre,
            foyerNouveau: foyerNouveau,
          ).beneficiaires(),
        ),
        // La demande de reprise qui concerne le titulaire (EA-11, EA-BR-28) :
        // rien n'est envoye.
        if (DonneesAdulteDemo.repriseTitulaire(etat)
            case final DemandeRepriseRecue demande)
          demandeRepriseRecueProvider.overrideWith((Ref _) async => demande),
        portRepriseFoyerProvider.overrideWithValue(_RepriseDemo(etat)),
      ],
      child: RepereDemonstration(
        child: NavShell(
          destinations: destinations,
          indexActif: destinations.indexWhere(
            (Destination d) => d.chemin == Routes.tuteurFoyer,
          ),
          onAller: (String chemin) => context.go(
            _adresse(switch (chemin) {
              Routes.tuteurFoyer => EcranDemoAdulte.maFamille,
              _ => EcranDemoAdulte.accueil,
            }),
          ),
          child: page,
        ),
      ),
    );
  }
}

/// La creation d'un profil eleve en demonstration : les memes regles
/// d'ecran que l'adaptateur reel (seul « Un enfant ou un mineur », compte
/// actif), et rien n'est envoye (K-28). Le formulaire ouvre ensuite une page
/// qui dit que rien n'a ete cree (`profilNonCree`).
class _CreationProfilDemo implements PortCreationProfilEleve {
  const _CreationProfilDemo();

  @override
  bool peutCreer(PourQui pourQui, {required PorteAcces porte}) =>
      pourQui == PourQui.enfantOuMineur && porte == PorteAcces.actif;

  @override
  Future<ResultatCreationProfil> creer(BrouillonProfilEleve _) async =>
      const ProfilCree();
}

/// L'invitation en demonstration (EA-6) : rien n'est envoye (K-28). « Erreur
/// reseau » rend la coupure ; « Double soumission » repond apres une latence
/// SIMULEE, qui laisse voir le bouton en attente et le second appui ignore
/// (ce n'est pas un delai du produit, F17).
///
/// Reponse tardive apres annulation (doc section 5.2, EA-6c) : apres
/// `annuler()`, la demonstration fait arriver l'acceptation de l'invitee ;
/// Ma famille lit alors la place que le serveur de demonstration rend apres
/// cette acceptation (`DonneesAdulteDemo.acceptationRecue`, situation
/// « Invitation annulee ») : personne n'est rattache (EA-BR-15).
class _InvitationDemo implements PortInvitationConjoint {
  const _InvitationDemo(this.etat);

  final EtatDemoAdulte etat;

  Future<T> _repondre<T>(T reussite, T coupure) async {
    if (etat == EtatDemoAdulte.erreurReseau) return coupure;
    if (etat == EtatDemoAdulte.doubleSoumission) {
      await Future<void>.delayed(latenceSimulee);
    }
    return reussite;
  }

  @override
  Future<ResultatInvitation> envoyer(InvitationConjoint _) =>
      _repondre<ResultatInvitation>(
        const InvitationPartie(),
        const InvitationEchecReseau(),
      );

  @override
  Future<ResultatAnnulation> annuler() => _repondre<ResultatAnnulation>(
    const AnnulationFaite(),
    const AnnulationEchecReseau(),
  );
}

/// La reponse du second adulte en demonstration (EA-7, EA-BR-20) : rien
/// n'est envoye (K-28). « Erreur reseau » rend la coupure (D5) ; « Double
/// soumission » repond apres la meme latence simulee que l'invitation ; sinon
/// l'etat que le serveur de demonstration rend (`acceptationDe`), ou le refus
/// enregistre.
class _ReponseInvitationDemo implements PortReponseInvitation {
  const _ReponseInvitationDemo(this.etat, this.genre);

  final EtatDemoAdulte etat;
  final GenreTitulaireDemo genre;

  Future<ResultatReponseInvitation> _repondre(EtatInvitationRecue suite) async {
    if (etat == EtatDemoAdulte.erreurReseau) return const ReponseEchecReseau();
    if (etat == EtatDemoAdulte.doubleSoumission) {
      await Future<void>.delayed(latenceSimulee);
    }
    return ReponseRecue(suite);
  }

  @override
  Future<ResultatReponseInvitation> accepter({required String cle}) =>
      _repondre(DonneesAdulteDemo.acceptationDe(etat, genre));

  @override
  Future<ResultatReponseInvitation> refuser({required String cle}) =>
      _repondre(const InvitationRefuseeParVous());
}

/// La sortie en demonstration (EA-8, EA-BR-21) : rien n'est envoye (K-28).
/// « Erreur reseau » rend la coupure (D5) ; « Double soumission » repond
/// apres la meme latence simulee ; sinon le rattachement a pris fin, avec la
/// date de delai que le serveur de demonstration rend apres un retrait, la
/// meme que Ma famille lira ensuite (`finDelaiPour`, F17).
class _SortieDemo implements PortSortieForfait {
  const _SortieDemo(this.etat);

  final EtatDemoAdulte etat;

  Future<ResultatSortie> _repondre() async {
    if (etat == EtatDemoAdulte.erreurReseau) return const SortieEchecReseau();
    if (etat == EtatDemoAdulte.doubleSoumission) {
      await Future<void>.delayed(latenceSimulee);
    }
    return SortieFaite(
      nouvelleDemandeLe: DonneesAdulteDemo.finDelaiPour(
        EtatDemoAdulte.conjointRetire,
      ),
    );
  }

  @override
  Future<ResultatSortie> retirerSecondAdulte({required String cle}) =>
      _repondre();

  @override
  Future<ResultatSortie> quitterForfait({required String cle}) => _repondre();
}

/// La recharge en demonstration (EA-10) : les beneficiaires et leurs offres,
/// et le recapitulatif que le serveur de demonstration arrete (EA-BR-24).
/// Le paiement n'est jamais fait (F13, EA-BR-25) : il rend l'etat honnete
/// (`CapaciteIndisponible`, aucun prestataire, doc section 20.8) ; « Erreur
/// reseau » rend la coupure (D5) ; « Double soumission » repond apres la
/// meme latence simulee. Rien n'est envoye (K-28).
class _RechargeDemo implements PortRechargeFoyer {
  const _RechargeDemo(this.etat, this.genre, {this.foyerNouveau = false});

  final EtatDemoAdulte etat;
  final GenreTitulaireDemo genre;
  final bool foyerNouveau;

  @override
  Future<List<BeneficiaireRecharge>> beneficiaires() async =>
      DonneesAdulteDemo.beneficiairesRecharge(
        etat,
        genre,
        foyerNouveau: foyerNouveau,
      );

  @override
  Future<RecapitulatifRecharge> verifier(List<ChoixRecharge> choix) async =>
      DonneesAdulteDemo.recapitulatifRecharge(
        etat,
        genre,
        choix,
        foyerNouveau: foyerNouveau,
      );

  @override
  Future<String> payer({
    required String recapitulatifId,
    required String cle,
  }) async {
    if (etat == EtatDemoAdulte.erreurReseau) {
      throw StateError('coupure simulee');
    }
    if (etat == EtatDemoAdulte.doubleSoumission) {
      await Future<void>.delayed(latenceSimulee);
    }
    throw const CapaciteIndisponible('FI-BR-06');
  }

  // La recharge se choisit par montants depuis FI-7 (un seul moteur) ; le
  // suivi des huit etats arrive avec FI-8.
  @override
  Future<RecapitulatifRecharge> verifierMontants(
    List<MontantRecharge> choix,
  ) async => DonneesAdulteDemo.recapitulatifMontants(
    etat,
    genre,
    choix,
    foyerNouveau: foyerNouveau,
  );

  @override
  Future<SuiviPaiement> suivre(String commandeId) =>
      Future<SuiviPaiement>.error(const CapaciteIndisponible('FI-BR-06'));
}

/// La reprise du foyer en demonstration (EA-11, EA-BR-27 et 28) : rien n'est
/// envoye (K-28). « Erreur reseau » rend la coupure (D5) ; « Double
/// soumission » repond apres la meme latence simulee ; sinon le geste est
/// enregistre et la page relit l'etat que le serveur de demonstration rend.
class _RepriseDemo implements PortRepriseFoyer {
  const _RepriseDemo(this.etat);

  final EtatDemoAdulte etat;

  Future<ResultatReprise> _repondre() async {
    if (etat == EtatDemoAdulte.erreurReseau) return const RepriseEchecReseau();
    if (etat == EtatDemoAdulte.doubleSoumission) {
      await Future<void>.delayed(latenceSimulee);
    }
    return const RepriseEnregistree();
  }

  @override
  Future<ResultatReprise> deposer({required String cle}) => _repondre();

  @override
  Future<ResultatReprise> refuser({required String cle}) => _repondre();
}

/// La latence reseau simulee de la situation « Double soumission » : le
/// jeton de mouvement le plus long (EA-6c), assez pour voir l'attente.
const Duration latenceSimulee = Mouvement.maximum;
