// L'adaptateur Supabase de la fusion de classes paralleles et du transfert
// d'un eleve (R5, R9, R10), sur les RPC `classes_cibles_fusion`,
// `apercu_fusion`, `fusionner_classes`, `membres_transferables`,
// `transferer_eleve` et `historique_classe` (migration 20261016100100).
//
// Le serveur rend les noms de classe en (libelle, numero) : le nom sans
// ambiguite se compose ici, dans la langue de l'interface
// ([nomClasseDistinct]). Les motifs de refus arrivent en codes et sont mis en
// mots ici ; un code inconnu prend une phrase neutre, jamais le code brut.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../classes/nom_classe_distinct.dart';
import '../i18n/strings.g.dart';
import 'port_fusion_classes.dart';

/// La fusion et le transfert servis par Supabase.
class FusionClassesSupabase implements PortFusionClasses {
  /// Cree l'adaptateur sur le client de l'application.
  const FusionClassesSupabase(this._client);

  final SupabaseClient _client;

  Future<Object?> _rpc(String fonction, Map<String, dynamic> params) =>
      _client.rpc<Object?>(fonction, params: params);

  @override
  Future<List<ClasseCible>> classesCibles(
    String classeId, {
    int? eleves,
  }) async {
    final Object? brut = await _rpc('classes_cibles_fusion', <String, dynamic>{
      'p_classe_id': classeId,
      'p_eleves': eleves,
    });
    return List<ClasseCible>.unmodifiable(<ClasseCible>[
      for (final Object? c in _liste(brut)) classeCibleJson(_objet(c)),
    ]);
  }

  @override
  Future<ApercuFusion> apercu({
    required String sourceId,
    required String cibleId,
  }) async => apercuFusionJson(
    _objet(
      await _rpc('apercu_fusion', <String, dynamic>{
        'p_source_id': sourceId,
        'p_cible_id': cibleId,
      }),
    ),
  );

  @override
  Future<ResultatFusion> fusionner({
    required String sourceId,
    required String cibleId,
    required String cleEnvoi,
  }) async => resultatFusionJson(
    _objet(
      await _rpc('fusionner_classes', <String, dynamic>{
        'p_source_id': sourceId,
        'p_cible_id': cibleId,
        'p_cle_envoi': cleEnvoi,
      }),
    ),
  );

  @override
  Future<List<MembreTransferable>> membres(String classeId) async {
    final Object? brut = await _rpc('membres_transferables', <String, dynamic>{
      'p_classe_id': classeId,
    });
    return List<MembreTransferable>.unmodifiable(<MembreTransferable>[
      for (final Object? m in _liste(brut)) membreTransferableJson(_objet(m)),
    ]);
  }

  @override
  Future<ResultatTransfert> transferer({
    required String eleveId,
    required String sourceId,
    required String cibleId,
    required String cleEnvoi,
  }) async => resultatTransfertJson(
    _objet(
      await _rpc('transferer_eleve', <String, dynamic>{
        'p_eleve_id': eleveId,
        'p_source_id': sourceId,
        'p_cible_id': cibleId,
        'p_cle_envoi': cleEnvoi,
      }),
    ),
  );

  @override
  Future<List<EvenementClasse>> historique(String classeId) async {
    final Object? brut = await _rpc('historique_classe', <String, dynamic>{
      'p_classe_id': classeId,
    });
    return List<EvenementClasse>.unmodifiable(<EvenementClasse>[
      for (final Object? e in _liste(brut))
        if (evenementClasseJson(_objet(e)) case final EvenementClasse ev) ev,
    ]);
  }
}

String _nom(Object? libelle, Object? numero) => nomClasseDistinct(
  libelle is String ? libelle : '',
  numero: numero is num ? numero.toInt() : null,
);

String? _personne(Object? prenom, Object? nom) {
  final String complet = <Object?>[
    prenom,
    nom,
  ].whereType<String>().join(' ').trim();
  return complet.isEmpty ? null : complet;
}

/// Une classe cible rendue par `classes_cibles_fusion` ou `apercu_fusion`.
ClasseCible classeCibleJson(Map<String, dynamic> c) => ClasseCible(
  classeId: c['classe_id'] as String,
  nom: _nom(c['libelle'], c['numero']),
  enseignant: _personne(c['enseignant_prenom'], c['enseignant_nom']),
  membres: _entier(c['membres']),
  capacite: _entier(c['capacite']),
);

/// Un eleve rendu par `membres_transferables`.
MembreTransferable membreTransferableJson(Map<String, dynamic> m) =>
    MembreTransferable(
      eleveId: m['eleve_id'] as String,
      prenom: m['prenom'] as String? ?? '',
    );

/// L'apercu rendu par `apercu_fusion`.
ApercuFusion apercuFusionJson(Map<String, dynamic> a) => ApercuFusion(
  sourceNom: _nom(a['source_libelle'], a['source_numero']),
  cible: classeCibleJson(_objet(a['cible'])),
  membresDeplaces: _entier(a['membres_deplaces']),
  enseignantLibere: _personne(
    a['enseignant_libere_prenom'],
    a['enseignant_libere_nom'],
  ),
  famillesNotifiees: _entier(a['familles_notifiees']),
);

/// La reponse de `fusionner_classes`.
ResultatFusion resultatFusionJson(Map<String, dynamic> r) =>
    switch (r['statut']) {
      'faite' => FusionFaite(
        cibleNom: _nom(r['cible_libelle'], r['cible_numero']),
        elevesDeplaces: _entier(r['eleves_deplaces']),
      ),
      'deja_faite' => const FusionDejaFaite(),
      'refusee' => FusionRefusee(motifRefusClasse(r['motif'])),
      _ => throw const FormatException('Statut de fusion inconnu.'),
    };

/// La reponse de `transferer_eleve`.
ResultatTransfert resultatTransfertJson(Map<String, dynamic> r) =>
    switch (r['statut']) {
      'fait' => TransfertFait(
        prenom: r['prenom'] as String? ?? '',
        cibleNom: _nom(r['cible_libelle'], r['cible_numero']),
      ),
      'deja_fait' => const TransfertDejaFait(),
      'refuse' => switch (r['raison']) {
        'chevauchement' => const TransfertRefuse(
          RaisonRefusTransfert.chevauchement,
        ),
        'classe_pleine' => const TransfertRefuse(
          RaisonRefusTransfert.classePleine,
        ),
        _ => TransfertRefuse(
          RaisonRefusTransfert.autre,
          motif: motifRefusClasse(r['motif']),
        ),
      },
      _ => throw const FormatException('Statut de transfert inconnu.'),
    };

/// Le code de motif d'un refus de fusion ou de transfert, mis en mots.
String motifRefusClasse(Object? code) {
  final m = t.admin.fusion.motif;
  return switch (code) {
    'classe_introuvable' => m.classeIntrouvable,
    'source_cloturee' => m.sourceCloturee,
    'cible_cloturee' => m.cibleCloturee,
    'cible_incompatible' => m.cibleIncompatible,
    'cible_pleine' => m.ciblePleine,
    'eleve_absent' => m.eleveAbsent,
    _ => m.inconnu,
  };
}

/// Une ligne de `historique_classe` ; nulle quand son type est inconnu.
EvenementClasse? evenementClasseJson(Map<String, dynamic> e) {
  final TypeEvenementClasse? type = switch (e['type']) {
    'fusion_sortante' => TypeEvenementClasse.fusionSortante,
    'fusion_entrante' => TypeEvenementClasse.fusionEntrante,
    'transfert_sortant' => TypeEvenementClasse.transfertSortant,
    'transfert_entrant' => TypeEvenementClasse.transfertEntrant,
    _ => null,
  };
  final DateTime? quand = e['quand'] is String
      ? DateTime.tryParse(e['quand'] as String)?.toLocal()
      : null;
  if (type == null || quand == null) return null;
  return EvenementClasse(
    id: e['id'] as String,
    type: type,
    quand: quand,
    autreClasse: _nom(e['autre_libelle'], e['autre_numero']),
    nombre: (e['nombre'] as num?)?.toInt(),
    prenom: e['prenom'] as String?,
  );
}

int _entier(Object? v) => v is num ? v.toInt() : 0;

List<Object?> _liste(Object? v) {
  if (v is! List) throw const FormatException('Liste attendue.');
  return v;
}

Map<String, dynamic> _objet(Object? v) {
  if (v is! Map) throw const FormatException('Objet attendu.');
  return Map<String, dynamic>.from(v);
}
