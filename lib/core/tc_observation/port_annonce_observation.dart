import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/elision.dart';
import '../i18n/strings.g.dart';
import '../reseau/sondage_regulier.dart';
import 'echec_observation.dart';
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
    this.prenomEnfant = '',
  });

  /// Le texte lu par l'enseignant, deja compose.
  final String libelle;

  /// Ce qu'il reste au tuteur. `null` quand le serveur ne le dit pas.
  final Duration? tempsRestant;

  /// L'enfant concerne, pour l'indicateur discret de son cote.
  final String? enfantConcerneId;

  /// Le prenom seul, sans la phrase autour.
  ///
  /// [libelle] porte la phrase entiere et reste la forme lue quand UN tuteur
  /// observe. Des que deux tuteurs observent en meme temps, l'indicateur
  /// n'affiche plus des phrases empilees mais des prenoms tronques qui
  /// glissent derriere un oeil : il lui faut donc le prenom NU, que `libelle`
  /// ne permet pas de recuperer sans defaire une traduction.
  ///
  /// Vide quand le serveur ne le dit pas : l'indicateur retombe alors sur le
  /// compteur seul, jamais sur une chaine vide affichee.
  final String prenomEnfant;
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
/// DEMANDE SQL de `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_G.md`. Elle ne rend
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
    SondageRegulier? sondage;

    Future<bool> lire() async {
      try {
        final Object? reponse = await _client.rpc<Object?>(
          'annonces_observation',
          params: <String, dynamic>{'p_session_id': sessionId},
        );
        if (!sortie.isClosed) {
          sortie.add(_lire(reponse));
        }
        return true;
      } on PostgrestException catch (e) {
        // Une annonce absente n'interrompt pas un cours : l'enseignant garde un
        // indicateur vide, et la lecture suivante a lieu comme prevu. C'est le
        // meme choix que `presenceSeanceProvider`, pour la meme raison.
        if (!sortie.isClosed &&
            motifDeErreurPostgrest(e) == MotifEchecObservation.reseau) {
          sortie.add(const <AnnonceObservation>[]);
        }
        return false;
      } on Object {
        if (!sortie.isClosed) {
          sortie.add(const <AnnonceObservation>[]);
        }
        return false;
      }
    }

    sortie
      ..onListen = () {
        // R14 : decalage au hasard et recul apres echec, cadence moyenne
        // inchangee (`SondageRegulier`).
        sondage = SondageRegulier(
          cadence: cadenceAnnonceObservation,
          lire: lire,
        )..demarrer();
      }
      ..onCancel = () {
        sondage?.arreter();
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
  final String prenom = json['enfant_prenom'] as String? ?? '';
  return AnnonceObservation(
    libelle: t.tc.observation.annonce.tuteurObserve(
      dePrenomEnfant: deDevant(prenom),
    ),
    tempsRestant: restant == null ? null : Duration(seconds: restant),
    enfantConcerneId: json['enfant_profile_id'] as String?,
    // Le prenom est conserve EN PLUS de la phrase : l'indicateur agrege en a
    // besoin nu, et le defaire de `libelle` reviendrait a analyser une
    // traduction.
    prenomEnfant: prenom,
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

/// Ce que l'enfant observe apprend, et lui seul : que SON tuteur regarde.
///
/// **Un booleen, pas une liste, et ce n'est pas une economie.** La
/// specification 11.3 interdit qu'un enfant apprenne que le parent d'un AUTRE
/// enfant observe -- ni son nom, ni son existence, ni meme leur nombre. Le
/// serveur applique cette borne lui-meme : `annonce_observation_pour_moi`
/// (migration `0040`) porte `enfant_profile_id = auth.uid()` dans son WHERE, et
/// ne rend donc jamais qu'une seule ligne, celle de l'appelant. Ce port ne peut
/// pas en apprendre davantage, meme si quelqu'un le voulait.
///
/// [annoncesObservationProvider] ne convient pas : `annonces_observation` leve
/// `insufficient_privilege` pour tout appelant qui n'est pas l'enseignant de la
/// seance, et elle rend les visites de TOUS les foyers.
abstract interface class PortAnnonceObservationEnfant {
  /// Vrai tant qu'une visite ouverte designe cet appelant comme enfant.
  Stream<bool> monTuteurObserve(String sessionId);
}

/// L'implementation reelle, sur la RPC de `0040`.
class AnnonceObservationEnfantSupabase implements PortAnnonceObservationEnfant {
  /// Cree le service.
  const AnnonceObservationEnfantSupabase(this._client);

  final SupabaseClient _client;

  @override
  Stream<bool> monTuteurObserve(String sessionId) {
    final StreamController<bool> sortie = StreamController<bool>();
    SondageRegulier? sondage;

    Future<bool> lire() async {
      try {
        final Object? reponse = await _client.rpc<Object?>(
          'annonce_observation_pour_moi',
          params: <String, dynamic>{'p_session_id': sessionId},
        );
        if (!sortie.isClosed) {
          sortie.add(
            reponse is Map<String, dynamic> && reponse['observe'] == true,
          );
        }
        return true;
      } on Object {
        // Un temoin qui ne sait pas reste ETEINT. Toute erreur retombe ici, y
        // compris le refus de la porte serveur (`insufficient_privilege`) que
        // recoit legitimement qui n'est pas membre du groupe de la seance :
        // c'est le cas de l'enseignant et du controleur, qui montent le meme
        // en-tete. Allumer par defaut dirait a un enfant qu'on le regarde
        // alors que personne ne le regarde.
        if (!sortie.isClosed) {
          sortie.add(false);
        }
        return false;
      }
    }

    sortie
      ..onListen = () {
        sondage = SondageRegulier(
          cadence: cadenceAnnonceObservation,
          lire: lire,
        )..demarrer();
      }
      ..onCancel = () {
        sondage?.arreter();
        return sortie.close();
      };
    return sortie.stream;
  }
}

/// Le service d'annonce cote enfant employe par l'application.
final Provider<PortAnnonceObservationEnfant>
portAnnonceObservationEnfantProvider = Provider<PortAnnonceObservationEnfant>(
  (Ref ref) => AnnonceObservationEnfantSupabase(Supabase.instance.client),
);

/// Vrai quand le tuteur de CET enfant observe la seance.
///
/// `isAutoDispose` : le flux s'arrete des que l'enfant quitte la salle, comme
/// celui de l'enseignant.
final StreamProviderFamily<bool, String> monTuteurObserveProvider =
    StreamProvider.family<bool, String>(
      (Ref ref, String sessionId) => ref
          .watch(portAnnonceObservationEnfantProvider)
          .monTuteurObserve(sessionId),
      isAutoDispose: true,
    );
