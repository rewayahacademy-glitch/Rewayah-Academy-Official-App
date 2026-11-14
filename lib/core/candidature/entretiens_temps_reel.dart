/// SALLE2-ENTRETIEN (14/11/2026) : les entretiens en temps reel, et les
/// entretiens du jour de la personne qui les mene.
///
/// Le signal : la migration 20261125820000 diffuse, apres tout changement de
/// creneau ou d'entretien, un message sans contenu sur le canal public
/// `entretiens` (Supabase Realtime, diffusion). Il ne porte aucune donnee :
/// chacun relit ses listes par les RPC, qui gardent leurs gardes. Avant, une
/// reservation n'apparaissait chez la direction qu'au rechargement (le
/// directeur, 14/11 : « plusieurs minutes »).
///
/// Les entretiens du jour : `mes_entretiens()` (V1-a) rend a la direction
/// ceux de son cote et a toute personne ceux ou elle participe (enseignant
/// compris). Le bouton « Rejoindre l'entretien » ouvre la meme seance que
/// celle du candidat (`/salle`, billet en `extra`).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'creneaux_direction.dart';
import 'entretien_candidat.dart';
import 'port_entretiens_direction.dart';

/// Le nom du canal de diffusion (le meme que dans la migration).
const String canalEntretiens = 'entretiens';

/// La source du signal ; `null` : aucun temps reel (tests, demonstration).
final Provider<Stream<void> Function()?> sourceSignalEntretiensProvider =
    Provider<Stream<void> Function()?>((Ref _) => null);

/// Le signal servi par Supabase Realtime : une diffusion sur [canalEntretiens].
Stream<void> Function() signalEntretiensSupabase(SupabaseClient client) {
  int rang = 0;
  return () {
    late final StreamController<void> flux;
    RealtimeChannel? canal;
    flux = StreamController<void>(
      onListen: () {
        rang += 1;
        canal = client
            .channel(canalEntretiens)
            .onBroadcast(
              event: 'change',
              callback: (Map<String, dynamic> _) {
                if (!flux.isClosed) flux.add(null);
              },
            )
            .subscribe((RealtimeSubscribeStatus statut, Object? _) {
              // Jointure ou rejointure : tout est a relire.
              if (statut == RealtimeSubscribeStatus.subscribed &&
                  !flux.isClosed &&
                  rang > 0) {
                flux.add(null);
              }
            });
      },
      onCancel: () async {
        final RealtimeChannel? c = canal;
        canal = null;
        if (c != null) await client.removeChannel(c);
        await flux.close();
      },
    );
    return flux.stream;
  };
}

/// La veille : tant qu'un ecran l'ecoute, chaque signal fait relire les
/// entretiens et les creneaux. Sans source, ne fait rien.
final Provider<void> veilleEntretiensProvider = Provider.autoDispose<void>((
  Ref ref,
) {
  final Stream<void> Function()? source = ref.watch(
    sourceSignalEntretiensProvider,
  );
  if (source == null) return;
  final StreamSubscription<void> abonnement = source().listen(
    (_) {
      ref
        ..invalidate(monEntretienProvider)
        ..invalidate(creneauxOuvertsProvider)
        ..invalidate(creneauxDirectionProvider)
        ..invalidate(entretiensDuJourProvider)
        ..invalidate(entretiensCandidatureProvider);
    },
    // Le canal tombe : les lectures restent, la relecture reprend au retour.
    onError: (Object _) {},
  );
  ref.onDispose(abonnement.cancel);
});

/// Un entretien de la journee, vu par la personne qui le mene.
class EntretienDuJour {
  /// Cree l'entretien.
  const EntretienDuJour({
    required this.sessionId,
    required this.reference,
    required this.nom,
    required this.debut,
    required this.fin,
    required this.jeParticipe,
  });

  /// Lit une ligne de `mes_entretiens()` ; `null` si elle est illisible ou si
  /// son issue est deja consignee.
  static EntretienDuJour? depuisJson(Map<String, dynamic> j) {
    final Object? session = j['session_id'];
    final DateTime? debut = j['debut'] is String
        ? DateTime.tryParse(j['debut'] as String)?.toLocal()
        : null;
    final DateTime? fin = j['fin'] is String
        ? DateTime.tryParse(j['fin'] as String)?.toLocal()
        : null;
    if (session is! String || debut == null || fin == null) return null;
    if (j['issue'] is String) return null;
    return EntretienDuJour(
      sessionId: session,
      reference: j['reference'] is String ? j['reference'] as String : '',
      nom: j['nom_complet'] is String
          ? (j['nom_complet'] as String).trim()
          : '',
      debut: debut,
      fin: fin,
      jeParticipe: j['je_participe'] == true,
    );
  }

  /// La seance de l'entretien (celle que `/salle` ouvre).
  final String sessionId;

  /// La reference de la candidature (fiche de la direction).
  final String reference;

  /// Le nom du candidat.
  final String nom;

  /// Le debut, heure de l'appareil.
  final DateTime debut;

  /// La fin, heure de l'appareil.
  final DateTime fin;

  /// Vrai si la personne connectee mene cet entretien.
  final bool jeParticipe;

  /// Vrai quand on peut rejoindre a [maintenant] : de 10 minutes avant le
  /// debut a 15 minutes apres la fin, comme le jeton video.
  bool rejoignableA(DateTime maintenant) =>
      jeParticipe &&
      !maintenant.isBefore(debut.subtract(const Duration(minutes: 10))) &&
      maintenant.isBefore(fin.add(const Duration(minutes: 15)));

  /// Vrai si l'entretien est dans la journee : pas fini depuis plus de 15
  /// minutes et commence dans moins de 24 heures.
  bool duJourA(DateTime maintenant) =>
      maintenant.isBefore(fin.add(const Duration(minutes: 15))) &&
      debut.isBefore(maintenant.add(const Duration(hours: 24)));
}

/// La lecture des entretiens de la personne connectee ; `null` : capacite
/// indisponible (l'ecran ne montre alors rien).
final Provider<Future<List<EntretienDuJour>> Function()?>
lireEntretiensProvider = Provider<Future<List<EntretienDuJour>> Function()?>(
  (Ref _) => null,
);

/// La lecture sur Supabase : `mes_entretiens(p_jours => 1)`.
Future<List<EntretienDuJour>> Function() lireEntretiensSupabase(
  SupabaseClient client,
) => () async {
  final Object? brut = await client.rpc<Object?>(
    'mes_entretiens',
    params: <String, dynamic>{'p_jours': 1},
  );
  return <EntretienDuJour>[
    if (brut is List)
      for (final Object? l in brut)
        if (l is Map)
          if (EntretienDuJour.depuisJson(Map<String, dynamic>.from(l))
              case final EntretienDuJour e)
            e,
  ];
};

/// Les entretiens de la journee, du plus proche au plus lointain. Sans
/// lecture branchee : une liste vide (rien a montrer, rien d'invente).
final FutureProvider<List<EntretienDuJour>> entretiensDuJourProvider =
    FutureProvider.autoDispose<List<EntretienDuJour>>((Ref ref) async {
      final Future<List<EntretienDuJour>> Function()? lire = ref.watch(
        lireEntretiensProvider,
      );
      if (lire == null) return const <EntretienDuJour>[];
      final DateTime maintenant = DateTime.now();
      final List<EntretienDuJour> tous = await lire();
      return <EntretienDuJour>[
        for (final EntretienDuJour e in tous)
          if (e.duJourA(maintenant)) e,
      ]..sort(
        (EntretienDuJour a, EntretienDuJour b) => a.debut.compareTo(b.debut),
      );
    }, retry: (int _, Object _) => null);

/// Un tic toutes les 30 secondes, pour qu'un bouton « Rejoindre » apparaisse
/// a l'heure dans un ecran sans minuterie propre.
final StreamProvider<int> ticEntretiensProvider =
    StreamProvider.autoDispose<int>(
      (Ref _) =>
          Stream<int>.periodic(const Duration(seconds: 30), (int i) => i),
    );
