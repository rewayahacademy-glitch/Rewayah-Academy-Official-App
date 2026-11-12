// Fixtures d'horloge : les six etats d'une seance, les trois fuseaux, et le
// scenario de changement d'heure.
//
// PROPRIETE : Agent Q (test/teaching_core/fixtures/). Aucune ligne de
// production.
//
// REGLE STRUCTURANTE. Les heures locales de ce fichier sont des **donnees**,
// pas des calculs : `HorlogeAffichee.heureLocaleRendue` arrive deja rendue du
// serveur (CONTRACTS section 3, invariant 1), et le depot n'embarque de toute
// facon ni `timezone` ni `intl`. Aucune fonction d'ici ne convertit un fuseau,
// et aucune n'ajoute une `Duration(hours: 1)` pour changer de fuseau.

import 'package:rewayah_academy/core/tc_horloge/session_clock_vm.dart';

/// Le fuseau de reference du groupe dans nos scenarios.
const String fuseauParis = 'Europe/Paris';

/// Un fuseau sans changement d'heure, a l'ouest.
const String fuseauConakry = 'Africa/Conakry';

/// Un fuseau sans changement d'heure, a l'est.
const String fuseauRiyad = 'Asia/Riyadh';

/// La fenetre d'acces par defaut : T-20, **configurable** (decision D-13).
///
/// Elle est ici une donnee de fixture, pas une constante de produit. Le test
/// Q-02 verifie precisement qu'une fenetre differente deplace
/// `joinOpensAtUtc` : si elle etait codee en dur cote client, elle ne le
/// ferait pas.
const Duration fenetreAccesParDefaut = Duration(minutes: 20);

/// La tolerance apres la fin prevue, alignee sur `graceApresFin` du depot.
const Duration graceApresFinParDefaut = Duration(minutes: 15);

/// Le debut de la seance de reference : lundi 19 octobre 2026, 18h00 a Paris.
///
/// Paris est alors a l'heure d'ete (UTC+2), donc 16h00 UTC. Cette valeur est
/// **posee**, pas calculee : aucune conversion de fuseau n'a lieu en Dart.
final DateTime debutSeanceAvantDst = DateTime.utc(2026, 10, 19, 16);

/// La meme seance la semaine suivante : lundi 26 octobre 2026, 18h00 a Paris.
///
/// Le changement d'heure europeen est intervenu le dimanche 25 octobre 2026 a
/// 01h00 UTC. Paris est repasse a UTC+1, donc la meme seance de 18h00 tombe
/// maintenant a **17h00 UTC**.
///
/// L'ecart entre les deux occurrences vaut donc **169 heures, pas 168** :
/// c'est exactement ce qu'un `debut.add(Duration(days: 7))` raterait.
final DateTime debutSeanceApresDst = DateTime.utc(2026, 10, 26, 17);

/// L'instant de la transition d'heure d'ete vers heure d'hiver en Europe.
final DateTime transitionDstParis = DateTime.utc(2026, 10, 25, 1);

/// La duree d'une seance de reference.
const Duration dureeSeance = Duration(hours: 1, minutes: 30);

/// Les six instants d'observation, relatifs au debut de la seance.
///
/// L'ordre est celui du vecu : on attend, la salle ouvre, on entre, le cours
/// commence, il deborde, il se termine.
enum MomentSeance {
  /// Trente minutes avant : la fenetre n'est pas ouverte.
  tMoins30,

  /// Vingt minutes avant : la fenetre s'ouvre tout juste.
  tMoins20,

  /// Dix minutes avant, deja connecte : l'attente ne consomme rien.
  attenteConnecte,

  /// L'heure pile.
  t0,

  /// En plein cours.
  enDirect,

  /// Apres la fin prevue, la seance est encore ouverte.
  depassement,

  /// Apres la grace : terminee.
  terminee,
}

/// L'instant d'observation correspondant a un [MomentSeance].
DateTime instantDe(MomentSeance moment, {DateTime? debutUtc}) {
  final DateTime debut = debutUtc ?? debutSeanceAvantDst;
  return switch (moment) {
    MomentSeance.tMoins30 => debut.subtract(const Duration(minutes: 30)),
    MomentSeance.tMoins20 => debut.subtract(const Duration(minutes: 20)),
    MomentSeance.attenteConnecte => debut.subtract(const Duration(minutes: 10)),
    MomentSeance.t0 => debut,
    MomentSeance.enDirect => debut.add(const Duration(minutes: 45)),
    MomentSeance.depassement => debut.add(
      dureeSeance + const Duration(minutes: 5),
    ),
    MomentSeance.terminee => debut.add(
      dureeSeance + graceApresFinParDefaut + const Duration(minutes: 1),
    ),
  };
}

/// La phase d'une seance, calculee **uniquement** sur des instants UTC.
///
/// Fonction pure, sans horloge implicite : `maintenant` est un parametre, et
/// c'est `calculeeAUtc` cote contrat. Aucun offset de fuseau n'intervient --
/// une phase ne depend pas du pays d'ou on la regarde.
PhaseSeance phaseDe({
  required DateTime debutUtc,
  required DateTime finPrevueUtc,
  required DateTime joinOpensAtUtc,
  required DateTime maintenant,
  required bool connecte,
  Duration graceApresFin = graceApresFinParDefaut,
}) {
  if (maintenant.isBefore(joinOpensAtUtc)) return PhaseSeance.avantFenetre;
  if (maintenant.isBefore(debutUtc)) {
    // La distinction porte tout l'invariant 8 du chantier : etre connecte
    // avant T0 est une phase a part, precisement pour qu'aucune minute
    // academique ne s'y accumule.
    return connecte ? PhaseSeance.attenteAvantT0 : PhaseSeance.salleOuverte;
  }
  if (maintenant.isBefore(finPrevueUtc)) return PhaseSeance.enCours;
  if (maintenant.isBefore(finPrevueUtc.add(graceApresFin))) {
    return PhaseSeance.prolongee;
  }
  return PhaseSeance.terminee;
}

/// Le temps restant affichable pour une phase donnee.
///
/// `null` en [PhaseSeance.prolongee] et en [PhaseSeance.terminee] : un
/// countdown negatif ne s'affiche jamais (CONTRACTS section 3, invariant 3).
Duration? restantDe({
  required PhaseSeance phase,
  required DateTime debutUtc,
  required DateTime finPrevueUtc,
  required DateTime maintenant,
}) => switch (phase) {
  PhaseSeance.avantFenetre ||
  PhaseSeance.salleOuverte ||
  PhaseSeance.attenteAvantT0 => debutUtc.difference(maintenant),
  PhaseSeance.enCours => finPrevueUtc.difference(maintenant),
  PhaseSeance.prolongee || PhaseSeance.terminee => null,
};

/// Une horloge affichee, telle que le serveur la rend.
///
/// Les quatre chaines sont des **donnees de fixture**. Rien ici ne convertit
/// un fuseau : c'est la regle, pas une facilite.
HorlogeAffichee horlogeAffichee({
  required String fuseauIana,
  required String libelleVille,
  required String heureLocaleRendue,
  required String dateLocaleRendue,
}) => HorlogeAffichee(
  fuseauIana: fuseauIana,
  libelleVille: libelleVille,
  heureLocaleRendue: heureLocaleRendue,
  dateLocaleRendue: dateLocaleRendue,
);

/// L'horloge de Paris pour la seance d'avant le changement d'heure.
final HorlogeAffichee horlogeParisAvantDst = horlogeAffichee(
  fuseauIana: fuseauParis,
  libelleVille: 'Paris',
  heureLocaleRendue: '18:00',
  dateLocaleRendue: 'Lundi 19 octobre',
);

/// L'horloge de Paris pour la seance d'apres le changement d'heure.
///
/// **L'heure institutionnelle du groupe n'a pas bouge** : toujours 18:00.
/// C'est l'instant UTC qui a bouge, pas l'horaire affiche aux Parisiens.
final HorlogeAffichee horlogeParisApresDst = horlogeAffichee(
  fuseauIana: fuseauParis,
  libelleVille: 'Paris',
  heureLocaleRendue: '18:00',
  dateLocaleRendue: 'Lundi 26 octobre',
);

/// L'horloge de Conakry avant le changement d'heure europeen.
final HorlogeAffichee horlogeConakryAvantDst = horlogeAffichee(
  fuseauIana: fuseauConakry,
  libelleVille: 'Conakry',
  heureLocaleRendue: '16:00',
  dateLocaleRendue: 'Lundi 19 octobre',
);

/// L'horloge de Conakry apres le changement d'heure europeen.
///
/// Conakry ne change jamais d'heure, et pourtant **son heure de cours change**,
/// parce que c'est Paris qui a bouge. C'est exactement ce que la notice DST
/// doit dire a la famille.
final HorlogeAffichee horlogeConakryApresDst = horlogeAffichee(
  fuseauIana: fuseauConakry,
  libelleVille: 'Conakry',
  heureLocaleRendue: '17:00',
  dateLocaleRendue: 'Lundi 26 octobre',
);

/// L'horloge de Riyad avant le changement d'heure europeen.
final HorlogeAffichee horlogeRiyadAvantDst = horlogeAffichee(
  fuseauIana: fuseauRiyad,
  libelleVille: 'Riyad',
  heureLocaleRendue: '19:00',
  dateLocaleRendue: 'Lundi 19 octobre',
);

/// L'horloge de Riyad apres le changement d'heure europeen.
final HorlogeAffichee horlogeRiyadApresDst = horlogeAffichee(
  fuseauIana: fuseauRiyad,
  libelleVille: 'Riyad',
  heureLocaleRendue: '20:00',
  dateLocaleRendue: 'Lundi 26 octobre',
);

/// La notice de changement d'heure, du point de vue d'une famille a Conakry.
final NoticeDst noticeDstConakry = NoticeDst(
  transitionUtc: transitionDstParis,
  fuseauConcerne: fuseauConakry,
  heureAvantRendue: '16:00',
  heureApresRendue: '17:00',
  echeance: EcheanceDst.j7,
);

/// Construit une horloge de seance coherente pour un instant d'observation.
///
/// Tout est derive des instants UTC et de [fenetreAcces] : rien n'est fige.
/// Changer [fenetreAcces] deplace `joinOpensAtUtc`, et c'est le test.
SessionClockVM horlogeSeance({
  required DateTime maintenant,
  DateTime? debutUtc,
  Duration fenetreAcces = fenetreAccesParDefaut,
  Duration duree = dureeSeance,
  Duration graceApresFin = graceApresFinParDefaut,
  bool connecte = false,
  String? sessionId = 'seance-1',
  HorlogeAffichee? horlogeUtilisateur,
  HorlogeAffichee? horlogeContrepartie,
  NoticeDst? noticeDst,
}) {
  final DateTime debut = debutUtc ?? debutSeanceAvantDst;
  final DateTime finPrevue = debut.add(duree);
  final DateTime ouverture = debut.subtract(fenetreAcces);
  final PhaseSeance phase = phaseDe(
    debutUtc: debut,
    finPrevueUtc: finPrevue,
    joinOpensAtUtc: ouverture,
    maintenant: maintenant,
    connecte: connecte,
    graceApresFin: graceApresFin,
  );
  return SessionClockVM(
    sessionId: sessionId,
    debutUtc: debut,
    finPrevueUtc: finPrevue,
    joinOpensAtUtc: ouverture,
    fenetreAcces: fenetreAcces,
    graceApresFin: graceApresFin,
    horlogeUtilisateur: horlogeUtilisateur ?? horlogeParisAvantDst,
    horlogeContrepartie: horlogeContrepartie,
    phase: phase,
    restant: restantDe(
      phase: phase,
      debutUtc: debut,
      finPrevueUtc: finPrevue,
      maintenant: maintenant,
    ),
    rejoindreOuvert:
        !maintenant.isBefore(ouverture) && phase != PhaseSeance.terminee,
    noticeDst: noticeDst,
    calculeeAUtc: maintenant,
  );
}
