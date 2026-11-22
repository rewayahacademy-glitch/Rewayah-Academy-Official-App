/// FICHE-ELEVE-DIRECTION (directeur, 22/11/2026) : la fiche complete d'un
/// eleve, lue par la direction d'un seul appel, `fiche_eleve_direction`
/// (migration 20261201010000).
///
/// Le serveur decide de tout : la garde (direction active), le masquage
/// d'identite, l'etape et le rythme de la progression, l'etat de presence.
/// **Rien n'est calcule ici, rien n'est invente** : une donnee absente cache
/// sa ligne, un eleve inconnu rend `null` (page « introuvable »).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// Le tuteur dont depend un eleve.
@immutable
class TuteurFiche {
  /// Cree un tuteur.
  const TuteurFiche({
    required this.id,
    this.matricule,
    this.prenom,
    this.nom,
    this.courriel,
    this.telephone,
  });

  /// Lit le tuteur ; nul si le serveur n'en rend pas.
  static TuteurFiche? depuisJson(Object? json) {
    if (json is! Map || json['id'] is! String) return null;
    return TuteurFiche(
      id: json['id'] as String,
      matricule: _texte(json['matricule']),
      prenom: _texte(json['prenom']),
      nom: _texte(json['nom']),
      courriel: _texte(json['courriel']),
      telephone: _texte(json['telephone']),
    );
  }

  /// Son identifiant de profil (la famille s'ouvre par lui).
  final String id;

  /// Son matricule (jamais masque) : la famille s'ouvre par lui.
  final String? matricule;

  /// Son prenom ; nul sous masquage d'identite.
  final String? prenom;

  /// Son nom ; nul sous masquage d'identite.
  final String? nom;

  /// Son courriel ; nul sous masquage ou sans adresse.
  final String? courriel;

  /// Son telephone, quand il en a un.
  final String? telephone;

  /// Prenom et nom, ou vide.
  String get libelle => <String?>[
    prenom,
    nom,
  ].whereType<String>().where((String s) => s.isNotEmpty).join(' ');
}

/// Un creneau hebdomadaire de la classe, a l'heure de la classe.
@immutable
class CreneauFiche {
  /// Cree un creneau.
  const CreneauFiche({
    required this.jour,
    required this.heure,
    this.dureeMinutes,
  });

  /// Le jour, de 1 (lundi) a 7.
  final int jour;

  /// L'heure pleine, dans le fuseau de la classe.
  final int heure;

  /// La duree, quand le serveur la dit.
  final int? dureeMinutes;
}

/// Une classe active de l'eleve.
@immutable
class ClasseFiche {
  /// Cree une classe.
  const ClasseFiche({
    required this.id,
    required this.libelle,
    required this.fuseau,
    required this.creneaux,
    this.enseignantId,
    this.enseignantPrenom,
    this.enseignantNom,
    this.depuis,
  });

  /// Son identifiant.
  final String id;

  /// Son nom.
  final String libelle;

  /// Le fuseau IANA de la classe.
  final String fuseau;

  /// Ses creneaux.
  final List<CreneauFiche> creneaux;

  /// L'enseignant attitre, quand il y en a un.
  final String? enseignantId;

  /// Son prenom ; nul sous masquage.
  final String? enseignantPrenom;

  /// Son nom ; nul sous masquage.
  final String? enseignantNom;

  /// L'entree de l'eleve dans la classe.
  final DateTime? depuis;

  /// Le nom de l'enseignant, ou vide.
  String get enseignant => <String?>[
    enseignantPrenom,
    enseignantNom,
  ].whereType<String>().where((String s) => s.isNotEmpty).join(' ');
}

/// Une seance passee et la presence de l'eleve.
@immutable
class SeanceFiche {
  /// Cree une seance.
  const SeanceFiche({required this.debut, required this.etat});

  /// Son debut.
  final DateTime debut;

  /// L'etat de presence rendu par le serveur (`presente`, `absente`...).
  final String etat;
}

/// Les presences de l'eleve.
@immutable
class PresencesFiche {
  /// Cree les presences.
  const PresencesFiche({
    required this.total,
    required this.presents,
    required this.retards,
    required this.absents,
    required this.excuses,
    required this.dernieres,
  });

  /// Les seances tenues ou manquees, jamais celles a venir.
  final int total;

  /// Presente.
  final int presents;

  /// En retard.
  final int retards;

  /// Absente.
  final int absents;

  /// Excusee.
  final int excuses;

  /// Les dernieres seances, la plus recente d'abord.
  final List<SeanceFiche> dernieres;
}

/// Ou en est l'eleve du programme.
@immutable
class ProgressionFiche {
  /// Cree la progression.
  const ProgressionFiche({
    required this.etape,
    this.ordre,
    this.cycle,
    this.depuis,
    this.dateLimite,
    this.rythme,
  });

  /// Le nom de l'etape en cours.
  final String etape;

  /// Son rang.
  final int? ordre;

  /// Son cycle.
  final String? cycle;

  /// L'entree dans l'etape ; nulle quand le serveur la retient.
  final DateTime? depuis;

  /// La date limite ; nulle quand le serveur la retient.
  final DateTime? dateLimite;

  /// Le rythme rendu par le serveur (`en_avance`, `dans_les_temps`...).
  final String? rythme;
}

/// Les reponses de l'admission.
@immutable
class AdmissionFiche {
  /// Cree les reponses.
  const AdmissionFiche({
    this.age,
    this.niveau,
    this.objectif,
    this.langue,
    this.langueSecours,
    this.langueAutre,
    this.moments = const <String>[],
    this.riwaya,
    this.riwayaAutre,
    this.memorise,
    this.juz = const <int>[],
    this.sourates = const <String>[],
    this.source,
  });

  /// L'age declare d'un enfant.
  final int? age;

  /// Le niveau declare (code).
  final String? niveau;

  /// L'objectif declare (code).
  final String? objectif;

  /// La langue de cours (code).
  final String? langue;

  /// La langue de secours.
  final String? langueSecours;

  /// Une autre langue, ecrite par la famille.
  final String? langueAutre;

  /// Les moments de la journee (`matin`, `apres_midi`, `soir`).
  final List<String> moments;

  /// La lecture du Coran (`hafs`, `warsh`, `autre`).
  final String? riwaya;

  /// La lecture ecrite par la famille pour `autre`.
  final String? riwayaAutre;

  /// La quantite deja memorisee (code).
  final String? memorise;

  /// Les juz indiques.
  final List<int> juz;

  /// Les sourates indiquees (codes).
  final List<String> sourates;

  /// Comment la famille a connu l'academie.
  final String? source;

  /// Vrai quand rien n'a ete repondu.
  bool get vide =>
      age == null &&
      niveau == null &&
      objectif == null &&
      langue == null &&
      langueSecours == null &&
      langueAutre == null &&
      moments.isEmpty &&
      riwaya == null &&
      memorise == null &&
      juz.isEmpty &&
      sourates.isEmpty &&
      source == null;
}

/// La fiche d'un eleve.
@immutable
class FicheEleveDirection {
  /// Cree la fiche.
  const FicheEleveDirection({
    required this.id,
    required this.matricule,
    required this.etatCompte,
    required this.classes,
    required this.presences,
    this.prenom,
    this.nom,
    this.genre,
    this.tranche,
    this.langueCours,
    this.langueCommunication,
    this.inscritLe,
    this.accesJusquAu,
    this.foyerId,
    this.titulaire = false,
    this.tuteur,
    this.admission,
    this.progression,
  });

  /// Lit la fiche rendue par `fiche_eleve_direction` ; nulle quand le serveur
  /// ne rend rien (aucun eleve de cet identifiant). Pure, pour les tests.
  static FicheEleveDirection? depuisJson(Object? json) {
    if (json is! Map) return null;
    final Object? i = json['identite'];
    if (i is! Map || i['id'] is! String) return null;
    DateTime? date(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    int entier(Object? v) => (v is num) ? v.toInt() : 0;

    final Object? a = json['admission'];
    final Object? p = json['presences'];
    final Object? g = json['progression'];
    return FicheEleveDirection(
      id: i['id'] as String,
      matricule: _texte(i['matricule']) ?? '',
      etatCompte: _texte(i['etat_compte']) ?? '',
      prenom: _texte(i['prenom']),
      nom: _texte(i['nom']),
      genre: _texte(i['genre']),
      tranche: _texte(i['tranche']),
      langueCours: _texte(i['langue_cours']),
      langueCommunication: _texte(i['langue_communication']),
      inscritLe: date(i['inscrit_le']),
      accesJusquAu: date(i['acces_jusqu_au']),
      foyerId: _texte(i['foyer_id']),
      titulaire: i['est_titulaire'] == true,
      tuteur: TuteurFiche.depuisJson(json['tuteur']),
      admission: a is Map
          ? AdmissionFiche(
              age: (a['age'] as num?)?.toInt(),
              niveau: _texte(a['niveau']),
              objectif: _texte(a['objectif']),
              langue: _texte(a['langue']),
              langueSecours: _texte(a['langue_secours']),
              langueAutre: _texte(a['langue_autre']),
              moments: <String>[
                for (final Object? m
                    in a['moments'] is List
                        ? a['moments'] as List<Object?>
                        : const <Object?>[])
                  if (m is String) m,
              ],
              riwaya: _texte(a['riwaya']),
              riwayaAutre: _texte(a['riwaya_autre']),
              memorise: _texte(a['memorise']),
              juz: <int>[
                for (final Object? n
                    in a['juz'] is List
                        ? a['juz'] as List<Object?>
                        : const <Object?>[])
                  if (n is num) n.toInt(),
              ],
              sourates: <String>[
                for (final Object? n
                    in a['sourates'] is List
                        ? a['sourates'] as List<Object?>
                        : const <Object?>[])
                  if (n is String) n,
              ],
              source: _texte(a['source']),
            )
          : null,
      classes: <ClasseFiche>[
        for (final Object? c
            in json['classes'] is List
                ? json['classes'] as List<Object?>
                : const <Object?>[])
          if (c is Map && c['id'] is String)
            ClasseFiche(
              id: c['id'] as String,
              libelle: _texte(c['libelle']) ?? '',
              fuseau: _texte(c['fuseau']) ?? 'Asia/Riyadh',
              depuis: date(c['depuis']),
              enseignantId: c['enseignant'] is Map
                  ? _texte((c['enseignant'] as Map)['id'])
                  : null,
              enseignantPrenom: c['enseignant'] is Map
                  ? _texte((c['enseignant'] as Map)['prenom'])
                  : null,
              enseignantNom: c['enseignant'] is Map
                  ? _texte((c['enseignant'] as Map)['nom'])
                  : null,
              creneaux: <CreneauFiche>[
                for (final Object? k
                    in c['creneaux'] is List
                        ? c['creneaux'] as List<Object?>
                        : const <Object?>[])
                  if (k is Map && k['jour'] is num && k['heure'] is num)
                    CreneauFiche(
                      jour: (k['jour'] as num).toInt(),
                      heure: (k['heure'] as num).toInt(),
                      dureeMinutes: (k['duree'] as num?)?.toInt(),
                    ),
              ],
            ),
      ],
      presences: PresencesFiche(
        total: p is Map ? entier(p['total']) : 0,
        presents: p is Map ? entier(p['presents']) : 0,
        retards: p is Map ? entier(p['retards']) : 0,
        absents: p is Map ? entier(p['absents']) : 0,
        excuses: p is Map ? entier(p['excuses']) : 0,
        dernieres: <SeanceFiche>[
          for (final Object? s
              in p is Map && p['dernieres'] is List
                  ? p['dernieres'] as List<Object?>
                  : const <Object?>[])
            if (s is Map && date(s['debut']) != null)
              SeanceFiche(
                debut: date(s['debut'])!,
                etat: _texte(s['etat']) ?? '',
              ),
        ],
      ),
      progression: g is Map && _texte(g['etape']) != null
          ? ProgressionFiche(
              etape: _texte(g['etape'])!,
              ordre: (g['ordre'] as num?)?.toInt(),
              cycle: _texte(g['cycle']),
              depuis: date(g['depuis']),
              dateLimite: date(g['date_limite']),
              rythme: _texte(g['rythme']),
            )
          : null,
    );
  }

  /// L'identifiant de profil de l'eleve.
  final String id;

  /// Le matricule.
  final String matricule;

  /// L'etat du compte, tel que la base le dit.
  final String etatCompte;

  /// Le prenom ; nul sous masquage d'identite.
  final String? prenom;

  /// Le nom ; nul sous masquage d'identite.
  final String? nom;

  /// Le genre (`female`, `male`).
  final String? genre;

  /// `enfant` ou `adulte`.
  final String? tranche;

  /// La langue de cours choisie.
  final String? langueCours;

  /// La langue de communication du compte.
  final String? langueCommunication;

  /// La date d'inscription.
  final DateTime? inscritLe;

  /// La fin d'acces d'un compte provisoire.
  final DateTime? accesJusquAu;

  /// Le foyer.
  final String? foyerId;

  /// Vrai pour un adulte titulaire qui apprend pour lui-meme.
  final bool titulaire;

  /// Le tuteur, s'il y en a un.
  final TuteurFiche? tuteur;

  /// Les reponses de l'admission.
  final AdmissionFiche? admission;

  /// Les classes actives.
  final List<ClasseFiche> classes;

  /// Les presences.
  final PresencesFiche presences;

  /// La progression, quand l'eleve a une etape.
  final ProgressionFiche? progression;

  /// Prenom et nom, ou vide.
  String get libelle => <String?>[
    prenom,
    nom,
  ].whereType<String>().where((String s) => s.isNotEmpty).join(' ');
}

String? _texte(Object? v) {
  if (v is! String) return null;
  final String s = v.trim();
  return s.isEmpty ? null : s;
}

/// La lecture de la fiche.
abstract interface class PortFicheEleveDirection {
  /// La fiche de l'eleve [eleveId] ; `null` quand le serveur n'en connait pas.
  Future<FicheEleveDirection?> lire(String eleveId);
}

/// La source de la fiche, posee par `main.dart` ; `null` hors production.
final Provider<PortFicheEleveDirection?> portFicheEleveDirectionProvider =
    Provider<PortFicheEleveDirection?>((Ref _) => null);

/// La fiche d'un eleve ; une source absente est une erreur, jamais une fiche
/// vide.
final FutureProviderFamily<FicheEleveDirection?, String>
ficheEleveDirectionProvider =
    FutureProvider.family<FicheEleveDirection?, String>((
      Ref ref,
      String eleveId,
    ) async {
      final PortFicheEleveDirection? port = ref.watch(
        portFicheEleveDirectionProvider,
      );
      if (port == null) {
        throw StateError('fiche eleve : aucune source');
      }
      return port.lire(eleveId);
    });
