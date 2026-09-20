import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'echec_observation.dart';
import 'libelles_tc_g.dart';
import 'port_politique_observation.dart';

/// Ce que l'enseignant lit quand un tuteur observe sa classe.
///
/// **Le tuteur n'est jamais nomme.** L'annonce dit « Tuteur d'Amina observe »
/// et rien d'autre : l'identite du tuteur n'apporte rien a l'enseignant, et la
/// faire circuler serait exactement la PII famille que le chantier s'interdit.
/// Le prenom de l'enfant, lui, est deja celui que `teacher_roster_v` livre a
/// l'enseignant depuis la migration `0005`.
@immutable
class AnnonceObservation {
  /// Cree une annonce.
  const AnnonceObservation({
    required this.libelle,
    this.tempsRestant,
    this.enfantConcerneId,
  });

  /// Le texte lu par l'enseignant, deja compose.
  final String libelle;

  /// Ce qu'il reste au tuteur. `null` quand le serveur ne le dit pas.
  final Duration? tempsRestant;

  /// L'enfant concerne, pour l'indicateur discret de son cote.
  final String? enfantConcerneId;
}

/// Les observations en cours d'une seance, du point de vue de l'enseignant.
///
/// **Aucune notification de sortie.** Le flux cesse simplement de porter
/// l'annonce : l'enseignant qui donne cours n'a pas a etre interrompu deux fois
/// pour une visite de deux minutes (specification section 11.3).
abstract interface class PortAnnonceObservation {
  /// Le flux des annonces d'une seance. Liste vide = personne n'observe.
  Stream<List<AnnonceObservation>> annonces(String sessionId);
}

/// A quelle cadence les annonces sont relues.
///
/// Plus lent que le budget : l'indicateur de l'enseignant est discret par
/// construction, et une precision a la seconde y serait une distraction pendant
/// qu'il enseigne.
const Duration cadenceAnnonceObservation = Duration(seconds: 10);

/// L'implementation reelle.
///
/// La fonction `annonces_observation` n'existe pas encore : voir la section
/// DEMANDE SQL de `docs/teaching-core/TC_CONTRACT_REQUEST_G.md`. Elle ne rend
/// **que** les visites de role `guardian_observer` : une visite incognito qui
/// apparaitrait ici cesserait d'etre incognito.
class AnnonceObservationSupabase implements PortAnnonceObservation {
  /// Cree le service.
  const AnnonceObservationSupabase(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<AnnonceObservation>> annonces(String sessionId) {
    final StreamController<List<AnnonceObservation>> sortie =
        StreamController<List<AnnonceObservation>>();
    Timer? minuterie;

    Future<void> lire() async {
      try {
        final Object? reponse = await _client.rpc<Object?>(
          'annonces_observation',
          params: <String, dynamic>{'p_session_id': sessionId},
        );
        if (!sortie.isClosed) {
          sortie.add(_lire(reponse));
        }
      } on PostgrestException catch (e) {
        // Une annonce absente n'interrompt pas un cours : l'enseignant garde un
        // indicateur vide, et la lecture suivante a lieu comme prevu. C'est le
        // meme choix que `presenceSeanceProvider`, pour la meme raison.
        if (!sortie.isClosed &&
            motifDeErreurPostgrest(e) == MotifEchecObservation.reseau) {
          sortie.add(const <AnnonceObservation>[]);
        }
      } on Object {
        if (!sortie.isClosed) {
          sortie.add(const <AnnonceObservation>[]);
        }
      }
    }

    sortie
      ..onListen = () {
        minuterie = Timer.periodic(
          cadenceAnnonceObservation,
          (Timer _) => unawaited(lire()),
        );
        unawaited(lire());
      }
      ..onCancel = () {
        minuterie?.cancel();
        return sortie.close();
      };
    return sortie.stream;
  }

  List<AnnonceObservation> _lire(Object? reponse) {
    if (reponse is! List<dynamic>) {
      return const <AnnonceObservation>[];
    }
    return <AnnonceObservation>[
      for (final Object? ligne in reponse)
        if (ligne is Map<String, dynamic>) annonceDepuisJson(ligne),
    ];
  }
}

/// Compose une annonce a partir d'une ligne du serveur.
///
/// **Le libelle est compose ici, pas en base.** Une phrase stockee en SQL
/// echapperait a slang et ne se traduirait jamais ; le serveur livre donc un
/// prenom et un nombre de secondes, et le francais se fabrique du cote qui sait
/// parler francais.
@visibleForTesting
AnnonceObservation annonceDepuisJson(Map<String, dynamic> json) {
  final int? restant = (json['restant_secondes'] as num?)?.toInt();
  return AnnonceObservation(
    libelle: LibellesTcG.tuteurObserve(
      json['enfant_prenom'] as String? ?? '',
    ),
    tempsRestant: restant == null ? null : Duration(seconds: restant),
    enfantConcerneId: json['enfant_profile_id'] as String?,
  );
}

/// Le service d'annonce d'observation employe par l'application.
final Provider<PortAnnonceObservation> portAnnonceObservationProvider =
    Provider<PortAnnonceObservation>(
      (Ref ref) => AnnonceObservationSupabase(Supabase.instance.client),
    );

/// Les annonces d'observation d'une seance, relues a la cadence discrete.
final StreamProviderFamily<List<AnnonceObservation>, String>
annoncesObservationProvider =
    StreamProvider.family<List<AnnonceObservation>, String>(
      (Ref ref, String sessionId) =>
          ref.watch(portAnnonceObservationProvider).annonces(sessionId),
      isAutoDispose: true,
    );
