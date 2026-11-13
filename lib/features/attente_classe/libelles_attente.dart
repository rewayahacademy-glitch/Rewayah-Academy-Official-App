/// SUIVI-ATTENTE : les mots du suivi, en fonctions pures. L'ecran, la carte
/// d'accueil et la version simple de l'eleve disent la meme chose de la meme
/// demande. Aucune fonction ne calcule une etape ni un delai : elles ne font
/// que dire ce que le serveur a rendu (S1, S2).
library;

import '../../core/attente_classe/modele_attente.dart';
import '../../core/i18n/strings.g.dart';
import '../suivi_demandes/libelles_suivi_demandes.dart'
    show deFuseau, hhmmDemande, jourDateDemande, libelleJalon;

/// La date glissee dans une phrase s'ecrit en minuscule : « depuis le lundi 9
/// novembre », « le lundi 16 novembre a 18:00 ». Sans effet en arabe.
String enMinuscule(String texte) =>
    texte.isEmpty ? texte : texte[0].toLowerCase() + texte.substring(1);

/// L'enfant de 6 a 9 ans, dans son espace : tutoiement, **ni date ni duree**
/// (S6, arbitrage du 13/11/2026).
bool estSimple(SuiviAttente s) => s.audience == AudienceAttente.petit;

/// Un mineur dans son espace (6 a 9 ans ou 10 a 17 ans) : tutoiement, jamais
/// les mots des adultes ni ceux du tuteur.
bool estTu(SuiviAttente s) => s.audience != AudienceAttente.adulte;

/// Le nom de l'etape [numero] (S1).
String nomEtape(int numero) => switch (numero) {
  1 => t.suiviAttente.etapes.recue,
  2 => t.suiviAttente.etapes.formation,
  3 => t.suiviAttente.etapes.confirmee,
  4 => t.suiviAttente.etapes.enseignant,
  5 => t.suiviAttente.etapes.pret,
  _ => '',
};

/// L'etat d'une etape, en un mot.
String libelleEtatEtape(EtatEtapeAttente etat) => switch (etat) {
  EtatEtapeAttente.fait => t.suiviAttente.etats.fait,
  EtatEtapeAttente.enCours => t.suiviAttente.etats.enCours,
  EtatEtapeAttente.aVenir => t.suiviAttente.etats.aVenir,
};

/// « Lundi 16 novembre a 18:00, heure de Paris », ou `null` sans date.
String? quandCours(SuiviAttente s, DateTime? quand) {
  if (quand == null || quand.isUtc) return null;
  return t.suiviDemandes.debutValeur(
    date: jourDateDemande(quand),
    heure: hhmmDemande(quand.hour, quand.minute),
    deVille: deFuseau(s.fuseauIana, cle: 'suiviDemandes.debutValeur'),
  );
}

/// « Votre premier cours : lundi 16 novembre a 18:00, heure de Paris », ou
/// `null` quand le serveur ne connait pas la date. Passe : « a eu lieu le... ».
String? phrasePremierCours(SuiviAttente s) {
  final String? date = quandCours(s, s.premierCours);
  if (date == null) return null;
  // L'enfant de 6 a 9 ans ne lit ni date ni heure : son tuteur les lit.
  if (estSimple(s)) {
    return s.premierCoursPasse
        ? t.suiviAttente.tu.premierCoursPassePetit
        : t.suiviAttente.tu.premierCoursPetit;
  }
  final String quand = enMinuscule(date);
  if (s.premierCoursPasse) {
    return estTu(s)
        ? t.suiviAttente.tu.premierCoursPasse(quand: quand)
        : t.suiviAttente.premierCoursPasse(quand: quand);
  }
  return estTu(s)
      ? t.suiviAttente.premierCoursSimple(quand: quand)
      : t.suiviAttente.premierCours(quand: quand);
}

/// Ce que dit l'etape [e] : ce qui s'est passe, ou ce qui se passe, ou ce qui
/// viendra, et qui agit. Les etapes a venir d'une demande close ne disent rien.
String? phraseEtape(SuiviAttente s, EtapeAttente e) {
  final bool tu = estTu(s);
  final f = t.suiviAttente.dit;
  final u = t.suiviAttente.tu;
  switch (e.numero) {
    case 1:
      return tu ? f.recueFaitSimple : f.recueFait;
    case 2:
      return switch (e.etat) {
        EtatEtapeAttente.fait => f.formationFait,
        EtatEtapeAttente.enCours =>
          s.cas == CasAttente.listeAttente
              ? (tu ? u.formationListeAttente : f.formationListeAttente)
              : f.formationEnCours,
        EtatEtapeAttente.aVenir => s.close ? null : f.formationAVenir,
      };
    case 3:
      return switch (e.etat) {
        EtatEtapeAttente.fait =>
          s.classe == null
              ? (tu ? u.confirmeeFait : f.confirmeeFait)
              : (tu
                    ? u.confirmeeFaitNom(classe: s.classe!)
                    : f.confirmeeFaitNom(classe: s.classe!)),
        _ => s.close ? null : f.confirmeeAVenir,
      };
    case 4:
      return switch (e.etat) {
        EtatEtapeAttente.fait => tu ? f.enseignantFaitSimple : f.enseignantFait,
        EtatEtapeAttente.enCours =>
          s.cas == CasAttente.enAttenteEnseignant
              ? (tu ? u.enseignantEnAttente : f.enseignantEnAttente)
              : f.enseignantEnCours,
        EtatEtapeAttente.aVenir => s.close ? null : f.enseignantAVenir,
      };
    case 5:
      return switch (e.etat) {
        EtatEtapeAttente.fait => f.pretFait,
        EtatEtapeAttente.enCours => tu ? u.pretEnCours : f.pretEnCours,
        EtatEtapeAttente.aVenir =>
          s.close ? null : (tu ? u.pretAVenir : f.pretAVenir),
      };
  }
  return null;
}

/// La date d'une etape franchie : « Jeudi 2 octobre a 10:00 ». Pour l'etape 2,
/// qui n'a pas de date propre, rien (le serveur n'en connait pas).
String? dateEtape(SuiviAttente s, EtapeAttente e) =>
    !estSimple(s) && e.etat == EtatEtapeAttente.fait
    ? libelleJalon(e.quand)
    : null;

/// « Depuis le jeudi 2 octobre » pour l'etape en cours, quand l'etape
/// precedente a une date.
String? depuisEtape(SuiviAttente s, EtapeAttente e) {
  if (estSimple(s) || e.etat != EtatEtapeAttente.enCours || e.numero < 2) {
    return null;
  }
  final DateTime? depuis = s.etape(e.numero == 2 ? 1 : e.numero - 1).quand;
  if (depuis == null || depuis.isUtc) return null;
  return t.suiviAttente.depuis(date: enMinuscule(jourDateDemande(depuis)));
}

/// La phrase du delai de formation, **seulement quand il est depasse** : une
/// phrase vraie (« La formation de votre classe prend plus de temps que
/// prevu. L'academie vous ecrit. »). Aucune duree annoncee, aucune date limite,
/// aucun point d'etape : rien ne les tient encore (arbitrage du 13/11/2026).
/// L'enfant de 6 a 9 ans ne lit rien de tel. Vide sinon.
List<String> phrasesDelai(SuiviAttente s) {
  final DelaiFormation? d = s.delai;
  if (d == null || estSimple(s) || !d.depasse) return const <String>[];
  return <String>[
    estTu(s) ? t.suiviAttente.tu.depasse : t.suiviAttente.delai.depasse,
  ];
}

/// Le titre d'une demande close.
String titreCloture(SuiviAttente s) => switch (s.cas) {
  CasAttente.refusee =>
    estTu(s)
        ? t.suiviAttente.tu.titreRefusee
        : t.suiviAttente.cloture.titreRefusee,
  CasAttente.retiree => t.suiviAttente.cloture.titreRetiree,
  _ => t.suiviAttente.cloture.titreClose,
};

/// Le motif d'une demande close, en clair (texte de l'application, jamais un
/// texte libre du serveur).
String motifCloture(SuiviAttente s) {
  if (estSimple(s)) {
    return switch (s.cas) {
      CasAttente.refusee => t.suiviAttente.cloture.simple.refusee,
      CasAttente.retiree => t.suiviAttente.cloture.simple.retiree,
      _ => t.suiviAttente.cloture.simple.close,
    };
  }
  return switch (s.motif) {
    MotifCloture.retraitFamille =>
      estTu(s)
          ? t.suiviAttente.tu.retraitFamille
          : t.suiviAttente.cloture.motif.retraitFamille,
    MotifCloture.offreRetiree => t.suiviAttente.cloture.motif.offreRetiree,
    MotifCloture.classeNonConstituee =>
      t.suiviAttente.cloture.motif.classeNonConstituee,
    MotifCloture.refusDirection => t.suiviAttente.cloture.motif.refusDirection,
    MotifCloture.dejaEnClasse => t.suiviAttente.cloture.motif.dejaEnClasse,
    MotifCloture.inconnu || null => t.suiviAttente.cloture.motif.inconnu,
  };
}

/// L'etape a mettre en avant sur la carte d'accueil : la courante, sinon la
/// derniere franchie.
EtapeAttente etapeResumee(SuiviAttente s) {
  final EtapeAttente? c = s.courante;
  if (c != null) return c;
  EtapeAttente derniere = s.etape(1);
  for (final EtapeAttente e in s.etapes) {
    if (e.etat == EtatEtapeAttente.fait) derniere = e;
  }
  return derniere;
}

/// La ligne de la carte d'accueil : « Yusuf : etape 3 sur 5, Classe
/// confirmee ». Tout est pret : « Yusuf : tout est pret. Premier cours : ... ».
String ligneCarte(SuiviAttente s) {
  if (s.toutEstPret) {
    final String? quand = quandCours(s, s.premierCours);
    if (quand != null && !s.premierCoursPasse && estSimple(s)) {
      return t.suiviAttente.carte.pretSansDate(prenom: s.prenom);
    }
    if (quand != null && !s.premierCoursPasse) {
      return t.suiviAttente.carte.pret(
        prenom: s.prenom,
        quand: enMinuscule(quand),
      );
    }
  }
  if (s.close) return '${s.prenom} : ${titreCloture(s)}';
  final EtapeAttente e = etapeResumee(s);
  return t.suiviAttente.carte.ligne(
    prenom: s.prenom,
    n: e.numero,
    total: nombreEtapesAttente,
    etape: nomEtape(e.numero),
  );
}

/// Le titre de l'enseignant, ou rien.
String? titreEnseignant(CarteEnseignantAttente e) => switch (e.titre) {
  'sayyid' => t.suiviAttente.enseignant.sayyid,
  'sayyida' => t.suiviAttente.enseignant.sayyida,
  _ => null,
};

/// Le nom de l'enseignant : « Sayyid Ibrahim » (civilite et prenom, jamais le
/// nom de famille).
String nomEnseignant(CarteEnseignantAttente e) {
  final String? titre = titreEnseignant(e);
  return titre == null
      ? t.suiviAttente.enseignant.nomPlein(prenom: e.prenom)
      : t.suiviAttente.enseignant.nomAvecTitre(titre: titre, prenom: e.prenom);
}

/// « jeudi 2 octobre » : le jour d'une heure murale du foyer, dans une phrase.
String jourDateCourt(DateTime quand) => enMinuscule(jourDateDemande(quand));
