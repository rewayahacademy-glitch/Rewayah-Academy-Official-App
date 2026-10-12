import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_delais.dart';
import 'port_suivi_demandes.dart';

/// Adaptateur du suivi C-10/C-10 bis vers les RPC et changements Postgres.
///
/// `mes_demandes_horaires_famille()` ne reçoit aucun identifiant client : le
/// serveur déduit le foyer de la session et ne rend que ses propres demandes.
class PortSuiviDemandesSupabase implements PortSuiviDemandes {
  const PortSuiviDemandesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<SuiviDemande>> suivre() async* {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Une session est requise pour suivre les demandes.');
    }

    final StreamController<void> changements = StreamController<void>();
    final Completer<void> abonne = Completer<void>();
    Timer? debounce;
    bool stopping = false;

    void invalider() {
      debounce?.cancel();
      debounce = Timer(AppDelais.debounceRealtime, () {
        if (!changements.isClosed) changements.add(null);
      });
    }

    void propagerErreur(Object? erreur, String message) {
      if (stopping) return;
      final Object cause = erreur ?? StateError(message);
      if (!abonne.isCompleted) {
        abonne.completeError(cause);
      } else if (!changements.isClosed) {
        changements.addError(cause);
      }
    }

    final RealtimeChannel canal = _client
        .channel('suivi-demandes-famille:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'demandes_horaires_famille',
          callback: (_) {
            invalider();
          },
        );

    canal.subscribe((RealtimeSubscribeStatus statut, Object? erreur) {
      if (statut == RealtimeSubscribeStatus.subscribed) {
        if (!abonne.isCompleted) abonne.complete();
      } else if (statut == RealtimeSubscribeStatus.channelError ||
          statut == RealtimeSubscribeStatus.timedOut ||
          statut == RealtimeSubscribeStatus.closed) {
        propagerErreur(erreur, 'Abonnement aux demandes interrompu.');
      }
    });

    try {
      await abonne.future.timeout(const Duration(seconds: 20));
      yield await _charger();
      await for (final void _ in changements.stream) {
        yield await _charger();
      }
    } finally {
      stopping = true;
      debounce?.cancel();
      await _client.removeChannel(canal);
      await changements.close();
    }
  }

  Future<List<SuiviDemande>> _charger() async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'mes_demandes_horaires_famille',
    );
    return decodeSuiviDemandes(lignes);
  }
}

/// Décode la réponse JSON du RPC de suivi, en gardant l'heure propre à chaque
/// jour (C-10 bis) et en refusant les tableaux incohérents.
List<SuiviDemande> decodeSuiviDemandes(Object? value) {
  if (value is! List) {
    throw const FormatException('La réponse de suivi doit être une liste.');
  }
  return List<SuiviDemande>.unmodifiable(value.map(_decodeSuiviDemande));
}

SuiviDemande _decodeSuiviDemande(Object? value) {
  if (value is! Map) {
    throw const FormatException('Une demande doit être un objet JSON.');
  }
  final Map<String, dynamic> json = Map<String, dynamic>.from(value);
  final String etat = _texteRequis(json, 'etat');
  final EtapeDemande etape = switch (etat) {
    'envoyee' => EtapeDemande.envoyee,
    'classe_validee' => EtapeDemande.classeValidee,
    'enseignant_affecte' => EtapeDemande.enseignantAffecte,
    'refusee' || 'retiree' => EtapeDemande.close,
    _ => throw FormatException('État de demande inconnu: $etat.'),
  };

  final List<int> jours = _entiersRequis(json, 'jours');
  final List<int> heures = _entiersRequis(json, 'heures_locales');
  if (jours.isEmpty || jours.length != heures.length) {
    throw const FormatException('Les jours et heures doivent être parallèles.');
  }
  final List<OccurrenceCreneau> occurrences = <OccurrenceCreneau>[];
  for (int i = 0; i < jours.length; i++) {
    final int jour = jours[i];
    final int heure = heures[i];
    if (jour < 1 || jour > 7 || heure < 0 || heure > 23) {
      throw const FormatException('Jour ISO ou heure locale invalide.');
    }
    occurrences.add(OccurrenceCreneau(jourIso: jour, heure: heure));
  }
  if (occurrences.map((OccurrenceCreneau o) => o.jourIso).toSet().length !=
      occurrences.length) {
    throw const FormatException('Un jour ne peut apparaître qu’une fois.');
  }

  final String fuseau = _texteRequis(json, 'fuseau_iana');
  final String? motifTexte = json['motif'] as String?;
  final MotifCloture? motif = switch (motifTexte) {
    'retrait_famille' => MotifCloture.retraitFamille,
    'offre_retiree' => MotifCloture.offreRetiree,
    'classe_non_constituee' => MotifCloture.classeNonConstituee,
    'refus_direction' => MotifCloture.refusDirection,
    null => null,
    _ => MotifCloture.inconnu,
  };

  return SuiviDemande(
    demandeId: _texteRequis(json, 'demande_id'),
    eleveId: _texteRequis(json, 'eleve_id'),
    prenom: _texteRequis(json, 'prenom'),
    etape: etape,
    creneau: CreneauDemande(occurrences: occurrences),
    fuseauIana: fuseau,
    personnalise: json['personnalisee'] == true,
    enseignant: _texteOptionnel(json['enseignant']),
    debutCours: _heureMuraleOptionnelle(json['debut_cours_local']),
    motif: motif,
    peutChoisirAutreCreneau: json['peut_choisir_autre_creneau'] == true,
  );
}

String _texteRequis(Map<String, dynamic> json, String cle) {
  final Object? valeur = json[cle];
  if (valeur is! String || valeur.trim().isEmpty) {
    throw FormatException('Champ texte requis absent: $cle.');
  }
  return valeur;
}

String? _texteOptionnel(Object? valeur) =>
    valeur is String && valeur.trim().isNotEmpty ? valeur : null;

List<int> _entiersRequis(Map<String, dynamic> json, String cle) {
  final Object? valeur = json[cle];
  if (valeur is! List || valeur.any((dynamic item) => item is! num)) {
    throw FormatException('Tableau numérique requis absent: $cle.');
  }
  return valeur.cast<num>().map((num item) => item.toInt()).toList();
}

DateTime? _heureMuraleOptionnelle(Object? valeur) {
  if (valeur == null) return null;
  if (valeur is! String ||
      RegExp(r'(?:Z|[+-]\d{2}:?\d{2})$').hasMatch(valeur)) {
    throw const FormatException(
      'Le début du cours doit être une heure locale sans décalage UTC.',
    );
  }
  final DateTime? resultat = DateTime.tryParse(valeur);
  if (resultat == null || resultat.isUtc) {
    throw const FormatException('Heure murale de début de cours invalide.');
  }
  return resultat;
}
