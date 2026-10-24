// Les mots de la file des candidatures (`ADM-20`) : chaque etape, etat, issue,
// versement et salle se dit par son libelle, **jamais par son code**
// (`CATALOGUE_ECRANS_RECRUTEMENT.md` 5.4 et 5.6). Ce fichier ne decide rien : il
// traduit ce que le serveur a rendu en mots et en ton, et ne recalcule ni
// l'etape, ni l'etat, ni un compteur.
library;

import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/nom_latin.dart';
import '../../core/i18n/identifiant_insecable.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/widgets/status_pill.dart';
import '../talents/libelles_talents.dart';

/// Le nom entier de la salle d'une etape, ou `null` avant la Salle d'examen
/// (reçue, invitee) : ces deux etapes n'ont pas de salle, leur etat le dit.
/// Les noms de salle s'ecrivent en entier, jamais sous une forme courte.
String? libelleSalle(EtapeCandidature? etape) => switch (etape) {
  EtapeCandidature.prequalification => t.recrutement.salles.examen,
  EtapeCandidature.verifications => t.recrutement.salles.verification,
  EtapeCandidature.confirmee => t.recrutement.salles.prets,
  EtapeCandidature.recue || EtapeCandidature.invitee || null => null,
};

/// L'etat affiche d'une ligne : un mot et son ton. Le mot porte l'etat, la
/// couleur ne le porte jamais seule.
typedef EtatAffiche = ({String libelle, TonEtat ton});

/// L'etat d'une ligne tel que la direction le lit, ou `null` quand la salle
/// suffit a le dire (une candidature confirmee, en regle).
///
/// L'ordre est celui de la gravite pour la direction : une issue (refusee,
/// retiree) prime sur une pause, une pause sur une restriction, une
/// restriction sur une indisponibilite, puis vient l'etat dans l'etape. Rien
/// n'est deduit d'une autre dimension : chaque drapeau vient du serveur.
EtatAffiche? etatAffiche(LigneCandidature ligne) {
  final r = t.admin.candidatures.etats;
  if (ligne.issue == IssueCandidature.refusee) {
    return (libelle: r.refusee, ton: TonEtat.alerte);
  }
  if (ligne.issue == IssueCandidature.retiree) {
    return (libelle: r.retiree, ton: TonEtat.neutre);
  }
  if (ligne.enPause) {
    return (libelle: r.enPause, ton: TonEtat.neutre);
  }
  if (ligne.restreinte) {
    return (libelle: r.restreinte, ton: TonEtat.alerte);
  }
  if (ligne.indisponible) {
    return (libelle: r.indisponible, ton: TonEtat.avertissement);
  }
  switch (ligne.etape) {
    case EtapeCandidature.recue:
      return (libelle: r.gardee, ton: TonEtat.neutre);
    case EtapeCandidature.invitee:
      return (libelle: r.invitee, ton: TonEtat.neutre);
    case EtapeCandidature.prequalification:
    case EtapeCandidature.verifications:
      return libelleEtatDansEtape(ligne.etat);
    case EtapeCandidature.confirmee:
    case null:
      return null;
  }
}

/// Le mot et le ton d'un etat dans l'etape, ou `null` sans etat.
EtatAffiche? libelleEtatDansEtape(EtatCandidature? etat) {
  final r = t.admin.candidatures.etats;
  return switch (etat) {
    EtatCandidature.aCompleter => (
      libelle: r.aCompleter,
      ton: TonEtat.avertissement,
    ),
    EtatCandidature.enExamen => (libelle: r.enExamen, ton: TonEtat.accent),
    EtatCandidature.paiementNonDisponible => (
      libelle: r.versementImpossible,
      ton: TonEtat.avertissement,
    ),
    EtatCandidature.entretienAPlanifier => (
      libelle: r.entretienAPlanifier,
      ton: TonEtat.avertissement,
    ),
    EtatCandidature.entretienPlanifie => (
      libelle: r.entretienPlanifie,
      ton: TonEtat.accent,
    ),
    EtatCandidature.decisionEnAttente => (
      libelle: r.decisionEnAttente,
      ton: TonEtat.accent,
    ),
    null => null,
  };
}

/// Le mot d'un etat dans l'etape (menu « Etat »).
String libelleEtat(EtatCandidature etat) => libelleEtatDansEtape(etat)!.libelle;

/// Le mot d'une issue (menu « Issue »).
String libelleIssue(IssueCandidature issue) => switch (issue) {
  IssueCandidature.enCours => t.admin.candidatures.filtres.enCours,
  IssueCandidature.refusee => t.admin.candidatures.etats.refusee,
  IssueCandidature.retiree => t.admin.candidatures.etats.retiree,
};

/// Le mot du versement d'une candidature.
String libelleVersement(EtatVersement versement) {
  final v = t.admin.candidatures.etats.versement;
  return switch (versement) {
    EtatVersement.inconnu => v.inconnu,
    EtatVersement.aVerifier => v.aVerifier,
    EtatVersement.compatible => v.compatible,
    EtatVersement.incompatible => v.incompatible,
  };
}

/// Le nom du pays de residence dans la langue de l'interface, ou `null`.
String? libellePays(String? code) => code == null ? null : nomDuPays(code);

/// La reference `CAND-…` telle qu'elle s'affiche : traits d'union insecables,
/// comme les autres identifiants (`UX`, « TEACHER-AS-000001 »). Elle ne se
/// montre qu'a la direction.
String referenceAffichee(LigneCandidature ligne) =>
    identifiantInsecable(ligne.reference);

/// Une date en jour, mois abrege et annee, dans le fuseau de la personne qui
/// lit : « 23 sept. 2026 ». Un instant voyage en UTC et s'affiche en local.
String dateCourteCandidature(DateTime instant) {
  final DateTime local = instant.toLocal();
  // Les trois morceaux de la date arrivent isoles (U+2068 ... U+2069) en
  // arabe ; le texte qui la porte l'isole deja a son tour. Un isolat dans un
  // isolat ne voit aucune lettre forte : il se lisait de gauche a droite
  // (« 2026 أكتوبر 22 »). Sans les isolats internes, la date prend le sens de
  // sa langue (« 22 أكتوبر 2026 »).
  return t.historique
      .dateCourte(
        jour: local.day,
        mois: t.historique.moisCourts[local.month - 1],
        annee: local.year,
      )
      .replaceAll('\u2068', '')
      .replaceAll('\u2069', '');
}

/// Le nom de reference d'une ligne, en lettres latines (decision du directeur
/// du 23/10/2026) : le nom latin confirme ; sinon, quand le nom d'origine n'est
/// pas latin, la proposition de translitteration (marquee « a confirmer », voir
/// [nomAConfirmer]) ; sinon le nom d'origine. Jamais vide : la reference
/// `CAND-...` tient lieu de nom a une ligne sans nom. C'est lui que montrent la
/// liste, le lecteur d'ecran et le tri.
String nomAffiche(LigneCandidature ligne) {
  final String? latin = ligne.nomLatin?.trim();
  if (latin != null && latin.isNotEmpty) {
    return latin;
  }
  final String origine = ligne.nomComplet.trim();
  if (ligne.nomLatinAConfirmer) {
    final String proposition = proposerNomLatin(origine);
    if (proposition.isNotEmpty) {
      return proposition;
    }
  }
  return origine.isEmpty ? ligne.reference : origine;
}

/// Le nom d'origine, a montrer en second quand il differe du nom de reference
/// (en petit sous le nom latin) ; `null` quand il n'y a rien de plus a dire.
String? nomOrigineAffiche(LigneCandidature ligne) {
  final String origine = ligne.nomComplet.trim();
  return origine.isEmpty || origine == nomAffiche(ligne) ? null : origine;
}

/// Vrai quand le nom montre est une proposition que la personne n'a pas
/// confirmee : la liste le marque « a confirmer ».
bool nomAConfirmer(LigneCandidature ligne) => ligne.nomLatinAConfirmer;

/// Les marques d'informations manquantes d'une ligne, en mots.
List<String> marquesDeLigne(LigneCandidature ligne) {
  final l = t.admin.candidatures.ligne;
  return <String>[
    if (ligne.courrielAObtenir) l.courrielAObtenir,
    if (ligne.indicatifAConfirmer) l.indicatifAConfirmer,
  ];
}

/// La ligne de detail d'une pause ou d'une indisponibilite, quand le serveur
/// donne une date, sinon `null`.
String? detailDate(LigneCandidature ligne) {
  final l = t.admin.candidatures.ligne;
  if (ligne.enPause && ligne.repriseLe != null) {
    return l.reprise(date: dateCourteCandidature(ligne.repriseLe!));
  }
  if (ligne.indisponible && ligne.indisponibleJusquAu != null) {
    return l.indisponibleJusquAu(
      date: dateCourteCandidature(ligne.indisponibleJusquAu!),
    );
  }
  return null;
}

/// Le texte d'un instant d'activite, pour la carte et le tableau.
String activiteAffichee(LigneCandidature ligne) =>
    dateCourteCandidature(ligne.derniereActivite);

/// Le rappel des filtres poses, pour « Aucune candidature ne correspond a ces
/// filtres » : la recherche, puis chaque axe, en mots.
String? rappelFiltres(FiltreCandidatures filtre) {
  final r = t.admin.candidatures;
  final List<String> morceaux = <String>[
    if (filtre.rechercheNette.isNotEmpty)
      r.rappel.recherche(texte: filtre.rechercheNette),
    if (filtre.etape != null) ?nomEtapeFiltre(filtre.etape!),
    if (filtre.etat != null) libelleEtat(filtre.etat!),
    if (filtre.issue != null) libelleIssue(filtre.issue!),
    if (filtre.enPause != null)
      filtre.enPause! ? r.etats.enPause : r.filtres.sansPause,
    if (filtre.paiement != null) libelleVersement(filtre.paiement!),
    if (filtre.paysResidence != null) libellePays(filtre.paysResidence)!,
    // Autres competences (CAND-07) : chaque axe pose, en mots.
    if (filtre.competenceDomaine != null)
      nomDomaineFiltre(filtre.competenceDomaine!),
    if (filtre.competenceNiveauMin != null)
      switch (filtre.competenceNiveauMin!) {
        NiveauCompetence.metier => r.filtres.talents.niveauMetier,
        _ => r.filtres.talents.niveauExperience,
      },
    if (filtre.competenceDisponibilite != null)
      libelleDisponibilite(filtre.competenceDisponibilite!),
    if (filtre.competenceAccord != null)
      filtre.competenceAccord!
          ? r.filtres.talents.accordDonne
          : r.filtres.talents.accordAbsent,
  ];
  return morceaux.isEmpty
      ? null
      : r.rappel.filtres(filtres: morceaux.join(' · '));
}

String? nomEtapeFiltre(EtapeCandidature etape) => switch (etape) {
  EtapeCandidature.invitee => t.admin.candidatures.filtres.invitees,
  EtapeCandidature.recue => t.admin.candidatures.filtres.gardees,
  _ => libelleSalle(etape),
};
