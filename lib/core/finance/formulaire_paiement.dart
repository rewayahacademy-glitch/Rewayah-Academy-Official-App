// Le formulaire de paiement integre (FI-BR-06, decision du directeur du
// 01/11/2026 : « le paiement doit se faire sur l'app, pas de sortir
// ailleurs »).
//
// Le serveur (`recharge-payer`) rend, pour une commande, le secret client de
// la session Stripe et la cle publiable du compte : de quoi monter le
// formulaire de Stripe dans la page de resultat, sans quitter l'application.
// Ni l'un ni l'autre n'est un secret du compte : la cle publiable est faite
// pour le navigateur, et le secret client ne sert qu'a payer CETTE session.
// Rien n'est conclu ici : seul le webhook signe credite (FI9).
//
// PAY-UX (constats du directeur du 02/11/2026) : la page du formulaire a
// toujours le meme fond clair, quel que soit le theme, et le serveur donne ce
// meme fond au formulaire de Stripe (`branding_settings.background_color`) :
// plus de cadre d'une autre couleur autour du formulaire (le CSS de la page
// ne traverse pas l'iframe de Stripe).

import 'package:flutter/material.dart';

import '../domain/enums.dart';
import '../theme/app_theme.dart';

/// Le fond de la page du formulaire de paiement : la surface du theme clair,
/// dans tous les modes (le formulaire de Stripe a son propre fond, reglable
/// seulement a la creation de la session).
ColorScheme couleursFormulairePaiement() =>
    AppTheme.pour(InterfaceMode.standard, Brightness.light).colorScheme;

/// Ce fond en « #RRGGBB », tel que le serveur le pose sur la session.
String fondFormulairePaiement() =>
    '#${(couleursFormulairePaiement().surface.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Le serveur n'a pas pu fermer le formulaire ouvert avant ce nouveau depart
/// (session deja payee a l'instant, ou prestataire injoignable) : aucune
/// nouvelle session n'est ouverte, rien n'est paye deux fois.
class PaiementPrecedentOuvert implements Exception {
  /// Cree l'erreur.
  const PaiementPrecedentOuvert();
}

/// Ce qu'il faut pour monter le formulaire de Stripe d'une commande.
class FormulairePaiement {
  /// Cree le formulaire.
  const FormulairePaiement({
    required this.clePublique,
    required this.secretClient,
    this.forme = FormeFormulaire.integre,
    this.email,
  });

  /// La cle publiable du compte Stripe (`pk_...`).
  final String clePublique;

  /// Le secret client de la session Checkout de la commande.
  final String secretClient;

  /// LINK-CHOIX : la forme de la session, donc du formulaire a monter.
  final FormeFormulaire forme;

  /// LINK-CHOIX : l'adresse du compte, exigee par Stripe a la confirmation
  /// en [FormeFormulaire.elements] ; passee seulement au moment de payer.
  final String? email;
}

/// LINK-CHOIX (directeur, 06/11/2026 : « donner le choix aux users ») : la
/// forme du formulaire de Stripe.
enum FormeFormulaire {
  /// Le formulaire complet de Stripe (`embedded_page`) : Link y reconnait la
  /// personne de lui-meme et peut envoyer un code avant tout choix.
  integre,

  /// L'element de paiement (`elements`) : la carte, puis Link et les
  /// portefeuilles en boutons ; Link ne s'ouvre que sur un clic.
  elements;

  /// La forme lue dans la reponse du serveur ; l'ancienne par defaut.
  static FormeFormulaire depuis(String? v) =>
      v == 'elements' ? FormeFormulaire.elements : FormeFormulaire.integre;
}

/// GAINS (pilote et garde-cap, 06/11/2026) : une source qui sait reveiller
/// la fonction de paiement a l'ouverture de la recharge (le demarrage a froid
/// et le pre-vol coutaient 2,6 s au toucher de « Payer », le 06/11 a 13:28).
/// L'appel ne cree rien et son echec est ignore.
abstract interface class ChauffePaiement {
  /// Reveille la fonction de paiement, sans attendre ni rien dire.
  void chaufferPaiement();
}

/// Une source de paiement qui garde, pour la page de resultat, le formulaire
/// integre de chaque commande qu'elle vient d'ouvrir.
abstract interface class SourceFormulairePaiement {
  /// Le formulaire a monter pour [commandeId], ou `null` : aucun (page
  /// hebergee, commande deja decidee, ou application rechargee).
  FormulairePaiement? formulairePour(String commandeId);

  /// Le formulaire de [commandeId] ne se montre plus (paiement termine dans
  /// le formulaire, ou abandon).
  void oublierFormulaire(String commandeId);

  /// PAY-UX : vrai quand la source sait redemander un formulaire pour
  /// [commandeId] (la demande de paiement de cette commande est connue).
  bool peutRouvrir(String commandeId);

  /// PAY-UX (constat du directeur du 02/11/2026 : revenir rouvrait l'ancien
  /// formulaire, vide) : redemande au serveur un formulaire NEUF pour
  /// [commandeId]. Le serveur ferme d'abord l'ancien (jamais un formulaire
  /// deja paye) ; `null` quand il n'y a plus rien a payer. Leve
  /// [PaiementPrecedentOuvert] quand l'ancien n'a pas pu etre ferme.
  Future<FormulairePaiement?> rouvrirFormulaire(String commandeId);
}
