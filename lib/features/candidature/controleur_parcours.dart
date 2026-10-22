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

import '../../core/candidature/creneaux_declares.dart';
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
/// Le fuseau se confirme **avant** la grille des plages : les plages sont a
/// l'heure de chez la personne. Le champ du fuseau est donc pose juste avant
/// celui des plages, quelle que soit sa place dans la definition.
List<EtapeParcours> planifierParcours(
  Questionnaire questionnaire, {
  bool avecPresentation = true,
}) {
  final ChampQuestionnaire? fuseau = questionnaire.champ('fuseauIana');
  return <EtapeParcours>[
    if (avecPresentation)
      for (int rang = 1; rang <= nombrePresentations; rang++)
        EtapePresentation(rang),
    for (final ChampQuestionnaire c in questionnaire.champs) ...<EtapeParcours>[
      if (c.code == 'disponibilitesDeclarees' && fuseau != null)
        EtapeChamp(fuseau),
      if (c.code != 'fuseauIana') EtapeChamp(c),
    ],
    const EtapeRecapitulatif(),
  ];
}

/// Pourquoi on n'avance pas.
enum ManqueReponse {
  /// Aucune reponse.
  aucune,

  /// Aucune plage choisie.
  aucunePlage,

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
        final CreneauxDeclares creneaux = CreneauxDeclares.depuisReponse(v);
        final Object? fuseau = v is Map ? v['fuseau'] : null;
        if (!creneaux.estVide && fuseau is String) {
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
       _versionBrouillon = questionnaire.versionBrouillon {
    etapes = planifierParcours(
      questionnaire,
      avecPresentation: reponses.isEmpty,
    );
    _index = _premiereEtapeAFaire();
  }

  /// Le questionnaire du parcours.
  final Questionnaire questionnaire;

  /// Le port du candidat (le brouillon).
  final PortMaCandidature? port;

  /// Les cartes que la direction a demande de completer (codes de carte).
  final Set<String> cartesADemander;

  /// Les etapes, dans l'ordre.
  late final List<EtapeParcours> etapes;

  final Map<String, Object?> _reponses;
  int _index = 0;
  int _versionBrouillon;
  bool _depuisRecap = false;
  bool _brouillonNonGarde = false;
  Future<void> _file = Future<void>.value();
  bool _ferme = false;

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

  /// Les plages declarees.
  CreneauxDeclares get creneaux =>
      CreneauxDeclares.depuisReponse(_reponses['disponibilitesDeclarees']);

  /// Le fuseau retenu.
  String? get fuseau => _reponses['fuseauIana'] as String?;

  /// Retient la reponse du champ [code]. Une reponse change ce qui en depend :
  /// le fuseau suit les plages, le pays de versement vide les operateurs.
  void repondre(String code, Object? valeur) {
    if (valeur == null || (valeur is Iterable && valeur.isEmpty)) {
      _reponses.remove(code);
    } else {
      _reponses[code] = valeur;
    }
    if (code == 'fuseauIana' && valeur is String) {
      final Object? plages = _reponses['disponibilitesDeclarees'];
      if (plages is Map) {
        _reponses['disponibilitesDeclarees'] = <String, Object?>{
          ...Map<String, Object?>.from(plages),
          'fuseau': valeur,
        };
      }
    }
    if (code == 'paysVersement') {
      _reponses.remove('operateurs');
    }
    notifyListeners();
  }

  /// Retient les plages de la grille, dans le fuseau retenu.
  void declarerPlages(CreneauxDeclares plages) {
    final String? zone = fuseau;
    if (zone == null) {
      return;
    }
    if (plages.estVide) {
      _reponses.remove('disponibilitesDeclarees');
    } else {
      _reponses['disponibilitesDeclarees'] = plages.versReponse(zone);
    }
    notifyListeners();
  }

  /// Pourquoi on ne peut pas quitter [etape], ou `null` si on le peut.
  ManqueReponse? manque(EtapeParcours etape) {
    if (etape is! EtapeChamp) {
      return null;
    }
    final ChampQuestionnaire c = etape.champ;
    switch (etape.forme) {
      case FormeQuestion.creneaux:
        return creneaux.estVide ? ManqueReponse.aucunePlage : null;
      case FormeQuestion.operateurs:
        return _trop(c, valeurs(c.code).length);
      case FormeQuestion.choix ||
          FormeQuestion.langue ||
          FormeQuestion.pays ||
          FormeQuestion.fuseau:
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
        if (e is EtapeChamp && cartesADemander.contains(e.champ.carte)) {
          return i;
        }
      }
    }
    // Rien de repondu : le parcours commence par la presentation.
    if (_reponses.isEmpty) {
      return 0;
    }
    for (int i = 0; i < etapes.length; i++) {
      final EtapeParcours e = etapes[i];
      if (e is EtapeChamp && manque(e) != null) {
        return i;
      }
    }
    return etapes.length - 1;
  }

  /// Vrai quand l'etape [etape] est une de celles que la direction demande de
  /// completer.
  bool aCompleter(EtapeParcours etape) =>
      etape is EtapeChamp && cartesADemander.contains(etape.champ.carte);

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
    if (courante is EtapeChamp) {
      _enregistrerSansBloquer();
    }
    _index = _depuisRecap ? indexRecapitulatif : _index + 1;
    _depuisRecap = false;
    notifyListeners();
    return true;
  }

  /// Revient a l'etape precedente, ou au recapitulatif apres une modification.
  void reculer() {
    if (_index == 0) {
      return;
    }
    if (_depuisRecap) {
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
      if (e is EtapeChamp && e.champ.code == code) {
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

  /// Les reponses telles que l'envoi les porte : le fuseau des plages est celui
  /// qui est retenu, et rien d'autre que des champs du questionnaire.
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
