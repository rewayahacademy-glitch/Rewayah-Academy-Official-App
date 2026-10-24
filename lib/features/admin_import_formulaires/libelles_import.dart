// Les mots de l'import des formulaires (`ADM-23`) : chaque code que le serveur
// rend (champ, issue, motif, avertissement, nature de cle) devient une phrase
// de `admin.importFormulaires.*`, en francais et en arabe. **Aucun code n'est
// jamais affiche** (`CATALOGUE_ECRANS_RECRUTEMENT.md`, 5.4) : un code que ce
// client ne connait pas devient « un point est a verifier dans cette ligne ».
library;

import '../../core/candidature/modeles_import_candidatures.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/status_pill.dart';
import 'controleur_import.dart';

/// Le libelle d'un pas.
String libellePas(PasImport pas) {
  final p = t.admin.importFormulaires.pas;
  return switch (pas) {
    PasImport.depot => p.depot,
    PasImport.apercu => p.apercu,
    PasImport.colonnes => p.colonnes,
    PasImport.doublons => p.doublons,
    PasImport.erreurs => p.controle,
    PasImport.comptes => p.comptes,
    PasImport.confirmation => p.confirmation,
    PasImport.rapport => p.rapport,
  };
}

/// Le nom d'un champ du formulaire.
String libelleChamp(ChampFormulaire champ) {
  final c = t.admin.importFormulaires.champ;
  return switch (champ) {
    ChampFormulaire.horodatage => c.horodatage,
    ChampFormulaire.genre => c.genre,
    ChampFormulaire.nom => c.nom,
    ChampFormulaire.telephone => c.telephone,
    ChampFormulaire.langueMaternelle => c.langueMaternelle,
    ChampFormulaire.languesExplication => c.languesExplication,
    ChampFormulaire.memorisation => c.memorisation,
    ChampFormulaire.ijaza => c.ijaza,
    ChampFormulaire.experience => c.experience,
    ChampFormulaire.creneaux => c.creneaux,
    ChampFormulaire.heures => c.heures,
    ChampFormulaire.debut => c.debut,
    ChampFormulaire.whatsapp => c.whatsapp,
    ChampFormulaire.courriel => c.courriel,
  };
}

/// Ce que sert un champ : une phrase.
String aideChamp(ChampFormulaire champ) {
  final c = t.admin.importFormulaires.champ;
  return switch (champ) {
    ChampFormulaire.horodatage => c.horodatageAide,
    ChampFormulaire.genre => c.genreAide,
    ChampFormulaire.nom => c.nomAide,
    ChampFormulaire.telephone => c.telephoneAide,
    ChampFormulaire.langueMaternelle => c.langueMaternelleAide,
    ChampFormulaire.languesExplication => c.languesExplicationAide,
    ChampFormulaire.memorisation => c.memorisationAide,
    ChampFormulaire.ijaza => c.ijazaAide,
    ChampFormulaire.experience => c.experienceAide,
    ChampFormulaire.creneaux => c.creneauxAide,
    ChampFormulaire.heures => c.heuresAide,
    ChampFormulaire.debut => c.debutAide,
    ChampFormulaire.whatsapp => c.whatsappAide,
    ChampFormulaire.courriel => c.courrielAide,
  };
}

/// Le nom d'un champ que le serveur dit manquant.
String libelleManquant(ChampManquant champ) => switch (champ) {
  ChampManquant.horodatage => libelleChamp(ChampFormulaire.horodatage),
  ChampManquant.genre => libelleChamp(ChampFormulaire.genre),
  ChampManquant.nom => libelleChamp(ChampFormulaire.nom),
  ChampManquant.contact => t.admin.importFormulaires.champ.contact,
};

/// Une liste de noms, separes par une virgule.
String listeDe(Iterable<String> noms) => noms.join(', ');

/// Ce que la direction lit d'une reference source (`classeur|onglet|horodatage`) :
/// la date de la reponse telle qu'elle est ecrite dans le fichier. La barre
/// verticale et les noms du classeur n'ont rien a faire a l'ecran ; la direction
/// connait le classeur qu'elle vient de deposer.
String horodatageDeReference(String reference) {
  final int i = reference.lastIndexOf('|');
  final String h = i < 0 ? reference : reference.substring(i + 1);
  return h.trim();
}

/// Le libelle de l'issue d'une ligne.
String libelleIssue(IssueLigne issue) {
  final i = t.admin.importFormulaires.issue;
  return switch (issue) {
    IssueLigne.nouvelle => i.nouvelle,
    IssueLigne.corrigee => i.corrigee,
    IssueLigne.dejaConnue => i.dejaConnue,
    IssueLigne.ignoree => i.ignoree,
    IssueLigne.aCorriger => i.aCorriger,
  };
}

/// Le ton de la pastille d'une issue : jamais la couleur seule, le mot est
/// toujours la.
TonEtat tonIssue(IssueLigne issue) => switch (issue) {
  IssueLigne.nouvelle => TonEtat.succes,
  IssueLigne.corrigee => TonEtat.accent,
  IssueLigne.dejaConnue => TonEtat.neutre,
  IssueLigne.ignoree => TonEtat.neutre,
  IssueLigne.aCorriger => TonEtat.avertissement,
};

/// La nature de la cle d'un groupe de doublons.
String libelleNature(NatureCle nature) {
  final n = t.admin.importFormulaires.doublons.nature;
  return switch (nature) {
    NatureCle.courriel => n.courriel,
    NatureCle.telephone => n.telephone,
    NatureCle.courrielEtTelephone => n.courrielEtTelephone,
  };
}

/// La phrase d'un motif ou d'un avertissement du serveur.
String texteRemarque(String code) {
  final m = t.admin.importFormulaires.motif;
  final a = t.admin.importFormulaires.avertissement;
  if (code.startsWith('libelle_inconnu_') && code != 'libelle_inconnu_heures') {
    return a.libelleInconnu;
  }
  return switch (code) {
    'ligne_vide' => m.ligneVide,
    'horodatage_illisible' => m.horodatageIllisible,
    'genre_illisible' => m.genreIllisible,
    'nom_absent' => m.nomAbsent,
    'nom_trop_long' => m.nomTropLong,
    'meme_reference_meme_contenu' => m.memeReferenceMemeContenu,
    'meme_reference_contenu_different' => m.memeReferenceContenuDifferent,
    'genre_change_sur_ligne_suivie' => m.genreChangeSurLigneSuivie,
    'inscription_12_10' => m.inscription1210,
    'telephone_illisible' => a.telephoneIllisible,
    'format_national' => a.formatNational,
    'indicatif_inconnu' => a.indicatifInconnu,
    'longueur_implausible' => a.longueurImplausible,
    'indicatif_a_confirmer' => a.indicatifAConfirmer,
    'zero_national_en_trop' => a.zeroNationalEnTrop,
    'courriel_malforme' => a.courrielMalforme,
    'langue_maternelle_vers_autre' => a.langueMaternelleVersAutre,
    'langue_inconnue_vers_autre' => a.langueInconnueVersAutre,
    'arabe_retire' => a.arabeRetire,
    'libelle_inconnu_heures' => a.libelleInconnu,
    'ijaza_declaree_en_g' => a.ijazaDeclareeEnG,
    'experience_pret_test_sans_equivalent' => a.experiencePretTest,
    'moins_de_3_heures' => a.moinsDe3Heures,
    'creneaux_contradictoires' => a.creneauxContradictoires,
    _ => m.inconnu,
  };
}

/// Les remarques d'une ligne (motifs, puis avertissements), sans doublon.
String remarquesDeLigne(List<String> motifs, List<String> avertissements) =>
    <String>{
      for (final String c in <String>[...motifs, ...avertissements])
        texteRemarque(c),
    }.join(' ; ');

/// La cause d'un fichier illisible.
String texteCause(CauseFichier cause) {
  final c = t.admin.importFormulaires.fichier.cause;
  return switch (cause) {
    CauseFichier.guillemetNonFerme => c.guillemetNonFerme,
    CauseFichier.tropVolumineux => c.tropVolumineux,
    CauseFichier.malForme => c.malForme,
    CauseFichier.inconnue => c.inconnue,
  };
}

/// La phrase d'un fichier illisible : la ligne quand le client la connait, et
/// toujours quoi faire (K-59).
String texteFichierIllisible(ProblemeFichier probleme) {
  final f = t.admin.importFormulaires.fichier;
  final String cause = texteCause(probleme.cause);
  final String constat = probleme.ligne == null
      ? f.illisible(cause: cause)
      : f.illisibleLigne(ligne: probleme.ligne!, cause: cause);
  return '$constat ${f.quoiFaire}';
}
