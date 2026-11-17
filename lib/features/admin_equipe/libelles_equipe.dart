// BE-2b : les mots de l'ecran « Equipe ». Un geste ne se montre jamais par son
// code (`lire`, `valider_piece`) : il s'ecrit en mots de l'ecran ; un code que
// cette version ne connait pas devient « un autre geste », jamais le code.
library;

import '../../core/candidature/modeles_candidature.dart' show EtapeCandidature;
import '../../core/equipe/modeles_equipe.dart';
import '../../core/i18n/strings.g.dart';
import '../admin_candidatures/libelles_candidatures.dart'
    show dateCourteCandidature, libelleSalle;
import '../candidature/libelles_parcours.dart' show nomDeLangue;

/// Le geste d'une mission, en mots (un verbe : « lire les candidatures »).
String libelleGesteMission(String code) {
  final g = t.admin.equipe.gestes;
  return switch (code) {
    'lire' => g.lire,
    'voir_contact' => g.voir_contact,
    'demander_complement' => g.demander_complement,
    'admettre_verifications' => g.admettre_verifications,
    'confirmer_moyen_paiement' => g.confirmer_moyen_paiement,
    'infirmer_moyen_paiement' => g.infirmer_moyen_paiement,
    'debloquer_versement' => g.debloquer_versement,
    'definir_responsable' => g.definir_responsable,
    'consigner_prevenu' => g.consigner_prevenu,
    'rattacher' => g.rattacher,
    'planifier_entretien' => g.planifier_entretien,
    'consigner_entretien_tenu' => g.consigner_entretien_tenu,
    'consigner_entretien_non_tenu' => g.consigner_entretien_non_tenu,
    'valider_piece' => g.valider_piece,
    'rouvrir' => g.rouvrir,
    'retirer' => g.retirer,
    _ => g.autre,
  };
}

/// Les gestes d'une mission, en mots, separes par des virgules.
String phraseGestes(List<String> gestes) =>
    gestes.map(libelleGesteMission).join(', ');

/// Le role d'une personne de l'equipe, en mot ; vide pour un role inconnu.
String libelleRoleEquipe(String role) => switch (role) {
  'associe' => t.admin.comptes.roleAssocie,
  'teacher' => t.admin.comptes.roleEnseignant,
  'accountant' => t.admin.comptes.roleComptable,
  _ => '',
};

/// Le cote tel que le serveur l'a ecrit, en mot : « hommes » ou « femmes ».
String? libelleCoteEquipe(String? cote) => switch (cote) {
  'male' => t.admin.equipe.cote.male,
  'female' => t.admin.equipe.cote.female,
  _ => null,
};

/// Le perimetre en mots : « les candidatures en Anglais, Salle d'examen ».
/// Sans limite : toutes les candidatures du cote de la personne.
String phrasePerimetre(PerimetreMission p) {
  final r = t.admin.equipe.perimetre;
  final List<String> morceaux = <String>[
    if (p.langues.isNotEmpty)
      r.langues(
        langues: p.langues.map((String c) => nomDeLangue(c) ?? c).join(', '),
      ),
    if (p.etapes.isNotEmpty)
      r.salles(
        salles: <String>[
          for (final EtapeCandidature e in p.etapes)
            if (libelleSalle(e) case final String s) s,
        ].join(', '),
      ),
    if (p.dossiers > 0) r.dossiers(n: p.dossiers),
  ];
  return morceaux.isEmpty ? r.tous : morceaux.join(', ');
}

/// La duree d'une attribution : « sans fin » ou « jusqu'au 30 novembre ».
String phraseDuree(DateTime? fin) => fin == null
    ? t.admin.equipe.sansFin
    : t.admin.equipe.jusquAu(date: dateCourteCandidature(fin.toLocal()));
