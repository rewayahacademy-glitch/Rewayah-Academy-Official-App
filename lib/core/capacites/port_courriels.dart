// Les e-mails sortants, cote direction (COURRIELS-1, migration
// 20261023120000) : ecrire un e-mail a la main et suivre la file d'envoi.
//
// Le serveur decide de tout : qui a le droit, quelles categories existent, si
// l'adresse est exclue, quand la file part. Flutter envoie et affiche ; il ne
// dit jamais « envoye » avant que la ligne soit `envoye` cote serveur. Un
// envoi manuel est mis en file ; la file est vidée par le serveur dans la
// minute.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'capacite_indisponible.dart';

/// Ou en est un e-mail de la file.
enum StatutCourriel {
  /// Dans la file, pas encore pris.
  enAttente('en_attente'),

  /// Pris par l'envoi, la reponse n'est pas revenue.
  envoi('envoi'),

  /// Parti : seul statut qui permet de dire « envoye ».
  envoye('envoye'),

  /// Les essais sont epuises.
  echec('echec'),

  /// Retire de la file.
  annule('annule');

  const StatutCourriel(this.sql);

  /// La valeur cote serveur.
  final String sql;

  /// Le statut de la valeur serveur, ou `null` si elle est inconnue.
  static StatutCourriel? depuisSql(String? v) {
    for (final StatutCourriel s in values) {
      if (s.sql == v) return s;
    }
    return null;
  }

  /// Vrai quand la direction peut remettre l'e-mail en file.
  bool get peutReessayer => this == echec || this == annule;
}

/// D'ou vient un e-mail.
enum OrigineCourriel {
  /// Un evenement de l'application.
  auto('auto'),

  /// La direction, a la main.
  manuel('manuel');

  const OrigineCourriel(this.sql);

  /// La valeur cote serveur.
  final String sql;

  /// L'origine de la valeur serveur, ou `null` si elle est inconnue.
  static OrigineCourriel? depuisSql(String? v) {
    for (final OrigineCourriel o in values) {
      if (o.sql == v) return o;
    }
    return null;
  }
}

/// Une ligne de la file, vue de la direction. Le corps n'y figure jamais.
@immutable
class CourrielSortant {
  /// Cree une ligne.
  const CourrielSortant({
    required this.id,
    required this.categorie,
    required this.modele,
    required this.destinataire,
    required this.origine,
    required this.statut,
    required this.tentatives,
    required this.creeLe,
    this.derniereErreur,
    this.envoyeLe,
    this.sujet,
    this.langue = 'fr',
  });

  /// L'identifiant.
  final String id;

  /// Le code de la categorie.
  final String categorie;

  /// Le modele de message (`message_libre` pour un envoi manuel).
  final String modele;

  /// L'adresse du destinataire.
  final String destinataire;

  /// Automatique ou manuel.
  final OrigineCourriel origine;

  /// Le statut.
  final StatutCourriel statut;

  /// Les essais d'envoi faits.
  final int tentatives;

  /// La derniere erreur rendue par le fournisseur, s'il y en a une.
  final String? derniereErreur;

  /// La mise en file.
  final DateTime creeLe;

  /// L'envoi, une fois parti.
  final DateTime? envoyeLe;

  /// Le sujet : seulement pour un message libre.
  final String? sujet;

  /// La langue dans laquelle l'e-mail part (COURRIELS-2) : celle de son
  /// destinataire, fixee par le serveur a la mise en file.
  final String langue;
}

/// Une categorie et l'adresse d'ou elle part.
@immutable
class CategorieCourriel {
  /// Cree une categorie.
  const CategorieCourriel({
    required this.code,
    required this.libelle,
    required this.expediteurAdresse,
    required this.expediteurNom,
    required this.repondreA,
    required this.essentielle,
    required this.active,
  });

  /// Le code.
  final String code;

  /// Le nom lu par la direction.
  final String libelle;

  /// L'adresse d'envoi (l'alias).
  final String expediteurAdresse;

  /// Le nom affiche a cote de l'adresse.
  final String expediteurNom;

  /// L'adresse qui recoit les reponses.
  final String repondreA;

  /// Vrai quand le message est lie au service : pas de desinscription.
  final bool essentielle;

  /// Faux quand la categorie est coupee : rien n'en part.
  final bool active;
}

/// Les champs que le serveur sait refuser (`22023`, message = nom du champ).
enum ChampCourriel {
  /// L'adresse du destinataire.
  adresse,

  /// La categorie.
  categorie,

  /// Le sujet.
  sujet,

  /// Le texte.
  corps,

  /// Le destinataire ne peut pas recevoir cet e-mail (compte enfant, ou
  /// desinscription).
  destinataireExclu;

  /// Le champ nomme par le serveur, ou `null` s'il est inconnu.
  static ChampCourriel? depuisServeur(String? message) =>
      switch ((message ?? '').trim().toLowerCase()) {
        'adresse' => adresse,
        'categorie' => categorie,
        'sujet' => sujet,
        'corps' => corps,
        'destinataire exclu' => destinataireExclu,
        _ => null,
      };
}

/// Le serveur refuse l'envoi (`22023`).
class CourrielInvalide implements Exception {
  /// Cree l'erreur. [champ] est `null` quand le serveur ne le nomme pas.
  const CourrielInvalide(this.champ);

  /// Ce qui est refuse, si c'est connu.
  final ChampCourriel? champ;

  @override
  String toString() => 'CourrielInvalide($champ)';
}

/// L'e-mail n'existe plus, ou n'est plus en echec ni annule (`P0002`).
class CourrielIntrouvable implements Exception {
  /// Cree l'erreur.
  const CourrielIntrouvable();

  @override
  String toString() => 'CourrielIntrouvable()';
}

/// Les e-mails sortants (contrat de la migration 20261023120000).
abstract interface class PortCourriels {
  /// Met un e-mail en file (`admin_courriel_envoyer`) et rend son identifiant.
  /// [cle] est la cle d'idempotence : la meme cle ne met jamais deux e-mails
  /// en file, un double appui rend la ligne deja creee. Adresse libre ici ;
  /// [profil] pour un envoi a un compte. [CourrielInvalide] si le serveur
  /// refuse.
  Future<String> envoyer({
    required String categorie,
    required String sujet,
    required String corps,
    required String cle,
    String? adresse,
    String? profil,
  });

  /// La file, la plus recente d'abord (`admin_courriels_lister`).
  Future<List<CourrielSortant>> lister({
    StatutCourriel? statut,
    int limite = 100,
  });

  /// Remet en file un e-mail en echec ou annule (`admin_courriel_reessayer`).
  /// [CourrielIntrouvable] si le serveur refuse.
  Future<void> reessayer(String id);

  /// Les categories et leur adresse d'envoi (`admin_courriel_categories`).
  Future<List<CategorieCourriel>> categories();
}

/// Tant qu'aucun adaptateur serveur n'est branche : les ecrans disent que la
/// fonction est indisponible.
class CourrielsIndisponibles implements PortCourriels {
  /// Cree l'implementation.
  const CourrielsIndisponibles();

  static const CapaciteIndisponible _absente = CapaciteIndisponible(
    'COURRIELS-1',
  );

  @override
  Future<String> envoyer({
    required String categorie,
    required String sujet,
    required String corps,
    required String cle,
    String? adresse,
    String? profil,
  }) => Future<String>.error(_absente);

  @override
  Future<List<CourrielSortant>> lister({
    StatutCourriel? statut,
    int limite = 100,
  }) => Future<List<CourrielSortant>>.error(_absente);

  @override
  Future<void> reessayer(String id) => Future<void>.error(_absente);

  @override
  Future<List<CategorieCourriel>> categories() =>
      Future<List<CategorieCourriel>>.error(_absente);
}

/// Le port des e-mails sortants.
final Provider<PortCourriels> portCourrielsProvider = Provider<PortCourriels>(
  (Ref ref) => const CourrielsIndisponibles(),
);
