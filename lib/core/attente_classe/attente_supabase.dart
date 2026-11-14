import 'package:supabase_flutter/supabase_flutter.dart';

import 'modele_attente.dart';

/// Source du suivi de l'attente. La lecture `suivi_attente_foyer()` reste sous
/// le JWT courant : le serveur borne les demandes a l'eleve ou a son tuteur.
/// Le flux se relit a chaque fait du journal des demandes (Realtime), comme la
/// frise C-20.
class AttenteSupabase implements PortSuiviAttente {
  const AttenteSupabase(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<SuiviAttente>> suivre() => _client
      .from('demande_evenements')
      .stream(primaryKey: const <String>['id'])
      .asyncMap((_) => _charger());

  Future<List<SuiviAttente>> _charger() async {
    try {
      final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
        'suivi_attente_foyer',
      );
      return suivisAttenteDepuisDonnees(lignes);
    } on PostgrestException catch (e) {
      // La lecture n'est pas encore installee sur ce serveur (PGRST202, ou
      // 42883 fonction inconnue) : rien a suivre, aucune carte, jamais une
      // erreur montree a toutes les familles tant que la migration manque.
      if (e.code == 'PGRST202' || e.code == '42883') {
        return const <SuiviAttente>[];
      }
      rethrow;
    }
  }
}

/// Le reglage de visibilite de l'enseignant aupres des familles.
class PresentationEnseignantSupabase implements PortPresentationEnseignant {
  const PresentationEnseignantSupabase(this._client);

  final SupabaseClient _client;

  @override
  Future<PresentationAuxFamilles> lire() async {
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'ma_presentation_aux_familles',
    );
    if (lignes.isEmpty || lignes.first is! Map) {
      throw const FormatException('reglage de presentation absent');
    }
    final Map<String, dynamic> l = Map<String, dynamic>.from(
      lignes.first as Map,
    );
    return PresentationAuxFamilles(
      montre: (l['montre_aux_familles'] as bool?) ?? false,
      confirme: (l['confirme'] as bool?) ?? false,
      paysOrigine: l['pays_origine'] as String?,
      paysResidence: l['pays_residence'] as String?,
      mot: l['mot_presentation'] as String?,
    );
  }

  @override
  Future<void> regler({
    required bool montre,
    String? paysOrigine,
    String? paysResidence,
    String? mot,
  }) => _client.rpc<void>(
    'regler_presentation_aux_familles',
    params: <String, dynamic>{
      'p_montre': montre,
      'p_pays_origine': paysOrigine,
      'p_pays_residence': paysResidence,
      'p_mot': mot,
    },
  );
}

/// Projection pure de `suivi_attente_foyer()`. Toute ligne invalide leve une
/// [FormatException] : l'ecran dit alors que la lecture a echoue, il ne
/// montre pas un suivi devine.
List<SuiviAttente> suivisAttenteDepuisDonnees(List<dynamic> lignes) =>
    lignes.map(_suivi).toList(growable: false);

SuiviAttente _suivi(dynamic brut) {
  if (brut is! Map) throw const FormatException('ligne de suivi invalide');
  final Map<String, dynamic> l = Map<String, dynamic>.from(brut);
  final List<dynamic> occ = (l['occurrences'] as List<dynamic>?) ?? const [];
  return SuiviAttente(
    demandeId: l['demande_id'] as String,
    eleveId: l['eleve_id'] as String,
    prenom: (l['prenom'] as String?) ?? '',
    typePublic: (l['type_public'] as String?) ?? 'enfant',
    versionSimple: (l['version_simple'] as bool?) ?? false,
    fuseauIana: l['fuseau_iana'] as String,
    cas: _cas(l['cas'] as String?),
    motif: _motif(l['motif'] as String?),
    creneau: occ.isEmpty
        ? null
        : CreneauDemande(
            occurrences: occ.map((dynamic o) {
              if (o is! Map) throw const FormatException('occurrence invalide');
              return OccurrenceCreneau(
                jourIso: (o['jour_iso'] as num).toInt(),
                heure: (o['heure'] as num).toInt(),
                minute: (o['minute'] as num?)?.toInt() ?? 0,
              );
            }),
          ),
    etapes: _etapes(l['etapes']),
    delai: _delai(l['delai']),
    classe: l['classe'] as String?,
    premierCours: _date(l['premier_cours']),
    premierCoursPasse: (l['premier_cours_passe'] as bool?) ?? false,
    creneauChangeLe: _date(l['creneau_change_le']),
    enseignant: _enseignant(l['enseignant']),
    peutChoisirAutreCreneau:
        (l['peut_choisir_autre_creneau'] as bool?) ?? false,
    visibleAccueil: (l['visible_accueil'] as bool?) ?? true,
  );
}

CasAttente _cas(String? cas) => switch (cas) {
  'chemin' => CasAttente.chemin,
  'en_attente_enseignant' => CasAttente.enAttenteEnseignant,
  'liste_attente' => CasAttente.listeAttente,
  'refusee' => CasAttente.refusee,
  'retiree' => CasAttente.retiree,
  'close' => CasAttente.close,
  _ => throw const FormatException('cas de suivi inconnu'),
};

MotifCloture? _motif(String? motif) => switch (motif) {
  null => null,
  'retrait_famille' => MotifCloture.retraitFamille,
  'offre_retiree' => MotifCloture.offreRetiree,
  'classe_non_constituee' => MotifCloture.classeNonConstituee,
  'refus_direction' => MotifCloture.refusDirection,
  'deja_en_classe' => MotifCloture.dejaEnClasse,
  _ => MotifCloture.inconnu,
};

List<EtapeAttente> _etapes(Object? brut) {
  if (brut is! List || brut.length != nombreEtapesAttente) {
    throw const FormatException('le suivi porte cinq etapes');
  }
  return brut
      .map((dynamic e) {
        if (e is! Map) throw const FormatException('etape invalide');
        return EtapeAttente(
          numero: (e['numero'] as num).toInt(),
          etat: switch (e['statut']) {
            'fait' => EtatEtapeAttente.fait,
            'en_cours' => EtatEtapeAttente.enCours,
            'a_venir' => EtatEtapeAttente.aVenir,
            _ => throw const FormatException('statut d etape inconnu'),
          },
          quand: _date(e['le']),
        );
      })
      .toList(growable: false);
}

DelaiFormation? _delai(Object? brut) {
  if (brut is! Map) return null;
  final DateTime? limite = _date(brut['limite']);
  if (limite == null) return null;
  return DelaiFormation(
    jours: (brut['jours'] as num).toInt(),
    limite: limite,
    point: _date(brut['point']),
    pointPasse: (brut['point_passe'] as bool?) ?? false,
    depasse: (brut['depasse'] as bool?) ?? false,
  );
}

CarteEnseignantAttente? _enseignant(Object? brut) {
  if (brut is! Map) return null;
  return CarteEnseignantAttente(
    prenom: (brut['prenom'] as String?) ?? '',
    titre: brut['titre'] as String?,
    langueCours: brut['langue_cours'] as String?,
    montre: (brut['montre'] as bool?) ?? false,
    enseignantId: brut['teacher_id'] as String?,
    paysOrigine: brut['pays_origine'] as String?,
    paysResidence: brut['pays_residence'] as String?,
    mot: brut['mot'] as String?,
  );
}

/// Une heure murale du foyer, sans decalage. Une date avec decalage (instant)
/// est refusee : le client ne convertit aucun fuseau, il n'affiche rien
/// plutot qu'une heure fausse.
DateTime? _date(Object? valeur) {
  if (valeur == null) return null;
  if (valeur is! String) throw const FormatException('date de suivi invalide');
  final DateTime? d = DateTime.tryParse(valeur);
  if (d == null) throw const FormatException('date de suivi invalide');
  return d.isUtc ? null : d;
}
