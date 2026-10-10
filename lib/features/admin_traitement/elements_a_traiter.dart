import 'package:flutter/foundation.dart';

import '../../core/capacites/revue_dossiers_depuis_validation.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/service_validation.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/matching/service_matching.dart';

/// La nature d'un element de l'Espace de traitement (`ADM-18`).
///
/// **Deux natures, parce que le serveur en sert deux** : les dossiers
/// d'identite en attente (`dossiers_en_attente()`) et les demandes en attente
/// (`demandes_en_attente()`). Signalements, absences et documents manquants de
/// l'image ADMIN-SHELL-02 n'ont aucune lecture : AD-X-BR-01.
enum NatureElement { dossier, demande }

/// Le tri de la file.
enum TriFile { plusRecent, plusAncien }

/// Le groupe de temps d'une ligne : Aujourd'hui, Hier, Cette semaine, Plus
/// ancien (ADMIN-SHELL-02).
enum GroupeTemps { aujourdhui, hier, semaine, plusAncien }

/// Un element de la file : un dossier ou une demande, avec ce que la ligne et
/// le detail affichent. Aucune donnee de plus que les deux lectures reelles.
@immutable
class ElementATraiter {
  /// Cree un element depuis un dossier d'identite.
  ElementATraiter.depuisDossier(DossierAValider d)
    : id = 'dossier-${d.profilId}',
      nature = NatureElement.dossier,
      nom = d.libelle,
      depuis = d.deposeLe,
      dossier = d,
      demande = null;

  /// Cree un element depuis une demande.
  ElementATraiter.depuisDemande(Demande d)
    : id = 'demande-${d.id}',
      nature = NatureElement.demande,
      nom = d.sujetLibelle,
      depuis = d.creeeLe,
      dossier = null,
      demande = d;

  /// Une cle stable, unique dans la file (nature + identifiant).
  final String id;

  /// Dossier ou demande.
  final NatureElement nature;

  /// Comment nommer la personne concernee.
  final String nom;

  /// Depuis quand l'element attend : depot du dossier, creation de la
  /// demande. C'est la cle du tri et des groupes.
  final DateTime depuis;

  /// Le dossier, pour un element de nature dossier.
  final DossierAValider? dossier;

  /// La demande, pour un element de nature demande.
  final Demande? demande;

  /// La ligne sous le nom : « Dossier d'identite · Enseignant », ou la sorte
  /// de la demande.
  String get precision => switch (nature) {
    NatureElement.dossier => t.admin.traitement.natureDossier,
    NatureElement.demande => switch (demande?.sorte) {
      SorteDemande.reaffectation => t.admin.traitement.natureReaffectation,
      SorteDemande.plafond => t.admin.traitement.naturePlafond,
      SorteDemande.regle => t.admin.traitement.natureRegle,
      null => t.admin.traitement.natureDemande,
    },
  };
}

/// La file reunie : les dossiers (enseignants seulement, K-47, comme la file
/// `ADM-02` qu'ils ouvrent) et les demandes, filtres par [nature] (nul :
/// tout), tries selon [tri].
List<ElementATraiter> reunirFile({
  required List<DossierAValider> dossiers,
  required List<Demande> demandes,
  NatureElement? nature,
  TriFile tri = TriFile.plusRecent,
}) {
  final List<ElementATraiter> tous = <ElementATraiter>[
    if (nature != NatureElement.demande)
      for (final DossierAValider d
          in RevueDossiersDepuisValidation.enseignantsSeulement(dossiers))
        ElementATraiter.depuisDossier(d),
    if (nature != NatureElement.dossier)
      for (final Demande d in demandes) ElementATraiter.depuisDemande(d),
  ];
  tous.sort((ElementATraiter a, ElementATraiter b) {
    final int c = tri == TriFile.plusRecent
        ? b.depuis.compareTo(a.depuis)
        : a.depuis.compareTo(b.depuis);
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  return tous;
}

/// Le groupe de temps de [depuis], par rapport au jour de [maintenant] :
/// meme jour, veille, six jours avant, ou plus ancien.
GroupeTemps groupePour(DateTime depuis, DateTime maintenant) {
  final DateTime jour = DateTime(
    maintenant.year,
    maintenant.month,
    maintenant.day,
  );
  final DateTime jourDepuis = DateTime(depuis.year, depuis.month, depuis.day);
  final int ecart = jour.difference(jourDepuis).inDays;
  if (ecart <= 0) return GroupeTemps.aujourdhui;
  if (ecart == 1) return GroupeTemps.hier;
  if (ecart < 7) return GroupeTemps.semaine;
  return GroupeTemps.plusAncien;
}

/// Le titre d'un groupe de temps.
String titreGroupe(GroupeTemps groupe) => switch (groupe) {
  GroupeTemps.aujourdhui => t.admin.traitement.groupeAujourdhui,
  GroupeTemps.hier => t.admin.traitement.groupeHier,
  GroupeTemps.semaine => t.admin.traitement.groupeSemaine,
  GroupeTemps.plusAncien => t.admin.traitement.groupePlusAncien,
};
