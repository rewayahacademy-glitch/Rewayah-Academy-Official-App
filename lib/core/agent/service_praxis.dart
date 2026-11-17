import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// L'etat d'une cle de Praxis, tel que la base le calcule (jamais compare
/// ici a l'horloge du poste : meme regle que pour les jetons d'observation).
enum EtatClePraxis {
  /// Vivante : elle ouvre encore des appels.
  active,

  /// Revoquee a la main. Definitif.
  revoquee,

  /// Arrivee a son terme.
  expiree;

  /// Lit la valeur rendue par `direction_praxis_etat()`.
  static EtatClePraxis depuisSql(String? valeur) => switch (valeur) {
    'active' => EtatClePraxis.active,
    'revoquee' => EtatClePraxis.revoquee,
    // Un etat inconnu se traite comme mort : on ne laisse jamais passer par
    // defaut ce qu'on n'a pas su lire.
    _ => EtatClePraxis.expiree,
  };
}

/// L'usage d'une cle : une conversation dirigee, ou une routine autonome.
enum UsageClePraxis {
  /// La direction parle a Praxis dans un chat ; il agit quand on le lui dit.
  chat,

  /// Praxis travaille seul a heures fixes (demande le mode autonome).
  routine;

  /// Lit la valeur de la base.
  static UsageClePraxis depuisSql(String? valeur) =>
      valeur == 'routine' ? UsageClePraxis.routine : UsageClePraxis.chat;

  /// La valeur envoyee a la base.
  String get sql => name;
}

/// Une cle de Praxis, vue par la direction. Le secret n'y figure jamais : il
/// n'existe qu'une fois, dans la reponse de l'emission.
@immutable
class ClePraxis {
  /// Cree une cle.
  const ClePraxis({
    required this.id,
    required this.libelle,
    required this.prefixe,
    required this.usage,
    required this.emiseLe,
    required this.expireLe,
    required this.etat,
    this.derniereUtilisationLe,
    this.revoqueeLe,
    this.motifRevocation,
  });

  /// Lit une cle de `direction_praxis_etat()`.
  factory ClePraxis.depuisJson(Map<String, dynamic> json) => ClePraxis(
    id: json['id'] as String? ?? '',
    libelle: json['libelle'] as String? ?? '',
    prefixe: json['prefixe'] as String? ?? '',
    usage: UsageClePraxis.depuisSql(json['usage'] as String?),
    emiseLe: DateTime.parse(json['emiseLe'] as String).toLocal(),
    expireLe: DateTime.parse(json['expireLe'] as String).toLocal(),
    etat: EtatClePraxis.depuisSql(json['etat'] as String?),
    derniereUtilisationLe: DateTime.tryParse(
      json['derniereUtilisationLe'] as String? ?? '',
    )?.toLocal(),
    revoqueeLe: DateTime.tryParse(json['revoqueeLe'] as String? ?? '')
        ?.toLocal(),
    motifRevocation: json['motifRevocation'] as String?,
  );

  /// Identifiant de la ligne.
  final String id;

  /// Ce que la direction a ecrit en emettant.
  final String libelle;

  /// Les douze premiers signes du secret : assez pour reconnaitre une ligne.
  final String prefixe;

  /// Chat ou routine.
  final UsageClePraxis usage;

  /// Emission.
  final DateTime emiseLe;

  /// Terme.
  final DateTime expireLe;

  /// Active, revoquee ou expiree, selon la base.
  final EtatClePraxis etat;

  /// Derniere utilisation, si elle a servi.
  final DateTime? derniereUtilisationLe;

  /// Revocation, quand elle a eu lieu.
  final DateTime? revoqueeLe;

  /// Le motif ecrit en revoquant.
  final String? motifRevocation;

  /// Vrai quand cette cle n'a jamais servi.
  bool get jamaisServie => derniereUtilisationLe == null;
}

/// Les reglages de Praxis et ses cles.
@immutable
class EtatPraxis {
  /// Cree l'etat.
  const EtatPraxis({
    required this.actif,
    required this.autonome,
    required this.envoisParHeure,
    required this.cles,
    this.essaiFils = const <String>[],
    this.donneesReelles = false,
    this.derniereRoutine,
  });

  /// Lit la reponse de `direction_praxis_etat()`.
  factory EtatPraxis.depuisJson(Map<String, dynamic> json) => EtatPraxis(
    actif: json['actif'] as bool? ?? false,
    autonome: json['autonome'] as bool? ?? false,
    envoisParHeure: (json['envoisParHeure'] as num?)?.toInt() ?? 30,
    donneesReelles: json['donneesReelles'] as bool? ?? false,
    derniereRoutine: TirRoutinePraxis.depuisJson(json['derniereRoutine']),
    essaiFils: (json['essaiFils'] as List<dynamic>? ?? <dynamic>[])
        .whereType<String>()
        .toList(growable: false),
    cles: (json['cles'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ClePraxis.depuisJson)
        .toList(growable: false),
  );

  /// Praxis est allume.
  final bool actif;

  /// Praxis peut travailler seul (cles « routine »).
  final bool autonome;

  /// Plafond d'envois par heure, de 1 a 120.
  final int envoisParHeure;

  /// Les cles, les plus recentes d'abord (100 au plus).
  final List<ClePraxis> cles;

  /// Les conversations d'essai (MODE ESSAI) : vide, pas de mode essai ;
  /// sinon Praxis ne voit que celles-la et n'annonce rien.
  final List<String> essaiFils;

  /// Les donnees reelles sont ouvertes (PX-2) : faux a l'installation ; tant
  /// qu'il est faux, Praxis ne lit aucun dossier ni aucune conversation reels.
  final bool donneesReelles;

  /// Le dernier tir de la routine horaire ; `null` tant qu'aucun n'a ete note.
  final TirRoutinePraxis? derniereRoutine;
}

/// Le dernier tir de la routine horaire (PRAXIS-ROUTINE) : ce que le directeur
/// voit pour savoir si la routine tourne. `issue` : `ok`, `rien_a_faire` ou
/// `erreur`. Aucune donnee de personne : des compteurs et une note courte.
@immutable
class TirRoutinePraxis {
  /// Cree un tir.
  const TirRoutinePraxis({
    required this.termineLe,
    required this.issue,
    required this.filsLus,
    required this.messagesEnvoyes,
    required this.passesEquipe,
    required this.refus,
    this.note,
  });

  /// Lit `derniereRoutine` de `direction_praxis_etat()` ; `null` si absent
  /// ou illisible (aucun tir note, ou serveur sans la migration du pouls).
  static TirRoutinePraxis? depuisJson(Object? brut) {
    if (brut is! Map<String, dynamic>) return null;
    final DateTime? fin = DateTime.tryParse(brut['termineLe'] as String? ?? '');
    if (fin == null) return null;
    return TirRoutinePraxis(
      termineLe: fin.toLocal(),
      issue: brut['issue'] as String? ?? '',
      filsLus: (brut['filsLus'] as num?)?.toInt() ?? 0,
      messagesEnvoyes: (brut['messagesEnvoyes'] as num?)?.toInt() ?? 0,
      passesEquipe: (brut['passesEquipe'] as num?)?.toInt() ?? 0,
      refus: (brut['refus'] as num?)?.toInt() ?? 0,
      note: brut['note'] as String?,
    );
  }

  /// La fin du tir (heure de la base).
  final DateTime termineLe;

  /// `ok`, `rien_a_faire` ou `erreur`.
  final String issue;

  /// Fils lus pendant le tir.
  final int filsLus;

  /// Messages envoyes pendant le tir.
  final int messagesEnvoyes;

  /// Fils laisses a l'equipe.
  final int passesEquipe;

  /// Refus d'outil recus.
  final int refus;

  /// Une note courte de la routine (200 signes au plus).
  final String? note;
}

/// Ce que l'emission rend, une seule fois.
@immutable
class ClePraxisEmise {
  /// Cree le resultat d'une emission.
  const ClePraxisEmise({
    required this.secret,
    required this.id,
    required this.expireLe,
  });

  /// Le secret en clair. **Il ne repassera jamais** : la base n'en garde que
  /// l'empreinte.
  final String secret;

  /// L'identifiant de la ligne creee.
  final String id;

  /// Le terme de la cle.
  final DateTime expireLe;
}

/// Une ligne de « Ce que Praxis a envoye ».
@immutable
class LigneJournalPraxis {
  /// Cree une ligne.
  const LigneJournalPraxis({
    required this.id,
    required this.outil,
    required this.issue,
    required this.heure,
    this.extrait,
  });

  /// Lit une ligne de `direction_praxis_journal()`.
  factory LigneJournalPraxis.depuisJson(Map<String, dynamic> json) =>
      LigneJournalPraxis(
        id: (json['id'] as num?)?.toInt() ?? 0,
        outil: json['outil'] as String? ?? '',
        issue: json['issue'] as String? ?? '',
        heure: DateTime.parse(json['heure'] as String).toLocal(),
        extrait: json['extrait'] as String?,
      );

  /// Identifiant (curseur).
  final int id;

  /// `ecrire` (un message) ou `annoncer` (une annonce).
  final String outil;

  /// `ok`, ou la cause du refus.
  final String issue;

  /// Quand.
  final DateTime heure;

  /// Au plus 300 signes de ce que Praxis a lui-meme envoye.
  final String? extrait;

  /// Vrai quand l'envoi a eu lieu.
  bool get envoye => issue == 'ok';

  /// Vrai pour une annonce.
  bool get annonce => outil == 'annoncer';
}

/// Une page du journal.
@immutable
class PageJournalPraxis {
  /// Cree une page.
  const PageJournalPraxis({required this.lignes, this.suite});

  /// Lit la reponse de `direction_praxis_journal()`.
  factory PageJournalPraxis.depuisJson(Map<String, dynamic> json) =>
      PageJournalPraxis(
        lignes: (json['lignes'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(LigneJournalPraxis.depuisJson)
            .toList(growable: false),
        suite: (json['suite'] as num?)?.toInt(),
      );

  /// Les lignes, les plus recentes d'abord.
  final List<LigneJournalPraxis> lignes;

  /// Le curseur de la page suivante ; nul a la derniere page.
  final int? suite;
}

/// L'acces de la direction a Praxis (lectures, reglages, cles).
abstract interface class ServicePraxis {
  /// L'interrupteur, le mode, le plafond et les cles.
  Future<EtatPraxis> etat();

  /// « Ce que Praxis a envoye », par pages.
  Future<PageJournalPraxis> journal({int? avant});

  /// Regle un ou plusieurs reglages (double verification exigee par la base).
  Future<void> regler({bool? actif, bool? autonome, int? envoisParHeure});

  /// Nomme les conversations d'essai (dix au plus) ; une liste vide met fin
  /// au mode essai (double verification exigee par la base).
  Future<void> reglerEssai(List<String> fils);

  /// Ouvre ou ferme les donnees reelles (double verification exigee par la
  /// base).
  Future<void> reglerDonneesReelles({required bool ouvert});

  /// Emet une cle. Rend le secret une seule fois. [cleEmission] est la cle
  /// d'idempotence : le meme appel rejoue ne remontre jamais le secret.
  Future<ClePraxisEmise> emettre({
    required String libelle,
    required UsageClePraxis usage,
    required DateTime expireLe,
    required String cleEmission,
  });

  /// Revoque une cle, avec son motif. Rend faux s'il n'y avait rien a revoquer.
  Future<bool> revoquer({
    required String id,
    required String motif,
    required String cleRevocation,
  });

  /// L'adresse du connecteur a coller dans le chat de Praxis.
  String get adresseConnecteur;
}

/// L'implementation Supabase.
class ServicePraxisSupabase implements ServicePraxis {
  /// Cree le service.
  ServicePraxisSupabase(this._client);

  final SupabaseClient _client;

  @override
  String get adresseConnecteur => '${Env.supabaseUrl}/functions/v1/praxis-mcp';

  @override
  Future<EtatPraxis> etat() async {
    final Object? rendu = await _client.rpc<Object?>('direction_praxis_etat');
    return EtatPraxis.depuisJson(
      rendu is Map<String, dynamic> ? rendu : <String, dynamic>{},
    );
  }

  @override
  Future<PageJournalPraxis> journal({int? avant}) async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_journal',
      params: <String, dynamic>{'p_limite': 20, 'p_avant': avant},
    );
    return PageJournalPraxis.depuisJson(
      rendu is Map<String, dynamic> ? rendu : <String, dynamic>{},
    );
  }

  @override
  Future<void> regler({
    bool? actif,
    bool? autonome,
    int? envoisParHeure,
  }) async {
    await _client.rpc<Object?>(
      'direction_praxis_regler',
      params: <String, dynamic>{
        'p_actif': actif,
        'p_autonome': autonome,
        'p_envois_par_heure': envoisParHeure,
      },
    );
  }

  @override
  Future<void> reglerDonneesReelles({required bool ouvert}) async {
    await _client.rpc<Object?>(
      'direction_praxis_regler_donnees_reelles',
      params: <String, dynamic>{'p_ouvert': ouvert},
    );
  }

  @override
  Future<void> reglerEssai(List<String> fils) async {
    await _client.rpc<Object?>(
      'direction_praxis_regler_essai',
      params: <String, dynamic>{'p_essai_fils': fils},
    );
  }

  @override
  Future<ClePraxisEmise> emettre({
    required String libelle,
    required UsageClePraxis usage,
    required DateTime expireLe,
    required String cleEmission,
  }) async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_emettre_cle',
      params: <String, dynamic>{
        'p_libelle': libelle,
        'p_usage': usage.sql,
        'p_expire_le': expireLe.toUtc().toIso8601String(),
        'p_cle': cleEmission,
      },
    );
    final Map<String, dynamic> ligne = rendu is Map<String, dynamic>
        ? rendu
        : <String, dynamic>{};
    return ClePraxisEmise(
      secret: ligne['secret'] as String? ?? '',
      id: ligne['id'] as String? ?? '',
      expireLe: DateTime.parse(ligne['expireLe'] as String).toLocal(),
    );
  }

  @override
  Future<bool> revoquer({
    required String id,
    required String motif,
    required String cleRevocation,
  }) async {
    final Object? rendu = await _client.rpc<Object?>(
      'direction_praxis_revoquer_cle',
      params: <String, dynamic>{
        'p_id': id,
        'p_motif': motif,
        'p_cle': cleRevocation,
      },
    );
    return rendu == true;
  }
}

/// Le service de la direction pour Praxis.
final Provider<ServicePraxis> servicePraxisProvider = Provider<ServicePraxis>(
  (Ref ref) => ServicePraxisSupabase(Supabase.instance.client),
);
