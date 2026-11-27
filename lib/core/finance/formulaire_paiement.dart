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
/// dans tous les modes (l'apparence de l'element de paiement de Stripe se
/// regle dans la page, pas a la creation de la session).
ColorScheme couleursFormulairePaiement() =>
    AppTheme.pour(InterfaceMode.standard, Brightness.light).colorScheme;

/// Le serveur n'a pas pu fermer le formulaire ouvert avant ce nouveau depart
/// (session deja payee a l'instant, ou prestataire injoignable) : aucune
/// nouvelle session n'est ouverte, rien n'est paye deux fois.
class PaiementPrecedentOuvert implements Exception {
  /// Cree l'erreur.
  const PaiementPrecedentOuvert();
}

/// La dette ou les mois ont change entre la verification et le paiement
/// (une facture est tombee, le mois a change) : le serveur refuse AVANT le
/// prestataire. Rien n'est paye ; la famille verifie de nouveau.
class MontantChange implements Exception {
  /// Cree l'erreur.
  const MontantChange();
}

/// Ce qu'il faut pour monter le formulaire de Stripe d'une commande.
class FormulairePaiement {
  /// Cree le formulaire.
  const FormulairePaiement({
    required this.clePublique,
    required this.secretClient,
    this.email,
  });

  /// La cle publiable du compte Stripe (`pk_...`).
  final String clePublique;

  /// Le secret client de la session Checkout de la commande.
  final String secretClient;

  /// LINK-CHOIX : l'adresse du compte, exigee par Stripe a la confirmation ;
  /// passee seulement au moment de payer.
  final String? email;
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
