import 'package:supabase_flutter/supabase_flutter.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart' show Coffre;
import '../finance/montant.dart';
import 'port_delegation_finance.dart';

/// Adaptateur des politiques, journaux et commandes de délégation serveur.
final class DelegationFinanceSupabase
    implements PortDelegationFinance, PortControleDelegation {
  const DelegationFinanceSupabase(this._client);

  final SupabaseClient _client;

  static Map<String, dynamic> _map(Object? value, String field) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map)
      return value.map((Object? key, Object? item) => MapEntry('$key', item));
    throw FormatException('$field: objet attendu');
  }

  static List<dynamic> _list(Object? value, String field) {
    if (value is List) return value;
    throw FormatException('$field: liste attendue');
  }

  static String _string(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('$field: texte attendu');
  }

  static bool _bool(Object? value, String field) {
    if (value is bool) return value;
    throw FormatException('$field: booléen attendu');
  }

  static int _int(Object? value, String field) {
    if (value is int) return value;
    throw FormatException('$field: entier attendu');
  }

  static String? _optionalString(Object? value, String field) =>
      value == null ? null : _string(value, field);

  static DateTime? _optionalDate(Object? value, String field) =>
      value == null ? null : DateTime.parse(_string(value, field)).toLocal();

  static Montant? _montant(Object? value, String field) {
    if (value == null) return null;
    final Map<String, dynamic> json = _map(value, field);
    return Montant(
      _int(json['mineur'], '$field.mineur'),
      _string(json['devise'], '$field.devise'),
    );
  }

  static T _enum<T extends Enum>(List<T> values, Object? value, String field) {
    final String raw = _string(value, field);
    return values.firstWhere(
      (T item) => item.name == raw,
      orElse: () => throw FormatException('$field: valeur inconnue ($raw)'),
    );
  }

  static PolitiqueDelegationFinance _politique(Object? value) {
    final Map<String, dynamic> json = _map(value, 'politique delegation');
    final EtatDelegation state = switch (json['etat']) {
      'active' => EtatDelegation.active,
      'suspendue' => EtatDelegation.suspendue,
      'expiree' => EtatDelegation.expiree,
      final Object? other => throw FormatException(
        'etat delegation inconnu: $other',
      ),
    };
    final List<ExceptionDelegation>
    exceptions = _list(json['exceptions'], 'exceptions')
        .map((Object? value) {
          final Map<String, dynamic> row = _map(value, 'exception');
          final Set<Coffre> vaults = _list(
            row['coffres_autorises'],
            'coffres_autorises',
          ).map((Object? item) => _enum(Coffre.values, item, 'coffre')).toSet();
          final List<BeneficiaireExclu> excluded =
              _list(row['beneficiaires_exclus'], 'beneficiaires_exclus')
                  .map((Object? item) {
                    final Map<String, dynamic> person = _map(
                      item,
                      'beneficiaire exclu',
                    );
                    return BeneficiaireExclu(
                      id: _string(person['id'], 'beneficiaire.id'),
                      nom: _string(person['nom'], 'beneficiaire.nom'),
                    );
                  })
                  .toList(growable: false);
          return ExceptionDelegation(
            id: _string(row['id'], 'exception.id'),
            libelle: _string(row['libelle'], 'exception.libelle'),
            coffresAutorises: vaults,
            beneficiairesExclus: excluded,
            plafondParTransaction: _montant(
              row['plafond_par_transaction'],
              'exception.plafond',
            ),
          );
        })
        .toList(growable: false);
    return PolitiqueDelegationFinance(
      version: _string(json['version'], 'version'),
      paiementsStandardsAutorises: _bool(
        json['paiements_standards_autorises'],
        'paiements_standards_autorises',
      ),
      plafondParTransaction: _montant(
        json['plafond_par_transaction'],
        'plafond_par_transaction',
      ),
      plafondParLot: _montant(json['plafond_par_lot'], 'plafond_par_lot'),
      plafondParPeriode: _montant(
        json['plafond_par_periode'],
        'plafond_par_periode',
      ),
      remboursementStandardAutorise: _bool(
        json['remboursement_standard_autorise'],
        'remboursement_standard_autorise',
      ),
      alimentationReserveAutorisee: _bool(
        json['alimentation_reserve_autorisee'],
        'alimentation_reserve_autorisee',
      ),
      retraitReserveInterdit: _bool(
        json['retrait_reserve_interdit'],
        'retrait_reserve_interdit',
      ),
      premierPaiementSecondeValidation: _bool(
        json['premier_paiement_seconde_validation'],
        'premier_paiement_seconde_validation',
      ),
      coordonneesRecentesSecondeValidation: _bool(
        json['coordonnees_recentes_seconde_validation'],
        'coordonnees_recentes_seconde_validation',
      ),
      joursCoordonneesRecentes: json['jours_coordonnees_recentes'] == null
          ? null
          : _int(
              json['jours_coordonnees_recentes'],
              'jours_coordonnees_recentes',
            ),
      autoPayoutInterdit: _bool(
        json['auto_payout_interdit'],
        'auto_payout_interdit',
      ),
      montantManuelInterdit: _bool(
        json['montant_manuel_interdit'],
        'montant_manuel_interdit',
      ),
      politiqueTarifaireInterdite: _bool(
        json['politique_tarifaire_interdite'],
        'politique_tarifaire_interdite',
      ),
      dateEffet: _optionalDate(json['date_effet'], 'date_effet'),
      auteur: _optionalString(json['auteur'], 'auteur'),
      etat: state,
      suspendueLe: _optionalDate(json['suspendue_le'], 'suspendue_le'),
      expireLe: _optionalDate(json['expire_le'], 'expire_le'),
      dureeJours: json['duree_jours'] == null
          ? null
          : _int(json['duree_jours'], 'duree_jours'),
      delaiSortieHeures: json['delai_sortie_heures'] == null
          ? null
          : _int(json['delai_sortie_heures'], 'delai_sortie_heures'),
      exceptions: exceptions,
    );
  }

  static Map<String, dynamic> _policyPayload(
    BrouillonDelegationFinance draft,
  ) => {
    'paiements_standards_autorises': draft.paiementsStandardsAutorises,
    'plafond_par_transaction': _amountPayload(draft.plafondParTransaction),
    'plafond_par_lot': _amountPayload(draft.plafondParLot),
    'plafond_par_periode': _amountPayload(draft.plafondParPeriode),
    'remboursement_standard_autorise': draft.remboursementStandardAutorise,
    'alimentation_reserve_autorisee': draft.alimentationReserveAutorisee,
    'retrait_reserve_interdit': draft.retraitReserveInterdit,
    'premier_paiement_seconde_validation':
        draft.premierPaiementSecondeValidation,
    'coordonnees_recentes_seconde_validation':
        draft.coordonneesRecentesSecondeValidation,
    'jours_coordonnees_recentes': draft.joursCoordonneesRecentes,
    'exceptions': draft.exceptions
        .map(
          (ExceptionDelegation exception) => {
            'id': exception.id,
            'libelle': exception.libelle,
            'coffres_autorises': exception.coffresAutorises
                .map((Coffre vault) => vault.name)
                .toList(),
            'beneficiaires_exclus': exception.beneficiairesExclus
                .map(
                  (BeneficiaireExclu person) => {
                    'id': person.id,
                    'nom': person.nom,
                  },
                )
                .toList(),
            'plafond_par_transaction': _amountPayload(
              exception.plafondParTransaction,
            ),
          },
        )
        .toList(growable: false),
  };

  static Map<String, dynamic>? _amountPayload(Montant? amount) => amount == null
      ? null
      : {'mineur': amount.mineur, 'devise': amount.devise};

  @override
  Future<PolitiqueDelegationFinance> politique() async =>
      _politique(await _client.rpc<Object?>('lire_delegation_finance'));

  @override
  Future<PolitiqueDelegationFinance> enregistrer({
    required BrouillonDelegationFinance brouillon,
    required String cleIdempotence,
  }) async => _politique(
    await _client.rpc<Object?>(
      'enregistrer_delegation_finance',
      params: {
        'p_brouillon': _policyPayload(brouillon),
        'p_cle': cleIdempotence,
      },
    ),
  );

  @override
  Future<List<EntreeJournal>> journal() async {
    final List<dynamic> rows = _list(
      await _client.rpc<Object?>('journal_delegation_finance'),
      'journal',
    );
    return rows
        .map((Object? item) {
          final Map<String, dynamic> row = _map(item, 'journal');
          return EntreeJournal(
            id: '${row['id']}',
            date: DateTime.parse(_string(row['date'], 'journal.date'))
                .toLocal(),
            initiateur: _string(row['initiateur'], 'journal.initiateur'),
            objet: _string(row['objet'], 'journal.objet'),
            source: _optionalString(row['source'], 'journal.source'),
            ancienEtat: _optionalString(
              row['ancien_etat'],
              'journal.ancien_etat',
            ),
            nouvelEtat: _optionalString(
              row['nouvel_etat'],
              'journal.nouvel_etat',
            ),
            montant: _montant(row['montant'], 'journal.montant'),
            preuve: _optionalString(row['preuve'], 'journal.preuve'),
            reference: _optionalString(row['reference'], 'journal.reference'),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<PolitiqueDelegationFinance> suspendreToutes({
    required String cleIdempotence,
  }) async => _politique(
    await _client.rpc<Object?>(
      'suspendre_toutes_delegations_finance',
      params: {'p_cle': cleIdempotence},
    ),
  );

  @override
  Future<PolitiqueDelegationFinance> reactiver({
    required String cleIdempotence,
    required String raison,
  }) async => _politique(
    await _client.rpc<Object?>(
      'reactiver_delegation_finance',
      params: {'p_cle': cleIdempotence, 'p_raison': raison},
    ),
  );

  @override
  Future<PolitiqueDelegationFinance> renouveler({
    required String cleIdempotence,
  }) async => _politique(
    await _client.rpc<Object?>(
      'renouveler_delegation_finance',
      params: {'p_cle': cleIdempotence},
    ),
  );

  @override
  Future<List<SortieEnAttente>> sortiesEnAttente() async {
    final List<dynamic> rows = _list(
      await _client.rpc<Object?>('sorties_en_attente_delegation_finance'),
      'sorties',
    );
    return rows
        .map((Object? item) {
          final Map<String, dynamic> row = _map(item, 'sortie');
          return SortieEnAttente(
            id: _string(row['id'], 'sortie.id'),
            beneficiaire: _string(row['beneficiaire'], 'sortie.beneficiaire'),
            objet: _string(row['objet'], 'sortie.objet'),
            montant: _montant(row['montant'], 'sortie.montant')!,
            demandeeLe: DateTime.parse(
              _string(row['demandee_le'], 'sortie.demandee_le'),
            ).toLocal(),
            liberableLe: DateTime.parse(
              _string(row['liberable_le'], 'sortie.liberable_le'),
            ).toLocal(),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> annulerSortie({
    required String sortieId,
    required String cleIdempotence,
  }) async {
    await _client.rpc<void>(
      'annuler_sortie_delegation_finance',
      params: {'p_sortie_id': sortieId, 'p_cle': cleIdempotence},
    );
  }
}
