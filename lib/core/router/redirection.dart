import '../../features/demo/mode_demonstration.dart';
import '../config/env.dart';
import '../domain/enums.dart';
import '../preferences/presentation_vue.dart';
import '../session/session_state.dart';
import 'billet_salle.dart';
import 'chemin_retour.dart';
import 'routes.dart';

/// Decide de la redirection a appliquer, ou `null` pour laisser passer.
///
/// Fonction pure, volontairement separee de la construction du routeur : les
/// scenarios d'acceptation 3 et 6 de l'etape 2 se verifient ici sans monter
/// d'application ni de reseau.
///
/// Rappel de cadrage : **ceci n'est pas une barriere de securite.** La
/// protection reelle reste la RLS de l'etape 1. Une route atteinte malgre cette
/// fonction ne donnerait acces a aucune donnee supplementaire.
///
/// Les etats transverses (mandat Tuteur V1 section 8) :
///
/// - [routeConnue] faux (aucune route ne correspond) : on laisse passer, et
///   le routeur rend la page « introuvable », qui ne montre aucune donnee et
///   ramene a l'accueil ou a la connexion selon la session ;
/// - une route connue d'un autre role, ou un sous-arbre `/tc/` qui lui est
///   ferme : pour le tuteur, la page « acces refuse » ([Routes.accesRefuse]),
///   qui ramene a sa racine ; pour les autres roles, leur racine, comme
///   avant le chantier Tuteur V1 ;
/// - une route protegee demandee sans session : la connexion, avec le chemin
///   demande en `retour` s'il est un chemin interne valide
///   (`cheminRetourValide`) ; une fois connecte, on y retourne s'il est ouvert
///   au role, sinon a la racine ;
/// - aucune reponse du serveur a la lecture du profil : la page hors ligne
///   ([Routes.horsLigne]), qui n'ouvre rien.
///
/// [cheminComplet] est l'adresse demandee avec sa requete (le `retour`), et
/// [retour] le parametre `retour` de cette adresse.
///
/// [presentation] dit si la presentation publique a deja ete vue sur cet
/// appareil (PUB-1) : elle ne compte que pour la racine d'un visiteur sans
/// session.
String? deciderRedirection({
  required SessionState session,
  required String cheminDemande,
  required DateTime maintenant,
  BilletSalle? billet,
  bool routeConnue = true,
  String? cheminComplet,
  String? retour,
  String environnement = Env.environnement,
  EtatPresentation presentation = EtatPresentation.aVoir,
}) {
  // La salle de demonstration passe sans session hors production : donnees
  // fictives, aucun appel serveur (K-28). En production, la route n'existe
  // pas et cette porte reste fermee.
  if (environnementAutoriseDemo(environnement) &&
      (cheminDemande == Routes.demoSalle ||
          cheminDemande.startsWith('${Routes.demoSalle}/') ||
          cheminDemande == Routes.demoClasse ||
          cheminDemande.startsWith('${Routes.demoClasse}/') ||
          cheminDemande == Routes.demoEnseignant ||
          cheminDemande.startsWith('${Routes.demoEnseignant}/') ||
          cheminDemande == Routes.demoControleur ||
          cheminDemande.startsWith('${Routes.demoControleur}/') ||
          cheminDemande == Routes.demoAccessibilite ||
          cheminDemande.startsWith('${Routes.demoAccessibilite}/') ||
          cheminDemande == Routes.demoAdulte ||
          cheminDemande.startsWith('${Routes.demoAdulte}/'))) {
    return null;
  }

  // La galerie de developpement echappe a la porte : elle ne montre que des
  // composants, aucune donnee. Elle n'est de toute facon pas compilee en
  // production.
  if (Env.galerieActive &&
      (cheminDemande == Routes.galerie ||
          cheminDemande.startsWith('${Routes.galerie}/'))) {
    return null;
  }

  switch (session.porte) {
    // Tant que la session n'est pas resolue, on ne decide rien : rediriger sur
    // un etat inconnu ferait clignoter l'ecran au demarrage.
    case PorteAcces.chargement:
      return null;

    // Le serveur n'a pas repondu : une seule page, qui n'ouvre rien et
    // relance la lecture. Jamais le portail d'attente, jamais un acces.
    case PorteAcces.horsLigne:
      return cheminDemande == Routes.horsLigne ? null : Routes.horsLigne;

    // Les sous-arbres publics, lus dans UNE liste (`Routes.publiques`) : la
    // connexion (celle de l'adulte, et celle de l'enfant qui arrive avec un
    // code, scanner et saisie compris), la recuperation d'acces, l'accueil
    // public, et l'entree d'un agent IA (ADR-025), publique par construction :
    // un porteur de jeton n'a, par definition, aucune session, et la renvoyer
    // sur `/connexion` lui ferait perdre le jeton passe dans l'URL.
    case PorteAcces.deconnecte:
      for (final String publique in Routes.publiques) {
        if (_dansLeSousArbre(cheminDemande, publique)) {
          return null;
        }
      }
      if (!routeConnue) {
        return null;
      }
      // La racine d'un visiteur sans session (demande A-1, PUB-1) : la
      // presentation publique `/bienvenue` a la premiere visite sur cet
      // appareil, la connexion ensuite. Tant que l'appareil n'a pas ete lu,
      // on ne decide rien : l'ecran de demarrage reste, sans clignotement.
      if (cheminDemande == Routes.racine) {
        return switch (presentation) {
          EtatPresentation.inconnu => null,
          EtatPresentation.aVoir => Routes.bienvenue,
          EtatPresentation.vue => Routes.connexion,
        };
      }
      // Session expiree, ou lien profond ouvert sans session : la connexion
      // garde la destination, si c'en est une (R7 : un chemin interne valide,
      // jamais la salle, la classe ni l'entree d'agent).
      final String? destination = cheminRetourValide(
        cheminComplet ?? cheminDemande,
      );
      return destination == null
          ? Routes.connexion
          : Uri(
              path: Routes.connexion,
              queryParameters: <String, String>{'retour': destination},
            ).toString();

    // Session valide, aucun profil : l'inscription est la seule destination.
    // Sans cette porte, ce compte retombait en `deconnecte` et repartait sur
    // l'ecran de connexion en boucle
    // (`docs/archive/2026-09-pre-remise-a-plat/architecture/etape-3-auth-kyc.md` section 2.1).
    case PorteAcces.inscription:
      return _dansLeSousArbre(cheminDemande, Routes.inscription) || !routeConnue
          ? null
          : Routes.inscription;

    // Un compte en portail d'attente n'atteint aucune route protegee, quelle
    // que soit l'URL tapee directement dans un navigateur. Le portail a ses
    // propres pages, accusé, contrat et depot de piece : c'est le sous-arbre
    // entier qui est ouvert, pas la seule racine.
    case PorteAcces.attente:
    case PorteAcces.suspendu:
      // K-47 (HL-A-6) : la piece d'identite ne concerne que l'enseignant. Un
      // tuteur ne depose aucune piece : le depot lui reste ferme, meme par
      // une adresse tapee a la main.
      if (session.role == AppRole.guardian &&
          _dansLeSousArbre(cheminDemande, Routes.attentePiece)) {
        return Routes.attente;
      }
      return _dansLeSousArbre(cheminDemande, Routes.attente) || !routeConnue
          ? null
          : Routes.attente;

    case PorteAcces.actif:
      final AppRole? role = session.role;
      if (role == null) {
        return Routes.connexion;
      }
      final String racine = Routes.racinePour(role);

      // Un compte actif n'a plus rien a faire sur la racine, la connexion,
      // l'inscription, le portail d'attente ou la page hors ligne,
      // sous-arbres compris. Une session d'agent resolue quitte `/agent`
      // comme un compte connecte quitte `/connexion` : le tunnel d'entree a
      // fini son travail. Au sortir de la connexion, la destination gardee
      // en `retour` est reprise si elle est valide et ouverte au role.
      if (cheminDemande == Routes.racine ||
          cheminDemande == Routes.horsLigne ||
          _dansLeSousArbre(cheminDemande, Routes.connexion) ||
          _dansLeSousArbre(cheminDemande, Routes.bienvenue) ||
          _dansLeSousArbre(cheminDemande, Routes.inscription) ||
          _dansLeSousArbre(cheminDemande, Routes.agentEntree) ||
          _dansLeSousArbre(cheminDemande, Routes.attente)) {
        if (cheminDemande == Routes.connexion) {
          final String? reprise = _reprise(session, retour, maintenant);
          if (reprise != null) {
            return reprise;
          }
        }
        return racine;
      }

      // Le tuteur a son propre compte, quatrieme branche de sa coquille, et
      // ses classes sous `/tuteur/classes` : ses anciennes adresses communes
      // (`/compte*`, `/tc/groupes*`) le rejoignent la ou il a sa barre
      // (mapping des routes Tuteur V1, section 2). Les autres roles gardent
      // les leurs.
      if (role == AppRole.guardian) {
        final String? alias = _aliasTuteur(cheminDemande);
        if (alias != null) {
          return alias;
        }
      }

      // Aucune route ne correspond : la page introuvable le dit, sans rien
      // montrer, et ramene a l'accueil du role.
      if (!routeConnue) {
        return null;
      }

      // La salle n'est ni partageable ni memorisable en favori (ADR-005). Le
      // billet ne transite pas par l'URL : une adresse copiee, rouverte dans un
      // autre onglet ou le lendemain, arrive sans billet et repart d'ou elle
      // vient.
      if (cheminDemande == Routes.salle) {
        final bool presentable = billet != null && billet.valideA(maintenant);
        return presentable ? null : racine;
      }

      // Le compte est un espace commun : chaque role actif peut consulter ses
      // informations et ses preferences sans changer d'espace metier. La page
      // « acces refuse » est ouverte a tous, par construction.
      if (_dansLeSousArbre(cheminDemande, Routes.compte) ||
          cheminDemande == Routes.accesRefuse) {
        return null;
      }

      // Le Teaching Core vit sous `/tc/`, hors du prefixe unique de chaque
      // role (plan d'integration Teaching Core, etape 7 section 8.2 point 4).
      // Sans cette autorisation explicite, les sept chemins seraient tous
      // inatteignables : `/tc/` n'appartient a aucun role.
      if (_teachingCoreAutorise(cheminDemande, role)) {
        return null;
      }

      // Une route d'un autre role demandee directement par URL n'ouvre rien,
      // sur le Web comme ailleurs. Le tuteur voit la page « acces refuse »,
      // qui le dit et ramene a sa racine (mandat Tuteur V1 section 8). Les
      // autres roles gardent le renvoi a leur racine d'avant le chantier :
      // leur navigation ne change pas sans decision du directeur (revue
      // phase 0, routes D3).
      final String prefixe = Routes.prefixePour(role);
      if (_dansLeSousArbre(cheminDemande, prefixe)) {
        return null;
      }
      return role == AppRole.guardian ? Routes.accesRefuse : racine;
  }
}

/// La destination gardee en `retour`, si elle est un chemin interne valide et
/// **ouverte a cette session** ; sinon `null` (la racine du role).
String? _reprise(SessionState session, String? retour, DateTime maintenant) {
  final String? cible = cheminRetourValide(retour);
  if (cible == null) {
    return null;
  }
  final String chemin = Uri.parse(cible).path;
  // Jamais de retour vers le tunnel d'entree lui-meme : ce serait une boucle.
  // Jamais non plus vers une page d'etat (acces refuse, hors ligne) : elle
  // n'est pas une destination, et l'utilisateur qui se reconnecte y
  // atterrirait sans raison (revue phase 0, routes D6).
  if (chemin == Routes.racine ||
      chemin == Routes.accesRefuse ||
      chemin == Routes.horsLigne ||
      _dansLeSousArbre(chemin, Routes.connexion) ||
      _dansLeSousArbre(chemin, Routes.inscription) ||
      _dansLeSousArbre(chemin, Routes.attente)) {
    return null;
  }
  return deciderRedirection(
            session: session,
            cheminDemande: chemin,
            maintenant: maintenant,
          ) ==
          null
      ? cible
      : null;
}

/// La nouvelle adresse d'un chemin commun pour le tuteur, ou `null`.
///
/// - `/compte` et ses pages rejoignent `/tuteur/compte` : profil vers
///   `informations`, reglages vers `preferences` ; les profils du foyer
///   rejoignent le Foyer et la fiche d'un eleve ;
/// - `/tc/groupes` rejoint l'Accueil (la classe se choisit depuis lui), et
///   `/tc/groupes/:id` la classe `/tuteur/classes/:id`, dans la branche
///   Accueil.
String? _aliasTuteur(String chemin) {
  if (chemin == Routes.compte) {
    return Routes.tuteurCompte;
  }
  if (chemin == Routes.compteProfil) {
    return Routes.compteTuteurSousPage('informations');
  }
  if (chemin == Routes.compteReglages) {
    return Routes.tuteurComptePreferences;
  }
  if (chemin == Routes.compteProfils) {
    return Routes.tuteurFoyer;
  }
  if (chemin.startsWith('${Routes.compteProfils}/')) {
    final String reste = chemin.substring(Routes.compteProfils.length + 1);
    return reste.isEmpty || reste.contains('/')
        ? Routes.tuteurFoyer
        : Routes.ficheElevePour(reste);
  }
  if (_dansLeSousArbre(chemin, Routes.compte)) {
    // Une page de compte inconnue garde son nom sous `/tuteur/compte` : si
    // elle n'y existe pas non plus, la page introuvable le dit.
    return '${Routes.tuteurCompte}${chemin.substring(Routes.compte.length)}';
  }
  if (chemin == Routes.tcGroupes) {
    return Routes.tuteurAccueil;
  }
  if (chemin.startsWith('${Routes.tcGroupes}/')) {
    final String groupe = chemin
        .substring(Routes.tcGroupes.length + 1)
        .split('/')
        .first;
    return groupe.isEmpty ? Routes.tuteurAccueil : Routes.classePour(groupe);
  }
  return null;
}

/// Vrai quand [chemin] est [racine] ou l'une de ses pages filles.
///
/// La comparaison teste `racine/` et non un simple prefixe : sans le separateur,
/// `/attentes-du-tuteur` passerait pour une page de `/attente`.
bool _dansLeSousArbre(String chemin, String racine) =>
    chemin == racine || chemin.startsWith('$racine/');

/// Autorise un role a entrer dans un sous-arbre `/tc/` precis.
///
/// **Chaque sous-arbre porte ses propres roles**, contrairement au prefixe
/// unique de [Routes.prefixePour] : `/tc/groupes` s'ouvre a l'eleve et au
/// tuteur, `/tc/classe` a l'enseignant et a l'eleve, `/tc/mushaf` au seul
/// eleve, `/tc/observation/...` au tuteur, a l'admin et au controleur. La
/// table vient du plan d'integration Teaching Core, section 8.2.
bool _teachingCoreAutorise(String chemin, AppRole role) {
  if (_dansLeSousArbre(chemin, Routes.tcGroupes) ||
      _dansLeSousArbre(chemin, Routes.tcBibliotheque)) {
    return role == AppRole.student || role == AppRole.guardian;
  }
  if (_dansLeSousArbre(chemin, Routes.tcClasse)) {
    return role == AppRole.teacher || role == AppRole.student;
  }
  if (_dansLeSousArbre(chemin, Routes.tcMushaf)) {
    return role == AppRole.student;
  }
  if (_dansLeSousArbre(chemin, '/tc/observation')) {
    return role == AppRole.guardian ||
        role == AppRole.admin ||
        role == AppRole.controller;
  }
  return false;
}
