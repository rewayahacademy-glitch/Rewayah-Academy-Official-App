/// SUIVI-FAMILLE (R20) : les mots de la frise des demandes.
///
/// Fonctions pures, partagees par l'ecran, la frise et les notifications.
/// Aucune ne lit un rang ni une identite d'autrui : le contrat n'en porte pas.
library;

import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/port_frise_demande.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart' show LibellesGroupe;
import '../suivi_demandes/libelles_suivi_demandes.dart';

/// Le nom d'une etape : « Classe créée ».
String libelleEtape(TypeEtapeFrise type) => switch (type) {
  TypeEtapeFrise.envoyee => t.suiviFamille.etapes.envoyee,
  TypeEtapeFrise.enAttente => t.suiviFamille.etapes.enAttente,
  TypeEtapeFrise.classeCreee => t.suiviFamille.etapes.classeCreee,
  TypeEtapeFrise.enseignantAffecte => t.suiviFamille.etapes.enseignantAffecte,
  TypeEtapeFrise.eleveIntegre => t.suiviFamille.etapes.eleveIntegre,
  TypeEtapeFrise.premiereSeance => t.suiviFamille.etapes.premiereSeance,
};

/// Le mot de l'etat d'une etape : jamais la couleur seule.
String libelleEtat(EtatEtapeFrise etat) => switch (etat) {
  EtatEtapeFrise.fait => t.suiviFamille.etats.fait,
  EtatEtapeFrise.enCours => t.suiviFamille.etats.enCours,
  EtatEtapeFrise.aVenir => t.suiviFamille.etats.aVenir,
};

/// Le motif d'attente en clair.
String libelleMotifAttente(MotifAttente motif) => switch (motif) {
  MotifAttente.classesPleines => t.suiviFamille.motif.classesPleines,
  MotifAttente.aucunEnseignantLibre =>
    t.suiviFamille.motif.aucunEnseignantLibre,
  MotifAttente.inconnu => t.suiviFamille.motif.inconnu,
};

String _date(DateTime d) => t.commun.dates.jourDate(
  jour: t.commun.dates.jours[d.weekday - 1],
  numero: d.day,
  mois: t.commun.dates.mois[d.month - 1],
);

/// « Lundi 19 octobre à 17:30 » : les champs de l'heure murale du foyer,
/// lus tels quels (jamais convertis par l'appareil).
String horodatage(DateTime d) => t.suiviFamille.horodatage(
  date: _date(d),
  heure: hhmmDemande(d.hour, d.minute),
);

/// « Prévue le lundi 19 octobre à 17:30 » : la premiere seance connue.
String datePrevue(DateTime d) =>
    t.suiviFamille.prevue(date: _date(d), heure: hhmmDemande(d.hour, d.minute));

/// L'intervalle entre deux etapes : « 3 jours plus tard », « 5 heures plus
/// tard ». Negatif (horloges incoherentes) : traite comme nul.
String intervalleEntre(DateTime avant, DateTime apres) {
  final Duration ecart = apres.difference(avant);
  final int heures = ecart.isNegative ? 0 : ecart.inHours;
  if (heures < 1) return t.suiviFamille.intervalle.moinsHeure;
  if (heures < 24) {
    return LibellesGroupe.insecable(
      t.suiviFamille.intervalle.heures(n: heures),
    );
  }
  return LibellesGroupe.insecable(
    t.suiviFamille.intervalle.jours(n: ecart.inDays),
  );
}

/// Le titre de la notification d'un passage d'etape. Les trois premieres
/// etapes gardent les titres du suivi existant.
String titreNotificationFrise(TypeEtapeFrise type, String prenom) {
  return switch (type) {
    TypeEtapeFrise.envoyee => t.suiviDemandes.notification.envoyee(
      dePrenom: deDevant(prenom, cle: 'suiviDemandes.notification.envoyee'),
    ),
    TypeEtapeFrise.classeCreee => t.suiviDemandes.notification.classeValidee(
      dePrenom: deDevant(
        prenom,
        cle: 'suiviDemandes.notification.classeValidee',
      ),
    ),
    TypeEtapeFrise.enseignantAffecte =>
      t.suiviDemandes.notification.enseignantAffecte(
        dePrenom: deDevant(
          prenom,
          cle: 'suiviDemandes.notification.enseignantAffecte',
        ),
      ),
    TypeEtapeFrise.enAttente => t.suiviFamille.notification.enAttente(
      dePrenom: deDevant(prenom, cle: 'suiviFamille.notification.enAttente'),
    ),
    TypeEtapeFrise.eleveIntegre => t.suiviFamille.notification.eleveIntegre(
      dePrenom: deDevant(prenom, cle: 'suiviFamille.notification.eleveIntegre'),
    ),
    TypeEtapeFrise.premiereSeance => t.suiviFamille.notification.premiereSeance(
      dePrenom: deDevant(
        prenom,
        cle: 'suiviFamille.notification.premiereSeance',
      ),
    ),
  };
}

/// Le motif de cloture en clair.
String libelleMotifCloture(
  MotifClotureFrise motif,
  String prenom,
) => switch (motif) {
  MotifClotureFrise.retraitFamille => t.suiviFamille.close.motif.retraitFamille,
  MotifClotureFrise.offreRetiree => t.suiviFamille.close.motif.offreRetiree,
  MotifClotureFrise.classeNonConstituee =>
    t.suiviFamille.close.motif.classeNonConstituee,
  MotifClotureFrise.refusDirection => t.suiviFamille.close.motif.refusDirection,
  MotifClotureFrise.dejaEnClasse => t.suiviFamille.close.motif.dejaEnClasse(
    prenom: prenom,
  ),
  MotifClotureFrise.inconnu => t.suiviFamille.close.motif.inconnu,
};

/// Le titre de la notification de cloture : « Demande de Yusuf : ce
/// créneau n'est plus proposé. »
String titreNotificationCloture(MotifClotureFrise motif, String prenom) {
  if (motif == MotifClotureFrise.dejaEnClasse) {
    return t.suiviFamille.notification.dejaEnClasse(
      dePrenom: deDevant(prenom, cle: 'suiviFamille.notification.dejaEnClasse'),
    );
  }
  final String phrase = libelleMotifCloture(motif, prenom);
  return t.suiviFamille.notification.close(
    dePrenom: deDevant(prenom, cle: 'suiviFamille.notification.close'),
    motif: phrase.isEmpty
        ? phrase
        : phrase[0].toLowerCase() + phrase.substring(1),
  );
}
