import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/strings.g.dart';
import 'port_horloge_seance.dart';
import 'session_clock_vm.dart';

/// Rend « Lundi 21 septembre » depuis un jour ISO et une date `AAAA-MM-JJ`.
///
/// La base rend `jour_iso` (1 = lundi) et une `date` ISO : la mise en mots
/// se fait ici, sans aucun calcul de fuseau. Aucune regle IANA n'est jouee
/// cote client ; seule la mise en forme d'un jour et d'un mois deja resolus.
/// Les noms viennent des libelles (`commun.dates`), jamais d'une liste en dur.
String dateRendue({required int jourIso, required String dateIso}) {
  final List<String> parts = dateIso.split('-');
  final int mois = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
  final int jour = parts.length > 2 ? int.tryParse(parts[2]) ?? 1 : 1;
  return t.commun.dates.jourDate(
    jour: t.commun.dates.jours[(jourIso - 1).clamp(0, 6)],
    numero: jour,
    mois: t.commun.dates.mois[(mois - 1).clamp(0, 11)],
  );
}

/// Le nom de ville lisible d'un identifiant IANA : `Asia/Riyadh` donne
/// « Riyadh ». Jamais un décalage numérique.
String villeDeFuseau(String fuseauIana) {
  final String dernier = fuseauIana.split('/').last;
  return dernier.replaceAll('_', ' ');
}

/// Lit une ligne de `horloge_seance()` en horloge de seance.
///
/// Pure, testable sans client. Les phases et le temps restant sont derives par
/// [SessionClockVM.depuisFenetre] a partir de `maintenant_utc` **serveur**,
/// jamais de l'horloge de l'appareil.
SessionClockVM horlogeDepuisLigne(Map<String, dynamic> ligne) {
  final DateTime debut = DateTime.parse(ligne['debut_utc'] as String).toUtc();
  final DateTime fin = DateTime.parse(ligne['fin_prevue_utc'] as String)
      .toUtc();
  final DateTime maintenant = DateTime.parse(ligne['maintenant_utc'] as String)
      .toUtc();
  final String tzUtilisateur = ligne['tz_utilisateur'] as String;
  final String tzGroupe = ligne['tz_groupe'] as String;

  final FenetreSeance fenetre = FenetreSeance(
    debutUtc: debut,
    finPrevueUtc: fin,
    fenetreAcces: Duration(minutes: (ligne['fenetre_minutes'] as int?) ?? 0),
    graceApresFin: Duration(minutes: (ligne['grace_minutes'] as int?) ?? 0),
  );

  return SessionClockVM.depuisFenetre(
    fenetre: fenetre,
    maintenantServeurUtc: maintenant,
    sessionId: ligne['session_id'] as String?,
    horlogeUtilisateur: HorlogeAffichee(
      fuseauIana: tzUtilisateur,
      libelleVille: villeDeFuseau(tzUtilisateur),
      heureLocaleRendue: ligne['heure_utilisateur'] as String,
      dateLocaleRendue: dateRendue(
        jourIso: (ligne['jour_iso_utilisateur'] as int?) ?? 1,
        dateIso: ligne['date_utilisateur'] as String,
      ),
    ),
    horlogeContrepartie: HorlogeAffichee(
      fuseauIana: tzGroupe,
      libelleVille: villeDeFuseau(tzGroupe),
      heureLocaleRendue: ligne['heure_groupe'] as String,
      dateLocaleRendue: dateRendue(
        jourIso: (ligne['jour_iso_groupe'] as int?) ?? 1,
        dateIso: ligne['date_groupe'] as String,
      ),
    ),
  );
}

/// L'adaptateur reel du port du temps.
///
/// `horloge_seance(p_session_id)` et `maintenant_serveur()` (migrations `0030`
/// et `0033`, presentes en production) rendent tout deja converti. Sans
/// identifiant de seance, la prochaine seance de la Classe est demandee au
/// serveur (`prochaine_seance_groupe`, RACCORDEMENT-1016) ; sans prochaine
/// seance materialisee, ou pour un appelant que la Classe ne concerne pas,
/// il n'y a **rien a rendre** : `null`, pas une horloge fabriquee.
class HorlogeSeanceSupabase implements PortHorlogeSeance {
  /// Cree l'adaptateur.
  const HorlogeSeanceSupabase(this._client, {this.cadence = _cadenceDefaut});

  static const Duration _cadenceDefaut = Duration(seconds: 30);

  final SupabaseClient _client;

  /// La cadence de rafraichissement du flux. Decidee ici, jamais par un widget.
  final Duration cadence;

  @override
  Future<SessionClockVM?> horlogeDe({
    required String groupeId,
    String? sessionId,
  }) async {
    final String? seance = sessionId ?? await _prochaineSeance(groupeId);
    if (seance == null) {
      return null;
    }
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'horloge_seance',
      params: <String, dynamic>{'p_session_id': seance},
    );
    if (lignes.isEmpty) {
      return null;
    }
    return horlogeDepuisLigne(lignes.first as Map<String, dynamic>);
  }

  /// L'identifiant de la prochaine seance de la Classe, ou `null`. Un refus
  /// (42501 : la Classe ne concerne pas l'appelant) n'est pas une panne : il
  /// n'y a simplement rien a montrer.
  Future<String?> _prochaineSeance(String groupeId) async {
    try {
      final Object? id = await _client.rpc<Object?>(
        'prochaine_seance_groupe',
        params: <String, dynamic>{'p_groupe_id': groupeId},
      );
      return id is String && id.isNotEmpty ? id : null;
    } on PostgrestException catch (e) {
      if (e.code == '42501') return null;
      rethrow;
    }
  }

  /// La premiere lecture part tout de suite, puis a chaque [cadence] : la
  /// prochaine seance est relue a chaque tour, la suivante prend la place de
  /// celle qui vient de finir. Une lecture en echec est rendue comme erreur
  /// du flux, qui continue.
  @override
  Stream<SessionClockVM> suivre({
    required String groupeId,
    String? sessionId,
  }) async* {
    while (true) {
      try {
        final SessionClockVM? h = await horlogeDe(
          groupeId: groupeId,
          sessionId: sessionId,
        );
        if (h != null) yield h;
      } on Object catch (e, pile) {
        yield* Stream<SessionClockVM>.error(e, pile);
      }
      await Future<void>.delayed(cadence);
    }
  }

  @override
  Future<DateTime> maintenantServeurUtc() async {
    final dynamic reponse = await _client.rpc<dynamic>('maintenant_serveur');
    return DateTime.parse(reponse as String).toUtc();
  }
}
