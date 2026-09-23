import 'package:supabase_flutter/supabase_flutter.dart';

import 'port_horloge_seance.dart';
import 'session_clock_vm.dart';

/// Les jours et les mois tels que `horloge_seance` les rend en nombres.
///
/// La base rend `jour_iso` (1 = lundi) et une `date` ISO : la mise en mots
/// se fait ici, sans aucun calcul de fuseau. Aucune regle IANA n'est jouee
/// cote client ; seule la mise en forme d'un jour et d'un mois deja resolus.
const List<String> _jours = <String>[
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];
const List<String> _mois = <String>[
  'janvier',
  'fevrier',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'aout',
  'septembre',
  'octobre',
  'novembre',
  'decembre',
];

/// Rend « Lundi 21 septembre » depuis un jour ISO et une date `AAAA-MM-JJ`.
String dateRendue({required int jourIso, required String dateIso}) {
  final List<String> parts = dateIso.split('-');
  final int mois = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
  final int jour = parts.length > 2 ? int.tryParse(parts[2]) ?? 1 : 1;
  final String nomJour = _jours[(jourIso - 1).clamp(0, 6)];
  final String nomMois = _mois[(mois - 1).clamp(0, 11)];
  return '$nomJour $jour $nomMois';
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
  final DateTime fin = DateTime.parse(
    ligne['fin_prevue_utc'] as String,
  ).toUtc();
  final DateTime maintenant = DateTime.parse(
    ligne['maintenant_utc'] as String,
  ).toUtc();
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
/// identifiant de seance il n'y a **rien a rendre** : `null`, pas une horloge
/// fabriquee. C'est l'etat honnete d'un groupe dont aucune occurrence n'est
/// materialisee.
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
    if (sessionId == null) {
      return null;
    }
    final List<dynamic> lignes = await _client.rpc<List<dynamic>>(
      'horloge_seance',
      params: <String, dynamic>{'p_session_id': sessionId},
    );
    if (lignes.isEmpty) {
      return null;
    }
    return horlogeDepuisLigne(lignes.first as Map<String, dynamic>);
  }

  @override
  Stream<SessionClockVM> suivre({required String groupeId, String? sessionId}) {
    if (sessionId == null) {
      return const Stream<SessionClockVM>.empty();
    }
    return Stream<void>.periodic(cadence)
        .asyncMap((_) => horlogeDe(groupeId: groupeId, sessionId: sessionId))
        .where((SessionClockVM? h) => h != null)
        .cast<SessionClockVM>();
  }

  @override
  Future<DateTime> maintenantServeurUtc() async {
    final dynamic reponse = await _client.rpc<dynamic>('maintenant_serveur');
    return DateTime.parse(reponse as String).toUtc();
  }
}
