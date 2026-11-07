// Adaptateur des coordonnees de versement et du fichier Wise (migration
// 20261110700000).
//
// **Aucun calcul** : les montants et les valeurs du fichier arrivent mis en
// forme par le serveur. Un refus de droits (42501) sur la lecture de MES
// coordonnees veut dire que cette capacite n'est pas la mienne (je ne suis pas
// enseignant) : [CapaciteIndisponible], la rubrique ne s'affiche pas. Le modele
// Wise absent devient [ModeleWiseAbsent].

import 'package:supabase_flutter/supabase_flutter.dart';

import 'capacite_indisponible.dart';
import 'port_coordonnees_versement.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'VERSEMENT-WISE';

String _date(DateTime d) => d.toIso8601String().substring(0, 10);

/// Decode la reponse de `mes_coordonnees_versement`.
MesCoordonneesVersement mesCoordonneesJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'mes_coordonnees_versement');
  final Object? c = j['coordonnees'];
  final Map<ChampVersement, String> valeurs = <ChampVersement, String>{};
  if (c != null) {
    final Map<String, dynamic> m = objetJson(c, 'coordonnees');
    const Map<String, ChampVersement> cles = <String, ChampVersement>{
      'titulaire': ChampVersement.titulaire,
      'numeroCompte': ChampVersement.numeroCompte,
      'iban': ChampVersement.iban,
      'swift': ChampVersement.swift,
      'adressePays': ChampVersement.adressePays,
      'adresseVille': ChampVersement.adresseVille,
      'adresseLigne': ChampVersement.adresseLigne,
      'codePostal': ChampVersement.codePostal,
      'adresseEtat': ChampVersement.adresseEtat,
    };
    cles.forEach((String cle, ChampVersement champ) {
      final String? v = texteNullableJson(m, cle);
      if (v != null && v.isNotEmpty) valeurs[champ] = v;
    });
  }
  final String? modifie = texteNullableJson(j, 'modifieLe');
  return MesCoordonneesVersement(
    deviseCible: texteJson(j, 'deviseCible'),
    // L'ordre de saisie est celui du serveur ; un champ inconnu est ignore.
    champs: <ChampDemande>[
      for (final Object? c in listeJson(j['champs'], 'champs')) ?_champ(c),
    ],
    enregistre: booleenJson(j, 'enregistre'),
    complet: booleenJson(j, 'complet'),
    valide: booleenJson(j, 'valide'),
    compteAMonNom: booleenJson(j, 'compteAMonNom'),
    lienTitulaire: LienTitulaire.depuisCode(
      texteNullableJson(j, 'lienTitulaire'),
    ),
    paysProfil: texteNullableJson(j, 'paysProfil'),
    valeurs: valeurs,
    modifieLe: modifie == null ? null : instantJson(modifie, 'modifieLe'),
  );
}

ChampDemande? _champ(Object? brut) {
  final Map<String, dynamic> c = objetJson(brut, 'champ');
  final ChampVersement? champ = ChampVersement.depuisCode(
    texteJson(c, 'champ'),
  );
  if (champ == null) return null;
  final Object? pays = c['siPays'];
  return ChampDemande(
    champ,
    obligatoire: booleenJson(c, 'obligatoire'),
    siPays: pays == null
        ? null
        : <String>[
            for (final Object? p in listeJson(pays, 'siPays'))
              if (p is String) p,
          ],
  );
}

/// Decode la reponse de `versement_export_wise`.
ExportWise exportWiseJson(Object? brut) {
  final Map<String, dynamic> j = objetJson(brut, 'versement_export_wise');
  return ExportWise(
    exportId: texteJson(j, 'exportId'),
    mois: dateJson(j['mois'], 'mois'),
    colonnes: <String>[
      for (final Object? c in listeJson(j['colonnes'], 'colonnes'))
        if (c is String) c else throw const FormatException('colonne'),
    ],
    lignes: <List<String>>[
      for (final Object? l in listeJson(j['lignes'], 'lignes'))
        <String>[
          for (final Object? v in listeJson(l, 'ligne'))
            if (v is String) v else throw const FormatException('valeur'),
        ],
    ],
    manquants: <EnseignantSansCoordonnees>[
      for (final Object? m in listeJson(j['manquants'], 'manquants'))
        _manquant(objetJson(m, 'manquant')),
    ],
    total: montantJson(j['total'], 'total'),
  );
}

EnseignantSansCoordonnees _manquant(Map<String, dynamic> m) =>
    EnseignantSansCoordonnees(
      enseignantId: texteJson(m, 'enseignantId'),
      nom: texteJson(m, 'nom'),
      matricule: texteNullableJson(m, 'matricule'),
      montant: montantJson(m['montant'], 'montant'),
      aucune: texteJson(m, 'raison') == 'aucune',
      aValider: texteJson(m, 'raison') == 'a_valider',
    );

/// Les coordonnees de versement servies par Supabase.
class CoordonneesVersementSupabase implements PortCoordonneesVersement {
  /// Cree l'adaptateur sur le client de l'application.
  CoordonneesVersementSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client);

  /// Cree l'adaptateur sur un appel injecte (tests).
  CoordonneesVersementSupabase.avecAppel(this._appel);

  final AppelRpc _appel;

  @override
  Future<MesCoordonneesVersement> mesCoordonnees() async {
    try {
      return mesCoordonneesJson(
        await appelerFinance(_appel, 'mes_coordonnees_versement', _dependance),
      );
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const CapaciteIndisponible(_dependance);
      rethrow;
    }
  }

  @override
  Future<MesCoordonneesVersement> enregistrer({
    required String deviseCible,
    required Map<ChampVersement, String> valeurs,
    bool compteAMonNom = true,
    LienTitulaire? lien,
    bool autorisation = false,
  }) async {
    try {
      return mesCoordonneesJson(
        await appelerFinance(
          _appel,
          'enregistrer_mes_coordonnees_versement',
          _dependance,
          <String, dynamic>{
            'p_devise_cible': deviseCible,
            'p_titulaire': valeurs[ChampVersement.titulaire],
            'p_numero_compte': valeurs[ChampVersement.numeroCompte],
            'p_iban': valeurs[ChampVersement.iban],
            'p_swift': valeurs[ChampVersement.swift],
            'p_adresse_pays': valeurs[ChampVersement.adressePays],
            'p_adresse_ville': valeurs[ChampVersement.adresseVille],
            'p_adresse_ligne': valeurs[ChampVersement.adresseLigne],
            'p_code_postal': valeurs[ChampVersement.codePostal],
            'p_adresse_etat': valeurs[ChampVersement.adresseEtat],
            'p_compte_a_mon_nom': compteAMonNom,
            'p_lien_titulaire': compteAMonNom ? null : lien?.code,
            'p_autorisation': !compteAMonNom && autorisation,
          },
        ),
      );
    } on PostgrestException catch (e) {
      if (e.code == 'P0001' && e.message.contains('pays_indisponible')) {
        throw const PaysVersementIndisponible();
      }
      rethrow;
    }
  }

  @override
  Future<MesCoordonneesVersement> retirer() async => mesCoordonneesJson(
    await appelerFinance(
      _appel,
      'retirer_mes_coordonnees_versement',
      _dependance,
    ),
  );

  @override
  Future<List<EntreeJournalCoordonnees>> journal() async =>
      <EntreeJournalCoordonnees>[
        for (final Object? e in listeJson(
          await appelerFinance(
            _appel,
            'mon_journal_coordonnees_versement',
            _dependance,
          ),
          'journal',
        ))
          _entree(objetJson(e, 'entree')),
      ];

  EntreeJournalCoordonnees _entree(Map<String, dynamic> j) =>
      EntreeJournalCoordonnees(
        id: texteJson(j, 'id'),
        date: instantJson(j['le'], 'le'),
        retrait: texteJson(j, 'objet') == 'coordonnees_retirees',
        validee: texteJson(j, 'objet') == 'coordonnees_validees',
      );

  @override
  Future<ExportWise> exporter(DateTime mois) async {
    try {
      return exportWiseJson(
        await appelerFinance(
          _appel,
          'versement_export_wise',
          _dependance,
          <String, dynamic>{'p_mois': _date(mois)},
        ),
      );
    } on PostgrestException catch (e) {
      if (e.code == 'P0001' && e.message.contains('modele_wise_absent')) {
        throw const ModeleWiseAbsent();
      }
      rethrow;
    }
  }

  @override
  Future<List<EnseignantVersement>> enseignants() async {
    final Map<String, dynamic> j = objetJson(
      await appelerFinance(
        _appel,
        'versement_coordonnees_direction',
        _dependance,
      ),
      'versement_coordonnees_direction',
    );
    return <EnseignantVersement>[
      for (final Object? e in listeJson(j['enseignants'], 'enseignants'))
        _enseignant(objetJson(e, 'enseignant')),
    ];
  }

  EnseignantVersement _enseignant(Map<String, dynamic> e) {
    final String nom = <String?>[
      texteNullableJson(e, 'prenom'),
      texteNullableJson(e, 'nom'),
    ].whereType<String>().where((String s) => s.isNotEmpty).join(' ');
    final String? autorise = texteNullableJson(e, 'autoriseLe');
    final String? enregistre = texteNullableJson(e, 'enregistreLe');
    final Object? aMonNom = e['compteAMonNom'];
    return EnseignantVersement(
      enseignantId: texteJson(e, 'enseignantId'),
      nom: nom,
      matricule: texteNullableJson(e, 'matricule'),
      complet: booleenJson(e, 'complet'),
      valide: booleenJson(e, 'valide'),
      coordonneesId: texteNullableJson(e, 'coordonneesId'),
      titulaire: texteNullableJson(e, 'titulaire'),
      compteAMonNom: aMonNom is bool ? aMonNom : true,
      lienTitulaire: LienTitulaire.depuisCode(
        texteNullableJson(e, 'lienTitulaire'),
      ),
      autoriseLe: autorise == null ? null : instantJson(autorise, 'autoriseLe'),
      pays: texteNullableJson(e, 'pays'),
      numeroMasque: texteNullableJson(e, 'numeroMasque'),
      enregistreLe: enregistre == null
          ? null
          : instantJson(enregistre, 'enregistreLe'),
    );
  }

  @override
  Future<void> valider({
    required String enseignantId,
    required String coordonneesId,
  }) async {
    await appelerFinance(
      _appel,
      'valider_coordonnees_versement',
      _dependance,
      <String, dynamic>{
        'p_enseignant': enseignantId,
        'p_coordonnees': coordonneesId,
      },
    );
  }
}
