// N1 (02/11/2026) : les alertes de la direction sur les signalements des
// enseignants (`signalements_ouverts_direction()`, migration 20261018160000,
// jamais appelee jusqu'ici), a la place de `AlertesIndisponibles`.
//
// * Gravite : un signalement « Sécurité d'un enfant » (`prioritaire`) est
//   urgent ; tout autre signalement ouvert est important.
// * Le titre est redige ici depuis les donnees du serveur (categorie,
//   matricule de l'eleve, note interne), dans slang. La note interne n'est
//   lue que par la direction : la fonction refuse toute autre personne.
// * Suivi : une lecture a l'ouverture, puis une par minute tant que l'ecran
//   ecoute. Le temps reel (DASH-BR-04) n'existe pas encore.
// * D1-bis (03/11/2026) : la ligne mene a la page des alertes, ou le
//   signalement se traite en feuille (examiner, transmettre, clore) ; cet
//   adaptateur sait aussi traiter (`PortTraitementSignalement`).
// * Une personne qui n'est pas de la direction, ou une fonction absente, rend
//   « indisponible » : la cloche et le bandeau ne s'affichent pas.

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../capacites/capacite_indisponible.dart';
import '../communications/communications_supabase.dart';
import '../i18n/strings.g.dart';
import '../router/routes.dart';
import 'alerte.dart';
import 'port_alertes.dart';
import 'traitement_signalement.dart';

/// Les alertes servies par Supabase.
class AlertesSupabase implements PortAlertes, PortTraitementSignalement {
  /// Cree l'adaptateur sur un appel RPC ; [intervalle] separe deux lectures.
  const AlertesSupabase(
    this._appel, {
    this.intervalle = const Duration(minutes: 1),
  });

  final AppelRpc _appel;

  /// Le temps entre deux lectures.
  final Duration intervalle;

  /// Ce que rend une lecture refusee.
  static const CapaciteIndisponible manque = CapaciteIndisponible(
    AlertesIndisponibles.dependance,
  );

  /// Une lecture des signalements ouverts.
  Future<List<Alerte>> lire() async {
    final Object? brut;
    try {
      brut = await _appel(
        'signalements_ouverts_direction',
        <String, dynamic>{},
      );
    } on Object catch (e) {
      // La garde de la fonction leve sans code propre (P0001) : c'est un
      // refus de lecture, pas une panne.
      if (estRefusOuAbsence(e) ||
          (e is PostgrestException && e.code == 'P0001')) {
        throw manque;
      }
      rethrow;
    }
    if (brut == null) return const <Alerte>[];
    return <Alerte>[
      for (final Map<String, dynamic> s in listeJson(brut))
        alerteSignalementJson(s),
    ];
  }

  @override
  Stream<List<Alerte>> suivre() {
    Timer? minuterie;
    late final StreamController<List<Alerte>> flux;
    var arrete = false;

    Future<void> relever() async {
      try {
        final List<Alerte> alertes = await lire();
        if (!arrete) flux.add(alertes);
      } on CapaciteIndisponible catch (e, pile) {
        // Indisponible : on le dit une fois et on cesse de relire.
        minuterie?.cancel();
        if (!arrete) flux.addError(e, pile);
      } on Object catch (e, pile) {
        if (!arrete) flux.addError(e, pile);
      }
    }

    flux = StreamController<List<Alerte>>(
      onListen: () {
        unawaited(relever());
        minuterie = Timer.periodic(intervalle, (_) => unawaited(relever()));
      },
      onCancel: () {
        arrete = true;
        minuterie?.cancel();
        unawaited(flux.close());
      },
    );
    return flux.stream;
  }

  /// Un geste de traitement : un refus de garde (P0001) est une transition
  /// refusee, un refus de droit ou une fonction absente, l'indisponibilite.
  Future<void> _geste(String fonction, Map<String, dynamic> params) async {
    try {
      await _appel(fonction, params);
    } on Object catch (e) {
      if (estRefusOuAbsence(e)) throw manque;
      if (e is PostgrestException && e.code == 'P0001') {
        throw TransitionRefusee(e.message);
      }
      rethrow;
    }
  }

  @override
  Future<void> examiner(String id) =>
      _geste('examiner_student_concern', <String, dynamic>{'p_concern_id': id});

  @override
  Future<void> rediger(String id, String resume) => _geste(
    'rediger_resume_student_concern',
    <String, dynamic>{'p_concern_id': id, 'p_resume': resume},
  );

  @override
  Future<void> transmettre(String id, CibleTransmission cible) =>
      _geste('transmettre_student_concern', <String, dynamic>{
        'p_concern_id': id,
        'p_cible': switch (cible) {
          CibleTransmission.tuteurDuMineur => 'tuteur_du_mineur',
          CibleTransmission.eleveAdulte => 'eleve_adulte',
        },
      });

  @override
  Future<void> clore(String id, {String? motif}) => _geste(
    'clore_student_concern',
    <String, dynamic>{'p_concern_id': id, 'p_motif': motif},
  );
}

/// Le signalement d'une ligne de la file, avec ses capacites.
SignalementATraiter signalementJson(Map<String, dynamic> m) =>
    SignalementATraiter(
      id: texteJson(m, 'id'),
      categorie: texteJson(m, 'categorie'),
      prioritaire: m['prioritaire'] == true,
      matricule: texteJson(m, 'academy_id'),
      note: (texteOptionnel(m, 'internal_details') ?? '').trim(),
      statut: switch (texteOptionnel(m, 'statut')) {
        'en_examen' => StatutSignalement.enExamen,
        'transmis' => StatutSignalement.transmis,
        _ => StatutSignalement.ouvert,
      },
      recuLe: instantJson(m, 'cree_le'),
      resume: texteOptionnel(m, 'family_summary'),
      cible: switch (texteOptionnel(m, 'cible')) {
        'tuteur_du_mineur' => CibleTransmission.tuteurDuMineur,
        'eleve_adulte' => CibleTransmission.eleveAdulte,
        _ => null,
      },
      peutExaminer: m['peut_examiner'] == true,
      peutRediger: m['peut_rediger'] == true,
      peutTransmettre: m['peut_transmettre'] == true,
      peutClore: m['peut_clore'] == true,
      // Absent (serveur d'avant D1-bis) : le motif est exige, par prudence.
      motifRequis: m['motif_cloture_requis'] != false,
    );

/// Une alerte redigee depuis une ligne de `signalements_ouverts_direction`.
Alerte alerteSignalementJson(Map<String, dynamic> m) {
  final c = t.tc.parcours.signalement.categorieValeur;
  final String categorie = switch (texteJson(m, 'categorie')) {
    'securite_enfant' => c.securiteEnfant,
    'pedagogique' => c.pedagogique,
    'presence' => c.presence,
    'technique' => c.technique,
    'changement' => c.changement,
    _ => c.autre,
  };
  return Alerte(
    id: 'signalement-${texteJson(m, 'id')}',
    gravite: m['prioritaire'] == true
        ? GraviteAlerte.urgent
        : GraviteAlerte.important,
    titre: t.n1.alertes.signalement(
      categorie: categorie,
      matricule: texteJson(m, 'academy_id'),
      note: (texteOptionnel(m, 'internal_details') ?? '').trim(),
    ),
    creeeLe: instantJson(m, 'cree_le'),
    destination: Routes.adminAlertes,
    signalement: signalementJson(m),
  );
}
