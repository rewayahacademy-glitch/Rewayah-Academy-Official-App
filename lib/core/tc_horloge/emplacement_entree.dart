import 'package:flutter/foundation.dart';

import '../i18n/elision.dart';
import '../i18n/isolat_bidi.dart';
import '../i18n/strings.g.dart';
import '../tc_groupe/libelles_tc_groupe.dart';
import 'session_clock_vm.dart';

/// Qui regarde l'emplacement d'entree (CL-4.2).
enum RoleEntree {
  /// Eleve en interface standard.
  eleve,

  /// Eleve en Interface guidee.
  eleveGuide,

  /// Enseignant : « Rejoindre la salle » (CTA-FIN-1), par la preparation.
  enseignant,
}

/// Les etats de l'emplacement d'entree unique (regle R4).
enum EtatEntree {
  /// Avant l'ouverture de la fenetre : « Cours dans ... ».
  aVenir,

  /// Fenetre ouverte : « Rejoindre » ou « Preparer l'entree ».
  fenetreOuverte,

  /// La preparation (pre-vol) est en cours pour cette seance.
  preparation,

  /// Deja dans la salle avant T0 : aucun temps academique consomme.
  attente,

  /// De T0 a la fermeture, prolongation comprise.
  enDirect,

  /// Seance close.
  terminee,

  /// Seance annulee.
  annulee,

  /// Aucune occurrence connue.
  aucune,

  /// Hors ligne, ou information de seance illisible.
  indisponible,
}

/// Bouton ou ligne d'etat : jamais un bouton grise (R4, revue UX n° 1).
enum FormeEntree {
  /// Un bouton principal (hauteur 52 reservee dans tous les etats).
  bouton,

  /// Une ligne d'etat : texte et icone, ni focalisable, ni « desactive ».
  ligne,
}

/// Ce que montre l'emplacement d'entree pour un role, a un instant.
///
/// **Modele pur, sans widget.** Le temps vient exclusivement de
/// [SessionClockVM] (R5) : aucune duree en dur, aucun minuteur, aucun
/// `DateTime.now()`. Un saut d'horloge se traite en recalculant avec le nouvel
/// instant ; il n'y a aucun compteur a reprendre.
@immutable
class EmplacementEntree {
  /// Cree un emplacement deja resolu. Preferer [EmplacementEntree.pour].
  const EmplacementEntree({
    required this.role,
    required this.etat,
    required this.forme,
    required this.libelle,
    required this.annonce,
    this.libelleLecteur,
    this.detail,
    this.avisDst,
    this.reessayer = false,
  });

  /// Resout l'emplacement depuis l'horloge de seance (source unique du temps).
  ///
  /// [horloge] `null` : aucune occurrence connue. [horsLigne] et
  /// [lectureEchouee] priment sur le temps : sans information fiable, on ne
  /// propose pas d'entrer. [annulee] vient du serveur. [preparationEnCours]
  /// est vrai pendant le pre-vol de cette seance. [accesInverifiable] est
  /// vrai quand la fenetre est ouverte mais qu'aucune seance n'est
  /// materialisee (aucun `sessionId`) : on ne peut pas y entrer.
  /// [tutoiement] est vrai pour l'eleve mineur en Mode Accessibilite (MA4) :
  /// les phrases qui s'adressent a lui le tutoient ; un adulte est vouvoye.
  factory EmplacementEntree.pour({
    required RoleEntree role,
    required SessionClockVM? horloge,
    required String nomClasse,
    bool annulee = false,
    bool horsLigne = false,
    bool lectureEchouee = false,
    bool preparationEnCours = false,
    bool accesInverifiable = false,
    bool tutoiement = false,
  }) {
    final String? dst = _avisDst(horloge?.noticeDst);
    if (horsLigne || lectureEchouee) {
      final String texte = horsLigne
          ? (tutoiement
                ? t.accessibilite.tutoiement.horsLigne
                : t.classe.entree.horsLigne)
          : t.classe.entree.indisponible;
      return EmplacementEntree(
        role: role,
        etat: EtatEntree.indisponible,
        forme: FormeEntree.ligne,
        libelle: texte,
        annonce: texte,
        reessayer: true,
        avisDst: dst,
      );
    }
    if (annulee) {
      return _ligne(role, EtatEntree.annulee, t.classe.entree.annulee, dst);
    }
    if (horloge == null) {
      return _ligne(role, EtatEntree.aucune, t.classe.entree.aucune, null);
    }
    final Duration reste = _positif(horloge.restant);
    final bool imminent = reste.inMinutes <= 0;
    final String duree = LibellesGroupe.dureeLisible(reste);
    switch (horloge.phase) {
      case PhaseSeance.avantFenetre:
        return EmplacementEntree(
          role: role,
          etat: EtatEntree.aVenir,
          forme: FormeEntree.ligne,
          libelle: imminent
              ? t.classe.entree.coursImminent
              : role == RoleEntree.enseignant
              ? _dansEnseignant(reste, horloge.debutUtc.toLocal())
              // RTL-ISOL-1 : « الدرس بعد 3 h 28 », jamais « h 28 3 ».
              : phraseAvecValeur(
                  (String d) => t.classe.entree.coursDans(duree: d),
                  duree,
                ),
          annonce: t.classe.entree.annonce.aVenir,
          avisDst: dst,
        );
      case PhaseSeance.terminee:
        return _ligne(role, EtatEntree.terminee, t.classe.entree.terminee, dst);
      case PhaseSeance.salleOuverte ||
          PhaseSeance.attenteAvantT0 ||
          PhaseSeance.enCours ||
          PhaseSeance.prolongee:
        break;
    }
    if (preparationEnCours) {
      return _ligne(
        role,
        EtatEntree.preparation,
        t.classe.entree.preparation,
        dst,
      );
    }
    // Fenetre ouverte sans seance materialisee : rien ne permet d'entrer. Ni
    // bouton grise, ni bouton muet : la ligne d'etat et « Reessayer » (R4).
    if (accesInverifiable) {
      final String texte = t.classe.entree.accesInverifiable;
      return EmplacementEntree(
        role: role,
        etat: EtatEntree.indisponible,
        forme: FormeEntree.ligne,
        libelle: texte,
        annonce: texte,
        reessayer: true,
        avisDst: dst,
      );
    }
    return switch (horloge.phase) {
      PhaseSeance.attenteAvantT0 => _bouton(
        role,
        EtatEntree.attente,
        nomClasse,
        detail: tutoiement
            ? (imminent
                  ? t.accessibilite.tutoiement.attenteImminent
                  : phraseAvecValeur(
                      (String d) =>
                          t.accessibilite.tutoiement.attente(duree: d),
                      duree,
                    ))
            : imminent
            ? t.classe.entree.attenteImminent
            : phraseAvecValeur(
                (String d) => t.classe.entree.attente(duree: d),
                duree,
              ),
        annonce: tutoiement
            ? t.accessibilite.tutoiement.annonceAttente
            : t.classe.entree.annonce.attente,
        dst: dst,
      ),
      PhaseSeance.enCours => _bouton(
        role,
        EtatEntree.enDirect,
        nomClasse,
        detail: t.classe.entree.enDirect,
        annonce: t.classe.entree.enDirect,
        dst: dst,
      ),
      // R6 : jamais de nombre negatif, « Temps prevu ecoule ».
      PhaseSeance.prolongee => _bouton(
        role,
        EtatEntree.enDirect,
        nomClasse,
        detail: LibellesGroupe.joindre(
          t.classe.entree.enDirect,
          t.classe.entree.tempsEcoule,
        ),
        annonce: t.classe.entree.enDirect,
        dst: dst,
      ),
      _ => _bouton(
        role,
        EtatEntree.fenetreOuverte,
        nomClasse,
        detail: imminent
            ? t.classe.entree.salleOuverteImminent
            : phraseAvecValeur(
                (String d) => t.classe.entree.salleOuverte(duree: d),
                duree,
              ),
        annonce: t.classe.entree.annonce.fenetreOuverte,
        dst: dst,
      ),
    };
  }

  /// Qui regarde.
  final RoleEntree role;

  /// L'etat.
  final EtatEntree etat;

  /// Bouton ou ligne d'etat.
  final FormeEntree forme;

  /// Le texte visible : libelle du bouton, ou texte de la ligne d'etat.
  final String libelle;

  /// Le libelle du bouton pour le lecteur d'ecran, `null` pour une ligne.
  final String? libelleLecteur;

  /// La phrase d'etat qui accompagne le bouton (decompte compris).
  final String? detail;

  /// Le texte annonce (region live polie) **aux seuls changements d'etat** :
  /// jamais de decompte dedans. Voir [annonceDepuis].
  final String annonce;

  /// La notice de changement d'heure, sous les heures, au-dessus de
  /// l'emplacement (revue UX n° 15). `null` sans transition qui deplace
  /// l'heure.
  final String? avisDst;

  /// Vrai quand « Reessayer » occupe l'emplacement (hors ligne, lecture).
  final bool reessayer;

  /// Vrai quand l'emplacement est un bouton.
  bool get estBouton => forme == FormeEntree.bouton;

  /// Le texte a annoncer en passant de [precedent] a cet emplacement, ou
  /// `null` quand l'etat n'a pas change (le decompte seul ne s'annonce pas).
  String? annonceDepuis(EmplacementEntree? precedent) =>
      precedent == null || precedent.etat != etat ? annonce : null;

  static EmplacementEntree _ligne(
    RoleEntree role,
    EtatEntree etat,
    String texte,
    String? dst,
  ) => EmplacementEntree(
    role: role,
    etat: etat,
    forme: FormeEntree.ligne,
    libelle: texte,
    annonce: texte,
    avisDst: dst,
  );

  static EmplacementEntree _bouton(
    RoleEntree role,
    EtatEntree etat,
    String nomClasse, {
    required String detail,
    required String annonce,
    required String? dst,
  }) {
    final bool enseignant = role == RoleEntree.enseignant;
    return EmplacementEntree(
      role: role,
      etat: etat,
      forme: FormeEntree.bouton,
      libelle: enseignant
          ? t.enseignant.journee.rejoindreSalle
          : t.classe.entree.rejoindre,
      libelleLecteur: enseignant
          ? t.enseignant.journee.rejoindreSalleLecteur(classe: nomClasse)
          : t.classe.entree.rejoindreLecteur(
              deClasse: deDevant(
                nomClasse,
                cle: 'classe.entree.rejoindreLecteur',
              ),
            ),
      detail: detail,
      annonce: annonce,
      avisDst: dst,
    );
  }

  static Duration _positif(Duration? d) =>
      d == null || d.isNegative ? Duration.zero : d;

  static String? _avisDst(NoticeDst? notice) =>
      notice == null || !notice.deplaceLHeure
      ? null
      : t.classe.entree.dst(
          avant: notice.heureAvantRendue,
          apres: notice.heureApresRendue,
        );
}

/// La ligne de contexte de l'enseignant, au format d'E11 : « Dans 1 h 24 »
/// (ENSEIGNANT-2026-09-26, E11), et non « Cours dans 1 h 24 ».
///
/// Le formateur unique ([LibellesGroupe.compteAReboursAvec]) avec les mots de
/// l'enseignant : au-dela du jour, « Demain a 19:00 » ou « Dans 4 jours »,
/// jamais « Dans 116 h 52 » (directeur, 30/10/2026). [debut] : l'heure locale
/// du cours.
String _dansEnseignant(Duration reste, DateTime debut) =>
    LibellesGroupe.compteAReboursAvec(
      reste,
      debut: debut,
      textes: (
        imminent: () => t.enseignant.journee.minuteurImminent,
        minutes: (int m) => t.enseignant.journee.minuteurMinutes(minutes: m),
        heures: (int h, String m) =>
            t.enseignant.journee.minuteurHeures(heures: h, minutes: m),
        demain: (String heure) =>
            t.enseignant.journee.minuteurDemain(heure: heure),
        jours: (int j) => t.enseignant.journee.minuteurJours(jours: j),
      ),
    );
