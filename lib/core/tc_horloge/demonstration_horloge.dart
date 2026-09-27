import 'dart:async';

import 'package:flutter/foundation.dart';

import 'port_horloge_seance.dart';
// `session_clock_vm.dart` reexporte `FenetreSeance` et `PhaseSeance` : une
// seule porte d'entree pour le temps, comme le veut l'unification.
import 'session_clock_vm.dart';

/// L'instant serveur de reference du jeu de demonstration.
///
/// **Le double est ancre, et ce n'est pas un raccourci de paresse.**
/// `HorlogeAffichee.heureLocaleRendue` est une chaine **deja convertie**, et
/// aucune capacite ne sait la produire aujourd'hui : le depot n'a ni `timezone`,
/// ni `tz`, ni `intl`, `pubspec.yaml` est gele, et aucune RPC ne rend de
/// conversion. Un double qui lirait l'heure reelle afficherait donc un compte a
/// rebours vivant a cote d'heures fausses.
///
/// Ancre le double sur un instant fixe rend au contraire l'ensemble
/// **coherent** : « Lundi 21 septembre, 18:00 Riyad, 15:00 Conakry, cours dans
/// 3 h 28 » se verifie ligne a ligne. Agent Z peut injecter
/// `() => DateTime.now().toUtc()` pour voir le compte a rebours bouger, en
/// sachant qu'il echange la coherence des heures contre du mouvement.
final DateTime ancreDemonstration = DateTime.utc(2026, 9, 21, 11, 32);

/// Les identifiants des groupes de demonstration.
///
/// Ils sont declares ici, du cote du temps, parce que c'est le temps qui donne
/// a chaque groupe l'etat qu'il illustre. `lib/core/tc_groupe/` les reprend.
abstract final class GroupesDemonstration {
  /// Avant la fenetre : compte a rebours long, aucun bouton.
  static const String alFatiha = 'demo-groupe-al-fatiha';

  /// Salle ouverte : le bouton apparait, le cours n'a pas commence.
  static const String anNour = 'demo-groupe-an-nour';

  /// Deja connecte avant T0 : attente, aucun temps academique consomme.
  static const String alIhsan = 'demo-groupe-al-ihsan';

  /// Cours en cours : compte a rebours descendant du temps restant.
  static const String alBaqara = 'demo-groupe-al-baqara';

  /// Prolongation : « Cours toujours en cours », aucun nombre negatif.
  static const String alHikma = 'demo-groupe-al-hikma';

  /// Seance terminee : retour a la prochaine, bouton ferme.
  static const String arRahma = 'demo-groupe-ar-rahma';

  /// Aucune occurrence materialisee : l'etat reel du depot aujourd'hui.
  static const String sabil = 'demo-groupe-sabil';
}

/// Ce que le serveur devra rendre pour une occurrence, reuni en un objet.
///
/// Chaque champ correspond a une capacite qui **manque** aujourd'hui, et la
/// demande correspondante est chiffree dans
/// `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_A.md`.
@immutable
class DonneeSeanceDemonstration {
  /// Cree une donnee de demonstration.
  const DonneeSeanceDemonstration({
    required this.fenetre,
    required this.horlogeUtilisateur,
    this.sessionId,
    this.horlogeContrepartie,
    this.connecte = false,
    this.seanceOuverte,
    this.noticeDst,
  });

  /// Les bornes de l'occurrence.
  final FenetreSeance fenetre;

  /// L'heure de la personne qui regarde, deja rendue.
  final HorlogeAffichee horlogeUtilisateur;

  /// L'heure de l'enseignant ou du groupe, deja rendue.
  final HorlogeAffichee? horlogeContrepartie;

  /// Identifiant de seance, `null` si l'occurrence n'est pas materialisee.
  final String? sessionId;

  /// Vrai quand la personne est deja entree dans la salle.
  final bool connecte;

  /// Ce que le serveur declare de l'etat de la seance apres sa fin prevue.
  final bool? seanceOuverte;

  /// L'avertissement de changement d'heure, quand il y en a un.
  final NoticeDst? noticeDst;
}

/// Le jeu de demonstration : six groupes, six etats du temps.
///
/// Les heures rendues sont coherentes avec [ancreDemonstration] : Riyad est en
/// avance de trois heures sur Conakry ce jour-la, Paris de deux. Ces relations
/// ne sont **calculees nulle part** : ce sont des chaines de fixture, produites
/// une fois pour que l'interface ait quelque chose de juste a montrer.
Map<String, DonneeSeanceDemonstration> seancesDemonstration() {
  const Duration fenetreAcces = Duration(minutes: 20);
  const Duration grace = Duration(minutes: 15);

  return <String, DonneeSeanceDemonstration>{
    // 11:32 + 3 h 28 = 15:00 UTC, soit 18:00 a Riyad et 15:00 a Conakry.
    GroupesDemonstration.alFatiha: DonneeSeanceDemonstration(
      fenetre: FenetreSeance(
        debutUtc: DateTime.utc(2026, 9, 21, 15),
        finPrevueUtc: DateTime.utc(2026, 9, 21, 16, 30),
        fenetreAcces: fenetreAcces,
        graceApresFin: grace,
      ),
      horlogeUtilisateur: const HorlogeAffichee(
        fuseauIana: 'Asia/Riyadh',
        libelleVille: 'Riyad',
        heureLocaleRendue: '18:00',
        dateLocaleRendue: 'Lundi 21 septembre',
      ),
      horlogeContrepartie: const HorlogeAffichee(
        fuseauIana: 'Africa/Conakry',
        libelleVille: 'Conakry',
        heureLocaleRendue: '15:00',
        dateLocaleRendue: 'Lundi 21 septembre',
      ),
      sessionId: 'demo-seance-al-fatiha',
    ),

    // 11:45 UTC : dans 13 minutes, donc la salle est ouverte depuis 11:25.
    // Un seul fuseau des deux cotes : la contrepartie est volontairement nulle.
    GroupesDemonstration.anNour: DonneeSeanceDemonstration(
      fenetre: FenetreSeance(
        debutUtc: DateTime.utc(2026, 9, 21, 11, 45),
        finPrevueUtc: DateTime.utc(2026, 9, 21, 13, 15),
        fenetreAcces: fenetreAcces,
        graceApresFin: grace,
      ),
      horlogeUtilisateur: const HorlogeAffichee(
        fuseauIana: 'Europe/Paris',
        libelleVille: 'Paris',
        heureLocaleRendue: '13:45',
        dateLocaleRendue: 'Lundi 21 septembre',
      ),
      sessionId: 'demo-seance-an-nour',
    ),

    // 11:50 UTC, et la personne est deja entree : etat d'attente. Le compte a
    // rebours vise toujours le DEBUT, et l'interface dit que ces minutes ne
    // comptent pas dans la presence academique.
    GroupesDemonstration.alIhsan: DonneeSeanceDemonstration(
      fenetre: FenetreSeance(
        debutUtc: DateTime.utc(2026, 9, 21, 11, 50),
        finPrevueUtc: DateTime.utc(2026, 9, 21, 12, 50),
        fenetreAcces: fenetreAcces,
        graceApresFin: grace,
      ),
      horlogeUtilisateur: const HorlogeAffichee(
        fuseauIana: 'Europe/Paris',
        libelleVille: 'Paris',
        heureLocaleRendue: '13:50',
        dateLocaleRendue: 'Lundi 21 septembre',
      ),
      horlogeContrepartie: const HorlogeAffichee(
        fuseauIana: 'Africa/Conakry',
        libelleVille: 'Conakry',
        heureLocaleRendue: '11:50',
        dateLocaleRendue: 'Lundi 21 septembre',
      ),
      sessionId: 'demo-seance-al-ihsan',
      connecte: true,
    ),

    // Commencee a 11:00, se termine a 12:00 : il reste 28 minutes.
    // Porte l'avertissement de changement d'heure, a sept jours.
    GroupesDemonstration.alBaqara: DonneeSeanceDemonstration(
      fenetre: FenetreSeance(
        debutUtc: DateTime.utc(2026, 9, 21, 11),
        finPrevueUtc: DateTime.utc(2026, 9, 21, 12),
        fenetreAcces: fenetreAcces,
        graceApresFin: grace,
      ),
      horlogeUtilisateur: const HorlogeAffichee(
        fuseauIana: 'Europe/Paris',
        libelleVille: 'Paris',
        heureLocaleRendue: '13:00',
        dateLocaleRendue: 'Lundi 21 septembre',
      ),
      horlogeContrepartie: const HorlogeAffichee(
        fuseauIana: 'Africa/Conakry',
        libelleVille: 'Conakry',
        heureLocaleRendue: '11:00',
        dateLocaleRendue: 'Lundi 21 septembre',
      ),
      sessionId: 'demo-seance-al-baqara',
      connecte: true,
      noticeDst: NoticeDst(
        transitionUtc: DateTime.utc(2026, 10, 25, 1),
        fuseauConcerne: 'Europe/Paris',
        heureAvantRendue: '13:00',
        heureApresRendue: '12:00',
        echeance: EcheanceDst.j7,
      ),
    ),

    // Fin prevue a 11:30, il est 11:32 : la seance deborde et le serveur la
    // declare encore ouverte. Aucun nombre negatif ne doit apparaitre.
    GroupesDemonstration.alHikma: DonneeSeanceDemonstration(
      fenetre: FenetreSeance(
        debutUtc: DateTime.utc(2026, 9, 21, 10, 30),
        finPrevueUtc: DateTime.utc(2026, 9, 21, 11, 30),
        fenetreAcces: fenetreAcces,
        graceApresFin: grace,
      ),
      horlogeUtilisateur: const HorlogeAffichee(
        fuseauIana: 'Europe/Paris',
        libelleVille: 'Paris',
        heureLocaleRendue: '12:30',
        dateLocaleRendue: 'Lundi 21 septembre',
      ),
      sessionId: 'demo-seance-al-hikma',
      connecte: true,
      seanceOuverte: true,
    ),

    // Finie a 11:00, grace epuisee a 11:15 : terminee.
    GroupesDemonstration.arRahma: DonneeSeanceDemonstration(
      fenetre: FenetreSeance(
        debutUtc: DateTime.utc(2026, 9, 21, 10),
        finPrevueUtc: DateTime.utc(2026, 9, 21, 11),
        fenetreAcces: fenetreAcces,
        graceApresFin: grace,
      ),
      horlogeUtilisateur: const HorlogeAffichee(
        fuseauIana: 'Europe/Paris',
        libelleVille: 'Paris',
        heureLocaleRendue: '12:00',
        dateLocaleRendue: 'Lundi 21 septembre',
      ),
      sessionId: 'demo-seance-ar-rahma',
      seanceOuverte: false,
    ),
    // `GroupesDemonstration.sabil` n'a volontairement aucune entree : c'est
    // l'etat reel de la base aujourd'hui, ou un groupe cree ne produit aucune
    // occurrence.
  };
}

/// Le double local du port du temps.
///
/// **Ce n'est pas une implementation de production, et il ne doit pas le
/// devenir.** Les trois capacites serveur qu'il simule (`join_opens_at`
/// configurable, horloge serveur, conversions rendues) sont chiffrees dans
/// `docs/archive/2026-09-pre-remise-a-plat/teaching-core/TC_CONTRACT_REQUEST_A.md`.
class HorlogeSeanceDemonstration implements PortHorlogeSeance {
  /// Cree le double.
  ///
  /// [horloge] permet de deplacer l'instant serveur simule : les tests
  /// l'utilisent pour parcourir la machine d'etats sans attendre.
  HorlogeSeanceDemonstration({
    Map<String, DonneeSeanceDemonstration>? seances,
    DateTime Function()? horloge,
    this.cadence = const Duration(seconds: 30),
  }) : _seances = seances ?? seancesDemonstration(),
       _horloge = horloge ?? (() => ancreDemonstration);

  final Map<String, DonneeSeanceDemonstration> _seances;
  final DateTime Function() _horloge;

  /// La cadence de rafraichissement du flux.
  ///
  /// **Decidee ici, jamais par un widget** : un compte a rebours qui se lit en
  /// minutes n'a pas besoin d'une reconstruction par seconde.
  ///
  /// Une cadence nulle emet une seule valeur puis ferme le flux. C'est ce dont
  /// un test de widget a besoin : un minuteur qui survit a la fin d'un test
  /// fait echouer le suivant, et c'est exactement le defaut deja documente dans
  /// `lib/core/presence/service_presence.dart`.
  final Duration cadence;

  SessionClockVM? _calculer(String groupeId) {
    final DonneeSeanceDemonstration? donnee = _seances[groupeId];
    if (donnee == null) {
      return null;
    }
    return SessionClockVM.depuisFenetre(
      fenetre: donnee.fenetre,
      maintenantServeurUtc: _horloge(),
      horlogeUtilisateur: donnee.horlogeUtilisateur,
      sessionId: donnee.sessionId,
      horlogeContrepartie: donnee.horlogeContrepartie,
      connecte: donnee.connecte,
      seanceOuverte: donnee.seanceOuverte,
      noticeDst: donnee.noticeDst,
    );
  }

  @override
  Future<SessionClockVM?> horlogeDe({
    required String groupeId,
    String? sessionId,
  }) async => _calculer(groupeId);

  @override
  Stream<SessionClockVM> suivre({
    required String groupeId,
    String? sessionId,
  }) async* {
    final SessionClockVM? premiere = _calculer(groupeId);
    if (premiere == null) {
      return;
    }
    yield premiere;
    if (cadence <= Duration.zero) {
      return;
    }
    yield* Stream<void>.periodic(cadence)
        .map((void _) => _calculer(groupeId))
        .where((SessionClockVM? vm) => vm != null)
        .cast<SessionClockVM>();
  }

  @override
  Future<DateTime> maintenantServeurUtc() async => _horloge();
}
