/// CALENDRIER-ET-PAUSES (lot 2 de la charte, 12/11/2026) : le calendrier de
/// l'ecole saisi par la direction, et la pause d'un mois.
///
/// Le serveur decide de tout (preavis de 7 jours, mois civil entier, plafond de
/// 2 mois sur 12, recul de la date limite) ; l'application ne calcule rien :
/// elle montre la regle que le serveur donne, et dit ses refus en mots simples.
/// Les valeurs de la regle viennent de `app_config` par `pauses_eleve_lecture`,
/// jamais d'une constante ici. Aucun argent dans ce lot.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Un jour (sans heure) lu dans une date SQL `AAAA-MM-JJ` ; `null` si illisible.
DateTime? jourDepuisSql(Object? brut) {
  if (brut is! String) return null;
  final DateTime? d = DateTime.tryParse(brut);
  return d == null ? null : DateTime(d.year, d.month, d.day);
}

/// Un jour ecrit pour le serveur : `AAAA-MM-JJ`.
String jourVersSql(DateTime jour) =>
    '${jour.year.toString().padLeft(4, '0')}-'
    '${jour.month.toString().padLeft(2, '0')}-'
    '${jour.day.toString().padLeft(2, '0')}';

/// Le genre d'une date du calendrier.
enum TypeEvenement {
  /// Les cours s'arretent ; les dates limites reculent.
  fermeture('fermeture'),

  /// Une rencontre de recitation (encourage, ne fait jamais passer d'etape).
  rencontre('rencontre'),

  /// Une date d'evaluation.
  evaluation('evaluation'),

  /// Une autre date importante.
  autre('autre');

  const TypeEvenement(this.valeurSql);

  /// La valeur dans `calendrier_ecole.type`.
  final String valeurSql;

  /// Lit la valeur SQL ; `null` si inconnue.
  static TypeEvenement? depuisSql(Object? v) {
    for (final TypeEvenement t in values) {
      if (t.valeurSql == v) return t;
    }
    return null;
  }
}

/// La categorie d'une fermeture : le Ramadan et l'Aid ont chacun leur maximum.
enum CategorieFermeture {
  /// Du 20 Ramadan au 7 Shawwal, 20 jours au plus.
  ramadan('ramadan'),

  /// Du 9 au 18 Dhu al-Hijja, 10 jours au plus.
  aidAlAdha('aid_al_adha'),

  /// Une autre fermeture, de la duree que la direction choisit.
  autre('autre');

  const CategorieFermeture(this.valeurSql);

  /// La valeur dans `calendrier_ecole.categorie`.
  final String valeurSql;

  /// Lit la valeur SQL ; `null` si inconnue ou absente.
  static CategorieFermeture? depuisSql(Object? v) {
    for (final CategorieFermeture c in values) {
      if (c.valeurSql == v) return c;
    }
    return null;
  }
}

/// A qui s'adresse une date.
enum PorteeEvenement {
  /// Toute l'ecole.
  ecole('ecole'),

  /// Une tranche d'age.
  tranche('tranche'),

  /// Une classe.
  classe('classe');

  const PorteeEvenement(this.valeurSql);

  /// La valeur dans `calendrier_ecole.portee`.
  final String valeurSql;

  /// Lit la valeur SQL ; `null` si inconnue.
  static PorteeEvenement? depuisSql(Object? v) {
    for (final PorteeEvenement p in values) {
      if (p.valeurSql == v) return p;
    }
    return null;
  }
}

/// Une date du calendrier, telle que la direction la lit
/// (`calendrier_ecole_liste`).
@immutable
class EvenementCalendrier {
  /// Cree la ligne.
  const EvenementCalendrier({
    required this.id,
    required this.type,
    required this.titre,
    required this.du,
    required this.au,
    required this.portee,
    required this.publie,
    this.categorie,
    this.cohorte,
    this.groupeId,
    this.groupeLibelle,
    this.elevesVises,
    this.seancesDejaPrevues,
  });

  /// Lit une ligne ; `null` si elle est illisible (jamais completee).
  static EvenementCalendrier? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final TypeEvenement? type = TypeEvenement.depuisSql(brut['type']);
    final PorteeEvenement? portee = PorteeEvenement.depuisSql(brut['portee']);
    final DateTime? du = jourDepuisSql(brut['du']);
    final DateTime? au = jourDepuisSql(brut['au']);
    final Object? id = brut['id'];
    if (type == null || portee == null || du == null || au == null) return null;
    if (id is! String) return null;
    return EvenementCalendrier(
      id: id,
      type: type,
      categorie: CategorieFermeture.depuisSql(brut['categorie']),
      titre: (brut['titre'] as String? ?? '').trim(),
      du: du,
      au: au,
      portee: portee,
      cohorte: brut['cohorte'] as String?,
      groupeId: brut['groupe_id'] as String?,
      groupeLibelle: brut['groupe_libelle'] as String?,
      publie: brut['publie'] == true,
      elevesVises: (brut['eleves_vises'] as num?)?.toInt(),
      seancesDejaPrevues: (brut['seances_deja_prevues'] as num?)?.toInt(),
    );
  }

  /// L'identifiant de la ligne.
  final String id;

  /// Le genre de date.
  final TypeEvenement type;

  /// La categorie d'une fermeture ; nulle sinon.
  final CategorieFermeture? categorie;

  /// Le titre saisi par la direction.
  final String titre;

  /// Le premier jour.
  final DateTime du;

  /// Le dernier jour, compris.
  final DateTime au;

  /// A qui la date s'adresse.
  final PorteeEvenement portee;

  /// Le code de la tranche d'age visee (portee tranche).
  final String? cohorte;

  /// La classe visee (portee classe).
  final String? groupeId;

  /// Le nom de la classe visee.
  final String? groupeLibelle;

  /// Publiee : seules les dates publiees agissent et se lisent.
  final bool publie;

  /// Pour une fermeture : le nombre d'eleves dont la date limite recule.
  final int? elevesVises;

  /// Pour une fermeture : les seances deja creees pendant ces jours, que le
  /// serveur ne supprime pas.
  final int? seancesDejaPrevues;

  /// Le nombre de jours, premier et dernier compris.
  int get jours => au.difference(du).inDays + 1;
}

/// Lit la liste de `calendrier_ecole_liste` ; une ligne illisible est ecartee.
List<EvenementCalendrier> evenementsDepuisJson(
  Object? brut,
) => <EvenementCalendrier>[
  for (final Object? l in brut is List ? brut : const <Object?>[])
    if (EvenementCalendrier.depuisJson(l) case final EvenementCalendrier e) e,
];

/// Pourquoi le serveur a refuse une saisie du calendrier.
enum MotifRefusCalendrier {
  /// Une fermeture du Ramadan ou de l'Aid depasse son maximum.
  fermetureTropLongue,

  /// Dates inversees ou trop eloignees.
  datesInvalides,

  /// La tranche ou la classe visee manque ou n'existe pas.
  porteeInvalide,

  /// Titre ou genre illisible.
  evenementInvalide,

  /// La date n'existe plus.
  introuvable,

  /// La personne connectee n'est pas la direction.
  nonAutorise,

  /// Un refus que le client ne connait pas.
  inconnu,
}

/// Le refus du serveur, en motif ferme.
class CalendrierRefuse implements Exception {
  /// Cree le refus.
  const CalendrierRefuse(this.motif);

  /// Le motif.
  final MotifRefusCalendrier motif;

  @override
  String toString() => 'CalendrierRefuse($motif)';
}

/// Le refus du serveur d'apres son message et son code SQL. Pure, pour les
/// tests.
MotifRefusCalendrier motifRefusCalendrier({
  required String? code,
  required String message,
}) => switch (message) {
  'calendrier_fermeture_trop_longue' =>
    MotifRefusCalendrier.fermetureTropLongue,
  'calendrier_dates_invalides' => MotifRefusCalendrier.datesInvalides,
  'calendrier_portee_invalide' => MotifRefusCalendrier.porteeInvalide,
  'calendrier_evenement_invalide' => MotifRefusCalendrier.evenementInvalide,
  'calendrier_evenement_introuvable' => MotifRefusCalendrier.introuvable,
  _ =>
    code == '42501'
        ? MotifRefusCalendrier.nonAutorise
        : MotifRefusCalendrier.inconnu,
};

/// Le calendrier cote direction : liste, saisie, publication.
abstract interface class PortCalendrierDirection {
  /// Toutes les dates, publiees ou non.
  Future<List<EvenementCalendrier>> lister();

  /// Ajoute une date ([id] nul) ou modifie la date [id]. Leve
  /// [CalendrierRefuse].
  Future<String> enregistrer({
    required TypeEvenement type,
    required String titre,
    required DateTime du,
    required DateTime au,
    required PorteeEvenement portee,
    String? id,
    CategorieFermeture? categorie,
    String? cohorte,
    String? groupeId,
  });

  /// Publie la date, ou la retire de la publication. Leve [CalendrierRefuse].
  Future<void> publier(String id, {required bool publie});
}

/// Le port du calendrier de la direction : absent tant que `main.dart` ne le
/// pose pas ; sans lui, la page dit que le calendrier est indisponible.
final Provider<PortCalendrierDirection?> portCalendrierDirectionProvider =
    Provider<PortCalendrierDirection?>((Ref _) => null);

/// Les dates du calendrier pour la direction ; `null` sans port.
final FutureProvider<List<EvenementCalendrier>?> calendrierDirectionProvider =
    FutureProvider<List<EvenementCalendrier>?>((Ref ref) {
      final PortCalendrierDirection? port = ref.watch(
        portCalendrierDirectionProvider,
      );
      if (port == null) return Future<List<EvenementCalendrier>?>.value();
      return port.lister();
    }, retry: (int _, Object _) => null);

// ---------------------------------------------------------------------------
// Les pauses
// ---------------------------------------------------------------------------

/// L'etat d'une pause.
enum StatutPause {
  /// En attente de la reponse de la direction.
  demandee('demandee'),

  /// Acceptee : la place est gardee, la date limite recule.
  acceptee('acceptee'),

  /// Refusee par la direction, avec son motif.
  refusee('refusee'),

  /// Annulee avant son debut.
  annulee('annulee');

  const StatutPause(this.valeurSql);

  /// La valeur dans `pauses_eleve.statut`.
  final String valeurSql;

  /// Lit la valeur SQL ; `null` si inconnue ou absente.
  static StatutPause? depuisSql(Object? v) {
    for (final StatutPause s in values) {
      if (s.valeurSql == v) return s;
    }
    return null;
  }
}

/// Le genre d'une pause.
enum TypePause {
  /// Un mois civil entier, demande par la famille.
  mois,

  /// Accordee par la direction (maladie soudaine, interruption accordee).
  exception;

  /// Lit la valeur SQL ; `null` si inconnue.
  static TypePause? depuisSql(Object? v) => switch (v) {
    'mois' => TypePause.mois,
    'exception' => TypePause.exception,
    _ => null,
  };
}

/// La regle de la pause, telle que le serveur la lit dans `app_config`.
@immutable
class ReglePause {
  /// Cree la regle.
  const ReglePause({
    required this.preavisJours,
    required this.plafondMois,
    required this.fenetreMois,
    required this.delaiReponseJours,
  });

  /// Lit la regle ; `null` si une valeur manque (jamais supposee).
  static ReglePause? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final int? p = (brut['preavis_jours'] as num?)?.toInt();
    final int? m = (brut['plafond_mois'] as num?)?.toInt();
    final int? f = (brut['fenetre_mois'] as num?)?.toInt();
    final int? d = (brut['delai_reponse_jours'] as num?)?.toInt();
    if (p == null || m == null || f == null || d == null) return null;
    return ReglePause(
      preavisJours: p,
      plafondMois: m,
      fenetreMois: f,
      delaiReponseJours: d,
    );
  }

  /// Jours de preavis avant le debut du mois.
  final int preavisJours;

  /// Mois de pause sans accord particulier...
  final int plafondMois;

  /// ... sur ce nombre de mois glissants.
  final int fenetreMois;

  /// Jours dont la direction dispose pour repondre.
  final int delaiReponseJours;
}

/// Un mois qu'on peut demander.
@immutable
class MoisPropose {
  /// Cree le mois.
  const MoisPropose({
    required this.mois,
    required this.aLaDirection,
    this.etat,
  });

  /// Le premier jour du mois.
  final DateTime mois;

  /// Vrai : au-dela du plafond, la demande attend la direction.
  final bool aLaDirection;

  /// Deja demande (en attente) ou accepte ; nul sinon.
  final StatutPause? etat;
}

/// Une pause de l'eleve.
@immutable
class PauseEleve {
  /// Cree la pause.
  const PauseEleve({
    required this.id,
    required this.type,
    required this.debut,
    required this.fin,
    required this.statut,
    required this.annulable,
    this.repondreAvant,
    this.motifDecision,
  });

  /// Lit une pause ; `null` si elle est illisible.
  static PauseEleve? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['id'];
    final TypePause? type = TypePause.depuisSql(brut['type']);
    final DateTime? debut = jourDepuisSql(brut['debut']);
    final DateTime? fin = jourDepuisSql(brut['fin']);
    final StatutPause? statut = StatutPause.depuisSql(brut['statut']);
    if (id is! String || type == null || debut == null || fin == null) {
      return null;
    }
    if (statut == null) return null;
    return PauseEleve(
      id: id,
      type: type,
      debut: debut,
      fin: fin,
      statut: statut,
      annulable: brut['annulable'] == true,
      repondreAvant: jourDepuisSql(brut['repondre_avant']),
      motifDecision: (brut['motif_decision'] as String?)?.trim(),
    );
  }

  /// L'identifiant de la pause.
  final String id;

  /// Mois demande ou exception accordee.
  final TypePause type;

  /// Premier jour.
  final DateTime debut;

  /// Dernier jour, compris.
  final DateTime fin;

  /// L'etat.
  final StatutPause statut;

  /// Vrai tant qu'elle n'a pas commence et qu'elle n'est ni refusee ni annulee.
  final bool annulable;

  /// Pour une demande en attente : le jour limite de la reponse.
  final DateTime? repondreAvant;

  /// Le motif ecrit par la direction en decidant.
  final String? motifDecision;
}

/// Ce que la famille lit : la regle, les mois proposes, les pauses.
@immutable
class LecturePauses {
  /// Cree la lecture.
  const LecturePauses({
    required this.eleveId,
    required this.regle,
    required this.moisAccordes,
    required this.moisProposes,
    required this.pauses,
    this.prenom,
  });

  /// Lit `pauses_eleve_lecture` ; `null` si la regle est illisible.
  static LecturePauses? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final ReglePause? regle = ReglePause.depuisJson(brut['regle']);
    final Object? eleve = brut['eleve_id'];
    if (regle == null || eleve is! String) return null;
    return LecturePauses(
      eleveId: eleve,
      prenom: (brut['prenom'] as String?)?.trim(),
      regle: regle,
      moisAccordes: (brut['mois_accordes'] as num?)?.toInt() ?? 0,
      moisProposes: <MoisPropose>[
        for (final Object? m
            in brut['mois_proposes'] is List
                ? brut['mois_proposes'] as List<Object?>
                : const <Object?>[])
          if (m is Map)
            if (jourDepuisSql(m['mois']) case final DateTime mois)
              MoisPropose(
                mois: mois,
                aLaDirection: m['a_la_direction'] == true,
                etat: StatutPause.depuisSql(m['etat']),
              ),
      ],
      pauses: <PauseEleve>[
        for (final Object? p
            in brut['pauses'] is List
                ? brut['pauses'] as List<Object?>
                : const <Object?>[])
          if (PauseEleve.depuisJson(p) case final PauseEleve pause) pause,
      ],
    );
  }

  /// L'eleve concerne.
  final String eleveId;

  /// Son prenom, quand le serveur le donne.
  final String? prenom;

  /// La regle de la pause.
  final ReglePause regle;

  /// Mois de pause acceptes sur la fenetre glissante.
  final int moisAccordes;

  /// Les mois qu'on peut demander, du plus proche au plus lointain.
  final List<MoisPropose> moisProposes;

  /// Les pauses, de la plus recente a la plus ancienne.
  final List<PauseEleve> pauses;
}

/// Pourquoi le serveur a refuse un geste sur une pause.
enum MotifRefusPause {
  /// Le mois commence dans moins de jours que le preavis.
  preavis,

  /// Ce mois est deja demande ou accorde.
  dejaDemandee,

  /// Mois illisible.
  moisInvalide,

  /// La pause a deja commence, ou n'est plus en cours de demande.
  nonAnnulable,

  /// Le motif manque.
  motifRequis,

  /// Une autre decision a deja ete prise.
  dejaDecidee,

  /// Le mois a commence sans reponse : il ne s'accepte plus.
  debutPasse,

  /// Dates inversees ou trop eloignees.
  datesInvalides,

  /// L'eleve n'existe pas.
  eleveIntrouvable,

  /// La personne connectee n'a pas ce droit.
  nonAutorise,

  /// Un refus que le client ne connait pas.
  inconnu,
}

/// Le refus du serveur, en motif ferme.
class PauseRefusee implements Exception {
  /// Cree le refus.
  const PauseRefusee(this.motif);

  /// Le motif.
  final MotifRefusPause motif;

  @override
  String toString() => 'PauseRefusee($motif)';
}

/// Le refus du serveur d'apres son message et son code SQL. Pure, pour les
/// tests.
MotifRefusPause motifRefusPause({
  required String? code,
  required String message,
}) => switch (message) {
  'pause_preavis' => MotifRefusPause.preavis,
  'pause_deja_demandee' => MotifRefusPause.dejaDemandee,
  'pause_mois_invalide' => MotifRefusPause.moisInvalide,
  'pause_non_annulable' => MotifRefusPause.nonAnnulable,
  'pause_motif_requis' => MotifRefusPause.motifRequis,
  'pause_deja_decidee' => MotifRefusPause.dejaDecidee,
  'pause_debut_passe' => MotifRefusPause.debutPasse,
  'pause_dates_invalides' => MotifRefusPause.datesInvalides,
  'pause_eleve_introuvable' => MotifRefusPause.eleveIntrouvable,
  _ => code == '42501' ? MotifRefusPause.nonAutorise : MotifRefusPause.inconnu,
};

/// Ce que la famille obtient en demandant un mois.
@immutable
class ReponseDemandePause {
  /// Cree la reponse.
  const ReponseDemandePause({
    required this.statut,
    required this.debut,
    required this.fin,
    this.repondreAvant,
  });

  /// Lit la reponse de `pause_demander` ; `null` si illisible.
  static ReponseDemandePause? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final StatutPause? statut = StatutPause.depuisSql(brut['statut']);
    final DateTime? debut = jourDepuisSql(brut['debut']);
    final DateTime? fin = jourDepuisSql(brut['fin']);
    if (statut == null || debut == null || fin == null) return null;
    return ReponseDemandePause(
      statut: statut,
      debut: debut,
      fin: fin,
      repondreAvant: jourDepuisSql(brut['repondre_avant']),
    );
  }

  /// `acceptee` dans la regle, `demandee` au-dela du plafond.
  final StatutPause statut;

  /// Premier jour du mois.
  final DateTime debut;

  /// Dernier jour du mois.
  final DateTime fin;

  /// Pour une demande en attente : le jour limite de la reponse.
  final DateTime? repondreAvant;
}

/// Une demande qui attend la direction.
@immutable
class DemandePauseDirection {
  /// Cree la demande.
  const DemandePauseDirection({
    required this.id,
    required this.eleveId,
    required this.eleveNom,
    required this.debut,
    required this.fin,
    required this.enRetard,
    required this.moisAccordes,
    this.cohorte,
    this.repondreAvant,
  });

  /// Lit une demande ; `null` si illisible.
  static DemandePauseDirection? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['id'];
    final Object? eleve = brut['eleve_id'];
    final DateTime? debut = jourDepuisSql(brut['debut']);
    final DateTime? fin = jourDepuisSql(brut['fin']);
    if (id is! String || eleve is! String || debut == null || fin == null) {
      return null;
    }
    return DemandePauseDirection(
      id: id,
      eleveId: eleve,
      eleveNom: (brut['eleve_nom'] as String? ?? '').trim(),
      cohorte: brut['cohorte'] as String?,
      debut: debut,
      fin: fin,
      repondreAvant: jourDepuisSql(brut['repondre_avant']),
      enRetard: brut['en_retard'] == true,
      moisAccordes: (brut['mois_accordes'] as num?)?.toInt() ?? 0,
    );
  }

  /// L'identifiant de la demande.
  final String id;

  /// L'eleve concerne.
  final String eleveId;

  /// Son nom, tel que la direction le lit.
  final String eleveNom;

  /// Sa tranche d'age.
  final String? cohorte;

  /// Premier jour du mois demande.
  final DateTime debut;

  /// Dernier jour du mois demande.
  final DateTime fin;

  /// Le jour limite de la reponse (3 jours).
  final DateTime? repondreAvant;

  /// Vrai quand le delai de reponse est passe.
  final bool enRetard;

  /// Mois de pause deja accordes a cet eleve sur la fenetre.
  final int moisAccordes;
}

/// Une decision recente de la direction (pause d'exception comprise).
@immutable
class DecisionPause {
  /// Cree la decision.
  const DecisionPause({
    required this.id,
    required this.eleveNom,
    required this.type,
    required this.debut,
    required this.fin,
    required this.statut,
    this.motif,
    this.motifDecision,
    this.decideeParNom,
  });

  /// Lit une decision ; `null` si illisible.
  static DecisionPause? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['id'];
    final TypePause? type = TypePause.depuisSql(brut['type']);
    final DateTime? debut = jourDepuisSql(brut['debut']);
    final DateTime? fin = jourDepuisSql(brut['fin']);
    final StatutPause? statut = StatutPause.depuisSql(brut['statut']);
    if (id is! String || type == null || debut == null || fin == null) {
      return null;
    }
    if (statut == null) return null;
    return DecisionPause(
      id: id,
      eleveNom: (brut['eleve_nom'] as String? ?? '').trim(),
      type: type,
      debut: debut,
      fin: fin,
      statut: statut,
      motif: (brut['motif'] as String?)?.trim(),
      motifDecision: (brut['motif_decision'] as String?)?.trim(),
      decideeParNom: (brut['decidee_par_nom'] as String?)?.trim(),
    );
  }

  /// L'identifiant de la pause.
  final String id;

  /// Le nom de l'eleve.
  final String eleveNom;

  /// Mois demande ou exception.
  final TypePause type;

  /// Premier jour.
  final DateTime debut;

  /// Dernier jour, compris.
  final DateTime fin;

  /// L'etat.
  final StatutPause statut;

  /// Le motif d'une exception.
  final String? motif;

  /// Le motif ecrit en decidant.
  final String? motifDecision;

  /// Le nom de la personne de la direction.
  final String? decideeParNom;
}

/// La file de la direction : les demandes a traiter et les decisions recentes.
@immutable
class FilePauses {
  /// Cree la file.
  const FilePauses({required this.aTraiter, required this.recentes});

  /// Lit `pauses_a_traiter`.
  factory FilePauses.depuisJson(Object? brut) {
    final Map<Object?, Object?> m = brut is Map
        ? brut.cast<Object?, Object?>()
        : const <Object?, Object?>{};
    return FilePauses(
      aTraiter: <DemandePauseDirection>[
        for (final Object? l
            in m['a_traiter'] is List
                ? m['a_traiter']! as List<Object?>
                : const <Object?>[])
          if (DemandePauseDirection.depuisJson(l)
              case final DemandePauseDirection d)
            d,
      ],
      recentes: <DecisionPause>[
        for (final Object? l
            in m['recentes'] is List
                ? m['recentes']! as List<Object?>
                : const <Object?>[])
          if (DecisionPause.depuisJson(l) case final DecisionPause d) d,
      ],
    );
  }

  /// Les demandes au-dela du plafond, qui attendent.
  final List<DemandePauseDirection> aTraiter;

  /// Les vingt dernieres decisions.
  final List<DecisionPause> recentes;
}

/// Un eleve trouve par son nom, pour une pause d'exception.
@immutable
class EleveTrouve {
  /// Cree l'eleve.
  const EleveTrouve({required this.id, required this.nom, this.cohorte});

  /// Lit une ligne de `pauses_eleves_recherche` ; `null` si illisible.
  static EleveTrouve? depuisJson(Object? brut) {
    if (brut is! Map) return null;
    final Object? id = brut['id'];
    if (id is! String) return null;
    return EleveTrouve(
      id: id,
      nom: (brut['nom'] as String? ?? '').trim(),
      cohorte: brut['cohorte'] as String?,
    );
  }

  /// L'identifiant du profil.
  final String id;

  /// Le nom.
  final String nom;

  /// La tranche d'age.
  final String? cohorte;
}

/// Les pauses : ce que la famille lit et demande, ce que la direction traite.
abstract interface class PortPauses {
  /// La regle, les mois proposes et les pauses de [eleveId]. Leve
  /// [PauseRefusee] pour un eleve qui n'est pas celui de la personne.
  Future<LecturePauses?> lecture(String eleveId);

  /// Demande le mois [mois] (n'importe quel jour du mois). Leve
  /// [PauseRefusee].
  Future<ReponseDemandePause> demander(String eleveId, DateTime mois);

  /// Annule une pause avant son debut. Leve [PauseRefusee].
  Future<void> annuler(String pauseId);

  /// La file de la direction.
  Future<FilePauses> file();

  /// La direction accepte ou refuse. Leve [PauseRefusee].
  Future<void> decider(String pauseId, {required bool accepter, String? motif});

  /// La direction accorde une pause d'exception. Leve [PauseRefusee].
  Future<void> accorderException({
    required String eleveId,
    required DateTime fin,
    required String motif,
  });

  /// Cherche un eleve par son nom (deux lettres au moins, vingt resultats au
  /// plus).
  Future<List<EleveTrouve>> rechercherEleves(String recherche);
}

/// Le port des pauses : absent tant que `main.dart` ne le pose pas.
final Provider<PortPauses?> portPausesProvider = Provider<PortPauses?>(
  (Ref _) => null,
);

/// La lecture des pauses d'un eleve ; `null` sans port.
final FutureProviderFamily<LecturePauses?, String> lecturePausesProvider =
    FutureProvider.family<LecturePauses?, String>((Ref ref, String eleveId) {
      final PortPauses? port = ref.watch(portPausesProvider);
      if (port == null) return Future<LecturePauses?>.value();
      return port.lecture(eleveId);
    }, retry: (int _, Object _) => null);

/// La file de la direction ; `null` sans port.
final FutureProvider<FilePauses?> filePausesProvider =
    FutureProvider<FilePauses?>((Ref ref) {
      final PortPauses? port = ref.watch(portPausesProvider);
      if (port == null) return Future<FilePauses?>.value();
      return port.file();
    }, retry: (int _, Object _) => null);
