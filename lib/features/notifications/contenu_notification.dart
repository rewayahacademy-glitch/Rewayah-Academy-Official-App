// Le texte de chaque notification (fiche « Fraicheur et notifications » du
// 27/10/2026, ligne 13) : une phrase du vocabulaire de l'academie, en
// francais et en arabe (slang), choisie d'apres l'evenement et, pour les
// evenements des classes, d'apres la portee que le serveur a posee (« soi » :
// l'eleve lui-meme ; « foyer » : le tuteur ; « classe » : l'enseignante) et
// l'heure locale de la seance (`debut_local`). Les identifiants restent
// caches. Un evenement inconnu (version du serveur plus recente que celle de
// l'application) a un titre de repli lisible : la page ne plante jamais.

import '../../core/capacites/notifications_supabase.dart';
import '../../core/i18n/strings.g.dart';
import '../suivi_foyer/filtres_historique.dart'
    show dateLongueHistorique, heureMinute;

/// L'heure locale d'une seance telle que le serveur la rend
/// (`YYYY-MM-DDTHH:MM:SS`, deja dans le fuseau de la personne), en toutes
/// lettres ; `null` quand elle manque ou ne se lit pas.
String? quandDepuis(Map<String, dynamic> params) {
  final dynamic brut = params['debut_local'];
  if (brut is! String) return null;
  final DateTime? instant = DateTime.tryParse(brut);
  if (instant == null || instant.isUtc) return null;
  return t.notifications.quand(
    date: dateLongueHistorique(instant),
    heure: heureMinute(instant),
  );
}

/// Résout uniquement des libellés traduits; les paramètres SQL restent cachés.
NotificationContenu contenuNotificationPour(
  String evenement,
  Map<String, dynamic> params,
) {
  final evenements = t.notifications.evenements;
  final String portee = params['portee'] is String
      ? params['portee'] as String
      : '';
  final String? quand = quandDepuis(params);

  /// Une phrase par portee, la phrase generale sinon.
  String selonPortee({
    required String soi,
    required String foyer,
    required String classe,
    required String sinon,
  }) => switch (portee) {
    'soi' => soi,
    'foyer' => foyer,
    'classe' => classe,
    _ => sinon,
  };

  final String titre = switch (evenement) {
    'demande_recue' => evenements.demandeRecue,
    'demande_presentation' => evenements.demandePresentation,
    'classe_validee' => evenements.classeValidee,
    'enseignant_affecte' => selonPortee(
      soi: evenements.enseignantAffecteSoi,
      foyer: evenements.enseignantAffecte,
      classe: evenements.enseignantAffecteClasse,
      sinon: evenements.enseignantAffecte,
    ),
    'demande_close' => evenements.demandeClose,
    'remplacement_propose' => evenements.remplacementPropose,
    'remplacement_pris' =>
      quand == null
          ? evenements.remplacementPris
          : evenements.remplacementPrisQuand(quand: quand),
    'controle_mission_attribuee' => evenements.controleMissionAttribuee,
    'controle_mission_non_controlee' => evenements.controleMissionNonControlee,
    'classe_changee' => evenements.classeChangee,
    'paiement_relance' => evenements.paiementRelance,
    'acces_suspendu_paiement' => evenements.accesSuspenduPaiement,
    'acces_retabli_paiement' => evenements.accesRetabliPaiement,
    'paiement_recu' => evenements.paiementRecu,
    // Fiche du 27/10, ligne 11.
    'classe_creee' => selonPortee(
      soi: evenements.classeCreeeSoi,
      foyer: evenements.classeCreeeFoyer,
      classe: evenements.classeCreeeClasse,
      sinon: evenements.classeCreee,
    ),
    'enseignant_change' => selonPortee(
      soi: evenements.enseignantChange,
      foyer: evenements.enseignantChange,
      classe: evenements.enseignantChangeClasse,
      sinon: evenements.enseignantChange,
    ),
    'eleve_inscrit' => selonPortee(
      soi: evenements.eleveInscritSoi,
      foyer: evenements.eleveInscritFoyer,
      classe: evenements.eleveInscritClasse,
      sinon: evenements.eleveInscrit,
    ),
    'eleve_retire' => selonPortee(
      soi: evenements.eleveRetireSoi,
      foyer: evenements.eleveRetireFoyer,
      classe: evenements.eleveRetireClasse,
      sinon: evenements.eleveRetire,
    ),
    'creneau_change' => evenements.creneauChange,
    'seance_annulee' =>
      quand == null
          ? evenements.seanceAnnulee
          : evenements.seanceAnnuleeQuand(quand: quand),
    'seance_deplacee' =>
      quand == null
          ? evenements.seanceDeplacee
          : evenements.seanceDeplaceeQuand(quand: quand),
    'enseignante_absente' =>
      quand == null
          ? evenements.enseignanteAbsente
          : evenements.enseignanteAbsenteQuand(quand: quand),
    // A3 (31/10/2026) : le titulaire n'est pas entre dans la salle.
    'remplacement_avertissement' => switch (int.tryParse(
      '${params['minutes'] ?? ''}',
    )) {
      final int minutes => evenements.remplacementAvertissementMinutes(
        minutes: minutes,
      ),
      null => evenements.remplacementAvertissement,
    },
    'remplacement_pre_alerte' => evenements.remplacementPreAlerte,
    'remplacement_inutile' => evenements.remplacementInutile,
    'titulaire_en_retard' =>
      portee == 'direction'
          ? evenements.titulaireEnRetardDirection
          : evenements.titulaireEnRetard,
    'remplacant_arrive' => evenements.remplacantArrive,
    'classe_supprimee' => selonPortee(
      soi: evenements.classeSupprimeeSoi,
      foyer: evenements.classeSupprimeeFoyer,
      classe: evenements.classeSupprimeeClasse,
      sinon: evenements.classeSupprimee,
    ),
    // FN-028 (01/11/2026) : l'avis de fin de seance, application seulement.
    'seance_terminee' => texteSeanceTerminee(params, portee, quand),
    // Un evenement que cette version ne connait pas : dit, jamais perdu, et
    // la phrase dit quoi faire (K-59).
    _ => evenements.inconnu,
  };
  return NotificationContenu(titre: titre);
}

/// FN-028 : le texte de l'avis de fin de seance, d'apres ce que le serveur a
/// pose. Enseignant (portee « classe ») : les presents sur les inscrits, puis
/// le cahier (a remplir, ou depose). Eleve et tuteur : le Travail a preparer
/// seulement si la regle de partage l'ouvre (`travail_etat` « partage ») ;
/// « Aucun travail a preparer. » seulement si le cahier, partage, n'en porte
/// pas (« aucun ») ; sinon rien n'est dit du travail.
String texteSeanceTerminee(
  Map<String, dynamic> params,
  String portee,
  String? quand,
) {
  final evenements = t.notifications.evenements;
  final Object? brutClasse = params['classe'];
  final String? classe = brutClasse is String && brutClasse.trim().isNotEmpty
      ? brutClasse.trim()
      : null;
  final String premiere = classe != null && quand != null
      ? evenements.seanceTermineeDe(classe: classe, quand: quand)
      : evenements.seanceTerminee;
  String? suite;
  if (portee == 'classe') {
    final int? presents = int.tryParse('${params['presents'] ?? ''}');
    final int? inscrits = int.tryParse('${params['inscrits'] ?? ''}');
    final String cahier = params['cahier_depose'] == true
        ? evenements.seanceTermineeCahierDepose
        : evenements.seanceTermineeCahierAttend;
    suite = presents == null || inscrits == null
        ? cahier
        : evenements.seanceTermineePhrases(
            premiere: evenements.seanceTermineePresents(
              n: presents,
              total: inscrits,
            ),
            suite: cahier,
          );
  } else {
    final Object? travail = params['travail'];
    suite = switch (params['travail_etat']) {
      'partage' when travail is String && travail.trim().isNotEmpty =>
        evenements.seanceTermineeTravail(travail: travail.trim()),
      'aucun' => evenements.seanceTermineeAucunTravail,
      _ => null,
    };
  }
  return suite == null
      ? premiere
      : evenements.seanceTermineePhrases(premiere: premiere, suite: suite);
}
