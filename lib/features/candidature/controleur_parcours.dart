// Le parcours d'accueil du candidat dans la Salle d'examen (CAND-01) : les
// etapes, les reponses, le brouillon.
//
// Un parcours, pas un formulaire : trois ecrans de presentation, une question
// par ecran, puis le recapitulatif. Les questions sont celles que rend
// `questionnaire_salle_examen()` (`Questionnaire`), dans l'ordre du serveur ;
// l'application n'ajoute aucune question et aucune regle. Tout se choisit au
// toucher : une reponse est toujours une valeur d'une liste que le serveur a
// rendue (ou une plage de la grille), jamais un texte tape.
//
// Le brouillon est enregistre a chaque etape franchie. Il ne bloque jamais le
// parcours : hors ligne ou en erreur, les reponses restent a l'ecran et
// partent avec l'envoi.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/candidature/disponibilites_declarees.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/port_ma_candidature.dart';
import 'modele_questions.dart';

/// Une etape du parcours.
sealed class EtapeParcours {
  const EtapeParcours();
}

/// Un ecran de presentation de l'academie (rang de 1 a [nombrePresentations]).
final class EtapePresentation extends EtapeParcours {
  /// Cree l'etape.
  const EtapePresentation(this.rang);

  /// Le rang de l'ecran, a partir de 1.
  final int rang;
}

/// Une question : un champ du questionnaire.
final class EtapeChamp extends EtapeParcours {
  /// Cree l'etape.
  const EtapeChamp(this.champ);

  /// Le champ pose.
  final ChampQuestionnaire champ;

  /// La forme de la question.
  FormeQuestion get forme => modelesQuestions[champ.code]!.forme;
}

/// Les ecrans de la question des disponibilites : ce sont plusieurs ecrans, un
/// par decision, et non une grille a remplir d'un coup.
enum SousEtapeDisponibilites {
  /// Les jours de la semaine ou la personne peut enseigner.
  jours,

  /// Les heures de debut possibles, pour le premier jour choisi.
  heures,

  /// « Memes heures pour tous ces jours ? » : oui, ou ajuster jour par jour.
  memes,

  /// Les heures de debut de chaque jour, quand elles different.
  parJour,

  /// Le recapitulatif de la semaine.
  semaine,
}

/// Un des ecrans de la question `disponibilitesDeclarees`.
final class EtapeDisponibilites extends EtapeParcours {
  /// Cree l'etape.
  const EtapeDisponibilites(this.champ, this.sous);

  /// Le champ pose (`disponibilitesDeclarees`).
  final ChampQuestionnaire champ;

  /// L'ecran de la question.
  final SousEtapeDisponibilites sous;
}

/// Le recapitulatif, les conditions de remuneration et l'envoi.
final class EtapeRecapitulatif extends EtapeParcours {
  /// Cree l'etape.
  const EtapeRecapitulatif();
}

/// Le nombre d'ecrans de presentation.
const int nombrePresentations = 3;

/// Les etapes du parcours : la presentation (sauf [avecPresentation] faux),
/// une etape par champ dans l'ordre du serveur, puis le recapitulatif.
///
/// Deux champs sont poses **avant** les disponibilites, quelle que soit leur
/// place dans la definition : le public (la duree d'un cours en depend :
/// 60 minutes pour des enfants, 90 pour des adultes) et le fuseau (les heures
/// sont celles de chez la personne). Les disponibilites tiennent en cinq
/// ecrans au plus : [nombreJours] jours choisis et [memesHeures] decident de
/// ceux qui sont poses (« memes heures ? » demande deux jours au moins ; le
/// reglage jour par jour, un « non »). Un champ facultatif dont le serveur ne
/// rend aucune option (les moyens de paiement connus) n'est pas pose.
List<EtapeParcours> planifierParcours(
  Questionnaire questionnaire, {
  bool avecPresentation = true,
  int nombreJours = 0,
  bool? memesHeures,
}) {
  final ChampQuestionnaire? fuseau = questionnaire.champ('fuseauIana');
  final ChampQuestionnaire? publics = questionnaire.champ('publics');
  final ChampQuestionnaire? dispo = questionnaire.champ(
    'disponibilitesDeclarees',
  );
  final bool groupe = dispo != null;
  return <EtapeParcours>[
    if (avecPresentation)
      for (int rang = 1; rang <= nombrePresentations; rang++)
        EtapePresentation(rang),
    for (final ChampQuestionnaire c in questionnaire.champs) ...<EtapeParcours>[
      if (c.code == 'disponibilitesDeclarees') ...<EtapeParcours>[
        ?(publics == null ? null : EtapeChamp(publics)),
        ?(fuseau == null ? null : EtapeChamp(fuseau)),
        EtapeDisponibilites(c, SousEtapeDisponibilites.jours),
        EtapeDisponibilites(c, SousEtapeDisponibilites.heures),
        if (nombreJours >= 2)
          EtapeDisponibilites(c, SousEtapeDisponibilites.memes),
        if (nombreJours >= 2 && memesHeures == false)
          EtapeDisponibilites(c, SousEtapeDisponibilites.parJour),
        EtapeDisponibilites(c, SousEtapeDisponibilites.semaine),
      ] else if (groupe && (c.code == 'fuseauIana' || c.code == 'publics'))
        ...const <EtapeParcours>[]
      else if (c.code == 'moyensAccessibles' && c.options.isEmpty)
        ...const <EtapeParcours>[]
      else
        EtapeChamp(c),
    ],
    const EtapeRecapitulatif(),
  ];
}

/// Pourquoi on n'avance pas.
enum ManqueReponse {
  /// Aucune reponse.
  aucune,

  /// Aucun jour choisi.
  aucunJour,

  /// Aucune heure de debut choisie.
  aucuneHeure,

  /// Un jour choisi n'a aucune heure de debut ([ParcoursControleur.jourSansHeure]
  /// le nomme).
  jourSansHeure,

  /// Trop de reponses.
  trop,
}

/// Les reponses qui restent valables pour [questionnaire] : celles d'un champ
/// qui existe encore et dont la valeur est dans sa liste. Une reponse que le
/// serveur refuserait n'est jamais renvoyee.
Map<String, Object?> reponsesValables(
  Questionnaire questionnaire,
  Map<String, Object?> brutes,
) {
  final Map<String, Object?> gardees = <String, Object?>{};
  for (final ChampQuestionnaire c in questionnaire.champs) {
    final Object? v = brutes[c.code];
    if (v == null) {
      continue;
    }
    final Set<String> permises = <String>{
      for (final OptionQuestionnaire o in c.options) o.code,
    };
    switch (c.type) {
      case TypeChamp.booleen:
        if (v is bool) {
          gardees[c.code] = v;
        }
      case TypeChamp.choix:
        if (v is String && permises.contains(v)) {
          gardees[c.code] = v;
        }
      case TypeChamp.choixMultiple:
        if (v is List) {
          // Les operateurs dependent du pays : le serveur les relit.
          final List<String> valeurs = <String>[
            for (final Object? x in v)
              if (x is String && (c.options.isEmpty || permises.contains(x))) x,
          ];
          if (valeurs.isNotEmpty) {
            gardees[c.code] = valeurs;
          }
        }
      case TypeChamp.creneaux:
        // La forme du lot C18 : une liste de plages `{jour, debut, fin}`. Une
        // ancienne forme (`{fuseau, creneaux}`, des demi-heures) n'est jamais
        // renvoyee : le serveur la refuserait.
        if (DisponibilitesDeclarees.plagesBienFormees(v)) {
          gardees[c.code] = v;
        }
    }
  }
  return gardees;
}

/// Le parcours d'un candidat : ou il en est, ce qu'il a repondu.
class ParcoursControleur extends ChangeNotifier {
  /// Cree le parcours. [reponses] est ce que le brouillon (ou un envoi
  /// precedent) a rendu, deja nettoye par [reponsesValables].
  ParcoursControleur({
    required this.questionnaire,
    required this.port,
    required Map<String, Object?> reponses,
    this.cartesADemander = const <String>{},
  }) : _reponses = Map<String, Object?>.of(reponses),
       _versionBrouillon = questionnaire.versionBrouillon,
       _avecPresentation = reponses.isEmpty {
    _lireDisponibilites();
    _replanifier();
    _index = _premiereEtapeAFaire();
  }

  /// Le questionnaire du parcours.
  final Questionnaire questionnaire;

  /// Le port du candidat (le brouillon).
  final PortMaCandidature? port;

  /// Les cartes que la direction a demande de completer (codes de carte).
  final Set<String> cartesADemander;

  /// Les etapes, dans l'ordre. Elles se replanifient quand les disponibilites
  /// changent de forme (deux jours ou plus, « memes heures ? »), toujours
  /// apres l'etape courante.
  List<EtapeParcours> etapes = const <EtapeParcours>[];

  final bool _avecPresentation;
  final Map<String, Object?> _reponses;
  int _index = 0;
  int _versionBrouillon;
  bool _depuisRecap = false;
  bool _brouillonNonGarde = false;
  Future<void> _file = Future<void>.value();
  bool _ferme = false;

  // Les disponibilites en cours de saisie : les jours choisis (un jour sans
  // heure y est le temps de la saisie), les heures de debut de chacun, et
  // « memes heures pour tous ces jours ? » (nul tant que la personne n'a pas
  // repondu).
  final Set<int> _jours = <int>{};
  final Map<int, Set<int>> _debuts = <int, Set<int>>{};
  bool? _memesHeures;

  /// Les reponses, par code de champ.
  Map<String, Object?> get reponses =>
      Map<String, Object?>.unmodifiable(_reponses);

  /// L'index de l'etape courante.
  int get index => _index;

  /// L'etape courante.
  EtapeParcours get courante => etapes[_index];

  /// Vrai a la premiere etape.
  bool get estPremiere => _index == 0;

  /// Vrai quand on revient au recapitulatif apres avoir change une reponse.
  bool get depuisRecap => _depuisRecap;

  /// Vrai quand le dernier enregistrement du brouillon a echoue pour une autre
  /// raison que le reseau : les reponses restent a l'ecran.
  bool get brouillonNonGarde => _brouillonNonGarde;

  /// L'index du recapitulatif.
  int get indexRecapitulatif => etapes.length - 1;

  /// La reponse du champ [code].
  Object? reponse(String code) => _reponses[code];

  /// Les valeurs d'une reponse a choix (une valeur ou une liste).
  Set<String> valeurs(String code) {
    final Object? v = _reponses[code];
    if (v is String) {
      return <String>{v};
    }
    if (v is List) {
      return <String>{
        for (final Object? x in v)
          if (x is String) x,
      };
    }
    return const <String>{};
  }

  /// Vrai quand la personne enseigne des enfants (au moins une tranche).
  bool get avecEnfants => valeurs('publics').any(tranchesEnfants.contains);

  /// Vrai quand la personne enseigne des adultes.
  bool get avecAdultes => valeurs('publics').contains(trancheAdultes);

  /// La duree des cours dont les heures se declarent : 90 minutes des qu'une
  /// classe d'adultes est possible (l'heure suivante est alors declaree aussi),
  /// 60 minutes sinon.
  int get dureeDeclaree => dureeDeclareeDe(_reponses['publics']);

  /// Le fuseau retenu.
  String? get fuseau => _reponses['fuseauIana'] as String?;

  /// Les jours choisis (1 pour lundi), tries.
  List<int> get jours => _jours.toList()..sort();

  /// Le premier jour choisi, ou `null`.
  int? get premierJour => _jours.isEmpty ? null : jours.first;

  /// Les heures de debut possibles du jour [jour], triees.
  List<int> debutsDuJour(int jour) =>
      (_debuts[jour] ?? const <int>{}).toList()..sort();

  /// « Memes heures pour tous ces jours ? » : `null` tant que la personne n'a
  /// pas repondu.
  bool? get memesHeures => _memesHeures;

  /// Les disponibilites telles que le serveur les recevra (les jours qui ont
  /// au moins une heure).
  DisponibilitesDeclarees get disponibilites =>
      DisponibilitesDeclarees(<int, Set<int>>{
        for (final int j in _jours)
          if ((_debuts[j] ?? const <int>{}).isNotEmpty) j: _debuts[j]!,
      });

  /// Le premier jour choisi qui n'a aucune heure de debut, ou `null`.
  int? get jourSansHeure {
    for (final int j in jours) {
      if ((_debuts[j] ?? const <int>{}).isEmpty) {
        return j;
      }
    }
    return null;
  }

  /// Retient la reponse du champ [code]. Une reponse change ce qui en depend :
  /// le public change la duree des cours (donc les heures declarees), le pays
  /// de versement vide les operateurs.
  void repondre(String code, Object? valeur) {
    if (valeur == null || (valeur is Iterable && valeur.isEmpty)) {
      _reponses.remove(code);
    } else {
      _reponses[code] = valeur;
    }
    if (code == 'paysVersement') {
      _reponses.remove('operateurs');
    }
    if (code == 'publics') {
      _ecrireDisponibilites();
    }
    notifyListeners();
  }

  /// Choisit ou retire le jour [jour] (1 a 7). Un jour neuf reprend les heures
  /// du premier jour choisi : la plupart des semaines se ressemblent.
  void basculerJour(int jour) {
    if (_jours.contains(jour)) {
      _jours.remove(jour);
      _debuts.remove(jour);
    } else {
      final int? modele = premierJour;
      _jours.add(jour);
      _debuts[jour] = <int>{if (modele != null) ...?_debuts[modele]};
    }
    _apresChangementDeJours();
  }

  /// Remplace les jours choisis par [choisis] (un raccourci : lundi, mercredi,
  /// vendredi...). Un jour deja choisi garde ses heures.
  void choisirJours(Set<int> choisis) {
    // Les heures du premier jour, lues avant qu'un raccourci ne le retire.
    final int? modele = premierJour;
    final Set<int> heuresModele = <int>{
      if (modele != null) ...?_debuts[modele],
    };
    for (final int j in _jours.difference(choisis).toList()) {
      _jours.remove(j);
      _debuts.remove(j);
    }
    for (final int j in choisis.difference(_jours)) {
      _jours.add(j);
      _debuts[j] = <int>{...heuresModele};
    }
    _apresChangementDeJours();
  }

  void _apresChangementDeJours() {
    if (_jours.length < 2) {
      _memesHeures = null;
    }
    // Les jours changent la liste des ecrans (« memes heures ? »).
    _ecrireDisponibilites();
    _replanifier();
    notifyListeners();
  }

  /// Choisit ou retire l'heure de debut [heure] (0 a 23) le jour [jour]. Tant
  /// que les heures sont les memes tous les jours (pas de « non » a « memes
  /// heures ? »), un changement du premier jour vaut pour tous.
  void basculerHeure(int jour, int heure) {
    final Set<int> heures = _debuts.putIfAbsent(jour, () => <int>{});
    if (!heures.remove(heure)) {
      heures.add(heure);
    }
    if (_memesHeures != false && jour == premierJour) {
      _copierPremierJour();
    }
    _ecrireDisponibilites();
    notifyListeners();
  }

  /// Repond a « Memes heures pour tous ces jours ? ». Oui : tous les jours
  /// prennent les heures du premier. Non : chaque jour garde les siennes et se
  /// regle ensuite.
  void repondreMemes({required bool oui}) {
    _memesHeures = oui;
    if (oui) {
      _copierPremierJour();
    }
    _ecrireDisponibilites();
    _replanifier();
    notifyListeners();
  }

  void _copierPremierJour() {
    final int? modele = premierJour;
    if (modele == null) {
      return;
    }
    final Set<int> heures = _debuts[modele] ?? const <int>{};
    for (final int j in _jours) {
      if (j != modele) {
        _debuts[j] = <int>{...heures};
      }
    }
  }

  /// Ecrit la reponse `disponibilitesDeclarees` dans la forme du serveur : les
  /// plages d'heures entieres que touchent les cours possibles.
  void _ecrireDisponibilites() {
    final DisponibilitesDeclarees dispo = disponibilites;
    if (dispo.estVide) {
      _reponses.remove('disponibilitesDeclarees');
    } else {
      _reponses['disponibilitesDeclarees'] = dispo.versPlages(dureeDeclaree);
    }
  }

  /// Relit les disponibilites d'un brouillon ou d'un envoi : les plages du
  /// serveur redonnent les heures de debut possibles d'un cours.
  void _lireDisponibilites() {
    final DisponibilitesDeclarees dispo = DisponibilitesDeclarees.depuisPlages(
      _reponses['disponibilitesDeclarees'],
      dureeMinutes: dureeDeclaree,
    );
    for (final int j in dispo.jours) {
      _jours.add(j);
      _debuts[j] = <int>{...dispo.debuts(j)};
    }
    if (_jours.length >= 2) {
      final Set<int> premier = _debuts[premierJour]!;
      _memesHeures = _jours.every(
        (int j) =>
            _debuts[j]!.length == premier.length &&
            _debuts[j]!.containsAll(premier),
      );
    }
    if (dispo.estVide) {
      _reponses.remove('disponibilitesDeclarees');
    } else {
      _reponses['disponibilitesDeclarees'] = dispo.versPlages(dureeDeclaree);
    }
  }

  void _replanifier() {
    etapes = planifierParcours(
      questionnaire,
      avecPresentation: _avecPresentation,
      nombreJours: _jours.length,
      memesHeures: _memesHeures,
    );
  }

  /// Pourquoi on ne peut pas quitter [etape], ou `null` si on le peut.
  ManqueReponse? manque(EtapeParcours etape) {
    if (etape is EtapeDisponibilites) {
      return switch (etape.sous) {
        SousEtapeDisponibilites.jours =>
          _jours.isEmpty ? ManqueReponse.aucunJour : null,
        SousEtapeDisponibilites.heures =>
          (_debuts[premierJour] ?? const <int>{}).isEmpty
              ? ManqueReponse.aucuneHeure
              : null,
        SousEtapeDisponibilites.memes =>
          _memesHeures == null ? ManqueReponse.aucune : null,
        SousEtapeDisponibilites.parJour =>
          jourSansHeure == null ? null : ManqueReponse.jourSansHeure,
        SousEtapeDisponibilites.semaine => null,
      };
    }
    if (etape is! EtapeChamp) {
      return null;
    }
    final ChampQuestionnaire c = etape.champ;
    switch (etape.forme) {
      case FormeQuestion.creneaux:
        return disponibilites.estVide ? ManqueReponse.aucunJour : null;
      case FormeQuestion.operateurs || FormeQuestion.moyensAccessibles:
        return _trop(c, valeurs(c.code).length);
      case FormeQuestion.choix ||
          FormeQuestion.langue ||
          FormeQuestion.pays ||
          FormeQuestion.fuseau ||
          FormeQuestion.classes:
        return _reponses[c.code] == null && c.requis
            ? ManqueReponse.aucune
            : null;
      case FormeQuestion.ouiNon:
        return _reponses[c.code] is! bool && c.requis
            ? ManqueReponse.aucune
            : null;
      case FormeQuestion.choixMultiple ||
          FormeQuestion.langues ||
          FormeQuestion.riwayat:
        final int n = valeurs(c.code).length;
        if (c.requis && n == 0) {
          return ManqueReponse.aucune;
        }
        return _trop(c, n);
    }
  }

  ManqueReponse? _trop(ChampQuestionnaire c, int n) =>
      c.max != null && n > c.max! ? ManqueReponse.trop : null;

  /// La premiere etape qui attend une reponse, ou le recapitulatif. Si la
  /// direction a demande un complement, la premiere etape des cartes nommees.
  int _premiereEtapeAFaire() {
    if (cartesADemander.isNotEmpty) {
      for (int i = 0; i < etapes.length; i++) {
        final EtapeParcours e = etapes[i];
        if (aCompleter(e)) {
          return i;
        }
      }
    }
    // Rien de repondu : le parcours commence par la presentation.
    if (_reponses.isEmpty) {
      return 0;
    }
    for (int i = 0; i < etapes.length; i++) {
      if (manque(etapes[i]) != null) {
        return i;
      }
    }
    return etapes.length - 1;
  }

  /// Vrai quand l'etape [etape] est une de celles que la direction demande de
  /// completer.
  bool aCompleter(EtapeParcours etape) => switch (etape) {
    EtapeChamp(:final ChampQuestionnaire champ) => cartesADemander.contains(
      champ.carte,
    ),
    EtapeDisponibilites(:final ChampQuestionnaire champ) =>
      cartesADemander.contains(champ.carte),
    _ => false,
  };

  bool _dansLesDisponibilites(int index) =>
      index >= 0 &&
      index < etapes.length &&
      etapes[index] is EtapeDisponibilites;

  /// Passe a l'etape suivante, ou revient au recapitulatif apres une
  /// modification. Rend `false` quand la reponse manque (rien ne bouge).
  bool avancer() {
    if (manque(courante) != null) {
      return false;
    }
    // Le pays de versement repart du pays de residence : une proposition que
    // la personne peut changer (CAND-F16), jamais une reponse tapee.
    final EtapeParcours etape = courante;
    if (etape is EtapeChamp &&
        etape.champ.code == 'paysResidence' &&
        _reponses['paysVersement'] == null &&
        _reponses['paysResidence'] is String) {
      _reponses['paysVersement'] = _reponses['paysResidence'];
    }
    if (courante is EtapeChamp || courante is EtapeDisponibilites) {
      _enregistrerSansBloquer();
    }
    // Modifier les disponibilites depuis le recapitulatif parcourt leurs
    // ecrans jusqu'au dernier, puis revient au recapitulatif.
    final bool resteDansLesDisponibilites =
        _depuisRecap &&
        courante is EtapeDisponibilites &&
        _dansLesDisponibilites(_index + 1);
    _index = _depuisRecap && !resteDansLesDisponibilites
        ? indexRecapitulatif
        : _index + 1;
    _depuisRecap = resteDansLesDisponibilites;
    notifyListeners();
    return true;
  }

  /// Revient a l'etape precedente, ou au recapitulatif apres une modification.
  void reculer() {
    if (_index == 0) {
      return;
    }
    if (_depuisRecap &&
        !(courante is EtapeDisponibilites &&
            _dansLesDisponibilites(_index - 1))) {
      _index = indexRecapitulatif;
      _depuisRecap = false;
    } else {
      _index--;
    }
    notifyListeners();
  }

  /// Va modifier la reponse du champ [code] depuis le recapitulatif.
  void modifier(String code) {
    for (int i = 0; i < etapes.length; i++) {
      final EtapeParcours e = etapes[i];
      final bool visee = switch (e) {
        EtapeChamp(:final ChampQuestionnaire champ) => champ.code == code,
        EtapeDisponibilites(:final ChampQuestionnaire champ, :final sous) =>
          champ.code == code && sous == SousEtapeDisponibilites.jours,
        _ => false,
      };
      if (visee) {
        _index = i;
        _depuisRecap = true;
        notifyListeners();
        return;
      }
    }
  }

  /// Enregistre le brouillon ; jamais bloquant, jamais deux a la fois.
  void _enregistrerSansBloquer() {
    final PortMaCandidature? p = port;
    if (p == null) {
      return;
    }
    final Map<String, Object?> envoi = Map<String, Object?>.of(_reponses);
    _file = _file.then((_) => _enregistrer(p, envoi));
  }

  Future<void> _enregistrer(
    PortMaCandidature p,
    Map<String, Object?> envoi,
  ) async {
    for (int essai = 0; essai < 2; essai++) {
      try {
        final ResultatBrouillon r = await p.enregistrerBrouillon(
          versionQuestionnaire: questionnaire.version,
          reponses: envoi,
          versionBrouillon: _versionBrouillon,
          cleIdempotence: nouvelleCleIdempotence(),
        );
        _versionBrouillon = r.versionBrouillon;
        _signaler(garde: true);
        return;
      } on ConflitBrouillon catch (e) {
        // Le brouillon a change ailleurs : ce que la personne vient de
        // repondre est le plus recent, il prend la place.
        final int? courante = e.versionCourante;
        if (courante == null) {
          break;
        }
        _versionBrouillon = courante;
      } on HorsLigneCandidature {
        // Hors ligne : les reponses restent a l'ecran, le bandeau le dit deja.
        return;
      } on Object {
        break;
      }
    }
    _signaler(garde: false);
  }

  void _signaler({required bool garde}) {
    if (_ferme) {
      return;
    }
    final bool nonGarde = !garde;
    if (nonGarde != _brouillonNonGarde) {
      _brouillonNonGarde = nonGarde;
      notifyListeners();
    }
  }

  /// Les reponses telles que l'envoi les porte : rien d'autre que des champs
  /// du questionnaire, dans la forme que le serveur attend.
  Map<String, Object?> reponsesPourEnvoi() {
    final Map<String, Object?> envoi = <String, Object?>{};
    for (final ChampQuestionnaire c in questionnaire.champs) {
      final Object? v = _reponses[c.code];
      if (v != null) {
        envoi[c.code] = v;
      }
    }
    return envoi;
  }

  @override
  void dispose() {
    _ferme = true;
    super.dispose();
  }
}
