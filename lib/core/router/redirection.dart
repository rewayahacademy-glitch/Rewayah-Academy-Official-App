import '../config/env.dart';
import '../domain/enums.dart';
import '../session/session_state.dart';
import 'billet_salle.dart';
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
String? deciderRedirection({
  required SessionState session,
  required String cheminDemande,
  required DateTime maintenant,
  BilletSalle? billet,
}) {
  // La galerie de developpement echappe a la porte : elle ne montre que des
  // composants, aucune donnee. Elle n'est de toute facon pas compilee en
  // production.
  if (Env.galerieActive && cheminDemande == Routes.galerie) {
    return null;
  }

  switch (session.porte) {
    // Tant que la session n'est pas resolue, on ne decide rien : rediriger sur
    // un etat inconnu ferait clignoter l'ecran au demarrage.
    case PorteAcces.chargement:
      return null;

    // La connexion a deux entrees : celle de l'adulte, et celle de l'enfant qui
    // arrive avec un code. Le sous-arbre entier est donc public.
    case PorteAcces.deconnecte:
      return _dansLeSousArbre(cheminDemande, Routes.connexion)
          ? null
          : Routes.connexion;

    // Session valide, aucun profil : l'inscription est la seule destination.
    // Sans cette porte, ce compte retombait en `deconnecte` et repartait sur
    // l'ecran de connexion en boucle
    // (`docs/architecture/etape-3-auth-kyc.md` section 2.1).
    case PorteAcces.inscription:
      return _dansLeSousArbre(cheminDemande, Routes.inscription)
          ? null
          : Routes.inscription;

    // Un compte en portail d'attente n'atteint aucune route protegee, quelle
    // que soit l'URL tapee directement dans un navigateur. Le portail a ses
    // propres pages, accusé, contrat et depot de piece : c'est le sous-arbre
    // entier qui est ouvert, pas la seule racine.
    case PorteAcces.attente:
    case PorteAcces.suspendu:
      return _dansLeSousArbre(cheminDemande, Routes.attente)
          ? null
          : Routes.attente;

    case PorteAcces.actif:
      final AppRole? role = session.role;
      if (role == null) {
        return Routes.connexion;
      }
      final String racine = Routes.racinePour(role);

      // Un compte actif n'a plus rien a faire sur la racine, la connexion,
      // l'inscription ou le portail d'attente, sous-arbres compris.
      if (cheminDemande == Routes.racine ||
          _dansLeSousArbre(cheminDemande, Routes.connexion) ||
          _dansLeSousArbre(cheminDemande, Routes.inscription) ||
          _dansLeSousArbre(cheminDemande, Routes.attente)) {
        return racine;
      }

      // La salle n'est ni partageable ni memorisable en favori (ADR-005). Le
      // billet ne transite pas par l'URL : une adresse copiee, rouverte dans un
      // autre onglet ou le lendemain, arrive sans billet et repart d'ou elle
      // vient.
      if (cheminDemande == Routes.salle) {
        final bool presentable = billet != null && billet.valideA(maintenant);
        return presentable ? null : racine;
      }

      // Une route d'un autre role demandee directement par URL renvoie chez
      // soi, sur le Web comme ailleurs.
      final String prefixe = Routes.prefixePour(role);
      return _dansLeSousArbre(cheminDemande, prefixe) ? null : racine;
  }
}

/// Vrai quand [chemin] est [racine] ou l'une de ses pages filles.
///
/// La comparaison teste `racine/` et non un simple prefixe : sans le separateur,
/// `/attentes-du-tuteur` passerait pour une page de `/attente`.
bool _dansLeSousArbre(String chemin, String racine) =>
    chemin == racine || chemin.startsWith('$racine/');
