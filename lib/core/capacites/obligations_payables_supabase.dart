// Adaptateur CPT-BR-01, lecture seule (B2.5, migration 20261102200000) : la
// paie des enseignants par mois, lue par `releve_paie_mensuel` et
// `releve_paie_seances`. Le serveur borne la lecture a la direction et a la
// comptabilite (42501 sinon).
//
// **Aucun calcul** : chaque montant arrive arrete par le serveur, qui le lit
// dans l'ecriture de paie de chaque seance (taux x eleves presents x heures).
// Une ligne = un enseignant pour un mois (le mois en cours et le precedent).
//
// Ce qui reste indisponible, faute de source serveur : le paiement lui-meme
// (aucune permission n'est rendue, la page ne propose donc pas « Payer »),
// la destination de paiement, « Signaler un ecart » et le journal. Le releve
// n'a pas de date de versement en base : l'echeance rendue est le dernier
// jour du mois du releve.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../comptable/modeles_comptable.dart';
import '../comptable/statuts_comptable.dart';
import '../finance/montant.dart';
import '../i18n/strings.g.dart';
import 'capacite_indisponible.dart';
import 'port_obligations_payables.dart';
import 'rpc_finance_supabase.dart';

const String _dependance = 'CPT-BR-01';
const CapaciteIndisponible _manque = CapaciteIndisponible(_dependance);

/// Les obligations payables des enseignants servies par Supabase.
class ObligationsPayablesSupabase implements PortObligationsPayables {
  /// Cree l'adaptateur sur le client de l'application.
  ObligationsPayablesSupabase(SupabaseClient client)
    : _appel = appelRpcSupabase(client),
      _maintenant = DateTime.now;

  /// Cree l'adaptateur sur un appel et une horloge injectes (tests).
  ObligationsPayablesSupabase.avecAppel(
    this._appel, [
    this._maintenant = DateTime.now,
  ]);

  final AppelRpc _appel;
  final DateTime Function() _maintenant;

  @override
  Future<List<ObligationPayable>> liste(FiltreObligations filtre) async {
    // Le releve ne porte que la paie calculee des enseignants : aucun
    // contractuel, aucun etat de paiement (pret, infos, verification...).
    if (filtre.type == TypeBeneficiaire.contractuel || filtre.filtre != null) {
      return const <ObligationPayable>[];
    }
    final DateTime ici = _maintenant();
    final DateTime mois = DateTime(ici.year, ici.month);
    final List<ObligationPayable> toutes = <ObligationPayable>[
      ...await _mois(DateTime(mois.year, mois.month - 1)),
      ...await _mois(mois),
    ];
    final String? classe = filtre.classe;
    return List<ObligationPayable>.unmodifiable(<ObligationPayable>[
      for (final ObligationPayable o in toutes)
        if (classe == null || o.classes.contains(classe)) o,
    ]);
  }

  Future<List<ObligationPayable>> _mois(DateTime mois) async {
    final Object? brut = await appelerFinance(
      _appel,
      'releve_paie_mensuel',
      _dependance,
      <String, dynamic>{'p_mois': _jour(mois)},
    );
    return decoderReleve(brut);
  }

  @override
  Future<ObligationPayable> detail(String obligationId) async {
    final ({String enseignant, DateTime mois})? cle = _lireId(obligationId);
    if (cle == null) {
      throw FormatException('obligation inconnue: $obligationId');
    }
    final Object? brut = await appelerFinance(
      _appel,
      'releve_paie_seances',
      _dependance,
      <String, dynamic>{
        'p_mois': _jour(cle.mois),
        'p_enseignant': cle.enseignant,
      },
    );
    return decoderDetail(brut);
  }

  /// Aucun signalement d'ecart cote serveur.
  @override
  Future<SignalementEcart> signalerEcart({
    required String obligationId,
    required String ligneId,
    required String motif,
    required String cleIdempotence,
  }) => Future<SignalementEcart>.error(_manque);

  /// Aucun journal de paie cote serveur.
  @override
  Future<List<EntreeJournal>> journal(String obligationId) =>
      Future<List<EntreeJournal>>.error(_manque);

  /// Decode la reponse de `releve_paie_mensuel`, une obligation par
  /// enseignant, sans rien recalculer.
  static List<ObligationPayable> decoderReleve(Object? brut) {
    final Map<String, dynamic> j = objetJson(brut, 'releve');
    final DateTime debut = dateJson(j['debut'], 'debut');
    final DateTime fin = dateJson(j['fin'], 'fin');
    return List<ObligationPayable>.unmodifiable(<ObligationPayable>[
      for (final Object? e in listeJson(j['enseignants'], 'enseignants'))
        _ligne(objetJson(e, 'enseignant'), debut, fin),
    ]);
  }

  static ObligationPayable _ligne(
    Map<String, dynamic> e,
    DateTime debut,
    DateTime fin,
  ) {
    final String id = texteJson(e, 'enseignantId');
    final int enAttente = entierJson(e, 'seancesEnAttente');
    final Montant montant = montantJson(e['montant'], 'montant');
    return ObligationPayable(
      id: idObligation(id, debut),
      version: '${montant.mineur}-${entierJson(e, 'seancesTenues')}-$enAttente',
      periode: periodeDe(debut),
      beneficiaire: IdentiteBeneficiaire(
        id: id,
        nom: _nom(e),
        type: TypeBeneficiaire.enseignant,
      ),
      montant: montant,
      etat: enAttente > 0
          ? EtatPaiementSortant.aVerifier
          : EtatPaiementSortant.calcule,
      echeance: fin,
      classes: List<String>.unmodifiable(<String>[
        for (final Object? c in listeJson(e['classes'], 'classes'))
          if (c is String && c.isNotEmpty) c,
      ]),
    );
  }

  /// Decode la reponse de `releve_paie_seances` : une ligne de calcul par
  /// seance, sa source dit les eleves presents sur les inscrits.
  static ObligationPayable decoderDetail(Object? brut) {
    final Map<String, dynamic> j = objetJson(brut, 'detail');
    final DateTime debut = dateJson(j['debut'], 'debut');
    final Map<String, dynamic> e = objetJson(j['enseignant'], 'enseignant');
    final String id = texteJson(e, 'enseignantId');
    final List<LigneCalcul> lignes = <LigneCalcul>[];
    final Set<String> classes = <String>{};
    bool attente = false;
    for (final Object? brutSeance in listeJson(j['seances'], 'seances')) {
      final Map<String, dynamic> s = objetJson(brutSeance, 'seance');
      final String classe = texteJson(s, 'classe');
      final bool enAttente = booleenJson(s, 'enAttente');
      attente = attente || enAttente;
      classes.add(classe);
      final Montant? montant = montantNullableJson(s['montant'], 'montant');
      lignes.add(
        LigneCalcul(
          id: texteJson(s, 'seanceId'),
          libelle: classe,
          // Une seance en attente n'a pas de montant : la ligne vaut zero.
          montant: montant ?? Montant(0, texteJson(j, 'devise')),
          source: enAttente
              ? t.etat.enAttente
              : t.tc.classe.roster.compteur(
                  presents: entierJson(s, 'elevesPresents'),
                  attendus: entierJson(s, 'elevesInscrits'),
                ),
          date: instantJson(s['debut'], 'debut'),
        ),
      );
    }
    final Montant total = montantJson(j['total'], 'total');
    return ObligationPayable(
      id: idObligation(id, debut),
      version: '${total.mineur}-${lignes.length}',
      periode: periodeDe(debut),
      beneficiaire: IdentiteBeneficiaire(
        id: id,
        nom: _nom(e),
        type: TypeBeneficiaire.enseignant,
      ),
      montant: total,
      etat: attente
          ? EtatPaiementSortant.aVerifier
          : EtatPaiementSortant.calcule,
      echeance: dateJson(j['fin'], 'fin'),
      lignes: List<LigneCalcul>.unmodifiable(lignes),
      classes: List<String>.unmodifiable(classes.toList()..sort()),
    );
  }

  /// L'identifiant d'une ligne du releve : enseignant et mois.
  static String idObligation(String enseignant, DateTime mois) =>
      '${enseignant}_${_jour(mois)}';

  /// « Octobre 2026 ».
  static String periodeDe(DateTime mois) {
    final String p = t.commun.dates.moisAnnee(
      mois: t.commun.dates.mois[mois.month - 1],
      annee: mois.year,
    );
    // Le mois ouvre la cellule : majuscule initiale (sans effet en arabe).
    return p.isEmpty ? p : p[0].toUpperCase() + p.substring(1);
  }

  static ({String enseignant, DateTime mois})? _lireId(String id) {
    final int i = id.lastIndexOf('_');
    if (i <= 0) return null;
    final DateTime? mois = DateTime.tryParse(id.substring(i + 1));
    if (mois == null) return null;
    return (enseignant: id.substring(0, i), mois: mois);
  }

  static String _nom(Map<String, dynamic> e) => <String?>[
    texteNullableJson(e, 'prenom'),
    texteNullableJson(e, 'nom'),
  ].whereType<String>().join(' ');

  static String _jour(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-01';
}
