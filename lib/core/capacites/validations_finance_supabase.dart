// Adaptateur CPT-BR-09 : les demandes de validation de la comptabilite,
// servies par les RPC de FAC-D-01 (migration 20261018090000).
//
// La source rend, pour chaque demande, ce que la personne connectee peut en
// faire (`actions`, `blocages`) : l'ecran ne lit jamais un role. Les refus
// de decision ont leurs codes propres (RV001 demandeur, RV002 motif, RV003
// deja decidee) et deviennent [RefusDecision] : rien n'a change. Toute autre
// erreur remonte telle quelle : l'issue est inconnue.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../i18n/strings.g.dart';
import 'port_validations_finance.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'CPT-BR-09';

/// Les validations servies par Supabase.
class ValidationsFinanceSupabase implements PortValidationsFinance {
  /// Cree l'adaptateur sur le client de l'application.
  ValidationsFinanceSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  ValidationsFinanceSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<List<DemandeValidation>> demandes(
    FiltreDemandesValidation filtre,
  ) async => <DemandeValidation>[
    for (final Object? d in listeJson(
      await appelerFinance(
        _appel,
        'finance_validations_lister',
        _dependance,
        <String, dynamic>{
          'p_etat': switch (filtre.etat) {
            null => null,
            final EtatDemandeValidation e => etatValidationSql(e),
          },
          'p_nature': switch (filtre.nature) {
            null => null,
            final NatureDemandeValidation n => natureValidationSql(n),
          },
          'p_objet': filtre.objetId,
        },
      ),
      'demandes',
    ))
      // Une nature que cette version de l'application ne connait pas encore
      // reste a la source : elle se decide depuis une version a jour.
      if (natureValidationJson(objetJson(d, 'demande')['nature'])
          case final NatureDemandeValidation _)
        demandeValidationJson(d),
  ];

  @override
  Future<DemandeValidation> decider({
    required String demandeId,
    required DecisionValidation decision,
    required String cleIdempotence,
    String? motif,
  }) async {
    final Object? brut;
    try {
      brut = await appelerFinance(
        _appel,
        'finance_validation_decider',
        _dependance,
        <String, dynamic>{
          'p_demande': demandeId,
          'p_decision': switch (decision) {
            DecisionValidation.valider => 'valider',
            DecisionValidation.refuser => 'refuser',
          },
          'p_motif': motif,
          'p_cle': cleIdempotence,
        },
      );
    } on PostgrestException catch (e) {
      throw switch (e.code) {
        'RV001' => const RefusDecision(
          MotifRefusDecision.demandeurNePeutPasValider,
        ),
        'RV002' => const RefusDecision(MotifRefusDecision.motifObligatoire),
        'RV003' => const RefusDecision(MotifRefusDecision.dejaDecidee),
        _ => e,
      };
    }
    return demandeValidationJson(brut);
  }

  @override
  Future<List<EntreeJournal>> journal(String demandeId) async =>
      <EntreeJournal>[
        for (final Object? e in listeJson(
          await appelerFinance(
            _appel,
            'finance_validation_journal',
            _dependance,
            <String, dynamic>{'p_demande': demandeId},
          ),
          'journal',
        ))
          entreeJournalValidationJson(e),
      ];
}

/// L'etat tel que la base l'ecrit.
String etatValidationSql(EtatDemandeValidation e) => switch (e) {
  EtatDemandeValidation.enAttente => 'en_attente',
  EtatDemandeValidation.validee => 'validee',
  EtatDemandeValidation.refusee => 'refusee',
};

/// La nature telle que la base l'ecrit ; `null` pour une nature que la base
/// ne porte pas encore.
String? natureValidationSql(NatureDemandeValidation n) => switch (n) {
  NatureDemandeValidation.paiementRecu => 'paiement_recu',
  _ => null,
};

/// La nature rendue, ou `null` si cette version ne la connait pas.
NatureDemandeValidation? natureValidationJson(Object? v) => switch (v) {
  'paiement_recu' => NatureDemandeValidation.paiementRecu,
  _ => null,
};

EtatDemandeValidation _etatJson(Object? v) => switch (v) {
  'en_attente' => EtatDemandeValidation.enAttente,
  'validee' => EtatDemandeValidation.validee,
  'refusee' => EtatDemandeValidation.refusee,
  _ => throw FormatException('etat de validation inconnu: $v'),
};

RaisonBlocage _raisonJson(Object? v) => switch (v) {
  'paiement_hors_application' => RaisonBlocage.paiementHorsApplication,
  'auto_paiement' => RaisonBlocage.autoPaiement,
  _ => throw FormatException('raison inconnue: $v'),
};

/// Une demande rendue par `finance_validations_lister` ou
/// `finance_validation_decider`.
DemandeValidation demandeValidationJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'demande');
  final NatureDemandeValidation? nature = natureValidationJson(j['nature']);
  if (nature == null) {
    throw FormatException('nature de validation inconnue: ${j['nature']}');
  }
  final Object? dateDecision = j['dateDecision'];
  final Set<ActionFinance> actions = <ActionFinance>{
    for (final Object? a in listeJson(j['actions'], 'actions'))
      if (a == 'approuver') ActionFinance.approuver,
  };
  final Map<String, dynamic> blocages = objetJson(j['blocages'], 'blocages');
  final Object? blocage = blocages['approuver'];
  return DemandeValidation(
    id: texteJson(j, 'id'),
    nature: nature,
    date: instantJson(j['date'], 'date'),
    demandeur: texteJson(j, 'demandeur'),
    objet: texteJson(j, 'objet'),
    objetId: texteNullableJson(j, 'objetId'),
    montant: montantJson(j['montant'], 'montant'),
    raison: _raisonJson(j['raison']),
    precision: switch (texteNullableJson(j, 'reference')) {
      null => null,
      final String r => t.comptable.validation.reference(reference: r),
    },
    etat: _etatJson(j['etat']),
    decideur: texteNullableJson(j, 'decideur'),
    motifDecision: texteNullableJson(j, 'motif'),
    dateDecision: dateDecision == null
        ? null
        : instantJson(dateDecision, 'dateDecision'),
    permissions: PermissionsFinance(
      actions: actions,
      blocages: <ActionFinance, RaisonBlocage>{
        if (blocage != null) ActionFinance.approuver: _raisonJson(blocage),
      },
    ),
  );
}

/// Une entree de `finance_validation_journal` : l'action devient une phrase.
EntreeJournal entreeJournalValidationJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'entree');
  final v = t.comptable.validation.journal;
  final Object? action = j['action'];
  return EntreeJournal(
    id: texteJson(j, 'id'),
    date: instantJson(j['date'], 'date'),
    initiateur: texteJson(j, 'initiateur'),
    objet: switch (action) {
      'demandee' => v.demandee,
      'validee' => v.validee,
      'refusee' => v.refusee,
      _ => throw FormatException('action de journal inconnue: $action'),
    },
    montant: montantNullableJson(j['montant'], 'montant'),
    reference: texteNullableJson(j, 'reference'),
  );
}
