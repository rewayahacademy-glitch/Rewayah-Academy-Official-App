// Coordonnees de versement de l'enseignant et fichier de paie Wise (lot
// FINANCE-ENSEIGNANT, 06/11/2026 ; decision du directeur du 06/11 : paie par
// paiement groupe Wise, un fichier CSV ; migration 20261110700000).
//
// L'enseignant saisit lui-meme ses coordonnees ; il ne relit que les siennes,
// les numeros masques sauf les 4 derniers caracteres (le serveur masque, l'app
// ne voit jamais le reste). Les champs demandes viennent du serveur
// (`champsRequis`, par devise), jamais d'une liste ecrite ici.
//
// La direction exporte le fichier du mois : colonnes et valeurs viennent du
// serveur (montant = du du releve moins ce qui est deja verse) ; l'app ne fait
// que les ecrire en CSV (`fichierCsvWise`). Aucun calcul de montant ici.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../finance/montant.dart';
import 'capacite_indisponible.dart';

/// Un champ de coordonnees, tel que le serveur le nomme. L'ordre d'affichage
/// est celui que rend le serveur.
enum ChampVersement {
  /// Nom du titulaire du compte.
  titulaire('titulaire'),

  /// Numero de compte.
  numeroCompte('numero_compte'),

  /// IBAN.
  iban('iban'),

  /// Code SWIFT (BIC).
  swift('swift'),

  /// Rue, quartier.
  adresseLigne('adresse_ligne'),

  /// Ville.
  adresseVille('adresse_ville'),

  /// Code postal.
  codePostal('code_postal'),

  /// Etat ou province (Etats-Unis, Canada).
  adresseEtat('adresse_etat'),

  /// Pays de l'adresse (ISO 3166-1 alpha-2).
  adressePays('adresse_pays');

  const ChampVersement(this.code);

  /// Le nom du champ cote serveur.
  final String code;

  /// Le champ d'un nom serveur, ou `null` s'il est inconnu.
  static ChampVersement? depuisCode(String code) {
    for (final ChampVersement c in values) {
      if (c.code == code) return c;
    }
    return null;
  }
}

/// Le lien entre l'enseignant et le titulaire d'un compte qui n'est pas a son
/// nom (directeur, 06/11/2026).
enum LienTitulaire {
  /// Le pere ou la mere.
  parent('parent'),

  /// Le conjoint.
  conjoint('conjoint'),

  /// Le frere ou la soeur.
  frereSoeur('frere_soeur'),

  /// Une autre personne.
  autre('autre');

  const LienTitulaire(this.code);

  /// Le nom cote serveur.
  final String code;

  /// Le lien d'un nom serveur, ou `null`.
  static LienTitulaire? depuisCode(String? code) {
    for (final LienTitulaire l in values) {
      if (l.code == code) return l;
    }
    return null;
  }
}

/// Un champ demande par le modele de versement.
@immutable
class ChampDemande {
  /// Cree le champ.
  const ChampDemande(this.champ, {this.obligatoire = true, this.siPays});

  /// Le champ.
  final ChampVersement champ;

  /// Vrai s'il est requis.
  final bool obligatoire;

  /// Les pays d'adresse pour lesquels il est demande (`null` : toujours).
  final List<String>? siPays;

  /// Vrai si le champ est demande pour le pays d'adresse [pays].
  bool demandePour(String? pays) => siPays == null || siPays!.contains(pays);
}

/// Mes coordonnees de versement, telles que le serveur les rend.
@immutable
class MesCoordonneesVersement {
  /// Cree l'etat.
  const MesCoordonneesVersement({
    required this.deviseCible,
    required this.champs,
    required this.enregistre,
    required this.complet,
    this.valide = false,
    this.compteAMonNom = true,
    this.lienTitulaire,
    this.paysProfil,
    this.valeurs = const <ChampVersement, String>{},
    this.modifieLe,
  });

  /// La devise que l'enseignant recoit.
  final String deviseCible;

  /// Les champs que le modele de versement demande pour cette devise, dans
  /// l'ordre de saisie.
  final List<ChampDemande> champs;

  /// Vrai si des coordonnees sont enregistrees.
  final bool enregistre;

  /// Vrai si elles sont completes.
  final bool complet;

  /// Vrai si la direction les a validees : seules les coordonnees validees
  /// entrent dans le fichier Wise.
  final bool valide;

  /// Faux si le compte est au nom d'un tiers.
  final bool compteAMonNom;

  /// Le lien avec le titulaire, pour un compte qui n'est pas a mon nom.
  final LienTitulaire? lienTitulaire;

  /// Le pays du profil de l'enseignant, pour preremplir (K-57).
  final String? paysProfil;

  /// Les valeurs relues, numeros masques par le serveur.
  final Map<ChampVersement, String> valeurs;

  /// La date du dernier enregistrement.
  final DateTime? modifieLe;
}

/// Une ligne du journal de mes coordonnees.
@immutable
class EntreeJournalCoordonnees {
  /// Cree l'entree.
  const EntreeJournalCoordonnees({
    required this.id,
    required this.date,
    required this.retrait,
    this.validee = false,
  });

  /// L'identifiant.
  final String id;

  /// La date.
  final DateTime date;

  /// Vrai pour un retrait, faux pour un enregistrement.
  final bool retrait;

  /// Vrai pour une validation par la direction.
  final bool validee;
}

/// Un enseignant a part dans l'export : coordonnees absentes ou incompletes.
@immutable
class EnseignantSansCoordonnees {
  /// Cree la ligne.
  const EnseignantSansCoordonnees({
    required this.enseignantId,
    required this.nom,
    required this.montant,
    required this.aucune,
    this.matricule,
    this.aValider = false,
  });

  /// L'enseignant.
  final String enseignantId;

  /// Son nom.
  final String nom;

  /// Son matricule.
  final String? matricule;

  /// Ce qui reste a lui verser.
  final Montant montant;

  /// Vrai s'il n'a aucune coordonnee ; faux si elles sont incompletes ou a
  /// valider.
  final bool aucune;

  /// Vrai si ses coordonnees sont completes mais pas encore validees.
  final bool aValider;
}

/// Le fichier de paie Wise d'un mois, rendu par le serveur.
@immutable
class ExportWise {
  /// Cree l'export.
  const ExportWise({
    required this.exportId,
    required this.mois,
    required this.colonnes,
    required this.lignes,
    required this.manquants,
    required this.total,
  });

  /// L'identifiant de l'export journalise.
  final String exportId;

  /// Le mois de paie.
  final DateTime mois;

  /// Les en-tetes, dans l'ordre du modele Wise.
  final List<String> colonnes;

  /// Les lignes, une par enseignant, valeurs deja mises en forme.
  final List<List<String>> lignes;

  /// Les enseignants a part.
  final List<EnseignantSansCoordonnees> manquants;

  /// La somme des lignes du fichier.
  final Montant total;
}

/// Un enseignant vu par la direction : qui il est, si ses coordonnees sont
/// completes et validees, et ce qu'il faut lire pour les valider (le
/// titulaire, le lien, l'accord, le pays, le numero masque ; jamais le numero
/// entier).
@immutable
class EnseignantVersement {
  /// Cree la ligne.
  const EnseignantVersement({
    required this.enseignantId,
    required this.nom,
    required this.complet,
    this.matricule,
    this.valide = false,
    this.coordonneesId,
    this.titulaire,
    this.compteAMonNom = true,
    this.lienTitulaire,
    this.autoriseLe,
    this.pays,
    this.numeroMasque,
    this.enregistreLe,
  });

  /// Vrai si la direction a valide les coordonnees actives.
  final bool valide;

  /// La ligne de coordonnees lue (a rendre a la validation).
  final String? coordonneesId;

  /// Le nom du titulaire du compte.
  final String? titulaire;

  /// Faux si le compte est au nom d'un tiers.
  final bool compteAMonNom;

  /// Le lien avec le titulaire.
  final LienTitulaire? lienTitulaire;

  /// La date de l'accord de l'enseignant (compte d'un tiers).
  final DateTime? autoriseLe;

  /// Le pays de l'adresse.
  final String? pays;

  /// Le numero, masque sauf les 4 derniers caracteres.
  final String? numeroMasque;

  /// La date de l'enregistrement.
  final DateTime? enregistreLe;

  /// Vrai si des coordonnees completes attendent la direction.
  bool get aValider => complet && !valide && coordonneesId != null;

  /// L'enseignant.
  final String enseignantId;

  /// Prenom et nom.
  final String nom;

  /// Son matricule.
  final String? matricule;

  /// Vrai si ses coordonnees sont completes.
  final bool complet;
}

/// Le pays du compte est un pays ou le prestataire ne verse pas (referentiel
/// de paiement, etat `indisponible`) : l'enregistrement est refuse.
class PaysVersementIndisponible implements Exception {
  /// Cree l'exception.
  const PaysVersementIndisponible();
}

/// Le modele Wise n'est pas encore pose par la direction : l'export est
/// impossible tant qu'il manque.
class ModeleWiseAbsent implements Exception {
  /// Cree l'exception.
  const ModeleWiseAbsent();
}

/// Le contenu CSV du fichier : en-tetes puis lignes, separateur virgule, fins
/// de ligne CRLF, UTF-8 (wise.com/help/articles/2942777). Le serveur garantit
/// qu'aucune valeur ne contient de virgule, de guillemet ni de saut de ligne ;
/// une valeur qui en contiendrait serait mise entre guillemets, par prudence.
String fichierCsvWise(ExportWise export) {
  String cellule(String v) =>
      RegExp(r'[,"\r\n]').hasMatch(v) ? '"${v.replaceAll('"', '""')}"' : v;
  final StringBuffer sortie = StringBuffer()
    ..write(export.colonnes.map(cellule).join(','))
    ..write('\r\n');
  for (final List<String> ligne in export.lignes) {
    sortie
      ..write(ligne.map(cellule).join(','))
      ..write('\r\n');
  }
  return sortie.toString();
}

/// Les coordonnees de versement et le fichier Wise.
abstract interface class PortCoordonneesVersement {
  /// Mes coordonnees (l'enseignant connecte).
  Future<MesCoordonneesVersement> mesCoordonnees();

  /// Enregistre mes coordonnees ; les champs hors du modele sont ignores par
  /// le serveur. Un compte au nom d'un tiers exige [lien] et [autorisation].
  Future<MesCoordonneesVersement> enregistrer({
    required String deviseCible,
    required Map<ChampVersement, String> valeurs,
    bool compteAMonNom = true,
    LienTitulaire? lien,
    bool autorisation = false,
  });

  /// Retire mes coordonnees (la ligne reste, inactive).
  Future<MesCoordonneesVersement> retirer();

  /// Le journal de mes changements.
  Future<List<EntreeJournalCoordonnees>> journal();

  /// Le fichier de paie du mois [mois] (direction, comptabilite).
  Future<ExportWise> exporter(DateTime mois);

  /// Les enseignants et l'etat de leurs coordonnees (direction, comptabilite).
  Future<List<EnseignantVersement>> enseignants();

  /// La direction valide les coordonnees [coordonneesId] de [enseignantId],
  /// telles qu'elle les a lues.
  Future<void> valider({
    required String enseignantId,
    required String coordonneesId,
  });
}

/// Aucune source : la migration n'est pas installee.
class CoordonneesVersementIndisponibles implements PortCoordonneesVersement {
  /// Cree l'implementation.
  const CoordonneesVersementIndisponibles();

  static const CapaciteIndisponible _manque = CapaciteIndisponible(
    'VERSEMENT-WISE',
  );

  @override
  Future<MesCoordonneesVersement> mesCoordonnees() =>
      Future<MesCoordonneesVersement>.error(_manque);

  @override
  Future<MesCoordonneesVersement> enregistrer({
    required String deviseCible,
    required Map<ChampVersement, String> valeurs,
    bool compteAMonNom = true,
    LienTitulaire? lien,
    bool autorisation = false,
  }) => Future<MesCoordonneesVersement>.error(_manque);

  @override
  Future<MesCoordonneesVersement> retirer() =>
      Future<MesCoordonneesVersement>.error(_manque);

  @override
  Future<List<EntreeJournalCoordonnees>> journal() =>
      Future<List<EntreeJournalCoordonnees>>.error(_manque);

  @override
  Future<ExportWise> exporter(DateTime mois) =>
      Future<ExportWise>.error(_manque);

  @override
  Future<List<EnseignantVersement>> enseignants() =>
      Future<List<EnseignantVersement>>.error(_manque);

  @override
  Future<void> valider({
    required String enseignantId,
    required String coordonneesId,
  }) => Future<void>.error(_manque);
}

/// Le port ; la production le surcharge dans `main.dart`.
final Provider<PortCoordonneesVersement> portCoordonneesVersementProvider =
    Provider<PortCoordonneesVersement>(
      (Ref _) => const CoordonneesVersementIndisponibles(),
    );
