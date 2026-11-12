/// SUIVI-ELEVE (07/11/2026) : ou en est l'eleve sur le programme, pour lui ou
/// pour sa famille.
///
/// SOCLE-PROGRAMME (lot 1 de la charte, 12/11/2026) : le serveur decide de
/// tout par LA lecture unique de l'etape de l'eleve (`etape_eleve_lecture`,
/// migration 20261123900000) : qui lit, l'etape en cours, le chemin des
/// etapes de son niveau pour sa tranche d'age, la date d'entree dans l'etape,
/// sa duree prevue et SA date limite (depuis l'entree dans l'etape), l'horizon
/// du niveau (somme des etapes restantes) et la vitesse ; date limite, horizon
/// et vitesse sont retenus pour l'enfant de 6 a 9 ans qui lit pour lui-meme. **Rien n'est calcule ici** :
/// le client lit [Rythme] et les dates tels que la base les rend.
/// `suivi_pedagogique_eleve` reste en base jusqu'au lot 10, plus appelee.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

/// La vitesse de l'eleve sur son etape, calculee par le serveur.
///
/// Seuils du garde-cap (07/11/2026), sur les regles deja decidees : il n'y a
/// pas d'etat « en avance », rien dans le programme ne le mesure.
enum Rythme {
  /// Le temps ecoule tient dans la duree prevue.
  dansLesTemps('dans_les_temps'),

  /// Au-dela de la duree prevue, avant la date limite.
  auDelaDuPrevu('au_dela_du_prevu'),

  /// La date limite est passee.
  dateLimiteDepassee('date_limite_depassee'),

  /// Pas de date de debut ou pas de duree : la ligne se cache.
  inconnu('inconnu');

  const Rythme(this.valeurSql);

  /// La valeur rendue par la base.
  final String valeurSql;

  /// Lit une valeur de la base ; une valeur inconnue rend [inconnu], jamais
  /// un rythme suppose.
  static Rythme depuisSql(Object? valeur) {
    for (final Rythme r in Rythme.values) {
      if (r.valeurSql == valeur) return r;
    }
    return Rythme.inconnu;
  }
}

/// Le suivi pedagogique d'un eleve, tel que la base le rend.
@immutable
class SuiviPedagogique {
  /// Cree un suivi.
  const SuiviPedagogique({
    required this.etapeNom,
    required this.etapeOrdre,
    this.objectifs = const <String>[],
    this.dureePrevueSemaines,
    this.dateLimite,
    this.semainesEcoulees,
    this.rythme = Rythme.inconnu,
    this.pageReprise,
    this.sourates,
    this.niveauNom,
    this.matierePrincipale,
    this.matiereSecondaire,
    this.entreeLe,
    this.dateLimiteSemaines,
    this.horizon,
    this.chemin = const <EtapeDuChemin>[],
    this.eleveVoitDates = false,
    this.enAttenteEntretien = false,
  });

  /// L'eleve est en classe, mais son etape attend l'entretien de lecture avec
  /// la direction (il a declare savoir lire) : aucune etape n'est supposee.
  const SuiviPedagogique.attenteEntretien()
    : etapeNom = '',
      etapeOrdre = null,
      objectifs = const <String>[],
      dureePrevueSemaines = null,
      dateLimite = null,
      semainesEcoulees = null,
      rythme = Rythme.inconnu,
      pageReprise = null,
      sourates = null,
      niveauNom = null,
      matierePrincipale = null,
      matiereSecondaire = null,
      entreeLe = null,
      dateLimiteSemaines = null,
      horizon = null,
      chemin = const <EtapeDuChemin>[],
      eleveVoitDates = false,
      enAttenteEntretien = true;

  /// Lit la reponse de `etape_eleve_lecture` (jsonb). Pure, pour les tests ;
  /// nulle quand l'eleve n'a pas encore d'etape ou que la reponse est
  /// illisible. Une valeur absente reste absente : jamais supposee.
  static SuiviPedagogique? depuisLecture(Object? brut) {
    if (brut is! Map) return null;
    if (brut['attente'] == 'entretien_de_lecture') {
      return const SuiviPedagogique.attenteEntretien();
    }
    final Object? etape = brut['etape'];
    if (etape is! Map) return null;
    final String nom = '${etape['nom'] ?? ''}'.trim();
    if (nom.isEmpty) return null;
    final Object? niveau = brut['niveau'];
    final Map<Object?, Object?> n = niveau is Map
        ? niveau
        : const <Object?, Object?>{};
    final Object? page = brut['page_reprise'];
    final int? pageLue = page is num ? page.toInt() : null;
    final Object? sourates = brut['sourates'];
    final Object? chemin = brut['chemin'];
    return SuiviPedagogique(
      etapeNom: nom,
      etapeOrdre: _entier(etape['ordre']),
      objectifs: _textes(etape['objectifs']),
      dureePrevueSemaines: _entier(etape['duree_prevue_semaines']),
      dateLimite: etape['date_limite'] is String
          ? DateTime.tryParse('${etape['date_limite']}')
          : null,
      semainesEcoulees: _entier(etape['semaines_ecoulees']),
      rythme: Rythme.depuisSql(etape['rythme']),
      pageReprise: pageLue != null && pageLue >= 1 && pageLue <= 604
          ? pageLue
          : null,
      sourates: sourates is Map
          ? SouratesValidees.depuis(sourates['validees'], sourates['total'])
          : null,
      niveauNom: _texte(n['nom']),
      matierePrincipale: _texte(etape['matiere_principale']),
      matiereSecondaire: _texte(etape['matiere_secondaire']),
      entreeLe: etape['entree_le'] is String
          ? DateTime.tryParse('${etape['entree_le']}')
          : null,
      dateLimiteSemaines: _entier(etape['date_limite_semaines']),
      horizon: n['horizon'] is String
          ? DateTime.tryParse('${n['horizon']}')
          : null,
      chemin: <EtapeDuChemin>[
        for (final Object? e in chemin is List ? chemin : const <Object?>[])
          if (EtapeDuChemin.depuis(e) case final EtapeDuChemin lue) lue,
      ],
      eleveVoitDates: brut['eleve_voit_dates'] == true,
    );
  }

  static String? _texte(Object? v) {
    final String lu = '${v ?? ''}'.trim();
    return lu.isEmpty ? null : lu;
  }

  static List<String> _textes(Object? v) => <String>[
    for (final Object? o in v is List ? v : const <Object?>[])
      if ('${o ?? ''}'.trim().isNotEmpty) '$o'.trim(),
  ];

  /// Lit une ligne de `suivi_pedagogique_eleve`. Pure, pour les tests ; nulle
  /// quand la ligne est illisible (aucune etape).
  static SuiviPedagogique? depuisJson(Object? brut) {
    final Object? ligne = brut is List
        ? (brut.isEmpty ? null : brut.first)
        : brut;
    if (ligne is! Map) return null;
    final String nom = '${ligne['etape_nom'] ?? ''}'.trim();
    if (nom.isEmpty) return null;
    final Object? page = ligne['page_reprise'];
    final int? pageLue = page is num ? page.toInt() : null;
    final Object? objectifs = ligne['objectifs'];
    return SuiviPedagogique(
      etapeNom: nom,
      etapeOrdre: _entier(ligne['etape_ordre']),
      objectifs: <String>[
        for (final Object? o
            in objectifs is List ? objectifs : const <Object?>[])
          if ('${o ?? ''}'.trim().isNotEmpty) '$o'.trim(),
      ],
      dureePrevueSemaines: _entier(ligne['duree_prevue_semaines']),
      dateLimite: DateTime.tryParse('${ligne['date_limite']}'),
      semainesEcoulees: _entier(ligne['semaines_ecoulees']),
      rythme: Rythme.depuisSql(ligne['rythme']),
      pageReprise: pageLue != null && pageLue >= 1 && pageLue <= 604
          ? pageLue
          : null,
      sourates: SouratesValidees.depuis(
        ligne['sourates_validees'],
        ligne['sourates_total'],
      ),
    );
  }

  static int? _entier(Object? v) => v is num ? v.toInt() : null;

  /// Le nom de l'etape en cours.
  final String etapeNom;

  /// Son rang dans le programme.
  final int? etapeOrdre;

  /// Ses objectifs, dans l'ordre.
  final List<String> objectifs;

  /// La duree prevue pour la tranche d'age de l'eleve, en semaines.
  final int? dureePrevueSemaines;

  /// La date limite de l'etape (entree dans l'etape + sa date limite), nulle
  /// quand le serveur la retient (enfant de 6 a 9 ans) ou ne la connait pas.
  final DateTime? dateLimite;

  /// Les semaines ecoulees depuis le debut de l'etape.
  final int? semainesEcoulees;

  /// La vitesse, calculee par le serveur.
  final Rythme rythme;

  /// La derniere page du Mushaf presentee en classe (CAHIER-C1), nulle quand
  /// rien n'a ete presente : la ligne se cache.
  final int? pageReprise;

  /// SOURATES (directeur, 11/11/2026, option A) : les sourates des bases
  /// validees au cahier, sur leur total ; nulle quand le serveur ne les rend
  /// pas (jamais un 0 invente : l'anneau reste dore).
  final SouratesValidees? sourates;

  /// SOCLE-PROGRAMME : le nom du niveau (« Les bases »), nul s'il manque.
  final String? niveauNom;

  /// La matiere principale de l'etape pour la tranche d'age de l'eleve.
  final String? matierePrincipale;

  /// La matiere secondaire, nulle quand il n'y en a pas encore (6-9 ans,
  /// avant la chadda : le livre seul).
  final String? matiereSecondaire;

  /// Le jour d'entree dans l'etape.
  final DateTime? entreeLe;

  /// La date limite de l'etape, en semaines depuis l'entree dans l'etape.
  final int? dateLimiteSemaines;

  /// L'horizon du niveau : la fin au plus tard des etapes restantes (simple
  /// horizon, pas une date de plus a tenir). Nul quand le serveur le retient.
  final DateTime? horizon;

  /// Le chemin des etapes du niveau, dans l'ordre, la sienne marquee.
  final List<EtapeDuChemin> chemin;

  /// Rendu par le serveur, independant de qui lit : l'eleve lui-meme voit-il
  /// ses dates et ses durees ? Faux de 6 a 9 ans et quand la tranche est
  /// inconnue ; vrai des 10 ans et pour un adulte.
  final bool eleveVoitDates;

  /// L'etape attend l'entretien de lecture avec la direction.
  final bool enAttenteEntretien;
}

/// Ou en est une etape du chemin, pour l'eleve.
enum StatutEtape {
  /// Une etape d'avant la sienne (jamais « Etape validee » : ce mot est
  /// reserve au resultat d'une evaluation).
  precedente('precedente'),

  /// Son etape.
  enCours('en_cours'),

  /// Une etape d'apres.
  aVenir('a_venir');

  const StatutEtape(this.valeurSql);

  /// La valeur rendue par la base.
  final String valeurSql;
}

/// Une etape du chemin de l'eleve, telle que la base la rend.
@immutable
class EtapeDuChemin {
  /// Cree une etape du chemin.
  const EtapeDuChemin({
    required this.ordre,
    required this.nom,
    required this.statut,
    this.objectifs = const <String>[],
    this.dureePrevueSemaines,
    this.dateLimiteSemaines,
  });

  /// Lit une etape ; nulle si elle est illisible (nom ou statut inconnu).
  static EtapeDuChemin? depuis(Object? brut) {
    if (brut is! Map) return null;
    final String nom = '${brut['nom'] ?? ''}'.trim();
    final Object? ordre = brut['ordre'];
    StatutEtape? statut;
    for (final StatutEtape s in StatutEtape.values) {
      if (s.valeurSql == brut['statut']) statut = s;
    }
    if (nom.isEmpty || ordre is! num || statut == null) return null;
    final Object? objectifs = brut['objectifs'];
    final Object? prevue = brut['duree_prevue_semaines'];
    final Object? limite = brut['date_limite_semaines'];
    return EtapeDuChemin(
      ordre: ordre.toInt(),
      nom: nom,
      statut: statut,
      objectifs: <String>[
        for (final Object? o
            in objectifs is List ? objectifs : const <Object?>[])
          if ('${o ?? ''}'.trim().isNotEmpty) '$o'.trim(),
      ],
      dureePrevueSemaines: prevue is num ? prevue.toInt() : null,
      dateLimiteSemaines: limite is num ? limite.toInt() : null,
    );
  }

  /// Son rang dans le niveau.
  final int ordre;

  /// Son nom.
  final String nom;

  /// Franchie, en cours ou a venir.
  final StatutEtape statut;

  /// Ses objectifs, dans l'ordre.
  final List<String> objectifs;

  /// Sa duree prevue en semaines, pour la tranche d'age de l'eleve.
  final int? dureePrevueSemaines;

  /// Sa date limite en semaines depuis l'entree dans l'etape.
  final int? dateLimiteSemaines;
}

/// Les sourates des bases validees d'un eleve, telles que le serveur les
/// compte (`suivi_pedagogique_eleve`) : jamais calculees sur l'appareil.
@immutable
class SouratesValidees {
  /// Cree le compte.
  const SouratesValidees({required this.validees, required this.total})
    : assert(total > 0 && validees >= 0 && validees <= total);

  /// Lit le compte ; nul si l'une des deux valeurs manque ou est incoherente.
  static SouratesValidees? depuis(Object? validees, Object? total) {
    if (validees is! num || total is! num) return null;
    final int v = validees.toInt();
    final int t = total.toInt();
    if (t <= 0 || v < 0 || v > t) return null;
    return SouratesValidees(validees: v, total: t);
  }

  /// Le nombre de sourates validees.
  final int validees;

  /// Le nombre de sourates des bases (17).
  final int total;

  /// Toutes les sourates des bases sont validees.
  bool get toutes => validees == total;
}

/// Le port.
abstract interface class PortSuiviPedagogique {
  /// Le suivi de [eleveId] ; nul quand l'eleve n'a pas de Classe active ou pas
  /// d'etape publiee.
  Future<SuiviPedagogique?> pourEleve(String eleveId);
}

/// Le port : absent tant que `main.dart` ne le pose pas ; sans lui, le bloc
/// n'est pas pose.
final Provider<PortSuiviPedagogique?> portSuiviPedagogiqueProvider =
    Provider<PortSuiviPedagogique?>((Ref _) => null);

/// Le suivi d'un eleve ; `null` sans port ou sans etape.
final FutureProviderFamily<SuiviPedagogique?, String> suiviPedagogiqueProvider =
    FutureProvider.family<SuiviPedagogique?, String>((Ref ref, String eleveId) {
      final PortSuiviPedagogique? port = ref.watch(
        portSuiviPedagogiqueProvider,
      );
      if (port == null) return Future<SuiviPedagogique?>.value();
      return port.pourEleve(eleveId);
    }, retry: (int _, Object _) => null);
