import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/group_summary_vm.dart' show TitreEnseignant;
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/widgets/status_pill.dart';
import 'domaine/classe_vm.dart';
import 'domaine/conformite.dart';

/// Les libelles et la mise en forme du domaine Classe.
///
/// **Un seul endroit decide de chaque phrase.** L'administration, l'enseignant
/// et la famille lisent la meme carte : deux formulations du meme creneau
/// feraient douter de laquelle croire. Ce module ne convertit **aucun** fuseau
/// et ne calcule **aucune** duree academique : il compose des mots a partir de
/// valeurs deja rendues.
abstract final class LibellesClasses {
  /// Le nom du jour, en toutes lettres.
  static String jour(int jourIso) =>
      t.disponibilites.joursLongs[(jourIso - 1).clamp(0, 6)];

  /// L'heure d'un creneau, sur deux chiffres.
  static String heure(CreneauClasse creneau) =>
      '${creneau.heure.toString().padLeft(2, '0')}:'
      '${creneau.minute.toString().padLeft(2, '0')}';

  /// Le nom lisible d'un fuseau IANA : « Paris », « Conakry ». **Jamais un
  /// decalage numerique.**
  static String ville(String fuseauIana) {
    final List<String> segments = fuseauIana.split('/');
    return segments.last.replaceAll('_', ' ');
  }

  /// Le creneau, en clair. Le fuseau ne se dit que lorsqu'il differe de
  /// celui de la personne qui regarde : une information de plus quand elle ne
  /// change rien est du bruit.
  static String creneau(CreneauClasse creneau, {String? fuseauUtilisateur}) {
    final String j = jour(creneau.jourIso);
    final String h = heure(creneau);
    if (fuseauUtilisateur != null && fuseauUtilisateur != creneau.fuseauIana) {
      return t.classes.carte.creneauAvecVille(
        jour: j,
        heure: h,
        ville: creneau.libelleVille ?? ville(creneau.fuseauIana),
      );
    }
    return t.classes.carte.creneau(jour: j, heure: h);
  }

  /// Une duree prevue, en clair : « 1 h 30 » ou « 45 min ».
  static String duree(Duration duree) => LibellesGroupe.dureeLisible(duree);

  /// Le public, en clair.
  static String publicClasse(PublicClasse publicClasse) =>
      switch (publicClasse) {
        PublicClasse.enfants => t.classes.commun.publicEnfants,
        PublicClasse.adultes => t.classes.commun.publicAdultes,
      };

  /// La capacite reelle, toujours lue de la donnee serveur.
  static String capacite({required int inscrits, required int seuil}) =>
      t.classes.carte.capacite(inscrits: inscrits, seuil: seuil);

  /// La capacite, en toutes lettres pour les technologies d'assistance.
  static String capacitePhrase({required int inscrits, required int seuil}) =>
      t.classes.carte.capacitePhrase(inscrits: inscrits, seuil: seuil);

  /// Le mot d'un etat de publication.
  static String etat(EtatPublication etat) => switch (etat) {
    EtatPublication.brouillon => t.classes.carte.brouillon,
    EtatPublication.publiee => t.classes.carte.publiee,
    EtatPublication.cloturee => t.classes.carte.cloturee,
  };

  /// La famille semantique d'un etat de publication.
  static TonEtat tonEtat(EtatPublication etat) => switch (etat) {
    EtatPublication.brouillon => TonEtat.neutre,
    EtatPublication.publiee => TonEtat.succes,
    EtatPublication.cloturee => TonEtat.neutre,
  };

  /// L'enseignant, precede de son titre quand la base le porte.
  ///
  /// **Sayyid / Sayyida, jamais Ustaz** (decision D-02). Sans titre connu, le
  /// nom seul : on ne fabrique pas un titre.
  static String enseignantNomme(EnseignantClasse enseignant) {
    final String? titre = switch (enseignant.titre) {
      TitreEnseignant.sayyid => LibellesGroupe.sayyid,
      TitreEnseignant.sayyida => LibellesGroupe.sayyida,
      null => null,
    };
    return titre == null
        ? enseignant.nomAffichage
        : '$titre ${enseignant.nomAffichage}';
  }

  /// Le mot d'un etat KYC.
  static String etatKyc(EtatKyc etat) => switch (etat) {
    EtatKyc.nonCommence => t.classes.conformite.etatNonCommence,
    EtatKyc.soumis => t.classes.conformite.etatSoumis,
    EtatKyc.verifie => t.classes.conformite.etatVerifie,
    EtatKyc.correctionDemandee => t.classes.conformite.etatCorrection,
    EtatKyc.refuse => t.classes.conformite.etatRefuse,
    EtatKyc.dispense => t.classes.conformite.etatDispense,
  };

  /// Le ton d'un etat KYC : l'inconnu et le refus se voient, le reste se lit.
  static TonEtat tonEtatKyc(EtatKyc etat) => switch (etat) {
    EtatKyc.verifie || EtatKyc.dispense => TonEtat.succes,
    EtatKyc.soumis => TonEtat.accent,
    EtatKyc.nonCommence || EtatKyc.correctionDemandee => TonEtat.avertissement,
    EtatKyc.refuse => TonEtat.alerte,
  };

  /// Le mot d'une exigence KYC.
  static String exigenceKyc(ExigenceKyc exigence) => switch (exigence) {
    ExigenceKyc.requise => t.classes.conformite.exigenceRequise,
    ExigenceKyc.optionnelle => t.classes.conformite.exigenceOptionnelle,
    ExigenceKyc.dispensee => t.classes.conformite.exigenceDispensee,
  };

  /// Le programme, le niveau et le public sur une ligne, en sautant ce qui
  /// manque sans laisser de separateur orphelin.
  static String ligneProgramme(ClasseVM classe) => <String>[
    if (classe.programme case final String p when p.trim().isNotEmpty) p,
    if (classe.niveauHumain case final String n when n.trim().isNotEmpty) n,
    publicClasse(classe.publicClasse),
  ].join(LibellesGroupe.separateur);
}
