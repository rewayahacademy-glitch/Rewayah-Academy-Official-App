import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_frise_demande.dart';

/// Source des frises C-20. Les deux lectures restent sous le JWT courant :
/// la RPC existante borne les demandes du foyer et la vue borne les jalons.
class FriseDemandesSupabase implements PortFriseDemandes {
  const FriseDemandesSupabase(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<FriseDemande>> suivre() => _client
      .from('demande_evenements')
      .stream(primaryKey: const <String>['id'])
      .asyncMap((_) => _charger());

  Future<List<FriseDemande>> _charger() async {
    final List<dynamic> demandes = await _client.rpc(
      'suivi_demandes_horaires_foyer',
    );
    final List<Map<String, dynamic>> evenements = await _client
        .from('demande_evenements_foyer_v')
        .select('demande_id,type,motif_attente,survenu_le_foyer');
    return frisesDepuisDonnees(demandes, evenements);
  }
}

/// Projection pure pour garder le contrat UTC/fuseau vérifiable sans réseau.
List<FriseDemande> frisesDepuisDonnees(
  List<dynamic> demandes,
  List<Map<String, dynamic>> evenements,
) {
  final Map<String, List<Map<String, dynamic>>> parDemande =
      <String, List<Map<String, dynamic>>>{};
  for (final Map<String, dynamic> evenement in evenements) {
    final String id = evenement['demande_id'] as String;
    (parDemande[id] ??= <Map<String, dynamic>>[]).add(evenement);
  }

  return demandes
      .map((dynamic brut) {
        if (brut is! Map) {
          throw const FormatException('ligne de suivi invalide');
        }
        final Map<String, dynamic> demande = Map<String, dynamic>.from(brut);
        final String id = demande['demande_id'] as String;
        final List<Map<String, dynamic>> sources =
            parDemande[id] ?? const <Map<String, dynamic>>[];
        final Map<TypeEtapeFrise, DateTime?> jalons =
            <TypeEtapeFrise, DateTime?>{};
        MotifAttente? motifAttente;

        for (final Map<String, dynamic> source in sources) {
          final TypeEtapeFrise? type = _typeEtape(source['type'] as String?);
          if (type == null) continue;
          final DateTime? quand = _heureMurale(source['survenu_le_foyer']);
          jalons[type] = quand;
          if (type == TypeEtapeFrise.enAttente) {
            motifAttente = switch (source['motif_attente']) {
              'classes_pleines' => MotifAttente.classesPleines,
              'aucun_enseignant_libre' => MotifAttente.aucunEnseignantLibre,
              _ => MotifAttente.inconnu,
            };
          }
        }

        final TypeEtapeFrise? etapeServeur = switch (demande['etape']) {
          'envoyee' => TypeEtapeFrise.envoyee,
          'classe_validee' => TypeEtapeFrise.classeCreee,
          'enseignant_affecte' => TypeEtapeFrise.enseignantAffecte,
          'close' => null,
          _ => throw const FormatException('étape de suivi inconnue'),
        };
        TypeEtapeFrise? courante = etapeServeur;
        for (final TypeEtapeFrise type in jalons.keys) {
          if (courante == null || type.index > courante.index) courante = type;
        }

        final DateTime? premiereSeance = _heureMurale(demande['debut_cours']);
        if (premiereSeance != null) {
          jalons[TypeEtapeFrise.premiereSeance] = premiereSeance;
        }
        final bool close = demande['etape'] == 'close';
        final List<EtapeFrise> etapes = <EtapeFrise>[
          for (final TypeEtapeFrise type in TypeEtapeFrise.values)
            if (type != TypeEtapeFrise.enAttente || jalons.containsKey(type))
              if (!close ||
                  type == TypeEtapeFrise.envoyee ||
                  jalons.containsKey(type))
                EtapeFrise(type: type, quand: jalons[type]),
        ];

        return FriseDemande(
          demandeId: id,
          eleveId: demande['eleve_id'] as String,
          prenom: (demande['prenom'] as String?) ?? '',
          fuseauIana: demande['fuseau_iana'] as String,
          etapes: etapes,
          courante: close ? null : courante,
          motifAttente: motifAttente,
          cloture: close ? _motifCloture(demande['motif'] as String?) : null,
          peutChoisirAutreCreneau:
              (demande['peut_choisir_autre_creneau'] as bool?) ?? false,
        );
      })
      .toList(growable: false);
}

TypeEtapeFrise? _typeEtape(String? type) => switch (type) {
  'envoyee' => TypeEtapeFrise.envoyee,
  'en_attente' => TypeEtapeFrise.enAttente,
  'classe_creee' => TypeEtapeFrise.classeCreee,
  'enseignant_affecte' => TypeEtapeFrise.enseignantAffecte,
  'eleve_integre' => TypeEtapeFrise.eleveIntegre,
  'premiere_seance_prevue' => TypeEtapeFrise.premiereSeance,
  'close' || null => null,
  _ => throw const FormatException('type d’événement inconnu'),
};

DateTime? _heureMurale(Object? valeur) {
  if (valeur == null) return null;
  if (valeur is! String) throw const FormatException('date de frise invalide');
  final DateTime? date = DateTime.tryParse(valeur);
  if (date == null || date.isUtc) {
    throw const FormatException('la date doit être une heure murale du foyer');
  }
  return date;
}

MotifClotureFrise _motifCloture(String? motif) => switch (motif) {
  'retrait_famille' => MotifClotureFrise.retraitFamille,
  'offre_retiree' => MotifClotureFrise.offreRetiree,
  'classe_non_constituee' => MotifClotureFrise.classeNonConstituee,
  'refus_direction' => MotifClotureFrise.refusDirection,
  'deja_en_classe' => MotifClotureFrise.dejaEnClasse,
  _ => MotifClotureFrise.inconnu,
};
