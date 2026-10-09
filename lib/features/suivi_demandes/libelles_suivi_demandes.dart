/// OFFRES-FAM-1 : les mots du suivi des demandes de creneau.
///
/// Fonctions pures, partagees par l'ecran de suivi, la carte de l'accueil et
/// les notifications de demonstration : les trois disent la meme chose de la
/// meme demande. Aucune ne lit un nombre de demandeurs ni une identite
/// d'autrui : le contrat n'en porte pas (`port_suivi_demandes.dart`).
library;

import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/offres/port_suivi_demandes.dart';

/// « 18:05 » : heure murale, sur deux chiffres. Jamais convertie par
/// l'appareil : elle est deja dans le fuseau du foyer.
String hhmmDemande(int heure, int minute) =>
    '${heure.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// « Paris » pour `Europe/Paris`, « New York » pour `America/New_York`.
String villeDuFuseau(String fuseauIana) {
  final String dernier = fuseauIana.split('/').last;
  return dernier.replaceAll('_', ' ');
}

/// « Lundi, mardi et jeudi » : jours tries et dedoublonnes, le premier avec
/// sa majuscule.
String joursDemande(List<int> joursIso) {
  final List<String> noms = t.commun.dates.jours;
  final List<int> tries =
      joursIso.where((int j) => j >= 1 && j <= 7).toSet().toList()..sort();
  final List<String> mots = <String>[
    for (final (int i, int j) in tries.indexed)
      i == 0 ? noms[j - 1] : noms[j - 1].toLowerCase(),
  ];
  if (mots.length < 2) {
    return mots.join();
  }
  return t.suiviDemandes.joursEt(
    debut: mots.sublist(0, mots.length - 1).join(', '),
    dernier: mots.last,
  );
}

/// « 18:00, heure de Paris ».
String heureDemande(SuiviDemande d) => t.suiviDemandes.heureFuseau(
  heure: hhmmDemande(d.creneau.heure, d.creneau.minute),
  deVille: deDevant(villeDuFuseau(d.fuseauIana)),
);

/// « Lundi 19 octobre a 18:00, heure de Paris », ou `null` sans date.
String? debutCoursDemande(SuiviDemande d) {
  final DateTime? debut = d.debutCours;
  if (debut == null) {
    return null;
  }
  return t.suiviDemandes.debutValeur(
    date: t.commun.dates.jourDate(
      jour: t.commun.dates.jours[debut.weekday - 1],
      numero: debut.day,
      mois: t.commun.dates.mois[debut.month - 1],
    ),
    heure: hhmmDemande(debut.hour, debut.minute),
    deVille: deDevant(villeDuFuseau(d.fuseauIana)),
  );
}

/// Vrai pour une demande retiree (par la famille ou avec l'offre), faux pour
/// une demande non retenue.
bool estRetiree(MotifCloture motif) => switch (motif) {
  MotifCloture.retraitFamille || MotifCloture.offreRetiree => true,
  MotifCloture.classeNonConstituee || MotifCloture.refusDirection => false,
};

/// L'etat court d'une demande : « Demande envoyee », « Classe validee »,
/// « Enseignant affecte », « Demande retiree », « Demande non retenue ».
String etatCourtDemande(SuiviDemande d) => switch (d.etape) {
  EtapeDemande.envoyee => t.suiviDemandes.etapes.envoyee,
  EtapeDemande.classeValidee => t.suiviDemandes.etapes.classeValidee,
  EtapeDemande.enseignantAffecte => t.suiviDemandes.etapes.enseignantAffecte,
  EtapeDemande.close =>
    estRetiree(d.motif!)
        ? t.suiviDemandes.close.retiree
        : t.suiviDemandes.close.nonRetenue,
};

/// Le motif en clair d'une demande close.
String motifDemande(MotifCloture motif) => switch (motif) {
  MotifCloture.retraitFamille => t.suiviDemandes.close.motif.retraitFamille,
  MotifCloture.offreRetiree => t.suiviDemandes.close.motif.offreRetiree,
  MotifCloture.classeNonConstituee =>
    t.suiviDemandes.close.motif.classeNonConstituee,
  MotifCloture.refusDirection => t.suiviDemandes.close.motif.refusDirection,
};

/// La phrase de situation (decision du 09/10, §4), `null` pour une demande
/// close (son motif la remplace).
String? situationDemande(EtapeDemande etape) => switch (etape) {
  EtapeDemande.envoyee => t.suiviDemandes.situation.envoyee,
  EtapeDemande.classeValidee => t.suiviDemandes.situation.classeValidee,
  EtapeDemande.enseignantAffecte => t.suiviDemandes.situation.enseignantAffecte,
  EtapeDemande.close => null,
};

/// Le titre d'une notification de transition : qui, puis ce qui a change.
String titreNotificationDemande(SuiviDemande d) => switch (d.etape) {
  EtapeDemande.envoyee => t.suiviDemandes.notification.envoyee(
    dePrenom: deDevant(d.prenom),
  ),
  EtapeDemande.classeValidee => t.suiviDemandes.notification.classeValidee(
    dePrenom: deDevant(d.prenom),
  ),
  EtapeDemande.enseignantAffecte =>
    t.suiviDemandes.notification.enseignantAffecte(
      dePrenom: deDevant(d.prenom),
    ),
  EtapeDemande.close => t.suiviDemandes.notification.close(
    dePrenom: deDevant(d.prenom),
    motif: _minusculeInitiale(motifDemande(d.motif!)),
  ),
};

/// Au milieu d'une phrase, le motif commence en minuscule.
String _minusculeInitiale(String phrase) =>
    phrase.isEmpty ? phrase : phrase[0].toLowerCase() + phrase.substring(1);
