// PERSONNES-UNE-PAGE, etape (d) : les 26 filtres de la file des candidatures,
// decrits pour le filtre unique de la page « Personnes » (« Filtrer par », la
// famille, le type, puis la valeur).
//
// Aucun filtre nouveau, aucune regle : ce sont ceux de la feuille « Filtres »
// de l'ancienne liste (`admin_candidatures/feuille_filtres.dart`), avec les
// memes libelles et **les memes cles d'adresse** (`adresse_candidatures.dart`,
// `clesAdresseCandidatures`) : un lien vers l'ancienne liste garde son sens.
// Le serveur filtre (`lister_candidatures`).
library;

import '../../core/agent/travail_praxis.dart';
import '../../core/candidature/modeles_autres_competences.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/i18n/pays_iso.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../admin_candidatures/feuille_filtres.dart';
import '../admin_candidatures/libelles_candidatures.dart';
import '../admin_candidatures/libelles_praxis.dart';
import '../candidature/libelles_parcours.dart';
import '../talents/libelles_talents.dart';
import 'filtres_personnes.dart';

/// Les types de filtre de la vue « Candidats », ranges en familles.
List<TypeFiltrePersonnes> typesFiltreCandidats({
  CatalogueCompetences? catalogue,
  bool garderPourSuivi = false,
}) {
  final f = t.admin.candidatures.filtres;
  final r = t.recrutement.file;
  final p = t.admin.personnesPage;

  const String oui = 'oui';
  const String non = 'non';

  final List<PaysIso> pays = <PaysIso>[...paysIso]
    ..sort(
      (PaysIso a, PaysIso b) =>
          formeDeRecherche(a.nom).compareTo(formeDeRecherche(b.nom)),
    );

  return <TypeFiltrePersonnes>[
    // L'etape et l'etat du dossier.
    TypeFiltrePersonnes(
      famille: p.familleEtape,
      cle: 'etape',
      libelle: r.salle,
      valeurs: <ValeurFiltre>[
        for (final EtapeCandidature e in EtapeCandidature.values)
          if (e != EtapeCandidature.recue || garderPourSuivi)
            (
              code: e.name,
              libelle: switch (e) {
                EtapeCandidature.invitee => f.invitees,
                EtapeCandidature.recue => f.gardees,
                _ => libelleSalle(e) ?? e.name,
              },
            ),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEtape,
      cle: 'etat',
      libelle: f.etat,
      valeurs: <ValeurFiltre>[
        for (final EtatCandidature e in EtatCandidature.values)
          (code: e.name, libelle: libelleEtat(e)),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEtape,
      cle: 'issue',
      libelle: f.issue,
      valeurs: <ValeurFiltre>[
        for (final IssueCandidature i in IssueCandidature.values)
          (code: i.name, libelle: libelleIssue(i)),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEtape,
      cle: 'pause',
      libelle: f.pause,
      valeurs: <ValeurFiltre>[
        (code: oui, libelle: t.admin.candidatures.etats.enPause),
        (code: non, libelle: f.sansPause),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEtape,
      cle: 'complet',
      libelle: f.dossier,
      valeurs: <ValeurFiltre>[
        (code: oui, libelle: f.dossierComplet),
        (code: non, libelle: f.dossierIncomplet),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEtape,
      cle: 'piece',
      libelle: r.piece,
      valeurs: <ValeurFiltre>[
        (code: oui, libelle: t.admin.candidatures.attentes.pieceAValider),
        (code: non, libelle: r.pieceSansAttente),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEtape,
      cle: 'nouveau',
      libelle: p.typeNouveau,
      valeurs: <ValeurFiltre>[
        (code: oui, libelle: r.nouveaux),
        (code: non, libelle: r.pasNouveaux),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEtape,
      cle: 'responsable',
      libelle: r.responsable,
      valeurs: <ValeurFiltre>[
        (code: 'moi', libelle: r.responsableMoi),
        (code: 'aucun', libelle: r.responsableAucun),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEtape,
      cle: 'versement',
      libelle: f.versement,
      valeurs: <ValeurFiltre>[
        for (final EtatVersement v in EtatVersement.values)
          (code: v.name, libelle: libelleVersement(v)),
      ],
    ),
    // La personne.
    TypeFiltrePersonnes(
      famille: p.famillePersonne,
      cle: 'genre',
      libelle: f.genre,
      valeurs: <ValeurFiltre>[
        (code: 'male', libelle: t.admin.candidatures.genres.male),
        (code: 'female', libelle: t.admin.candidatures.genres.female),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.famillePersonne,
      cle: 'pays',
      libelle: f.pays,
      valeurs: <ValeurFiltre>[
        for (final PaysIso x in pays) (code: x.code, libelle: x.nom),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.famillePersonne,
      cle: 'majorite',
      libelle: r.age,
      valeurs: <ValeurFiltre>[
        (code: 'attestee', libelle: r.ageAttestee),
        (code: 'non_attestee', libelle: r.ageNonAttestee),
        (code: 'moins_18', libelle: r.ageMoins18),
      ],
    ),
    // Ce que la personne enseigne.
    TypeFiltrePersonnes(
      famille: p.familleEnseignement,
      cle: 'ijaza',
      libelle: r.ijaza,
      valeurs: <ValeurFiltre>[
        for (final String c in ijazasFiltrables)
          (code: c, libelle: libelleOptionFiltre('ijaza', c)),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEnseignement,
      cle: 'langue',
      libelle: r.langue,
      valeurs: <ValeurFiltre>[
        for (final String c in languesFiltrables)
          (code: c, libelle: nomDeLangue(c) ?? c),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEnseignement,
      cle: 'riwaya',
      libelle: r.riwaya,
      valeurs: <ValeurFiltre>[
        for (final String c in riwayatFiltrables)
          (code: c, libelle: libelleOptionFiltre('riwayat', c)),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleEnseignement,
      cle: 'public',
      libelle: r.public,
      valeurs: <ValeurFiltre>[
        for (final String c in publicsFiltrables)
          (code: c, libelle: libelleOptionFiltre('public', c)),
      ],
    ),
    // Les disponibilites.
    TypeFiltrePersonnes(
      famille: p.familleDisponibilites,
      cle: 'jours',
      libelle: r.jours,
      multiple: true,
      valeurs: <ValeurFiltre>[
        for (int j = 1; j <= 7; j++) (code: '$j', libelle: nomDeJour(j)),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleDisponibilites,
      cle: 'jours_min',
      libelle: r.joursMin,
      valeurs: <ValeurFiltre>[
        for (int n = 1; n <= 7; n++)
          (code: '$n', libelle: LibellesGroupe.insecable(r.joursMinN(n: n))),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleDisponibilites,
      cle: 'heure_de',
      libelle: r.heureDe,
      valeurs: <ValeurFiltre>[
        for (int h = 0; h < 24; h++) (code: '$h', libelle: libelleHeure(h)),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.familleDisponibilites,
      cle: 'heure_a',
      libelle: r.heureA,
      valeurs: <ValeurFiltre>[
        for (int h = 1; h <= 24; h++) (code: '$h', libelle: libelleHeure(h)),
      ],
    ),
    // La lecture de Praxis.
    TypeFiltrePersonnes(
      famille: p.famillePraxis,
      cle: 'pile',
      libelle: f.pilePraxis,
      valeurs: <ValeurFiltre>[
        for (final PilePraxis x in PilePraxis.values)
          (code: x.sql, libelle: libellePile(x)),
      ],
    ),
    TypeFiltrePersonnes(
      famille: p.famillePraxis,
      cle: 'etiquette',
      libelle: f.etiquettePraxis,
      valeurs: <ValeurFiltre>[
        for (final EtiquettePraxis e in EtiquettePraxis.values)
          (code: e.sql, libelle: libelleEtiquette(e)),
      ],
    ),
    // Les autres competences.
    TypeFiltrePersonnes(
      famille: f.talents.domaine,
      cle: 'domaine',
      libelle: p.typeDomaine,
      valeurs: <ValeurFiltre>[
        for (final FamilleCompetence famille in FamilleCompetence.values) ...[
          if (famille != FamilleCompetence.autre)
            (
              code: famille.valeurSql,
              libelle: f.talents.familleToutes(famille: titreFamille(famille)),
            ),
          for (final EntreeCatalogue e
              in catalogue?.competences ?? const <EntreeCatalogue>[])
            if (e.familleCode == famille.valeurSql)
              (
                code: e.code,
                libelle: nomDomaineFiltre(e.code, catalogue: catalogue),
              ),
        ],
      ],
    ),
    TypeFiltrePersonnes(
      famille: f.talents.domaine,
      cle: 'niveau',
      libelle: f.talents.niveau,
      valeurs: <ValeurFiltre>[
        (
          code: NiveauCompetence.experience.name,
          libelle: f.talents.niveauExperience,
        ),
        (code: NiveauCompetence.metier.name, libelle: f.talents.niveauMetier),
      ],
    ),
    TypeFiltrePersonnes(
      famille: f.talents.domaine,
      cle: 'dispo',
      libelle: f.talents.disponibilite,
      valeurs: <ValeurFiltre>[
        for (final DisponibiliteMission d in DisponibiliteMission.values)
          (code: d.name, libelle: libelleDisponibilite(d)),
      ],
    ),
    TypeFiltrePersonnes(
      famille: f.talents.domaine,
      cle: 'accord',
      libelle: f.talents.accord,
      valeurs: <ValeurFiltre>[
        (code: oui, libelle: f.talents.accordDonne),
        (code: non, libelle: f.talents.accordAbsent),
      ],
    ),
  ];
}
